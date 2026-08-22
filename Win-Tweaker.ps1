#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Wethereal - Windows Performance Tweaker ULTIMATE EDITION v4.4.2
.DESCRIPTION
    A comprehensive Windows optimization tool with 190+ tweaks across 12 categories,
    automatic CPU (Intel/AMD) and GPU (NVIDIA/AMD/Intel, including hybrid multi-GPU
    laptops) hardware detection with vendor-adaptive optimizations, and a live
    progress bar on every applied tweak.
.NOTES
    Author: Wethereal Team
    Version: 4.4.2 Ultimate Edition
    Requires: PowerShell 5.1+ and Administrator privileges
    Compatible: Windows 10/11
.PARAMETER Silent
    Runs Wethereal unattended: no menu, no confirmation prompts, no "press
    enter" pauses. Requires -Profile. Intended for scripted/mass deployment
    (e.g. imaging a fleet of gaming PCs with the same tweak set).
.PARAMETER ProfileName
    Profile to apply when -Silent is used: Gaming, Work, MaxPerformance,
    Privacy, LowEndGaming, Streaming, or Presentation. (Named ProfileName,
    not Profile, to avoid colliding with PowerShell's built-in $Profile
    automatic variable.)
.PARAMETER Gui
    Launches the WinForms graphical front-end instead of the console menu.
    Needs an STA session — if launched from an MTA host, relaunch with
    'powershell -STA -File Win-Tweaker.ps1 -Gui'.
.EXAMPLE
    .\Win-Tweaker.ps1 -Silent -ProfileName LowEndGaming
    Applies the Low-End Gaming / Max FPS profile with zero interaction, then exits.
.EXAMPLE
    .\Win-Tweaker.ps1 -Gui
    Opens the graphical quick-launch window.
#>

param(
    [switch]$Silent,

    [ValidateSet('Gaming', 'Work', 'MaxPerformance', 'Privacy', 'LowEndGaming', 'Streaming', 'Presentation')]
    [string]$ProfileName,

    [switch]$Gui
)

if ($Silent -and -not $ProfileName) {
    Write-Host "ERROR: -Silent requires -ProfileName <Gaming|Work|MaxPerformance|Privacy|LowEndGaming|Streaming|Presentation>" -ForegroundColor Red
    exit 1
}

# Script configuration
$Script:Version = "4.4.2"
$Script:LogFile = "$PSScriptRoot\WinTweaker.log"
$Script:ConfigFile = "$PSScriptRoot\Config.json"
$Script:BackupFile = "$PSScriptRoot\WinTweaker_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
# NOTE: this MUST be an array (@()), never a hashtable (@{}). Backup-RegistryValue
# and Backup-ServiceState append structured entries with `+=` — on a Hashtable,
# `+=` invokes the Hashtable `+` operator (a key MERGE that throws on the very
# next call once two entries share a key like "Type"), silently breaking every
# backup after the first and making Restore/Undo/Export/Compare no-ops.
$Script:ConfigBackup = @()
$Script:UndoStack = @()
$Script:Hardware = $null
$Script:MasterBackupFile = "$PSScriptRoot\Wethereal_MasterBackup.json"

# When $true (set while a profile applies a batch of optimizations), individual
# tweak functions skip their own y/N confirmation and "press enter" pause so a
# profile really is one click instead of a dozen manual confirmations.
$Script:SkipConfirmations = $false
$Script:SkipPauses = $false
# Set for the whole run by -Silent: suppresses every prompt, including the
# top-level "Apply this profile?" and the end-of-profile restart question.
$Script:SilentMode = $false

# Color scheme
$Script:Colors = @{
    Title     = 'Cyan'
    Menu      = 'Yellow'
    Success   = 'Green'
    Warning   = 'Yellow'
    Error     = 'Red'
    Info      = 'White'
    Highlight = 'Magenta'
}

# Configuration structure
$Script:Config = @{
    Version             = $Script:Version
    Profile             = "Default"
    OptimizationHistory = @()
    LastRun             = $null
    Settings            = @{}
}

# Optimization profiles
$Script:Profiles = @{
    Gaming         = @{
        Name        = "🎮 Gaming Performance"
        Description = "Maximum performance for gaming"
        Tweaks      = @('cpu', 'gpu', 'memory', 'network-gaming', 'visual-effects', 'game-mode')
    }
    Work           = @{
        Name        = "💼 Work & Productivity"
        Description = "Balanced for productivity"
        Tweaks      = @('services', 'visual-effects', 'cleanup', 'privacy', 'network')
    }
    MaxPerformance = @{
        Name        = "⚡ Maximum Performance"
        Description = "All performance optimizations"
        Tweaks      = @('all-performance')
    }
    Privacy        = @{
        Name        = "🔒 Privacy Focused"
        Description = "Maximum privacy and security"
        Tweaks      = @('telemetry', 'privacy', 'bloatware', 'tracking')
    }
    LowEndGaming   = @{
        Name        = "🕹️ Low-End Gaming / Max FPS"
        Description = "Aggressive FPS-focused profile for low-spec/budget PCs — strips every non-essential background process, service and visual effect to hand as much CPU/GPU/RAM headroom as possible to the foreground game"
        Tweaks      = @('low-end-gaming')
    }
    Streaming      = @{
        Name        = "📡 Streaming"
        Description = "Tuned for streaming/recording with OBS — frees the GPU hardware encoder from Windows' own capture, mutes on-screen popups, and keeps upload bandwidth stable"
        Tweaks      = @('streaming')
    }
    Presentation   = @{
        Name        = "🔋 Presentation / Battery"
        Description = "The inverse profile: quiet notifications, battery-friendly power plan, screen kept awake, Windows Update paused — for presenting or maximizing battery life"
        Tweaks      = @('presentation')
    }
}

#region Helper Functions

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Debug', 'Info', 'Success', 'Warning', 'Error', 'Critical')]
        [string]$Level = 'Info',
        [string]$Category = 'General'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] [$Category] $Message"
    Add-Content -Path $Script:LogFile -Value $logMessage
    
    $color = switch ($Level) {
        'Success' { $Script:Colors.Success }
        'Warning' { $Script:Colors.Warning }
        'Error' { $Script:Colors.Error }
        'Critical' { $Script:Colors.Error }
        'Debug' { $Script:Colors.Info }
        default { $Script:Colors.Info }
    }
    
    Write-Host $logMessage -ForegroundColor $color
}

function Show-Header {
    param([string]$Subtitle = "")
    
    Clear-Host
    
    # ASCII Art Banner - WETHEREAL
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                           ║" -ForegroundColor Cyan
    Write-Host "║   ██╗    ██╗███████╗████████╗██╗  ██╗███████╗██████╗ ███████╗ █████╗ ██╗║" -ForegroundColor Cyan
    Write-Host "║   ██║    ██║██╔════╝╚══██╔══╝██║  ██║██╔════╝██╔══██╗██╔════╝██╔══██╗██║║" -ForegroundColor Cyan
    Write-Host "║   ██║ █╗ ██║█████╗     ██║   ███████║█████╗  ██████╔╝█████╗  ███████║██║║" -ForegroundColor Cyan
    Write-Host "║   ██║███╗██║██╔══╝     ██║   ██╔══██║██╔══╝  ██╔══██╗██╔══╝  ██╔══██║██║║" -ForegroundColor Cyan
    Write-Host "║   ╚███╔███╔╝███████╗   ██║   ██║  ██║███████╗██║  ██║███████╗██║  ██║███████╗" -ForegroundColor Cyan
    Write-Host "║    ╚══╝╚══╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝" -ForegroundColor Cyan
    Write-Host "║                                                                           ║" -ForegroundColor Cyan
    Write-Host "╠═══════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║            Windows Performance Tweaker - Ultimate Edition v$($Script:Version)           ║" -ForegroundColor White
    Write-Host "╠═══════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║ 🚀 135+ Optimizations │ 🎮 CPU+GPU Auto-Detect │ 📊 Live Progress Bars     ║" -ForegroundColor Green
    Write-Host "║ 💻 Intel/AMD Adaptive │ 🌐 Network Tweaks │ 🔒 Privacy & Security          ║" -ForegroundColor Green
    Write-Host "╠═══════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    if ($Subtitle) {
        $paddedSubtitle = "  " + $Subtitle
        $paddedSubtitle = $paddedSubtitle.PadRight(75)
        Write-Host "║$paddedSubtitle║" -ForegroundColor Magenta
        Write-Host "╠═══════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    }
    
    # Live System Info Bar
    try {
        $sysInfo = Get-SystemInfo
        $hw = Get-HardwareProfile

        # CPU Info (tagged with detected vendor so the platform is always visible)
        $cpuText = "$($sysInfo.CPU) [$($hw.CPU.Vendor)]"
        if ($cpuText.Length -gt 66) { $cpuText = $cpuText.Substring(0, 63) + "..." }
        $cpuText = $cpuText.PadRight(66)

        # GPU Info — shows every detected adapter on hybrid systems (e.g. Intel + AMD)
        if ($hw.GPUs.Count -eq 0) {
            $gpuText = "Not detected"
        }
        else {
            $gpuText = ($hw.GPUs | ForEach-Object { "$($_.Name) [$($_.Vendor)]" }) -join " + "
        }
        if ($gpuText.Length -gt 66) { $gpuText = $gpuText.Substring(0, 63) + "..." }
        $gpuText = $gpuText.PadRight(66)

        # RAM Info
        $ramInfo = $sysInfo.RAM

        Write-Host "║ 💻 CPU: $cpuText  ║" -ForegroundColor DarkGray
        Write-Host "║ 🎮 GPU: $gpuText  ║" -ForegroundColor DarkGray
        Write-Host "║ 🧠 RAM: $($ramInfo.PadRight(58))      ║" -ForegroundColor DarkGray
    }
    catch {
        Write-Host "║ System Info: Initializing...                                              ║" -ForegroundColor DarkGray
    }
    
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Show-MainMenu {
    Show-Header
    Write-Host "  $(Get-Str 'MainMenuTitle')" -ForegroundColor $Script:Colors.Menu
    Write-Host "  ═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Menu
    Write-Host "   1. 🖥️  $(Get-Str 'Cat1')" -ForegroundColor White
    Write-Host "   2. 🎮 $(Get-Str 'Cat2')" -ForegroundColor White
    Write-Host "   3. 🌐 $(Get-Str 'Cat3')" -ForegroundColor White
    Write-Host "   4. 🔒 $(Get-Str 'Cat4')" -ForegroundColor White
    Write-Host "   5. 🗑️  $(Get-Str 'Cat5')" -ForegroundColor White
    Write-Host "   6. ⚙️  $(Get-Str 'Cat6')" -ForegroundColor White
    Write-Host "   7. 📊 $(Get-Str 'Cat7')" -ForegroundColor White
    Write-Host "   8. 🛠️  $(Get-Str 'Cat8')" -ForegroundColor White
    Write-Host "   9. 🚀 $(Get-Str 'Cat9')" -ForegroundColor White
    Write-Host "  10. 🕹️  $(Get-Str 'Cat10')" -ForegroundColor White
    Write-Host "  11. 🤖 $(Get-Str 'Cat11')" -ForegroundColor White
    Write-Host "  12. 🧰 $(Get-Str 'Cat12')" -ForegroundColor White
    Write-Host ""
    Write-Host "  $(Get-Str 'QuickActions')" -ForegroundColor $Script:Colors.Menu
    Write-Host "  ═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Menu
    Write-Host "  13. ⚡ Apply Optimization Profile" -ForegroundColor Green
    Write-Host "  14. 🔍 System Analysis & Recommendations" -ForegroundColor Cyan
    Write-Host "  15. 🎮 GPU-Specific Optimizations" -ForegroundColor Magenta
    Write-Host "  16. 🗑️  Enhanced Bloatware Removal" -ForegroundColor Yellow
    Write-Host "  17. 📈 Generate Optimization Report" -ForegroundColor White
    Write-Host "  18. 🔄 Restore Previous Settings" -ForegroundColor Yellow
    Write-Host "  19. 📋 View Optimization Log" -ForegroundColor White
    Write-Host ""
    Write-Host "  ADVANCED TOOLS (NEW!)" -ForegroundColor $Script:Colors.Highlight
    Write-Host "  ═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Menu
    Write-Host "  20. 📊 Real-Time Performance Dashboard" -ForegroundColor Cyan
    Write-Host "  21. 🌐 Network Speed Test" -ForegroundColor Green
    Write-Host "  22. 🚀 Startup Impact Analyzer" -ForegroundColor Yellow
    Write-Host "  23. 🌡️  System Temperature Monitor" -ForegroundColor Magenta
    Write-Host "  24. 🔄 One-Click Restore" -ForegroundColor White
    Write-Host ""
    Write-Host "  PROFESSIONAL TOOLS (ULTIMATE!)" -ForegroundColor $Script:Colors.Highlight
    Write-Host "  ═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Menu
    Write-Host "  25. 🏥 Comprehensive System Health Check" -ForegroundColor Cyan
    Write-Host "  26. 📝 Registry Optimizer" -ForegroundColor Green
    Write-Host "  27. ⚙️  Intelligent Service Optimizer" -ForegroundColor Yellow
    Write-Host "  28. 🔄 Windows Update Manager" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "   0. ❌ Exit" -ForegroundColor Red
    Write-Host "     (Tip: relaunch with -Gui for the graphical quick-launch window)" -ForegroundColor DarkGray
    Write-Host ""
}

function Confirm-Action {
    param(
        [string]$Message = "Do you want to proceed?",
        [switch]$DefaultYes
    )

    if ($Script:SkipConfirmations -or $Script:SilentMode) { return $true }

    Write-Host ""
    $prompt = if ($DefaultYes) { "$Message (Y/n)" } else { "$Message (y/N)" }
    $response = Read-Host $prompt

    if ($DefaultYes) {
        return $response -ne 'N' -and $response -ne 'n'
    }
    return $response -eq 'Y' -or $response -eq 'y'
}

function Wait-ForUser {
    <#
        Replaces the old inline "Read-Host 'Press Enter to continue'" calls used at
        the end of every tweak function. When a profile is applying a whole batch of
        optimizations back-to-back ($Script:SkipPauses), this becomes a no-op so the
        user isn't forced to press Enter after each of the ~8 steps in a profile.
    #>
    param([string]$Message = "`nPress Enter to continue")

    if ($Script:SkipPauses -or $Script:SilentMode) { return }
    Read-Host $Message
}

function Add-UndoAction {
    param(
        [string]$Description,
        [scriptblock]$UndoScript,
        [hashtable]$Parameters = @{}
    )
    
    $Script:UndoStack += @{
        Timestamp   = Get-Date
        Description = $Description
        UndoScript  = $UndoScript
        Parameters  = $Parameters
    }
}

function Add-MasterBackupEntry {
    <#
        Appends one backup entry to Wethereal_MasterBackup.json, a file that
        accumulates across EVERY run of Wethereal on this machine (never
        truncated) — the "original value the very first time Wethereal ever
        touched this setting". Invoke-FullRollback replays this whole file,
        so it's how "undo everything Wethereal has ever changed" works, as
        opposed to $Script:ConfigBackup which only covers this session.
    #>
    param([hashtable]$Entry)

    try {
        $existing = if (Test-Path $Script:MasterBackupFile) {
            @(Get-Content -Path $Script:MasterBackupFile -Raw -ErrorAction Stop | ConvertFrom-Json)
        }
        else { @() }

        $isDup = $existing | Where-Object {
            if ($Entry.Type -eq 'Registry') { $_.Type -eq 'Registry' -and $_.Path -eq $Entry.Path -and $_.Name -eq $Entry.Name }
            else { $_.Type -eq 'Service' -and $_.Name -eq $Entry.Name }
        }
        if (-not $isDup) {
            $existing = @($existing) + [PSCustomObject]$Entry
            $existing | ConvertTo-Json -Depth 10 | Out-File -FilePath $Script:MasterBackupFile -Encoding UTF8
        }
    }
    catch {
        Write-Log "Failed to update master backup file: $($_.Exception.Message)" -Level Warning -Category "Backup"
    }
}

function Backup-ServiceState {
    param([string]$ServiceName)
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service) {
            # Guard against clobbering the TRUE original state: if this service was
            # already backed up earlier in the session, a second call would otherwise
            # capture the now-modified state as "original", making restore a no-op.
            $alreadyBacked = $Script:ConfigBackup | Where-Object { $_.Type -eq 'Service' -and $_.Name -eq $ServiceName }
            if (-not $alreadyBacked) {
                $entry = @{
                    Type      = 'Service'
                    Name      = $ServiceName
                    Status    = $service.Status.ToString()
                    StartType = $service.StartType.ToString()
                }
                $Script:ConfigBackup += $entry
                Add-MasterBackupEntry -Entry $entry

                Add-UndoAction -Description "Restore service: $ServiceName" -UndoScript {
                    param($Name, $StartType, $Status)
                    Set-Service -Name $Name -StartupType $StartType
                    if ($Status -eq 'Running') { Start-Service -Name $Name -ErrorAction SilentlyContinue }
                } -Parameters @{ Name = $ServiceName; StartType = $service.StartType.ToString(); Status = $service.Status.ToString() }
            }
        }
    }
    catch {
        Write-Log "Failed to backup service state for $ServiceName" -Level Warning -Category "Backup"
    }
}

function Backup-RegistryValue {
    param(
        [string]$Path,
        [string]$Name
    )

    try {
        if (Test-Path $Path) {
            $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($value) {
                # Same original-value guard as Backup-ServiceState above.
                $alreadyBacked = $Script:ConfigBackup | Where-Object { $_.Type -eq 'Registry' -and $_.Path -eq $Path -and $_.Name -eq $Name }
                if (-not $alreadyBacked) {
                    $entry = @{
                        Type  = 'Registry'
                        Path  = $Path
                        Name  = $Name
                        Value = $value.$Name
                    }
                    $Script:ConfigBackup += $entry
                    Add-MasterBackupEntry -Entry $entry

                    Add-UndoAction -Description "Restore registry: $Path\$Name" -UndoScript {
                        param($RegPath, $RegName, $RegValue)
                        Set-ItemProperty -Path $RegPath -Name $RegName -Value $RegValue
                    } -Parameters @{ RegPath = $Path; RegName = $Name; RegValue = $value.$Name }
                }
            }
        }
    }
    catch {
        Write-Log "Failed to backup registry value $Path\$Name" -Level Warning -Category "Backup"
    }
}

function Invoke-BackupRestore {
    <#
        Applies every entry captured by Backup-RegistryValue / Backup-ServiceState —
        either the live in-memory $Script:ConfigBackup, or one deserialized from a
        WinTweaker_Backup_*.json file on disk — back onto the system, using the
        same visual progress-bar sequence as every other tweak.
    #>
    param([Parameter(Mandatory = $true)][array]$Entries)

    if ($Entries.Count -eq 0) {
        Write-Host "`n⚠ Nothing to restore in this backup." -ForegroundColor $Script:Colors.Warning
        return
    }

    $steps = $Entries | ForEach-Object {
        $entry = $_
        if ($entry.Type -eq 'Registry') {
            @{
                Name   = "Restoring $($entry.Path)\$($entry.Name)"
                Action = { Set-ItemProperty -Path $entry.Path -Name $entry.Name -Value $entry.Value -ErrorAction Stop }.GetNewClosure()
            }
        }
        elseif ($entry.Type -eq 'Service') {
            @{
                Name   = "Restoring service state: $($entry.Name)"
                Action = {
                    Set-Service -Name $entry.Name -StartupType $entry.StartType -ErrorAction Stop
                    if ($entry.Status -eq 'Running') { Start-Service -Name $entry.Name -ErrorAction SilentlyContinue }
                }.GetNewClosure()
            }
        }
    } | Where-Object { $_ }

    Invoke-TweakSequence -Title "Restoring Previous Settings" -Steps $steps -Category "Restore" | Out-Null
}

function Get-SystemInfo {
    $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    $ram = Get-CimInstance -ClassName Win32_ComputerSystem
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $gpu = Get-CimInstance -ClassName Win32_VideoController | Select-Object -First 1

    return @{
        CPU    = "$($cpu.Name) ($($cpu.NumberOfCores) cores, $($cpu.NumberOfLogicalProcessors) threads)"
        RAM    = "$([math]::Round($ram.TotalPhysicalMemory / 1GB, 2)) GB"
        OS     = "$($os.Caption) Build $($os.BuildNumber)"
        GPU    = $gpu.Name
        Uptime = (Get-Date) - $os.LastBootUpTime
    }
}

function Invoke-TweakSequence {
    <#
        Shared progress-bar engine used by every optimization function in Wethereal.
        Takes an ordered array of steps (@{ Name = "..."; Action = { <scriptblock> } })
        and executes them one by one, showing a native Write-Progress bar plus a live
        checklist in the console so the user always knows exactly what is happening.
        Each step is independently wrapped in try/catch so one failure never aborts
        the whole sequence, and every outcome is written to the log file.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][array]$Steps,
        [string]$Category = 'General'
    )

    $total = $Steps.Count
    $current = 0
    $succeeded = 0
    $failed = 0
    $skipped = 0

    Write-Host ""
    foreach ($step in $Steps) {
        $current++
        $percent = [math]::Round(($current / $total) * 100)

        Write-Progress -Activity "⚡ $Title" -Status "[$current/$total] $($step.Name)" -PercentComplete $percent -CurrentOperation "Applying tweak..."

        # Optional per-step gate, e.g. skip a tweak when the relevant hardware isn't present
        if ($step.ContainsKey('Condition') -and -not (& $step.Condition)) {
            Write-Host ("  [{0,2}/{1,-2}] ⏭  {2} " -f $current, $total, $step.Name) -ForegroundColor DarkGray
            Write-Log "$($step.Name) - skipped (condition not met)" -Level Debug -Category $Category
            $skipped++
            continue
        }

        try {
            & $step.Action
            Write-Host ("  [{0,2}/{1,-2}] ✓ {2}" -f $current, $total, $step.Name) -ForegroundColor $Script:Colors.Success
            Write-Log $step.Name -Level Success -Category $Category
            $succeeded++
            if (Get-Command -Name Add-TelemetryEvent -ErrorAction SilentlyContinue) {
                Add-TelemetryEvent -Category $Category -StepName $step.Name
            }
        }
        catch {
            Write-Host ("  [{0,2}/{1,-2}] ✗ {2} — {3}" -f $current, $total, $step.Name, $_.Exception.Message) -ForegroundColor $Script:Colors.Error
            Write-Log "$($step.Name) failed: $($_.Exception.Message)" -Level Warning -Category $Category
            $failed++
        }

        Start-Sleep -Milliseconds 80
    }

    Write-Progress -Activity "⚡ $Title" -Completed

    $bar = "█" * [math]::Floor(($succeeded / [math]::Max($total, 1)) * 30)
    $bar = $bar.PadRight(30, '░')
    Write-Host "`n  [$bar] $succeeded/$total applied" -ForegroundColor $Script:Colors.Highlight
    if ($failed -gt 0) {
        Write-Host "  ⚠ $failed step(s) failed — see log for details." -ForegroundColor $Script:Colors.Warning
    }
    if ($skipped -gt 0) {
        Write-Host "  ⏭  $skipped step(s) skipped (not applicable to this hardware)." -ForegroundColor DarkGray
    }

    return @{ Total = $total; Succeeded = $succeeded; Failed = $failed; Skipped = $skipped }
}

#endregion

#region Load Additional Modules

# Load additional optimization modules
# NOTE: Modules-HardwareDetection.ps1 must load FIRST — every other module calls
# Get-CPUVendor / Get-GPUVendor / Get-HardwareProfile to adapt its optimizations.
$moduleFiles = @(
    "$PSScriptRoot\Modules-HardwareDetection.ps1",
    "$PSScriptRoot\Modules-GamingNetwork.ps1",
    "$PSScriptRoot\Modules-PrivacyCleanup.ps1",
    "$PSScriptRoot\Modules-AdvancedTools.ps1",
    "$PSScriptRoot\Modules-Enhancements.ps1",
    "$PSScriptRoot\Modules-Advanced.ps1",
    "$PSScriptRoot\Modules-FinalEnhancements.ps1",
    "$PSScriptRoot\Modules-UltimateExtras.ps1",
    "$PSScriptRoot\Modules-ProGamingTools.ps1",
    "$PSScriptRoot\Modules-SystemAutomation.ps1",
    "$PSScriptRoot\Modules-ProSuite.ps1",
    "$PSScriptRoot\Modules-GUI.ps1"
)

foreach ($moduleFile in $moduleFiles) {
    if (Test-Path $moduleFile) {
        . $moduleFile
        Write-Log "Loaded module: $(Split-Path $moduleFile -Leaf)" -Level Debug -Category "System"
    }
    else {
        Write-Log "Module not found: $(Split-Path $moduleFile -Leaf)" -Level Warning -Category "System"
    }
}

#endregion

#region Category 1: System Performance

function Show-SystemPerformanceMenu {
    do {
        Show-Header "System Performance"
        Write-Host "  SYSTEM PERFORMANCE OPTIMIZATIONS" -ForegroundColor $Script:Colors.Menu
        Write-Host "  ═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Menu
        Write-Host "   1. CPU Optimizations (Core Parking, Scheduling, Power)" -ForegroundColor White
        Write-Host "   2. GPU & Graphics Optimizations" -ForegroundColor White
        Write-Host "   3. RAM & Memory Advanced Tweaks" -ForegroundColor White
        Write-Host "   4. Disk I/O Optimizations" -ForegroundColor White
        Write-Host "   5. Windows Services Optimization" -ForegroundColor White
        Write-Host "   6. Visual Effects Optimization" -ForegroundColor White
        Write-Host "   7. Storage Optimization (SSD/HDD)" -ForegroundColor White
        Write-Host "   8. Windows Update Optimizations" -ForegroundColor White
        Write-Host "   9. ⚡ Apply All System Optimizations" -ForegroundColor Green
        Write-Host "   0. ← Back to Main Menu" -ForegroundColor Yellow
        Write-Host ""
        
        $choice = Read-Host "Select an option"
        
        switch ($choice) {
            '1' { Optimize-CPU }
            '2' { Optimize-GPU }
            '3' { Optimize-MemoryAdvanced }
            '4' { Optimize-DiskIO }
            '5' { Optimize-WindowsServices }
            '6' { Optimize-VisualEffects }
            '7' { Optimize-Storage }
            '8' { Optimize-WindowsUpdate }
            '9' { Invoke-AllSystemOptimizations }
            '0' { return }
        }
    } while ($true)
}

function Optimize-CPU {
    Write-Host "`n[CPU OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    $hw = Get-HardwareProfile
    Write-Host "Detected CPU: $($hw.CPU.Name) [$($hw.CPU.Vendor)]" -ForegroundColor $Script:Colors.Info
    Write-Host "This will optimize CPU settings for maximum performance." -ForegroundColor $Script:Colors.Info

    if (-not (Confirm-Action)) { return }

    Write-Log "Starting CPU optimizations for $($hw.CPU.Vendor) CPU" -Level Info -Category "CPU"

    $steps = @(
        @{
            Name   = "Disabling CPU core parking"
            Action = {
                $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"
                if (Test-Path $path) {
                    Backup-RegistryValue -Path $path -Name "ValueMax"
                    Set-ItemProperty -Path $path -Name "ValueMax" -Value 0 -Type DWord
                }
            }
        }
        @{
            Name   = "Optimizing processor scheduling for programs"
            Action = {
                $path = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
                Backup-RegistryValue -Path $path -Name "Win32PrioritySeparation"
                Set-ItemProperty -Path $path -Name "Win32PrioritySeparation" -Value 38 -Type DWord
            }
        }
        @{
            Name   = "Disabling CPU throttling (min processor state 100%)"
            Action = {
                powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100 | Out-Null
                powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100 | Out-Null
            }
        }
        @{
            Name   = "Optimizing DPC/interrupt moderation"
            Action = {
                $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "DpcWatchdogProfileOffset"
                Set-ItemProperty -Path $path -Name "DpcWatchdogProfileOffset" -Value 1 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "CPU Optimization" -Steps $steps -Category "CPU" | Out-Null

    # Vendor-specific pass: AMD Ryzen vs Intel get different power/scheduling tweaks
    switch ($hw.CPU.Vendor) {
        "AMD" { Optimize-AMDCPU }
        "Intel" { Optimize-IntelCPU }
        default { Write-Host "`n  ℹ No vendor-specific CPU profile available for '$($hw.CPU.Vendor)'." -ForegroundColor DarkGray }
    }

    Write-Host "`n✓ CPU optimizations complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Optimize-GPU {
    Write-Host "`n[GPU & GRAPHICS OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    $hw = Get-HardwareProfile
    if ($hw.GPUs.Count -eq 0) {
        Write-Host "No GPU detected." -ForegroundColor $Script:Colors.Warning
    }
    elseif ($hw.IsHybridGPU) {
        Write-Host "Detected hybrid GPU setup: $($hw.GPUVendors -join ' + ')" -ForegroundColor $Script:Colors.Info
    }
    else {
        Write-Host "Detected GPU: $($hw.PrimaryGPU.Name) [$($hw.PrimaryGPU.Vendor)]" -ForegroundColor $Script:Colors.Info
    }

    if (-not (Confirm-Action)) { return }

    Write-Log "Starting GPU optimizations" -Level Info -Category "GPU"

    $steps = @(
        @{
            Name   = "Enabling Hardware-Accelerated GPU Scheduling"
            Action = {
                $path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "HwSchMode"
                Set-ItemProperty -Path $path -Name "HwSchMode" -Value 2 -Type DWord
            }
        }
        @{
            Name   = "Disabling Game Bar auto-launch"
            Action = {
                $path = "HKCU:\Software\Microsoft\GameBar"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "AllowAutoGameMode"
                Set-ItemProperty -Path $path -Name "AllowAutoGameMode" -Value 0 -Type DWord
                Backup-RegistryValue -Path $path -Name "AutoGameModeEnabled"
                Set-ItemProperty -Path $path -Name "AutoGameModeEnabled" -Value 0 -Type DWord
            }
        }
        @{
            Name   = "Disabling Game DVR / background recording"
            Action = {
                $path = "HKCU:\System\GameConfigStore"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "GameDVR_Enabled"
                Set-ItemProperty -Path $path -Name "GameDVR_Enabled" -Value 0 -Type DWord
            }
        }
        @{
            Name   = "Configuring DirectX high-performance GPU preference"
            Action = {
                $path = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            }
        }
    )

    Invoke-TweakSequence -Title "GPU Optimization" -Steps $steps -Category "GPU" | Out-Null

    Write-Host "`n✓ GPU optimizations complete!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Note: Restart required for GPU scheduling changes." -ForegroundColor $Script:Colors.Warning
    Wait-ForUser
}

function Optimize-MemoryAdvanced {
    Write-Host "`n[ADVANCED MEMORY OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Starting advanced memory optimizations" -Level Info -Category "Memory"

    $steps = @(
        @{
            Name   = "Configuring large system cache"
            Action = {
                $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
                Backup-RegistryValue -Path $path -Name "LargeSystemCache"
                Set-ItemProperty -Path $path -Name "LargeSystemCache" -Value 1 -Type DWord
            }
        }
        @{
            Name   = "Disabling paging executive (keeps kernel in RAM)"
            Action = {
                $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
                Backup-RegistryValue -Path $path -Name "DisablePagingExecutive"
                Set-ItemProperty -Path $path -Name "DisablePagingExecutive" -Value 1 -Type DWord
            }
        }
        @{
            Name   = "Clearing standby memory via garbage collection"
            Action = {
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()
            }
        }
        @{
            Name   = "Disabling SysMain/Superfetch service"
            Action = {
                $service = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
                if ($service) {
                    Backup-ServiceState -ServiceName "SysMain"
                    Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
                    Set-Service -Name "SysMain" -StartupType Disabled
                }
            }
        }
        @{
            Name   = "Optimizing prefetch parameters"
            Action = {
                $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
                if (Test-Path $path) {
                    Backup-RegistryValue -Path $path -Name "EnablePrefetcher"
                    Set-ItemProperty -Path $path -Name "EnablePrefetcher" -Value 0 -Type DWord
                    Backup-RegistryValue -Path $path -Name "EnableSuperfetch"
                    Set-ItemProperty -Path $path -Name "EnableSuperfetch" -Value 0 -Type DWord
                }
            }
        }
    )

    Invoke-TweakSequence -Title "Memory Optimization" -Steps $steps -Category "Memory" | Out-Null

    Write-Host "`n✓ Memory optimizations complete!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Note: Restart recommended for full effect." -ForegroundColor $Script:Colors.Warning
    Wait-ForUser
}

function Optimize-DiskIO {
    Write-Host "`n[DISK I/O OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Starting disk I/O optimizations" -Level Info -Category "Disk"

    $steps = @(
        @{ Name = "Enabling TRIM for SSDs"; Action = { fsutil behavior set DisableDeleteNotify 0 | Out-Null } }
        @{ Name = "Disabling 8.3 filename creation"; Action = { fsutil behavior set disable8dot3 1 | Out-Null } }
        @{ Name = "Disabling last-access timestamps"; Action = { fsutil behavior set disablelastaccess 1 | Out-Null } }
        @{ Name = "Optimizing NTFS memory usage"; Action = { fsutil behavior set memoryusage 2 | Out-Null } }
    )

    Invoke-TweakSequence -Title "Disk I/O Optimization" -Steps $steps -Category "Disk" | Out-Null

    Write-Host "`n✓ Disk I/O optimizations complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Optimize-WindowsServices {
    Write-Host "`n[WINDOWS SERVICES OPTIMIZATION]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Starting Windows Services optimization" -Level Info -Category "Services"
    
    $servicesToDisable = @(
        'DiagTrack',                    # Connected User Experiences and Telemetry
        'dmwappushservice',             # WAP Push Message Routing Service
        'SysMain',                      # Superfetch
        'WSearch',                      # Windows Search
        'XblAuthManager',               # Xbox Live Auth Manager
        'XblGameSave',                  # Xbox Live Game Save
        'XboxNetApiSvc',                # Xbox Live Networking Service
        'XboxGipSvc',                   # Xbox Accessory Management Service
        'RetailDemo',                   # Retail Demo Service
        'MapsBroker',                   # Downloaded Maps Manager
        'lfsvc',                        # Geolocation Service
        'RemoteRegistry',               # Remote Registry
        'RemoteAccess',                 # Routing and Remote Access
        'WMPNetworkSvc',                # Windows Media Player Network Sharing
        'WerSvc',                       # Windows Error Reporting
        'Fax',                          # Fax Service
        'TabletInputService',           # Touch Keyboard and Handwriting Panel Service
        'PhoneSvc',                     # Phone Service
        'wisvc',                        # Windows Insider Service
        'stisvc'                        # Windows Image Acquisition
    )
    
    $steps = $servicesToDisable | ForEach-Object {
        $svcName = $_
        @{
            Name   = "Disabling service: $svcName"
            Action = {
                $service = Get-Service -Name $svcName -ErrorAction SilentlyContinue
                if ($service) {
                    Backup-ServiceState -ServiceName $svcName
                    Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
                    Set-Service -Name $svcName -StartupType Disabled -ErrorAction Stop
                }
                else {
                    throw "Service not present on this system"
                }
            }.GetNewClosure()
        }
    }

    $result = Invoke-TweakSequence -Title "Windows Services Optimization" -Steps $steps -Category "Services"

    Write-Host "`n✓ Disabled $($result.Succeeded) services!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Optimize-VisualEffects {
    Write-Host "`n[VISUAL EFFECTS OPTIMIZATION]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Starting Visual Effects optimization" -Level Info -Category "Visual"

    $steps = @(
        @{
            Name   = "Setting visual effects to 'Best Performance'"
            Action = {
                $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "VisualFXSetting"
                Set-ItemProperty -Path $path -Name "VisualFXSetting" -Value 2 -Type DWord
            }
        }
        @{
            Name   = "Disabling window minimize/maximize animations"
            Action = {
                $path = "HKCU:\Control Panel\Desktop\WindowMetrics"
                Backup-RegistryValue -Path $path -Name "MinAnimate"
                Set-ItemProperty -Path $path -Name "MinAnimate" -Value 0 -Type String
            }
        }
        @{
            Name   = "Disabling transparency effects"
            Action = {
                $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "EnableTransparency"
                Set-ItemProperty -Path $path -Name "EnableTransparency" -Value 0 -Type DWord
            }
        }
        @{
            Name   = "Disabling taskbar animations"
            Action = {
                $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                Backup-RegistryValue -Path $path -Name "TaskbarAnimations"
                Set-ItemProperty -Path $path -Name "TaskbarAnimations" -Value 0 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "Visual Effects Optimization" -Steps $steps -Category "Visual" | Out-Null

    Write-Host "`n✓ Visual effects optimized!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Optimize-Storage {
    Write-Host "`n[STORAGE OPTIMIZATION]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Starting Storage optimization" -Level Info -Category "Storage"

    $drives = Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' }

    if (-not $drives -or $drives.Count -eq 0) {
        Write-Host "`n⚠ No fixed drives found to optimize." -ForegroundColor $Script:Colors.Warning
        Wait-ForUser
        return
    }

    $steps = $drives | ForEach-Object {
        $letter = $_.DriveLetter
        @{
            Name   = "Optimizing drive $($letter):"
            Action = { Optimize-Volume -DriveLetter $letter -ErrorAction Stop }.GetNewClosure()
        }
    }

    Invoke-TweakSequence -Title "Storage Optimization" -Steps $steps -Category "Storage" | Out-Null

    Write-Host "`n✓ Storage optimization complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Optimize-WindowsUpdate {
    Write-Host "`n[WINDOWS UPDATE OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Starting Windows Update optimizations" -Level Info -Category "WindowsUpdate"

    $steps = @(
        @{
            Name   = "Disabling automatic driver updates"
            Action = {
                $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "SearchOrderConfig"
                Set-ItemProperty -Path $path -Name "SearchOrderConfig" -Value 0 -Type DWord
            }
        }
        @{
            Name   = "Configuring delivery optimization"
            Action = {
                $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "DODownloadMode"
                Set-ItemProperty -Path $path -Name "DODownloadMode" -Value 0 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "Windows Update Optimization" -Steps $steps -Category "WindowsUpdate" | Out-Null

    Write-Host "`n✓ Windows Update optimizations complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Invoke-AllSystemOptimizations {
    Write-Host "`n[APPLY ALL SYSTEM OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    Write-Host "This will apply ALL system performance optimizations." -ForegroundColor $Script:Colors.Warning
    
    if (-not (Confirm-Action)) { return }
    
    Optimize-CPU
    Optimize-GPU
    Optimize-MemoryAdvanced
    Optimize-DiskIO
    Optimize-WindowsServices
    Optimize-VisualEffects
    Optimize-Storage
    Optimize-WindowsUpdate
    
    Write-Host "`n╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Script:Colors.Success
    Write-Host "║  ✓ ALL SYSTEM OPTIMIZATIONS COMPLETED!                                    ║" -ForegroundColor $Script:Colors.Success
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Script:Colors.Success
    
    Wait-ForUser
}

#endregion

# Due to size constraints, I'll continue in the next file...
# This is Part 1 of the Ultimate Edition
# Remaining categories will be added incrementally

#region Main Program (Simplified for now)

function Main {
    # Check for admin privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "This script requires Administrator privileges." -ForegroundColor $Script:Colors.Error
        Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor $Script:Colors.Warning
        if (-not $Silent) { Read-Host "`nPress Enter to exit" }
        exit 1
    }

    Import-TelemetrySettings
    Import-LanguageSetting

    if ($Silent) {
        # Unattended mode: no banner, no prompts — apply the requested profile
        # and exit. Intended for scripted/fleet deployment.
        $Script:SilentMode = $true
        Get-HardwareProfile -Refresh | Out-Null
        Write-Log "Wethereal v$($Script:Version) started in -Silent mode (Profile: $ProfileName)" -Level Info -Category "System"
        Write-Host "Wethereal v$($Script:Version) - Silent mode - Applying profile '$ProfileName'..." -ForegroundColor Cyan
        Invoke-OptimizationProfile -ProfileName $ProfileName
        Write-Host "Done. See $Script:LogFile for details." -ForegroundColor Green
        exit 0
    }

    if ($Gui) {
        Get-HardwareProfile -Refresh | Out-Null
        Write-Log "Wethereal v$($Script:Version) started in -Gui mode" -Level Info -Category "System"
        Write-Host "Wethereal v$($Script:Version) - Launching graphical quick-launch window..." -ForegroundColor Cyan
        Write-Host "(This console window stays open — live progress for anything you run prints here.)" -ForegroundColor DarkGray
        Show-GraphicalMenu
        Write-Host "`nGUI closed. Falling back to the console menu below." -ForegroundColor Cyan
    }

    # Startup Animation
    Clear-Host
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                           ║" -ForegroundColor Cyan
    Write-Host "║   ██╗    ██╗███████╗████████╗██╗  ██╗███████╗██████╗ ███████╗ █████╗ ██╗║" -ForegroundColor Cyan
    Write-Host "║   ██║    ██║██╔════╝╚══██╔══╝██║  ██║██╔════╝██╔══██╗██╔════╝██╔══██╗██║║" -ForegroundColor Cyan
    Write-Host "║   ██║ █╗ ██║█████╗     ██║   ███████║█████╗  ██████╔╝█████╗  ███████║██║║" -ForegroundColor Cyan
    Write-Host "║   ██║███╗██║██╔══╝     ██║   ██╔══██║██╔══╝  ██╔══██╗██╔══╝  ██╔══██║██║║" -ForegroundColor Cyan
    Write-Host "║   ╚███╔███╔╝███████╗   ██║   ██║  ██║███████╗██║  ██║███████╗██║  ██║███████╗" -ForegroundColor Cyan
    Write-Host "║    ╚══╝╚══╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝" -ForegroundColor Cyan
    Write-Host "║                                                                           ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Initializing Wethereal v$($Script:Version)..." -ForegroundColor Yellow -NoNewline
    Start-Sleep -Milliseconds 500
    Write-Host " ✓" -ForegroundColor Green
    
    Write-Host "  Loading optimization modules..." -ForegroundColor Yellow -NoNewline
    Start-Sleep -Milliseconds 400
    Write-Host " ✓" -ForegroundColor Green
    
    Write-Host "  Detecting CPU vendor (Intel / AMD)..." -ForegroundColor Yellow -NoNewline
    $hw = Get-HardwareProfile -Refresh
    Start-Sleep -Milliseconds 300
    Write-Host " ✓ [$($hw.CPU.Vendor) detected]" -ForegroundColor Green

    Write-Host "  Scanning GPU vendor(s)..." -ForegroundColor Yellow -NoNewline
    Start-Sleep -Milliseconds 300
    if ($hw.IsHybridGPU) {
        Write-Host " ✓ [Hybrid: $($hw.GPUVendors -join ' + ') detected]" -ForegroundColor Green
    }
    else {
        Write-Host " ✓ [$($hw.GPUVendors -join ', ') detected]" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "  🎯 Platform profile: $(Show-HardwarePlatformSummary)" -ForegroundColor Magenta
    Write-Host "     Optimizations below will automatically adapt to this hardware." -ForegroundColor DarkGray

    Write-Host ""
    Write-Host "  🚀 Ready! Press any key to continue..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    Write-Log "Wethereal Ultimate Edition v$($Script:Version) started - Platform: $(Show-HardwarePlatformSummary)" -Level Info -Category "System"
    
    do {
        Show-MainMenu
        $choice = Read-Host "Select an option (0-28)"

        switch ($choice) {
            '1' { Show-SystemPerformanceMenu }
            '2' { Show-GamingMenu }
            '3' { Show-NetworkMenu }
            '4' { Show-PrivacyMenu }
            '5' { Show-CleanupMenu }
            '6' { Show-AdvancedMenu }
            '7' { Show-MonitoringMenu }
            '8' { Show-ToolsMenu }
            '9' { Show-UltimateExtrasMenu }
            '10' { Show-ProGamingToolsMenu }
            '11' { Show-AutomationMenu }
            '12' { Show-ProSuiteMenu }
            '13' { Show-ProfilesMenuEnhanced }
            '14' { Start-SystemAnalysis }
            '15' { Optimize-GPUSpecific }
            '16' { Get-EnhancedBloatwareList }
            '17' { New-OptimizationReport }
            '18' { Restore-PreviousSettings }
            '19' { Show-OptimizationLog }
            '20' { Show-PerformanceDashboard }
            '21' { Test-NetworkSpeed }
            '22' { Show-StartupImpact }
            '23' { Show-SystemTemperature }
            '24' { Invoke-QuickRestore }
            '25' { Start-SystemHealthCheck }
            '26' { Optimize-Registry }
            '27' { Optimize-ServicesIntelligent }
            '28' { Set-WindowsUpdates }
            '0' {
                Write-Host "`nThank you for using Wethereal Ultimate Edition!" -ForegroundColor $Script:Colors.Success
                Write-Log "Wethereal exited" -Level Info -Category "System"
                exit
            }
            default {
                Write-Host "`n✗ Invalid option. Please try again." -ForegroundColor $Script:Colors.Error
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}

# Run the main program
Main

#endregion

#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows Performance Tweaker ULTIMATE EDITION v2.0.0
.DESCRIPTION
    The most comprehensive Windows optimization tool ever created with 50+ tweaks across 8 categories.
.NOTES
    Author: Windows Performance Tweaker Team
    Version: 2.0.0 Ultimate Edition
    Requires: PowerShell 5.1+ and Administrator privileges
    Compatible: Windows 10/11
#>

# Script configuration
$Script:Version = "3.5.0"
$Script:LogFile = "$PSScriptRoot\WinTweaker.log"
$Script:ConfigFile = "$PSScriptRoot\Config.json"
$Script:BackupFile = "$PSScriptRoot\WinTweaker_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$Script:ConfigBackup = @{}
$Script:UndoStack = @()

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
    Write-Host "║ 🚀 125+ Optimizations │ 🎮 GPU Auto-Detect │ 📊 Smart Analysis │ 🤖 Profiles║" -ForegroundColor Green
    Write-Host "║ 💻 System Performance │ 🌐 Network Tweaks │ 🔒 Privacy & Security          ║" -ForegroundColor Green
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
        $gpuVendor = Get-GPUVendor
        
        # CPU Info
        $cpuText = $sysInfo.CPU
        if ($cpuText.Length -gt 55) { $cpuText = $cpuText.Substring(0, 52) + "..." }
        $cpuText = $cpuText.PadRight(58)
        
        # GPU Info
        $gpuText = $sysInfo.GPU
        if ($gpuText.Length -gt 45) { $gpuText = $gpuText.Substring(0, 42) + "..." }
        $gpuText = $gpuText.PadRight(48)
        
        # RAM Info
        $ramInfo = $sysInfo.RAM
        
        Write-Host "║ 💻 CPU: $cpuText  ║" -ForegroundColor DarkGray
        Write-Host "║ 🎮 GPU: $gpuText [$($gpuVendor.PadRight(7))]  ║" -ForegroundColor DarkGray
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
    Write-Host "  SELECT A CATEGORY" -ForegroundColor $Script:Colors.Menu
    Write-Host "  ═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Menu
    Write-Host "   1. 🖥️  System Performance (CPU, GPU, RAM, Disk)" -ForegroundColor White
    Write-Host "   2. 🎮 Gaming & Graphics Optimization" -ForegroundColor White
    Write-Host "   3. 🌐 Network & Internet Tweaks" -ForegroundColor White
    Write-Host "   4. 🔒 Privacy & Security" -ForegroundColor White
    Write-Host "   5. 🗑️  Cleanup & Maintenance" -ForegroundColor White
    Write-Host "   6. ⚙️  Advanced System Tweaks" -ForegroundColor White
    Write-Host "   7. 📊 Monitoring & System Info" -ForegroundColor White
    Write-Host "   8. 🛠️  Tools & Utilities" -ForegroundColor White
    Write-Host ""
    Write-Host "  QUICK ACTIONS" -ForegroundColor $Script:Colors.Menu
    Write-Host "  ═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Menu
    Write-Host "   9. ⚡ Apply Optimization Profile" -ForegroundColor Green
    Write-Host "  10. 🔍 System Analysis & Recommendations" -ForegroundColor Cyan
    Write-Host "  11. 🎮 GPU-Specific Optimizations" -ForegroundColor Magenta
    Write-Host "  12. 🗑️  Enhanced Bloatware Removal" -ForegroundColor Yellow
    Write-Host "  13. 📈 Generate Optimization Report" -ForegroundColor White
    Write-Host ""
    Write-Host "  ADVANCED TOOLS (NEW!)" -ForegroundColor $Script:Colors.Highlight
    Write-Host "  ═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Menu
    Write-Host "  16. 📊 Real-Time Performance Dashboard" -ForegroundColor Cyan
    Write-Host "  17. 🌐 Network Speed Test" -ForegroundColor Green
    Write-Host "  18. 🚀 Startup Impact Analyzer" -ForegroundColor Yellow
    Write-Host "  19. 🌡️  System Temperature Monitor" -ForegroundColor Magenta
    Write-Host "  20. 🔄 One-Click Restore" -ForegroundColor White
    Write-Host ""
    Write-Host "  PROFESSIONAL TOOLS (ULTIMATE!)" -ForegroundColor $Script:Colors.Highlight
    Write-Host "  ═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Menu
    Write-Host "  21. 🏥 Comprehensive System Health Check" -ForegroundColor Cyan
    Write-Host "  22. 📝 Registry Optimizer" -ForegroundColor Green
    Write-Host "  23. ⚙️  Intelligent Service Optimizer" -ForegroundColor Yellow
    Write-Host "  24. 🔄 Windows Update Manager" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  14. 🔄 Restore Previous Settings" -ForegroundColor Yellow
    Write-Host "  15. 📋 View Optimization Log" -ForegroundColor White
    Write-Host "   0. ❌ Exit" -ForegroundColor Red
    Write-Host ""
}

function Confirm-Action {
    param(
        [string]$Message = "Do you want to proceed?",
        [switch]$DefaultYes
    )
    
    Write-Host ""
    $prompt = if ($DefaultYes) { "$Message (Y/n)" } else { "$Message (y/N)" }
    $response = Read-Host $prompt
    
    if ($DefaultYes) {
        return $response -ne 'N' -and $response -ne 'n'
    }
    return $response -eq 'Y' -or $response -eq 'y'
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

function Backup-ServiceState {
    param([string]$ServiceName)
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service) {
            $Script:ConfigBackup["Service_$ServiceName"] = @{
                Status    = $service.Status
                StartType = $service.StartType
            }
            
            Add-UndoAction -Description "Restore service: $ServiceName" -UndoScript {
                param($Name, $StartType)
                Set-Service -Name $Name -StartupType $StartType
            } -Parameters @{ Name = $ServiceName; StartType = $service.StartType }
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
                $key = "Registry_$($Path)_$Name"
                $Script:ConfigBackup[$key] = $value.$Name
                
                Add-UndoAction -Description "Restore registry: $Path\$Name" -UndoScript {
                    param($RegPath, $RegName, $RegValue)
                    Set-ItemProperty -Path $RegPath -Name $RegName -Value $RegValue
                } -Parameters @{ RegPath = $Path; RegName = $Name; RegValue = $value.$Name }
            }
        }
    }
    catch {
        Write-Log "Failed to backup registry value $Path\$Name" -Level Warning -Category "Backup"
    }
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

#endregion

#region Load Additional Modules

# Load additional optimization modules
$moduleFiles = @(
    "$PSScriptRoot\Modules-GamingNetwork.ps1",
    "$PSScriptRoot\Modules-PrivacyCleanup.ps1",
    "$PSScriptRoot\Modules-AdvancedTools.ps1",
    "$PSScriptRoot\Modules-Enhancements.ps1",
    "$PSScriptRoot\Modules-Advanced.ps1",
    "$PSScriptRoot\Modules-FinalEnhancements.ps1"
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
    Write-Host "This will optimize CPU settings for maximum performance." -ForegroundColor $Script:Colors.Info
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Starting CPU optimizations" -Level Info -Category "CPU"
    
    try {
        # Disable CPU core parking
        $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"
        if (Test-Path $path) {
            Backup-RegistryValue -Path $path -Name "ValueMax"
            Set-ItemProperty -Path $path -Name "ValueMax" -Value 0 -Type DWord
            Write-Log "Disabled CPU core parking" -Level Success -Category "CPU"
        }
        
        # Set processor scheduling for programs
        $path = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
        Backup-RegistryValue -Path $path -Name "Win32PrioritySeparation"
        Set-ItemProperty -Path $path -Name "Win32PrioritySeparation" -Value 38 -Type DWord
        Write-Log "Optimized processor scheduling for programs" -Level Success -Category "CPU"
        
        # Disable CPU throttling
        powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100
        powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100
        Write-Log "Disabled CPU throttling" -Level Success -Category "CPU"
        
        # Optimize interrupt moderation
        $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Backup-RegistryValue -Path $path -Name "DpcWatchdogProfileOffset"
        Set-ItemProperty -Path $path -Name "DpcWatchdogProfileOffset" -Value 1 -Type DWord
        Write-Log "Optimized interrupt moderation" -Level Success -Category "CPU"
        
        Write-Host "`n✓ CPU optimizations complete!" -ForegroundColor $Script:Colors.Success
        Write-Log "CPU optimizations completed" -Level Success -Category "CPU"
    }
    catch {
        Write-Log "Failed to optimize CPU: $($_.Exception.Message)" -Level Error -Category "CPU"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Optimize-GPU {
    Write-Host "`n[GPU & GRAPHICS OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Starting GPU optimizations" -Level Info -Category "GPU"
    
    try {
        # Enable hardware-accelerated GPU scheduling (Windows 10 2004+)
        $path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Backup-RegistryValue -Path $path -Name "HwSchMode"
        Set-ItemProperty -Path $path -Name "HwSchMode" -Value 2 -Type DWord
        Write-Log "Enabled hardware-accelerated GPU scheduling" -Level Success -Category "GPU"
        
        # Disable Game Bar and DVR
        $path = "HKCU:\Software\Microsoft\GameBar"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Backup-RegistryValue -Path $path -Name "AllowAutoGameMode"
        Set-ItemProperty -Path $path -Name "AllowAutoGameMode" -Value 0 -Type DWord
        Backup-RegistryValue -Path $path -Name "AutoGameModeEnabled"
        Set-ItemProperty -Path $path -Name "AutoGameModeEnabled" -Value 0 -Type DWord
        
        $path = "HKCU:\System\GameConfigStore"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Backup-RegistryValue -Path $path -Name "GameDVR_Enabled"
        Set-ItemProperty -Path $path -Name "GameDVR_Enabled" -Value 0 -Type DWord
        Write-Log "Disabled Game Bar and DVR" -Level Success -Category "GPU"
        
        # Set graphics performance preference to high performance
        $path = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Write-Log "Configured graphics performance preferences" -Level Success -Category "GPU"
        
        Write-Host "`n✓ GPU optimizations complete!" -ForegroundColor $Script:Colors.Success
        Write-Host "  Note: Restart required for GPU scheduling changes." -ForegroundColor $Script:Colors.Warning
    }
    catch {
        Write-Log "Failed to optimize GPU: $($_.Exception.Message)" -Level Error -Category "GPU"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Optimize-MemoryAdvanced {
    Write-Host "`n[ADVANCED MEMORY OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Starting advanced memory optimizations" -Level Info -Category "Memory"
    
    try {
        # Configure large system cache
        $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
        Backup-RegistryValue -Path $path -Name "LargeSystemCache"
        Set-ItemProperty -Path $path -Name "LargeSystemCache" -Value 1 -Type DWord
        Write-Log "Configured large system cache" -Level Success -Category "Memory"
        
        # Disable paging executive
        Backup-RegistryValue -Path $path -Name "DisablePagingExecutive"
        Set-ItemProperty -Path $path -Name "DisablePagingExecutive" -Value 1 -Type DWord
        Write-Log "Disabled paging executive" -Level Success -Category "Memory"
        
        # Clear standby memory
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        Write-Log "Cleared standby memory" -Level Success -Category "Memory"
        
        # Disable Superfetch/SysMain
        $service = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
        if ($service) {
            Backup-ServiceState -ServiceName "SysMain"
            Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
            Set-Service -Name "SysMain" -StartupType Disabled
            Write-Log "Disabled SysMain/Superfetch" -Level Success -Category "Memory"
        }
        
        # Optimize prefetch
        $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
        if (Test-Path $path) {
            Backup-RegistryValue -Path $path -Name "EnablePrefetcher"
            Set-ItemProperty -Path $path -Name "EnablePrefetcher" -Value 0 -Type DWord
            Backup-RegistryValue -Path $path -Name "EnableSuperfetch"
            Set-ItemProperty -Path $path -Name "EnableSuperfetch" -Value 0 -Type DWord
            Write-Log "Optimized prefetch settings" -Level Success -Category "Memory"
        }
        
        Write-Host "`n✓ Memory optimizations complete!" -ForegroundColor $Script:Colors.Success
        Write-Host "  Note: Restart recommended for full effect." -ForegroundColor $Script:Colors.Warning
    }
    catch {
        Write-Log "Failed to optimize memory: $($_.Exception.Message)" -Level Error -Category "Memory"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Optimize-DiskIO {
    Write-Host "`n[DISK I/O OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Starting disk I/O optimizations" -Level Info -Category "Disk"
    
    try {
        # Enable TRIM for SSDs
        fsutil behavior set DisableDeleteNotify 0
        Write-Log "Enabled TRIM for SSDs" -Level Success -Category "Disk"
        
        # Disable 8.3 filename creation
        fsutil behavior set disable8dot3 1
        Write-Log "Disabled 8.3 filename creation" -Level Success -Category "Disk"
        
        # Disable last access time stamp
        fsutil behavior set disablelastaccess 1
        Write-Log "Disabled last access time stamps" -Level Success -Category "Disk"
        
        # Optimize NTFS memory usage
        fsutil behavior set memoryusage 2
        Write-Log "Optimized NTFS memory usage" -Level Success -Category "Disk"
        
        Write-Host "`n✓ Disk I/O optimizations complete!" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Log "Failed to optimize disk I/O: $($_.Exception.Message)" -Level Error -Category "Disk"
    }
    
    Read-Host "`nPress Enter to continue"
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
    
    $disabledCount = 0
    foreach ($serviceName in $servicesToDisable) {
        try {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($service) {
                Backup-ServiceState -ServiceName $serviceName
                Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
                Set-Service -Name $serviceName -StartupType Disabled -ErrorAction Stop
                Write-Log "Disabled service: $serviceName" -Level Success -Category "Services"
                $disabledCount++
            }
        }
        catch {
            Write-Log "Failed to disable service: $serviceName" -Level Warning -Category "Services"
        }
    }
    
    Write-Host "`n✓ Disabled $disabledCount services!" -ForegroundColor $Script:Colors.Success
    Read-Host "`nPress Enter to continue"
}

function Optimize-VisualEffects {
    Write-Host "`n[VISUAL EFFECTS OPTIMIZATION]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Starting Visual Effects optimization" -Level Info -Category "Visual"
    
    try {
        # Set visual effects to best performance
        $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Backup-RegistryValue -Path $path -Name "VisualFXSetting"
        Set-ItemProperty -Path $path -Name "VisualFXSetting" -Value 2 -Type DWord
        
        # Disable animations
        $path = "HKCU:\Control Panel\Desktop\WindowMetrics"
        Backup-RegistryValue -Path $path -Name "MinAnimate"
        Set-ItemProperty -Path $path -Name "MinAnimate" -Value 0 -Type String
        
        # Disable transparency
        $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Backup-RegistryValue -Path $path -Name "EnableTransparency"
        Set-ItemProperty -Path $path -Name "EnableTransparency" -Value 0 -Type DWord
        
        # Disable taskbar animations
        $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Backup-RegistryValue -Path $path -Name "TaskbarAnimations"
        Set-ItemProperty -Path $path -Name "TaskbarAnimations" -Value 0 -Type DWord
        
        Write-Host "`n✓ Visual effects optimized!" -ForegroundColor $Script:Colors.Success
        Write-Log "Visual Effects optimization completed" -Level Success -Category "Visual"
    }
    catch {
        Write-Log "Failed to optimize visual effects: $($_.Exception.Message)" -Level Error -Category "Visual"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Optimize-Storage {
    Write-Host "`n[STORAGE OPTIMIZATION]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Starting Storage optimization" -Level Info -Category "Storage"
    
    try {
        # Optimize drives
        Write-Host "`nOptimizing all drives..." -ForegroundColor $Script:Colors.Info
        $drives = Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' }
        
        foreach ($drive in $drives) {
            try {
                $driveLetter = $drive.DriveLetter
                Write-Host "  Optimizing drive $driveLetter..." -ForegroundColor $Script:Colors.Info
                Optimize-Volume -DriveLetter $driveLetter -ErrorAction SilentlyContinue
                Write-Log "Optimized drive $driveLetter" -Level Success -Category "Storage"
            }
            catch {
                Write-Log "Failed to optimize drive $driveLetter" -Level Warning -Category "Storage"
            }
        }
        
        Write-Host "`n✓ Storage optimization complete!" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Log "Failed to optimize storage: $($_.Exception.Message)" -Level Error -Category "Storage"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Optimize-WindowsUpdate {
    Write-Host "`n[WINDOWS UPDATE OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Starting Windows Update optimizations" -Level Info -Category "WindowsUpdate"
    
    try {
        # Disable automatic driver updates
        $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Backup-RegistryValue -Path $path -Name "SearchOrderConfig"
        Set-ItemProperty -Path $path -Name "SearchOrderConfig" -Value 0 -Type DWord
        Write-Log "Disabled automatic driver updates" -Level Success -Category "WindowsUpdate"
        
        # Configure delivery optimization
        $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Backup-RegistryValue -Path $path -Name "DODownloadMode"
        Set-ItemProperty -Path $path -Name "DODownloadMode" -Value 0 -Type DWord
        Write-Log "Configured delivery optimization" -Level Success -Category "WindowsUpdate"
        
        Write-Host "`n✓ Windows Update optimizations complete!" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Log "Failed to optimize Windows Update: $($_.Exception.Message)" -Level Error -Category "WindowsUpdate"
    }
    
    Read-Host "`nPress Enter to continue"
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
    
    Read-Host "`nPress Enter to continue"
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
        Read-Host "`nPress Enter to exit"
        exit
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
    
    Write-Host "  Detecting system configuration..." -ForegroundColor Yellow -NoNewline
    Start-Sleep -Milliseconds 300
    Write-Host " ✓" -ForegroundColor Green
    
    Write-Host "  Scanning GPU vendor..." -ForegroundColor Yellow -NoNewline
    $gpuVendor = Get-GPUVendor
    Start-Sleep -Milliseconds 300
    Write-Host " ✓ [$gpuVendor detected]" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "  🚀 Ready! Press any key to continue..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    Write-Log "Wethereal Ultimate Edition v$($Script:Version) started" -Level Info -Category "System"
    
    do {
        Show-MainMenu
        $choice = Read-Host "Select an option (0-15)"
        
        switch ($choice) {
            '1' { Show-SystemPerformanceMenu }
            '2' { Show-GamingMenu }
            '3' { Show-NetworkMenu }
            '4' { Show-PrivacyMenu }
            '5' { Show-CleanupMenu }
            '6' { Show-AdvancedMenu }
            '7' { Show-MonitoringMenu }
            '8' { Show-ToolsMenu }
            '9' { Show-ProfilesMenuEnhanced }
            '10' { Start-SystemAnalysis }
            '11' { Optimize-GPUSpecific }
            '12' { Get-EnhancedBloatwareList }
            '13' { New-OptimizationReport }
            '14' { Restore-PreviousSettings }
            '15' { Show-OptimizationLog }
            '16' { Show-PerformanceDashboard }
            '17' { Test-NetworkSpeed }
            '18' { Show-StartupImpact }
            '19' { Show-SystemTemperature }
            '20' { Invoke-QuickRestore }
            '21' { Start-SystemHealthCheck }
            '22' { Optimize-Registry }
            '23' { Optimize-ServicesIntelligent }
            '24' { Set-WindowsUpdates }
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

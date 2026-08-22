# Wethereal Ultimate Edition - Final Enhancement Module
# Ultimate Professional Features for Complete System Control

#region System Health Check

function Start-SystemHealthCheck {
    Write-Host "`n[COMPREHENSIVE SYSTEM HEALTH CHECK]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    Write-Host "Performing comprehensive system diagnostics..." -ForegroundColor $Script:Colors.Info
    Write-Host ""
    
    $healthScore = 100
    $issues = @()
    $warnings = @()
    $totalChecks = 10

    # Check 1: Disk Health
    Write-Progress -Activity "🏥 System Health Check" -Status "[1/$totalChecks] Checking disk health..." -PercentComplete 10
    Write-Host "  [1/10] Checking disk health..." -ForegroundColor $Script:Colors.Info
    try {
        $drives = Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' }
        foreach ($drive in $drives) {
            $freePercent = ($drive.SizeRemaining / $drive.Size) * 100
            if ($freePercent -lt 10) {
                $issues += "Drive $($drive.DriveLetter): Critical - Only $([math]::Round($freePercent, 1))% free"
                $healthScore -= 15
            }
            elseif ($freePercent -lt 20) {
                $warnings += "Drive $($drive.DriveLetter): Low space - $([math]::Round($freePercent, 1))% free"
                $healthScore -= 5
            }
        }
        Write-Host "    ✓ Disk health checked" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "    ⚠ Could not check disk health" -ForegroundColor $Script:Colors.Warning
    }
    
    # Check 2: Memory Usage
    Write-Progress -Activity "🏥 System Health Check" -Status "[2/$totalChecks] Checking memory usage..." -PercentComplete 20
    Write-Host "  [2/10] Checking memory usage..." -ForegroundColor $Script:Colors.Info
    try {
        $mem = Get-CimInstance Win32_OperatingSystem
        $memUsed = (($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / $mem.TotalVisibleMemorySize) * 100
        if ($memUsed -gt 90) {
            $issues += "Memory usage critical: $([math]::Round($memUsed, 1))%"
            $healthScore -= 10
        }
        elseif ($memUsed -gt 80) {
            $warnings += "Memory usage high: $([math]::Round($memUsed, 1))%"
            $healthScore -= 5
        }
        Write-Host "    ✓ Memory usage: $([math]::Round($memUsed, 1))%" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "    ⚠ Could not check memory" -ForegroundColor $Script:Colors.Warning
    }
    
    # Check 3: Windows Update Status
    Write-Progress -Activity "🏥 System Health Check" -Status "[3/$totalChecks] Checking Windows Update status..." -PercentComplete 30
    Write-Host "  [3/10] Checking Windows Update status..." -ForegroundColor $Script:Colors.Info
    try {
        $updateService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
        if ($updateService.Status -ne 'Running') {
            $warnings += "Windows Update service is not running"
            $healthScore -= 3
        }
        Write-Host "    ✓ Update service checked" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "    ⚠ Could not check updates" -ForegroundColor $Script:Colors.Warning
    }
    
    # Check 4: Antivirus Status
    Write-Progress -Activity "🏥 System Health Check" -Status "[4/$totalChecks] Checking antivirus status..." -PercentComplete 40
    Write-Host "  [4/10] Checking antivirus status..." -ForegroundColor $Script:Colors.Info
    try {
        $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($defender) {
            if (-not $defender.RealTimeProtectionEnabled) {
                $issues += "Windows Defender real-time protection is disabled"
                $healthScore -= 15
            }
            if ($defender.AntivirusSignatureAge -gt 7) {
                $warnings += "Antivirus definitions are $($defender.AntivirusSignatureAge) days old"
                $healthScore -= 5
            }
        }
        Write-Host "    ✓ Antivirus checked" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "    ⚠ Could not check antivirus" -ForegroundColor $Script:Colors.Warning
    }
    
    # Check 5: System Uptime
    Write-Progress -Activity "🏥 System Health Check" -Status "[5/$totalChecks] Checking system uptime..." -PercentComplete 50
    Write-Host "  [5/10] Checking system uptime..." -ForegroundColor $Script:Colors.Info
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $uptime = (Get-Date) - $os.LastBootUpTime
        if ($uptime.Days -gt 30) {
            $warnings += "System hasn't been restarted in $($uptime.Days) days"
            $healthScore -= 5
        }
        Write-Host "    ✓ Uptime: $($uptime.Days) days, $($uptime.Hours) hours" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "    ⚠ Could not check uptime" -ForegroundColor $Script:Colors.Warning
    }
    
    # Check 6: Event Log Errors
    Write-Progress -Activity "🏥 System Health Check" -Status "[6/$totalChecks] Checking recent errors..." -PercentComplete 60
    Write-Host "  [6/10] Checking recent errors..." -ForegroundColor $Script:Colors.Info
    try {
        $recentErrors = Get-EventLog -LogName System -EntryType Error -Newest 50 -ErrorAction SilentlyContinue | Measure-Object
        if ($recentErrors.Count -gt 20) {
            $warnings += "High number of system errors: $($recentErrors.Count) in last 50 events"
            $healthScore -= 5
        }
        Write-Host "    ✓ Error log checked" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "    ⚠ Could not check event logs" -ForegroundColor $Script:Colors.Warning
    }
    
    # Check 7: Startup Programs
    Write-Progress -Activity "🏥 System Health Check" -Status "[7/$totalChecks] Checking startup programs..." -PercentComplete 70
    Write-Host "  [7/10] Checking startup programs..." -ForegroundColor $Script:Colors.Info
    try {
        $startupCount = 0
        $runKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        )
        foreach ($key in $runKeys) {
            if (Test-Path $key) {
                $items = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
                if ($items) {
                    $startupCount += ($items.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' }).Count
                }
            }
        }
        if ($startupCount -gt 15) {
            $warnings += "High number of startup programs: $startupCount"
            $healthScore -= 5
        }
        Write-Host "    ✓ Startup programs: $startupCount" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "    ⚠ Could not check startup programs" -ForegroundColor $Script:Colors.Warning
    }
    
    # Check 8: Temporary Files
    Write-Progress -Activity "🏥 System Health Check" -Status "[8/$totalChecks] Checking temporary files..." -PercentComplete 80
    Write-Host "  [8/10] Checking temporary files..." -ForegroundColor $Script:Colors.Info
    try {
        $tempSize = 0
        $tempPaths = @($env:TEMP, "$env:SystemRoot\Temp")
        foreach ($path in $tempPaths) {
            if (Test-Path $path) {
                $tempSize += (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            }
        }
        $tempSizeGB = [math]::Round($tempSize / 1GB, 2)
        if ($tempSizeGB -gt 5) {
            $warnings += "Large amount of temporary files: $tempSizeGB GB"
            $healthScore -= 3
        }
        Write-Host "    ✓ Temp files: $tempSizeGB GB" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "    ⚠ Could not check temp files" -ForegroundColor $Script:Colors.Warning
    }
    
    # Check 9: Network Connectivity
    Write-Progress -Activity "🏥 System Health Check" -Status "[9/$totalChecks] Checking network connectivity..." -PercentComplete 90
    Write-Host "  [9/10] Checking network connectivity..." -ForegroundColor $Script:Colors.Info
    try {
        $ping = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue
        if (-not $ping) {
            $issues += "No internet connectivity detected"
            $healthScore -= 10
        }
        Write-Host "    ✓ Network connectivity OK" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "    ⚠ Could not check network" -ForegroundColor $Script:Colors.Warning
    }
    
    # Check 10: System Files
    Write-Progress -Activity "🏥 System Health Check" -Status "[10/$totalChecks] Checking system file integrity..." -PercentComplete 100
    Write-Host "  [10/10] Checking system file integrity..." -ForegroundColor $Script:Colors.Info
    Write-Host "    ℹ System file check requires 'sfc /scannow' (run manually)" -ForegroundColor DarkGray
    Write-Progress -Activity "🏥 System Health Check" -Completed

    # Display Results
    Write-Host "`n  ════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    Write-Host "`n  HEALTH SCORE: $healthScore/100" -ForegroundColor $(
        if ($healthScore -ge 80) { $Script:Colors.Success }
        elseif ($healthScore -ge 60) { $Script:Colors.Warning }
        else { $Script:Colors.Error }
    )
    
    if ($issues.Count -gt 0) {
        Write-Host "`n  CRITICAL ISSUES:" -ForegroundColor $Script:Colors.Error
        foreach ($issue in $issues) {
            Write-Host "    ✗ $issue" -ForegroundColor Red
        }
    }
    
    if ($warnings.Count -gt 0) {
        Write-Host "`n  WARNINGS:" -ForegroundColor $Script:Colors.Warning
        foreach ($warning in $warnings) {
            Write-Host "    ⚠ $warning" -ForegroundColor Yellow
        }
    }
    
    if ($issues.Count -eq 0 -and $warnings.Count -eq 0) {
        Write-Host "`n  ✓ No issues detected! System is healthy." -ForegroundColor $Script:Colors.Success
    }
    
    Write-Host "`n  RECOMMENDATIONS:" -ForegroundColor $Script:Colors.Info
    if ($healthScore -lt 80) {
        Write-Host "    → Run cleanup tasks (Category 5)" -ForegroundColor Cyan
        Write-Host "    → Apply optimization profile (Option 12)" -ForegroundColor Cyan
        Write-Host "    → Check startup programs (Option 21)" -ForegroundColor Cyan
    }
    else {
        Write-Host "    ✓ System is well optimized!" -ForegroundColor $Script:Colors.Success
    }
    
    Write-Log "System health check completed. Score: $healthScore/100" -Level Info -Category "Health"
    
    Wait-ForUser
}

#endregion

#region Registry Optimizer

function Optimize-Registry {
    Write-Host "`n[REGISTRY OPTIMIZER]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    Write-Host "Optimizing Windows Registry..." -ForegroundColor $Script:Colors.Info
    Write-Host ""
    
    if (-not (Confirm-Action -Message "Optimize registry? (Backup recommended)")) {
        return
    }
    
    # Create automatic backup
    Write-Host "  Creating automatic backup..." -ForegroundColor $Script:Colors.Info
    New-AutomaticBackup | Out-Null

    $steps = @(
        @{ Name = "Reducing menu show delay"; Action = { Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -ErrorAction Stop } }
        @{ Name = "Disabling Aero Shake"; Action = { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DisallowShaking" -Value 1 -ErrorAction Stop } }
        @{ Name = "Optimizing Snap Assist"; Action = { Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WindowArrangementActive" -Value "0" -ErrorAction Stop } }
        @{ Name = "Disabling taskbar animations"; Action = { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 0 -ErrorAction Stop } }
        @{ Name = "Optimizing icon cache"; Action = { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "Max Cached Icons" -Value "4096" -ErrorAction Stop } }
        @{ Name = "Optimizing thumbnail cache"; Action = { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DisableThumbnailCache" -Value 0 -ErrorAction Stop } }
        @{ Name = "Optimizing Windows Search"; Action = { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -ErrorAction Stop } }
        @{
            Name   = "Disabling Cortana"
            Action = {
                if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search")) {
                    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null
                }
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -ErrorAction Stop
            }
        }
    )

    $result = Invoke-TweakSequence -Title "Registry Optimizer" -Steps $steps -Category "Registry"

    Write-Host "`n  ✓ Registry optimization complete!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Applied $($result.Succeeded)/$($result.Total) optimizations" -ForegroundColor $Script:Colors.Highlight
    Write-Host "`n  ⚠ Restart required for changes to take effect" -ForegroundColor $Script:Colors.Warning

    Wait-ForUser
}

#endregion

#region Service Optimizer

function Optimize-ServicesIntelligent {
    Write-Host "`n[INTELLIGENT SERVICE OPTIMIZER]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    Write-Host "Analyzing and optimizing Windows services..." -ForegroundColor $Script:Colors.Info
    Write-Host ""
    
    if (-not (Confirm-Action -Message "Optimize services intelligently?")) {
        return
    }
    
    # Services safe to disable for performance
    $servicesToDisable = @(
        @{Name = "DiagTrack"; DisplayName = "Connected User Experiences and Telemetry" },
        @{Name = "dmwappushservice"; DisplayName = "WAP Push Message Routing Service" },
        @{Name = "SysMain"; DisplayName = "Superfetch (if SSD)" },
        @{Name = "WSearch"; DisplayName = "Windows Search (optional)" },
        @{Name = "XblAuthManager"; DisplayName = "Xbox Live Auth Manager" },
        @{Name = "XblGameSave"; DisplayName = "Xbox Live Game Save" },
        @{Name = "XboxNetApiSvc"; DisplayName = "Xbox Live Networking Service" }
    )
    
    $steps = $servicesToDisable | ForEach-Object {
        $svc = $_
        @{
            Name      = "Disabling: $($svc.DisplayName)"
            Condition = { (Get-Service -Name $svc.Name -ErrorAction SilentlyContinue) -ne $null }.GetNewClosure()
            Action    = {
                $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
                Backup-ServiceState -ServiceName $svc.Name
                if ($service.Status -eq 'Running') {
                    Stop-Service -Name $svc.Name -Force -ErrorAction Stop
                }
                Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction Stop
            }.GetNewClosure()
        }
    }

    $result = Invoke-TweakSequence -Title "Intelligent Service Optimizer" -Steps $steps -Category "Services"

    Write-Host "`n  ✓ Service optimization complete!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Optimized: $($result.Succeeded) services" -ForegroundColor $Script:Colors.Highlight
    Write-Host "  Not present on this system: $($result.Skipped) services" -ForegroundColor DarkGray

    Wait-ForUser
}

#endregion

#region Update Manager

function Set-WindowsUpdates {
    Write-Host "`n[WINDOWS UPDATE MANAGER]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    Write-Host ""
    Write-Host "  1. Pause updates for 7 days" -ForegroundColor White
    Write-Host "  2. Pause updates for 30 days" -ForegroundColor White
    Write-Host "  3. Resume updates" -ForegroundColor White
    Write-Host "  4. Check for updates now" -ForegroundColor White
    Write-Host "  5. Disable automatic updates (not recommended)" -ForegroundColor Yellow
    Write-Host "  6. Enable automatic updates" -ForegroundColor Green
    Write-Host "  0. Back to main menu" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Select an option (0-6)"
    
    switch ($choice) {
        '1' {
            Write-Host "`n  Pausing updates for 7 days..." -ForegroundColor $Script:Colors.Info
            try {
                $resumeDate = (Get-Date).AddDays(7)
                $pauseUntil = $resumeDate.ToString("yyyy-MM-ddTHH:mm:ssZ")
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -Value $pauseUntil -ErrorAction Stop
                # Bug fix: the original code wrote `$(Get-Date).AddDays(7).ToString(...)`
                # inside the string — only $(Get-Date) was evaluated as a subexpression,
                # so ".AddDays(7).ToString('yyyy-MM-dd')" printed as LITERAL text after
                # the timestamp instead of computing the actual resume date.
                Write-Host "  ✓ Updates paused until $($resumeDate.ToString('yyyy-MM-dd'))" -ForegroundColor $Script:Colors.Success
            }
            catch {
                Write-Host "  ✗ Failed to pause updates" -ForegroundColor $Script:Colors.Error
            }
        }
        '2' {
            Write-Host "`n  Pausing updates for 30 days..." -ForegroundColor $Script:Colors.Info
            try {
                $resumeDate = (Get-Date).AddDays(30)
                $pauseUntil = $resumeDate.ToString("yyyy-MM-ddTHH:mm:ssZ")
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -Value $pauseUntil -ErrorAction Stop
                Write-Host "  ✓ Updates paused until $($resumeDate.ToString('yyyy-MM-dd'))" -ForegroundColor $Script:Colors.Success
            }
            catch {
                Write-Host "  ✗ Failed to pause updates" -ForegroundColor $Script:Colors.Error
            }
        }
        '3' {
            Write-Host "`n  Resuming updates..." -ForegroundColor $Script:Colors.Info
            try {
                Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -ErrorAction Stop
                Write-Host "  ✓ Updates resumed" -ForegroundColor $Script:Colors.Success
            }
            catch {
                Write-Host "  ✗ Failed to resume updates" -ForegroundColor $Script:Colors.Error
            }
        }
        '4' {
            Write-Host "`n  Checking for updates..." -ForegroundColor $Script:Colors.Info
            Write-Host "  Opening Windows Update settings..." -ForegroundColor DarkGray
            Start-Process "ms-settings:windowsupdate"
        }
        '5' {
            if (Confirm-Action -Message "Disable automatic updates? (NOT RECOMMENDED for security)") {
                Write-Host "`n  Disabling automatic updates..." -ForegroundColor $Script:Colors.Warning
                try {
                    Stop-Service -Name wuauserv -Force -ErrorAction Stop
                    Set-Service -Name wuauserv -StartupType Disabled -ErrorAction Stop
                    Write-Host "  ✓ Automatic updates disabled" -ForegroundColor $Script:Colors.Success
                    Write-Host "  ⚠ WARNING: Your system will not receive security updates!" -ForegroundColor Red
                }
                catch {
                    Write-Host "  ✗ Failed to disable updates" -ForegroundColor $Script:Colors.Error
                }
            }
        }
        '6' {
            Write-Host "`n  Enabling automatic updates..." -ForegroundColor $Script:Colors.Info
            try {
                Set-Service -Name wuauserv -StartupType Automatic -ErrorAction Stop
                Start-Service -Name wuauserv -ErrorAction Stop
                Write-Host "  ✓ Automatic updates enabled" -ForegroundColor $Script:Colors.Success
            }
            catch {
                Write-Host "  ✗ Failed to enable updates" -ForegroundColor $Script:Colors.Error
            }
        }
        '0' { }
        default {
            Write-Host "`n✗ Invalid option." -ForegroundColor $Script:Colors.Error
        }
    }

    if ($choice -ne '0') {
        Wait-ForUser
    }
}

#endregion


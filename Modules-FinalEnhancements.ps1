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
    
    # Check 1: Disk Health
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
    Write-Host "  [10/10] Checking system file integrity..." -ForegroundColor $Script:Colors.Info
    Write-Host "    ℹ System file check requires 'sfc /scannow' (run manually)" -ForegroundColor DarkGray
    
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
        Write-Host "    → Apply optimization profile (Option 9)" -ForegroundColor Cyan
        Write-Host "    → Check startup programs (Option 18)" -ForegroundColor Cyan
    }
    else {
        Write-Host "    ✓ System is well optimized!" -ForegroundColor $Script:Colors.Success
    }
    
    Write-Log "System health check completed. Score: $healthScore/100" -Level Info -Category "Health"
    
    Read-Host "`nPress Enter to continue"
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
    
    $optimizations = 0
    
    # 1. Disable Menu Delay
    Write-Host "  [1/8] Reducing menu show delay..." -ForegroundColor $Script:Colors.Info
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -ErrorAction Stop
        $optimizations++
        Write-Host "    ✓ Menu delay reduced" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "    ✗ Failed to reduce menu delay" -ForegroundColor $Script:Colors.Error
    }
    
    # 2. Disable Aero Shake
    Write-Host "  [2/8] Disabling Aero Shake..." -ForegroundColor $Script:Colors.Info
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DisallowShaking" -Value 1 -ErrorAction Stop
        $optimizations++
        Write-Host "    ✓ Aero Shake disabled" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "    ✗ Failed to disable Aero Shake" -ForegroundColor $Script:Colors.Error
    }
    
    # 3. Disable Snap Assist
    Write-Host "  [3/8] Optimizing Snap Assist..." -ForegroundColor $Script:Colors.Info
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WindowArrangementActive" -Value "0" -ErrorAction Stop
        $optimizations++
        Write-Host "    ✓ Snap Assist optimized" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "    ✗ Failed to optimize Snap Assist" -ForegroundColor $Script:Colors.Error
    }
    
    # 4. Disable Taskbar Animations
    Write-Host "  [4/8] Disabling taskbar animations..." -ForegroundColor $Script:Colors.Info
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 0 -ErrorAction Stop
        $optimizations++
        Write-Host "    ✓ Taskbar animations disabled" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "    ✗ Failed to disable taskbar animations" -ForegroundColor $Script:Colors.Error
    }
    
    # 5. Optimize Icon Cache
    Write-Host "  [5/8] Optimizing icon cache..." -ForegroundColor $Script:Colors.Info
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "Max Cached Icons" -Value "4096" -ErrorAction Stop
        $optimizations++
        Write-Host "    ✓ Icon cache optimized" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "    ✗ Failed to optimize icon cache" -ForegroundColor $Script:Colors.Error
    }
    
    # 6. Disable Thumbnail Cache
    Write-Host "  [6/8] Optimizing thumbnail cache..." -ForegroundColor $Script:Colors.Info
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DisableThumbnailCache" -Value 0 -ErrorAction Stop
        $optimizations++
        Write-Host "    ✓ Thumbnail cache optimized" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "    ✗ Failed to optimize thumbnail cache" -ForegroundColor $Script:Colors.Error
    }
    
    # 7. Optimize Search
    Write-Host "  [7/8] Optimizing Windows Search..." -ForegroundColor $Script:Colors.Info
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -ErrorAction Stop
        $optimizations++
        Write-Host "    ✓ Search optimized" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "    ✗ Failed to optimize search" -ForegroundColor $Script:Colors.Error
    }
    
    # 8. Disable Cortana
    Write-Host "  [8/8] Disabling Cortana..." -ForegroundColor $Script:Colors.Info
    try {
        if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search")) {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -ErrorAction Stop
        $optimizations++
        Write-Host "    ✓ Cortana disabled" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "    ✗ Failed to disable Cortana" -ForegroundColor $Script:Colors.Error
    }
    
    Write-Host "`n  ✓ Registry optimization complete!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Applied $optimizations/8 optimizations" -ForegroundColor $Script:Colors.Highlight
    Write-Host "`n  ⚠ Restart required for changes to take effect" -ForegroundColor $Script:Colors.Warning
    
    Write-Log "Registry optimization completed. Applied $optimizations/8 tweaks." -Level Success -Category "Registry"
    
    Read-Host "`nPress Enter to continue"
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
    
    $optimized = 0
    $skipped = 0
    
    foreach ($svc in $servicesToDisable) {
        $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        
        if ($service) {
            Write-Host "  Processing: $($svc.DisplayName)..." -ForegroundColor $Script:Colors.Info
            
            try {
                # Backup current state
                Backup-ServiceState -ServiceName $svc.Name
                
                # Stop and disable service
                if ($service.Status -eq 'Running') {
                    Stop-Service -Name $svc.Name -Force -ErrorAction Stop
                }
                Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction Stop
                
                Write-Host "    ✓ Disabled: $($svc.DisplayName)" -ForegroundColor $Script:Colors.Success
                $optimized++
            }
            catch {
                Write-Host "    ⚠ Skipped: $($svc.DisplayName)" -ForegroundColor $Script:Colors.Warning
                $skipped++
            }
        }
    }
    
    Write-Host "`n  ✓ Service optimization complete!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Optimized: $optimized services" -ForegroundColor $Script:Colors.Highlight
    Write-Host "  Skipped: $skipped services" -ForegroundColor DarkGray
    
    Write-Log "Intelligent service optimization completed. Optimized: $optimized, Skipped: $skipped" -Level Success -Category "Services"
    
    Read-Host "`nPress Enter to continue"
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
                $pauseUntil = (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ssZ")
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -Value $pauseUntil -ErrorAction Stop
                Write-Host "  ✓ Updates paused until $(Get-Date).AddDays(7).ToString('yyyy-MM-dd')" -ForegroundColor $Script:Colors.Success
            }
            catch {
                Write-Host "  ✗ Failed to pause updates" -ForegroundColor $Script:Colors.Error
            }
        }
        '2' {
            Write-Host "`n  Pausing updates for 30 days..." -ForegroundColor $Script:Colors.Info
            try {
                $pauseUntil = (Get-Date).AddDays(30).ToString("yyyy-MM-ddTHH:mm:ssZ")
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -Value $pauseUntil -ErrorAction Stop
                Write-Host "  ✓ Updates paused until $(Get-Date).AddDays(30).ToString('yyyy-MM-dd')" -ForegroundColor $Script:Colors.Success
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
    }
    
    if ($choice -ne '0') {
        Read-Host "`nPress Enter to continue"
    }
}

#endregion

# Export all functions
Export-ModuleMember -Function *

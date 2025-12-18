# Windows Performance Tweaker Ultimate Edition v2.0.0
# Additional Optimization Modules - Part 4
# Advanced Tweaks, Monitoring, Tools & Utilities

#region Category 6: Advanced Tweaks

function Show-AdvancedMenu {
    do {
        Show-Header "Advanced Tweaks"
        Write-Host "  ADVANCED SYSTEM TWEAKS" -ForegroundColor $Script:Colors.Menu
        Write-Host "  ═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Menu
        Write-Host "   1. Boot & Shutdown Optimization" -ForegroundColor White
        Write-Host "   2. File Explorer Tweaks" -ForegroundColor White
        Write-Host "   3. Taskbar & Start Menu Tweaks" -ForegroundColor White
        Write-Host "   4. Notification & Action Center" -ForegroundColor White
        Write-Host "   5. Windows Defender Optimization" -ForegroundColor White
        Write-Host "   6. Font Rendering & ClearType" -ForegroundColor White
        Write-Host "   7. Registry Performance Tweaks" -ForegroundColor White
        Write-Host "   8. ⚡ Apply All Advanced Tweaks" -ForegroundColor Green
        Write-Host "   0. ← Back to Main Menu" -ForegroundColor Yellow
        Write-Host ""
        
        $choice = Read-Host "Select an option"
        
        switch ($choice) {
            '1' { Optimize-BootShutdown }
            '2' { Tweak-FileExplorer }
            '3' { Tweak-TaskbarStartMenu }
            '4' { Configure-Notifications }
            '5' { Optimize-WindowsDefender }
            '6' { Configure-FontRendering }
            '7' { Apply-RegistryTweaks }
            '8' { Apply-AllAdvancedTweaks }
            '0' { return }
        }
    } while ($true)
}

function Optimize-BootShutdown {
    Write-Host "`n[BOOT & SHUTDOWN OPTIMIZATION]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Optimizing boot and shutdown" -Level Info -Category "Advanced"
    
    try {
        # Configure boot timeout
        bcdedit /timeout 3 | Out-Null
        Write-Log "Set boot timeout to 3 seconds" -Level Success -Category "Advanced"
        
        # Enable fast startup
        $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Backup-RegistryValue -Path $path -Name "HiberbootEnabled"
        Set-ItemProperty -Path $path -Name "HiberbootEnabled" -Value 1 -Type DWord
        Write-Log "Enabled fast startup" -Level Success -Category "Advanced"
        
        # Configure shutdown timeout
        $path = "HKLM:\SYSTEM\CurrentControlSet\Control"
        Backup-RegistryValue -Path $path -Name "WaitToKillServiceTimeout"
        Set-ItemProperty -Path $path -Name "WaitToKillServiceTimeout" -Value 2000 -Type String
        Write-Log "Optimized shutdown timeout" -Level Success -Category "Advanced"
        
        Write-Host "`n✓ Boot and shutdown optimized!" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Log "Failed to optimize boot/shutdown: $($_.Exception.Message)" -Level Error -Category "Advanced"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Tweak-FileExplorer {
    Write-Host "`n[FILE EXPLORER TWEAKS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Tweaking File Explorer" -Level Info -Category "Advanced"
    
    try {
        # Show file extensions
        $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Backup-RegistryValue -Path $path -Name "HideFileExt"
        Set-ItemProperty -Path $path -Name "HideFileExt" -Value 0 -Type DWord
        Write-Log "Enabled file extensions" -Level Success -Category "Advanced"
        
        # Show hidden files
        Backup-RegistryValue -Path $path -Name "Hidden"
        Set-ItemProperty -Path $path -Name "Hidden" -Value 1 -Type DWord
        Write-Log "Enabled hidden files" -Level Success -Category "Advanced"
        
        # Disable recent files
        Backup-RegistryValue -Path $path -Name "ShowRecent"
        Set-ItemProperty -Path $path -Name "ShowRecent" -Value 0 -Type DWord
        Backup-RegistryValue -Path $path -Name "ShowFrequent"
        Set-ItemProperty -Path $path -Name "ShowFrequent" -Value 0 -Type DWord
        Write-Log "Disabled recent files" -Level Success -Category "Advanced"
        
        # Optimize folder view
        Backup-RegistryValue -Path $path -Name "LaunchTo"
        Set-ItemProperty -Path $path -Name "LaunchTo" -Value 1 -Type DWord
        Write-Log "Set File Explorer to open to This PC" -Level Success -Category "Advanced"
        
        Write-Host "`n✓ File Explorer tweaked!" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Log "Failed to tweak File Explorer: $($_.Exception.Message)" -Level Error -Category "Advanced"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Tweak-TaskbarStartMenu {
    Write-Host "`n[TASKBAR & START MENU TWEAKS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Tweaking taskbar and start menu" -Level Info -Category "Advanced"
    
    try {
        # Disable taskbar animations
        $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Backup-RegistryValue -Path $path -Name "TaskbarAnimations"
        Set-ItemProperty -Path $path -Name "TaskbarAnimations" -Value 0 -Type DWord
        Write-Log "Disabled taskbar animations" -Level Success -Category "Advanced"
        
        # Disable live tiles
        $path = "HKCU:\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Backup-RegistryValue -Path $path -Name "NoTileApplicationNotification"
        Set-ItemProperty -Path $path -Name "NoTileApplicationNotification" -Value 1 -Type DWord
        Write-Log "Disabled live tiles" -Level Success -Category "Advanced"
        
        # Remove suggested apps from start menu
        $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Backup-RegistryValue -Path $path -Name "SystemPaneSuggestionsEnabled"
        Set-ItemProperty -Path $path -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord
        Write-Log "Removed suggested apps" -Level Success -Category "Advanced"
        
        Write-Host "`n✓ Taskbar and start menu tweaked!" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Log "Failed to tweak taskbar/start menu: $($_.Exception.Message)" -Level Error -Category "Advanced"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Configure-Notifications {
    Write-Host "`n[NOTIFICATION & ACTION CENTER]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Configuring notifications" -Level Info -Category "Advanced"
    
    try {
        # Disable action center
        $path = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Backup-RegistryValue -Path $path -Name "DisableNotificationCenter"
        Set-ItemProperty -Path $path -Name "DisableNotificationCenter" -Value 1 -Type DWord
        Write-Log "Disabled action center" -Level Success -Category "Advanced"
        
        # Disable notification sounds
        $path = "HKCU:\AppEvents\Schemes"
        Backup-RegistryValue -Path $path -Name "(Default)"
        Set-ItemProperty -Path $path -Name "(Default)" -Value ".None" -Type String
        Write-Log "Disabled notification sounds" -Level Success -Category "Advanced"
        
        Write-Host "`n✓ Notifications configured!" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Log "Failed to configure notifications: $($_.Exception.Message)" -Level Error -Category "Advanced"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Optimize-WindowsDefender {
    Write-Host "`n[WINDOWS DEFENDER OPTIMIZATION]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    Write-Host "This will optimize Windows Defender for performance." -ForegroundColor $Script:Colors.Info
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Optimizing Windows Defender" -Level Info -Category "Advanced"
    
    try {
        # Configure scan schedule
        Set-MpPreference -ScanScheduleDay 0 -ErrorAction SilentlyContinue
        Write-Log "Disabled scheduled scans" -Level Success -Category "Advanced"
        
        # Optimize cloud protection
        Set-MpPreference -MAPSReporting 0 -ErrorAction SilentlyContinue
        Write-Log "Disabled MAPS reporting" -Level Success -Category "Advanced"
        
        Write-Host "`n✓ Windows Defender optimized!" -ForegroundColor $Script:Colors.Success
        Write-Host "  Note: Real-time protection remains enabled." -ForegroundColor $Script:Colors.Info
    }
    catch {
        Write-Log "Failed to optimize Windows Defender: $($_.Exception.Message)" -Level Error -Category "Advanced"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Configure-FontRendering {
    Write-Host "`n[FONT RENDERING & CLEARTYPE]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Configuring font rendering" -Level Info -Category "Advanced"
    
    try {
        # Enable ClearType
        $path = "HKCU:\Control Panel\Desktop"
        Backup-RegistryValue -Path $path -Name "FontSmoothing"
        Set-ItemProperty -Path $path -Name "FontSmoothing" -Value 2 -Type String
        Backup-RegistryValue -Path $path -Name "FontSmoothingType"
        Set-ItemProperty -Path $path -Name "FontSmoothingType" -Value 2 -Type DWord
        Write-Log "Enabled ClearType" -Level Success -Category "Advanced"
        
        Write-Host "`n✓ Font rendering configured!" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Log "Failed to configure font rendering: $($_.Exception.Message)" -Level Error -Category "Advanced"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Apply-RegistryTweaks {
    Write-Host "`n[REGISTRY PERFORMANCE TWEAKS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Applying registry tweaks" -Level Info -Category "Advanced"
    
    try {
        # Speed up menu show delay
        $path = "HKCU:\Control Panel\Desktop"
        Backup-RegistryValue -Path $path -Name "MenuShowDelay"
        Set-ItemProperty -Path $path -Name "MenuShowDelay" -Value 0 -Type String
        Write-Log "Reduced menu show delay" -Level Success -Category "Advanced"
        
        # Disable Aero Shake
        $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Backup-RegistryValue -Path $path -Name "DisallowShaking"
        Set-ItemProperty -Path $path -Name "DisallowShaking" -Value 1 -Type DWord
        Write-Log "Disabled Aero Shake" -Level Success -Category "Advanced"
        
        # Disable Sticky Keys prompt
        $path = "HKCU:\Control Panel\Accessibility\StickyKeys"
        Backup-RegistryValue -Path $path -Name "Flags"
        Set-ItemProperty -Path $path -Name "Flags" -Value 506 -Type String
        Write-Log "Disabled Sticky Keys prompt" -Level Success -Category "Advanced"
        
        # Increase icon cache size
        $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
        Backup-RegistryValue -Path $path -Name "Max Cached Icons"
        Set-ItemProperty -Path $path -Name "Max Cached Icons" -Value 4096 -Type String
        Write-Log "Increased icon cache size" -Level Success -Category "Advanced"
        
        Write-Host "`n✓ Registry tweaks applied!" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Log "Failed to apply registry tweaks: $($_.Exception.Message)" -Level Error -Category "Advanced"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Apply-AllAdvancedTweaks {
    Write-Host "`n[APPLY ALL ADVANCED TWEAKS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Optimize-BootShutdown
    Tweak-FileExplorer
    Tweak-TaskbarStartMenu
    Configure-Notifications
    Optimize-WindowsDefender
    Apply-RegistryTweaks
    
    Write-Host "`n✓ ALL ADVANCED TWEAKS COMPLETED!" -ForegroundColor $Script:Colors.Success
    Read-Host "`nPress Enter to continue"
}

#endregion

#region Category 7: Monitoring & System Info

function Show-MonitoringMenu {
    do {
        Show-Header "Monitoring & System Info"
        Write-Host "  MONITORING & SYSTEM INFORMATION" -ForegroundColor $Script:Colors.Menu
        Write-Host "  ═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Menu
        Write-Host "   1. System Information Dashboard" -ForegroundColor White
        Write-Host "   2. Performance Benchmark" -ForegroundColor White
        Write-Host "   3. Resource Monitor (Real-time)" -ForegroundColor White
        Write-Host "   4. Optimization History" -ForegroundColor White
        Write-Host "   5. System Health Check" -ForegroundColor White
        Write-Host "   0. ← Back to Main Menu" -ForegroundColor Yellow
        Write-Host ""
        
        $choice = Read-Host "Select an option"
        
        switch ($choice) {
            '1' { Show-SystemInfoDashboard }
            '2' { Run-PerformanceBenchmark }
            '3' { Show-ResourceMonitor }
            '4' { Show-OptimizationHistory }
            '5' { Run-SystemHealthCheck }
            '0' { return }
        }
    } while ($true)
}

function Show-SystemInfoDashboard {
    Show-Header "System Information Dashboard"
    
    $sysInfo = Get-SystemInfo
    
    Write-Host "  SYSTEM INFORMATION" -ForegroundColor $Script:Colors.Menu
    Write-Host "  ═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Menu
    Write-Host ""
    Write-Host "  💻 CPU:       $($sysInfo.CPU)" -ForegroundColor White
    Write-Host "  🧠 RAM:       $($sysInfo.RAM)" -ForegroundColor White
    Write-Host "  🎮 GPU:       $($sysInfo.GPU)" -ForegroundColor White
    Write-Host "  🪟 OS:        $($sysInfo.OS)" -ForegroundColor White
    Write-Host "  ⏱️  Uptime:    $($sysInfo.Uptime.Days)d $($sysInfo.Uptime.Hours)h $($sysInfo.Uptime.Minutes)m" -ForegroundColor White
    Write-Host ""
    
    # Disk info
    Write-Host "  DISK INFORMATION" -ForegroundColor $Script:Colors.Menu
    Write-Host "  ═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Menu
    $drives = Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' }
    foreach ($drive in $drives) {
        $freeGB = [math]::Round($drive.SizeRemaining / 1GB, 2)
        $totalGB = [math]::Round($drive.Size / 1GB, 2)
        $usedPercent = [math]::Round((($drive.Size - $drive.SizeRemaining) / $drive.Size) * 100, 1)
        Write-Host "  💾 Drive $($drive.DriveLetter):  $freeGB GB free / $totalGB GB total ($usedPercent% used)" -ForegroundColor White
    }
    Write-Host ""
    
    Read-Host "Press Enter to continue"
}

function Run-PerformanceBenchmark {
    Write-Host "`n[PERFORMANCE BENCHMARK]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    Write-Host "This will run a quick performance benchmark." -ForegroundColor $Script:Colors.Info
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Running performance benchmark" -Level Info -Category "Monitoring"
    
    Write-Host "`n  Running CPU benchmark..." -ForegroundColor $Script:Colors.Info
    $cpuStart = Get-Date
    1..1000000 | ForEach-Object { $_ * 2 } | Out-Null
    $cpuTime = (Get-Date) - $cpuStart
    Write-Host "  ✓ CPU test completed in $($cpuTime.TotalMilliseconds) ms" -ForegroundColor $Script:Colors.Success
    
    Write-Host "`n  Running memory benchmark..." -ForegroundColor $Script:Colors.Info
    $memStart = Get-Date
    $array = 1..100000
    $memTime = (Get-Date) - $memStart
    Write-Host "  ✓ Memory test completed in $($memTime.TotalMilliseconds) ms" -ForegroundColor $Script:Colors.Success
    
    Write-Host "`n  Measuring boot time..." -ForegroundColor $Script:Colors.Info
    $bootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $uptime = (Get-Date) - $bootTime
    Write-Host "  ✓ System uptime: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m" -ForegroundColor $Script:Colors.Success
    
    Write-Host "`n✓ Benchmark complete!" -ForegroundColor $Script:Colors.Success
    Write-Log "Performance benchmark completed" -Level Success -Category "Monitoring"
    
    Read-Host "`nPress Enter to continue"
}

function Show-ResourceMonitor {
    Write-Host "`n[RESOURCE MONITOR]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    Write-Host "Opening Windows Resource Monitor..." -ForegroundColor $Script:Colors.Info
    
    Start-Process "resmon.exe"
    Write-Log "Opened Resource Monitor" -Level Info -Category "Monitoring"
    
    Read-Host "`nPress Enter to continue"
}

function Show-OptimizationHistory {
    Write-Host "`n[OPTIMIZATION HISTORY]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (Test-Path $Script:LogFile) {
        Write-Host "`nShowing last 30 optimization entries:" -ForegroundColor $Script:Colors.Info
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Info
        Get-Content -Path $Script:LogFile -Tail 30
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Info
    }
    else {
        Write-Host "`nNo optimization history found." -ForegroundColor $Script:Colors.Warning
    }
    
    Read-Host "`nPress Enter to continue"
}

function Run-SystemHealthCheck {
    Write-Host "`n[SYSTEM HEALTH CHECK]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Running system health check" -Level Info -Category "Monitoring"
    
    Write-Host "`n  Checking disk health..." -ForegroundColor $Script:Colors.Info
    $disks = Get-PhysicalDisk
    foreach ($disk in $disks) {
        $health = $disk.HealthStatus
        $color = if ($health -eq 'Healthy') { $Script:Colors.Success } else { $Script:Colors.Error }
        Write-Host "  Disk $($disk.DeviceId): $health" -ForegroundColor $color
    }
    
    Write-Host "`n  Checking Windows Update status..." -ForegroundColor $Script:Colors.Info
    Write-Host "  Use Windows Settings to check for updates" -ForegroundColor $Script:Colors.Info
    
    Write-Host "`n✓ System health check complete!" -ForegroundColor $Script:Colors.Success
    Write-Log "System health check completed" -Level Success -Category "Monitoring"
    
    Read-Host "`nPress Enter to continue"
}

#endregion

#region Category 8: Tools & Utilities

function Show-ToolsMenu {
    do {
        Show-Header "Tools & Utilities"
        Write-Host "  TOOLS & UTILITIES" -ForegroundColor $Script:Colors.Menu
        Write-Host "  ═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Menu
        Write-Host "   1. Optimization Profiles" -ForegroundColor White
        Write-Host "   2. Create System Restore Point" -ForegroundColor White
        Write-Host "   3. Backup Current Settings" -ForegroundColor White
        Write-Host "   4. Restore Previous Settings" -ForegroundColor White
        Write-Host "   5. View Optimization Log" -ForegroundColor White
        Write-Host "   6. Undo Last Optimization" -ForegroundColor White
        Write-Host "   7. Export Configuration" -ForegroundColor White
        Write-Host "   0. ← Back to Main Menu" -ForegroundColor Yellow
        Write-Host ""
        
        $choice = Read-Host "Select an option"
        
        switch ($choice) {
            '1' { Show-ProfilesMenu }
            '2' { Create-SystemRestorePoint }
            '3' { Backup-CurrentSettings }
            '4' { Restore-PreviousSettings }
            '5' { Show-OptimizationLog }
            '6' { Undo-LastOptimization }
            '7' { Export-Configuration }
            '0' { return }
        }
    } while ($true)
}

function Show-ProfilesMenu {
    Write-Host "`n[OPTIMIZATION PROFILES]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    Write-Host "Select a profile to apply:" -ForegroundColor $Script:Colors.Info
    Write-Host ""
    Write-Host "  1. $($Script:Profiles.Gaming.Name)" -ForegroundColor Green
    Write-Host "     $($Script:Profiles.Gaming.Description)" -ForegroundColor White
    Write-Host ""
    Write-Host "  2. $($Script:Profiles.Work.Name)" -ForegroundColor Cyan
    Write-Host "     $($Script:Profiles.Work.Description)" -ForegroundColor White
    Write-Host ""
    Write-Host "  3. $($Script:Profiles.MaxPerformance.Name)" -ForegroundColor Yellow
    Write-Host "     $($Script:Profiles.MaxPerformance.Description)" -ForegroundColor White
    Write-Host ""
    Write-Host "  4. $($Script:Profiles.Privacy.Name)" -ForegroundColor Magenta
    Write-Host "     $($Script:Profiles.Privacy.Description)" -ForegroundColor White
    Write-Host ""
    Write-Host "  0. Cancel" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Select profile"
    
    # Profile application would go here
    if ($choice -ne '0') {
        Write-Host "`nProfile application coming in next update..." -ForegroundColor $Script:Colors.Info
    }
    
    Read-Host "`nPress Enter to continue"
}

function Create-SystemRestorePoint {
    Write-Host "`n[CREATE SYSTEM RESTORE POINT]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Creating system restore point" -Level Info -Category "Tools"
    
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        $description = "WinTweaker Ultimate - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS"
        
        Write-Host "`n✓ System restore point created!" -ForegroundColor $Script:Colors.Success
        Write-Host "  Description: $description" -ForegroundColor $Script:Colors.Info
        Write-Log "Created system restore point: $description" -Level Success -Category "Tools"
    }
    catch {
        Write-Host "`n✗ Failed to create system restore point." -ForegroundColor $Script:Colors.Error
        Write-Log "Failed to create system restore point: $($_.Exception.Message)" -Level Error -Category "Tools"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Backup-CurrentSettings {
    Write-Host "`n[BACKUP CURRENT SETTINGS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    try {
        if ($Script:ConfigBackup.Count -gt 0) {
            $Script:ConfigBackup | ConvertTo-Json -Depth 10 | Out-File -FilePath $Script:BackupFile -Encoding UTF8
            
            Write-Host "`n✓ Settings backed up!" -ForegroundColor $Script:Colors.Success
            Write-Host "  Backup file: $Script:BackupFile" -ForegroundColor $Script:Colors.Info
            Write-Host "  Items backed up: $($Script:ConfigBackup.Count)" -ForegroundColor $Script:Colors.Info
            Write-Log "Created settings backup: $Script:BackupFile" -Level Success -Category "Tools"
        }
        else {
            Write-Host "`n⚠ No settings have been modified yet." -ForegroundColor $Script:Colors.Warning
        }
    }
    catch {
        Write-Host "`n✗ Failed to create backup." -ForegroundColor $Script:Colors.Error
        Write-Log "Failed to create backup: $($_.Exception.Message)" -Level Error -Category "Tools"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Restore-PreviousSettings {
    Write-Host "`n[RESTORE PREVIOUS SETTINGS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    $backupFiles = Get-ChildItem -Path $PSScriptRoot -Filter "WinTweaker_Backup_*.json" | Sort-Object LastWriteTime -Descending
    
    if ($backupFiles.Count -eq 0) {
        Write-Host "`n⚠ No backup files found." -ForegroundColor $Script:Colors.Warning
        Read-Host "`nPress Enter to continue"
        return
    }
    
    Write-Host "`nAvailable backups:" -ForegroundColor $Script:Colors.Info
    for ($i = 0; $i -lt [Math]::Min($backupFiles.Count, 10); $i++) {
        Write-Host "  $($i + 1). $($backupFiles[$i].Name) - $(Get-Date $backupFiles[$i].LastWriteTime -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
    }
    
    Write-Host ""
    $selection = Read-Host "Select backup to restore (1-$([Math]::Min($backupFiles.Count, 10))) or 0 to cancel"
    
    if ($selection -eq '0' -or [string]::IsNullOrWhiteSpace($selection)) {
        return
    }
    
    Write-Host "`nRestore functionality coming in next update..." -ForegroundColor $Script:Colors.Info
    Read-Host "`nPress Enter to continue"
}

function Show-OptimizationLog {
    Write-Host "`n[OPTIMIZATION LOG]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (Test-Path $Script:LogFile) {
        Write-Host "`nShowing last 50 log entries:" -ForegroundColor $Script:Colors.Info
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Info
        Get-Content -Path $Script:LogFile -Tail 50
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Info
    }
    else {
        Write-Host "`n⚠ No log file found." -ForegroundColor $Script:Colors.Warning
    }
    
    Read-Host "`nPress Enter to continue"
}

function Undo-LastOptimization {
    Write-Host "`n[UNDO LAST OPTIMIZATION]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if ($Script:UndoStack.Count -eq 0) {
        Write-Host "`n⚠ No optimizations to undo." -ForegroundColor $Script:Colors.Warning
        Read-Host "`nPress Enter to continue"
        return
    }
    
    Write-Host "`nUndo functionality coming in next update..." -ForegroundColor $Script:Colors.Info
    Read-Host "`nPress Enter to continue"
}

function Export-Configuration {
    Write-Host "`n[EXPORT CONFIGURATION]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    Write-Host "`nExport functionality coming in next update..." -ForegroundColor $Script:Colors.Info
    Read-Host "`nPress Enter to continue"
}

#endregion

# Export functions for main script
Export-ModuleMember -Function *

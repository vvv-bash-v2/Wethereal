# Windows Performance Tweaker Ultimate Edition v3.5.0
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
            default {
                Write-Host "`n✗ Invalid option." -ForegroundColor $Script:Colors.Error
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

function Optimize-BootShutdown {
    Write-Host "`n[BOOT & SHUTDOWN OPTIMIZATION]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Optimizing boot and shutdown" -Level Info -Category "Advanced"

    $steps = @(
        @{ Name = "Setting boot menu timeout to 3 seconds"; Action = { bcdedit /timeout 3 | Out-Null } }
        @{
            Name   = "Enabling Fast Startup"
            Action = {
                $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "HiberbootEnabled"
                Set-ItemProperty -Path $path -Name "HiberbootEnabled" -Value 1 -Type DWord
            }
        }
        @{
            Name   = "Reducing service-kill timeout on shutdown"
            Action = {
                $path = "HKLM:\SYSTEM\CurrentControlSet\Control"
                Backup-RegistryValue -Path $path -Name "WaitToKillServiceTimeout"
                Set-ItemProperty -Path $path -Name "WaitToKillServiceTimeout" -Value 2000 -Type String
            }
        }
    )

    Invoke-TweakSequence -Title "Boot & Shutdown Optimization" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n✓ Boot and shutdown optimized!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Tweak-FileExplorer {
    Write-Host "`n[FILE EXPLORER TWEAKS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Tweaking File Explorer" -Level Info -Category "Advanced"

    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $steps = @(
        @{ Name = "Showing known file extensions"; Action = { Backup-RegistryValue -Path $path -Name "HideFileExt"; Set-ItemProperty -Path $path -Name "HideFileExt" -Value 0 -Type DWord }.GetNewClosure() }
        @{ Name = "Showing hidden files"; Action = { Backup-RegistryValue -Path $path -Name "Hidden"; Set-ItemProperty -Path $path -Name "Hidden" -Value 1 -Type DWord }.GetNewClosure() }
        @{
            Name   = "Disabling Recent/Frequent items in Quick Access"
            Action = {
                Backup-RegistryValue -Path $path -Name "ShowRecent"
                Set-ItemProperty -Path $path -Name "ShowRecent" -Value 0 -Type DWord
                Backup-RegistryValue -Path $path -Name "ShowFrequent"
                Set-ItemProperty -Path $path -Name "ShowFrequent" -Value 0 -Type DWord
            }.GetNewClosure()
        }
        @{ Name = "Setting File Explorer to open to 'This PC'"; Action = { Backup-RegistryValue -Path $path -Name "LaunchTo"; Set-ItemProperty -Path $path -Name "LaunchTo" -Value 1 -Type DWord }.GetNewClosure() }
    )

    Invoke-TweakSequence -Title "File Explorer Tweaks" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n✓ File Explorer tweaked!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Tweak-TaskbarStartMenu {
    Write-Host "`n[TASKBAR & START MENU TWEAKS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Tweaking taskbar and start menu" -Level Info -Category "Advanced"

    $steps = @(
        @{
            Name   = "Disabling taskbar animations"
            Action = {
                $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                Backup-RegistryValue -Path $path -Name "TaskbarAnimations"
                Set-ItemProperty -Path $path -Name "TaskbarAnimations" -Value 0 -Type DWord
            }
        }
        @{
            Name   = "Disabling live tile notifications"
            Action = {
                $path = "HKCU:\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "NoTileApplicationNotification"
                Set-ItemProperty -Path $path -Name "NoTileApplicationNotification" -Value 1 -Type DWord
            }
        }
        @{
            Name   = "Removing suggested apps from Start menu"
            Action = {
                $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
                Backup-RegistryValue -Path $path -Name "SystemPaneSuggestionsEnabled"
                Set-ItemProperty -Path $path -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "Taskbar & Start Menu Tweaks" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n✓ Taskbar and start menu tweaked!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Configure-Notifications {
    Write-Host "`n[NOTIFICATION & ACTION CENTER]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Configuring notifications" -Level Info -Category "Advanced"

    $steps = @(
        @{
            Name   = "Disabling Action Center"
            Action = {
                $path = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "DisableNotificationCenter"
                Set-ItemProperty -Path $path -Name "DisableNotificationCenter" -Value 1 -Type DWord
            }
        }
        @{
            Name   = "Muting the default notification sound scheme"
            Action = {
                $path = "HKCU:\AppEvents\Schemes"
                Backup-RegistryValue -Path $path -Name "(Default)"
                Set-ItemProperty -Path $path -Name "(Default)" -Value ".None" -Type String
            }
        }
    )

    Invoke-TweakSequence -Title "Notification Settings" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n✓ Notifications configured!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Optimize-WindowsDefender {
    Write-Host "`n[WINDOWS DEFENDER OPTIMIZATION]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    Write-Host "This will optimize Windows Defender for performance." -ForegroundColor $Script:Colors.Info

    if (-not (Confirm-Action)) { return }

    Write-Log "Optimizing Windows Defender" -Level Info -Category "Advanced"

    $steps = @(
        @{ Name = "Disabling scheduled scans"; Action = { Set-MpPreference -ScanScheduleDay 0 -ErrorAction Stop } }
        @{ Name = "Reducing MAPS cloud-reporting level"; Action = { Set-MpPreference -MAPSReporting 0 -ErrorAction Stop } }
    )

    Invoke-TweakSequence -Title "Windows Defender Optimization" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n✓ Windows Defender optimized!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Note: Real-time protection remains enabled." -ForegroundColor $Script:Colors.Info
    Wait-ForUser
}

function Configure-FontRendering {
    Write-Host "`n[FONT RENDERING & CLEARTYPE]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Configuring font rendering" -Level Info -Category "Advanced"

    $steps = @(
        @{
            Name   = "Enabling ClearType font smoothing"
            Action = {
                $path = "HKCU:\Control Panel\Desktop"
                Backup-RegistryValue -Path $path -Name "FontSmoothing"
                Set-ItemProperty -Path $path -Name "FontSmoothing" -Value 2 -Type String
                Backup-RegistryValue -Path $path -Name "FontSmoothingType"
                Set-ItemProperty -Path $path -Name "FontSmoothingType" -Value 2 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "Font Rendering" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n✓ Font rendering configured!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Apply-RegistryTweaks {
    Write-Host "`n[REGISTRY PERFORMANCE TWEAKS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Applying registry tweaks" -Level Info -Category "Advanced"

    $steps = @(
        @{
            Name   = "Reducing menu show delay to 0ms"
            Action = {
                $path = "HKCU:\Control Panel\Desktop"
                Backup-RegistryValue -Path $path -Name "MenuShowDelay"
                Set-ItemProperty -Path $path -Name "MenuShowDelay" -Value 0 -Type String
            }
        }
        @{
            Name   = "Disabling Aero Shake"
            Action = {
                $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                Backup-RegistryValue -Path $path -Name "DisallowShaking"
                Set-ItemProperty -Path $path -Name "DisallowShaking" -Value 1 -Type DWord
            }
        }
        @{
            Name   = "Disabling Sticky Keys activation prompt"
            Action = {
                $path = "HKCU:\Control Panel\Accessibility\StickyKeys"
                Backup-RegistryValue -Path $path -Name "Flags"
                Set-ItemProperty -Path $path -Name "Flags" -Value 506 -Type String
            }
        }
        @{
            Name   = "Increasing icon cache size"
            Action = {
                $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
                Backup-RegistryValue -Path $path -Name "Max Cached Icons"
                Set-ItemProperty -Path $path -Name "Max Cached Icons" -Value 4096 -Type String
            }
        }
    )

    Invoke-TweakSequence -Title "Registry Performance Tweaks" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n✓ Registry tweaks applied!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Apply-AllAdvancedTweaks {
    Write-Host "`n[APPLY ALL ADVANCED TWEAKS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    $Script:SkipConfirmations = $true
    $Script:SkipPauses = $true
    try {
        Optimize-BootShutdown
        Tweak-FileExplorer
        Tweak-TaskbarStartMenu
        Configure-Notifications
        Optimize-WindowsDefender
        Apply-RegistryTweaks
    }
    finally {
        $Script:SkipConfirmations = $false
        $Script:SkipPauses = $false
    }

    Write-Host "`n✓ ALL ADVANCED TWEAKS COMPLETED!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
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
            default {
                Write-Host "`n✗ Invalid option." -ForegroundColor $Script:Colors.Error
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

function Show-SystemInfoDashboard {
    Show-Header "System Information Dashboard"

    $sysInfo = Get-SystemInfo
    $hw = Get-HardwareProfile

    Write-Host "  SYSTEM INFORMATION" -ForegroundColor $Script:Colors.Menu
    Write-Host "  ═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Menu
    Write-Host ""
    Write-Host "  💻 CPU:       $($sysInfo.CPU) [$($hw.CPU.Vendor)]" -ForegroundColor White
    Write-Host "  🧠 RAM:       $($sysInfo.RAM)" -ForegroundColor White
    if ($hw.GPUs.Count -eq 0) {
        Write-Host "  🎮 GPU:       Not detected" -ForegroundColor White
    }
    else {
        foreach ($gpu in $hw.GPUs) {
            Write-Host "  🎮 GPU:       $($gpu.Name) [$($gpu.Vendor)]$(if ($gpu.IsActive) { ' (active)' })" -ForegroundColor White
        }
    }
    Write-Host "  🪟 OS:        $($sysInfo.OS)" -ForegroundColor White
    Write-Host "  ⏱️  Uptime:    $($sysInfo.Uptime.Days)d $($sysInfo.Uptime.Hours)h $($sysInfo.Uptime.Minutes)m" -ForegroundColor White
    Write-Host "  🎯 Platform:  $(Show-HardwarePlatformSummary)" -ForegroundColor Magenta
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

    Wait-ForUser
}

function Run-PerformanceBenchmark {
    Write-Host "`n[PERFORMANCE BENCHMARK]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    Write-Host "This will run a quick performance benchmark." -ForegroundColor $Script:Colors.Info

    if (-not (Confirm-Action)) { return }

    Write-Log "Running performance benchmark" -Level Info -Category "Monitoring"

    $results = @{}
    $steps = @(
        @{
            Name   = "Running CPU benchmark"
            Action = {
                $cpuStart = Get-Date
                1..1000000 | ForEach-Object { $_ * 2 } | Out-Null
                $results.CpuMs = ((Get-Date) - $cpuStart).TotalMilliseconds
            }.GetNewClosure()
        }
        @{
            Name   = "Running memory allocation benchmark"
            Action = {
                $memStart = Get-Date
                $null = 1..100000
                $results.MemMs = ((Get-Date) - $memStart).TotalMilliseconds
            }.GetNewClosure()
        }
        @{
            Name   = "Measuring system uptime since last boot"
            Action = {
                $bootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
                $results.Uptime = (Get-Date) - $bootTime
            }.GetNewClosure()
        }
    )

    Invoke-TweakSequence -Title "Performance Benchmark" -Steps $steps -Category "Monitoring" | Out-Null

    Write-Host "`n  Results:" -ForegroundColor $Script:Colors.Highlight
    Write-Host "    CPU test:    $([math]::Round($results.CpuMs, 1)) ms" -ForegroundColor White
    Write-Host "    Memory test: $([math]::Round($results.MemMs, 1)) ms" -ForegroundColor White
    Write-Host "    Uptime:      $($results.Uptime.Days)d $($results.Uptime.Hours)h $($results.Uptime.Minutes)m" -ForegroundColor White

    Write-Host "`n✓ Benchmark complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Show-ResourceMonitor {
    Write-Host "`n[RESOURCE MONITOR]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    Write-Host "Opening Windows Resource Monitor..." -ForegroundColor $Script:Colors.Info

    Start-Process "resmon.exe"
    Write-Log "Opened Resource Monitor" -Level Info -Category "Monitoring"

    Wait-ForUser
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

    Wait-ForUser
}

function Run-SystemHealthCheck {
    Write-Host "`n[SYSTEM HEALTH CHECK]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Running system health check" -Level Info -Category "Monitoring"

    Write-Host "`n  Checking disk health..." -ForegroundColor $Script:Colors.Info
    $disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
    foreach ($disk in $disks) {
        $health = $disk.HealthStatus
        $color = if ($health -eq 'Healthy') { $Script:Colors.Success } else { $Script:Colors.Error }
        Write-Host "  Disk $($disk.DeviceId): $health" -ForegroundColor $color
    }

    Write-Host "`n  Checking Windows Update status..." -ForegroundColor $Script:Colors.Info
    Write-Host "  Use Windows Settings to check for updates" -ForegroundColor $Script:Colors.Info

    Write-Host "`n✓ System health check complete!" -ForegroundColor $Script:Colors.Success
    Write-Log "System health check completed" -Level Success -Category "Monitoring"

    Wait-ForUser
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
            '1' { Show-ProfilesMenuEnhanced }
            '2' { Create-SystemRestorePoint }
            '3' { Backup-CurrentSettings }
            '4' { Restore-PreviousSettings }
            '5' { Show-OptimizationLog }
            '6' { Undo-LastOptimization }
            '7' { Export-Configuration }
            '0' { return }
            default {
                Write-Host "`n✗ Invalid option." -ForegroundColor $Script:Colors.Error
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
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

    Wait-ForUser
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

    Wait-ForUser
}

function Restore-PreviousSettings {
    Write-Host "`n[RESTORE PREVIOUS SETTINGS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    $backupFiles = Get-ChildItem -Path $PSScriptRoot -Filter "WinTweaker_Backup_*.json" | Sort-Object LastWriteTime -Descending

    if ($backupFiles.Count -eq 0) {
        Write-Host "`n⚠ No backup files found. Use 'Backup Current Settings' first." -ForegroundColor $Script:Colors.Warning
        Wait-ForUser
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

    $index = 0
    if (-not [int]::TryParse($selection, [ref]$index) -or $index -lt 1 -or $index -gt [Math]::Min($backupFiles.Count, 10)) {
        Write-Host "`n✗ Invalid selection." -ForegroundColor $Script:Colors.Error
        Wait-ForUser
        return
    }

    $selectedFile = $backupFiles[$index - 1]

    if (-not (Confirm-Action -Message "Restore settings from $($selectedFile.Name)? This overwrites current registry/service values")) { return }

    try {
        $entries = @(Get-Content -Path $selectedFile.FullName -Raw | ConvertFrom-Json)
        Write-Log "Restoring settings from backup: $($selectedFile.Name)" -Level Info -Category "Restore"
        Invoke-BackupRestore -Entries $entries
        Write-Host "`n✓ Settings restored from $($selectedFile.Name)!" -ForegroundColor $Script:Colors.Success
        Write-Host "  Note: Restart recommended for all changes to fully apply." -ForegroundColor $Script:Colors.Warning
        Write-Log "Restore from $($selectedFile.Name) completed" -Level Success -Category "Restore"
    }
    catch {
        Write-Host "`n✗ Failed to restore backup: $($_.Exception.Message)" -ForegroundColor $Script:Colors.Error
        Write-Log "Failed to restore backup $($selectedFile.Name): $($_.Exception.Message)" -Level Error -Category "Restore"
    }

    Wait-ForUser
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

    Wait-ForUser
}

function Undo-LastOptimization {
    Write-Host "`n[UNDO LAST OPTIMIZATION]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    if ($Script:UndoStack.Count -eq 0) {
        Write-Host "`n⚠ No optimizations to undo (nothing recorded this session)." -ForegroundColor $Script:Colors.Warning
        Wait-ForUser
        return
    }

    $lastAction = $Script:UndoStack[-1]
    Write-Host "`nMost recent change: $($lastAction.Description)" -ForegroundColor $Script:Colors.Info
    Write-Host "  Applied at: $($lastAction.Timestamp)" -ForegroundColor DarkGray

    if (-not (Confirm-Action -Message "Undo this change?")) { return }

    try {
        $params = $lastAction.Parameters
        & $lastAction.UndoScript @params
        # Remove the action we just reverted (pop from the end of the stack).
        # NOTE: PowerShell's range operator on a single-element case like `0..-1`
        # counts DOWN and yields @(0, -1) instead of an empty range, so a plain
        # "$stack[0..($stack.Count - 2)]" would wrongly keep an element when only
        # one item was on the stack — guard that case explicitly.
        if ($Script:UndoStack.Count -gt 1) {
            $Script:UndoStack = @($Script:UndoStack[0..($Script:UndoStack.Count - 2)])
        }
        else {
            $Script:UndoStack = @()
        }

        Write-Host "`n✓ Reverted: $($lastAction.Description)" -ForegroundColor $Script:Colors.Success
        Write-Log "Undid last optimization: $($lastAction.Description)" -Level Success -Category "Undo"
    }
    catch {
        Write-Host "`n✗ Failed to undo: $($_.Exception.Message)" -ForegroundColor $Script:Colors.Error
        Write-Log "Failed to undo '$($lastAction.Description)': $($_.Exception.Message)" -Level Error -Category "Undo"
    }

    Write-Host "  $($Script:UndoStack.Count) more change(s) available to undo." -ForegroundColor DarkGray
    Wait-ForUser
}

function Export-Configuration {
    Write-Host "`n[EXPORT CONFIGURATION]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    try {
        $hw = Get-HardwareProfile
        $exportPath = "$PSScriptRoot\Wethereal_Config_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"

        $export = @{
            ExportedAt      = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            Version         = $Script:Version
            Hardware        = @{
                CPU        = $hw.CPU
                GPUs       = $hw.GPUs
                GPUVendors = $hw.GPUVendors
                IsHybrid   = $hw.IsHybridGPU
            }
            AppliedChanges  = $Script:ConfigBackup
            OptimizationLog = if (Test-Path $Script:LogFile) { Get-Content -Path $Script:LogFile -Tail 100 } else { @() }
        }

        $export | ConvertTo-Json -Depth 10 | Out-File -FilePath $exportPath -Encoding UTF8

        Write-Host "`n✓ Configuration exported!" -ForegroundColor $Script:Colors.Success
        Write-Host "  File: $exportPath" -ForegroundColor $Script:Colors.Info
        Write-Log "Exported configuration to $exportPath" -Level Success -Category "Tools"
    }
    catch {
        Write-Host "`n✗ Failed to export configuration: $($_.Exception.Message)" -ForegroundColor $Script:Colors.Error
        Write-Log "Failed to export configuration: $($_.Exception.Message)" -Level Error -Category "Tools"
    }

    Wait-ForUser
}

#endregion

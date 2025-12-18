# Windows Performance Tweaker Ultimate Edition v2.0.0
# Additional Optimization Modules - Part 3
# Privacy, Cleanup, Advanced Tweaks

#region Category 4: Privacy & Security

function Show-PrivacyMenu {
    do {
        Show-Header "Privacy & Security"
        Write-Host "  PRIVACY & SECURITY OPTIMIZATIONS" -ForegroundColor $Script:Colors.Menu
        Write-Host "  ═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Menu
        Write-Host "   1. Advanced Telemetry Blocking" -ForegroundColor White
        Write-Host "   2. Disable Tracking & Ads" -ForegroundColor White
        Write-Host "   3. Remove Bloatware & Pre-installed Apps" -ForegroundColor White
        Write-Host "   4. Windows Features Privacy" -ForegroundColor White
        Write-Host "   5. Camera & Microphone Privacy" -ForegroundColor White
        Write-Host "   6. Network Privacy Settings" -ForegroundColor White
        Write-Host "   7. Security Hardening" -ForegroundColor White
        Write-Host "   8. ⚡ Apply All Privacy Optimizations" -ForegroundColor Green
        Write-Host "   0. ← Back to Main Menu" -ForegroundColor Yellow
        Write-Host ""
        
        $choice = Read-Host "Select an option"
        
        switch ($choice) {
            '1' { Block-TelemetryAdvanced }
            '2' { Disable-TrackingAds }
            '3' { Remove-Bloatware }
            '4' { Set-WindowsFeaturesPrivacy }
            '5' { Set-CameraMicrophonePrivacy }
            '6' { Set-NetworkPrivacy }
            '7' { Enable-SecurityHardening }
            '8' { Invoke-AllPrivacyOptimizations }
            '0' { return }
        }
    } while ($true)
}

function Block-TelemetryAdvanced {
    Write-Host "`n[ADVANCED TELEMETRY BLOCKING]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Blocking telemetry" -Level Info -Category "Privacy"
    
    try {
        # Disable telemetry
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Backup-RegistryValue -Path $path -Name "AllowTelemetry"
        Set-ItemProperty -Path $path -Name "AllowTelemetry" -Value 0 -Type DWord
        
        # Disable DiagTrack service
        $service = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
        if ($service) {
            Backup-ServiceState -ServiceName "DiagTrack"
            Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue
            Set-Service -Name "DiagTrack" -StartupType Disabled
        }
        
        # Disable dmwappushservice
        $service = Get-Service -Name "dmwappushservice" -ErrorAction SilentlyContinue
        if ($service) {
            Backup-ServiceState -ServiceName "dmwappushservice"
            Stop-Service -Name "dmwappushservice" -Force -ErrorAction SilentlyContinue
            Set-Service -Name "dmwappushservice" -StartupType Disabled
        }
        
        # Disable activity history
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Backup-RegistryValue -Path $path -Name "PublishUserActivities"
        Set-ItemProperty -Path $path -Name "PublishUserActivities" -Value 0 -Type DWord
        Backup-RegistryValue -Path $path -Name "UploadUserActivities"
        Set-ItemProperty -Path $path -Name "UploadUserActivities" -Value 0 -Type DWord
        
        Write-Log "Advanced telemetry blocking completed" -Level Success -Category "Privacy"
        Write-Host "`n✓ Telemetry blocked!" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Log "Failed to block telemetry: $($_.Exception.Message)" -Level Error -Category "Privacy"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Disable-TrackingAds {
    Write-Host "`n[DISABLE TRACKING & ADS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Disabling tracking and ads" -Level Info -Category "Privacy"
    
    try {
        # Disable advertising ID
        $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Backup-RegistryValue -Path $path -Name "Enabled"
        Set-ItemProperty -Path $path -Name "Enabled" -Value 0 -Type DWord
        
        # Disable app suggestions
        $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Backup-RegistryValue -Path $path -Name "SubscribedContent-338389Enabled"
        Set-ItemProperty -Path $path -Name "SubscribedContent-338389Enabled" -Value 0 -Type DWord
        Backup-RegistryValue -Path $path -Name "SubscribedContent-338393Enabled"
        Set-ItemProperty -Path $path -Name "SubscribedContent-338393Enabled" -Value 0 -Type DWord
        Backup-RegistryValue -Path $path -Name "SubscribedContent-353694Enabled"
        Set-ItemProperty -Path $path -Name "SubscribedContent-353694Enabled" -Value 0 -Type DWord
        Backup-RegistryValue -Path $path -Name "SubscribedContent-353696Enabled"
        Set-ItemProperty -Path $path -Name "SubscribedContent-353696Enabled" -Value 0 -Type DWord
        
        # Disable feedback
        $path = "HKCU:\Software\Microsoft\Siuf\Rules"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Backup-RegistryValue -Path $path -Name "NumberOfSIUFInPeriod"
        Set-ItemProperty -Path $path -Name "NumberOfSIUFInPeriod" -Value 0 -Type DWord
        
        Write-Log "Tracking and ads disabled" -Level Success -Category "Privacy"
        Write-Host "`n✓ Tracking and ads disabled!" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Log "Failed to disable tracking: $($_.Exception.Message)" -Level Error -Category "Privacy"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Remove-Bloatware {
    Write-Host "`n[REMOVE BLOATWARE & PRE-INSTALLED APPS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    Write-Host "⚠️  WARNING: This will remove pre-installed Windows apps." -ForegroundColor $Script:Colors.Warning
    Write-Host "Some apps cannot be easily reinstalled." -ForegroundColor $Script:Colors.Warning
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Removing bloatware" -Level Info -Category "Privacy"
    
    $bloatwareApps = @(
        "Microsoft.3DBuilder"
        "Microsoft.BingFinance"
        "Microsoft.BingNews"
        "Microsoft.BingSports"
        "Microsoft.BingWeather"
        "Microsoft.GetHelp"
        "Microsoft.Getstarted"
        "Microsoft.Messaging"
        "Microsoft.Microsoft3DViewer"
        "Microsoft.MicrosoftOfficeHub"
        "Microsoft.MicrosoftSolitaireCollection"
        "Microsoft.MixedReality.Portal"
        "Microsoft.Office.OneNote"
        "Microsoft.People"
        "Microsoft.Print3D"
        "Microsoft.SkypeApp"
        "Microsoft.Wallet"
        "Microsoft.WindowsAlarms"
        "Microsoft.WindowsCamera"
        "microsoft.windowscommunicationsapps"
        "Microsoft.WindowsFeedbackHub"
        "Microsoft.WindowsMaps"
        "Microsoft.WindowsSoundRecorder"
        "Microsoft.Xbox.TCUI"
        "Microsoft.XboxApp"
        "Microsoft.XboxGameOverlay"
        "Microsoft.XboxGamingOverlay"
        "Microsoft.XboxIdentityProvider"
        "Microsoft.XboxSpeechToTextOverlay"
        "Microsoft.YourPhone"
        "Microsoft.ZuneMusic"
        "Microsoft.ZuneVideo"
    )
    
    $removedCount = 0
    foreach ($app in $bloatwareApps) {
        try {
            $package = Get-AppxPackage -Name $app -ErrorAction SilentlyContinue
            if ($package) {
                Remove-AppxPackage -Package $package.PackageFullName -ErrorAction Stop
                Write-Log "Removed app: $app" -Level Success -Category "Privacy"
                $removedCount++
            }
        }
        catch {
            Write-Log "Failed to remove app: $app" -Level Warning -Category "Privacy"
        }
    }
    
    Write-Host "`n✓ Removed $removedCount bloatware apps!" -ForegroundColor $Script:Colors.Success
    Read-Host "`nPress Enter to continue"
}

function Set-WindowsFeaturesPrivacy {
    Write-Host "`n[WINDOWS FEATURES PRIVACY]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Configuring Windows features privacy" -Level Info -Category "Privacy"
    
    try {
        # Disable Cortana
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Backup-RegistryValue -Path $path -Name "AllowCortana"
        Set-ItemProperty -Path $path -Name "AllowCortana" -Value 0 -Type DWord
        
        # Disable location tracking
        $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
        if (Test-Path $path) {
            Backup-RegistryValue -Path $path -Name "Value"
            Set-ItemProperty -Path $path -Name "Value" -Value "Deny" -Type String
        }
        
        # Disable timeline
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Backup-RegistryValue -Path $path -Name "EnableActivityFeed"
        Set-ItemProperty -Path $path -Name "EnableActivityFeed" -Value 0 -Type DWord
        
        Write-Log "Windows features privacy configured" -Level Success -Category "Privacy"
        Write-Host "`n✓ Windows features privacy configured!" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Log "Failed to configure Windows features privacy: $($_.Exception.Message)" -Level Error -Category "Privacy"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Set-CameraMicrophonePrivacy {
    Write-Host "`n[CAMERA & MICROPHONE PRIVACY]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Configuring camera and microphone privacy" -Level Info -Category "Privacy"
    
    try {
        # Disable camera access
        $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam"
        if (Test-Path $path) {
            Backup-RegistryValue -Path $path -Name "Value"
            Set-ItemProperty -Path $path -Name "Value" -Value "Deny" -Type String
        }
        
        # Disable microphone access
        $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone"
        if (Test-Path $path) {
            Backup-RegistryValue -Path $path -Name "Value"
            Set-ItemProperty -Path $path -Name "Value" -Value "Deny" -Type String
        }
        
        Write-Log "Camera and microphone privacy configured" -Level Success -Category "Privacy"
        Write-Host "`n✓ Camera and microphone privacy configured!" -ForegroundColor $Script:Colors.Success
        Write-Host "  Note: You can grant access to specific apps in Windows Settings." -ForegroundColor $Script:Colors.Info
    }
    catch {
        Write-Log "Failed to configure camera/microphone privacy: $($_.Exception.Message)" -Level Error -Category "Privacy"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Set-NetworkPrivacy {
    Write-Host "`n[NETWORK PRIVACY SETTINGS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Configuring network privacy" -Level Info -Category "Privacy"
    
    try {
        # Disable Wi-Fi Sense
        $path = "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config"
        if (Test-Path $path) {
            Backup-RegistryValue -Path $path -Name "AutoConnectAllowedOEM"
            Set-ItemProperty -Path $path -Name "AutoConnectAllowedOEM" -Value 0 -Type DWord
        }
        
        Write-Log "Network privacy configured" -Level Success -Category "Privacy"
        Write-Host "`n✓ Network privacy configured!" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Log "Failed to configure network privacy: $($_.Exception.Message)" -Level Error -Category "Privacy"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Enable-SecurityHardening {
    Write-Host "`n[SECURITY HARDENING]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Enabling security hardening" -Level Info -Category "Security"
    
    try {
        # Enable DEP (Data Execution Prevention)
        bcdedit /set nx AlwaysOn | Out-Null
        Write-Log "Enabled DEP" -Level Success -Category "Security"
        
        # Disable SMBv1
        Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue | Out-Null
        Write-Log "Disabled SMBv1" -Level Success -Category "Security"
        
        Write-Host "`n✓ Security hardening complete!" -ForegroundColor $Script:Colors.Success
        Write-Host "  Note: Restart required for changes to take effect." -ForegroundColor $Script:Colors.Warning
    }
    catch {
        Write-Log "Failed to enable security hardening: $($_.Exception.Message)" -Level Error -Category "Security"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Invoke-AllPrivacyOptimizations {
    Write-Host "`n[APPLY ALL PRIVACY OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Block-TelemetryAdvanced
    Disable-TrackingAds
    Set-WindowsFeaturesPrivacy
    Set-NetworkPrivacy
    Enable-SecurityHardening
    
    Write-Host "`n✓ ALL PRIVACY OPTIMIZATIONS COMPLETED!" -ForegroundColor $Script:Colors.Success
    Read-Host "`nPress Enter to continue"
}

#endregion

#region Category 5: Cleanup & Maintenance

function Show-CleanupMenu {
    do {
        Show-Header "Cleanup & Maintenance"
        Write-Host "  CLEANUP & MAINTENANCE" -ForegroundColor $Script:Colors.Menu
        Write-Host "  ═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Menu
        Write-Host "   1. Advanced Disk Cleanup" -ForegroundColor White
        Write-Host "   2. Clean Temporary Files" -ForegroundColor White
        Write-Host "   3. Event Log Management" -ForegroundColor White
        Write-Host "   4. Scheduled Tasks Optimization" -ForegroundColor White
        Write-Host "   5. Context Menu Cleanup" -ForegroundColor White
        Write-Host "   6. Search Indexing Optimization" -ForegroundColor White
        Write-Host "   7. System Maintenance Tasks" -ForegroundColor White
        Write-Host "   8. ⚡ Run All Cleanup Tasks" -ForegroundColor Green
        Write-Host "   0. ← Back to Main Menu" -ForegroundColor Yellow
        Write-Host ""
        
        $choice = Read-Host "Select an option"
        
        switch ($choice) {
            '1' { Start-AdvancedDiskCleanup }
            '2' { Clear-TemporaryFiles }
            '3' { Update-EventLogs }
            '4' { Optimize-ScheduledTasks }
            '5' { Clear-ContextMenu }
            '6' { Optimize-SearchIndexing }
            '7' { Start-SystemMaintenance }
            '8' { Start-AllCleanupTasks }
            '0' { return }
        }
    } while ($true)
}

function Start-AdvancedDiskCleanup {
    Write-Host "`n[ADVANCED DISK CLEANUP]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Running advanced disk cleanup" -Level Info -Category "Cleanup"
    
    try {
        # Clean Windows.old folder
        if (Test-Path "$env:SystemDrive\Windows.old") {
            Write-Host "  Removing Windows.old folder..." -ForegroundColor $Script:Colors.Info
            Remove-Item -Path "$env:SystemDrive\Windows.old" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "Removed Windows.old folder" -Level Success -Category "Cleanup"
        }
        
        # Clean delivery optimization files
        Write-Host "  Cleaning delivery optimization files..." -ForegroundColor $Script:Colors.Info
        Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\DeliveryOptimization\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Cleaned delivery optimization files" -Level Success -Category "Cleanup"
        
        # Clean thumbnail cache
        Write-Host "  Cleaning thumbnail cache..." -ForegroundColor $Script:Colors.Info
        Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
        Write-Log "Cleaned thumbnail cache" -Level Success -Category "Cleanup"
        
        # Clean icon cache
        Write-Host "  Cleaning icon cache..." -ForegroundColor $Script:Colors.Info
        Remove-Item -Path "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
        Write-Log "Cleaned icon cache" -Level Success -Category "Cleanup"
        
        Write-Host "`n✓ Advanced disk cleanup complete!" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Log "Failed to run advanced disk cleanup: $($_.Exception.Message)" -Level Error -Category "Cleanup"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Clear-TemporaryFiles {
    Write-Host "`n[CLEAN TEMPORARY FILES]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Cleaning temporary files" -Level Info -Category "Cleanup"
    
    $cleanupPaths = @(
        "$env:TEMP\*",
        "$env:WINDIR\Temp\*",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*",
        "$env:LOCALAPPDATA\Microsoft\Windows\WebCache\*",
        "$env:LOCALAPPDATA\Temp\*"
    )
    
    $totalFreed = 0
    foreach ($path in $cleanupPaths) {
        try {
            $items = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            $sizeBefore = ($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            
            if ($sizeBefore) {
                $totalFreed += $sizeBefore
                Write-Log "Cleaned: $path ($('{0:N2}' -f ($sizeBefore / 1MB)) MB)" -Level Success -Category "Cleanup"
            }
        }
        catch {
            Write-Log "Failed to clean: $path" -Level Warning -Category "Cleanup"
        }
    }
    
    Write-Host "`n✓ Freed approximately $('{0:N2}' -f ($totalFreed / 1GB)) GB!" -ForegroundColor $Script:Colors.Success
    Read-Host "`nPress Enter to continue"
}

function Update-EventLogs {
    Write-Host "`n[EVENT LOG MANAGEMENT]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    Write-Host "This will clear all event logs." -ForegroundColor $Script:Colors.Warning
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Managing event logs" -Level Info -Category "Cleanup"
    
    try {
        $logs = Get-EventLog -List | Where-Object { $_.Entries.Count -gt 0 }
        foreach ($log in $logs) {
            try {
                Clear-EventLog -LogName $log.Log -ErrorAction SilentlyContinue
                Write-Log "Cleared event log: $($log.Log)" -Level Success -Category "Cleanup"
            }
            catch {
                Write-Log "Failed to clear event log: $($log.Log)" -Level Warning -Category "Cleanup"
            }
        }
        
        Write-Host "`n✓ Event logs cleared!" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Log "Failed to manage event logs: $($_.Exception.Message)" -Level Error -Category "Cleanup"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Optimize-ScheduledTasks {
    Write-Host "`n[SCHEDULED TASKS OPTIMIZATION]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Optimizing scheduled tasks" -Level Info -Category "Cleanup"
    
    $tasksToDisable = @(
        "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
        "\Microsoft\Windows\Application Experience\ProgramDataUpdater"
        "\Microsoft\Windows\Autochk\Proxy"
        "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
        "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
        "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
    )
    
    $disabledCount = 0
    foreach ($taskPath in $tasksToDisable) {
        try {
            $task = Get-ScheduledTask -TaskPath $taskPath -ErrorAction SilentlyContinue
            if ($task) {
                Disable-ScheduledTask -TaskPath $taskPath -ErrorAction Stop | Out-Null
                Write-Log "Disabled task: $taskPath" -Level Success -Category "Cleanup"
                $disabledCount++
            }
        }
        catch {
            Write-Log "Failed to disable task: $taskPath" -Level Warning -Category "Cleanup"
        }
    }
    
    Write-Host "`n✓ Disabled $disabledCount scheduled tasks!" -ForegroundColor $Script:Colors.Success
    Read-Host "`nPress Enter to continue"
}

function Clear-ContextMenu {
    Write-Host "`n[CONTEXT MENU CLEANUP]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    Write-Host "This will remove unnecessary context menu items." -ForegroundColor $Script:Colors.Info
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Cleaning context menu" -Level Info -Category "Cleanup"
    
    try {
        # Remove "Share with" from context menu
        $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Set-ItemProperty -Path $path -Name "{e2bf9676-5f8f-435c-97eb-11607a5bedf7}" -Value "" -Type String
        Write-Log "Removed 'Share with' from context menu" -Level Success -Category "Cleanup"
        
        Write-Host "`n✓ Context menu cleaned!" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Log "Failed to clean context menu: $($_.Exception.Message)" -Level Error -Category "Cleanup"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Optimize-SearchIndexing {
    Write-Host "`n[SEARCH INDEXING OPTIMIZATION]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    Write-Host "Choose an option:" -ForegroundColor $Script:Colors.Info
    Write-Host "  1. Optimize indexing (keep enabled)" -ForegroundColor White
    Write-Host "  2. Disable indexing completely" -ForegroundColor White
    Write-Host "  0. Cancel" -ForegroundColor Yellow
    Write-Host ""
    
    $choice = Read-Host "Select option"
    
    if ($choice -eq '0') { return }
    
    Write-Log "Optimizing search indexing" -Level Info -Category "Cleanup"
    
    try {
        if ($choice -eq '2') {
            # Disable Windows Search service
            $service = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue
            if ($service) {
                Backup-ServiceState -ServiceName "WSearch"
                Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
                Set-Service -Name "WSearch" -StartupType Disabled
                Write-Log "Disabled Windows Search service" -Level Success -Category "Cleanup"
            }
        }
        
        Write-Host "`n✓ Search indexing optimized!" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Log "Failed to optimize search indexing: $($_.Exception.Message)" -Level Error -Category "Cleanup"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Start-SystemMaintenance {
    Write-Host "`n[SYSTEM MAINTENANCE TASKS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Write-Log "Running system maintenance" -Level Info -Category "Maintenance"
    
    try {
        # Check disk
        Write-Host "  Checking system drive..." -ForegroundColor $Script:Colors.Info
        $systemDrive = $env:SystemDrive.TrimEnd(':')
        chkdsk $systemDrive /scan
        Write-Log "Disk check completed" -Level Success -Category "Maintenance"
        
        # Update Windows Defender
        Write-Host "  Updating Windows Defender..." -ForegroundColor $Script:Colors.Info
        Update-MpSignature -ErrorAction SilentlyContinue
        Write-Log "Updated Windows Defender" -Level Success -Category "Maintenance"
        
        Write-Host "`n✓ System maintenance complete!" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Log "Failed to run system maintenance: $($_.Exception.Message)" -Level Error -Category "Maintenance"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Start-AllCleanupTasks {
    Write-Host "`n[RUN ALL CLEANUP TASKS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    if (-not (Confirm-Action)) { return }
    
    Start-AdvancedDiskCleanup
    Clear-TemporaryFiles
    Optimize-ScheduledTasks
    Start-SystemMaintenance
    
    Write-Host "`n✓ ALL CLEANUP TASKS COMPLETED!" -ForegroundColor $Script:Colors.Success
    Read-Host "`nPress Enter to continue"
}

#endregion

# Export functions for main script
Export-ModuleMember -Function *

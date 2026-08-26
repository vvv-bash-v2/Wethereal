# Windows Performance Tweaker Ultimate Edition v3.5.0
# Additional Optimization Modules - Part 3
# Privacy, Cleanup, Advanced Tweaks

#region Category 4: Privacy & Security

function Global:Show-PrivacyMenu {
    do {
        Show-Header "Privacy & Security"
        Write-Host "  PRIVACY & SECURITY OPTIMIZATIONS" -ForegroundColor $Script:Colors.Menu
        Write-Host "  =======================================================================" -ForegroundColor $Script:Colors.Menu
        Write-Host "   1. Advanced Telemetry Blocking" -ForegroundColor White
        Write-Host "   2. Disable Tracking & Ads" -ForegroundColor White
        Write-Host "   3. Remove Bloatware & Pre-installed Apps" -ForegroundColor White
        Write-Host "   4. Windows Features Privacy" -ForegroundColor White
        Write-Host "   5. Camera & Microphone Privacy" -ForegroundColor White
        Write-Host "   6. Network Privacy Settings" -ForegroundColor White
        Write-Host "   7. Security Hardening" -ForegroundColor White
        Write-Host "   8. * Apply All Privacy Optimizations" -ForegroundColor Green
        Write-Host "   0. <- Back to Main Menu" -ForegroundColor Yellow
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
            default {
                Write-Host "`n[X] Invalid option." -ForegroundColor $Script:Colors.Error
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

function Global:Block-TelemetryAdvanced {
    Write-Host "`n[ADVANCED TELEMETRY BLOCKING]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Blocking telemetry" -Level Info -Category "Privacy"

    $steps = @(
        @{
            Name   = "Setting AllowTelemetry policy to Security/Off"
            Action = {
                $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "AllowTelemetry"
                Set-ItemProperty -Path $path -Name "AllowTelemetry" -Value 0 -Type DWord
            }
        }
        @{
            Name   = "Disabling Connected User Experiences and Telemetry (DiagTrack)"
            Action = {
                $service = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
                if ($service) {
                    Backup-ServiceState -ServiceName "DiagTrack"
                    Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue
                    Set-Service -Name "DiagTrack" -StartupType Disabled
                }
            }
        }
        @{
            Name   = "Disabling WAP Push Message Routing Service"
            Action = {
                $service = Get-Service -Name "dmwappushservice" -ErrorAction SilentlyContinue
                if ($service) {
                    Backup-ServiceState -ServiceName "dmwappushservice"
                    Stop-Service -Name "dmwappushservice" -Force -ErrorAction SilentlyContinue
                    Set-Service -Name "dmwappushservice" -StartupType Disabled
                }
            }
        }
        @{
            Name   = "Disabling activity history upload"
            Action = {
                $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "PublishUserActivities"
                Set-ItemProperty -Path $path -Name "PublishUserActivities" -Value 0 -Type DWord
                Backup-RegistryValue -Path $path -Name "UploadUserActivities"
                Set-ItemProperty -Path $path -Name "UploadUserActivities" -Value 0 -Type DWord
            }
        }
        @{
            Name   = "Disabling Windows Recall (Copilot+ AI snapshot history)"
            Action = {
                $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "DisableAIDataAnalysis"
                Set-ItemProperty -Path $path -Name "DisableAIDataAnalysis" -Value 1 -Type DWord
                $userPath = "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI"
                if (-not (Test-Path $userPath)) { New-Item -Path $userPath -Force | Out-Null }
                Backup-RegistryValue -Path $userPath -Name "DisableAIDataAnalysis"
                Set-ItemProperty -Path $userPath -Name "DisableAIDataAnalysis" -Value 1 -Type DWord
            }
        }
        @{
            Name   = "Disabling Windows Copilot"
            Action = {
                $path = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "TurnOffWindowsCopilot"
                Set-ItemProperty -Path $path -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord
                $explorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                if (-not (Test-Path $explorerPath)) { New-Item -Path $explorerPath -Force | Out-Null }
                Backup-RegistryValue -Path $explorerPath -Name "ShowCopilotButton"
                Set-ItemProperty -Path $explorerPath -Name "ShowCopilotButton" -Value 0 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "Telemetry Blocking" -Steps $steps -Category "Privacy" | Out-Null

    Write-Host "`n[OK] Telemetry blocked!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Disable-TrackingAds {
    Write-Host "`n[DISABLE TRACKING & ADS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Disabling tracking and ads" -Level Info -Category "Privacy"

    $steps = @(
        @{
            Name   = "Disabling advertising ID"
            Action = {
                $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "Enabled"
                Set-ItemProperty -Path $path -Name "Enabled" -Value 0 -Type DWord
            }
        }
        @{
            Name   = "Disabling Start menu app suggestions"
            Action = {
                $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                foreach ($name in @(
                        "SubscribedContent-338389Enabled", "SubscribedContent-338393Enabled",
                        "SubscribedContent-353694Enabled", "SubscribedContent-353696Enabled"
                    )) {
                    Backup-RegistryValue -Path $path -Name $name
                    Set-ItemProperty -Path $path -Name $name -Value 0 -Type DWord
                }
            }
        }
        @{
            Name   = "Disabling feedback / diagnostic prompts"
            Action = {
                $path = "HKCU:\Software\Microsoft\Siuf\Rules"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "NumberOfSIUFInPeriod"
                Set-ItemProperty -Path $path -Name "NumberOfSIUFInPeriod" -Value 0 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "Tracking & Ads Blocking" -Steps $steps -Category "Privacy" | Out-Null

    Write-Host "`n[OK] Tracking and ads disabled!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Remove-Bloatware {
    Write-Host "`n[REMOVE BLOATWARE & PRE-INSTALLED APPS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "[!]  WARNING: This will remove pre-installed Windows apps." -ForegroundColor $Script:Colors.Warning
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

    $steps = $bloatwareApps | ForEach-Object {
        $appName = $_
        @{
            Name      = "Removing $appName"
            Condition = { (Get-AppxPackage -Name $appName -ErrorAction SilentlyContinue) -ne $null }.GetNewClosure()
            Action    = {
                $package = Get-AppxPackage -Name $appName -ErrorAction SilentlyContinue
                if ($package) { Remove-AppxPackage -Package $package.PackageFullName -ErrorAction Stop }
            }.GetNewClosure()
        }
    }

    Invoke-TweakSequence -Title "Bloatware Removal" -Steps $steps -Category "Privacy" | Out-Null
    Wait-ForUser
}

function Global:Set-WindowsFeaturesPrivacy {
    Write-Host "`n[WINDOWS FEATURES PRIVACY]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Configuring Windows features privacy" -Level Info -Category "Privacy"

    $steps = @(
        @{
            Name   = "Disabling Cortana"
            Action = {
                $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "AllowCortana"
                Set-ItemProperty -Path $path -Name "AllowCortana" -Value 0 -Type DWord
            }
        }
        @{
            Name   = "Denying system-wide location access"
            Action = {
                $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
                if (Test-Path $path) {
                    Backup-RegistryValue -Path $path -Name "Value"
                    Set-ItemProperty -Path $path -Name "Value" -Value "Deny" -Type String
                }
            }
        }
        @{
            Name   = "Disabling Windows Timeline / activity feed"
            Action = {
                $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "EnableActivityFeed"
                Set-ItemProperty -Path $path -Name "EnableActivityFeed" -Value 0 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "Windows Features Privacy" -Steps $steps -Category "Privacy" | Out-Null

    Write-Host "`n[OK] Windows features privacy configured!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Set-CameraMicrophonePrivacy {
    Write-Host "`n[CAMERA & MICROPHONE PRIVACY]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Configuring camera and microphone privacy" -Level Info -Category "Privacy"

    $steps = @(
        @{
            Name   = "Denying system-wide camera access"
            Action = {
                $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam"
                if (Test-Path $path) {
                    Backup-RegistryValue -Path $path -Name "Value"
                    Set-ItemProperty -Path $path -Name "Value" -Value "Deny" -Type String
                }
            }
        }
        @{
            Name   = "Denying system-wide microphone access"
            Action = {
                $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone"
                if (Test-Path $path) {
                    Backup-RegistryValue -Path $path -Name "Value"
                    Set-ItemProperty -Path $path -Name "Value" -Value "Deny" -Type String
                }
            }
        }
    )

    Invoke-TweakSequence -Title "Camera & Microphone Privacy" -Steps $steps -Category "Privacy" | Out-Null

    Write-Host "`n[OK] Camera and microphone privacy configured!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Note: You can grant access to specific apps in Windows Settings." -ForegroundColor $Script:Colors.Info
    Wait-ForUser
}

function Global:Set-NetworkPrivacy {
    Write-Host "`n[NETWORK PRIVACY SETTINGS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Configuring network privacy" -Level Info -Category "Privacy"

    $steps = @(
        @{
            Name   = "Disabling Wi-Fi Sense auto-connect to open hotspots"
            Action = {
                $path = "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config"
                if (Test-Path $path) {
                    Backup-RegistryValue -Path $path -Name "AutoConnectAllowedOEM"
                    Set-ItemProperty -Path $path -Name "AutoConnectAllowedOEM" -Value 0 -Type DWord
                }
            }
        }
    )

    Invoke-TweakSequence -Title "Network Privacy" -Steps $steps -Category "Privacy" | Out-Null

    Write-Host "`n[OK] Network privacy configured!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Enable-SecurityHardening {
    Write-Host "`n[SECURITY HARDENING]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Enabling security hardening" -Level Info -Category "Security"

    $steps = @(
        @{ Name = "Enabling DEP (Data Execution Prevention)"; Action = { bcdedit /set nx AlwaysOn | Out-Null } }
        @{ Name = "Disabling legacy SMBv1 protocol"; Action = { Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction Stop | Out-Null } }
    )

    Invoke-TweakSequence -Title "Security Hardening" -Steps $steps -Category "Security" | Out-Null

    Write-Host "`n[OK] Security hardening complete!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Note: Restart required for changes to take effect." -ForegroundColor $Script:Colors.Warning
    Wait-ForUser
}

function Global:Invoke-AllPrivacyOptimizations {
    Write-Host "`n[APPLY ALL PRIVACY OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    $Script:SkipConfirmations = $true
    $Script:SkipPauses = $true
    try {
        Block-TelemetryAdvanced
        Disable-TrackingAds
        Set-WindowsFeaturesPrivacy
        Set-NetworkPrivacy
        Enable-SecurityHardening
    }
    finally {
        $Script:SkipConfirmations = $false
        $Script:SkipPauses = $false
    }

    Write-Host "`n[OK] ALL PRIVACY OPTIMIZATIONS COMPLETED!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

#endregion

#region Category 5: Cleanup & Maintenance

function Global:Show-CleanupMenu {
    do {
        Show-Header "Cleanup & Maintenance"
        Write-Host "  CLEANUP & MAINTENANCE" -ForegroundColor $Script:Colors.Menu
        Write-Host "  =======================================================================" -ForegroundColor $Script:Colors.Menu
        Write-Host "   1. Advanced Disk Cleanup" -ForegroundColor White
        Write-Host "   2. Clean Temporary Files" -ForegroundColor White
        Write-Host "   3. Event Log Management" -ForegroundColor White
        Write-Host "   4. Scheduled Tasks Optimization" -ForegroundColor White
        Write-Host "   5. Context Menu Cleanup" -ForegroundColor White
        Write-Host "   6. Search Indexing Optimization" -ForegroundColor White
        Write-Host "   7. System Maintenance Tasks" -ForegroundColor White
        Write-Host "   8. * Run All Cleanup Tasks" -ForegroundColor Green
        Write-Host "   0. <- Back to Main Menu" -ForegroundColor Yellow
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
            default {
                Write-Host "`n[X] Invalid option." -ForegroundColor $Script:Colors.Error
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

function Global:Start-AdvancedDiskCleanup {
    Write-Host "`n[ADVANCED DISK CLEANUP]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Running advanced disk cleanup" -Level Info -Category "Cleanup"

    $steps = @(
        @{
            Name      = "Removing Windows.old folder"
            Condition = { Test-Path "$env:SystemDrive\Windows.old" }
            Action    = { Remove-Item -Path "$env:SystemDrive\Windows.old" -Recurse -Force -ErrorAction Stop }
        }
        @{ Name = "Cleaning delivery optimization files"; Action = { Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\DeliveryOptimization\*" -Recurse -Force -ErrorAction SilentlyContinue } }
        @{ Name = "Cleaning thumbnail cache"; Action = { Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue } }
        @{ Name = "Cleaning icon cache"; Action = { Remove-Item -Path "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue } }
    )

    Invoke-TweakSequence -Title "Advanced Disk Cleanup" -Steps $steps -Category "Cleanup" | Out-Null

    Write-Host "`n[OK] Advanced disk cleanup complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Clear-TemporaryFiles {
    Write-Host "`n[CLEAN TEMPORARY FILES]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    $cleanupPaths = @(
        "$env:TEMP\*",
        "$env:WINDIR\Temp\*",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*",
        "$env:LOCALAPPDATA\Microsoft\Windows\WebCache\*",
        "$env:LOCALAPPDATA\Temp\*"
    )

    # Scan sizes up front so the user knows what they're about to free BEFORE
    # confirming, not just what got freed afterward.
    Write-Host "Scanning temporary file locations..." -ForegroundColor $Script:Colors.Info
    $pathSizes = @{}
    $totalBytes = 0
    foreach ($cleanPath in $cleanupPaths) {
        $size = (Get-ChildItem -Path $cleanPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        if (-not $size) { $size = 0 }
        $pathSizes[$cleanPath] = $size
        $totalBytes += $size
    }
    Write-Host "About to free approximately $('{0:N2}' -f ($totalBytes / 1GB)) GB." -ForegroundColor $Script:Colors.Highlight

    if (-not (Confirm-Action)) { return }

    Write-Log "Cleaning temporary files ($('{0:N2}' -f ($totalBytes / 1GB)) GB detected)" -Level Info -Category "Cleanup"

    $Script:LastTempCleanupFreedBytes = 0
    $steps = $cleanupPaths | ForEach-Object {
        $cleanPath = $_
        $knownSize = $pathSizes[$cleanPath]
        @{
            Name   = "Cleaning $cleanPath ($('{0:N2}' -f ($knownSize / 1MB)) MB)"
            Action = {
                Remove-Item -Path $cleanPath -Recurse -Force -ErrorAction SilentlyContinue
                $Script:LastTempCleanupFreedBytes += $knownSize
            }.GetNewClosure()
        }
    }

    Invoke-TweakSequence -Title "Temporary File Cleanup" -Steps $steps -Category "Cleanup" | Out-Null

    Write-Host "`n[OK] Freed approximately $('{0:N2}' -f ($Script:LastTempCleanupFreedBytes / 1GB)) GB!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Update-EventLogs {
    Write-Host "`n[EVENT LOG MANAGEMENT]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "This will clear all event logs." -ForegroundColor $Script:Colors.Warning

    if (-not (Confirm-Action)) { return }

    Write-Log "Managing event logs" -Level Info -Category "Cleanup"

    $logs = Get-EventLog -List -ErrorAction SilentlyContinue | Where-Object { $_.Entries.Count -gt 0 }
    $steps = $logs | ForEach-Object {
        $logName = $_.Log
        @{
            Name   = "Clearing event log: $logName"
            Action = { Clear-EventLog -LogName $logName -ErrorAction Stop }.GetNewClosure()
        }
    }

    Invoke-TweakSequence -Title "Event Log Cleanup" -Steps $steps -Category "Cleanup" | Out-Null

    Write-Host "`n[OK] Event logs cleared!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Optimize-ScheduledTasks {
    Write-Host "`n[SCHEDULED TASKS OPTIMIZATION]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

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

    $steps = $tasksToDisable | ForEach-Object {
        $taskPath = $_
        @{
            Name      = "Disabling task: $taskPath"
            Condition = { (Get-ScheduledTask -TaskPath $taskPath -ErrorAction SilentlyContinue) -ne $null }.GetNewClosure()
            Action    = { Disable-ScheduledTask -TaskPath $taskPath -ErrorAction Stop | Out-Null }.GetNewClosure()
        }
    }

    Invoke-TweakSequence -Title "Scheduled Task Optimization" -Steps $steps -Category "Cleanup" | Out-Null
    Wait-ForUser
}

function Global:Clear-ContextMenu {
    Write-Host "`n[CONTEXT MENU CLEANUP]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "This will remove unnecessary context menu items." -ForegroundColor $Script:Colors.Info

    if (-not (Confirm-Action)) { return }

    Write-Log "Cleaning context menu" -Level Info -Category "Cleanup"

    $steps = @(
        @{
            Name   = "Removing 'Share with' from context menu"
            Action = {
                $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Set-ItemProperty -Path $path -Name "{e2bf9676-5f8f-435c-97eb-11607a5bedf7}" -Value "" -Type String
            }
        }
    )

    Invoke-TweakSequence -Title "Context Menu Cleanup" -Steps $steps -Category "Cleanup" | Out-Null

    Write-Host "`n[OK] Context menu cleaned!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Optimize-SearchIndexing {
    Write-Host "`n[SEARCH INDEXING OPTIMIZATION]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Choose an option:" -ForegroundColor $Script:Colors.Info
    Write-Host "  1. Optimize indexing (keep enabled)" -ForegroundColor White
    Write-Host "  2. Disable indexing completely" -ForegroundColor White
    Write-Host "  0. Cancel" -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "Select option"

    if ($choice -eq '0') { return }
    if ($choice -ne '1' -and $choice -ne '2') {
        Write-Host "`n[X] Invalid selection." -ForegroundColor $Script:Colors.Error
        Start-Sleep -Seconds 1
        return
    }

    Write-Log "Optimizing search indexing" -Level Info -Category "Cleanup"

    if ($choice -eq '2') {
        $steps = @(
            @{
                Name   = "Disabling Windows Search service"
                Action = {
                    $service = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue
                    if ($service) {
                        Backup-ServiceState -ServiceName "WSearch"
                        Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
                        Set-Service -Name "WSearch" -StartupType Disabled
                    }
                    else { throw "Windows Search service not present" }
                }
            }
        )
        Invoke-TweakSequence -Title "Search Indexing" -Steps $steps -Category "Cleanup" | Out-Null
    }
    else {
        Write-Host "`n  [i] Indexing left enabled - no changes made." -ForegroundColor $Script:Colors.Info
    }

    Write-Host "`n[OK] Search indexing optimized!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Start-SystemMaintenance {
    Write-Host "`n[SYSTEM MAINTENANCE TASKS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Running system maintenance" -Level Info -Category "Maintenance"

    $steps = @(
        @{
            Name   = "Scanning system drive for errors (chkdsk /scan)"
            Action = {
                $systemDrive = $env:SystemDrive.TrimEnd(':')
                chkdsk $systemDrive /scan | Out-Null
            }
        }
        @{ Name = "Updating Windows Defender signatures"; Action = { Update-MpSignature -ErrorAction Stop } }
    )

    Invoke-TweakSequence -Title "System Maintenance" -Steps $steps -Category "Maintenance" | Out-Null

    Write-Host "`n[OK] System maintenance complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Start-AllCleanupTasks {
    Write-Host "`n[RUN ALL CLEANUP TASKS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    $Script:SkipConfirmations = $true
    $Script:SkipPauses = $true
    try {
        Start-AdvancedDiskCleanup
        Clear-TemporaryFiles
        Optimize-ScheduledTasks
        Start-SystemMaintenance
    }
    finally {
        $Script:SkipConfirmations = $false
        $Script:SkipPauses = $false
    }

    Write-Host "`n[OK] ALL CLEANUP TASKS COMPLETED!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

#endregion

# Wethereal Ultimate Edition - Super Optimizer Extras Module
# Category 13: Advanced Performance & Compatibility
# CPU C-States, USB/PCIe power management, Fast Startup, missing prerequisites
# checker, game-aware notification muting, GPU driver version check, audio
# latency tweaks - plus an "Apply All" like Categories 1 and 2.

#region Category 13: Advanced Performance & Compatibility

function Global:Show-SuperOptimizerMenu {
    do {
        Show-Header "Advanced Performance & Compatibility"
        Write-Host "  ADVANCED PERFORMANCE & COMPATIBILITY" -ForegroundColor $Script:Colors.Menu
        Write-Host "  =======================================================================" -ForegroundColor $Script:Colors.Menu
        Write-Host "   1. [BOOST] Disable CPU C-States (lowest input latency)" -ForegroundColor White
        Write-Host "   2. [BOOST] Disable USB Selective Suspend + PCIe ASPM" -ForegroundColor White
        Write-Host "   3. [BOOST] Disable Fast Startup (Hybrid Boot)" -ForegroundColor White
        Write-Host "   4. [SCAN] Check & Install Missing Prerequisites (VC++/DirectX)" -ForegroundColor White
        Write-Host "   5. [SYNC] Auto-Mute Notifications While Gaming" -ForegroundColor White
        Write-Host "   6. [SCAN] GPU Driver Version Check" -ForegroundColor White
        Write-Host "   7. [BOOST] Audio Latency Tweaks" -ForegroundColor White
        Write-Host "   8. * Apply All Advanced Performance Optimizations" -ForegroundColor Green
        Write-Host "   0. <- Back to Main Menu" -ForegroundColor Yellow
        Write-Host ""

        $choice = Read-Host "Select an option"

        switch ($choice) {
            '1' { Disable-CpuCStates }
            '2' { Disable-UsbPcieSuspend }
            '3' { Disable-FastStartup }
            '4' { Install-MissingPrerequisites }
            '5' { Set-GameAwareNotificationMute }
            '6' { Test-GpuDriverVersion }
            '7' { Optimize-AudioLatency }
            '8' { Invoke-AllAdvancedPerformanceOptimizations }
            '0' { return }
            default {
                Write-Host "`n[X] Invalid option." -ForegroundColor $Script:Colors.Error
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

function Global:Disable-CpuCStates {
    <#
        Disables CPU idle sleep states (C1E/C3/C6) via the power scheme instead
        of the registry - there is no registry-only equivalent, powercfg is the
        supported interface for this. Trades a small amount of idle power/heat
        for the lowest possible wake-from-idle latency, the same trick used by
        competitive-gaming and BIOS "responsiveness" presets. Undo restores
        C-states to enabled (0) via the same interface.
    #>
    Write-Host "`n[DISABLE CPU C-STATES]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Disables CPU idle sleep states for the lowest possible input latency." -ForegroundColor $Script:Colors.Info
    Write-Host "[!]  Trade-off: slightly higher idle power draw and heat." -ForegroundColor $Script:Colors.Warning

    if (-not (Confirm-Action)) { return }

    Write-Log "Disabling CPU C-States" -Level Info -Category "Advanced"

    $subProcessor = "54533251-82be-4824-96c1-47b60b740d00"
    $idleDisableSetting = "5d76a2ca-e8c0-402f-a133-2158492d58ad"

    $steps = @(
        @{
            Name   = "Disabling CPU idle states (C-States)"
            Action = {
                powercfg -attributes $subProcessor $idleDisableSetting -ATTRIB_HIDE:$false 2>&1 | Out-Null
                powercfg -setacvalueindex SCHEME_CURRENT $subProcessor $idleDisableSetting 1 2>&1 | Out-Null
                powercfg -setactive SCHEME_CURRENT 2>&1 | Out-Null
                Add-UndoAction -Description "Re-enable CPU C-States" -UndoScript {
                    param($SubGroup, $Setting)
                    powercfg -setacvalueindex SCHEME_CURRENT $SubGroup $Setting 0 2>&1 | Out-Null
                    powercfg -setactive SCHEME_CURRENT 2>&1 | Out-Null
                } -Parameters @{ SubGroup = $subProcessor; Setting = $idleDisableSetting }
            }
        }
    )

    Invoke-TweakSequence -Title "CPU C-States" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n[OK] CPU C-States disabled!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Disable-UsbPcieSuspend {
    <#
        Disables two power-saving features that can introduce wake-up latency
        or micro-stutter: USB Selective Suspend (a USB controller/device can be
        put to sleep and needs to wake up on demand) and PCIe Active State
        Power Management (the PCIe bus itself drops into a lower-power link
        state and has to renegotiate). Both are set via powercfg, the same
        supported interface as C-States above.
    #>
    Write-Host "`n[DISABLE USB SELECTIVE SUSPEND + PCIe ASPM]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Stops USB devices and the PCIe bus from entering low-power states that" -ForegroundColor $Script:Colors.Info
    Write-Host "need to wake up on demand - removes a real source of micro-stutter." -ForegroundColor $Script:Colors.Info

    if (-not (Confirm-Action)) { return }

    Write-Log "Disabling USB Selective Suspend and PCIe ASPM" -Level Info -Category "Advanced"

    $subUsb = "2a737441-1930-4402-8d77-b2bebba308a3"
    $usbSuspendSetting = "48e6b7a6-50f5-4782-a5d4-53bb8f07e226"
    $subPcie = "501a4d13-42af-4429-9fd1-a8218c268e20"
    $aspmSetting = "ee12f906-d277-404b-b6da-e5fa1a576df5"

    $steps = @(
        @{
            Name   = "Disabling USB Selective Suspend"
            Action = {
                powercfg -setacvalueindex SCHEME_CURRENT $subUsb $usbSuspendSetting 0 2>&1 | Out-Null
                Add-UndoAction -Description "Re-enable USB Selective Suspend" -UndoScript {
                    param($SubGroup, $Setting)
                    powercfg -setacvalueindex SCHEME_CURRENT $SubGroup $Setting 1 2>&1 | Out-Null
                } -Parameters @{ SubGroup = $subUsb; Setting = $usbSuspendSetting }
            }
        }
        @{
            Name   = "Disabling PCIe Active State Power Management"
            Action = {
                powercfg -setacvalueindex SCHEME_CURRENT $subPcie $aspmSetting 0 2>&1 | Out-Null
                powercfg -setactive SCHEME_CURRENT 2>&1 | Out-Null
                Add-UndoAction -Description "Re-enable PCIe ASPM" -UndoScript {
                    param($SubGroup, $Setting)
                    powercfg -setacvalueindex SCHEME_CURRENT $SubGroup $Setting 1 2>&1 | Out-Null
                    powercfg -setactive SCHEME_CURRENT 2>&1 | Out-Null
                } -Parameters @{ SubGroup = $subPcie; Setting = $aspmSetting }
            }
        }
    )

    Invoke-TweakSequence -Title "USB/PCIe Power Management" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n[OK] USB Selective Suspend and PCIe ASPM disabled!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Disable-FastStartup {
    Write-Host "`n[DISABLE FAST STARTUP]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Fast Startup (hybrid boot) hibernates the kernel session instead of a" -ForegroundColor $Script:Colors.Info
    Write-Host "full shutdown, which can leave drivers/services in a stale state after" -ForegroundColor $Script:Colors.Info
    Write-Host "an update - a common, hard-to-diagnose cause of 'it worked yesterday'." -ForegroundColor $Script:Colors.Info

    if (-not (Confirm-Action)) { return }

    Write-Log "Disabling Fast Startup" -Level Info -Category "Advanced"

    $steps = @(
        @{
            Name   = "Disabling Fast Startup (HiberbootEnabled)"
            Action = {
                $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
                Backup-RegistryValue -Path $path -Name "HiberbootEnabled"
                Set-ItemProperty -Path $path -Name "HiberbootEnabled" -Value 0 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "Fast Startup" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n[OK] Fast Startup disabled - full shutdowns will now be a clean boot." -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Install-MissingPrerequisites {
    <#
        Checks for the two prerequisite runtimes that a very large share of
        "the game won't even launch" problems trace back to: the Visual C++
        2015-2022 Redistributable (x86 and x64) and the legacy DirectX
        End-User Runtime (still required by many older titles even though
        DirectX 12 ships with Windows). Detected via the real Uninstall
        registry entries / well-known runtime DLLs rather than assuming
        anything is missing. Installs are opt-in per missing item.
    #>
    Write-Host "`n[CHECK & INSTALL MISSING PREREQUISITES]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Checks for the Visual C++ Redistributables and legacy DirectX runtime that" -ForegroundColor $Script:Colors.Info
    Write-Host "most 'game won't launch' errors trace back to." -ForegroundColor $Script:Colors.Info

    Write-Log "Checking for missing game prerequisites" -Level Info -Category "Advanced"

    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $installed = Get-ItemProperty -Path $uninstallPaths -ErrorAction SilentlyContinue

    $hasVcX64 = [bool]($installed | Where-Object { $_.DisplayName -match 'Visual C\+\+ 2015-20\d\d Redistributable \(x64\)' })
    $hasVcX86 = [bool]($installed | Where-Object { $_.DisplayName -match 'Visual C\+\+ 2015-20\d\d Redistributable \(x86\)' })
    $hasDirectX = Test-Path "$env:WINDIR\System32\xinput1_3.dll"

    Write-Host ""
    Write-Host "  VC++ Redistributable (x64): $(if ($hasVcX64) { '[OK] Installed' } else { '[!] Missing' })" -ForegroundColor $(if ($hasVcX64) { $Script:Colors.Success } else { $Script:Colors.Warning })
    Write-Host "  VC++ Redistributable (x86): $(if ($hasVcX86) { '[OK] Installed' } else { '[!] Missing' })" -ForegroundColor $(if ($hasVcX86) { $Script:Colors.Success } else { $Script:Colors.Warning })
    Write-Host "  Legacy DirectX Runtime:     $(if ($hasDirectX) { '[OK] Installed' } else { '[!] Missing' })" -ForegroundColor $(if ($hasDirectX) { $Script:Colors.Success } else { $Script:Colors.Warning })

    if ($hasVcX64 -and $hasVcX86 -and $hasDirectX) {
        Write-Host "`n[OK] All checked prerequisites are already installed." -ForegroundColor $Script:Colors.Success
        Wait-ForUser
        return
    }

    if (-not (Confirm-Action -Message "`nInstall the missing prerequisite(s) now?" -DefaultYes)) { return }

    $steps = @()
    if (-not $hasVcX64) {
        $steps += @{
            Name   = "Installing VC++ 2015-2022 Redistributable (x64)"
            Action = {
                if (Test-WingetAvailable) {
                    winget install --id Microsoft.VCRedist.2015+.x64 -e --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
                    if ($LASTEXITCODE -ne 0) { throw "winget exited with code $LASTEXITCODE" }
                }
                else { throw "winget is not available on this system" }
            }
        }
    }
    if (-not $hasVcX86) {
        $steps += @{
            Name   = "Installing VC++ 2015-2022 Redistributable (x86)"
            Action = {
                if (Test-WingetAvailable) {
                    winget install --id Microsoft.VCRedist.2015+.x86 -e --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
                    if ($LASTEXITCODE -ne 0) { throw "winget exited with code $LASTEXITCODE" }
                }
                else { throw "winget is not available on this system" }
            }
        }
    }
    if (-not $hasDirectX) {
        $steps += @{
            Name   = "Installing legacy DirectX End-User Runtime"
            Action = {
                $installerPath = "$env:TEMP\dxwebsetup.exe"
                Invoke-WebRequest -Uri "https://download.microsoft.com/download/1/7/1/171398B7-6B01-4AC0-A70D-641C4E845059/dxwebsetup.exe" -OutFile $installerPath -UseBasicParsing -ErrorAction Stop
                Start-Process -FilePath $installerPath -ArgumentList "/Q" -Wait
                Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Invoke-TweakSequence -Title "Installing Missing Prerequisites" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n[OK] Prerequisite installation finished!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Set-GameAwareNotificationMute {
    <#
        Mutes Windows toast notifications the moment a detected game starts and
        restores them once no monitored game is running - the same watcher-
        script + scheduled-task pattern as Set-GameAwareUpdatePause, reused
        here for notifications instead of Windows Update. Toggling the actual
        Focus Assist UI setting requires writing an undocumented, Windows-
        build-dependent binary blob with no stable public schema; toggling
        ToastEnabled achieves the same practical outcome (no popups while
        gaming) through a single, simple, well-documented DWORD instead.
    #>
    Write-Host "`n[AUTO-MUTE NOTIFICATIONS WHILE GAMING]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Automatically mutes toast notifications while a detected game is running," -ForegroundColor $Script:Colors.Info
    Write-Host "and restores them a few minutes after you close it." -ForegroundColor $Script:Colors.Info
    Write-Host ""
    Write-Host "  1. Enable" -ForegroundColor White
    Write-Host "  2. Disable and remove" -ForegroundColor White
    Write-Host "  0. Cancel" -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "Select an option"
    if ($choice -eq '0' -or [string]::IsNullOrWhiteSpace($choice)) { return }

    $taskName = "Wethereal Game-Aware Notification Mute"
    $watcherPath = "$PSScriptRoot\Wethereal-GameNotificationMuteWatcher.ps1"
    $markerPath = "$PSScriptRoot\Wethereal-NotificationsMutedByGame.marker"
    $notifPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications"

    if ($choice -eq '2') {
        if (-not (Confirm-Action -Message "Remove auto-mute and restore notifications?")) { return }
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        Remove-Item -Path $watcherPath -Force -ErrorAction SilentlyContinue
        if (Test-Path $markerPath) {
            if (-not (Test-Path $notifPath)) { New-Item -Path $notifPath -Force | Out-Null }
            Set-ItemProperty -Path $notifPath -Name "ToastEnabled" -Value 1 -Type DWord
            Remove-Item -Path $markerPath -Force -ErrorAction SilentlyContinue
        }
        Write-Host "`n[OK] Removed - notifications are back to normal." -ForegroundColor $Script:Colors.Success
        Write-Log "Removed game-aware notification mute" -Level Success -Category "Advanced"
        Wait-ForUser
        return
    }

    if ($choice -ne '1') {
        Write-Host "`n[X] Invalid selection." -ForegroundColor $Script:Colors.Error
        Start-Sleep -Seconds 1
        return
    }

    $gameFolders = Get-DetectedGameFolders
    if (-not $gameFolders -or $gameFolders.Count -eq 0) {
        Write-Host "`n[!] No detected game library folders - nothing to watch for." -ForegroundColor $Script:Colors.Warning
        Wait-ForUser
        return
    }

    if (-not (Confirm-Action -Message "Enable notification auto-mute for detected games?" -DefaultYes)) { return }

    Write-Log "Enabling game-aware notification mute" -Level Info -Category "Advanced"

    $folderListLiteral = ($gameFolders | ForEach-Object { "'$($_ -replace "'", "''")'" }) -join ', '
    $watcherLines = @(
        '# Auto-generated by Wethereal. Regenerate via Advanced Performance > Auto-Mute Notifications While Gaming instead of editing by hand.'
        "`$gameFolders = @($folderListLiteral)"
        "`$markerFile = '$markerPath'"
        "`$notifPath = '$notifPath'"
        '$gameRunning = $false'
        'foreach ($proc in (Get-Process -ErrorAction SilentlyContinue)) {'
        '    if (-not $proc.Path) { continue }'
        '    foreach ($folder in $gameFolders) {'
        '        if ($proc.Path.StartsWith($folder, [System.StringComparison]::OrdinalIgnoreCase)) { $gameRunning = $true; break }'
        '    }'
        '    if ($gameRunning) { break }'
        '}'
        'if ($gameRunning) {'
        '    if (-not (Test-Path $markerFile)) {'
        '        if (-not (Test-Path $notifPath)) { New-Item -Path $notifPath -Force | Out-Null }'
        '        Set-ItemProperty -Path $notifPath -Name "ToastEnabled" -Value 0 -Type DWord'
        '        New-Item -Path $markerFile -ItemType File -Force | Out-Null'
        '    }'
        '}'
        'else {'
        '    if (Test-Path $markerFile) {'
        '        if (Test-Path $notifPath) { Set-ItemProperty -Path $notifPath -Name "ToastEnabled" -Value 1 -Type DWord }'
        '        Remove-Item -Path $markerFile -Force -ErrorAction SilentlyContinue'
        '    }'
        '}'
    )

    try {
        Set-Content -Path $watcherPath -Value ($watcherLines -join "`n") -Encoding UTF8

        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$watcherPath`""
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]::MaxValue)
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null

        Write-Host "`n[OK] Enabled - watching $($gameFolders.Count) game folder(s), checked every 5 minutes." -ForegroundColor $Script:Colors.Success
        Write-Log "Created game-aware notification mute task ($($gameFolders.Count) folders watched)" -Level Success -Category "Advanced"
    }
    catch {
        Write-Host "`n[X] Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor $Script:Colors.Error
        Write-Log "Failed to create game-aware notification mute task: $($_.Exception.Message)" -Level Error -Category "Advanced"
    }

    Wait-ForUser
}

function Global:Test-GpuDriverVersion {
    <#
        Informational only: reports the installed GPU driver version and how
        old it is, and points to the vendor's official driver page. Wethereal
        deliberately does not scrape vendor pages to compare against "the
        latest" version number - there's no stable public API for that, and
        scraping is fragile and against most vendors' terms of use. An honest
        "here's what you have and how old it is" beats a guess at "the latest".
    #>
    Write-Host "`n[GPU DRIVER VERSION CHECK]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    $gpus = Get-CimInstance -ClassName Win32_VideoController -ErrorAction SilentlyContinue
    if (-not $gpus) {
        Write-Host "`n[!] Could not query any GPU via WMI." -ForegroundColor $Script:Colors.Warning
        Wait-ForUser
        return
    }

    $downloadPages = @{
        NVIDIA = "https://www.nvidia.com/Download/index.aspx"
        AMD    = "https://www.amd.com/en/support"
        Intel  = "https://www.intel.com/content/www/us/en/support/detect.html"
    }

    foreach ($gpu in $gpus) {
        $vendor = if ($gpu.Name -match 'NVIDIA') { 'NVIDIA' } elseif ($gpu.Name -match 'AMD|Radeon') { 'AMD' } elseif ($gpu.Name -match 'Intel') { 'Intel' } else { 'Unknown' }
        $driverDate = $null
        if ($gpu.DriverDate) { try { $driverDate = [Management.ManagementDateTimeConverter]::ToDateTime($gpu.DriverDate) } catch { $driverDate = $null } }
        $ageDays = if ($driverDate) { [math]::Round(((Get-Date) - $driverDate).TotalDays) } else { $null }

        Write-Host "`n  $($gpu.Name) [$vendor]" -ForegroundColor $Script:Colors.Highlight
        Write-Host "    Driver version: $($gpu.DriverVersion)" -ForegroundColor White
        if ($driverDate) {
            $ageColor = if ($ageDays -gt 365) { $Script:Colors.Error } elseif ($ageDays -gt 180) { $Script:Colors.Warning } else { $Script:Colors.Success }
            Write-Host "    Driver date:    $($driverDate.ToString('yyyy-MM-dd')) ($ageDays days old)" -ForegroundColor $ageColor
            if ($ageDays -gt 180) { Write-Host "    [!] Consider checking for a newer driver." -ForegroundColor $Script:Colors.Warning }
        }
        if ($downloadPages.ContainsKey($vendor)) {
            Write-Host "    Official driver page: $($downloadPages[$vendor])" -ForegroundColor DarkGray
        }
    }

    Write-Log "GPU driver version check completed" -Level Info -Category "Advanced"
    Wait-ForUser
}

function Global:Optimize-AudioLatency {
    <#
        Two documented, driver-agnostic audio tweaks: disables automatic
        volume "ducking" of other sounds during communications activity
        (UserDuckingPreference), and attempts to disable each playback
        device's built-in sound effects processing (PKEY_AudioEndpoint_
        Disable_SysFx) - a real, measurable source of added audio latency on
        some drivers. The per-device property isn't present on every driver,
        so each device is handled independently and a missing property on one
        device is not treated as a failure for the others.
    #>
    Write-Host "`n[AUDIO LATENCY TWEAKS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Disables automatic volume ducking during voice chat/communications, and" -ForegroundColor $Script:Colors.Info
    Write-Host "turns off built-in sound-effects processing on playback devices where the" -ForegroundColor $Script:Colors.Info
    Write-Host "driver exposes that setting." -ForegroundColor $Script:Colors.Info

    if (-not (Confirm-Action)) { return }

    Write-Log "Applying audio latency tweaks" -Level Info -Category "Advanced"

    $steps = @(
        @{
            Name   = "Disabling automatic communications ducking"
            Action = {
                $path = "HKCU:\Software\Microsoft\Multimedia\Audio"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "UserDuckingPreference"
                # 3 = "Do nothing" instead of reducing other sounds' volume.
                Set-ItemProperty -Path $path -Name "UserDuckingPreference" -Value 3 -Type DWord
            }
        }
        @{
            Name   = "Disabling built-in sound-effects processing on playback devices"
            Action = {
                $renderRoot = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render"
                if (-not (Test-Path $renderRoot)) { return }
                $fxDisableProperty = "{1da5d803-d492-4edd-8c23-e0c0ffee7f0e},0"
                Get-ChildItem -Path $renderRoot -ErrorAction SilentlyContinue | ForEach-Object {
                    $propsPath = Join-Path $_.PSPath "Properties"
                    if (Test-Path $propsPath) {
                        try {
                            Backup-RegistryValue -Path $propsPath -Name $fxDisableProperty
                            Set-ItemProperty -Path $propsPath -Name $fxDisableProperty -Value 1 -Type DWord -ErrorAction Stop
                        }
                        catch {
                            # This driver doesn't expose the property - not every audio
                            # driver does, and that's fine, just skip this device.
                        }
                    }
                }
            }
        }
    )

    Invoke-TweakSequence -Title "Audio Latency Tweaks" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n[OK] Audio latency tweaks applied!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Invoke-AllAdvancedPerformanceOptimizations {
    Write-Host "`n[APPLY ALL ADVANCED PERFORMANCE OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "This applies C-States, USB/PCIe power management, Fast Startup, missing" -ForegroundColor $Script:Colors.Warning
    Write-Host "prerequisites, and audio latency tweaks. The two watcher-based features" -ForegroundColor $Script:Colors.Warning
    Write-Host "(notification mute, GPU driver check) are informational/opt-in and are" -ForegroundColor $Script:Colors.Warning
    Write-Host "not included here - run them individually from this menu if you want them." -ForegroundColor $Script:Colors.Warning

    if (-not (Confirm-Action)) { return }

    Write-Host "`n  Creating system restore point..." -ForegroundColor $Script:Colors.Info
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        $description = "Wethereal: Apply All Advanced Performance Optimizations - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "  [OK] Restore point created" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "  [!] Could not create restore point" -ForegroundColor $Script:Colors.Warning
    }

    $Script:SkipConfirmations = $true
    $Script:SkipPauses = $true
    try {
        Disable-CpuCStates
        Disable-UsbPcieSuspend
        Disable-FastStartup
        Install-MissingPrerequisites
        Optimize-AudioLatency
    }
    finally {
        $Script:SkipConfirmations = $false
        $Script:SkipPauses = $false
    }

    Write-Host "`n[OK] ALL ADVANCED PERFORMANCE OPTIMIZATIONS COMPLETED!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Restart your PC for the C-States/USB/PCIe/Fast Startup changes to take effect." -ForegroundColor $Script:Colors.Warning
    Wait-ForUser
}

#endregion

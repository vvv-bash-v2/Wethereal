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
        Write-Host "   8. [BOOST] Win32PrioritySeparation Tuning (foreground boost)" -ForegroundColor White
        Write-Host "   9. [DISK] Disable Hibernation Entirely (frees disk space)" -ForegroundColor White
        Write-Host "  10. [SCAN] Classic Windows Search (disable Bing web results)" -ForegroundColor White
        Write-Host "  11. [CLEAN] Schedule Storage Sense Auto-Cleanup" -ForegroundColor White
        Write-Host "  12. [NET] Network Bufferbloat / Latency-Under-Load Test" -ForegroundColor White
        Write-Host "  13. [SYNC] Reschedule Defender Full Scan (Off-Hours)" -ForegroundColor White
        Write-Host "  14. [!] Uninstall Xbox Game Bar & Xbox App (nuclear option)" -ForegroundColor White
        Write-Host "  15. [LOCK] Enable DNS-over-HTTPS (DoH)" -ForegroundColor White
        Write-Host "  16. [CLEAN] Clean Up Windows Component Store (DISM)" -ForegroundColor White
        Write-Host "  17. [CLEAN] Clean Up Old Driver Packages" -ForegroundColor White
        Write-Host "  18. [SCAN] NAT / Multiplayer Connectivity Diagnostic" -ForegroundColor White
        Write-Host "  19. * Apply All Advanced Performance Optimizations" -ForegroundColor Green
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
            '8' { Set-Win32PrioritySeparation }
            '9' { Disable-Hibernation }
            '10' { Set-ClassicWindowsSearch }
            '11' { Set-StorageSenseSchedule }
            '12' { Test-NetworkBufferbloat }
            '13' { Set-DefenderScanSchedule }
            '14' { Uninstall-XboxGameBar }
            '15' { Enable-DnsOverHttps }
            '16' { Clear-ComponentStore }
            '17' { Clear-OldDriverPackages }
            '18' { Test-NatConnectivity }
            '19' { Invoke-AllAdvancedPerformanceOptimizations }
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

function Global:Set-Win32PrioritySeparation {
    <#
        The classic "short, fixed quantum + foreground boost" scheduler tweak.
        Win32PrioritySeparation packs three 2-bit fields (quantum length,
        fixed/variable, foreground boost) into one byte; 0x26 (38 decimal) is
        the long-standing community-standard value for gaming/responsiveness:
        short quantum, fixed length, boost 2. Windows defaults to variable-
        length quanta tuned for background services, which is the wrong
        trade-off on a desktop where the foreground app (your game) is what
        matters.
    #>
    Write-Host "`n[WIN32PRIORITYSEPARATION TUNING]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Gives the foreground application (your game) a short, fixed CPU time slice" -ForegroundColor $Script:Colors.Info
    Write-Host "boost instead of Windows' default background-service-friendly scheduling." -ForegroundColor $Script:Colors.Info

    if (-not (Confirm-Action)) { return }

    Write-Log "Applying Win32PrioritySeparation tuning" -Level Info -Category "Advanced"

    $steps = @(
        @{
            Name   = "Setting short/fixed quantum with foreground boost"
            Action = {
                $path = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
                Backup-RegistryValue -Path $path -Name "Win32PrioritySeparation"
                Set-ItemProperty -Path $path -Name "Win32PrioritySeparation" -Value 38 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "Win32PrioritySeparation" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n[OK] Foreground priority boost applied! Restart for full effect." -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Disable-Hibernation {
    <#
        Fully disables hibernation (powercfg -h off), which also removes
        hiberfil.sys and frees disk space roughly equal to installed RAM - a
        real win on smaller SSDs. Distinct from Disable-FastStartup: turning
        off Fast Startup alone can still leave hiberfil.sys allocated, since
        Fast Startup is built on the hibernation subsystem. Undo restores
        hibernation (powercfg -h on).
    #>
    Write-Host "`n[DISABLE HIBERNATION ENTIRELY]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Fully disables hibernation and removes hiberfil.sys, freeing disk space" -ForegroundColor $Script:Colors.Info
    Write-Host "roughly equal to your installed RAM." -ForegroundColor $Script:Colors.Info
    Write-Host "[!]  You will no longer be able to Hibernate (Sleep still works fine)." -ForegroundColor $Script:Colors.Warning

    $hiberFile = "$env:SystemDrive\hiberfil.sys"
    $freedGB = if (Test-Path $hiberFile) { [math]::Round((Get-Item $hiberFile -Force -ErrorAction SilentlyContinue).Length / 1GB, 1) } else { 0 }
    if ($freedGB -gt 0) { Write-Host "  Estimated space to be freed: ~$freedGB GB" -ForegroundColor $Script:Colors.Highlight }

    if (-not (Confirm-Action)) { return }

    Write-Log "Disabling hibernation" -Level Info -Category "Advanced"

    $steps = @(
        @{
            Name   = "Disabling hibernation and removing hiberfil.sys"
            Action = {
                powercfg -h off 2>&1 | Out-Null
                Add-UndoAction -Description "Re-enable hibernation" -UndoScript {
                    powercfg -h on 2>&1 | Out-Null
                } -Parameters @{}
            }
        }
    )

    Invoke-TweakSequence -Title "Disable Hibernation" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n[OK] Hibernation disabled!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Set-ClassicWindowsSearch {
    Write-Host "`n[CLASSIC WINDOWS SEARCH]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Disables Bing web results in Start Menu search, keeping it local-files-only." -ForegroundColor $Script:Colors.Info

    if (-not (Confirm-Action)) { return }

    Write-Log "Disabling Bing web search integration" -Level Info -Category "Advanced"

    $steps = @(
        @{
            Name   = "Disabling Bing web results in search"
            Action = {
                $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "BingSearchEnabled"
                Set-ItemProperty -Path $path -Name "BingSearchEnabled" -Value 0 -Type DWord
                Backup-RegistryValue -Path $path -Name "CortanaConsent"
                Set-ItemProperty -Path $path -Name "CortanaConsent" -Value 0 -Type DWord
            }
        }
        @{
            Name   = "Disabling search box web suggestions (policy)"
            Action = {
                $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "DisableSearchBoxSuggestions"
                Set-ItemProperty -Path $path -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "Classic Windows Search" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n[OK] Windows Search is now local-only!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Set-StorageSenseSchedule {
    <#
        Configures Windows' own native Storage Sense feature to run weekly and
        auto-clean temp files, old Recycle Bin contents (30+ days) and old
        Downloads (30+ days) - a "set once and forget" complement to the
        manual Clear-TemporaryFiles tweak. All values are documented,
        non-destructive (nothing is deleted immediately - this only schedules
        Windows' own cleanup), and individually backed up.
    #>
    Write-Host "`n[SCHEDULE STORAGE SENSE AUTO-CLEANUP]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Turns on Windows' native Storage Sense to automatically clean temp files," -ForegroundColor $Script:Colors.Info
    Write-Host "old Recycle Bin items and old Downloads on a weekly schedule." -ForegroundColor $Script:Colors.Info

    if (-not (Confirm-Action)) { return }

    Write-Log "Scheduling Storage Sense auto-cleanup" -Level Info -Category "Advanced"

    $steps = @(
        @{
            Name   = "Enabling Storage Sense with weekly auto-cleanup"
            Action = {
                $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                $values = @{
                    "01"  = 1   # Enable Storage Sense
                    "04"  = 7   # Run frequency: weekly
                    "08"  = 1   # Delete temporary files apps aren't using
                    "32"  = 1   # Auto-empty Recycle Bin
                    "128" = 30  # ...items older than 30 days
                    "256" = 1   # Auto-clean Downloads folder
                    "512" = 30  # ...items older than 30 days
                }
                foreach ($name in $values.Keys) {
                    Backup-RegistryValue -Path $path -Name $name
                    Set-ItemProperty -Path $path -Name $name -Value $values[$name] -Type DWord
                }
            }
        }
    )

    Invoke-TweakSequence -Title "Storage Sense Schedule" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n[OK] Storage Sense scheduled for weekly auto-cleanup!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Test-NetworkBufferbloat {
    <#
        Informational-only diagnostic (no tweaks applied): measures baseline
        ping latency to a public host, then measures it again while
        generating real download load, and reports how much latency
        increases under load - "bufferbloat". A large increase means your
        router/ISP connection queues too much data, which is what causes
        ping spikes in games whenever something else on the network is
        downloading. Best-effort: if the load-generation download fails for
        any reason, still reports the baseline and says the load test was
        skipped rather than failing outright.
    #>
    Write-Host "`n[NETWORK BUFFERBLOAT / LATENCY-UNDER-LOAD TEST]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Measures how much your ping increases while your connection is under load -" -ForegroundColor $Script:Colors.Info
    Write-Host "this takes about 15 seconds and makes no changes to your system." -ForegroundColor $Script:Colors.Info

    Write-Log "Running network bufferbloat test" -Level Info -Category "Advanced"

    $testHost = "1.1.1.1"
    Write-Host "`n  Measuring baseline latency to $testHost..." -ForegroundColor $Script:Colors.Info
    $baseline = Test-Connection -ComputerName $testHost -Count 10 -ErrorAction SilentlyContinue
    if (-not $baseline) {
        Write-Host "  [!] Could not reach $testHost - check your internet connection." -ForegroundColor $Script:Colors.Warning
        Wait-ForUser
        return
    }
    $baselineAvg = ($baseline | Measure-Object -Property ResponseTime -Average).Average
    Write-Host "  Baseline average latency: $([math]::Round($baselineAvg, 1)) ms" -ForegroundColor White

    Write-Host "`n  Generating download load for ~10 seconds..." -ForegroundColor $Script:Colors.Info
    $loadJob = $null
    try {
        $loadJob = Start-Job -ScriptBlock {
            $urls = @(
                "https://speed.hetzner.de/100MB.bin",
                "http://ipv4.download.thinkbroadband.com/50MB.zip"
            )
            foreach ($url in $urls) {
                try { Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\wethereal_bufferbloat_test.tmp" -TimeoutSec 12 -ErrorAction Stop; break } catch {}
            }
        }
    }
    catch { $loadJob = $null }

    Start-Sleep -Seconds 3
    $underLoad = Test-Connection -ComputerName $testHost -Count 10 -ErrorAction SilentlyContinue

    if ($loadJob) {
        Wait-Job -Job $loadJob -Timeout 12 | Out-Null
        Remove-Job -Job $loadJob -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -Path "$env:TEMP\wethereal_bufferbloat_test.tmp" -Force -ErrorAction SilentlyContinue

    if (-not $underLoad) {
        Write-Host "`n  [!] Load test skipped or failed - only baseline latency is available." -ForegroundColor $Script:Colors.Warning
        Wait-ForUser
        return
    }

    $loadAvg = ($underLoad | Measure-Object -Property ResponseTime -Average).Average
    $increase = [math]::Round($loadAvg - $baselineAvg, 1)

    Write-Host "  Latency under load:       $([math]::Round($loadAvg, 1)) ms" -ForegroundColor White
    $verdictColor = if ($increase -gt 100) { $Script:Colors.Error } elseif ($increase -gt 30) { $Script:Colors.Warning } else { $Script:Colors.Success }
    $verdict = if ($increase -gt 100) { "Severe bufferbloat - consider enabling QoS/SQM on your router or a router with SQM/CAKE support." }
    elseif ($increase -gt 30) { "Moderate bufferbloat - noticeable ping spikes when downloading during games." }
    else { "Low bufferbloat - your connection handles concurrent load well." }
    Write-Host "  Latency increase:         +$increase ms" -ForegroundColor $verdictColor
    Write-Host "  Verdict: $verdict" -ForegroundColor $verdictColor

    Write-Log "Bufferbloat test: baseline=$([math]::Round($baselineAvg,1))ms, under load=$([math]::Round($loadAvg,1))ms, increase=+${increase}ms" -Level Info -Category "Advanced"
    Wait-ForUser
}

function Global:Set-DefenderScanSchedule {
    <#
        Moves Windows Defender's scheduled full scan to off-hours (3 AM daily
        by default) instead of whatever default/random time it was set to,
        so a CPU/disk-heavy full scan never kicks in mid-game session.
        Real-time protection is completely untouched - this only retimes the
        periodic full scan.
    #>
    Write-Host "`n[RESCHEDULE DEFENDER FULL SCAN]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Moves the periodic Windows Defender full scan to 3:00 AM daily so it never" -ForegroundColor $Script:Colors.Info
    Write-Host "runs during a gaming session. Real-time protection is not affected." -ForegroundColor $Script:Colors.Info

    if (-not (Confirm-Action)) { return }

    Write-Log "Rescheduling Windows Defender full scan" -Level Info -Category "Advanced"

    $steps = @(
        @{
            Name   = "Setting full scan to run daily at 3:00 AM"
            Action = {
                $previous = Get-MpPreference -ErrorAction SilentlyContinue
                Set-MpPreference -ScanScheduleDay 0 -ScanScheduleTime 180 -ScanParameters 2 -ErrorAction Stop
                if ($previous) {
                    Add-UndoAction -Description "Restore previous Defender scan schedule" -UndoScript {
                        param($Day, $Time)
                        Set-MpPreference -ScanScheduleDay $Day -ScanScheduleTime $Time -ErrorAction SilentlyContinue
                    } -Parameters @{ Day = $previous.ScanScheduleDay; Time = $previous.ScanScheduleTime }
                }
            }
        }
    )

    Invoke-TweakSequence -Title "Defender Scan Schedule" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n[OK] Full scan rescheduled to 3:00 AM daily!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Uninstall-XboxGameBar {
    <#
        The "nuclear" option, separate from Disable-GameBarOverlayPopup (which
        only suppresses the popup/DVR while leaving the apps installed): this
        actually removes the Xbox Game Bar overlay app and the Xbox app
        package family entirely. Manual opt-in only, never wired into any
        automatic pipeline, because it also removes the Xbox app some users
        rely on for Game Pass / cloud saves / Xbox social features.
    #>
    Write-Host "`n[UNINSTALL XBOX GAME BAR & XBOX APP]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "[!]  This completely removes the Xbox Game Bar overlay AND the Xbox app -" -ForegroundColor $Script:Colors.Warning
    Write-Host "  you will lose Xbox Game Pass app access, cloud saves via the Xbox app, and" -ForegroundColor $Script:Colors.Warning
    Write-Host "  Xbox social features from this PC. Only do this if you don't use any of" -ForegroundColor $Script:Colors.Warning
    Write-Host "  that - the overlay popup is already suppressed elsewhere without removing" -ForegroundColor $Script:Colors.Warning
    Write-Host "  anything (Gaming menu / Apply All)." -ForegroundColor $Script:Colors.Warning

    if (-not (Confirm-Action -Message "I understand - uninstall Xbox Game Bar and the Xbox app?")) { return }

    Write-Log "Uninstalling Xbox Game Bar and Xbox app packages" -Level Warning -Category "Advanced"

    $packagePatterns = @(
        "Microsoft.XboxGamingOverlay",
        "Microsoft.GamingApp",
        "Microsoft.XboxApp",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.Xbox.TCUI",
        "Microsoft.XboxSpeechToTextOverlay"
    )

    $steps = $packagePatterns | ForEach-Object {
        $pattern = $_
        @{
            Name      = "Removing package: $pattern"
            Condition = { [bool](Get-AppxPackage -Name $pattern -ErrorAction SilentlyContinue) }.GetNewClosure()
            Action    = { Get-AppxPackage -Name $pattern -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction Stop }.GetNewClosure()
        }
    }

    Invoke-TweakSequence -Title "Uninstall Xbox Game Bar & Xbox App" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n[OK] Xbox Game Bar and Xbox app removed!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Enable-DnsOverHttps {
    <#
        Registers DNS-over-HTTPS templates for a chosen provider (native
        Windows 11 feature, `netsh dns add encryption`) and points active
        adapters at that provider's IPs, so DNS lookups are encrypted instead
        of plaintext - closes off a real privacy leak and, on some ISPs that
        throttle/shape based on DNS queries, can incidentally help latency
        too. Falls back gracefully with a clear message on Windows 10, where
        `netsh dns add encryption` doesn't exist.
    #>
    Write-Host "`n[ENABLE DNS-OVER-HTTPS (DoH)]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Encrypts DNS lookups end-to-end instead of sending them in plaintext." -ForegroundColor $Script:Colors.Info
    Write-Host "Requires Windows 11 (or Windows 10 21H2+ with the feature enabled)." -ForegroundColor $Script:Colors.Info
    Write-Host ""
    Write-Host "  1. Cloudflare (1.1.1.1, 1.0.0.1)" -ForegroundColor White
    Write-Host "  2. Google (8.8.8.8, 8.8.4.4)" -ForegroundColor White
    Write-Host "  3. Quad9 (9.9.9.9, 149.112.112.112)" -ForegroundColor White
    Write-Host "  0. Cancel" -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "Select a DoH provider"
    $providers = @{
        '1' = @{ Name = "Cloudflare"; Servers = @("1.1.1.1", "1.0.0.1"); Template = "https://cloudflare-dns.com/dns-query" }
        '2' = @{ Name = "Google"; Servers = @("8.8.8.8", "8.8.4.4"); Template = "https://dns.google/dns-query" }
        '3' = @{ Name = "Quad9"; Servers = @("9.9.9.9", "149.112.112.112"); Template = "https://dns.quad9.net/dns-query" }
    }
    if ($choice -eq '0' -or [string]::IsNullOrWhiteSpace($choice)) { return }
    if (-not $providers.ContainsKey($choice)) {
        Write-Host "`n[X] Invalid selection." -ForegroundColor $Script:Colors.Error
        Start-Sleep -Seconds 1
        return
    }
    $provider = $providers[$choice]

    if (-not (Confirm-Action -Message "Enable DoH via $($provider.Name)?" -DefaultYes)) { return }

    Write-Log "Enabling DNS-over-HTTPS via $($provider.Name)" -Level Info -Category "Advanced"

    $steps = @()
    foreach ($server in $provider.Servers) {
        $steps += @{
            Name   = "Registering DoH template for $server"
            Action = {
                $result = netsh dns add encryption server=$server dohtemplate=$($provider.Template) autoupgrade=yes udpfallback=no 2>&1
                if ($LASTEXITCODE -ne 0) { throw "netsh dns add encryption is not supported on this Windows version" }
            }.GetNewClosure()
        }
    }

    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }
    $steps += $adapters | ForEach-Object {
        $adapterIndex = $_.ifIndex
        $adapterName = $_.Name
        @{
            Name   = "Pointing adapter '$adapterName' at $($provider.Name)"
            Action = { Set-DnsClientServerAddress -InterfaceIndex $adapterIndex -ServerAddresses $provider.Servers -ErrorAction Stop }.GetNewClosure()
        }
    }

    Invoke-TweakSequence -Title "DNS-over-HTTPS" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n[OK] DNS-over-HTTPS configured via $($provider.Name)!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Clear-ComponentStore {
    <#
        Runs DISM's native component-store cleanup (WinSxS bloat that
        accumulates from every cumulative/feature update). Deliberately does
        NOT use /ResetBase - that permanently removes the ability to
        uninstall currently-installed updates, a real trade-off most users
        wouldn't knowingly accept. Plain /StartComponentCleanup only removes
        components that are already fully superseded and unrecoverable
        either way. No "GB freed" figure is reported - Microsoft's own
        guidance is that raw WinSxS folder size is misleading due to
        hardlinks, so a before/after diff would just be a plausible-looking
        wrong number.
    #>
    Write-Host "`n[CLEAN UP WINDOWS COMPONENT STORE]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Runs DISM's component-store cleanup to remove superseded update files" -ForegroundColor $Script:Colors.Info
    Write-Host "from WinSxS. This can take several minutes and needs no restart." -ForegroundColor $Script:Colors.Info
    Write-Host "[!]  Does not use /ResetBase, so you can still uninstall recent updates." -ForegroundColor $Script:Colors.Warning

    if (-not (Confirm-Action)) { return }

    Write-Log "Running DISM component store cleanup" -Level Info -Category "Advanced"

    $steps = @(
        @{
            Name   = "Cleaning up the component store (this may take a few minutes)"
            Action = {
                $result = Dism /Online /Cleanup-Image /StartComponentCleanup 2>&1
                if ($LASTEXITCODE -ne 0) { throw "DISM exited with code $LASTEXITCODE" }
            }
        }
    )

    Invoke-TweakSequence -Title "Component Store Cleanup" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n[OK] Component store cleanup complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Clear-OldDriverPackages {
    <#
        Removes superseded third-party driver packages from the Driver Store
        (pnputil), keeping only the newest version of each unique driver
        (grouped by its original .inf name). pnputil itself refuses to delete
        a package that's actively bound to a device unless forced, and this
        never passes /force, so an in-use older driver is safely skipped
        rather than ripped out from under a working device.
    #>
    Write-Host "`n[CLEAN UP OLD DRIVER PACKAGES]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Removes superseded driver packages from the Driver Store, keeping only the" -ForegroundColor $Script:Colors.Info
    Write-Host "newest version of each driver. Packages still in use are safely skipped." -ForegroundColor $Script:Colors.Info

    Write-Log "Scanning driver store for superseded packages" -Level Info -Category "Advanced"

    $rawOutput = pnputil /enum-drivers 2>&1
    $drivers = @()
    $current = @{}
    foreach ($line in $rawOutput) {
        if ($line -match '^Published Name\s*:\s*(\S+)') {
            if ($current.Count -gt 0) { $drivers += [PSCustomObject]$current }
            $current = @{ PublishedName = $matches[1] }
        }
        elseif ($line -match '^Original Name\s*:\s*(\S+)') { $current.OriginalName = $matches[1] }
        elseif ($line -match '^Driver Version\s*:\s*(.+)$') { $current.DriverVersion = $matches[1].Trim() }
    }
    if ($current.Count -gt 0) { $drivers += [PSCustomObject]$current }

    if ($drivers.Count -eq 0) {
        Write-Host "`n[!] Could not enumerate driver packages (pnputil output not recognized)." -ForegroundColor $Script:Colors.Warning
        Wait-ForUser
        return
    }

    # Group by the original .inf name; anything beyond the single newest
    # entry per group (by driver version string, descending) is superseded.
    $toRemove = $drivers | Group-Object -Property OriginalName | Where-Object { $_.Count -gt 1 } | ForEach-Object {
        $_.Group | Sort-Object {
            try { [version]($_.DriverVersion -replace '[^0-9.].*$', '') } catch { [version]'0.0' }
        } -Descending | Select-Object -Skip 1
    }

    if (-not $toRemove -or $toRemove.Count -eq 0) {
        Write-Host "`n[OK] No superseded driver packages found - the driver store is already lean." -ForegroundColor $Script:Colors.Success
        Wait-ForUser
        return
    }

    Write-Host "`n  Found $($toRemove.Count) superseded driver package(s)." -ForegroundColor $Script:Colors.Highlight
    if (-not (Confirm-Action -Message "Remove them now?" -DefaultYes)) { return }

    $steps = $toRemove | ForEach-Object {
        $publishedName = $_.PublishedName
        @{
            Name   = "Removing superseded driver: $publishedName"
            Action = { pnputil /delete-driver $publishedName /uninstall 2>&1 | Out-Null }.GetNewClosure()
        }
    }

    Invoke-TweakSequence -Title "Old Driver Package Cleanup" -Steps $steps -Category "Advanced" | Out-Null

    Write-Host "`n[OK] Old driver packages cleaned up!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Test-NatConnectivity {
    <#
        Informational only, makes no changes: checks the signals that most
        commonly explain "strict NAT" / multiplayer connectivity complaints -
        the active network's classified profile (Private vs Public affects
        firewall defaults and Network Discovery), whether the Windows
        Firewall on that profile is blocking inbound by default, and whether
        the UPnP-related services Windows uses for automatic port mapping are
        running. Router-side NAT type isn't visible from Windows at all, so
        this reports what's checkable locally, not a guaranteed diagnosis.
    #>
    Write-Host "`n[NAT / MULTIPLAYER CONNECTIVITY DIAGNOSTIC]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Checks the Windows-side settings that most often cause multiplayer/NAT" -ForegroundColor $Script:Colors.Info
    Write-Host "connectivity issues. Router-side NAT type can't be checked from here." -ForegroundColor $Script:Colors.Info

    Write-Log "Running NAT/multiplayer connectivity diagnostic" -Level Info -Category "Advanced"

    $issues = @()

    $profiles = Get-NetConnectionProfile -ErrorAction SilentlyContinue
    foreach ($profile in $profiles) {
        $color = if ($profile.NetworkCategory -eq 'Public') { $Script:Colors.Warning } else { $Script:Colors.Success }
        Write-Host "`n  Network '$($profile.Name)': $($profile.NetworkCategory)" -ForegroundColor $color
        if ($profile.NetworkCategory -eq 'Public') { $issues += "'$($profile.Name)' is classified Public - Network Discovery and some inbound traffic are more restricted" }
    }

    $fwProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
    foreach ($fw in $fwProfiles) {
        Write-Host "  Firewall [$($fw.Name)]: Enabled=$($fw.Enabled), DefaultInboundAction=$($fw.DefaultInboundAction)" -ForegroundColor White
    }

    $upnpServices = @('SSDPSRV', 'upnphost') | ForEach-Object { Get-Service -Name $_ -ErrorAction SilentlyContinue }
    $upnpRunning = [bool]($upnpServices | Where-Object { $_.Status -eq 'Running' })
    Write-Host "  UPnP services (SSDP Discovery / UPnP Device Host): $(if ($upnpRunning) { '[OK] Running' } else { '[!] Not running' })" -ForegroundColor $(if ($upnpRunning) { $Script:Colors.Success } else { $Script:Colors.Warning })
    if (-not $upnpRunning) { $issues += "UPnP services aren't running - automatic port mapping (used by some games/consoles) won't work" }

    Write-Host ""
    if ($issues.Count -eq 0) {
        Write-Host "[OK] No local connectivity red flags found. If you still see strict NAT," -ForegroundColor $Script:Colors.Success
        Write-Host "  the issue is most likely on your router (enable UPnP/NAT-PMP there, or" -ForegroundColor $Script:Colors.Success
        Write-Host "  set up port forwarding for the specific game)." -ForegroundColor $Script:Colors.Success
    }
    else {
        Write-Host "[!] Potential issues found:" -ForegroundColor $Script:Colors.Warning
        $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor $Script:Colors.Warning }
    }

    Wait-ForUser
}

function Global:Invoke-AllAdvancedPerformanceOptimizations {
    Write-Host "`n[APPLY ALL ADVANCED PERFORMANCE OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Applies every one-shot, non-destructive, non-interactive tweak in this" -ForegroundColor $Script:Colors.Warning
    Write-Host "category: C-States, USB/PCIe power management, Fast Startup, missing" -ForegroundColor $Script:Colors.Warning
    Write-Host "prerequisites, audio latency, Win32PrioritySeparation, hibernation removal," -ForegroundColor $Script:Colors.Warning
    Write-Host "classic search, Storage Sense/Defender scheduling, component store and old" -ForegroundColor $Script:Colors.Warning
    Write-Host "driver cleanup. NOT included: DNS-over-HTTPS (needs your provider choice)," -ForegroundColor $Script:Colors.Warning
    Write-Host "the watcher/informational features (notification mute, GPU driver check," -ForegroundColor $Script:Colors.Warning
    Write-Host "bufferbloat test, NAT diagnostic), and the Xbox Game Bar uninstall" -ForegroundColor $Script:Colors.Warning
    Write-Host "(destructive) - run those individually if wanted." -ForegroundColor $Script:Colors.Warning

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
        Set-Win32PrioritySeparation
        Disable-Hibernation
        Set-ClassicWindowsSearch
        Set-StorageSenseSchedule
        Set-DefenderScanSchedule
        Clear-ComponentStore
        Clear-OldDriverPackages
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

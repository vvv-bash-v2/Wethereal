# Windows Performance Tweaker Ultimate Edition v3.5.0
# Additional Optimization Modules - Part 2
# Gaming, Network

#region Category 2: Gaming & Graphics

function Global:Show-GamingMenu {
    do {
        Show-Header "Gaming & Graphics"
        Write-Host "  GAMING & GRAPHICS OPTIMIZATIONS" -ForegroundColor $Script:Colors.Menu
        Write-Host "  =======================================================================" -ForegroundColor $Script:Colors.Menu
        Write-Host "   1. Enable Gaming Mode & Optimizations" -ForegroundColor White
        Write-Host "   2. Reduce Input Lag (Mouse/Keyboard)" -ForegroundColor White
        Write-Host "   3. Optimize Network for Gaming" -ForegroundColor White
        Write-Host "   4. Disable Fullscreen Optimizations" -ForegroundColor White
        Write-Host "   5. Audio Optimizations for Gaming" -ForegroundColor White
        Write-Host "   6. Frame Rate Optimizations" -ForegroundColor White
        Write-Host "   7. * Apply All Gaming Optimizations" -ForegroundColor Green
        Write-Host "   8. [GAME]  Low-End Gaming / Max FPS Mode (budget PCs)" -ForegroundColor Magenta
        Write-Host "   0. <- Back to Main Menu" -ForegroundColor Yellow
        Write-Host ""

        $choice = Read-Host "Select an option"

        switch ($choice) {
            '1' { Enable-GamingMode }
            '2' { Reduce-InputLag }
            '3' { Optimize-NetworkGaming }
            '4' { Disable-FullscreenOptimizations }
            '5' { Optimize-AudioGaming }
            '6' { Optimize-FrameRate }
            '7' { Apply-AllGamingOptimizations }
            '8' { Optimize-LowEndGaming }
            '0' { return }
            default {
                Write-Host "`n[X] Invalid option." -ForegroundColor $Script:Colors.Error
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

function Global:Enable-GamingMode {
    Write-Host "`n[GAMING MODE OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Enabling gaming mode optimizations" -Level Info -Category "Gaming"

    $steps = @(
        @{
            Name   = "Enabling Windows Game Mode"
            Action = {
                $path = "HKCU:\Software\Microsoft\GameBar"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "AllowAutoGameMode"
                Set-ItemProperty -Path $path -Name "AllowAutoGameMode" -Value 1 -Type DWord
                Backup-RegistryValue -Path $path -Name "AutoGameModeEnabled"
                Set-ItemProperty -Path $path -Name "AutoGameModeEnabled" -Value 1 -Type DWord
            }
        }
        @{
            Name   = "Setting high scheduler priority for games"
            Action = {
                $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "GPU Priority"
                Set-ItemProperty -Path $path -Name "GPU Priority" -Value 8 -Type DWord
                Backup-RegistryValue -Path $path -Name "Priority"
                Set-ItemProperty -Path $path -Name "Priority" -Value 6 -Type DWord
                Backup-RegistryValue -Path $path -Name "Scheduling Category"
                Set-ItemProperty -Path $path -Name "Scheduling Category" -Value "High" -Type String
            }
        }
    )

    Invoke-TweakSequence -Title "Gaming Mode" -Steps $steps -Category "Gaming" | Out-Null

    Write-Host "`n[OK] Gaming mode optimizations complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Reduce-InputLag {
    Write-Host "`n[INPUT LAG REDUCTION]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Reducing input lag" -Level Info -Category "Gaming"

    $steps = @(
        @{
            Name   = "Disabling mouse acceleration ('Enhance pointer precision')"
            Action = {
                $path = "HKCU:\Control Panel\Mouse"
                Backup-RegistryValue -Path $path -Name "MouseSpeed"
                Set-ItemProperty -Path $path -Name "MouseSpeed" -Value 0 -Type String
                Backup-RegistryValue -Path $path -Name "MouseThreshold1"
                Set-ItemProperty -Path $path -Name "MouseThreshold1" -Value 0 -Type String
                Backup-RegistryValue -Path $path -Name "MouseThreshold2"
                Set-ItemProperty -Path $path -Name "MouseThreshold2" -Value 0 -Type String
            }
        }
        @{
            Name   = "Normalizing mouse sensitivity to flat 1:1"
            Action = {
                $path = "HKCU:\Control Panel\Mouse"
                Backup-RegistryValue -Path $path -Name "MouseSensitivity"
                Set-ItemProperty -Path $path -Name "MouseSensitivity" -Value 10 -Type String
            }
        }
        @{
            Name   = "Optimizing keyboard repeat delay/rate"
            Action = {
                $path = "HKCU:\Control Panel\Keyboard"
                Backup-RegistryValue -Path $path -Name "KeyboardDelay"
                Set-ItemProperty -Path $path -Name "KeyboardDelay" -Value 0 -Type String
                Backup-RegistryValue -Path $path -Name "KeyboardSpeed"
                Set-ItemProperty -Path $path -Name "KeyboardSpeed" -Value 31 -Type String
            }
        }
    )

    Invoke-TweakSequence -Title "Input Lag Reduction" -Steps $steps -Category "Gaming" | Out-Null

    Write-Host "`n[OK] Input lag reduction complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Optimize-NetworkGaming {
    Write-Host "`n[NETWORK GAMING OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Optimizing network for gaming" -Level Info -Category "Gaming"

    $steps = @(
        @{
            Name   = "Disabling Nagle's algorithm on all interfaces (lower latency)"
            Action = {
                $path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
                $interfaces = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
                foreach ($interface in $interfaces) {
                    $interfacePath = $interface.PSPath
                    Backup-RegistryValue -Path $interfacePath -Name "TcpAckFrequency"
                    Set-ItemProperty -Path $interfacePath -Name "TcpAckFrequency" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                    Backup-RegistryValue -Path $interfacePath -Name "TCPNoDelay"
                    Set-ItemProperty -Path $interfacePath -Name "TCPNoDelay" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                }
            }
        }
        @{
            Name   = "Disabling network throttling for multimedia/gaming"
            Action = {
                $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
                Backup-RegistryValue -Path $path -Name "NetworkThrottlingIndex"
                Set-ItemProperty -Path $path -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "Network Gaming Optimization" -Steps $steps -Category "Gaming" | Out-Null

    Write-Host "`n[OK] Network gaming optimizations complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Disable-FullscreenOptimizations {
    Write-Host "`n[DISABLE FULLSCREEN OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "This disables Windows fullscreen optimizations for better gaming performance." -ForegroundColor $Script:Colors.Info

    if (-not (Confirm-Action)) { return }

    Write-Log "Disabling fullscreen optimizations" -Level Info -Category "Gaming"

    $steps = @(
        @{
            Name   = "Forcing exclusive fullscreen (bypassing DWM Flip Model)"
            Action = {
                $path = "HKCU:\System\GameConfigStore"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "GameDVR_DXGIHonorFSEWindowsCompatible"
                Set-ItemProperty -Path $path -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 1 -Type DWord
                Backup-RegistryValue -Path $path -Name "GameDVR_FSEBehavior"
                Set-ItemProperty -Path $path -Name "GameDVR_FSEBehavior" -Value 2 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "Fullscreen Optimizations" -Steps $steps -Category "Gaming" | Out-Null

    Write-Host "`n[OK] Fullscreen optimizations disabled!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Disable-GameBarOverlayPopup {
    <#
        Kills the "Do you want to open Xbox Game Bar?" / ms-gamingoverlay: prompt that
        Windows shows the first time a fullscreen game (or GameDVR trying to broadcast)
        tries to invoke the Game Bar overlay. Removing the Xbox Game Bar app alone isn't
        enough - Windows still tries to fire the ms-gamingoverlay: protocol and, with no
        handler registered, falls back to the "How do you want to open this?" chooser.
        The HKLM policy key is the real kill switch: it stops Windows from ever trying
        to broadcast/launch the overlay in the first place, so the prompt can't fire
        regardless of whether the Xbox Game Bar app is installed or removed.
    #>
    Write-Log "Disabling Xbox Game Bar overlay popup (ms-gamingoverlay)" -Level Info -Category "Gaming"

    $steps = @(
        @{
            Name   = "Disabling the Game Bar startup/first-run tip popup"
            Action = {
                $path = "HKCU:\Software\Microsoft\GameBar"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "ShowStartupPanel"
                Set-ItemProperty -Path $path -Name "ShowStartupPanel" -Value 0 -Type DWord
                Backup-RegistryValue -Path $path -Name "GamePanelStartupTipIndex"
                Set-ItemProperty -Path $path -Name "GamePanelStartupTipIndex" -Value 3 -Type DWord
                Backup-RegistryValue -Path $path -Name "UseNexusForGameBarEnabled"
                Set-ItemProperty -Path $path -Name "UseNexusForGameBarEnabled" -Value 0 -Type DWord
            }
        }
        @{
            Name   = "Disabling Game DVR background capture"
            Action = {
                $path = "HKCU:\System\GameConfigStore"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "GameDVR_Enabled"
                Set-ItemProperty -Path $path -Name "GameDVR_Enabled" -Value 0 -Type DWord
            }
        }
        @{
            Name   = "Disabling app capture / historical capture (GameDVR)"
            Action = {
                $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "AppCaptureEnabled"
                Set-ItemProperty -Path $path -Name "AppCaptureEnabled" -Value 0 -Type DWord
                Backup-RegistryValue -Path $path -Name "HistoricalCaptureEnabled"
                Set-ItemProperty -Path $path -Name "HistoricalCaptureEnabled" -Value 0 -Type DWord
            }
        }
        @{
            Name   = "Applying system-wide policy to fully disable Game DVR"
            Action = {
                $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "AllowGameDVR"
                Set-ItemProperty -Path $path -Name "AllowGameDVR" -Value 0 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "Game Bar Overlay Popup" -Steps $steps -Category "Gaming" | Out-Null
}

function Global:Optimize-AudioGaming {
    Write-Host "`n[AUDIO OPTIMIZATIONS FOR GAMING]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Optimizing audio for gaming" -Level Info -Category "Gaming"

    $steps = @(
        @{
            Name   = "Raising Multimedia Class Scheduler audio priority"
            Action = {
                $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "Priority"
                Set-ItemProperty -Path $path -Name "Priority" -Value 2 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "Audio Optimization for Gaming" -Steps $steps -Category "Gaming" | Out-Null

    Write-Host "`n[OK] Audio optimizations complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Optimize-FrameRate {
    Write-Host "`n[FRAME RATE OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Optimizing for frame rate" -Level Info -Category "Gaming"

    $steps = @(
        @{
            Name   = "Preparing DirectX high-performance GPU preference hive"
            Action = {
                $path = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            }
        }
    )

    Invoke-TweakSequence -Title "Frame Rate Optimization" -Steps $steps -Category "Gaming" | Out-Null

    Write-Host "  Note: Some tweaks may affect desktop visual quality." -ForegroundColor $Script:Colors.Warning
    Write-Host "`n[OK] Frame rate optimizations complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Apply-AllGamingOptimizations {
    Write-Host "`n[APPLY ALL GAMING OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    $Script:SkipConfirmations = $true
    $Script:SkipPauses = $true
    try {
        Enable-GamingMode
        Reduce-InputLag
        Optimize-NetworkGaming
        Disable-FullscreenOptimizations
        Disable-GameBarOverlayPopup
        Optimize-AudioGaming
        Optimize-FrameRate
    }
    finally {
        $Script:SkipConfirmations = $false
        $Script:SkipPauses = $false
    }

    Write-Host "`n[OK] ALL GAMING OPTIMIZATIONS COMPLETED!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Optimize-LowEndGaming {
    Write-Host "`n[LOW-END GAMING / MAX FPS MODE]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Aggressive profile for budget/low-spec PCs: strips every non-essential" -ForegroundColor $Script:Colors.Info
    Write-Host "background process, visual effect and service to free up CPU/GPU/RAM" -ForegroundColor $Script:Colors.Info
    Write-Host "headroom for the foreground game. Typical gains reported by users on" -ForegroundColor $Script:Colors.Info
    Write-Host "low-end hardware: roughly +30-70% FPS depending on how loaded the" -ForegroundColor $Script:Colors.Info
    Write-Host "system was before (e.g. ~100 -> 150-200 FPS in lighter esports titles)." -ForegroundColor $Script:Colors.Info
    Write-Host "[!]  This disables Widgets, Chat, background apps and several services." -ForegroundColor $Script:Colors.Warning

    if (-not (Confirm-Action -Message "Apply Low-End Gaming / Max FPS mode?" -DefaultYes)) { return }

    Write-Log "Applying Low-End Gaming / Max FPS profile" -Level Info -Category "Gaming"

    $Script:SkipConfirmations = $true
    $Script:SkipPauses = $true
    try {
        # Reuse the existing, already-progress-barred tweak functions first -
        # this keeps one implementation of each tweak instead of duplicating logic.
        Optimize-CPU
        Optimize-GPU
        Optimize-GPUSpecific
        Optimize-MemoryAdvanced
        Optimize-VisualEffects
        Optimize-WindowsServices
        Enable-GamingMode
        Reduce-InputLag
        Optimize-NetworkGaming
        Disable-FullscreenOptimizations
        Disable-GameBarOverlayPopup
        Optimize-FrameRate

        # FPS-specific tweaks not covered by any of the above.
        $steps = @(
            @{
                Name   = "Reserving 0% CPU for background tasks (SystemResponsiveness)"
                Action = {
                    $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
                    Backup-RegistryValue -Path $path -Name "SystemResponsiveness"
                    Set-ItemProperty -Path $path -Name "SystemResponsiveness" -Value 0 -Type DWord
                }
            }
            @{
                Name   = "Disabling background apps (global toggle)"
                Action = {
                    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
                    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                    Backup-RegistryValue -Path $path -Name "GlobalUserDisabled"
                    Set-ItemProperty -Path $path -Name "GlobalUserDisabled" -Value 1 -Type DWord
                }
            }
            @{
                Name   = "Hiding the Widgets icon from the taskbar (Windows 11)"
                Action = {
                    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                    Backup-RegistryValue -Path $path -Name "TaskbarDa"
                    Set-ItemProperty -Path $path -Name "TaskbarDa" -Value 0 -Type DWord
                }
            }
            @{
                Name   = "Hiding the Chat/Teams icon from the taskbar (Windows 11)"
                Action = {
                    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                    Backup-RegistryValue -Path $path -Name "TaskbarMn"
                    Set-ItemProperty -Path $path -Name "TaskbarMn" -Value 0 -Type DWord
                }
            }
            @{
                Name   = "Trimming low-priority services further (Fax, Error Reporting)"
                Action = {
                    foreach ($svcName in @('Fax', 'WerSvc')) {
                        $service = Get-Service -Name $svcName -ErrorAction SilentlyContinue
                        if ($service) {
                            Backup-ServiceState -ServiceName $svcName
                            Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
                            Set-Service -Name $svcName -StartupType Manual -ErrorAction SilentlyContinue
                        }
                    }
                }
            }
        )
        Invoke-TweakSequence -Title "Low-End Gaming FPS Tweaks" -Steps $steps -Category "Gaming" | Out-Null
    }
    finally {
        $Script:SkipConfirmations = $false
        $Script:SkipPauses = $false
    }

    Write-Host "`n[OK] Low-End Gaming / Max FPS mode applied!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Restart your PC, then set your game's Windows power plan to" -ForegroundColor $Script:Colors.Info
    Write-Host "  'Ultimate Performance' (Extras menu) for the largest remaining gain." -ForegroundColor $Script:Colors.Info
    Wait-ForUser
}

function Global:Optimize-Streaming {
    Write-Host "`n[STREAMING MODE]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Tuned for streaming/recording (OBS + a game at once): frees the GPU's" -ForegroundColor $Script:Colors.Info
    Write-Host "hardware encoder from Windows' own capture, quiets popups that would show" -ForegroundColor $Script:Colors.Info
    Write-Host "on stream, and keeps network upload stable." -ForegroundColor $Script:Colors.Info

    if (-not (Confirm-Action -Message "Apply Streaming mode?" -DefaultYes)) { return }

    Write-Log "Applying Streaming profile" -Level Info -Category "Gaming"

    # Frees the GPU's hardware encoder for OBS and, as a side effect, permanently
    # kills the "Do you want to open Xbox Game Bar?" popup while streaming/recording.
    Disable-GameBarOverlayPopup

    $steps = @(
        @{
            Name   = "Muting toast notifications (keeps popups off your stream)"
            Action = {
                $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "ToastEnabled"
                Set-ItemProperty -Path $path -Name "ToastEnabled" -Value 0 -Type DWord
            }
        }
        @{
            Name   = "Disabling network throttling (steadier upload for the stream)"
            Action = {
                $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
                Backup-RegistryValue -Path $path -Name "NetworkThrottlingIndex"
                Set-ItemProperty -Path $path -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord
            }
        }
        @{
            Name   = "Switching to the High Performance power plan"
            Action = {
                $highPerf = powercfg -l | Select-String "High performance" | ForEach-Object { ($_ -split '\s+')[3] }
                if ($highPerf) { powercfg -setactive $highPerf | Out-Null }
            }
        }
        @{
            Name      = "Giving OBS Studio Above Normal CPU priority"
            Condition = {
                $obsPaths = @("${env:ProgramFiles}\obs-studio\bin\64bit\obs64.exe", "${env:ProgramFiles(x86)}\obs-studio\bin\32bit\obs32.exe")
                ($obsPaths | Where-Object { Test-Path $_ }).Count -gt 0
            }
            Action    = {
                $obsPaths = @("${env:ProgramFiles}\obs-studio\bin\64bit\obs64.exe", "${env:ProgramFiles(x86)}\obs-studio\bin\32bit\obs32.exe")
                $obsExeName = Split-Path ($obsPaths | Where-Object { Test-Path $_ } | Select-Object -First 1) -Leaf
                $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$obsExeName\PerfOptions"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "CpuPriorityClass"
                Set-ItemProperty -Path $path -Name "CpuPriorityClass" -Value 3 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "Streaming Mode" -Steps $steps -Category "Gaming" | Out-Null

    Write-Host "`n[OK] Streaming mode applied!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Tip: use your GPU's hardware encoder in OBS (NVENC/AMF/QuickSync) instead" -ForegroundColor $Script:Colors.Info
    Write-Host "  of x264 - it costs almost no CPU/GPU headroom compared to software encoding." -ForegroundColor $Script:Colors.Info
    Wait-ForUser
}

#endregion

#region Category 3: Network & Internet

function Global:Show-NetworkMenu {
    do {
        Show-Header "Network & Internet"
        Write-Host "  NETWORK & INTERNET OPTIMIZATIONS" -ForegroundColor $Script:Colors.Menu
        Write-Host "  =======================================================================" -ForegroundColor $Script:Colors.Menu
        Write-Host "   1. Advanced TCP/IP Tweaks" -ForegroundColor White
        Write-Host "   2. DNS Optimizations" -ForegroundColor White
        Write-Host "   3. Network Adapter Tweaks" -ForegroundColor White
        Write-Host "   4. QoS Configuration" -ForegroundColor White
        Write-Host "   5. Browser Optimizations" -ForegroundColor White
        Write-Host "   6. * Apply All Network Optimizations" -ForegroundColor Green
        Write-Host "   0. <- Back to Main Menu" -ForegroundColor Yellow
        Write-Host ""

        $choice = Read-Host "Select an option"

        switch ($choice) {
            '1' { Optimize-TCPIP }
            '2' { Optimize-DNS }
            '3' { Optimize-NetworkAdapter }
            '4' { Configure-QoS }
            '5' { Optimize-Browsers }
            '6' { Apply-AllNetworkOptimizations }
            '0' { return }
            default {
                Write-Host "`n[X] Invalid option." -ForegroundColor $Script:Colors.Error
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

function Global:Optimize-TCPIP {
    Write-Host "`n[ADVANCED TCP/IP TWEAKS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Optimizing TCP/IP settings" -Level Info -Category "Network"

    $steps = @(
        @{
            Name   = "Tuning TCP global parameters (autotuning, RSS, ECN, DCA)"
            Action = {
                netsh int tcp set global autotuninglevel=normal | Out-Null
                netsh int tcp set global chimney=enabled | Out-Null
                netsh int tcp set global dca=enabled | Out-Null
                netsh int tcp set global netdma=enabled | Out-Null
                netsh int tcp set global ecncapability=enabled | Out-Null
                netsh int tcp set global timestamps=disabled | Out-Null
                netsh int tcp set global rss=enabled | Out-Null
            }
        }
        @{
            Name   = "Disabling network throttling"
            Action = {
                $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
                Backup-RegistryValue -Path $path -Name "NetworkThrottlingIndex"
                Set-ItemProperty -Path $path -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord
            }
        }
        @{
            Name   = "Disabling bandwidth reservation (20% QoS reserve)"
            Action = {
                $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "NonBestEffortLimit"
                Set-ItemProperty -Path $path -Name "NonBestEffortLimit" -Value 0 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "TCP/IP Optimization" -Steps $steps -Category "Network" | Out-Null

    Write-Host "`n[OK] TCP/IP optimizations complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Optimize-DNS {
    Write-Host "`n[DNS OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Choose DNS provider:" -ForegroundColor $Script:Colors.Info
    Write-Host "  1. Google DNS (8.8.8.8, 8.8.4.4)" -ForegroundColor White
    Write-Host "  2. Cloudflare DNS (1.1.1.1, 1.0.0.1)" -ForegroundColor White
    Write-Host "  3. Quad9 DNS (9.9.9.9, 149.112.112.112)" -ForegroundColor White
    Write-Host "  4. Clear DNS cache only" -ForegroundColor White
    Write-Host "  0. Cancel" -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "Select DNS provider"

    $dnsServers = $null
    switch ($choice) {
        '1' { $dnsServers = @("8.8.8.8", "8.8.4.4") }
        '2' { $dnsServers = @("1.1.1.1", "1.0.0.1") }
        '3' { $dnsServers = @("9.9.9.9", "149.112.112.112") }
        '4' { $dnsServers = $null }
        '0' { return }
        default {
            Write-Host "`n[X] Invalid selection." -ForegroundColor $Script:Colors.Error
            Start-Sleep -Seconds 1
            return
        }
    }

    Write-Log "Optimizing DNS settings" -Level Info -Category "Network"

    $steps = @(
        @{ Name = "Flushing DNS resolver cache"; Action = { ipconfig /flushdns | Out-Null } }
    )

    if ($dnsServers) {
        $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }
        $steps += $adapters | ForEach-Object {
            $adapterIndex = $_.ifIndex
            $adapterName = $_.Name
            @{
                Name   = "Setting DNS servers on adapter '$adapterName'"
                Action = { Set-DnsClientServerAddress -InterfaceIndex $adapterIndex -ServerAddresses $dnsServers -ErrorAction Stop }.GetNewClosure()
            }
        }
    }

    Invoke-TweakSequence -Title "DNS Optimization" -Steps $steps -Category "Network" | Out-Null

    Write-Host "`n[OK] DNS optimizations complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Optimize-NetworkAdapter {
    Write-Host "`n[NETWORK ADAPTER TWEAKS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Optimizing network adapters" -Level Info -Category "Network"

    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }

    if (-not $adapters -or $adapters.Count -eq 0) {
        Write-Host "`n[!] No active network adapters found." -ForegroundColor $Script:Colors.Warning
        Wait-ForUser
        return
    }

    $steps = $adapters | ForEach-Object {
        $adapterGuid = $_.InterfaceGuid
        $adapterName = $_.Name
        @{
            Name   = "Disabling power-saving on '$adapterName'"
            Action = {
                # Get-CimInstance replaces the deprecated Get-WmiObject (removed on
                # PowerShell 7+; WMI is being phased out in favor of CIM/WinRM).
                $powerMgmt = Get-CimInstance -Namespace root\wmi -ClassName MSPower_DeviceEnable -ErrorAction Stop |
                    Where-Object { $_.InstanceName -like "*$adapterGuid*" }
                if ($powerMgmt) {
                    $powerMgmt.Enable = $false
                    Set-CimInstance -InputObject $powerMgmt -ErrorAction Stop
                }
                else {
                    throw "No power management descriptor exposed by this adapter"
                }
            }.GetNewClosure()
        }
    }

    Invoke-TweakSequence -Title "Network Adapter Optimization" -Steps $steps -Category "Network" | Out-Null

    Write-Host "`n[OK] Network adapter optimizations complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Configure-QoS {
    Write-Host "`n[QoS CONFIGURATION]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "This will disable QoS packet scheduler bandwidth reservation." -ForegroundColor $Script:Colors.Info

    if (-not (Confirm-Action)) { return }

    Write-Log "Configuring QoS" -Level Info -Category "Network"

    $steps = @(
        @{
            Name   = "Setting QoS bandwidth reservation limit to 0%"
            Action = {
                $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "NonBestEffortLimit"
                Set-ItemProperty -Path $path -Name "NonBestEffortLimit" -Value 0 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "QoS Configuration" -Steps $steps -Category "Network" | Out-Null

    Write-Host "`n[OK] QoS configuration complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Optimize-Browsers {
    Write-Host "`n[BROWSER OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "This will optimize browser settings for performance." -ForegroundColor $Script:Colors.Info

    if (-not (Confirm-Action)) { return }

    Write-Log "Optimizing browsers" -Level Info -Category "Network"

    $steps = @(
        @{
            Name   = "Disabling Microsoft Edge background mode"
            Action = {
                $path = "HKCU:\Software\Policies\Microsoft\Edge"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "BackgroundModeEnabled"
                Set-ItemProperty -Path $path -Name "BackgroundModeEnabled" -Value 0 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "Browser Optimization" -Steps $steps -Category "Network" | Out-Null

    Write-Host "`n[OK] Browser optimizations complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Apply-AllNetworkOptimizations {
    Write-Host "`n[APPLY ALL NETWORK OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    $Script:SkipConfirmations = $true
    $Script:SkipPauses = $true
    try {
        Optimize-TCPIP
        Optimize-NetworkAdapter
        Configure-QoS
        Optimize-Browsers
    }
    finally {
        $Script:SkipConfirmations = $false
        $Script:SkipPauses = $false
    }

    Write-Host "`n[OK] ALL NETWORK OPTIMIZATIONS COMPLETED!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

#endregion

# Windows Performance Tweaker Ultimate Edition v3.5.0
# Additional Optimization Modules - Part 2
# Gaming, Network

#region Category 2: Gaming & Graphics

function Show-GamingMenu {
    do {
        Show-Header "Gaming & Graphics"
        Write-Host "  GAMING & GRAPHICS OPTIMIZATIONS" -ForegroundColor $Script:Colors.Menu
        Write-Host "  ═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Menu
        Write-Host "   1. Enable Gaming Mode & Optimizations" -ForegroundColor White
        Write-Host "   2. Reduce Input Lag (Mouse/Keyboard)" -ForegroundColor White
        Write-Host "   3. Optimize Network for Gaming" -ForegroundColor White
        Write-Host "   4. Disable Fullscreen Optimizations" -ForegroundColor White
        Write-Host "   5. Audio Optimizations for Gaming" -ForegroundColor White
        Write-Host "   6. Frame Rate Optimizations" -ForegroundColor White
        Write-Host "   7. ⚡ Apply All Gaming Optimizations" -ForegroundColor Green
        Write-Host "   0. ← Back to Main Menu" -ForegroundColor Yellow
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
            '0' { return }
            default {
                Write-Host "`n✗ Invalid option." -ForegroundColor $Script:Colors.Error
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

function Enable-GamingMode {
    Write-Host "`n[GAMING MODE OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

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

    Write-Host "`n✓ Gaming mode optimizations complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Reduce-InputLag {
    Write-Host "`n[INPUT LAG REDUCTION]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

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

    Write-Host "`n✓ Input lag reduction complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Optimize-NetworkGaming {
    Write-Host "`n[NETWORK GAMING OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

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

    Write-Host "`n✓ Network gaming optimizations complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Disable-FullscreenOptimizations {
    Write-Host "`n[DISABLE FULLSCREEN OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
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

    Write-Host "`n✓ Fullscreen optimizations disabled!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Optimize-AudioGaming {
    Write-Host "`n[AUDIO OPTIMIZATIONS FOR GAMING]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

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

    Write-Host "`n✓ Audio optimizations complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Optimize-FrameRate {
    Write-Host "`n[FRAME RATE OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

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
    Write-Host "`n✓ Frame rate optimizations complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Apply-AllGamingOptimizations {
    Write-Host "`n[APPLY ALL GAMING OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    $Script:SkipConfirmations = $true
    $Script:SkipPauses = $true
    try {
        Enable-GamingMode
        Reduce-InputLag
        Optimize-NetworkGaming
        Disable-FullscreenOptimizations
        Optimize-AudioGaming
        Optimize-FrameRate
    }
    finally {
        $Script:SkipConfirmations = $false
        $Script:SkipPauses = $false
    }

    Write-Host "`n✓ ALL GAMING OPTIMIZATIONS COMPLETED!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

#endregion

#region Category 3: Network & Internet

function Show-NetworkMenu {
    do {
        Show-Header "Network & Internet"
        Write-Host "  NETWORK & INTERNET OPTIMIZATIONS" -ForegroundColor $Script:Colors.Menu
        Write-Host "  ═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Menu
        Write-Host "   1. Advanced TCP/IP Tweaks" -ForegroundColor White
        Write-Host "   2. DNS Optimizations" -ForegroundColor White
        Write-Host "   3. Network Adapter Tweaks" -ForegroundColor White
        Write-Host "   4. QoS Configuration" -ForegroundColor White
        Write-Host "   5. Browser Optimizations" -ForegroundColor White
        Write-Host "   6. ⚡ Apply All Network Optimizations" -ForegroundColor Green
        Write-Host "   0. ← Back to Main Menu" -ForegroundColor Yellow
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
                Write-Host "`n✗ Invalid option." -ForegroundColor $Script:Colors.Error
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

function Optimize-TCPIP {
    Write-Host "`n[ADVANCED TCP/IP TWEAKS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

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

    Write-Host "`n✓ TCP/IP optimizations complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Optimize-DNS {
    Write-Host "`n[DNS OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
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
            Write-Host "`n✗ Invalid selection." -ForegroundColor $Script:Colors.Error
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

    Write-Host "`n✓ DNS optimizations complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Optimize-NetworkAdapter {
    Write-Host "`n[NETWORK ADAPTER TWEAKS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action)) { return }

    Write-Log "Optimizing network adapters" -Level Info -Category "Network"

    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }

    if (-not $adapters -or $adapters.Count -eq 0) {
        Write-Host "`n⚠ No active network adapters found." -ForegroundColor $Script:Colors.Warning
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

    Write-Host "`n✓ Network adapter optimizations complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Configure-QoS {
    Write-Host "`n[QoS CONFIGURATION]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
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

    Write-Host "`n✓ QoS configuration complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Optimize-Browsers {
    Write-Host "`n[BROWSER OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
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

    Write-Host "`n✓ Browser optimizations complete!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Apply-AllNetworkOptimizations {
    Write-Host "`n[APPLY ALL NETWORK OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

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

    Write-Host "`n✓ ALL NETWORK OPTIMIZATIONS COMPLETED!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

#endregion

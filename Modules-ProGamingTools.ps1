# Wethereal Ultimate Edition - Pro Gaming Tools Module
# Overclock/undervolt guidance (informational), CPU/GPU bottleneck detector,
# per-game process tuning, best-effort GPU driver clean-reinstall, FPS overlay.

#region Category 10: Pro Gaming Tools

function Global:Show-ProGamingToolsMenu {
    do {
        Show-Header "Pro Gaming Tools"
        Write-Host "  PRO GAMING TOOLS" -ForegroundColor $Script:Colors.Menu
        Write-Host "  =======================================================================" -ForegroundColor $Script:Colors.Menu
        Write-Host "   1. [HOT] Overclock / Undervolt Guide (informational)" -ForegroundColor White
        Write-Host "   2. [NAV] CPU/GPU Bottleneck Detector" -ForegroundColor White
        Write-Host "   3. [TARGET] Per-Game Process Tuning" -ForegroundColor White
        Write-Host "   4. [CLEAN] Clean GPU Driver Reinstall (DDU-style, best-effort)" -ForegroundColor White
        Write-Host "   5. [DEV] FPS Overlay (RTSS / MSI Afterburner)" -ForegroundColor White
        Write-Host "   6. [BOOST] Enable MSI Mode for GPU/NVMe interrupts (advanced)" -ForegroundColor White
        Write-Host "   7. [!] Disable Core Isolation / Memory Integrity (VBS, advanced)" -ForegroundColor White
        Write-Host "   8. [TARGET] Bulk Per-Game Tuning - Tune ALL Detected Games" -ForegroundColor White
        Write-Host "   0. <- Back to Main Menu" -ForegroundColor Yellow
        Write-Host ""

        $choice = Read-Host "Select an option"

        switch ($choice) {
            '1' { Show-OverclockGuide }
            '2' { Test-Bottleneck }
            '3' { Show-GameProfiles }
            '4' { Invoke-CleanGpuDriverReinstall }
            '5' { Enable-FpsOverlay }
            '6' { Enable-MSIModeInterrupts }
            '7' { Disable-CoreIsolation }
            '8' { Register-AllInstalledGames }
            '0' { return }
            default {
                Write-Host "`n[X] Invalid option." -ForegroundColor $Script:Colors.Error
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

#endregion

#region Overclock / Undervolt Guide (informational only)

function Global:Show-OverclockGuide {
    Write-Host "`n[OVERCLOCK / UNDERVOLT GUIDE]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "[!]  Wethereal does NOT touch voltages, clocks or power limits directly -" -ForegroundColor $Script:Colors.Warning
    Write-Host "   that's genuinely risky to automate blind (instability, crashes, in rare" -ForegroundColor $Script:Colors.Warning
    Write-Host "   cases hardware damage). Instead, here's exactly which official tool to" -ForegroundColor $Script:Colors.Warning
    Write-Host "   use for YOUR hardware, and a safe starting point." -ForegroundColor $Script:Colors.Warning
    Write-Host ""

    $hw = Get-HardwareProfile

    Write-Host "  CPU: $($hw.CPU.Name) [$($hw.CPU.Vendor)]" -ForegroundColor $Script:Colors.Highlight
    switch ($hw.CPU.Vendor) {
        "AMD" {
            Write-Host "    -> Tool: AMD Ryzen Master (official, free)" -ForegroundColor White
            Write-Host "    -> Safe starting point: enable 'Precision Boost Overdrive' (PBO) with" -ForegroundColor DarkGray
            Write-Host "      motherboard limits, then apply a small negative 'Curve Optimizer'" -ForegroundColor DarkGray
            Write-Host "      offset (e.g. -10 all-core) and stress-test before going further." -ForegroundColor DarkGray
            $cpuUrl = "https://www.amd.com/en/technologies/ryzen-master"
        }
        "Intel" {
            Write-Host "    -> Tool: Intel Extreme Tuning Utility (XTU, official, free)" -ForegroundColor White
            Write-Host "    -> Safe starting point: use the built-in 'Adaptive Undervoltage'" -ForegroundColor DarkGray
            Write-Host "      suggestion or a small -50mV core offset, then run the bundled" -ForegroundColor DarkGray
            Write-Host "      stress test before increasing it further." -ForegroundColor DarkGray
            $cpuUrl = "https://www.intel.com/content/www/us/en/download/17881/intel-extreme-tuning-utility-intel-xtu.html"
        }
        default {
            Write-Host "    -> CPU vendor not detected - skipping CPU-specific tool suggestion." -ForegroundColor DarkGray
            $cpuUrl = $null
        }
    }

    Write-Host ""
    if ($hw.GPUs.Count -eq 0) {
        Write-Host "  GPU: not detected." -ForegroundColor $Script:Colors.Warning
        $gpuUrl = $null
    }
    else {
        foreach ($gpu in $hw.GPUs) {
            Write-Host "  GPU: $($gpu.Name) [$($gpu.Vendor)]" -ForegroundColor $Script:Colors.Highlight
        }
        Write-Host "    -> Tool: MSI Afterburner (official, free, works on NVIDIA/AMD/Intel)" -ForegroundColor White
        Write-Host "    -> Safe starting point: use the Afterburner OC Scanner (NVIDIA) or a" -ForegroundColor DarkGray
        Write-Host "      small +50MHz core / +200MHz memory step (AMD/Intel), test stability" -ForegroundColor DarkGray
        Write-Host "      in a benchmark before layering on more. For undervolting, lower the" -ForegroundColor DarkGray
        Write-Host "      voltage at your current max boost clock in the curve editor." -ForegroundColor DarkGray
        $gpuUrl = "https://www.msi.com/Landing/afterburner/graphics-cards"
    }

    Write-Host ""
    Write-Host "  [!]  Always run a stability/stress test after any change, and revert" -ForegroundColor $Script:Colors.Warning
    Write-Host "     immediately if you see crashes, artifacts or blue screens." -ForegroundColor $Script:Colors.Warning
    Write-Host ""

    if (Confirm-Action -Message "Open the official download page(s) for these tools in your browser?") {
        if ($cpuUrl) { Start-Process $cpuUrl }
        if ($gpuUrl) { Start-Process $gpuUrl }
        Write-Log "Opened overclock/undervolt tool download pages for $($hw.CPU.Vendor) CPU / $($hw.GPUVendors -join ',') GPU" -Level Info -Category "Gaming"
    }

    Wait-ForUser
}

#endregion

#region CPU/GPU Bottleneck Detector

function Global:Test-Bottleneck {
    Write-Host "`n[CPU/GPU BOTTLENECK DETECTOR]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Runs a ~8 second synthetic CPU load while sampling CPU and GPU usage to" -ForegroundColor $Script:Colors.Info
    Write-Host "estimate which one is more likely limiting your gaming performance." -ForegroundColor $Script:Colors.Info
    Write-Host "(A rough signal, not a substitute for in-game monitoring under real load.)" -ForegroundColor DarkGray

    if (-not (Confirm-Action -Message "Run the bottleneck test now?" -DefaultYes)) { return }

    Write-Log "Running CPU/GPU bottleneck detector" -Level Info -Category "Gaming"

    # Saturate all logical CPUs in the background for the duration of the sample window.
    $hw = Get-HardwareProfile
    $threadCount = [Math]::Max(1, $hw.CPU.Threads)
    $loadJobs = 1..$threadCount | ForEach-Object {
        Start-Job -ScriptBlock {
            $deadline = (Get-Date).AddSeconds(9)
            while ((Get-Date) -lt $deadline) { $x = 0; for ($i = 0; $i -lt 2000000; $i++) { $x += $i * $i } }
        }
    }

    $cpuSamples = @()
    $gpuSamples = @()

    for ($i = 1; $i -le 8; $i++) {
        Write-Progress -Activity "[NAV] Bottleneck Detector" -Status "Sampling [$i/8]..." -PercentComplete ([math]::Round(($i / 8) * 100))
        Start-Sleep -Seconds 1
        try {
            $cpu = (Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop).CounterSamples[0].CookedValue
            $cpuSamples += $cpu
        }
        catch {}
        try {
            $gpuCounters = Get-Counter '\GPU Engine(*)\Utilization Percentage' -ErrorAction Stop
            # Windows exposes one counter instance per (process, engine) pair - sum and
            # cap at 100 to approximate overall GPU utilization from that snapshot.
            $gpuTotal = ($gpuCounters.CounterSamples | Measure-Object -Property CookedValue -Sum).Sum
            $gpuSamples += [Math]::Min(100, $gpuTotal)
        }
        catch {}
    }
    Write-Progress -Activity "[NAV] Bottleneck Detector" -Completed

    $loadJobs | Wait-Job -Timeout 12 | Out-Null
    $loadJobs | Remove-Job -Force -ErrorAction SilentlyContinue

    if ($cpuSamples.Count -eq 0) {
        Write-Host "`n[X] Could not read CPU performance counters on this system." -ForegroundColor $Script:Colors.Error
        Wait-ForUser
        return
    }

    $avgCpu = ($cpuSamples | Measure-Object -Average).Average
    $avgGpu = if ($gpuSamples.Count -gt 0) { ($gpuSamples | Measure-Object -Average).Average } else { $null }

    Write-Host "`n  Average CPU usage: $([math]::Round($avgCpu, 1))%" -ForegroundColor White
    if ($null -ne $avgGpu) {
        Write-Host "  Average GPU usage: $([math]::Round($avgGpu, 1))%" -ForegroundColor White
    }
    else {
        Write-Host "  GPU usage: unavailable (no 'GPU Engine' performance counters on this system/driver)" -ForegroundColor $Script:Colors.Warning
    }

    Write-Host "`n  Verdict:" -ForegroundColor $Script:Colors.Highlight
    if ($null -eq $avgGpu) {
        Write-Host "    [i] CPU is at $([math]::Round($avgCpu, 1))% under synthetic load. Re-run this while" -ForegroundColor Cyan
        Write-Host "      actually gaming (alt-tab quickly) for a more meaningful reading." -ForegroundColor Cyan
    }
    elseif ($avgCpu -gt 85 -and $avgGpu -lt 60) {
        Write-Host "    -> Likely CPU-bound: your CPU is maxed out while the GPU has headroom." -ForegroundColor Yellow
        Write-Host "      Consider: Category 1 CPU tweaks, closing background apps, or a CPU upgrade." -ForegroundColor White
    }
    elseif ($avgGpu -gt 85 -and $avgCpu -lt 60) {
        Write-Host "    -> Likely GPU-bound: your GPU is maxed out while the CPU has headroom." -ForegroundColor Yellow
        Write-Host "      Consider: lowering in-game resolution/settings, or a GPU upgrade." -ForegroundColor White
    }
    else {
        Write-Host "    -> No single clear bottleneck under this synthetic test - CPU and GPU" -ForegroundColor Green
        Write-Host "      loads were relatively balanced. Test again during actual gameplay." -ForegroundColor Green
    }

    Write-Log "Bottleneck detector: avg CPU=$([math]::Round($avgCpu,1))% avg GPU=$(if($avgGpu){[math]::Round($avgGpu,1)}else{'n/a'})%" -Level Info -Category "Gaming"
    Wait-ForUser
}

#endregion

#region Per-Game Process Tuning

$Script:CuratedGames = @(
    @{ Name = "Valorant"; Hint = "VALORANT-Win64-Shipping.exe" }
    @{ Name = "Counter-Strike 2"; Hint = "cs2.exe" }
    @{ Name = "Fortnite"; Hint = "FortniteClient-Win64-Shipping.exe" }
    @{ Name = "Apex Legends"; Hint = "r5apex.exe" }
    @{ Name = "League of Legends"; Hint = "League of Legends.exe" }
    @{ Name = "Call of Duty: Warzone"; Hint = "cod.exe" }
    @{ Name = "Other / custom .exe"; Hint = $null }
)

function Global:Show-GameProfiles {
    Write-Host "`n[PER-GAME PROCESS TUNING]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Applies Windows' own per-executable performance hooks to a specific game:" -ForegroundColor $Script:Colors.Info
    Write-Host "Above Normal CPU priority + 'High performance' GPU preference - scoped to" -ForegroundColor $Script:Colors.Info
    Write-Host "that one .exe only, so it never affects anything else on your system." -ForegroundColor $Script:Colors.Info
    Write-Host ""

    for ($i = 0; $i -lt $Script:CuratedGames.Count; $i++) {
        Write-Host ("  {0}. {1}" -f ($i + 1), $Script:CuratedGames[$i].Name) -ForegroundColor White
    }
    Write-Host "  0. Cancel" -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "Select a game"
    $idx = 0
    if ($choice -eq '0' -or [string]::IsNullOrWhiteSpace($choice)) { return }
    if (-not [int]::TryParse($choice, [ref]$idx) -or $idx -lt 1 -or $idx -gt $Script:CuratedGames.Count) {
        Write-Host "`n[X] Invalid selection." -ForegroundColor $Script:Colors.Error
        Start-Sleep -Seconds 1
        return
    }

    $game = $Script:CuratedGames[$idx - 1]
    $exePath = Read-Host "Full path to '$($game.Name)' executable$(if ($game.Hint) { " (usually named $($game.Hint))" })"

    if ([string]::IsNullOrWhiteSpace($exePath) -or -not (Test-Path $exePath)) {
        Write-Host "`n[X] That path doesn't exist. Find the game's .exe (right-click its shortcut ->" -ForegroundColor $Script:Colors.Error
        Write-Host "  Open file location) and try again." -ForegroundColor $Script:Colors.Error
        Wait-ForUser
        return
    }

    Write-Log "Applying per-game tuning to $exePath" -Level Info -Category "Gaming"

    $steps = @(
        @{
            Name   = "Setting Above Normal CPU priority for $(Split-Path $exePath -Leaf)"
            Action = {
                $exeName = Split-Path $exePath -Leaf
                $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$exeName\PerfOptions"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "CpuPriorityClass"
                # 3 = Above Normal. Deliberately NOT "High" (4) - that can starve the OS
                # and other apps on lower core-count systems.
                Set-ItemProperty -Path $path -Name "CpuPriorityClass" -Value 3 -Type DWord
            }.GetNewClosure()
        }
        @{
            Name   = "Setting 'High performance' GPU preference for $(Split-Path $exePath -Leaf)"
            Action = {
                $path = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name $exePath
                Set-ItemProperty -Path $path -Name $exePath -Value "GpuPreference=2;" -Type String
            }.GetNewClosure()
        }
    )

    Invoke-TweakSequence -Title "Per-Game Tuning: $($game.Name)" -Steps $steps -Category "Gaming" | Out-Null

    Write-Host "`n[OK] Tuning applied to $($game.Name)! Takes effect next time you launch it." -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

function Global:Register-AllInstalledGames {
    <#
        Bulk version of the per-game tuning above: instead of pasting one .exe
        path at a time, this walks every detected game library (Get-
        DetectedGameFolders - Steam/Epic/Battle.net/Riot/GOG/Ubisoft) and, for
        each installed game's own subfolder, tunes the single largest .exe in it
        (the reliable heuristic for "that's the real game binary, not a launcher
        or redistributable installer"). Same two tweaks as the single-game flow:
        Above Normal CPU priority + High-performance GPU preference, scoped to
        each .exe individually.
    #>
    Write-Host "`n[BULK PER-GAME TUNING - ALL DETECTED GAMES]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Scans every detected game library and applies Above Normal CPU priority +" -ForegroundColor $Script:Colors.Info
    Write-Host "High-performance GPU preference to each installed game's main .exe in one" -ForegroundColor $Script:Colors.Info
    Write-Host "pass, instead of doing it one game at a time." -ForegroundColor $Script:Colors.Info

    if (-not (Confirm-Action)) { return }

    Write-Log "Bulk-registering all detected games for Game Mode / priority tuning" -Level Info -Category "Gaming"

    $libraryRoots = Get-DetectedGameFolders
    if (-not $libraryRoots -or $libraryRoots.Count -eq 0) {
        Write-Host "`n[!] No known game library folders were found on this system." -ForegroundColor $Script:Colors.Warning
        Wait-ForUser
        return
    }

    # Utility/installer binaries that are never the actual game - skip them even
    # if they happen to be the largest .exe found in a folder.
    $excludePattern = 'unins|setup|redist|vcredist|dotnet|dxsetup|directx|crashreporter|crashpad|battleye|easyanticheat|vc_redist'

    $gameExes = [System.Collections.Generic.List[string]]::new()
    foreach ($root in $libraryRoots) {
        $gameDirs = Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue
        foreach ($gameDir in $gameDirs) {
            $candidateExe = Get-ChildItem -Path $gameDir.FullName -Filter "*.exe" -Recurse -Depth 3 -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -notmatch $excludePattern } |
                Sort-Object Length -Descending |
                Select-Object -First 1
            if ($candidateExe) { $gameExes.Add($candidateExe.FullName) }
        }
    }

    if ($gameExes.Count -eq 0) {
        Write-Host "`n[!] No game executables could be identified in the detected libraries." -ForegroundColor $Script:Colors.Warning
        Wait-ForUser
        return
    }

    $steps = $gameExes | ForEach-Object {
        $exePath = $_
        @{
            Name   = "Tuning: $(Split-Path $exePath -Leaf)"
            Action = {
                $exeName = Split-Path $exePath -Leaf
                $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$exeName\PerfOptions"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "CpuPriorityClass"
                Set-ItemProperty -Path $path -Name "CpuPriorityClass" -Value 3 -Type DWord

                $gpuPath = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
                if (-not (Test-Path $gpuPath)) { New-Item -Path $gpuPath -Force | Out-Null }
                Backup-RegistryValue -Path $gpuPath -Name $exePath
                Set-ItemProperty -Path $gpuPath -Name $exePath -Value "GpuPreference=2;" -Type String
            }.GetNewClosure()
        }
    }

    Invoke-TweakSequence -Title "Bulk Per-Game Tuning" -Steps $steps -Category "Gaming" | Out-Null

    Write-Host "`n[OK] Tuned $($gameExes.Count) detected game(s)!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

#endregion

#region Clean GPU Driver Reinstall (DDU-style, best-effort)

function Global:Invoke-CleanGpuDriverReinstall {
    Write-Host "`n[CLEAN GPU DRIVER REINSTALL]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "[!]  This is a BEST-EFFORT clean-up, not a full DDU replacement." -ForegroundColor $Script:Colors.Warning
    Write-Host "   Real Display Driver Uninstaller does its work from Safe Mode, which this" -ForegroundColor $Script:Colors.Warning
    Write-Host "   tool cannot force. If you're chasing a stubborn driver problem, use the" -ForegroundColor $Script:Colors.Warning
    Write-Host "   real DDU from Safe Mode instead - this option is for a routine clean swap." -ForegroundColor $Script:Colors.Warning
    Write-Host "   Your screen WILL go black/flicker while the driver is removed." -ForegroundColor $Script:Colors.Warning

    $hw = Get-HardwareProfile
    if ($hw.GPUs.Count -eq 0) {
        Write-Host "`n[X] No GPU detected - nothing to clean." -ForegroundColor $Script:Colors.Error
        Wait-ForUser
        return
    }

    Write-Host "`nDetected GPU(s): $(($hw.GPUs | ForEach-Object { "$($_.Name) [$($_.Vendor)]" }) -join ', ')" -ForegroundColor $Script:Colors.Info

    if (-not (Confirm-Action -Message "Proceed with best-effort GPU driver removal?")) { return }

    Write-Log "Starting best-effort GPU driver clean removal" -Level Info -Category "Gaming"

    $vendorPatterns = @{
        NVIDIA = 'nvidia|geforce'
        AMD    = 'amd|ati|radeon'
        Intel  = 'intel.*graphics|intel.*display'
    }
    $activePatterns = $hw.GPUVendors | ForEach-Object { $vendorPatterns[$_] } | Where-Object { $_ }

    $steps = @(
        @{
            Name   = "Enumerating third-party driver packages"
            Action = {
                $Script:_matchedDrivers = @()
                $drivers = pnputil /enum-drivers 2>&1
                $currentPub = $null
                foreach ($line in $drivers) {
                    if ($line -match '^Published Name\s*:\s*(oem\d+\.inf)') { $Script:_currentOem = $matches[1] }
                    if ($line -match '^Original Name\s*:\s*(.+)$') { $currentPub = $matches[1] }
                    if ($line -match '^Provider Name\s*:\s*(.+)$') {
                        $provider = $matches[1]
                        foreach ($pattern in $activePatterns) {
                            if ($provider -match $pattern -or $currentPub -match $pattern) {
                                $Script:_matchedDrivers += $Script:_currentOem
                                break
                            }
                        }
                    }
                }
                $Script:_matchedDrivers = $Script:_matchedDrivers | Select-Object -Unique
            }.GetNewClosure()
        }
        @{
            Name   = "Removing matched GPU driver packages"
            Action = {
                foreach ($oem in $Script:_matchedDrivers) {
                    pnputil /delete-driver $oem /uninstall /force 2>&1 | Out-Null
                }
                if (-not $Script:_matchedDrivers -or $Script:_matchedDrivers.Count -eq 0) {
                    throw "No matching third-party driver packages found via pnputil"
                }
            }.GetNewClosure()
        }
        @{
            Name   = "Cleaning leftover driver cache folders"
            Action = {
                $leftoverPaths = @(
                    "$env:ProgramData\NVIDIA Corporation\NV_Cache",
                    "$env:LOCALAPPDATA\NVIDIA\DXCache",
                    "$env:ProgramData\ATI\ACE",
                    "$env:LOCALAPPDATA\AMD\DxCache",
                    "$env:ProgramData\Intel\GfxLayer"
                )
                foreach ($p in $leftoverPaths) {
                    if (Test-Path $p) { Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue }
                }
            }
        }
    )

    Invoke-TweakSequence -Title "Clean GPU Driver Reinstall" -Steps $steps -Category "Gaming" | Out-Null

    Write-Host "`n[OK] Best-effort cleanup done." -ForegroundColor $Script:Colors.Success
    Write-Host "  Next: restart your PC, then install a fresh driver from the vendor site." -ForegroundColor $Script:Colors.Warning

    if (Confirm-Action -Message "Open the official driver download page now?" -DefaultYes) {
        $downloadUrl = switch ($hw.GPUVendors[0]) {
            "NVIDIA" { "https://www.nvidia.com/Download/index.aspx" }
            "AMD" { "https://www.amd.com/en/support" }
            "Intel" { "https://www.intel.com/content/www/us/en/download-center/home.html" }
            default { $null }
        }
        if ($downloadUrl) { Start-Process $downloadUrl }
    }

    Wait-ForUser
}

#endregion

#region FPS Overlay (RTSS)

function Global:Enable-FpsOverlay {
    Write-Host "`n[FPS OVERLAY]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Wethereal can't draw its own in-game overlay (that needs a DirectX/OpenGL" -ForegroundColor $Script:Colors.Info
    Write-Host "hook, well beyond PowerShell) - but it can set up RivaTuner Statistics" -ForegroundColor $Script:Colors.Info
    Write-Host "Server (RTSS), the same overlay engine MSI Afterburner and most FPS" -ForegroundColor $Script:Colors.Info
    Write-Host "counters use." -ForegroundColor $Script:Colors.Info
    Write-Host ""

    $rtssPaths = @(
        "${env:ProgramFiles(x86)}\RivaTuner Statistics Server\RTSS.exe",
        "$env:ProgramFiles\RivaTuner Statistics Server\RTSS.exe"
    )
    $rtssPath = $rtssPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($rtssPath) {
        Write-Host "[OK] RTSS is already installed." -ForegroundColor $Script:Colors.Success
        if (Confirm-Action -Message "Launch RTSS now?" -DefaultYes) {
            Start-Process $rtssPath
            Write-Host "  RTSS is running. Configure the on-screen overlay hotkey/position from" -ForegroundColor $Script:Colors.Info
            Write-Host "  its own window - it keeps running in the background after that." -ForegroundColor $Script:Colors.Info
            Write-Log "Launched RTSS for FPS overlay" -Level Success -Category "Gaming"
        }
    }
    else {
        Write-Host "RTSS was not found on this system." -ForegroundColor $Script:Colors.Warning
        if (-not (Test-WingetAvailable)) { Wait-ForUser; return }

        if (Confirm-Action -Message "Install MSI Afterburner now via winget? (bundles RTSS)" -DefaultYes) {
            $steps = @(
                @{
                    Name   = "Installing MSI Afterburner (includes RTSS)"
                    Action = {
                        winget install --id Guru3D.Afterburner -e --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
                        if ($LASTEXITCODE -ne 0) { throw "winget exited with code $LASTEXITCODE" }
                    }
                }
            )
            Invoke-TweakSequence -Title "FPS Overlay Setup" -Steps $steps -Category "Gaming" | Out-Null
            Write-Host "`n[OK] Installed. Launch 'RivaTuner Statistics Server' from the Start Menu to" -ForegroundColor $Script:Colors.Success
            Write-Host "  enable the on-screen FPS overlay (its own Setup tab has the hotkey)." -ForegroundColor $Script:Colors.Success
        }
    }

    Wait-ForUser
}

#endregion

#region MSI Mode for GPU/NVMe interrupts

function Global:Enable-MSIModeInterrupts {
    <#
        Switches supported devices (GPU, NVMe/storage controllers) from legacy
        line-based interrupts to Message Signaled Interrupts (MSI). MSI lets the
        device talk to any CPU core directly instead of funneling every interrupt
        through IRQ 16 shared with other hardware, which can meaningfully cut
        input lag / micro-stutter on systems where the GPU or NVMe drive is
        sharing an IRQ. Not every device exposes the "MSI Supported" registry
        value - those are silently skipped rather than treated as failures.
    #>
    Write-Host "`n[MSI MODE FOR GPU/NVMe INTERRUPTS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Switches your GPU and NVMe/storage controllers from legacy line-based" -ForegroundColor $Script:Colors.Info
    Write-Host "interrupts to Message Signaled Interrupts (MSI), which can reduce input" -ForegroundColor $Script:Colors.Info
    Write-Host "lag and micro-stutter caused by shared IRQs. Safe and fully reversible," -ForegroundColor $Script:Colors.Info
    Write-Host "but a restart is required for it to take effect." -ForegroundColor $Script:Colors.Info

    if (-not (Confirm-Action)) { return }

    Write-Log "Enabling MSI mode for GPU/NVMe interrupts" -Level Info -Category "Gaming"

    # Display adapters (GUID 4d36e968) + storage controllers (SCSIAdapter class,
    # covers NVMe/AHCI controllers) - the two device classes that most commonly
    # benefit from MSI mode for gaming/latency.
    $targets = @()
    $targets += Get-PnpDevice -Class Display -Status OK -ErrorAction SilentlyContinue
    $targets += Get-PnpDevice -Class SCSIAdapter -Status OK -ErrorAction SilentlyContinue

    if (-not $targets -or $targets.Count -eq 0) {
        Write-Host "`n[!] No eligible GPU/storage controller devices found." -ForegroundColor $Script:Colors.Warning
        Wait-ForUser
        return
    }

    $steps = $targets | ForEach-Object {
        $device = $_
        @{
            Name      = "Enabling MSI mode: $($device.FriendlyName)"
            Condition = {
                $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($device.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledBasedInterruptProperties"
                Test-Path (Split-Path $regPath -Parent) -ErrorAction SilentlyContinue
            }.GetNewClosure()
            Action    = {
                $imPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($device.InstanceId)\Device Parameters\Interrupt Management"
                $regPath = "$imPath\MessageSignaledBasedInterruptProperties"
                if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
                Backup-RegistryValue -Path $regPath -Name "MSISupported"
                Set-ItemProperty -Path $regPath -Name "MSISupported" -Value 1 -Type DWord
            }.GetNewClosure()
        }
    }

    Invoke-TweakSequence -Title "MSI Mode Interrupts" -Steps $steps -Category "Gaming" | Out-Null

    Write-Host "`n[OK] MSI mode applied where supported!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Restart your PC for the interrupt mode change to take effect." -ForegroundColor $Script:Colors.Warning
    Wait-ForUser
}

#endregion

#region Core Isolation / Memory Integrity (VBS) toggle

function Global:Disable-CoreIsolation {
    <#
        Virtualization-Based Security (Core Isolation / Memory Integrity) runs part
        of the OS in a hardware-isolated hypervisor sandbox. It's a real security
        feature, but on CPUs without efficient virtualization extensions it also
        adds measurable overhead to every syscall - a well-documented FPS cost in
        CPU-bound games. This tweak is opt-in and explicit about the trade-off; it
        is only ever applied automatically inside the Gaming / LowEndGaming
        profiles, which the user has already opted into for maximum performance.
    #>
    Write-Host "`n[DISABLE CORE ISOLATION / MEMORY INTEGRITY]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "[!]  SECURITY TRADE-OFF: Core Isolation / Memory Integrity (VBS) blocks" -ForegroundColor $Script:Colors.Warning
    Write-Host "  entire classes of kernel-level malware and driver exploits. Disabling it" -ForegroundColor $Script:Colors.Warning
    Write-Host "  removes that protection in exchange for lower CPU overhead and higher" -ForegroundColor $Script:Colors.Warning
    Write-Host "  FPS in CPU-bound games. Only disable this if you understand and accept" -ForegroundColor $Script:Colors.Warning
    Write-Host "  the risk. Fully reversible from Windows Security > Device Security." -ForegroundColor $Script:Colors.Warning

    if (-not (Confirm-Action -Message "I understand the security trade-off - disable it?")) { return }

    Write-Log "Disabling Core Isolation / Memory Integrity (VBS)" -Level Warning -Category "Gaming"

    $steps = @(
        @{
            Name   = "Disabling Virtualization-Based Security"
            Action = {
                $path = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "EnableVirtualizationBasedSecurity"
                Set-ItemProperty -Path $path -Name "EnableVirtualizationBasedSecurity" -Value 0 -Type DWord
            }
        }
        @{
            Name   = "Disabling Memory Integrity (HVCI)"
            Action = {
                $path = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "Enabled"
                Set-ItemProperty -Path $path -Name "Enabled" -Value 0 -Type DWord
            }
        }
        @{
            Name   = "Clearing Credential Guard configuration flags"
            Action = {
                $path = "HKLM:\SYSTEM\CurrentControlSet\Control\LSA"
                Backup-RegistryValue -Path $path -Name "LsaCfgFlags"
                Set-ItemProperty -Path $path -Name "LsaCfgFlags" -Value 0 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "Core Isolation Toggle" -Steps $steps -Category "Gaming" | Out-Null

    Write-Host "`n[OK] Core Isolation / Memory Integrity disabled!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Restart your PC for this to take effect." -ForegroundColor $Script:Colors.Warning
    Wait-ForUser
}

#endregion

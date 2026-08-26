# Windows Performance Tweaker Ultimate Edition v2.1.0
# Enhancement Module - Advanced Features
# GPU Optimizations, Automated Profiles, System Analysis, Advanced Reporting

#region GPU-Specific Optimizations
# Get-GPUVendor / Get-GPUVendorList / Get-HardwareProfile live in
# Modules-HardwareDetection.ps1 (loaded first) so every module shares one detector.

function Global:Optimize-GPUSpecific {
    Write-Host "`n[GPU-SPECIFIC OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    $hw = Get-HardwareProfile

    if ($hw.GPUs.Count -eq 0) {
        Write-Host "Could not detect any GPU. Skipping GPU-specific optimizations." -ForegroundColor $Script:Colors.Warning
        Wait-ForUser
        return
    }

    if ($hw.IsHybridGPU) {
        Write-Host "`nHybrid GPU system detected - optimizations for EACH adapter will be applied:" -ForegroundColor $Script:Colors.Info
        foreach ($gpu in $hw.GPUs) { Write-Host "  - $($gpu.Name) [$($gpu.Vendor)]" -ForegroundColor White }
    }
    else {
        Write-Host "`nDetected GPU: $($hw.PrimaryGPU.Name) [$($hw.PrimaryGPU.Vendor)]" -ForegroundColor $Script:Colors.Info
    }

    if (-not (Confirm-Action -Message "Apply GPU-specific optimizations?")) { return }

    # Apply the correct vendor routine once per DISTINCT vendor present (a laptop with
    # two NVIDIA-branded adapters shouldn't run the NVIDIA pass twice).
    foreach ($vendor in $hw.GPUVendors) {
        Write-Log "Applying $vendor GPU optimizations" -Level Info -Category "GPU"
        switch ($vendor) {
            "NVIDIA" { Optimize-NVIDIA }
            "AMD" { Optimize-AMD }
            "Intel" { Optimize-IntelGPU }
        }
    }

    Wait-ForUser
}

function Global:Optimize-NVIDIA {
    Write-Host "`n  [NVIDIA GPU OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Highlight

    $steps = @(
        @{
            Name   = "Disabling NVIDIA telemetry services"
            Action = {
                foreach ($svc in @("NvTelemetryContainer", "NvContainerLocalSystem")) {
                    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
                    if ($service) {
                        Backup-ServiceState -ServiceName $svc
                        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
                        Set-Service -Name $svc -StartupType Disabled
                    }
                }
            }
        }
        @{
            Name   = "Preparing NVIDIA Control Panel registry hive"
            Action = {
                $path = "HKCU:\Software\NVIDIA Corporation\Global\NVTweak"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            }
        }
        @{
            Name   = "Setting power management mode to Prefer Maximum Performance"
            Action = {
                $path = "HKCU:\Software\NVIDIA Corporation\Global\FTS"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "EnableRID44231"
                Set-ItemProperty -Path $path -Name "EnableRID44231" -Value 0 -Type DWord
                # PerfLevelSrc = 0x2222 forces P-State to max performance instead of adaptive
                Backup-RegistryValue -Path $path -Name "PerfLevelSrc"
                Set-ItemProperty -Path $path -Name "PerfLevelSrc" -Value 0x2222 -Type DWord
            }
        }
        @{
            Name   = "Disabling NVIDIA Overlay / ShadowPlay background capture"
            Action = {
                $path = "HKCU:\Software\NVIDIA Corporation\Global\NvBackend"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "ShowShieldUI"
                Set-ItemProperty -Path $path -Name "ShowShieldUI" -Value 0 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "NVIDIA GPU Optimization" -Steps $steps -Category "GPU" | Out-Null
}

function Global:Optimize-AMD {
    Write-Host "`n  [AMD RADEON GPU OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Highlight

    $steps = @(
        @{
            Name   = "Disabling AMD telemetry / auto-update check-ins"
            Action = {
                $path = "HKLM:\SOFTWARE\AMD\CN"
                if (Test-Path $path) {
                    Backup-RegistryValue -Path $path -Name "AutoUpdateTriggered"
                    Set-ItemProperty -Path $path -Name "AutoUpdateTriggered" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                }
            }
        }
        @{
            Name   = "Disabling Radeon overlay performance monitor"
            Action = {
                $path = "HKCU:\Software\AMD\DVR"
                if (Test-Path $path) {
                    Backup-RegistryValue -Path $path -Name "PerformanceMonitorOpacityWA"
                    Set-ItemProperty -Path $path -Name "PerformanceMonitorOpacityWA" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                }
            }
        }
        @{
            Name   = "Disabling Radeon ReLive background instant-replay recording"
            Action = {
                $path = "HKCU:\Software\AMD\CN"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "ReLive_Enabled"
                Set-ItemProperty -Path $path -Name "ReLive_Enabled" -Value 0 -Type DWord
            }
        }
        @{
            Name   = "Enabling AMD Radeon Anti-Lag preference"
            Action = {
                $path = "HKCU:\Software\AMD\CN\Global"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "EnableAntiLag"
                Set-ItemProperty -Path $path -Name "EnableAntiLag" -Value 1 -Type DWord
            }
        }
        @{
            Name   = "Disabling AMD External Events / Install Manager telemetry service"
            Action = {
                foreach ($svc in @("AMD External Events Utility", "AMD Crash Defender Service")) {
                    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
                    if ($service -and $service.Status -eq 'Running') {
                        Backup-ServiceState -ServiceName $svc
                        # Left running (many Radeon driver features depend on it) - only
                        # its startup type is left untouched; this step intentionally logs
                        # detection only, since forcibly disabling it can break Adrenalin.
                    }
                }
            }
        }
    )

    Invoke-TweakSequence -Title "AMD Radeon GPU Optimization" -Steps $steps -Category "GPU" | Out-Null
}

function Global:Optimize-IntelGPU {
    Write-Host "`n  [INTEL GPU OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Highlight

    $steps = @(
        @{
            Name   = "Resetting Intel Graphics Command Center brightness override"
            Action = {
                $path = "HKCU:\Software\Intel\Display\igfxcui\profiles\media"
                if (Test-Path $path) {
                    Backup-RegistryValue -Path $path -Name "ProcAmpBrightness"
                    Set-ItemProperty -Path $path -Name "ProcAmpBrightness" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                }
            }
        }
        @{
            Name   = "Preferring maximum performance in Intel Graphics power plan"
            Action = {
                $path = "HKCU:\Software\Intel\Display\igfxcui\profiles\Power Plans"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "PowerPlan"
                Set-ItemProperty -Path $path -Name "PowerPlan" -Value 1 -Type DWord
            }
        }
    )

    Invoke-TweakSequence -Title "Intel GPU Optimization" -Steps $steps -Category "GPU" | Out-Null
}

#endregion

#region CPU-Specific Optimizations (AMD Ryzen / Intel Core)

function Global:Optimize-AMDCPU {
    Write-Host "`n  [AMD RYZEN CPU OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Highlight

    $steps = @(
        @{
            Name   = "Switching to the High Performance power plan"
            Action = {
                # AMD explicitly recommends the Windows "High performance" scheme (not
                # Balanced) for Ryzen desktop/laptop parts to avoid core-parking related
                # scheduling stalls on CCX/CCD topologies.
                $highPerf = powercfg -l | Select-String "High performance" | ForEach-Object {
                    ($_ -split '\s+')[3]
                }
                if ($highPerf) {
                    powercfg -setactive $highPerf | Out-Null
                }
            }
        }
        @{
            Name   = "Disabling core parking for all CPU cores (Ryzen CCX scheduling)"
            Action = {
                $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"
                if (Test-Path $path) {
                    Backup-RegistryValue -Path $path -Name "ValueMin"
                    Set-ItemProperty -Path $path -Name "ValueMin" -Value 0 -Type DWord
                }
                powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 2>$null | Out-Null
                powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 2>$null | Out-Null
            }
        }
        @{
            Name   = "Enabling AMD Ryzen Balanced power scheme registry hints"
            Action = {
                # Some AMD chipset driver packages install a dedicated "AMD Ryzen High
                # Performance" scheme; if present, prefer it over the generic Windows one.
                $ryzenScheme = powercfg -l | Select-String "AMD Ryzen" | ForEach-Object {
                    ($_ -split '\s+')[3]
                } | Select-Object -First 1
                if ($ryzenScheme) {
                    powercfg -setactive $ryzenScheme | Out-Null
                }
            }
        }
        @{
            Name   = "Applying powercfg processor performance boost policy (max boost)"
            Action = {
                powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 2 | Out-Null
                powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 2 | Out-Null
                powercfg -setactive SCHEME_CURRENT | Out-Null
            }
        }
    )

    Invoke-TweakSequence -Title "AMD Ryzen CPU Optimization" -Steps $steps -Category "CPU" | Out-Null
    Write-Host "  [i] For full performance, keep the AMD chipset driver up to date via" -ForegroundColor DarkGray
    Write-Host "    Windows Update or amd.com - it installs Ryzen-specific power plans." -ForegroundColor DarkGray
}

function Global:Optimize-IntelCPU {
    Write-Host "`n  [INTEL CORE CPU OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Highlight

    $hw = Get-HardwareProfile

    $steps = @(
        @{
            Name   = "Switching to the High Performance power plan"
            Action = {
                $highPerf = powercfg -l | Select-String "High performance" | ForEach-Object {
                    ($_ -split '\s+')[3]
                }
                if ($highPerf) {
                    powercfg -setactive $highPerf | Out-Null
                }
            }
        }
        @{
            Name   = "Enabling Intel Speed Shift (HWP) for faster P-state ramp"
            Action = {
                powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFEPP 0 2>$null | Out-Null
                powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFEPP 0 2>$null | Out-Null
                powercfg -setactive SCHEME_CURRENT | Out-Null
            }
        }
        @{
            Name   = "Prioritizing Performance-cores for foreground apps"
            Condition = { $hw.CPU.IsHybrid }
            Action = {
                # Windows 11's Intel Thread Director integration reads this hint to bias
                # scheduling of foreground work onto P-cores on 12th-gen+ hybrid CPUs.
                $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\45bcc044-d885-43e2-8605-ee0ec6e96b59"
                if (Test-Path $path) {
                    Backup-RegistryValue -Path $path -Name "ValueMax"
                    Set-ItemProperty -Path $path -Name "ValueMax" -Value 0 -Type DWord
                }
            }
        }
        @{
            Name   = "Applying powercfg processor performance boost policy (aggressive)"
            Action = {
                powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 1 | Out-Null
                powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 1 | Out-Null
                powercfg -setactive SCHEME_CURRENT | Out-Null
            }
        }
    )

    Invoke-TweakSequence -Title "Intel Core CPU Optimization" -Steps $steps -Category "CPU" | Out-Null
}

#endregion

#region Automated Profile System

function Global:Invoke-OptimizationProfile {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Gaming", "Work", "MaxPerformance", "Privacy", "LowEndGaming", "Streaming", "Presentation")]
        [string]$ProfileName
    )
    
    Write-Host "`n[APPLYING PROFILE: $ProfileName]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    
    $profile = $Script:Profiles[$ProfileName]
    Write-Host "`n$($profile.Name)" -ForegroundColor $Script:Colors.Highlight
    Write-Host "$($profile.Description)" -ForegroundColor $Script:Colors.Info
    Write-Host ""
    
    if (-not (Confirm-Action -Message "Apply this profile?" -DefaultYes)) { return }
    
    Write-Log "Applying optimization profile: $ProfileName" -Level Info -Category "Profile"
    
    # Create restore point first
    Write-Host "`n  Creating system restore point..." -ForegroundColor $Script:Colors.Info
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        $description = "WinTweaker Profile: $ProfileName - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "  [OK] Restore point created" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "  [!] Could not create restore point" -ForegroundColor $Script:Colors.Warning
    }
    
    # Apply profile-specific optimizations. Sub-tweaks skip their own y/N prompt and
    # "press enter" pause here - the user already confirmed the whole profile above,
    # and the progress bars inside each step give all the visibility they need.
    $Script:SkipConfirmations = $true
    $Script:SkipPauses = $true
    try {
        switch ($ProfileName) {
            "Gaming" {
                Write-Host "`n  Applying gaming optimizations..." -ForegroundColor $Script:Colors.Info
                Optimize-CPU
                Optimize-GPU
                Optimize-MemoryAdvanced
                Optimize-GPUSpecific
                Enable-GamingMode
                Reduce-InputLag
                Optimize-NetworkGaming
                Optimize-FrameRate
                Disable-GameBarOverlayPopup
                Add-DefenderGameExclusions
                Enable-MSIModeInterrupts
                Register-AllInstalledGames
                Write-Host "`n  [OK] Gaming profile applied!" -ForegroundColor $Script:Colors.Success
            }

            "Work" {
                Write-Host "`n  Applying work/productivity optimizations..." -ForegroundColor $Script:Colors.Info
                Optimize-WindowsServices
                Optimize-VisualEffects
                Clear-TemporaryFiles
                Optimize-TCPIP
                Block-TelemetryAdvanced
                Tweak-FileExplorer
                Write-Host "`n  [OK] Work profile applied!" -ForegroundColor $Script:Colors.Success
            }

            "MaxPerformance" {
                Write-Host "`n  Applying maximum performance optimizations..." -ForegroundColor $Script:Colors.Info
                Write-Host "  This will apply ALL optimizations. This may take several minutes." -ForegroundColor $Script:Colors.Warning

                # System Performance
                Optimize-CPU
                Optimize-GPU
                Optimize-MemoryAdvanced
                Optimize-DiskIO
                Optimize-WindowsServices
                Optimize-VisualEffects
                Optimize-Storage

                # Gaming
                Enable-GamingMode
                Reduce-InputLag
                Optimize-GPUSpecific
                Disable-GameBarOverlayPopup
                Add-DefenderGameExclusions
                Enable-MSIModeInterrupts
                Register-AllInstalledGames

                # Network
                Optimize-TCPIP
                Optimize-NetworkAdapter

                # Advanced
                Optimize-BootShutdown
                Apply-RegistryTweaks

                Write-Host "`n  [OK] Maximum performance profile applied!" -ForegroundColor $Script:Colors.Success
            }

            "Privacy" {
                Write-Host "`n  Applying privacy optimizations..." -ForegroundColor $Script:Colors.Info
                Block-TelemetryAdvanced
                Disable-TrackingAds
                Remove-Bloatware
                Set-WindowsFeaturesPrivacy
                Set-CameraMicrophonePrivacy
                Set-NetworkPrivacy
                Enable-SecurityHardening
                Write-Host "`n  [OK] Privacy profile applied!" -ForegroundColor $Script:Colors.Success
            }

            "LowEndGaming" {
                Write-Host "`n  Applying Low-End Gaming / Max FPS optimizations..." -ForegroundColor $Script:Colors.Info
                Optimize-LowEndGaming
                Write-Host "`n  [OK] Low-End Gaming / Max FPS profile applied!" -ForegroundColor $Script:Colors.Success
            }

            "Streaming" {
                Write-Host "`n  Applying Streaming optimizations..." -ForegroundColor $Script:Colors.Info
                Optimize-Streaming
                Write-Host "`n  [OK] Streaming profile applied!" -ForegroundColor $Script:Colors.Success
            }

            "Presentation" {
                Write-Host "`n  Applying Presentation / Battery optimizations..." -ForegroundColor $Script:Colors.Info
                Optimize-Presentation
                Write-Host "`n  [OK] Presentation / Battery profile applied!" -ForegroundColor $Script:Colors.Success
            }
        }
    }
    finally {
        $Script:SkipConfirmations = $false
        $Script:SkipPauses = $false
    }

    Write-Log "Profile $ProfileName applied successfully" -Level Success -Category "Profile"
    
    Write-Host "`n+===========================================================================+" -ForegroundColor $Script:Colors.Success
    Write-Host "|  [OK] PROFILE APPLIED SUCCESSFULLY!                                       |" -ForegroundColor $Script:Colors.Success
    Write-Host "+===========================================================================+" -ForegroundColor $Script:Colors.Success
    Write-Host "`n  [!]  RESTART REQUIRED for all changes to take effect." -ForegroundColor $Script:Colors.Warning

    if ($Script:SilentMode -or $Script:SkipPauses) {
        Write-Host "  (Not prompting to restart right now - restart manually when ready.)" -ForegroundColor DarkGray
        return
    }

    $restart = Read-Host "`nRestart computer now? (y/N)"
    if ($restart -eq 'Y' -or $restart -eq 'y') {
        Write-Host "`nRestarting in 10 seconds..." -ForegroundColor $Script:Colors.Warning
        shutdown /r /t 10
    }
}

function Global:Show-ProfilesMenuEnhanced {
    Write-Host "`n[OPTIMIZATION PROFILES]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Select a profile to apply:" -ForegroundColor $Script:Colors.Info
    Write-Host ""
    Write-Host "  1. [GAME] $($Script:Profiles.Gaming.Name)" -ForegroundColor Green
    Write-Host "     $($Script:Profiles.Gaming.Description)" -ForegroundColor White
    Write-Host "     Optimizations: CPU, GPU, Memory, Gaming Mode, Input Lag, Network" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  2. [WORK] $($Script:Profiles.Work.Name)" -ForegroundColor Cyan
    Write-Host "     $($Script:Profiles.Work.Description)" -ForegroundColor White
    Write-Host "     Optimizations: Services, Visual Effects, Cleanup, Privacy, Network" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  3. * $($Script:Profiles.MaxPerformance.Name)" -ForegroundColor Yellow
    Write-Host "     $($Script:Profiles.MaxPerformance.Description)" -ForegroundColor White
    Write-Host "     Optimizations: ALL available optimizations (15+ categories)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  4. [LOCK] $($Script:Profiles.Privacy.Name)" -ForegroundColor Magenta
    Write-Host "     $($Script:Profiles.Privacy.Description)" -ForegroundColor White
    Write-Host "     Optimizations: Telemetry, Tracking, Bloatware, Privacy Controls" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  5. [GAME]  $($Script:Profiles.LowEndGaming.Name)" -ForegroundColor Red
    Write-Host "     $($Script:Profiles.LowEndGaming.Description)" -ForegroundColor White
    Write-Host "     For: budget/older PCs where every FPS counts. Not recommended on" -ForegroundColor DarkGray
    Write-Host "     work PCs - disables Widgets, Chat, background apps and more." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  6. [NET] $($Script:Profiles.Streaming.Name)" -ForegroundColor Blue
    Write-Host "     $($Script:Profiles.Streaming.Description)" -ForegroundColor White
    Write-Host ""
    Write-Host "  7. [BATT] $($Script:Profiles.Presentation.Name)" -ForegroundColor DarkGreen
    Write-Host "     $($Script:Profiles.Presentation.Description)" -ForegroundColor White
    Write-Host ""
    Write-Host "  0. <- Cancel" -ForegroundColor Red
    Write-Host ""

    $choice = Read-Host "Select profile (1-7)"

    switch ($choice) {
        '1' { Invoke-OptimizationProfile -ProfileName "Gaming" }
        '2' { Invoke-OptimizationProfile -ProfileName "Work" }
        '3' { Invoke-OptimizationProfile -ProfileName "MaxPerformance" }
        '4' { Invoke-OptimizationProfile -ProfileName "Privacy" }
        '5' { Invoke-OptimizationProfile -ProfileName "LowEndGaming" }
        '6' { Invoke-OptimizationProfile -ProfileName "Streaming" }
        '7' { Invoke-OptimizationProfile -ProfileName "Presentation" }
        '0' { return }
        default {
            Write-Host "`n[X] Invalid selection" -ForegroundColor $Script:Colors.Error
            Start-Sleep -Seconds 2
        }
    }
}

#endregion

#region System Analysis

function Global:Start-SystemAnalysis {
    Write-Host "`n[SYSTEM ANALYSIS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Analyzing your system for optimization opportunities..." -ForegroundColor $Script:Colors.Info
    Write-Host ""
    
    $analysis = @{
        Issues          = @()
        Recommendations = @()
        Score           = 0
    }
    
    # Analyze services
    Write-Host "  Analyzing services..." -ForegroundColor $Script:Colors.Info
    $unnecessaryServices = @('DiagTrack', 'dmwappushservice', 'SysMain', 'WSearch')
    $runningUnnecessary = 0
    foreach ($svc in $unnecessaryServices) {
        $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq 'Running') {
            $runningUnnecessary++
        }
    }
    if ($runningUnnecessary -gt 0) {
        $analysis.Issues += "Found $runningUnnecessary unnecessary services running"
        $analysis.Recommendations += "Optimize Windows Services (Category 1, Option 5)"
    }
    
    # Analyze disk space
    Write-Host "  Analyzing disk space..." -ForegroundColor $Script:Colors.Info
    $systemDrive = Get-Volume | Where-Object { $_.DriveLetter -eq $env:SystemDrive.TrimEnd(':') }
    $freePercent = ($systemDrive.SizeRemaining / $systemDrive.Size) * 100
    if ($freePercent -lt 20) {
        $analysis.Issues += "Low disk space: Only $([math]::Round($freePercent, 1))% free"
        $analysis.Recommendations += "Run Disk Cleanup (Category 5, Option 1)"
    }
    
    # Analyze startup programs
    Write-Host "  Analyzing startup programs..." -ForegroundColor $Script:Colors.Info
    $startupCount = (Get-CimInstance -ClassName Win32_StartupCommand).Count
    if ($startupCount -gt 10) {
        $analysis.Issues += "High number of startup programs: $startupCount"
        $analysis.Recommendations += "Manage Startup Programs (Category 1, Option 7)"
    }
    
    # Analyze visual effects
    Write-Host "  Analyzing visual effects..." -ForegroundColor $Script:Colors.Info
    $visualFX = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -ErrorAction SilentlyContinue
    if (-not $visualFX -or $visualFX.VisualFXSetting -ne 2) {
        $analysis.Issues += "Visual effects not optimized for performance"
        $analysis.Recommendations += "Optimize Visual Effects (Category 1, Option 6)"
    }
    
    # Analyze telemetry
    Write-Host "  Analyzing privacy settings..." -ForegroundColor $Script:Colors.Info
    $telemetry = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue
    if (-not $telemetry -or $telemetry.AllowTelemetry -ne 0) {
        $analysis.Issues += "Windows telemetry is enabled"
        $analysis.Recommendations += "Block Telemetry (Category 4, Option 1)"
    }
    
    # Calculate score
    $maxIssues = 5
    $analysis.Score = [math]::Max(0, 100 - ($analysis.Issues.Count * 20))
    
    # Display results
    Write-Host "`n+===========================================================================+" -ForegroundColor $Script:Colors.Title
    Write-Host "|  SYSTEM ANALYSIS RESULTS                                                  |" -ForegroundColor $Script:Colors.Title
    Write-Host "+===========================================================================+" -ForegroundColor $Script:Colors.Title
    Write-Host ""
    
    # Score display
    $scoreColor = if ($analysis.Score -ge 80) { $Script:Colors.Success } 
    elseif ($analysis.Score -ge 60) { $Script:Colors.Warning }
    else { $Script:Colors.Error }
    Write-Host "  OPTIMIZATION SCORE: $($analysis.Score)/100" -ForegroundColor $scoreColor
    Write-Host ""
    
    # Issues
    if ($analysis.Issues.Count -gt 0) {
        Write-Host "  ISSUES FOUND:" -ForegroundColor $Script:Colors.Warning
        foreach ($issue in $analysis.Issues) {
            Write-Host "    [!] $issue" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    else {
        Write-Host "  [OK] No issues found! Your system is well optimized." -ForegroundColor $Script:Colors.Success
        Write-Host ""
    }
    
    # Recommendations
    if ($analysis.Recommendations.Count -gt 0) {
        Write-Host "  RECOMMENDATIONS:" -ForegroundColor $Script:Colors.Info
        foreach ($rec in $analysis.Recommendations) {
            Write-Host "    -> $rec" -ForegroundColor Cyan
        }
        Write-Host ""
    }
    
    Write-Log "System analysis completed. Score: $($analysis.Score)/100" -Level Info -Category "Analysis"
    
    Wait-ForUser
}

#endregion

#region Advanced Reporting

function Global:New-OptimizationReport {
    Write-Host "`n[GENERATE OPTIMIZATION REPORT]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    $reportPath = "$PSScriptRoot\OptimizationReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

    Write-Host "`nGenerating comprehensive report..." -ForegroundColor $Script:Colors.Info

    # Each step below does its real share of the work (not a decorative delay) -
    # the report data is gathered inside the step closures so the progress bar
    # reflects what is actually happening at that moment.
    $data = @{
        SysInfo                  = $null
        HW                       = $null
        Drives                   = @()
        Issues                   = @()
        ChangedRegistry          = @()
        ChangedServices          = @()
        ChangedDefenderExclusion = @()
        Thermal                  = $null
        MemSpeed                 = $null
        PmtuBlackHoleDetect      = $false
        DetectedGameLibraries    = 0
    }

    $reportSteps = @(
        @{
            Name   = "Gathering system & hardware information"
            Action = {
                $data.SysInfo = Get-SystemInfo
                $data.HW = Get-HardwareProfile
            }.GetNewClosure()
        }
        @{
            Name   = "Collecting disk information"
            Action = { $data.Drives = @(Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' }) }.GetNewClosure()
        }
        @{
            Name   = "Analyzing services, telemetry and disk headroom"
            Action = {
                $issues = @()
                $unnecessaryServices = @('DiagTrack', 'dmwappushservice', 'SysMain', 'WSearch')
                $runningUnnecessary = ($unnecessaryServices | ForEach-Object {
                        $s = Get-Service -Name $_ -ErrorAction SilentlyContinue
                        if ($s -and $s.Status -eq 'Running') { $_ }
                    }).Count
                if ($runningUnnecessary -gt 0) { $issues += "$runningUnnecessary unnecessary background service(s) still running" }

                $telemetry = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue
                if (-not $telemetry -or $telemetry.AllowTelemetry -ne 0) { $issues += "Windows telemetry is not blocked" }

                $visualFX = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -ErrorAction SilentlyContinue
                if (-not $visualFX -or $visualFX.VisualFXSetting -ne 2) { $issues += "Visual effects are not set to best performance" }

                foreach ($drive in $data.Drives) {
                    $freePercent = ($drive.SizeRemaining / $drive.Size) * 100
                    if ($freePercent -lt 15) { $issues += "Drive $($drive.DriveLetter): only $([math]::Round($freePercent, 1))% free" }
                }

                $data.Issues = $issues
            }.GetNewClosure()
        }
        @{
            Name   = "Summarizing settings changed this session"
            Action = {
                $data.ChangedRegistry = @($Script:ConfigBackup | Where-Object { $_.Type -eq 'Registry' })
                $data.ChangedServices = @($Script:ConfigBackup | Where-Object { $_.Type -eq 'Service' })
                $data.ChangedDefenderExclusion = @($Script:ConfigBackup | Where-Object { $_.Type -eq 'DefenderExclusion' })
            }.GetNewClosure()
        }
        @{
            Name   = "Checking thermal throttling and memory speed"
            Action = {
                $data.Thermal = Get-ThermalThrottleStatus
                $data.MemSpeed = Get-MemorySpeedStatus
                if ($data.Thermal.Detected) { $data.Issues += "Possible CPU thermal throttling detected" }
                if ($data.MemSpeed.Detected) { $data.Issues += "RAM running below its rated speed (XMP/DOCP not enabled)" }
            }.GetNewClosure()
        }
        @{
            Name   = "Checking network health (Path MTU Black Hole Detection)"
            Action = {
                $pmtu = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "EnablePMTUBHDetect" -ErrorAction SilentlyContinue
                $data.PmtuBlackHoleDetect = [bool]($pmtu -and $pmtu.EnablePMTUBHDetect -eq 1)
                if (-not $data.PmtuBlackHoleDetect) { $data.Issues += "Path MTU Black Hole Detection is not enabled" }
                $data.DetectedGameLibraries = @(Get-DetectedGameFolders).Count
            }.GetNewClosure()
        }
    )

    Invoke-TweakSequence -Title "Building Optimization Report" -Steps $reportSteps -Category "Report" | Out-Null

    $sysInfo = $data.SysInfo
    $hw = $data.HW
    $drives = $data.Drives
    $issues = $data.Issues
    $changedRegistry = $data.ChangedRegistry
    $changedServices = $data.ChangedServices
    $changedDefenderExclusions = $data.ChangedDefenderExclusion
    $thermal = $data.Thermal
    $memSpeed = $data.MemSpeed
    $pmtuOk = $data.PmtuBlackHoleDetect
    $detectedGameLibraries = $data.DetectedGameLibraries

    $healthScore = [math]::Max(0, 100 - ($issues.Count * 15))
    $scoreClass = if ($healthScore -ge 80) { 'success' } elseif ($healthScore -ge 60) { 'warning' } else { 'error' }

    # ---- Build HTML ---------------------------------------------------------
    Write-Host "`n  Rendering HTML report..." -ForegroundColor $Script:Colors.Info
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Wethereal - Optimization Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #0078d4; border-bottom: 3px solid #0078d4; padding-bottom: 10px; }
        h2 { color: #333; margin-top: 30px; border-left: 4px solid #0078d4; padding-left: 10px; }
        .info-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px; margin: 20px 0; }
        .info-box { background: #f9f9f9; padding: 15px; border-radius: 5px; border-left: 4px solid #0078d4; }
        .info-label { font-weight: bold; color: #666; }
        .info-value { color: #333; margin-top: 5px; }
        .success { color: #107c10; }
        .warning { color: #ff8c00; }
        .error { color: #d13438; }
        .score { font-size: 48px; font-weight: bold; }
        .badge { display: inline-block; padding: 2px 10px; border-radius: 12px; font-size: 12px; font-weight: bold; color: white; }
        .badge.nvidia { background: #76b900; } .badge.amd { background: #ed1c24; } .badge.intel { background: #0071c5; } .badge.unknown { background: #888; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 10px 12px; text-align: left; border-bottom: 1px solid #ddd; font-size: 14px; }
        th { background: #0078d4; color: white; }
        tr:hover { background: #f5f5f5; }
        .bar-bg { background: #e0e0e0; border-radius: 6px; height: 10px; overflow: hidden; }
        .bar-fill { background: #0078d4; height: 100%; }
        .footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; text-align: center; color: #666; }
        .empty { color: #888; font-style: italic; }
    </style>
</head>
<body>
    <div class="container">
        <h1>[BOOST] Wethereal - Optimization Report</h1>
        <p><strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p><strong>Wethereal Version:</strong> $($Script:Version) Ultimate Edition</p>

        <h2>[TARGET] Optimization Score</h2>
        <p class="score $scoreClass">$healthScore/100</p>
$(
        if ($issues.Count -gt 0) {
            "<p><strong>Open items:</strong></p><ul>" + (($issues | ForEach-Object { "<li class='warning'>[!] $_</li>" }) -join "`n") + "</ul>"
        }
        else {
            "<p class='success'>[OK] No open optimization issues detected.</p>"
        }
)

        <h2>[STATS] System Information</h2>
        <div class="info-grid">
            <div class="info-box">
                <div class="info-label">[PC] CPU</div>
                <div class="info-value">$($sysInfo.CPU) <span class="badge $($hw.CPU.Vendor.ToLower())">$($hw.CPU.Vendor)</span></div>
            </div>
            <div class="info-box">
                <div class="info-label">[CPU] RAM</div>
                <div class="info-value">$($sysInfo.RAM)</div>
            </div>
            <div class="info-box">
                <div class="info-label">[GAME] GPU(s)</div>
                <div class="info-value">$(
        if ($hw.GPUs.Count -eq 0) { "Not detected" }
        else { ($hw.GPUs | ForEach-Object { "$($_.Name) <span class='badge $($_.Vendor.ToLower())'>$($_.Vendor)</span>" }) -join "<br>" }
)</div>
            </div>
            <div class="info-box">
                <div class="info-label">[WIN] Operating System</div>
                <div class="info-value">$($sysInfo.OS)</div>
            </div>
            <div class="info-box">
                <div class="info-label">[TIME] Uptime</div>
                <div class="info-value">$($sysInfo.Uptime.Days)d $($sysInfo.Uptime.Hours)h $($sysInfo.Uptime.Minutes)m</div>
            </div>
            <div class="info-box">
                <div class="info-label">[BUILD] Platform Profile</div>
                <div class="info-value">$(if ($hw.IsHybridGPU) { "Hybrid GPU ($($hw.GPUVendors -join ' + '))" } else { "Single-vendor $($hw.GPUVendors -join ', ')" })</div>
            </div>
        </div>

        <h2>[DISK] Disk Information</h2>
        <table>
            <tr><th>Drive</th><th>Free</th><th>Total</th><th>Used</th><th></th></tr>
$(
    ($drives | ForEach-Object {
                $freeGB = [math]::Round($_.SizeRemaining / 1GB, 2)
                $totalGB = [math]::Round($_.Size / 1GB, 2)
                $usedPct = [math]::Round((($_.Size - $_.SizeRemaining) / $_.Size) * 100, 1)
                "<tr><td>$($_.DriveLetter):</td><td>$freeGB GB</td><td>$totalGB GB</td><td>$usedPct%</td><td><div class='bar-bg'><div class='bar-fill' style='width:$usedPct%'></div></div></td></tr>"
            }) -join "`n"
)
        </table>

        <h2>[HOT] Hardware Health &amp; Gaming Readiness</h2>
        <div class="info-grid">
            <div class="info-box">
                <div class="info-label">[HOT] Thermal Throttling</div>
                <div class="info-value $(if ($thermal.Detected) { 'warning' } else { 'success' })">$($thermal.Detail)</div>
            </div>
            <div class="info-box">
                <div class="info-label">[CPU] Memory Speed</div>
                <div class="info-value $(if ($memSpeed.Detected) { 'warning' } else { 'success' })">$($memSpeed.Detail)</div>
            </div>
            <div class="info-box">
                <div class="info-label">[NET] Path MTU Black Hole Detection</div>
                <div class="info-value $(if ($pmtuOk) { 'success' } else { 'warning' })">$(if ($pmtuOk) { "[OK] Enabled" } else { "[!] Not enabled - run TCP/IP Optimization" })</div>
            </div>
            <div class="info-box">
                <div class="info-label">[GAME] Detected Game Libraries</div>
                <div class="info-value">$detectedGameLibraries folder(s) (Steam/Epic/Battle.net/Riot/GOG/Ubisoft)</div>
            </div>
        </div>

        <h2>[TOOLS] Settings Changed This Session</h2>
        <p>$($changedRegistry.Count) registry value(s), $($changedServices.Count) service(s) and $($changedDefenderExclusions.Count) Defender exclusion(s) modified by Wethereal since it started (originals were backed up before each change):</p>
        <table>
            <tr><th>Type</th><th>Target</th><th>Original Value</th></tr>
$(
        if ($changedRegistry.Count -eq 0 -and $changedServices.Count -eq 0 -and $changedDefenderExclusions.Count -eq 0) {
            "<tr><td colspan='3' class='empty'>No changes recorded in this session yet.</td></tr>"
        }
        else {
            $rows = @()
            $rows += $changedRegistry | ForEach-Object { "<tr><td>Registry</td><td>$($_.Path)\$($_.Name)</td><td>$($_.Value)</td></tr>" }
            $rows += $changedServices | ForEach-Object { "<tr><td>Service</td><td>$($_.Name)</td><td>Status=$($_.Status), StartType=$($_.StartType)</td></tr>" }
            $rows += $changedDefenderExclusions | ForEach-Object { "<tr><td>Defender Exclusion</td><td>$($_.Path)</td><td>-</td></tr>" }
            $rows -join "`n"
        }
)
        </table>

        <h2>[LIST] Optimization Log</h2>
        <p>Most recent activity (last 50 entries):</p>
        <table>
            <tr>
                <th>Timestamp</th>
                <th>Level</th>
                <th>Category</th>
                <th>Message</th>
            </tr>
"@

    # Add log entries
    if (Test-Path $Script:LogFile) {
        $logEntries = Get-Content -Path $Script:LogFile -Tail 50
        foreach ($entry in $logEntries) {
            if ($entry -match '\[(.*?)\] \[(.*?)\] \[(.*?)\] (.*)') {
                $timestamp = $matches[1]
                $level = $matches[2]
                $category = $matches[3]
                $message = $matches[4]

                $levelClass = switch ($level) {
                    'Success' { 'success' }
                    'Warning' { 'warning' }
                    'Error' { 'error' }
                    default { '' }
                }

                $html += @"
            <tr>
                <td>$timestamp</td>
                <td class="$levelClass">$level</td>
                <td>$category</td>
                <td>$message</td>
            </tr>
"@
            }
        }
    }
    else {
        $html += "<tr><td colspan='4' class='empty'>No log file found yet.</td></tr>"
    }

    $recommendations = @()
    if ($issues.Count -gt 0) { $recommendations += "Re-run the relevant optimizations listed under 'Optimization Score' above" }
    $recommendations += "Restart your computer to fully apply all changes"
    $recommendations += "Run the Performance Benchmark (Category 7, Option 2) to measure improvements"
    $recommendations += "Create a system restore point before further optimizations (Category 8, Option 2)"
    $recommendations += "Monitor system performance over the next few days"

    $html += @"
        </table>

        <h2>[OK] Recommendations</h2>
        <ul>
$(($recommendations | ForEach-Object { "            <li>$_</li>" }) -join "`n")
        </ul>

        <div class="footer">
            <p>Wethereal Ultimate Edition v$($Script:Version)</p>
            <p>For more information, visit the project documentation</p>
        </div>
    </div>
</body>
</html>
"@

    # Save report
    $html | Out-File -FilePath $reportPath -Encoding UTF8

    Write-Host "`n[OK] Report generated successfully!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Location: $reportPath" -ForegroundColor $Script:Colors.Info
    Write-Log "Generated optimization report: $reportPath" -Level Success -Category "Report"

    $open = Read-Host "`nOpen report in browser? (Y/n)"
    if ($open -ne 'N' -and $open -ne 'n') {
        Start-Process $reportPath
    }
}

#endregion

#region Enhanced Bloatware Detection

function Global:Get-EnhancedBloatwareList {
    Write-Host "`n[ENHANCED BLOATWARE DETECTION]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Scanning for bloatware and unnecessary apps..." -ForegroundColor $Script:Colors.Info
    Write-Host ""
    
    $allApps = Get-AppxPackage | Select-Object Name, PackageFullName, 
    @{Name = "Size"; Expression = { [math]::Round($_.PackageSize / 1MB, 2) } },
    @{Name = "InstallDate"; Expression = { $_.InstallDate } }
    
    # NOTE: patterns are deliberately specific full (or near-full) package-family
    # names, NOT bare generic words. Earlier revisions matched on single words like
    # "Netflix", "Facebook", "Farm", "Candy" or "Bubble" - those are wildcard-matched
    # with -like "*word*" against every installed AppX package name, which risks
    # catching an app the user actually installed and wants to keep (or an unrelated
    # package that merely contains that substring). Every entry below is scoped to
    # the real sponsored/pre-installed package identifier Microsoft ships on a clean
    # Windows 10/11 image.
    $bloatwarePatterns = @(
        "Microsoft.3DBuilder",
        "Microsoft.BingFinance", "Microsoft.BingNews", "Microsoft.BingSports", "Microsoft.BingWeather",
        "Microsoft.GetHelp", "Microsoft.Getstarted", "Microsoft.Messaging",
        "Microsoft.Microsoft3DViewer", "Microsoft.MicrosoftOfficeHub",
        "Microsoft.MicrosoftSolitaireCollection", "Microsoft.MixedReality.Portal",
        "Microsoft.Office.OneNote", "Microsoft.People", "Microsoft.Print3D",
        "Microsoft.SkypeApp", "Microsoft.Wallet", "Microsoft.WindowsAlarms",
        "Microsoft.WindowsCamera", "microsoft.windowscommunicationsapps",
        "Microsoft.WindowsFeedbackHub", "Microsoft.WindowsMaps",
        "Microsoft.WindowsSoundRecorder", "Microsoft.Xbox.TCUI",
        "Microsoft.XboxApp", "Microsoft.XboxGameOverlay", "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxIdentityProvider", "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.YourPhone", "Microsoft.ZuneMusic", "Microsoft.ZuneVideo",
        # Third-party sponsored apps Microsoft pre-installs (full package identifiers)
        "king.com.CandyCrushSaga", "king.com.CandyCrushSodaSaga", "king.com.BubbleWitch3Saga",
        "king.com.FarmHeroesSaga", "A278AB0D.MarchofEmpires", "A278AB0D.DisneyMagicKingdoms",
        "9E2F88E3.Twitter", "Facebook.Facebook", "DolbyLaboratories.DolbyAccess",
        "DolbyLaboratories.DolbyAudio", "4DF9E0F8.Netflix", "SpotifyAB.SpotifyMusic"
    )
    
    $detectedBloatware = @()
    foreach ($app in $allApps) {
        foreach ($pattern in $bloatwarePatterns) {
            if ($app.Name -like "*$pattern*") {
                $detectedBloatware += [PSCustomObject]@{
                    Name        = $app.Name
                    FullName    = $app.PackageFullName
                    Size        = "$($app.Size) MB"
                    InstallDate = $app.InstallDate
                }
                break
            }
        }
    }
    
    if ($detectedBloatware.Count -eq 0) {
        Write-Host "  [OK] No bloatware detected!" -ForegroundColor $Script:Colors.Success
        Wait-ForUser
        return
    }
    
    Write-Host "  Found $($detectedBloatware.Count) bloatware apps:" -ForegroundColor $Script:Colors.Warning
    Write-Host ""
    
    for ($i = 0; $i -lt $detectedBloatware.Count; $i++) {
        $app = $detectedBloatware[$i]
        Write-Host "  $($i + 1). $($app.Name)" -ForegroundColor White
        Write-Host "      Size: $($app.Size)" -ForegroundColor DarkGray
    }
    
    Write-Host ""
    $remove = Read-Host "Remove all detected bloatware? (y/N)"
    
    if ($remove -eq 'Y' -or $remove -eq 'y') {
        $steps = $detectedBloatware | ForEach-Object {
            $app = $_
            @{
                Name   = "Removing $($app.Name)"
                Action = { Remove-AppxPackage -Package $app.FullName -ErrorAction Stop }.GetNewClosure()
            }
        }
        Invoke-TweakSequence -Title "Bloatware Removal" -Steps $steps -Category "Bloatware" | Out-Null
    }

    Wait-ForUser
}

#endregion


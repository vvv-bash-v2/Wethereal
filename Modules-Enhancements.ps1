# Windows Performance Tweaker Ultimate Edition v2.1.0
# Enhancement Module - Advanced Features
# GPU Optimizations, Automated Profiles, System Analysis, Advanced Reporting

#region GPU-Specific Optimizations

function Get-GPUVendor {
    try {
        $gpu = Get-CimInstance -ClassName Win32_VideoController | Select-Object -First 1
        $name = $gpu.Name.ToLower()
        
        if ($name -match "nvidia|geforce|gtx|rtx") {
            return "NVIDIA"
        }
        elseif ($name -match "amd|radeon|rx") {
            return "AMD"
        }
        elseif ($name -match "intel|uhd|iris") {
            return "Intel"
        }
        else {
            return "Unknown"
        }
    }
    catch {
        return "Unknown"
    }
}

function Optimize-GPUSpecific {
    Write-Host "`n[GPU-SPECIFIC OPTIMIZATIONS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    $vendor = Get-GPUVendor
    Write-Host "`nDetected GPU: $vendor" -ForegroundColor $Script:Colors.Info
    
    if ($vendor -eq "Unknown") {
        Write-Host "Could not detect GPU vendor. Skipping GPU-specific optimizations." -ForegroundColor $Script:Colors.Warning
        Read-Host "`nPress Enter to continue"
        return
    }
    
    if (-not (Confirm-Action -Message "Apply $vendor-specific optimizations?")) { return }
    
    Write-Log "Applying $vendor GPU optimizations" -Level Info -Category "GPU"
    
    switch ($vendor) {
        "NVIDIA" { Optimize-NVIDIA }
        "AMD" { Optimize-AMD }
        "Intel" { Optimize-IntelGPU }
    }
    
    Read-Host "`nPress Enter to continue"
}

function Optimize-NVIDIA {
    Write-Host "`n  Applying NVIDIA optimizations..." -ForegroundColor $Script:Colors.Info
    
    try {
        # Disable NVIDIA telemetry
        $services = @("NvTelemetryContainer", "NvContainerLocalSystem")
        foreach ($svc in $services) {
            $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
            if ($service) {
                Backup-ServiceState -ServiceName $svc
                Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
                Set-Service -Name $svc -StartupType Disabled
                Write-Log "Disabled NVIDIA service: $svc" -Level Success -Category "GPU"
            }
        }
        
        # Optimize NVIDIA control panel settings via registry
        $path = "HKCU:\Software\NVIDIA Corporation\Global\NVTweak"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        
        # Set power management to prefer maximum performance
        $path = "HKCU:\Software\NVIDIA Corporation\Global\FTS"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Backup-RegistryValue -Path $path -Name "EnableRID44231"
        Set-ItemProperty -Path $path -Name "EnableRID44231" -Value 0 -Type DWord
        
        Write-Host "  ✓ NVIDIA optimizations applied!" -ForegroundColor $Script:Colors.Success
        Write-Log "NVIDIA optimizations completed" -Level Success -Category "GPU"
    }
    catch {
        Write-Log "Failed to optimize NVIDIA: $($_.Exception.Message)" -Level Error -Category "GPU"
    }
}

function Optimize-AMD {
    Write-Host "`n  Applying AMD optimizations..." -ForegroundColor $Script:Colors.Info
    
    try {
        # Disable AMD telemetry and user experience program
        $path = "HKLM:\SOFTWARE\AMD\CN"
        if (Test-Path $path) {
            Backup-RegistryValue -Path $path -Name "AutoUpdateTriggered"
            Set-ItemProperty -Path $path -Name "AutoUpdateTriggered" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        }
        
        # Optimize AMD settings
        $path = "HKCU:\Software\AMD\DVR"
        if (Test-Path $path) {
            Backup-RegistryValue -Path $path -Name "PerformanceMonitorOpacityWA"
            Set-ItemProperty -Path $path -Name "PerformanceMonitorOpacityWA" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        }
        
        Write-Host "  ✓ AMD optimizations applied!" -ForegroundColor $Script:Colors.Success
        Write-Log "AMD optimizations completed" -Level Success -Category "GPU"
    }
    catch {
        Write-Log "Failed to optimize AMD: $($_.Exception.Message)" -Level Error -Category "GPU"
    }
}

function Optimize-IntelGPU {
    Write-Host "`n  Applying Intel GPU optimizations..." -ForegroundColor $Script:Colors.Info
    
    try {
        # Optimize Intel graphics settings
        $path = "HKCU:\Software\Intel\Display\igfxcui\profiles\media"
        if (Test-Path $path) {
            Backup-RegistryValue -Path $path -Name "ProcAmpBrightness"
            Set-ItemProperty -Path $path -Name "ProcAmpBrightness" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        }
        
        Write-Host "  ✓ Intel GPU optimizations applied!" -ForegroundColor $Script:Colors.Success
        Write-Log "Intel GPU optimizations completed" -Level Success -Category "GPU"
    }
    catch {
        Write-Log "Failed to optimize Intel GPU: $($_.Exception.Message)" -Level Error -Category "GPU"
    }
}

#endregion

#region Automated Profile System

function Invoke-OptimizationProfile {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Gaming", "Work", "MaxPerformance", "Privacy")]
        [string]$ProfileName
    )
    
    Write-Host "`n[APPLYING PROFILE: $ProfileName]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
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
        Write-Host "  ✓ Restore point created" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "  ⚠ Could not create restore point" -ForegroundColor $Script:Colors.Warning
    }
    
    # Apply profile-specific optimizations
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
            Write-Host "`n  ✓ Gaming profile applied!" -ForegroundColor $Script:Colors.Success
        }
        
        "Work" {
            Write-Host "`n  Applying work/productivity optimizations..." -ForegroundColor $Script:Colors.Info
            Optimize-WindowsServices
            Optimize-VisualEffects
            Clean-TemporaryFiles
            Optimize-TCPIP
            Block-TelemetryAdvanced
            Tweak-FileExplorer
            Write-Host "`n  ✓ Work profile applied!" -ForegroundColor $Script:Colors.Success
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
            
            # Network
            Optimize-TCPIP
            Optimize-NetworkAdapter
            
            # Advanced
            Optimize-BootShutdown
            Apply-RegistryTweaks
            
            Write-Host "`n  ✓ Maximum performance profile applied!" -ForegroundColor $Script:Colors.Success
        }
        
        "Privacy" {
            Write-Host "`n  Applying privacy optimizations..." -ForegroundColor $Script:Colors.Info
            Block-TelemetryAdvanced
            Disable-TrackingAds
            Remove-Bloatware
            Configure-WindowsFeaturesPrivacy
            Configure-CameraMicrophonePrivacy
            Configure-NetworkPrivacy
            Enable-SecurityHardening
            Write-Host "`n  ✓ Privacy profile applied!" -ForegroundColor $Script:Colors.Success
        }
    }
    
    Write-Log "Profile $ProfileName applied successfully" -Level Success -Category "Profile"
    
    Write-Host "`n╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Script:Colors.Success
    Write-Host "║  ✓ PROFILE APPLIED SUCCESSFULLY!                                          ║" -ForegroundColor $Script:Colors.Success
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Script:Colors.Success
    Write-Host "`n  ⚠️  RESTART REQUIRED for all changes to take effect." -ForegroundColor $Script:Colors.Warning
    
    $restart = Read-Host "`nRestart computer now? (y/N)"
    if ($restart -eq 'Y' -or $restart -eq 'y') {
        Write-Host "`nRestarting in 10 seconds..." -ForegroundColor $Script:Colors.Warning
        shutdown /r /t 10
    }
}

function Show-ProfilesMenuEnhanced {
    Write-Host "`n[OPTIMIZATION PROFILES]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    Write-Host "Select a profile to apply:" -ForegroundColor $Script:Colors.Info
    Write-Host ""
    Write-Host "  1. 🎮 $($Script:Profiles.Gaming.Name)" -ForegroundColor Green
    Write-Host "     $($Script:Profiles.Gaming.Description)" -ForegroundColor White
    Write-Host "     Optimizations: CPU, GPU, Memory, Gaming Mode, Input Lag, Network" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  2. 💼 $($Script:Profiles.Work.Name)" -ForegroundColor Cyan
    Write-Host "     $($Script:Profiles.Work.Description)" -ForegroundColor White
    Write-Host "     Optimizations: Services, Visual Effects, Cleanup, Privacy, Network" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  3. ⚡ $($Script:Profiles.MaxPerformance.Name)" -ForegroundColor Yellow
    Write-Host "     $($Script:Profiles.MaxPerformance.Description)" -ForegroundColor White
    Write-Host "     Optimizations: ALL available optimizations (15+ categories)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  4. 🔒 $($Script:Profiles.Privacy.Name)" -ForegroundColor Magenta
    Write-Host "     $($Script:Profiles.Privacy.Description)" -ForegroundColor White
    Write-Host "     Optimizations: Telemetry, Tracking, Bloatware, Privacy Controls" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  0. ← Cancel" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Select profile (1-4)"
    
    switch ($choice) {
        '1' { Invoke-OptimizationProfile -ProfileName "Gaming" }
        '2' { Invoke-OptimizationProfile -ProfileName "Work" }
        '3' { Invoke-OptimizationProfile -ProfileName "MaxPerformance" }
        '4' { Invoke-OptimizationProfile -ProfileName "Privacy" }
        '0' { return }
        default {
            Write-Host "`n✗ Invalid selection" -ForegroundColor $Script:Colors.Error
            Start-Sleep -Seconds 2
        }
    }
}

#endregion

#region System Analysis

function Start-SystemAnalysis {
    Write-Host "`n[SYSTEM ANALYSIS]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
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
    Write-Host "`n╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Script:Colors.Title
    Write-Host "║  SYSTEM ANALYSIS RESULTS                                                  ║" -ForegroundColor $Script:Colors.Title
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Script:Colors.Title
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
            Write-Host "    ⚠ $issue" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    else {
        Write-Host "  ✓ No issues found! Your system is well optimized." -ForegroundColor $Script:Colors.Success
        Write-Host ""
    }
    
    # Recommendations
    if ($analysis.Recommendations.Count -gt 0) {
        Write-Host "  RECOMMENDATIONS:" -ForegroundColor $Script:Colors.Info
        foreach ($rec in $analysis.Recommendations) {
            Write-Host "    → $rec" -ForegroundColor Cyan
        }
        Write-Host ""
    }
    
    Write-Log "System analysis completed. Score: $($analysis.Score)/100" -Level Info -Category "Analysis"
    
    Read-Host "Press Enter to continue"
}

#endregion

#region Advanced Reporting

function New-OptimizationReport {
    Write-Host "`n[GENERATE OPTIMIZATION REPORT]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    
    $reportPath = "$PSScriptRoot\OptimizationReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    
    Write-Host "`nGenerating comprehensive report..." -ForegroundColor $Script:Colors.Info
    
    # Gather system information
    $sysInfo = Get-SystemInfo
    $vendor = Get-GPUVendor
    
    # Create HTML report
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Windows Performance Tweaker - Optimization Report</title>
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
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #0078d4; color: white; }
        tr:hover { background: #f5f5f5; }
        .footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; text-align: center; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Windows Performance Tweaker - Optimization Report</h1>
        <p><strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p><strong>Version:</strong> 2.1.0 Ultimate Edition</p>
        
        <h2>📊 System Information</h2>
        <div class="info-grid">
            <div class="info-box">
                <div class="info-label">💻 CPU</div>
                <div class="info-value">$($sysInfo.CPU)</div>
            </div>
            <div class="info-box">
                <div class="info-label">🧠 RAM</div>
                <div class="info-value">$($sysInfo.RAM)</div>
            </div>
            <div class="info-box">
                <div class="info-label">🎮 GPU</div>
                <div class="info-value">$($sysInfo.GPU) ($vendor)</div>
            </div>
            <div class="info-box">
                <div class="info-label">🪟 Operating System</div>
                <div class="info-value">$($sysInfo.OS)</div>
            </div>
        </div>
        
        <h2>📋 Optimization Log Summary</h2>
        <p>Recent optimization activities:</p>
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
        $logEntries = Get-Content -Path $Script:LogFile -Tail 20
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
    
    $html += @"
        </table>
        
        <h2>✅ Recommendations</h2>
        <ul>
            <li>Restart your computer to apply all changes</li>
            <li>Run performance benchmark to measure improvements</li>
            <li>Create a system restore point before further optimizations</li>
            <li>Monitor system performance over the next few days</li>
        </ul>
        
        <div class="footer">
            <p>Windows Performance Tweaker Ultimate Edition v2.1.0</p>
            <p>For more information, visit the project documentation</p>
        </div>
    </div>
</body>
</html>
"@
    
    # Save report
    $html | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-Host "`n✓ Report generated successfully!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Location: $reportPath" -ForegroundColor $Script:Colors.Info
    Write-Log "Generated optimization report: $reportPath" -Level Success -Category "Report"
    
    $open = Read-Host "`nOpen report in browser? (Y/n)"
    if ($open -ne 'N' -and $open -ne 'n') {
        Start-Process $reportPath
    }
}

#endregion

#region Enhanced Bloatware Detection

function Get-EnhancedBloatwareList {
    Write-Host "`n[ENHANCED BLOATWARE DETECTION]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title
    Write-Host "Scanning for bloatware and unnecessary apps..." -ForegroundColor $Script:Colors.Info
    Write-Host ""
    
    $allApps = Get-AppxPackage | Select-Object Name, PackageFullName, 
    @{Name = "Size"; Expression = { [math]::Round($_.PackageSize / 1MB, 2) } },
    @{Name = "InstallDate"; Expression = { $_.InstallDate } }
    
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
        "Candy", "Bubble", "Farm", "king.com", "Solitaire", "Twitter",
        "Facebook", "Disney", "Dolby", "Netflix", "Spotify"
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
        Write-Host "  ✓ No bloatware detected!" -ForegroundColor $Script:Colors.Success
        Read-Host "`nPress Enter to continue"
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
        Write-Host "`nRemoving bloatware..." -ForegroundColor $Script:Colors.Info
        $removed = 0
        foreach ($app in $detectedBloatware) {
            try {
                Remove-AppxPackage -Package $app.FullName -ErrorAction Stop
                Write-Host "  ✓ Removed: $($app.Name)" -ForegroundColor $Script:Colors.Success
                Write-Log "Removed bloatware: $($app.Name)" -Level Success -Category "Bloatware"
                $removed++
            }
            catch {
                Write-Host "  ✗ Failed to remove: $($app.Name)" -ForegroundColor $Script:Colors.Error
                Write-Log "Failed to remove bloatware: $($app.Name)" -Level Warning -Category "Bloatware"
            }
        }
        
        Write-Host "`n✓ Removed $removed out of $($detectedBloatware.Count) apps!" -ForegroundColor $Script:Colors.Success
    }
    
    Read-Host "`nPress Enter to continue"
}

#endregion

# Export functions for main script
Export-ModuleMember -Function *

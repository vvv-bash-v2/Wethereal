# Wethereal Ultimate Edition - Advanced Features Module
# Additional Professional Features for Complete Optimization

#region Advanced Performance Monitoring

function Global:Show-PerformanceDashboard {
    Write-Host "`n[REAL-TIME PERFORMANCE DASHBOARD]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Monitoring system performance... Press Ctrl+C to exit" -ForegroundColor $Script:Colors.Info
    Write-Host ""
    
    try {
        $counter = 0
        while ($counter -lt 30) {
            # Run for 30 seconds
            Clear-Host
            Write-Host "`n[REAL-TIME PERFORMANCE DASHBOARD]" -ForegroundColor $Script:Colors.Title
            Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
            
            # CPU Usage
            $cpu = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
            $cpuValue = [math]::Round($cpu.CounterSamples[0].CookedValue, 1)
            $cpuColor = if ($cpuValue -gt 80) { $Script:Colors.Error } elseif ($cpuValue -gt 50) { $Script:Colors.Warning } else { $Script:Colors.Success }
            Write-Host "  [PC] CPU Usage: $cpuValue%" -ForegroundColor $cpuColor
            
            # Memory Usage
            $mem = Get-CimInstance Win32_OperatingSystem
            $memUsed = [math]::Round((($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / $mem.TotalVisibleMemorySize) * 100, 1)
            $memColor = if ($memUsed -gt 90) { $Script:Colors.Error } elseif ($memUsed -gt 70) { $Script:Colors.Warning } else { $Script:Colors.Success }
            Write-Host "  [CPU] Memory Usage: $memUsed%" -ForegroundColor $memColor
            
            # Disk Usage
            $disk = Get-Volume | Where-Object { $_.DriveLetter -eq $env:SystemDrive.TrimEnd(':') }
            $diskUsed = [math]::Round((($disk.Size - $disk.SizeRemaining) / $disk.Size) * 100, 1)
            $diskColor = if ($diskUsed -gt 90) { $Script:Colors.Error } elseif ($diskUsed -gt 80) { $Script:Colors.Warning } else { $Script:Colors.Success }
            Write-Host "  [DISK] Disk Usage: $diskUsed%" -ForegroundColor $diskColor
            
            # Network Activity
            $net = Get-NetAdapterStatistics | Select-Object -First 1
            $netSent = [math]::Round($net.SentBytes / 1MB, 2)
            $netRecv = [math]::Round($net.ReceivedBytes / 1MB, 2)
            Write-Host "  [NET] Network: ^ $netSent MB | v $netRecv MB" -ForegroundColor $Script:Colors.Info
            
            # Process Count
            $procCount = (Get-Process).Count
            Write-Host "  [CFG]  Processes: $procCount" -ForegroundColor $Script:Colors.Info
            
            Write-Host "`n  Refreshing in 1 second... (Ctrl+C to exit)" -ForegroundColor DarkGray
            Start-Sleep -Seconds 1
            $counter++
        }
    }
    catch {
        Write-Host "`n  Monitoring stopped." -ForegroundColor $Script:Colors.Warning
    }
    
    Wait-ForUser
}

#endregion

#region Automatic Backup System

function Global:New-AutomaticBackup {
    Write-Host "`n[AUTOMATIC BACKUP]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    
    $backupDir = "$PSScriptRoot\Backups"
    if (-not (Test-Path $backupDir)) {
        New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupFile = "$backupDir\Wethereal_AutoBackup_$timestamp.json"
    
    Write-Host "  Creating automatic backup..." -ForegroundColor $Script:Colors.Info
    
    $backupData = @{
        Timestamp     = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Version       = $Script:Version
        SystemInfo    = Get-SystemInfo
        # Configuration carries the actual restorable registry/service entries -
        # this is what Invoke-QuickRestore replays. UndoStack scriptblocks cannot
        # survive a JSON round-trip, so they're intentionally not persisted here;
        # in-session undo uses $Script:UndoStack directly instead (see Undo-LastOptimization).
        Configuration = $Script:ConfigBackup
    }
    
    # Save backup
    $backupData | ConvertTo-Json -Depth 10 | Out-File -FilePath $backupFile -Encoding UTF8
    
    Write-Host "  [OK] Backup created: $backupFile" -ForegroundColor $Script:Colors.Success
    Write-Log "Automatic backup created: $backupFile" -Level Success -Category "Backup"
    
    return $backupFile
}

#endregion

#region One-Click Restore

function Global:Invoke-QuickRestore {
    Write-Host "`n[ONE-CLICK RESTORE]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    
    $backupDir = "$PSScriptRoot\Backups"
    if (-not (Test-Path $backupDir)) {
        Write-Host "  No backups found." -ForegroundColor $Script:Colors.Warning
        Wait-ForUser
        return
    }
    
    $backups = Get-ChildItem -Path $backupDir -Filter "*.json" | Sort-Object LastWriteTime -Descending
    
    if ($backups.Count -eq 0) {
        Write-Host "  No backup files available." -ForegroundColor $Script:Colors.Warning
        Wait-ForUser
        return
    }
    
    Write-Host "`n  Available Backups:" -ForegroundColor $Script:Colors.Info
    for ($i = 0; $i -lt [Math]::Min(10, $backups.Count); $i++) {
        $backup = $backups[$i]
        Write-Host "  $($i + 1). $($backup.Name) - $(Get-Date $backup.LastWriteTime -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor White
    }
    
    Write-Host ""
    $choice = Read-Host "Select backup to restore (1-$([Math]::Min(10, $backups.Count))) or 0 to cancel"
    
    if ($choice -eq '0' -or $choice -eq '') { return }
    
    $index = [int]$choice - 1
    if ($index -ge 0 -and $index -lt $backups.Count) {
        $selectedBackup = $backups[$index]
        
        if (Confirm-Action -Message "Restore from backup: $($selectedBackup.Name)?") {
            try {
                $backupData = Get-Content -Path $selectedBackup.FullName -Raw | ConvertFrom-Json
                $entries = @($backupData.Configuration)

                Write-Log "Restoring from backup: $($selectedBackup.Name)" -Level Info -Category "Restore"
                Invoke-BackupRestore -Entries $entries

                Write-Host "`n[OK] Backup restored successfully!" -ForegroundColor $Script:Colors.Success
                Write-Log "Restored from backup: $($selectedBackup.Name)" -Level Success -Category "Restore"
            }
            catch {
                Write-Host "  [X] Failed to restore backup: $($_.Exception.Message)" -ForegroundColor $Script:Colors.Error
                Write-Log "Failed to restore backup: $($_.Exception.Message)" -Level Error -Category "Restore"
            }
        }
    }
    
    Wait-ForUser
}

#endregion

#region Startup Impact Analyzer

function Global:Show-StartupImpact {
    Write-Host "`n[STARTUP IMPACT ANALYZER]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Analyzing startup programs..." -ForegroundColor $Script:Colors.Info
    Write-Host ""
    
    # Get startup programs from multiple locations
    $startupItems = @()
    
    # Registry Run keys
    $runKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
    )
    
    foreach ($key in $runKeys) {
        if (Test-Path $key) {
            $items = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
            if ($items) {
                $items.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } | ForEach-Object {
                    $startupItems += [PSCustomObject]@{
                        Name     = $_.Name
                        Command  = $_.Value
                        Location = $key
                        Impact   = "Medium"
                    }
                }
            }
        }
    }
    
    # Startup folder
    $startupFolders = @(
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
    )
    
    foreach ($folder in $startupFolders) {
        if (Test-Path $folder) {
            Get-ChildItem -Path $folder -ErrorAction SilentlyContinue | ForEach-Object {
                $startupItems += [PSCustomObject]@{
                    Name     = $_.Name
                    Command  = $_.FullName
                    Location = $folder
                    Impact   = "Low"
                }
            }
        }
    }
    
    # Task Scheduler
    try {
        $tasks = Get-ScheduledTask | Where-Object { $_.State -eq 'Ready' -and $_.Triggers.Count -gt 0 }
        foreach ($task in $tasks | Select-Object -First 20) {
            if ($task.Triggers | Where-Object { $_.CimClass.CimClassName -like '*LogonTrigger*' }) {
                $startupItems += [PSCustomObject]@{
                    Name     = $task.TaskName
                    Command  = "Scheduled Task"
                    Location = "Task Scheduler"
                    Impact   = "High"
                }
            }
        }
    }
    catch {
        # Silently continue if Task Scheduler access fails
    }
    
    # Display results
    Write-Host "  Found $($startupItems.Count) startup items:" -ForegroundColor $Script:Colors.Highlight
    Write-Host ""
    
    $highImpact = $startupItems | Where-Object { $_.Impact -eq "High" }
    $mediumImpact = $startupItems | Where-Object { $_.Impact -eq "Medium" }
    $lowImpact = $startupItems | Where-Object { $_.Impact -eq "Low" }
    
    if ($highImpact.Count -gt 0) {
        Write-Host "  HIGH IMPACT ($($highImpact.Count) items):" -ForegroundColor Red
        $highImpact | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor Yellow }
        Write-Host ""
    }
    
    if ($mediumImpact.Count -gt 0) {
        Write-Host "  MEDIUM IMPACT ($($mediumImpact.Count) items):" -ForegroundColor Yellow
        $mediumImpact | Select-Object -First 10 | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor White }
        Write-Host ""
    }
    
    if ($lowImpact.Count -gt 0) {
        Write-Host "  LOW IMPACT ($($lowImpact.Count) items):" -ForegroundColor Green
        Write-Host "    (Startup folder shortcuts)" -ForegroundColor DarkGray
        Write-Host ""
    }
    
    # Recommendations
    Write-Host "  RECOMMENDATIONS:" -ForegroundColor $Script:Colors.Info
    if ($startupItems.Count -gt 15) {
        Write-Host "    [!] High number of startup items detected!" -ForegroundColor $Script:Colors.Warning
        Write-Host "    -> Consider disabling unnecessary programs" -ForegroundColor Cyan
        Write-Host "    -> Use Task Manager > Startup tab to manage" -ForegroundColor Cyan
    }
    else {
        Write-Host "    [OK] Startup item count is reasonable" -ForegroundColor $Script:Colors.Success
    }
    
    Write-Log "Startup impact analysis completed. Found $($startupItems.Count) items." -Level Info -Category "Analysis"
    
    Wait-ForUser
}

#endregion

#region Network Speed Test

function Global:Test-NetworkSpeed {
    Write-Host "`n[NETWORK SPEED TEST]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Testing network connectivity and speed..." -ForegroundColor $Script:Colors.Info
    Write-Host ""
    
    # Test DNS Resolution
    # NOTE: $dnsSuccess must be set OUTSIDE the Measure-Command scriptblock - a
    # scriptblock invoked via Measure-Command runs in its own child scope, so a
    # variable assigned inside it never becomes visible here (this previously made
    # the DNS check report "Failed" every time regardless of the real result).
    Write-Host "  Testing DNS resolution..." -ForegroundColor $Script:Colors.Info
    $dnsSuccess = $false
    try {
        $dnsTest = Measure-Command {
            [System.Net.Dns]::GetHostAddresses("www.google.com") | Out-Null
        }
        $dnsSuccess = $true
    }
    catch {
        $dnsTest = [TimeSpan]::Zero
    }

    if ($dnsSuccess) {
        Write-Host "  [OK] DNS Resolution: $([math]::Round($dnsTest.TotalMilliseconds, 0)) ms" -ForegroundColor $Script:Colors.Success
    }
    else {
        Write-Host "  [X] DNS Resolution: Failed" -ForegroundColor $Script:Colors.Error
    }
    
    # Ping Test
    Write-Host "  Testing latency (ping)..." -ForegroundColor $Script:Colors.Info
    try {
        $ping = Test-Connection -ComputerName "8.8.8.8" -Count 4 -ErrorAction Stop
        $avgPing = [math]::Round(($ping | Measure-Object -Property ResponseTime -Average).Average, 0)
        $pingColor = if ($avgPing -lt 50) { $Script:Colors.Success } elseif ($avgPing -lt 100) { $Script:Colors.Warning } else { $Script:Colors.Error }
        Write-Host "  [OK] Average Ping: $avgPing ms" -ForegroundColor $pingColor
    }
    catch {
        Write-Host "  [X] Ping Test: Failed" -ForegroundColor $Script:Colors.Error
    }
    
    # Download Speed Test (simplified)
    Write-Host "  Testing download speed..." -ForegroundColor $Script:Colors.Info
    try {
        $url = "http://speedtest.ftp.otenet.gr/files/test1Mb.db"
        $downloadTest = Measure-Command {
            Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop | Out-Null
        }
        $speedMbps = [math]::Round((1 / $downloadTest.TotalSeconds) * 8, 2)
        Write-Host "  [OK] Estimated Speed: ~$speedMbps Mbps" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Host "  [!] Download test unavailable" -ForegroundColor $Script:Colors.Warning
    }
    
    # Network Adapter Info
    Write-Host "`n  Active Network Adapters:" -ForegroundColor $Script:Colors.Info
    Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
        Write-Host "    - $($_.Name): $($_.LinkSpeed)" -ForegroundColor White
    }
    
    Write-Log "Network speed test completed" -Level Info -Category "Network"
    
    Wait-ForUser
}

#endregion

#region Temperature Monitoring

function Global:Show-SystemTemperature {
    Write-Host "`n[SYSTEM TEMPERATURE MONITOR]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Attempting to read system temperatures..." -ForegroundColor $Script:Colors.Info
    Write-Host ""
    
    try {
        # Try to get temperature from WMI (may not work on all systems)
        $temps = Get-CimInstance -Namespace "root/wmi" -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
        
        if ($temps) {
            Write-Host "  Thermal Zones:" -ForegroundColor $Script:Colors.Highlight
            foreach ($temp in $temps) {
                $celsius = [math]::Round(($temp.CurrentTemperature / 10) - 273.15, 1)
                $tempColor = if ($celsius -gt 80) { $Script:Colors.Error } elseif ($celsius -gt 60) { $Script:Colors.Warning } else { $Script:Colors.Success }
                Write-Host "    - Zone $($temp.InstanceName): $celsius degC" -ForegroundColor $tempColor
            }
        }
        else {
            Write-Host "  [!] Temperature sensors not accessible via WMI" -ForegroundColor $Script:Colors.Warning
            Write-Host "  Note: Temperature monitoring requires specific hardware support" -ForegroundColor DarkGray
            Write-Host "  Consider using dedicated tools like HWMonitor or Core Temp" -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Host "  [!] Unable to read temperature data" -ForegroundColor $Script:Colors.Warning
        Write-Host "  This feature may not be supported on your system" -ForegroundColor DarkGray
    }
    
    # Show CPU usage as alternative metric
    Write-Host "`n  CPU Load (alternative metric):" -ForegroundColor $Script:Colors.Info
    $cpu = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
    if ($cpu) {
        $cpuValue = [math]::Round($cpu.CounterSamples[0].CookedValue, 1)
        $cpuColor = if ($cpuValue -gt 80) { $Script:Colors.Error } elseif ($cpuValue -gt 50) { $Script:Colors.Warning } else { $Script:Colors.Success }
        Write-Host "    - Current CPU Usage: $cpuValue%" -ForegroundColor $cpuColor
    }

    Wait-ForUser
}

function Global:Get-ThermalThrottleStatus {
    <#
        Fast, no-console-output heuristic for "is the CPU throttling right now" -
        used both by the interactive Test-ThermalThrottling menu item and by the
        HTML optimization report, so the report doesn't pay for a slow scan every
        time it's generated. Compares the CPU's currently reported clock speed
        against its rated maximum while it's under meaningful load; a large gap
        under load is the classic thermal-throttling signature. WMI's reported
        clock speed is a known-imperfect signal on modern turbo-boosting CPUs, so
        this is a heads-up, not a certified diagnosis - Test-ThermalThrottling
        offers the definitive powercfg /energy scan for that.
    #>
    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop | Select-Object -First 1
        $load = (Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue).CounterSamples[0].CookedValue
        $ratio = if ($cpu.MaxClockSpeed -gt 0) { $cpu.CurrentClockSpeed / $cpu.MaxClockSpeed } else { 1 }
        $likelyThrottling = ($load -gt 50 -and $ratio -lt 0.7)
        return @{
            Detected    = $likelyThrottling
            CurrentMHz  = $cpu.CurrentClockSpeed
            MaxMHz      = $cpu.MaxClockSpeed
            LoadPercent = [math]::Round($load, 1)
            Detail      = if ($likelyThrottling) {
                "Running at $($cpu.CurrentClockSpeed) MHz ($([math]::Round($ratio * 100))% of rated $($cpu.MaxClockSpeed) MHz) under $([math]::Round($load,0))% load - possible thermal throttling."
            }
            else {
                "Clock speed tracking normally relative to rated $($cpu.MaxClockSpeed) MHz."
            }
        }
    }
    catch {
        return @{ Detected = $false; Detail = "Could not read CPU clock/load counters." }
    }
}

function Global:Test-ThermalThrottling {
    Write-Host "`n[THERMAL THROTTLING DETECTOR]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Quick check first, using live CPU clock speed vs its rated maximum." -ForegroundColor $Script:Colors.Info

    $status = Get-ThermalThrottleStatus
    $color = if ($status.Detected) { $Script:Colors.Warning } else { $Script:Colors.Success }
    Write-Host "`n  $($status.Detail)" -ForegroundColor $color

    $runDeep = Read-Host "`nRun a definitive 20-second powercfg thermal/energy scan? (y/N)"
    if ($runDeep -eq 'Y' -or $runDeep -eq 'y') {
        Write-Host "`nScanning for 20 seconds - let the system idle or run your game now..." -ForegroundColor $Script:Colors.Info
        $reportPath = "$PSScriptRoot\ThermalEnergyReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
        try {
            powercfg /energy /output $reportPath /duration 20 2>&1 | Out-Null
            if (Test-Path $reportPath) {
                $reportContent = Get-Content -Path $reportPath -Raw -ErrorAction SilentlyContinue
                $thermalHits = [regex]::Matches($reportContent, '(?i)(thermal|throttl)[^<]{0,120}')
                if ($thermalHits.Count -gt 0) {
                    Write-Host "`n  [!] Thermal-related entries found in the energy report:" -ForegroundColor $Script:Colors.Warning
                    $thermalHits | Select-Object -First 5 -Unique | ForEach-Object { Write-Host "    - $($_.Value.Trim())" -ForegroundColor $Script:Colors.Warning }
                }
                else {
                    Write-Host "`n  [OK] No thermal throttling entries found in the energy report." -ForegroundColor $Script:Colors.Success
                }
                Write-Host "  Full report: $reportPath" -ForegroundColor DarkGray
                Write-Log "Thermal energy scan completed: $reportPath" -Level Info -Category "Monitoring"
            }
        }
        catch {
            Write-Host "`n  [!] powercfg /energy scan failed or requires elevation." -ForegroundColor $Script:Colors.Warning
        }
    }

    Wait-ForUser
}

function Global:Get-MemorySpeedStatus {
    <#
        Compares each RAM module's actual running speed (ConfiguredClockSpeed)
        against its rated/max supported speed (Speed, from SPD) to catch RAM
        quietly running at JEDEC default instead of its rated XMP/DOCP speed -
        a common, invisible performance loss (e.g. 2133 MT/s instead of a rated
        3200 MT/s) that most people never notice because nothing looks "wrong".
        ConfiguredClockSpeed isn't available on very old Windows builds; falls
        back to reporting Speed alone in that case.
    #>
    try {
        $modules = @(Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction Stop)
        if ($modules.Count -eq 0) { return @{ Detected = $false; Detail = "No memory module data available." } }

        $underclocked = $modules | Where-Object {
            $_.ConfiguredClockSpeed -and $_.Speed -and $_.ConfiguredClockSpeed -lt ($_.Speed * 0.9)
        }
        $ratedSpeed = ($modules | Measure-Object -Property Speed -Maximum).Maximum
        $runningSpeed = if ($modules[0].ConfiguredClockSpeed) { ($modules | Measure-Object -Property ConfiguredClockSpeed -Maximum).Maximum } else { $ratedSpeed }

        return @{
            Detected     = [bool]($underclocked.Count -gt 0)
            RatedMHz     = $ratedSpeed
            RunningMHz   = $runningSpeed
            ModuleCount  = $modules.Count
            Detail       = if ($underclocked.Count -gt 0) {
                "RAM running at $runningSpeed MT/s but rated for $ratedSpeed MT/s - enable XMP/DOCP/EXPO in the BIOS to reach full speed."
            }
            else {
                "RAM running at its rated speed ($runningSpeed MT/s across $($modules.Count) module(s))."
            }
        }
    }
    catch {
        return @{ Detected = $false; Detail = "Could not read memory module speed data." }
    }
}

function Global:Test-MemorySpeed {
    Write-Host "`n[MEMORY SPEED CHECK]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    $status = Get-MemorySpeedStatus
    $color = if ($status.Detected) { $Script:Colors.Warning } else { $Script:Colors.Success }
    Write-Host "`n  $($status.Detail)" -ForegroundColor $color
    if ($status.Detected) {
        Write-Host "  Note: this requires a BIOS/UEFI setting change (XMP/DOCP/EXPO profile) -" -ForegroundColor DarkGray
        Write-Host "  Wethereal cannot change BIOS settings from within Windows." -ForegroundColor DarkGray
    }

    $runDiag = Read-Host "`nSchedule a Windows Memory Diagnostic (restarts to test RAM for errors)? (y/N)"
    if ($runDiag -eq 'Y' -or $runDiag -eq 'y') {
        Write-Log "Scheduling Windows Memory Diagnostic" -Level Info -Category "Monitoring"
        Start-Process "mdsched.exe"
        Write-Host "`n  Memory Diagnostic scheduler launched - follow its prompts to restart and test." -ForegroundColor $Script:Colors.Success
    }

    Wait-ForUser
}

#endregion

#region Enhanced Error Handling

function Global:Initialize-ErrorHandling {
    # Set up global error handling
    $ErrorActionPreference = "Continue"
    
    # Create error log
    $Script:ErrorLog = "$PSScriptRoot\Errors.log"
    
    # Register error handler
    trap {
        $errorMessage = "ERROR: $($_.Exception.Message) at line $($_.InvocationInfo.ScriptLineNumber)"
        Write-Host "`n  $errorMessage" -ForegroundColor $Script:Colors.Error
        Add-Content -Path $Script:ErrorLog -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $errorMessage"
        Write-Log $errorMessage -Level Error -Category "System"
        continue
    }
}

#endregion


# Wethereal Ultimate Edition - System Automation Module
# Self-update from GitHub, before/after benchmark comparison, pagefile
# manager, and scheduled auto-reapply of a profile.

$Script:UpdateRepoOwner = "vvv-bash-v2"
$Script:UpdateRepoName = "Wethereal"

#region Category 11: Automation & Updates

function Global:Show-AutomationMenu {
    do {
        Show-Header "Automation & Updates"
        Write-Host "  AUTOMATION & UPDATES" -ForegroundColor $Script:Colors.Menu
        Write-Host "  =======================================================================" -ForegroundColor $Script:Colors.Menu
        Write-Host "   1. ^  Check for Wethereal Updates" -ForegroundColor White
        Write-Host "   2. [UP] Before/After Benchmark (apply a profile, measure the gain)" -ForegroundColor White
        Write-Host "   3. [DISK] Virtual Memory / Pagefile Manager" -ForegroundColor White
        Write-Host "   4. [TIMER] Schedule Automatic Profile Re-Apply" -ForegroundColor White
        Write-Host "   5. [SYNC] Windows Update Auto-Pause While Gaming" -ForegroundColor White
        Write-Host "   0. <- Back to Main Menu" -ForegroundColor Yellow
        Write-Host ""

        $choice = Read-Host "Select an option"

        switch ($choice) {
            '1' { Update-Wethereal }
            '2' { Invoke-BeforeAfterBenchmark }
            '3' { Optimize-PageFile }
            '4' { Set-ScheduledProfileReapply }
            '5' { Set-GameAwareUpdatePause }
            '0' { return }
            default {
                Write-Host "`n[X] Invalid option." -ForegroundColor $Script:Colors.Error
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

#endregion

#region Self-Update from GitHub

function Global:Update-Wethereal {
    Write-Host "`n[CHECK FOR WETHEREAL UPDATES]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Checking $Script:UpdateRepoOwner/$Script:UpdateRepoName on GitHub..." -ForegroundColor $Script:Colors.Info

    try {
        $rawUrl = "https://raw.githubusercontent.com/$Script:UpdateRepoOwner/$Script:UpdateRepoName/main/Win-Tweaker.ps1"
        $remoteContent = (Invoke-WebRequest -Uri $rawUrl -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop).Content
    }
    catch {
        Write-Host "`n[X] Could not reach GitHub: $($_.Exception.Message)" -ForegroundColor $Script:Colors.Error
        Write-Log "Update check failed: $($_.Exception.Message)" -Level Warning -Category "Update"
        Wait-ForUser
        return
    }

    if ($remoteContent -notmatch '\$Script:Version\s*=\s*"([\d.]+)"') {
        Write-Host "`n[X] Could not determine the remote version." -ForegroundColor $Script:Colors.Error
        Wait-ForUser
        return
    }
    $remoteVersion = $matches[1]

    Write-Host "  Installed version: $($Script:Version)" -ForegroundColor White
    Write-Host "  Latest on GitHub:  $remoteVersion" -ForegroundColor White

    if ([version]$remoteVersion -le [version]$Script:Version) {
        Write-Host "`n[OK] You're already on the latest version!" -ForegroundColor $Script:Colors.Success
        Wait-ForUser
        return
    }

    Write-Host "`n  [DONE] A newer version is available: v$remoteVersion" -ForegroundColor $Script:Colors.Highlight
    if (-not (Confirm-Action -Message "Download and install it now? (current files are backed up first)")) { return }

    Write-Log "Updating Wethereal from v$($Script:Version) to v$remoteVersion" -Level Info -Category "Update"

    $steps = @(
        @{
            Name   = "Backing up current script files"
            Action = {
                $backupDir = "$PSScriptRoot\Backups\PreUpdate_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
                Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1" | Copy-Item -Destination $backupDir -Force
                $Script:_updateBackupDir = $backupDir
            }
        }
        @{
            Name   = "Fetching the list of script files from the repository"
            Action = {
                $apiUrl = "https://api.github.com/repos/$Script:UpdateRepoOwner/$Script:UpdateRepoName/contents/"
                $headers = @{ "User-Agent" = "Wethereal-Updater" }
                $contents = Invoke-RestMethod -Uri $apiUrl -Headers $headers -TimeoutSec 15 -ErrorAction Stop
                $Script:_updateFiles = $contents | Where-Object { $_.type -eq 'file' -and $_.name -like '*.ps1' }
                if (-not $Script:_updateFiles -or $Script:_updateFiles.Count -eq 0) {
                    throw "No .ps1 files found in the repository listing"
                }
            }
        }
        @{
            Name   = "Downloading and replacing script files"
            Action = {
                foreach ($file in $Script:_updateFiles) {
                    $dest = Join-Path $PSScriptRoot $file.name
                    Invoke-WebRequest -Uri $file.download_url -OutFile $dest -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
                }
            }
        }
    )

    Invoke-TweakSequence -Title "Wethereal Self-Update" -Steps $steps -Category "Update" | Out-Null

    Write-Host "`n[OK] Updated to v$remoteVersion!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Backup of the previous version: $Script:_updateBackupDir" -ForegroundColor $Script:Colors.Info
    Write-Host "  Restart Wethereal to run the new version." -ForegroundColor $Script:Colors.Warning
    Write-Log "Wethereal updated to v$remoteVersion" -Level Success -Category "Update"

    if (Confirm-Action -Message "Exit now so you can restart with the new version?" -DefaultYes) {
        exit 0
    }

    Wait-ForUser
}

#endregion

#region Before/After Benchmark

function Global:Invoke-BeforeAfterBenchmark {
    Write-Host "`n[BEFORE/AFTER BENCHMARK]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Runs a quick benchmark, applies a profile of your choice, then benchmarks" -ForegroundColor $Script:Colors.Info
    Write-Host "again - so you see the real before/after difference, not just a promise." -ForegroundColor $Script:Colors.Info
    Write-Host ""

    $profileNames = @($Script:Profiles.Keys)
    for ($i = 0; $i -lt $profileNames.Count; $i++) {
        Write-Host ("  {0}. {1}" -f ($i + 1), $Script:Profiles[$profileNames[$i]].Name) -ForegroundColor White
    }
    Write-Host "  0. Cancel" -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "Which profile do you want to measure?"
    $idx = 0
    if ($choice -eq '0' -or [string]::IsNullOrWhiteSpace($choice)) { return }
    if (-not [int]::TryParse($choice, [ref]$idx) -or $idx -lt 1 -or $idx -gt $profileNames.Count) {
        Write-Host "`n[X] Invalid selection." -ForegroundColor $Script:Colors.Error
        Start-Sleep -Seconds 1
        return
    }
    $selectedProfile = $profileNames[$idx - 1]

    if (-not (Confirm-Action -Message "Benchmark, apply '$($Script:Profiles[$selectedProfile].Name)', then benchmark again?" -DefaultYes)) { return }

    Write-Log "Starting before/after benchmark for profile $selectedProfile" -Level Info -Category "Benchmark"

    function Measure-QuickBenchmark {
        $cpuStart = Get-Date
        1..1500000 | ForEach-Object { $_ * 2 } | Out-Null
        $cpuMs = ((Get-Date) - $cpuStart).TotalMilliseconds

        $mem = Get-CimInstance Win32_OperatingSystem
        $memFreeMB = [math]::Round($mem.FreePhysicalMemory / 1KB, 0)

        return @{ CpuMs = $cpuMs; MemFreeMB = $memFreeMB }
    }

    Write-Host "`n  Running BEFORE benchmark..." -ForegroundColor $Script:Colors.Info
    $before = Measure-QuickBenchmark
    Write-Host "  [OK] CPU: $([math]::Round($before.CpuMs,1)) ms | Free RAM: $($before.MemFreeMB) MB" -ForegroundColor $Script:Colors.Success

    # Suppress the profile's own confirmation/pauses/restart-prompt - we already
    # confirmed once above, and a mid-flow restart prompt would abort this benchmark.
    $Script:SkipConfirmations = $true
    $Script:SkipPauses = $true
    try {
        Invoke-OptimizationProfile -ProfileName $selectedProfile
    }
    finally {
        $Script:SkipConfirmations = $false
        $Script:SkipPauses = $false
    }

    Write-Host "`n  Running AFTER benchmark..." -ForegroundColor $Script:Colors.Info
    $after = Measure-QuickBenchmark
    Write-Host "  [OK] CPU: $([math]::Round($after.CpuMs,1)) ms | Free RAM: $($after.MemFreeMB) MB" -ForegroundColor $Script:Colors.Success

    $cpuChangePct = if ($before.CpuMs -gt 0) { (($before.CpuMs - $after.CpuMs) / $before.CpuMs) * 100 } else { 0 }
    $memChangeMB = $after.MemFreeMB - $before.MemFreeMB

    Write-Host "`n  ====================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "  RESULTS" -ForegroundColor $Script:Colors.Highlight
    Write-Host "  CPU synthetic-load time: $(if ($cpuChangePct -ge 0) { '-' } else { '+' })$([math]::Abs([math]::Round($cpuChangePct, 1)))% $(if ($cpuChangePct -ge 0) { '(faster)' } else { '(slower)' })" -ForegroundColor $(if ($cpuChangePct -ge 0) { $Script:Colors.Success } else { $Script:Colors.Warning })
    Write-Host "  Free RAM: $(if ($memChangeMB -ge 0) { '+' })$memChangeMB MB" -ForegroundColor $(if ($memChangeMB -ge 0) { $Script:Colors.Success } else { $Script:Colors.Warning })
    Write-Host "  ====================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "  Note: this is a rough CPU/RAM signal, not an FPS benchmark - most of what" -ForegroundColor DarkGray
    Write-Host "  a profile changes (services, network, visual effects) won't show up in a" -ForegroundColor DarkGray
    Write-Host "  30-second synthetic test. Real games are the real measure." -ForegroundColor DarkGray

    Write-Log "Before/after benchmark for $selectedProfile : CPU $([math]::Round($cpuChangePct,1))%, RAM change ${memChangeMB}MB" -Level Success -Category "Benchmark"
    Wait-ForUser
}

#endregion

#region Pagefile Manager

function Global:Optimize-PageFile {
    Write-Host "`n[VIRTUAL MEMORY / PAGEFILE MANAGER]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    $cs = Get-CimInstance Win32_ComputerSystem
    $ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
    $autoManaged = $cs.AutomaticManagedPagefile

    Write-Host "  Physical RAM detected: $ramGB GB" -ForegroundColor White
    Write-Host "  Currently: $(if ($autoManaged) { 'System-managed' } else { 'Manually configured' })" -ForegroundColor White

    $recommendation = if ($ramGB -ge 16) {
        "System-managed is fine - you have plenty of RAM, the pagefile is rarely touched."
    }
    elseif ($ramGB -ge 8) {
        "System-managed is fine, or a fixed size around $([math]::Round($ramGB * 1.5, 0)) GB for consistency."
    }
    else {
        "A fixed pagefile around $([math]::Round($ramGB * 1.5, 0))-$([math]::Round($ramGB * 2, 0)) GB is recommended - low RAM systems lean on the pagefile more."
    }
    Write-Host "  Recommendation: $recommendation" -ForegroundColor $Script:Colors.Info
    Write-Host ""
    Write-Host "  1. Set to System-managed (recommended default)" -ForegroundColor White
    Write-Host "  2. Set a custom fixed size" -ForegroundColor White
    Write-Host "  3. Disable pagefile entirely (advanced - NOT recommended)" -ForegroundColor Yellow
    Write-Host "  0. Cancel" -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "Select an option"
    if ($choice -eq '0' -or [string]::IsNullOrWhiteSpace($choice)) { return }

    switch ($choice) {
        '1' {
            if (-not (Confirm-Action -Message "Set pagefile to system-managed?" -DefaultYes)) { return }
            $steps = @(
                @{
                    Name   = "Enabling automatic pagefile management"
                    Action = {
                        $cs = Get-CimInstance Win32_ComputerSystem
                        $cs | Set-CimInstance -Property @{ AutomaticManagedPagefile = $true } -ErrorAction Stop
                    }
                }
            )
            Invoke-TweakSequence -Title "Pagefile Manager" -Steps $steps -Category "Memory" | Out-Null
        }
        '2' {
            $sizeInput = Read-Host "Fixed pagefile size in MB (e.g. $([math]::Round($ramGB * 1.5 * 1024, 0)) for ~$([math]::Round($ramGB * 1.5,1))GB)"
            $sizeMB = 0
            if (-not [int]::TryParse($sizeInput, [ref]$sizeMB) -or $sizeMB -lt 512) {
                Write-Host "`n[X] Invalid size (minimum 512 MB)." -ForegroundColor $Script:Colors.Error
                Wait-ForUser
                return
            }
            if (-not (Confirm-Action -Message "Set a fixed $sizeMB MB pagefile on $env:SystemDrive ?")) { return }

            $steps = @(
                @{
                    Name   = "Disabling automatic pagefile management"
                    Action = {
                        (Get-CimInstance Win32_ComputerSystem) | Set-CimInstance -Property @{ AutomaticManagedPagefile = $false } -ErrorAction Stop
                    }
                }
                @{
                    Name   = "Setting fixed pagefile size to $sizeMB MB"
                    Action = {
                        $existing = Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "$($env:SystemDrive)*" }
                        if ($existing) {
                            $existing | Set-CimInstance -Property @{ InitialSize = $sizeMB; MaximumSize = $sizeMB } -ErrorAction Stop
                        }
                        else {
                            $newPageFile = "$env:SystemDrive\pagefile.sys"
                            Invoke-CimMethod -ClassName Win32_PageFileSetting -MethodName Create -Arguments @{ Name = $newPageFile; InitialSize = $sizeMB; MaximumSize = $sizeMB } -ErrorAction Stop | Out-Null
                        }
                    }.GetNewClosure()
                }
            )
            Invoke-TweakSequence -Title "Pagefile Manager" -Steps $steps -Category "Memory" | Out-Null
        }
        '3' {
            Write-Host "`n[!]  Disabling the pagefile can cause crashes in memory-heavy games/apps" -ForegroundColor $Script:Colors.Warning
            Write-Host "   and prevents Windows from creating crash dumps. Only do this with a lot" -ForegroundColor $Script:Colors.Warning
            Write-Host "   of RAM (32GB+) and a good reason." -ForegroundColor $Script:Colors.Warning
            if (-not (Confirm-Action -Message "Are you SURE you want to disable the pagefile?")) { return }

            $steps = @(
                @{
                    Name   = "Disabling automatic pagefile management"
                    Action = { (Get-CimInstance Win32_ComputerSystem) | Set-CimInstance -Property @{ AutomaticManagedPagefile = $false } -ErrorAction Stop }
                }
                @{
                    Name   = "Removing all pagefile settings"
                    Action = {
                        $existing = Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue
                        foreach ($pf in $existing) { $pf | Remove-CimInstance -ErrorAction Stop }
                    }
                }
            )
            Invoke-TweakSequence -Title "Pagefile Manager" -Steps $steps -Category "Memory" | Out-Null
        }
        default {
            Write-Host "`n[X] Invalid selection." -ForegroundColor $Script:Colors.Error
            Start-Sleep -Seconds 1
            return
        }
    }

    Write-Host "`n[OK] Pagefile settings updated!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Restart required for changes to take effect." -ForegroundColor $Script:Colors.Warning
    Wait-ForUser
}

#endregion

#region Scheduled Profile Re-Apply

function Global:Set-ScheduledProfileReapply {
    Write-Host "`n[SCHEDULE AUTOMATIC PROFILE RE-APPLY]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Creates a Windows scheduled task that silently re-runs a profile - useful" -ForegroundColor $Script:Colors.Info
    Write-Host "because Windows Update sometimes resets services, telemetry or scheduled" -ForegroundColor $Script:Colors.Info
    Write-Host "tasks Wethereal disabled." -ForegroundColor $Script:Colors.Info
    Write-Host ""
    Write-Host "  1. Re-apply at every logon" -ForegroundColor White
    Write-Host "  2. Re-apply weekly" -ForegroundColor White
    Write-Host "  3. Re-apply after Windows Update installs updates (event-triggered)" -ForegroundColor White
    Write-Host "  4. Remove the scheduled re-apply task" -ForegroundColor White
    Write-Host "  0. Cancel" -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "Select an option"
    if ($choice -eq '0' -or [string]::IsNullOrWhiteSpace($choice)) { return }

    $taskName = "Wethereal Auto Re-Apply"

    if ($choice -eq '4') {
        if (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
            Write-Host "`n[!] No scheduled re-apply task found." -ForegroundColor $Script:Colors.Warning
            Wait-ForUser
            return
        }
        if (-not (Confirm-Action -Message "Remove the scheduled re-apply task?")) { return }
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "`n[OK] Scheduled task removed." -ForegroundColor $Script:Colors.Success
        Write-Log "Removed scheduled profile re-apply task" -Level Success -Category "Automation"
        Wait-ForUser
        return
    }

    if ($choice -notin @('1', '2', '3')) {
        Write-Host "`n[X] Invalid selection." -ForegroundColor $Script:Colors.Error
        Start-Sleep -Seconds 1
        return
    }

    $profileNames = @($Script:Profiles.Keys)
    for ($i = 0; $i -lt $profileNames.Count; $i++) {
        Write-Host ("  {0}. {1}" -f ($i + 1), $Script:Profiles[$profileNames[$i]].Name) -ForegroundColor White
    }
    $profChoice = Read-Host "Which profile should it re-apply?"
    $pIdx = 0
    if (-not [int]::TryParse($profChoice, [ref]$pIdx) -or $pIdx -lt 1 -or $pIdx -gt $profileNames.Count) {
        Write-Host "`n[X] Invalid selection." -ForegroundColor $Script:Colors.Error
        Wait-ForUser
        return
    }
    $selectedProfile = $profileNames[$pIdx - 1]

    if (-not (Confirm-Action -Message "Schedule '$($Script:Profiles[$selectedProfile].Name)' to auto re-apply?" -DefaultYes)) { return }

    Write-Log "Scheduling profile re-apply: $selectedProfile (mode $choice)" -Level Info -Category "Automation"

    try {
        $scriptPath = Join-Path $PSScriptRoot "Win-Tweaker.ps1"
        $action = New-ScheduledTaskAction -Execute "powershell.exe" `
            -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Silent -ProfileName $selectedProfile"
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

        switch ($choice) {
            '1' {
                $trigger = New-ScheduledTaskTrigger -AtLogOn
                Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
            }
            '2' {
                $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 9am
                Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
            }
            '3' {
                # Event-triggered task: fires when Windows Update logs a successful
                # installation (Event ID 19 in the WindowsUpdateClient operational log).
                $triggerClass = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler
                $trigger = New-CimInstance -CimClass $triggerClass -ClientOnly
                $trigger.Subscription = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''Microsoft-Windows-WindowsUpdateClient''] and (EventID=19)]]</Select></Query></QueryList>'
                $trigger.Enabled = $true
                Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
            }
        }

        Write-Host "`n[OK] Scheduled task '$taskName' created!" -ForegroundColor $Script:Colors.Success
        Write-Log "Created scheduled profile re-apply task ($choice) for $selectedProfile" -Level Success -Category "Automation"
    }
    catch {
        Write-Host "`n[X] Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor $Script:Colors.Error
        if ($choice -eq '3') {
            Write-Host "  Event-triggered tasks can be finicky depending on Windows edition/policy -" -ForegroundColor DarkGray
            Write-Host "  try option 2 (weekly) instead if this keeps failing." -ForegroundColor DarkGray
        }
        Write-Log "Failed to create scheduled task: $($_.Exception.Message)" -Level Error -Category "Automation"
    }

    Wait-ForUser
}

function Global:Set-GameAwareUpdatePause {
    <#
        Smarter alternative to the Presentation profile's fixed 7-day Windows
        Update pause: writes a small standalone watcher script to disk and
        schedules it every 5 minutes. The watcher checks whether any process is
        running from a detected game library folder (Get-DetectedGameFolders);
        if so it stops and disables the wuauserv service (Windows Update can't
        start a background install/reboot-nag mid-session), and drops it back to
        Manual/started again the moment no monitored game is still running. A
        marker file tracks whether Wethereal is the one holding it paused, so it
        never touches wuauserv if the user paused it themselves for another reason.
    #>
    Write-Host "`n[WINDOWS UPDATE AUTO-PAUSE WHILE GAMING]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Automatically pauses Windows Update the moment a detected game starts, and" -ForegroundColor $Script:Colors.Info
    Write-Host "resumes it a few minutes after you close it - no fixed pause window needed." -ForegroundColor $Script:Colors.Info
    Write-Host ""
    Write-Host "  1. Enable" -ForegroundColor White
    Write-Host "  2. Disable and remove" -ForegroundColor White
    Write-Host "  0. Cancel" -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "Select an option"
    if ($choice -eq '0' -or [string]::IsNullOrWhiteSpace($choice)) { return }

    $taskName = "Wethereal Game-Aware Update Pause"
    $watcherPath = "$PSScriptRoot\Wethereal-GameUpdatePauseWatcher.ps1"
    $markerPath = "$PSScriptRoot\Wethereal-UpdatePausedByGame.marker"

    if ($choice -eq '2') {
        if (-not (Confirm-Action -Message "Remove Windows Update auto-pause and restore Windows Update?")) { return }
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        Remove-Item -Path $watcherPath -Force -ErrorAction SilentlyContinue
        if (Test-Path $markerPath) {
            Set-Service -Name wuauserv -StartupType Manual -ErrorAction SilentlyContinue
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
            Remove-Item -Path $markerPath -Force -ErrorAction SilentlyContinue
        }
        Write-Host "`n[OK] Removed - Windows Update is back to normal." -ForegroundColor $Script:Colors.Success
        Write-Log "Removed Windows Update auto-pause" -Level Success -Category "Automation"
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

    if (-not (Confirm-Action -Message "Enable Windows Update auto-pause for detected games?" -DefaultYes)) { return }

    Write-Log "Enabling game-aware Windows Update pause" -Level Info -Category "Automation"

    $folderListLiteral = ($gameFolders | ForEach-Object { "'$($_ -replace "'", "''")'" }) -join ', '
    $watcherLines = @(
        '# Auto-generated by Wethereal. Regenerate via Automation > Windows Update Auto-Pause While Gaming instead of editing by hand.'
        "`$gameFolders = @($folderListLiteral)"
        "`$markerFile = '$markerPath'"
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
        '        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue'
        '        Set-Service -Name wuauserv -StartupType Disabled -ErrorAction SilentlyContinue'
        '        New-Item -Path $markerFile -ItemType File -Force | Out-Null'
        '    }'
        '}'
        'else {'
        '    if (Test-Path $markerFile) {'
        '        Set-Service -Name wuauserv -StartupType Manual -ErrorAction SilentlyContinue'
        '        Start-Service -Name wuauserv -ErrorAction SilentlyContinue'
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
        Write-Log "Created game-aware Windows Update pause task ($($gameFolders.Count) folders watched)" -Level Success -Category "Automation"
    }
    catch {
        Write-Host "`n[X] Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor $Script:Colors.Error
        Write-Log "Failed to create game-aware update pause task: $($_.Exception.Message)" -Level Error -Category "Automation"
    }

    Wait-ForUser
}

#endregion

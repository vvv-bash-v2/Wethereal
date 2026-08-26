# Wethereal Ultimate Edition - Pro Suite Module
# Full rollback, third-party adware scanner, disk S.M.A.R.T. health check,
# opt-in local usage telemetry, code-signing, EN/ES/FR/DE/PT language toggle,
# configuration drift detection, clean uninstall wizard, and a scanner for
# conflicting third-party optimization tools.

$Script:TelemetryFile = "$PSScriptRoot\Telemetry.json"
$Script:LanguageFile = "$PSScriptRoot\Language.json"
$Script:TelemetryEnabled = $false
$Script:TelemetryWebhookUrl = $null
$Script:Language = 'EN'

#region Category 12: Pro Suite

function Global:Show-ProSuiteMenu {
    do {
        Show-Header "Pro Suite"
        Write-Host "  PRO SUITE" -ForegroundColor $Script:Colors.Menu
        Write-Host "  =======================================================================" -ForegroundColor $Script:Colors.Menu
        Write-Host "   1. <<  Full Rollback (undo EVERYTHING Wethereal has ever changed)" -ForegroundColor White
        Write-Host "   2. [SCAN]  Third-Party Adware / Bloatware Scanner" -ForegroundColor White
        Write-Host "   3. [DISK] SSD/Disk Health Check (S.M.A.R.T.)" -ForegroundColor White
        Write-Host "   4. [STATS] Anonymous Usage Telemetry (opt-in, local)" -ForegroundColor White
        Write-Host "   5. [SIGN] Code-Sign Wethereal Scripts" -ForegroundColor White
        Write-Host "   6. [NET] Language / Idioma (EN/ES/FR/DE/PT)" -ForegroundColor White
        Write-Host "   7. [HEALTH] Configuration Drift Check (Doctor mode)" -ForegroundColor White
        Write-Host "   8. [SCAN] Conflicting Optimizer Scanner" -ForegroundColor White
        Write-Host "   9. [!] Clean Uninstall Wizard" -ForegroundColor White
        Write-Host "   0. <- Back to Main Menu" -ForegroundColor Yellow
        Write-Host ""

        $choice = Read-Host "Select an option"

        switch ($choice) {
            '1' { Invoke-FullRollback }
            '2' { Find-ThirdPartyAdware }
            '3' { Test-DiskHealth }
            '4' { Show-TelemetryMenu }
            '5' { Set-WetherealCodeSignature }
            '6' { Set-WetherealLanguage }
            '7' { Test-ConfigurationDrift }
            '8' { Find-ConflictingOptimizers }
            '9' { Invoke-WetherealUninstall }
            '0' { return }
            default {
                Write-Host "`n[X] Invalid option." -ForegroundColor $Script:Colors.Error
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

#endregion

#region Full Rollback

function Global:Invoke-FullRollback {
    Write-Host "`n[FULL ROLLBACK]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Reverts EVERY registry value and service Wethereal has EVER changed on" -ForegroundColor $Script:Colors.Info
    Write-Host "this machine - across every session, not just this one - back to the" -ForegroundColor $Script:Colors.Info
    Write-Host "first value it ever recorded for each." -ForegroundColor $Script:Colors.Info

    if (-not (Test-Path $Script:MasterBackupFile)) {
        Write-Host "`n[!] No lifetime backup file found yet - nothing has been recorded to roll" -ForegroundColor $Script:Colors.Warning
        Write-Host "  back (or it was deleted). Nothing to do." -ForegroundColor $Script:Colors.Warning
        Wait-ForUser
        return
    }

    $entries = @(Get-Content -Path $Script:MasterBackupFile -Raw | ConvertFrom-Json)
    if ($entries.Count -eq 0) {
        Write-Host "`n[!] The lifetime backup file is empty - nothing to roll back." -ForegroundColor $Script:Colors.Warning
        Wait-ForUser
        return
    }

    Write-Host "`n  Found $($entries.Count) recorded change(s) to revert." -ForegroundColor $Script:Colors.Highlight
    Write-Host "  [!]  This is a big hammer - it undoes months of tweaks in one go." -ForegroundColor $Script:Colors.Warning

    if (-not (Confirm-Action -Message "Roll back ALL $($entries.Count) changes now?")) { return }

    Write-Log "Starting full rollback of $($entries.Count) lifetime-tracked changes" -Level Info -Category "Rollback"
    Invoke-BackupRestore -Entries $entries

    Write-Host "`n[OK] Full rollback complete!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Note: services/settings changed OUTSIDE Wethereal (by you, by Windows" -ForegroundColor $Script:Colors.Info
    Write-Host "  Update, by another tool) since the original recording are not reverted -" -ForegroundColor $Script:Colors.Info
    Write-Host "  only the specific values Wethereal itself changed." -ForegroundColor $Script:Colors.Info
    Write-Host "  Restart recommended." -ForegroundColor $Script:Colors.Warning
    Write-Log "Full rollback completed" -Level Success -Category "Rollback"

    Wait-ForUser
}

#endregion

#region Third-Party Adware / Bloatware Scanner

# Known PUP/adware/scareware name FRAGMENTS seen in the Uninstall registry.
# Deliberately specific multi-word phrases (not bare words like "Toolbar"
# alone) to avoid flagging a legitimate app that happens to share a word.
$Script:AdwarePatterns = @(
    "Ask Toolbar", "Yahoo! Toolbar", "Conduit", "MyWebSearch", "Search Protect",
    "Searchqu", "Babylon Toolbar", "Delta Toolbar", "SweetIM", "Snap.Do",
    "iLivid", "OptimizerPro", "PC Optimizer Pro", "Driver Updater", "RegClean Pro",
    "Advanced PC Care", "PC Speed Up", "Registry Booster", "WebDiscover", "Qone8",
    "CoolWebSearch", "Wajam", "DefaultTab", "SaveSense", "PriceGong", "Slick Savings",
    "Coupon Server", "Systweak", "Advanced SystemCare"
)

function Global:Find-ThirdPartyAdware {
    Write-Host "`n[THIRD-PARTY ADWARE / BLOATWARE SCANNER]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Scans installed-program entries (beyond just Microsoft Store apps) for" -ForegroundColor $Script:Colors.Info
    Write-Host "known adware/PUP name patterns - toolbars, fake optimizers, search" -ForegroundColor $Script:Colors.Info
    Write-Host "hijackers, driver-update scams." -ForegroundColor $Script:Colors.Info
    Write-Host ""

    $uninstallKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $installed = Get-ItemProperty -Path $uninstallKeys -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName } |
        Select-Object DisplayName, UninstallString, PSPath -Unique

    $found = @()
    foreach ($app in $installed) {
        foreach ($pattern in $Script:AdwarePatterns) {
            if ($app.DisplayName -like "*$pattern*") {
                $found += [PSCustomObject]@{
                    Name            = $app.DisplayName
                    UninstallString = $app.UninstallString
                    RegistryPath    = $app.PSPath
                }
                break
            }
        }
    }

    if ($found.Count -eq 0) {
        Write-Host "  [OK] No known adware/bloatware patterns found in installed programs!" -ForegroundColor $Script:Colors.Success
        Write-Log "Adware scan: 0 matches" -Level Info -Category "Privacy"
        Wait-ForUser
        return
    }

    Write-Host "  [!] Found $($found.Count) suspicious program(s):" -ForegroundColor $Script:Colors.Warning
    for ($i = 0; $i -lt $found.Count; $i++) {
        Write-Host ("  {0}. {1}" -f ($i + 1), $found[$i].Name) -ForegroundColor White
    }
    Write-Host ""
    $selection = Read-Host "Select which to uninstall, comma-separated (0/blank to cancel, 'all' for all)"

    if ([string]::IsNullOrWhiteSpace($selection) -or $selection -eq '0') { return }

    $indices = if ($selection.Trim() -eq 'all') {
        0..($found.Count - 1)
    }
    else {
        $selection -split ',' | ForEach-Object {
            $n = 0
            if ([int]::TryParse($_.Trim(), [ref]$n)) { $n - 1 }
        } | Where-Object { $_ -ge 0 -and $_ -lt $found.Count } | Select-Object -Unique
    }

    if (-not $indices -or $indices.Count -eq 0) {
        Write-Host "`n[X] No valid selection." -ForegroundColor $Script:Colors.Error
        Wait-ForUser
        return
    }

    $toRemove = $indices | ForEach-Object { $found[$_] }

    $steps = $toRemove | ForEach-Object {
        $app = $_
        @{
            Name      = "Uninstalling $($app.Name)"
            Condition = { -not [string]::IsNullOrWhiteSpace($app.UninstallString) }.GetNewClosure()
            Action    = {
                # Uninstall strings are typically "MsiExec.exe /X{GUID}" or a
                # vendor .exe with its own silent-uninstall args (not
                # standardized, so this best-effort launches it and waits).
                if ($app.UninstallString -match 'msiexec') {
                    $productCode = [regex]::Match($app.UninstallString, '\{[0-9A-Fa-f-]+\}').Value
                    if ($productCode) {
                        Start-Process -FilePath "msiexec.exe" -ArgumentList "/X$productCode /qn" -Wait -ErrorAction Stop
                    }
                    else {
                        throw "Could not parse MSI product code from uninstall string"
                    }
                }
                else {
                    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$($app.UninstallString)`"" -Wait -ErrorAction Stop
                }
            }.GetNewClosure()
        }
    }

    Invoke-TweakSequence -Title "Adware/Bloatware Removal" -Steps $steps -Category "Privacy" | Out-Null
    Wait-ForUser
}

#endregion

#region SSD/Disk Health (S.M.A.R.T.)

function Global:Test-DiskHealth {
    Write-Host "`n[SSD/DISK HEALTH CHECK]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Reading S.M.A.R.T. reliability counters for every physical disk..." -ForegroundColor $Script:Colors.Info
    Write-Host ""

    $disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
    if (-not $disks) {
        Write-Host "[X] Could not enumerate physical disks on this system." -ForegroundColor $Script:Colors.Error
        Wait-ForUser
        return
    }

    foreach ($disk in $disks) {
        $healthColor = if ($disk.HealthStatus -eq 'Healthy') { $Script:Colors.Success } else { $Script:Colors.Error }
        Write-Host "  [DISK] $($disk.FriendlyName) [$($disk.MediaType), $([math]::Round($disk.Size/1GB,0)) GB]" -ForegroundColor $Script:Colors.Highlight
        Write-Host "     Health: $($disk.HealthStatus)  |  Operational: $($disk.OperationalStatus)" -ForegroundColor $healthColor

        try {
            $reliability = Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction Stop
            if ($null -ne $reliability.Temperature -and $reliability.Temperature -gt 0) {
                $tempColor = if ($reliability.Temperature -gt 60) { $Script:Colors.Error } elseif ($reliability.Temperature -gt 50) { $Script:Colors.Warning } else { $Script:Colors.Success }
                Write-Host "     Temperature: $($reliability.Temperature) degC" -ForegroundColor $tempColor
            }
            if ($null -ne $reliability.Wear) {
                $wearColor = if ($reliability.Wear -gt 80) { $Script:Colors.Error } elseif ($reliability.Wear -gt 50) { $Script:Colors.Warning } else { $Script:Colors.Success }
                Write-Host "     SSD wear used: $($reliability.Wear)%" -ForegroundColor $wearColor
            }
            if ($null -ne $reliability.ReadErrorsTotal -or $null -ne $reliability.WriteErrorsTotal) {
                $errColor = if (($reliability.ReadErrorsTotal + $reliability.WriteErrorsTotal) -gt 0) { $Script:Colors.Warning } else { $Script:Colors.Success }
                Write-Host "     Read errors: $($reliability.ReadErrorsTotal)  |  Write errors: $($reliability.WriteErrorsTotal)" -ForegroundColor $errColor
            }
            if ($null -ne $reliability.PowerOnHours) {
                Write-Host "     Power-on hours: $($reliability.PowerOnHours) ($([math]::Round($reliability.PowerOnHours / 24, 0)) days)" -ForegroundColor White
            }
        }
        catch {
            Write-Host "     [!] S.M.A.R.T. reliability counters unavailable for this disk (common on USB/RAID controllers)" -ForegroundColor DarkGray
        }
        Write-Host ""
    }

    Write-Log "Ran disk S.M.A.R.T. health check on $($disks.Count) disk(s)" -Level Info -Category "Monitoring"
    Wait-ForUser
}

#endregion

#region Configuration Drift Detection ("Doctor" mode)

function Global:Test-ConfigurationDrift {
    <#
        Compares every registry value and service Wethereal has ever recorded
        (the lifetime master backup - the ORIGINAL, pre-Wethereal value for
        each) against its CURRENT live value. If the current value now
        matches what it was BEFORE Wethereal touched it, that specific tweak
        has been silently reverted - typically by a Windows Update, a
        conflicting third-party tool, or the user manually changing it back -
        and the user would otherwise have no way to know without re-checking
        every tweak by hand. Read-only: reports drift, changes nothing.
    #>
    param([switch]$Quiet)

    if (-not $Quiet) {
        Write-Host "`n[CONFIGURATION DRIFT CHECK]" -ForegroundColor $Script:Colors.Title
        Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
        Write-Host "Checks every tweak Wethereal has ever applied against its current live" -ForegroundColor $Script:Colors.Info
        Write-Host "value, to catch anything silently reverted (a Windows Update, another" -ForegroundColor $Script:Colors.Info
        Write-Host "tool, or a manual change back)." -ForegroundColor $Script:Colors.Info
    }

    if (-not (Test-Path $Script:MasterBackupFile)) {
        if (-not $Quiet) { Write-Host "`n[!] No lifetime backup file yet - nothing has been recorded to check." -ForegroundColor $Script:Colors.Warning; Wait-ForUser }
        return @()
    }

    $entries = @(Get-Content -Path $Script:MasterBackupFile -Raw | ConvertFrom-Json)
    $drifted = @()

    foreach ($entry in $entries) {
        if ($entry.Type -eq 'Registry') {
            $current = Get-ItemProperty -Path $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue
            if ($current -and ("$($current.$($entry.Name))" -eq "$($entry.Value)")) {
                $drifted += "Registry: $($entry.Path)\$($entry.Name) is back to its pre-Wethereal value ($($entry.Value))"
            }
        }
        elseif ($entry.Type -eq 'Service') {
            $service = Get-Service -Name $entry.Name -ErrorAction SilentlyContinue
            if ($service -and $service.StartType -eq $entry.StartType -and $service.Status -eq $entry.Status) {
                $drifted += "Service: $($entry.Name) is back to its pre-Wethereal state (StartType=$($entry.StartType), Status=$($entry.Status))"
            }
        }
    }

    if (-not $Quiet) {
        if ($drifted.Count -eq 0) {
            Write-Host "`n[OK] No drift detected - every tracked tweak is still in effect." -ForegroundColor $Script:Colors.Success
        }
        else {
            Write-Host "`n[!] $($drifted.Count) tweak(s) appear to have reverted:" -ForegroundColor $Script:Colors.Warning
            $drifted | ForEach-Object { Write-Host "  - $_" -ForegroundColor $Script:Colors.Warning }
            Write-Host "`n  Re-apply the relevant tweak(s), or the profile/Apply All that covers them." -ForegroundColor $Script:Colors.Info
        }
        Write-Log "Configuration drift check: $($drifted.Count) drifted item(s)" -Level $(if ($drifted.Count -gt 0) { 'Warning' } else { 'Info' }) -Category "Doctor"
        Wait-ForUser
    }

    return $drifted
}

#endregion

#region Clean Uninstall Wizard

function Global:Invoke-WetherealUninstall {
    <#
        A proper "take me back to before I ever ran this" path, distinct from
        Full Rollback: rollback only restores tracked registry/service
        values, but leaves behind Wethereal's own scheduled tasks (Auto
        Re-Apply, Game-Aware Update Pause, Game-Aware Notification Mute) and
        generated files (log, master backup, config, telemetry/language
        settings, watcher scripts). This wizard does the rollback AND cleans
        up everything Wethereal itself created. It does not delete the
        Wethereal script files - PowerShell can't reliably delete a script
        that's actively running, so that last step is left to the user.
    #>
    Write-Host "`n[CLEAN UNINSTALL WIZARD]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "[!]  This will:" -ForegroundColor $Script:Colors.Warning
    Write-Host "     1. Roll back EVERY registry value/service Wethereal has ever changed" -ForegroundColor $Script:Colors.Warning
    Write-Host "     2. Remove all scheduled tasks Wethereal created" -ForegroundColor $Script:Colors.Warning
    Write-Host "     3. Delete Wethereal's own generated files (log, backups, settings)" -ForegroundColor $Script:Colors.Warning
    Write-Host "  It will NOT delete the Wethereal script files themselves - delete the" -ForegroundColor $Script:Colors.Info
    Write-Host "  folder yourself afterward if you want the tool fully gone." -ForegroundColor $Script:Colors.Info

    if (-not (Confirm-Action -Message "Proceed with the clean uninstall?")) { return }

    Write-Log "Starting clean uninstall wizard" -Level Warning -Category "Uninstall"

    $steps = @(
        @{
            Name   = "Rolling back all tracked registry/service changes"
            Action = {
                if (Test-Path $Script:MasterBackupFile) {
                    $entries = @(Get-Content -Path $Script:MasterBackupFile -Raw | ConvertFrom-Json)
                    if ($entries.Count -gt 0) { Invoke-BackupRestore -Entries $entries }
                }
            }
        }
        @{
            Name   = "Removing Wethereal scheduled tasks"
            Action = {
                @('Wethereal Auto Re-Apply', 'Wethereal Game-Aware Update Pause', 'Wethereal Game-Aware Notification Mute') | ForEach-Object {
                    Unregister-ScheduledTask -TaskName $_ -Confirm:$false -ErrorAction SilentlyContinue
                }
            }
        }
        @{
            Name   = "Deleting generated files"
            Action = {
                $filesToRemove = @(
                    $Script:LogFile, $Script:MasterBackupFile, $Script:ConfigFile,
                    $Script:TelemetryFile, $Script:LanguageFile,
                    "$PSScriptRoot\Wethereal-GameUpdatePauseWatcher.ps1",
                    "$PSScriptRoot\Wethereal-UpdatePausedByGame.marker",
                    "$PSScriptRoot\Wethereal-GameNotificationMuteWatcher.ps1",
                    "$PSScriptRoot\Wethereal-NotificationsMutedByGame.marker"
                )
                $filesToRemove | Where-Object { $_ } | ForEach-Object { Remove-Item -Path $_ -Force -ErrorAction SilentlyContinue }
                Get-ChildItem -Path $PSScriptRoot -Filter "WinTweaker_Backup_*.json" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                Get-ChildItem -Path $PSScriptRoot -Filter "OptimizationReport_*.html" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                Get-ChildItem -Path $PSScriptRoot -Filter "ThermalEnergyReport_*.html" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            }
        }
    )

    Invoke-TweakSequence -Title "Wethereal Clean Uninstall" -Steps $steps -Category "Uninstall" | Out-Null

    Write-Host "`n[OK] Clean uninstall complete!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Delete this folder to remove the Wethereal script files as well." -ForegroundColor $Script:Colors.Info
    Write-Host "  Restart recommended." -ForegroundColor $Script:Colors.Warning
    Wait-ForUser
}

#endregion

#region Conflicting Third-Party Optimizer Scanner

# Legitimate (if sometimes overlapping) optimization/cleaner tools that write
# to many of the same registry keys Wethereal does. Not malware like
# $Script:AdwarePatterns - just tools that can fight over the same settings,
# which is a common cause of "my changes keep reverting" confusion.
$Script:ConflictingOptimizerPatterns = @(
    "CCleaner", "Advanced SystemCare", "IObit Driver Booster", "Wise Care 365",
    "Wise Registry Cleaner", "Glary Utilities", "Auslogics BoostSpeed",
    "System Mechanic", "TuneUp Utilities", "AVG TuneUp", "Norton Utilities",
    "Ashampoo WinOptimizer", "Razer Cortex", "PC Cleaner Pro"
)

function Global:Find-ConflictingOptimizers {
    Write-Host "`n[CONFLICTING OPTIMIZER SCANNER]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Scans installed programs for other optimization/cleaner tools that write" -ForegroundColor $Script:Colors.Info
    Write-Host "to many of the same registry keys as Wethereal - a common, non-obvious" -ForegroundColor $Script:Colors.Info
    Write-Host "cause of tweaks appearing to 'revert on their own'. These are legitimate" -ForegroundColor $Script:Colors.Info
    Write-Host "tools, not malware - nothing is removed automatically." -ForegroundColor $Script:Colors.Info
    Write-Host ""

    $uninstallKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $installed = Get-ItemProperty -Path $uninstallKeys -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName } |
        Select-Object DisplayName, UninstallString -Unique

    $found = @()
    foreach ($app in $installed) {
        foreach ($pattern in $Script:ConflictingOptimizerPatterns) {
            if ($app.DisplayName -like "*$pattern*") {
                $found += $app.DisplayName
                break
            }
        }
    }
    $found = $found | Select-Object -Unique

    if ($found.Count -eq 0) {
        Write-Host "[OK] No known conflicting optimizer tools found." -ForegroundColor $Script:Colors.Success
        Write-Log "Conflicting optimizer scan: 0 matches" -Level Info -Category "Compatibility"
        Wait-ForUser
        return
    }

    Write-Host "[!] Found $($found.Count) tool(s) that may compete with Wethereal's settings:" -ForegroundColor $Script:Colors.Warning
    $found | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
    Write-Host "`n  If tweaks seem to 'undo themselves' after a reboot, check that tool's own" -ForegroundColor $Script:Colors.Info
    Write-Host "  settings/scheduled cleanup first - it may be resetting the same keys." -ForegroundColor $Script:Colors.Info

    Write-Log "Conflicting optimizer scan: found $($found -join ', ')" -Level Warning -Category "Compatibility"
    Wait-ForUser
}

#endregion

#region Opt-In Usage Telemetry (local, anonymous)

function Global:Import-TelemetrySettings {
    if (Test-Path $Script:TelemetryFile) {
        try {
            $cfg = Get-Content -Path $Script:TelemetryFile -Raw | ConvertFrom-Json
            $Script:TelemetryEnabled = [bool]$cfg.Enabled
            $Script:TelemetryWebhookUrl = $cfg.WebhookUrl
        }
        catch {}
    }
}

function Global:Save-TelemetrySettings {
    @{ Enabled = $Script:TelemetryEnabled; WebhookUrl = $Script:TelemetryWebhookUrl } |
        ConvertTo-Json | Out-File -FilePath $Script:TelemetryFile -Encoding UTF8
}

function Global:Add-TelemetryEvent {
    <#
        Called by Invoke-TweakSequence (Win-Tweaker.ps1) after each step, when
        telemetry is opted in. 100% local - counts which tweak names get
        applied most, no PII, nothing sent anywhere UNLESS the user has
        explicitly configured their OWN webhook URL to receive it.
    #>
    param([string]$Category, [string]$StepName)

    if (-not $Script:TelemetryEnabled) { return }

    try {
        $stats = if (Test-Path $Script:TelemetryFile) {
            $raw = Get-Content -Path $Script:TelemetryFile -Raw | ConvertFrom-Json
            if ($raw.PSObject.Properties.Name -contains 'Events') { $raw } else { [PSCustomObject]@{ Enabled = $Script:TelemetryEnabled; WebhookUrl = $Script:TelemetryWebhookUrl; Events = @{} } }
        }
        else {
            [PSCustomObject]@{ Enabled = $Script:TelemetryEnabled; WebhookUrl = $Script:TelemetryWebhookUrl; Events = @{} }
        }

        $eventsHash = @{}
        if ($stats.Events) { $stats.Events.PSObject.Properties | ForEach-Object { $eventsHash[$_.Name] = $_.Value } }
        $key = "$Category::$StepName"
        $eventsHash[$key] = [int]($eventsHash[$key]) + 1
        $stats = @{ Enabled = $Script:TelemetryEnabled; WebhookUrl = $Script:TelemetryWebhookUrl; Events = $eventsHash }
        $stats | ConvertTo-Json -Depth 5 | Out-File -FilePath $Script:TelemetryFile -Encoding UTF8

        if ($Script:TelemetryWebhookUrl) {
            try {
                Invoke-RestMethod -Uri $Script:TelemetryWebhookUrl -Method Post -Body (@{ category = $Category; step = $StepName; timestamp = (Get-Date).ToString('o') } | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 5 -ErrorAction Stop | Out-Null
            }
            catch { }
        }
    }
    catch { }
}

function Global:Show-TelemetryMenu {
    Write-Host "`n[ANONYMOUS USAGE TELEMETRY]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "[!]  Honest disclosure: Wethereal has no analytics backend of its own." -ForegroundColor $Script:Colors.Warning
    Write-Host "   This ONLY counts, locally on this machine, which tweaks you apply most" -ForegroundColor $Script:Colors.Warning
    Write-Host "   (no personal data, no machine identifiers). If you run your own webhook" -ForegroundColor $Script:Colors.Warning
    Write-Host "   endpoint (e.g. across a fleet of machines you manage), you can point it" -ForegroundColor $Script:Colors.Warning
    Write-Host "   there - otherwise nothing leaves this PC." -ForegroundColor $Script:Colors.Warning
    Write-Host ""
    Write-Host "  Currently: $(if ($Script:TelemetryEnabled) { 'ENABLED' } else { 'DISABLED' })" -ForegroundColor $(if ($Script:TelemetryEnabled) { $Script:Colors.Success } else { $Script:Colors.Warning })
    if ($Script:TelemetryWebhookUrl) { Write-Host "  Webhook: $Script:TelemetryWebhookUrl" -ForegroundColor White }
    Write-Host ""
    Write-Host "  1. Enable local telemetry" -ForegroundColor White
    Write-Host "  2. Enable + set a webhook URL (optional, your own endpoint)" -ForegroundColor White
    Write-Host "  3. Disable telemetry" -ForegroundColor White
    Write-Host "  4. View local usage summary" -ForegroundColor White
    Write-Host "  0. Back" -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "Select an option"
    switch ($choice) {
        '1' {
            $Script:TelemetryEnabled = $true
            Save-TelemetrySettings
            Write-Host "`n[OK] Local telemetry enabled." -ForegroundColor $Script:Colors.Success
            Write-Log "Telemetry enabled (local only)" -Level Info -Category "Telemetry"
        }
        '2' {
            $url = Read-Host "Webhook URL (https://...)"
            if ($url -match '^https://') {
                $Script:TelemetryEnabled = $true
                $Script:TelemetryWebhookUrl = $url
                Save-TelemetrySettings
                Write-Host "`n[OK] Telemetry enabled with webhook." -ForegroundColor $Script:Colors.Success
                Write-Log "Telemetry enabled with webhook $url" -Level Info -Category "Telemetry"
            }
            else {
                Write-Host "`n[X] Must be an https:// URL." -ForegroundColor $Script:Colors.Error
            }
        }
        '3' {
            $Script:TelemetryEnabled = $false
            $Script:TelemetryWebhookUrl = $null
            Save-TelemetrySettings
            Write-Host "`n[OK] Telemetry disabled." -ForegroundColor $Script:Colors.Success
            Write-Log "Telemetry disabled" -Level Info -Category "Telemetry"
        }
        '4' {
            if (Test-Path $Script:TelemetryFile) {
                $stats = Get-Content -Path $Script:TelemetryFile -Raw | ConvertFrom-Json
                if ($stats.Events -and $stats.Events.PSObject.Properties.Count -gt 0) {
                    Write-Host "`n  Local usage summary (this machine only):" -ForegroundColor $Script:Colors.Highlight
                    $stats.Events.PSObject.Properties | Sort-Object Value -Descending | ForEach-Object {
                        Write-Host ("    {0,-4} {1}" -f $_.Value, $_.Name) -ForegroundColor White
                    }
                }
                else {
                    Write-Host "`n  No usage recorded yet." -ForegroundColor $Script:Colors.Info
                }
            }
            else {
                Write-Host "`n  No usage recorded yet." -ForegroundColor $Script:Colors.Info
            }
        }
        '0' { return }
        default { Write-Host "`n[X] Invalid option." -ForegroundColor $Script:Colors.Error }
    }

    Wait-ForUser
}

#endregion

#region Code Signing

function Global:Set-WetherealCodeSignature {
    Write-Host "`n[CODE-SIGN WETHEREAL SCRIPTS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Creates a self-signed code-signing certificate and signs every .ps1 file" -ForegroundColor $Script:Colors.Info
    Write-Host "in this folder - this stops PowerShell's execution policy from blocking" -ForegroundColor $Script:Colors.Info
    Write-Host "the scripts on THIS machine (or others you distribute the certificate to" -ForegroundColor $Script:Colors.Info
    Write-Host "and mark as trusted)." -ForegroundColor $Script:Colors.Info
    Write-Host ""
    Write-Host "[!]  A self-signed cert does NOT stop SmartScreen warnings for other people" -ForegroundColor $Script:Colors.Warning
    Write-Host "   downloading Wethereal from the internet - that needs a certificate from" -ForegroundColor $Script:Colors.Warning
    Write-Host "   a public Certificate Authority (a paid code-signing cert)." -ForegroundColor $Script:Colors.Warning

    if (-not (Confirm-Action -Message "Create/reuse a local code-signing certificate and sign all scripts?" -DefaultYes)) { return }

    Write-Log "Code-signing Wethereal scripts" -Level Info -Category "Security"

    $steps = @(
        @{
            Name   = "Finding or creating a local code-signing certificate"
            Action = {
                $existing = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert -ErrorAction SilentlyContinue |
                    Where-Object { $_.Subject -like "*Wethereal*" } | Select-Object -First 1
                if ($existing) {
                    $Script:_signingCert = $existing
                }
                else {
                    $Script:_signingCert = New-SelfSignedCertificate -Type CodeSigning -Subject "CN=Wethereal Local Signing" `
                        -CertStoreLocation Cert:\CurrentUser\My -KeyUsage DigitalSignature -FriendlyName "Wethereal Code Signing" `
                        -NotAfter (Get-Date).AddYears(5) -ErrorAction Stop
                }
            }
        }
        @{
            Name   = "Trusting the certificate locally (Trusted Root + Publishers)"
            Action = {
                $rootStore = Get-Item Cert:\CurrentUser\Root
                $rootStore.Open("ReadWrite")
                $rootStore.Add($Script:_signingCert)
                $rootStore.Close()

                $pubStore = Get-Item Cert:\CurrentUser\TrustedPublisher
                $pubStore.Open("ReadWrite")
                $pubStore.Add($Script:_signingCert)
                $pubStore.Close()
            }
        }
        @{
            Name   = "Signing all .ps1 files in $PSScriptRoot"
            Action = {
                $files = Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1"
                $failures = @()
                foreach ($file in $files) {
                    $result = Set-AuthenticodeSignature -FilePath $file.FullName -Certificate $Script:_signingCert -ErrorAction Stop
                    if ($result.Status -ne 'Valid') { $failures += $file.Name }
                }
                if ($failures.Count -gt 0) { throw "Signature not valid for: $($failures -join ', ')" }
            }
        }
    )

    Invoke-TweakSequence -Title "Code Signing" -Steps $steps -Category "Security" | Out-Null

    Write-Host "`n[OK] Scripts signed!" -ForegroundColor $Script:Colors.Success
    Write-Host "  Set your execution policy to AllSigned or RemoteSigned to require/allow" -ForegroundColor $Script:Colors.Info
    Write-Host "  this: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor White
    Wait-ForUser
}

#endregion

#region Language / Idioma

$Script:Strings = @{
    EN = @{
        MainMenuTitle    = "SELECT A CATEGORY"
        QuickActions     = "QUICK ACTIONS"
        Cat1             = "System Performance (CPU, GPU, RAM, Disk)"
        Cat2             = "Gaming & Graphics Optimization"
        Cat3             = "Network & Internet Tweaks"
        Cat4             = "Privacy & Security"
        Cat5             = "Cleanup & Maintenance"
        Cat6             = "Advanced System Tweaks"
        Cat7             = "Monitoring & System Info"
        Cat8             = "Tools & Utilities"
        Cat9             = "Extras & App Manager (winget, Ultimate Perf, more)"
        Cat10            = "Pro Gaming Tools (OC guide, bottleneck, per-game tuning)"
        Cat11            = "Automation & Updates (self-update, benchmark, scheduling)"
        Cat12            = "Pro Suite (rollback, adware scan, disk health, more)"
        Cat13            = "Advanced Performance & Compatibility (C-states, power mgmt, prereqs, audio)"
        Exit             = "Exit"
        PressEnter       = "Press Enter to continue"
        Yes              = "Yes"
        No               = "No"
        Success          = "Success"
        Error            = "Error"
        Warning          = "Warning"
    }
    ES = @{
        MainMenuTitle    = "SELECCIONA UNA CATEGORIA"
        QuickActions     = "ACCIONES RAPIDAS"
        Cat1             = "Rendimiento del Sistema (CPU, GPU, RAM, Disco)"
        Cat2             = "Optimizacion de Juegos y Graficos"
        Cat3             = "Ajustes de Red e Internet"
        Cat4             = "Privacidad y Seguridad"
        Cat5             = "Limpieza y Mantenimiento"
        Cat6             = "Ajustes Avanzados del Sistema"
        Cat7             = "Monitorizacion e Informacion del Sistema"
        Cat8             = "Herramientas y Utilidades"
        Cat9             = "Extras y Gestor de Apps (winget, Rendimiento Extremo, mas)"
        Cat10            = "Herramientas Pro de Gaming (guia OC, cuellos de botella, ajuste por juego)"
        Cat11            = "Automatizacion y Actualizaciones (autoactualizacion, benchmark, programacion)"
        Cat12            = "Suite Pro (rollback, escaner de adware, salud de disco, mas)"
        Cat13            = "Rendimiento Avanzado y Compatibilidad (C-states, gestion de energia, prerequisitos, audio)"
        Exit             = "Salir"
        PressEnter       = "Pulsa Enter para continuar"
        Yes              = "Si"
        No               = "No"
        Success          = "Exito"
        Error            = "Error"
        Warning          = "Aviso"
    }
    FR = @{
        MainMenuTitle    = "SELECTIONNEZ UNE CATEGORIE"
        QuickActions     = "ACTIONS RAPIDES"
        Cat1             = "Performance Systeme (CPU, GPU, RAM, Disque)"
        Cat2             = "Optimisation Jeux et Graphismes"
        Cat3             = "Reglages Reseau et Internet"
        Cat4             = "Confidentialite et Securite"
        Cat5             = "Nettoyage et Maintenance"
        Cat6             = "Reglages Systeme Avances"
        Cat7             = "Surveillance et Infos Systeme"
        Cat8             = "Outils et Utilitaires"
        Cat9             = "Extras et Gestionnaire d'Apps (winget, Perf Ultime, plus)"
        Cat10            = "Outils Pro Gaming (guide OC, goulot d'etranglement, reglage par jeu)"
        Cat11            = "Automatisation et Mises a Jour (auto-maj, benchmark, planification)"
        Cat12            = "Suite Pro (rollback, scan adware, sante disque, plus)"
        Cat13            = "Performance Avancee et Compatibilite (C-states, gestion energie, prerequis, audio)"
        Exit             = "Quitter"
        PressEnter       = "Appuyez sur Entree pour continuer"
        Yes              = "Oui"
        No               = "Non"
        Success          = "Succes"
        Error            = "Erreur"
        Warning          = "Avertissement"
    }
    DE = @{
        MainMenuTitle    = "KATEGORIE AUSWAEHLEN"
        QuickActions     = "SCHNELLAKTIONEN"
        Cat1             = "Systemleistung (CPU, GPU, RAM, Festplatte)"
        Cat2             = "Gaming- und Grafikoptimierung"
        Cat3             = "Netzwerk- und Internet-Einstellungen"
        Cat4             = "Datenschutz und Sicherheit"
        Cat5             = "Bereinigung und Wartung"
        Cat6             = "Erweiterte Systemeinstellungen"
        Cat7             = "Ueberwachung und Systeminfo"
        Cat8             = "Werkzeuge und Dienstprogramme"
        Cat9             = "Extras und App-Manager (winget, Ultimate-Leistung, mehr)"
        Cat10            = "Pro-Gaming-Tools (OC-Anleitung, Engpass, spielspezifische Einstellungen)"
        Cat11            = "Automatisierung und Updates (Selbst-Update, Benchmark, Planung)"
        Cat12            = "Pro Suite (Rollback, Adware-Scan, Festplattengesundheit, mehr)"
        Cat13            = "Erweiterte Leistung und Kompatibilitaet (C-States, Energieverwaltung, Voraussetzungen, Audio)"
        Exit             = "Beenden"
        PressEnter       = "Druecken Sie Enter, um fortzufahren"
        Yes              = "Ja"
        No               = "Nein"
        Success          = "Erfolg"
        Error            = "Fehler"
        Warning          = "Warnung"
    }
    PT = @{
        MainMenuTitle    = "SELECIONE UMA CATEGORIA"
        QuickActions     = "ACOES RAPIDAS"
        Cat1             = "Desempenho do Sistema (CPU, GPU, RAM, Disco)"
        Cat2             = "Otimizacao de Jogos e Graficos"
        Cat3             = "Ajustes de Rede e Internet"
        Cat4             = "Privacidade e Seguranca"
        Cat5             = "Limpeza e Manutencao"
        Cat6             = "Ajustes Avancados do Sistema"
        Cat7             = "Monitoramento e Info do Sistema"
        Cat8             = "Ferramentas e Utilitarios"
        Cat9             = "Extras e Gerenciador de Apps (winget, Desempenho Maximo, mais)"
        Cat10            = "Ferramentas Pro de Gaming (guia OC, gargalo, ajuste por jogo)"
        Cat11            = "Automacao e Atualizacoes (auto-atualizacao, benchmark, agendamento)"
        Cat12            = "Suite Pro (rollback, scanner de adware, saude do disco, mais)"
        Cat13            = "Desempenho Avancado e Compatibilidade (C-states, gerenciamento de energia, pre-requisitos, audio)"
        Exit             = "Sair"
        PressEnter       = "Pressione Enter para continuar"
        Yes              = "Sim"
        No               = "Nao"
        Success          = "Sucesso"
        Error            = "Erro"
        Warning          = "Aviso"
    }
}

function Global:Get-Str {
    param([Parameter(Mandatory = $true)][string]$Key)
    $lang = if ($Script:Strings.ContainsKey($Script:Language)) { $Script:Language } else { 'EN' }
    if ($Script:Strings[$lang].ContainsKey($Key)) { return $Script:Strings[$lang][$Key] }
    return $Script:Strings['EN'][$Key]
}

function Global:Import-LanguageSetting {
    if (Test-Path $Script:LanguageFile) {
        try {
            $cfg = Get-Content -Path $Script:LanguageFile -Raw | ConvertFrom-Json
            if ($cfg.Language -in @('EN', 'ES', 'FR', 'DE', 'PT')) { $Script:Language = $cfg.Language }
        }
        catch {}
    }
}

function Global:Set-WetherealLanguage {
    Write-Host "`n[LANGUAGE / IDIOMA]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Currently: $Script:Language" -ForegroundColor White
    Write-Host ""
    Write-Host "  [i] Translates the main menu, categories and common prompts. Individual" -ForegroundColor DarkGray
    Write-Host "    tweak descriptions deep inside each category are still English-only -" -ForegroundColor DarkGray
    Write-Host "    full line-by-line translation of 170+ tweaks is a bigger future project." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  1. English" -ForegroundColor White
    Write-Host "  2. Espanol" -ForegroundColor White
    Write-Host "  3. Francais" -ForegroundColor White
    Write-Host "  4. Deutsch" -ForegroundColor White
    Write-Host "  5. Portugues" -ForegroundColor White
    Write-Host "  0. Cancel" -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "Select language"
    switch ($choice) {
        '1' { $Script:Language = 'EN' }
        '2' { $Script:Language = 'ES' }
        '3' { $Script:Language = 'FR' }
        '4' { $Script:Language = 'DE' }
        '5' { $Script:Language = 'PT' }
        '0' { return }
        default {
            Write-Host "`n[X] Invalid selection." -ForegroundColor $Script:Colors.Error
            Wait-ForUser
            return
        }
    }

    @{ Language = $Script:Language } | ConvertTo-Json | Out-File -FilePath $Script:LanguageFile -Encoding UTF8
    Write-Host "`n[OK] Language set to $Script:Language. The main menu will use it from now on." -ForegroundColor $Script:Colors.Success
    Write-Log "Language set to $Script:Language" -Level Info -Category "Settings"
    Wait-ForUser
}

#endregion

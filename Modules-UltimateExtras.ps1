# Wethereal Ultimate Edition - Ultimate Extras Module
# App Manager (winget), Ultimate Performance plan, Classic Context Menu,
# Taskbar Alignment, Hosts Ad-Block, Quick Tweak Checklist, Backup Compare,
# TPM/Secure Boot Check.

#region Category 9: Ultimate Extras

function Global:Show-UltimateExtrasMenu {
    do {
        Show-Header "Ultimate Extras"
        Write-Host "  ULTIMATE EXTRAS" -ForegroundColor $Script:Colors.Menu
        Write-Host "  =======================================================================" -ForegroundColor $Script:Colors.Menu
        Write-Host "   1. [PKG] App Manager (Install apps via winget)" -ForegroundColor White
        Write-Host "   2. [DEL]  App Manager (Uninstall apps via winget)" -ForegroundColor White
        Write-Host "   3. ^  Update All Apps (winget upgrade --all)" -ForegroundColor White
        Write-Host "   4. [BOOST] Ultimate Performance Power Plan" -ForegroundColor White
        Write-Host "   5. [MOUSE]  Classic Right-Click Context Menu (Windows 11)" -ForegroundColor White
        Write-Host "   6. [PIN] Taskbar Alignment (Windows 11)" -ForegroundColor White
        Write-Host "   7. [BLOCK] Hosts File Ad-Blocking" -ForegroundColor White
        Write-Host "   8. [OK] Quick Tweak Checklist (pick & apply)" -ForegroundColor White
        Write-Host "   9. [SCAN] Compare Two Backups" -ForegroundColor White
        Write-Host "  10. [LOCK] TPM & Secure Boot Check (Windows 11 readiness)" -ForegroundColor White
        Write-Host "   0. <- Back to Main Menu" -ForegroundColor Yellow
        Write-Host ""

        $choice = Read-Host "Select an option"

        switch ($choice) {
            '1' { Show-AppInstaller }
            '2' { Show-AppUninstaller }
            '3' { Invoke-WingetUpgradeAll }
            '4' { Enable-UltimatePerformancePlan }
            '5' { Set-ClassicContextMenu }
            '6' { Set-TaskbarAlignment }
            '7' { Set-HostsAdBlock }
            '8' { Show-TweakChecklist }
            '9' { Compare-Backups }
            '10' { Test-TpmSecureBoot }
            '0' { return }
            default {
                Write-Host "`n[X] Invalid option." -ForegroundColor $Script:Colors.Error
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

#endregion

#region App Manager (winget)

function Global:Test-WingetAvailable {
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Host "`n[X] winget (App Installer) was not found on this system." -ForegroundColor $Script:Colors.Error
        Write-Host "  Install 'App Installer' from the Microsoft Store, then try again." -ForegroundColor $Script:Colors.Info
        return $false
    }
    return $true
}

# Curated catalog of common, well-known apps (winget package IDs). Kept as a
# static list - rather than trying to list every possible winget package -
# because it's fast, predictable, and doesn't depend on winget's search index
# formatting, which changes over time.
$Script:AppCatalog = @(
    @{ Name = "Brave Browser"; Id = "Brave.Brave" }
    @{ Name = "Google Chrome"; Id = "Google.Chrome" }
    @{ Name = "Mozilla Firefox"; Id = "Mozilla.Firefox" }
    @{ Name = "7-Zip"; Id = "7zip.7zip" }
    @{ Name = "VLC Media Player"; Id = "VideoLAN.VLC" }
    @{ Name = "Discord"; Id = "Discord.Discord" }
    @{ Name = "Steam"; Id = "Valve.Steam" }
    @{ Name = "Epic Games Launcher"; Id = "EpicGames.EpicGamesLauncher" }
    @{ Name = "Visual Studio Code"; Id = "Microsoft.VisualStudioCode" }
    @{ Name = "Notepad++"; Id = "Notepad++.Notepad++" }
    @{ Name = "Everything (file search)"; Id = "voidtools.Everything" }
    @{ Name = "MSI Afterburner"; Id = "Guru3D.Afterburner" }
    @{ Name = "CPU-Z"; Id = "CPUID.CPU-Z" }
    @{ Name = "GPU-Z"; Id = "TechPowerUp.GPU-Z" }
    @{ Name = "HWMonitor"; Id = "CPUID.HWMonitor" }
    @{ Name = "Spotify"; Id = "Spotify.Spotify" }
    @{ Name = "OBS Studio"; Id = "OBSProject.OBSStudio" }
    @{ Name = "Git"; Id = "Git.Git" }
    @{ Name = "Python 3"; Id = "Python.Python.3.12" }
    @{ Name = "Microsoft PowerToys"; Id = "Microsoft.PowerToys" }
    @{ Name = ".NET Desktop Runtime (latest)"; Id = "Microsoft.DotNet.DesktopRuntime.8" }
    @{ Name = "Visual C++ Redistributables (all)"; Id = "Microsoft.VCRedist.2015+.x64" }
)

function Global:Show-AppInstaller {
    Write-Host "`n[APP MANAGER - INSTALL]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Test-WingetAvailable)) { Wait-ForUser; return }

    Write-Host "Select apps to install (comma-separated numbers, e.g. 1,3,7 - or 'all'):" -ForegroundColor $Script:Colors.Info
    Write-Host ""
    for ($i = 0; $i -lt $Script:AppCatalog.Count; $i++) {
        Write-Host ("  {0,2}. {1}" -f ($i + 1), $Script:AppCatalog[$i].Name) -ForegroundColor White
    }
    Write-Host ""
    $selection = Read-Host "Selection (0 to cancel)"

    if ([string]::IsNullOrWhiteSpace($selection) -or $selection -eq '0') { return }

    if ($selection.Trim() -eq 'all') {
        $indices = 0..($Script:AppCatalog.Count - 1)
    }
    else {
        $indices = $selection -split ',' | ForEach-Object {
            $n = 0
            if ([int]::TryParse($_.Trim(), [ref]$n)) { $n - 1 }
        } | Where-Object { $_ -ge 0 -and $_ -lt $Script:AppCatalog.Count } | Select-Object -Unique
    }

    if (-not $indices -or $indices.Count -eq 0) {
        Write-Host "`n[X] No valid apps selected." -ForegroundColor $Script:Colors.Error
        Wait-ForUser
        return
    }

    $selectedApps = $indices | ForEach-Object { $Script:AppCatalog[$_] }
    Write-Host "`nWill install: $(($selectedApps | ForEach-Object { $_.Name }) -join ', ')" -ForegroundColor $Script:Colors.Highlight

    if (-not (Confirm-Action -Message "Proceed with installation?" -DefaultYes)) { return }

    Write-Log "Installing apps via winget: $(($selectedApps | ForEach-Object { $_.Id }) -join ', ')" -Level Info -Category "AppManager"

    $steps = $selectedApps | ForEach-Object {
        $app = $_
        @{
            Name   = "Installing $($app.Name)"
            Action = {
                $result = winget install --id $app.Id -e --silent --accept-source-agreements --accept-package-agreements 2>&1
                if ($LASTEXITCODE -ne 0) { throw "winget exited with code $LASTEXITCODE" }
            }.GetNewClosure()
        }
    }

    Invoke-TweakSequence -Title "App Manager - Install" -Steps $steps -Category "AppManager" | Out-Null
    Wait-ForUser
}

function Global:Show-AppUninstaller {
    Write-Host "`n[APP MANAGER - UNINSTALL]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Test-WingetAvailable)) { Wait-ForUser; return }

    Write-Host "Listing installed packages (this can take a few seconds)..." -ForegroundColor $Script:Colors.Info
    $rawList = winget list --accept-source-agreements 2>&1

    # winget's table output uses runs of 2+ spaces as column separators; the
    # header row itself is followed by a line of dashes we use as the anchor.
    $separatorIndex = ($rawList | Select-String -Pattern '^-+\s*$' | Select-Object -First 1).LineNumber
    if (-not $separatorIndex) {
        Write-Host "`n[X] Could not parse winget's package list." -ForegroundColor $Script:Colors.Error
        Wait-ForUser
        return
    }

    $installed = @()
    foreach ($line in ($rawList | Select-Object -Skip $separatorIndex)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $cols = $line -split '\s{2,}'
        if ($cols.Count -ge 2) {
            $installed += [PSCustomObject]@{ Name = $cols[0].Trim(); Id = $cols[1].Trim() }
        }
    }

    if ($installed.Count -eq 0) {
        Write-Host "`n[!] No packages found (or winget's output format could not be parsed)." -ForegroundColor $Script:Colors.Warning
        Wait-ForUser
        return
    }

    Write-Host "`nInstalled packages:" -ForegroundColor $Script:Colors.Info
    for ($i = 0; $i -lt $installed.Count; $i++) {
        Write-Host ("  {0,3}. {1} [{2}]" -f ($i + 1), $installed[$i].Name, $installed[$i].Id) -ForegroundColor White
    }
    Write-Host ""
    $selection = Read-Host "Select apps to UNINSTALL, comma-separated (0 to cancel)"

    if ([string]::IsNullOrWhiteSpace($selection) -or $selection -eq '0') { return }

    $indices = $selection -split ',' | ForEach-Object {
        $n = 0
        if ([int]::TryParse($_.Trim(), [ref]$n)) { $n - 1 }
    } | Where-Object { $_ -ge 0 -and $_ -lt $installed.Count } | Select-Object -Unique

    if (-not $indices -or $indices.Count -eq 0) {
        Write-Host "`n[X] No valid apps selected." -ForegroundColor $Script:Colors.Error
        Wait-ForUser
        return
    }

    $selectedApps = $indices | ForEach-Object { $installed[$_] }
    Write-Host "`n[!]  Will UNINSTALL: $(($selectedApps | ForEach-Object { $_.Name }) -join ', ')" -ForegroundColor $Script:Colors.Warning

    if (-not (Confirm-Action -Message "Proceed with uninstallation?")) { return }

    $steps = $selectedApps | ForEach-Object {
        $app = $_
        @{
            Name   = "Uninstalling $($app.Name)"
            Action = {
                $result = winget uninstall --id $app.Id -e --silent 2>&1
                if ($LASTEXITCODE -ne 0) { throw "winget exited with code $LASTEXITCODE" }
            }.GetNewClosure()
        }
    }

    Invoke-TweakSequence -Title "App Manager - Uninstall" -Steps $steps -Category "AppManager" | Out-Null
    Wait-ForUser
}

function Global:Invoke-WingetUpgradeAll {
    Write-Host "`n[UPDATE ALL APPS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    if (-not (Test-WingetAvailable)) { Wait-ForUser; return }

    if (-not (Confirm-Action -Message "Upgrade every app winget can update?" -DefaultYes)) { return }

    Write-Log "Running winget upgrade --all" -Level Info -Category "AppManager"
    Write-Host "`nRunning winget upgrade --all (winget shows its own per-app progress)...`n" -ForegroundColor $Script:Colors.Info

    winget upgrade --all --accept-source-agreements --accept-package-agreements

    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n[OK] All available upgrades applied!" -ForegroundColor $Script:Colors.Success
        Write-Log "winget upgrade --all completed successfully" -Level Success -Category "AppManager"
    }
    else {
        Write-Host "`n[!] winget exited with code $LASTEXITCODE (some packages may need manual attention)." -ForegroundColor $Script:Colors.Warning
        Write-Log "winget upgrade --all exited with code $LASTEXITCODE" -Level Warning -Category "AppManager"
    }

    Wait-ForUser
}

#endregion

#region Ultimate Performance Power Plan

function Global:Enable-UltimatePerformancePlan {
    Write-Host "`n[ULTIMATE PERFORMANCE POWER PLAN]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Surfaces and activates Windows' hidden 'Ultimate Performance' power" -ForegroundColor $Script:Colors.Info
    Write-Host "plan - more aggressive than 'High performance', disables most power" -ForegroundColor $Script:Colors.Info
    Write-Host "saving/parking so hardware stays at max clocks. Uses more power/heat" -ForegroundColor $Script:Colors.Info
    Write-Host "in exchange - best on desktops or plugged-in laptops." -ForegroundColor $Script:Colors.Info

    if (-not (Confirm-Action -Message "Enable and activate Ultimate Performance?" -DefaultYes)) { return }

    Write-Log "Enabling Ultimate Performance power plan" -Level Info -Category "Power"

    $steps = @(
        @{
            Name   = "Surfacing the Ultimate Performance scheme"
            Action = {
                $existing = powercfg -l | Select-String "Ultimate Performance"
                if (-not $existing) {
                    # e9a42b02-d5df-448d-aa00-03f14749eb61 is Microsoft's documented
                    # hidden template GUID for this scheme on Windows 10/11.
                    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
                }
            }
        }
        @{
            Name   = "Activating Ultimate Performance"
            Action = {
                $scheme = powercfg -l | Select-String "Ultimate Performance" | Select-Object -First 1
                if ($scheme -and $scheme -match '([0-9a-fA-F-]{36})') {
                    powercfg -setactive $matches[1] | Out-Null
                }
                else {
                    throw "Could not locate the Ultimate Performance scheme GUID after creating it"
                }
            }
        }
    )

    Invoke-TweakSequence -Title "Ultimate Performance Power Plan" -Steps $steps -Category "Power" | Out-Null

    Write-Host "`n[OK] Ultimate Performance is now active!" -ForegroundColor $Script:Colors.Success
    Wait-ForUser
}

#endregion

#region Classic Context Menu (Windows 11)

function Global:Set-ClassicContextMenu {
    Write-Host "`n[CLASSIC RIGHT-CLICK CONTEXT MENU]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Windows 11 hides most right-click options behind 'Show more options'." -ForegroundColor $Script:Colors.Info
    Write-Host "This restores the full Windows 10-style menu directly." -ForegroundColor $Script:Colors.Info
    Write-Host ""
    Write-Host "  1. Enable classic (full) context menu" -ForegroundColor White
    Write-Host "  2. Restore default Windows 11 context menu" -ForegroundColor White
    Write-Host "  0. Cancel" -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "Select an option"
    if ($choice -eq '0' -or [string]::IsNullOrWhiteSpace($choice)) { return }
    if ($choice -ne '1' -and $choice -ne '2') {
        Write-Host "`n[X] Invalid selection." -ForegroundColor $Script:Colors.Error
        Start-Sleep -Seconds 1
        return
    }

    Write-Log "Setting classic context menu: option $choice" -Level Info -Category "Explorer"

    $steps = if ($choice -eq '1') {
        @(
            @{
                Name   = "Restoring the full Windows 10-style context menu"
                Action = {
                    $path = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
                    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                    Set-ItemProperty -Path $path -Name "(Default)" -Value "" -Type String
                }
            }
        )
    }
    else {
        @(
            @{
                Name   = "Restoring the default Windows 11 context menu"
                Action = {
                    $path = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
                    if (Test-Path $path) { Remove-Item -Path $path -Recurse -Force }
                }
            }
        )
    }

    Invoke-TweakSequence -Title "Context Menu" -Steps $steps -Category "Explorer" | Out-Null

    if (Confirm-Action -Message "Restart Windows Explorer now to apply?" -DefaultYes) {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        Start-Process explorer
    }
    else {
        Write-Host "  Sign out or restart Explorer manually for the change to take effect." -ForegroundColor $Script:Colors.Warning
    }

    Wait-ForUser
}

#endregion

#region Taskbar Alignment (Windows 11)

function Global:Set-TaskbarAlignment {
    Write-Host "`n[TASKBAR ALIGNMENT]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "  1. Left-align taskbar icons (classic Windows 10 style)" -ForegroundColor White
    Write-Host "  2. Center-align taskbar icons (Windows 11 default)" -ForegroundColor White
    Write-Host "  0. Cancel" -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "Select an option"
    if ($choice -eq '0' -or [string]::IsNullOrWhiteSpace($choice)) { return }
    if ($choice -ne '1' -and $choice -ne '2') {
        Write-Host "`n[X] Invalid selection." -ForegroundColor $Script:Colors.Error
        Start-Sleep -Seconds 1
        return
    }

    $value = if ($choice -eq '1') { 0 } else { 1 }
    $label = if ($choice -eq '1') { "left" } else { "center" }

    Write-Log "Setting taskbar alignment to $label" -Level Info -Category "Explorer"

    $steps = @(
        @{
            Name   = "Setting taskbar alignment to $label"
            Action = {
                $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Backup-RegistryValue -Path $path -Name "TaskbarAl"
                Set-ItemProperty -Path $path -Name "TaskbarAl" -Value $value -Type DWord
            }.GetNewClosure()
        }
    )

    Invoke-TweakSequence -Title "Taskbar Alignment" -Steps $steps -Category "Explorer" | Out-Null

    Write-Host "`n[OK] Taskbar set to $label alignment. Sign out or restart Explorer to see it." -ForegroundColor $Script:Colors.Success
    if (Confirm-Action -Message "Restart Windows Explorer now?" -DefaultYes) {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        Start-Process explorer
    }
    Wait-ForUser
}

#endregion

#region Hosts File Ad-Blocking

# A deliberately small, well-known set of ad/telemetry domains, embedded
# directly rather than downloaded from the internet at runtime - this keeps
# the tweak reliable offline and avoids trusting a remote list unreviewed.
$Script:HostsBlockDomains = @(
    "ads.microsoft.com", "adnexus.net", "adsystem.com", "doubleclick.net",
    "googleadservices.com", "googlesyndication.com", "adservice.google.com",
    "ads.yahoo.com", "advertising.com", "analytics.twitter.com",
    "telemetry.microsoft.com", "vortex.data.microsoft.com", "watson.telemetry.microsoft.com",
    "settings-win.data.microsoft.com", "browser.events.data.msn.com"
)

function Global:Set-HostsAdBlock {
    Write-Host "`n[HOSTS FILE AD-BLOCKING]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    Write-Host "  1. Enable ad/telemetry blocking ($($Script:HostsBlockDomains.Count) domains)" -ForegroundColor White
    Write-Host "  2. Restore original hosts file (undo)" -ForegroundColor White
    Write-Host "  0. Cancel" -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "Select an option"
    if ($choice -eq '0' -or [string]::IsNullOrWhiteSpace($choice)) { return }

    if ($choice -eq '1') {
        if (-not (Confirm-Action -Message "Add $($Script:HostsBlockDomains.Count) ad/telemetry domains to the hosts file?" -DefaultYes)) { return }

        Write-Log "Enabling hosts-based ad blocking" -Level Info -Category "Privacy"

        $steps = @(
            @{
                Name   = "Backing up the current hosts file"
                Action = {
                    $backupPath = "$PSScriptRoot\hosts_original_backup.txt"
                    if (-not (Test-Path $backupPath)) {
                        Copy-Item -Path $hostsPath -Destination $backupPath -Force
                    }
                }.GetNewClosure()
            }
            @{
                Name   = "Appending ad/telemetry block entries"
                Action = {
                    $existing = Get-Content -Path $hostsPath -Raw -ErrorAction SilentlyContinue
                    if ($existing -notmatch '# Wethereal Ad-Block Start') {
                        $block = "`n# Wethereal Ad-Block Start`n"
                        $block += ($Script:HostsBlockDomains | ForEach-Object { "0.0.0.0 $_" }) -join "`n"
                        $block += "`n# Wethereal Ad-Block End`n"
                        Add-Content -Path $hostsPath -Value $block -ErrorAction Stop
                    }
                }.GetNewClosure()
            }
            @{ Name = "Flushing DNS cache"; Action = { ipconfig /flushdns | Out-Null } }
        )

        Invoke-TweakSequence -Title "Hosts Ad-Blocking" -Steps $steps -Category "Privacy" | Out-Null
        Write-Host "`n[OK] Ad-blocking entries added to hosts file!" -ForegroundColor $Script:Colors.Success
    }
    elseif ($choice -eq '2') {
        $backupPath = "$PSScriptRoot\hosts_original_backup.txt"
        if (-not (Test-Path $backupPath)) {
            Write-Host "`n[!] No hosts backup found - nothing to restore." -ForegroundColor $Script:Colors.Warning
            Wait-ForUser
            return
        }
        if (-not (Confirm-Action -Message "Restore the original hosts file?" -DefaultYes)) { return }

        $steps = @(
            @{ Name = "Restoring original hosts file"; Action = { Copy-Item -Path $backupPath -Destination $hostsPath -Force }.GetNewClosure() }
            @{ Name = "Flushing DNS cache"; Action = { ipconfig /flushdns | Out-Null } }
        )
        Invoke-TweakSequence -Title "Hosts File Restore" -Steps $steps -Category "Privacy" | Out-Null
        Write-Host "`n[OK] Original hosts file restored!" -ForegroundColor $Script:Colors.Success
    }
    else {
        Write-Host "`n[X] Invalid selection." -ForegroundColor $Script:Colors.Error
        Start-Sleep -Seconds 1
        return
    }

    Wait-ForUser
}

#endregion

#region Quick Tweak Checklist

function Global:Show-TweakChecklist {
    Write-Host "`n[QUICK TWEAK CHECKLIST]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Pick any combination of quick, independent tweaks and apply them all" -ForegroundColor $Script:Colors.Info
    Write-Host "at once, in a single progress bar - instead of hunting through menus." -ForegroundColor $Script:Colors.Info
    Write-Host ""

    $checklist = @(
        @{ Name = "Block Windows telemetry"; Action = { Block-TelemetryAdvanced } }
        @{ Name = "Disable Xbox Game Bar auto-launch"; Action = { $p = "HKCU:\Software\Microsoft\GameBar"; if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }; Backup-RegistryValue -Path $p -Name "AllowAutoGameMode"; Set-ItemProperty -Path $p -Name "AllowAutoGameMode" -Value 0 -Type DWord } }
        @{ Name = "Show file extensions in Explorer"; Action = { $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Backup-RegistryValue -Path $p -Name "HideFileExt"; Set-ItemProperty -Path $p -Name "HideFileExt" -Value 0 -Type DWord } }
        @{ Name = "Enable Dark Mode (apps + system)"; Action = { $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }; Backup-RegistryValue -Path $p -Name "AppsUseLightTheme"; Set-ItemProperty -Path $p -Name "AppsUseLightTheme" -Value 0 -Type DWord; Backup-RegistryValue -Path $p -Name "SystemUsesLightTheme"; Set-ItemProperty -Path $p -Name "SystemUsesLightTheme" -Value 0 -Type DWord } }
        @{ Name = "Disable Cortana"; Action = { $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }; Backup-RegistryValue -Path $p -Name "AllowCortana"; Set-ItemProperty -Path $p -Name "AllowCortana" -Value 0 -Type DWord } }
        @{ Name = "Hide Widgets icon (Windows 11)"; Action = { $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Backup-RegistryValue -Path $p -Name "TaskbarDa"; Set-ItemProperty -Path $p -Name "TaskbarDa" -Value 0 -Type DWord } }
        @{ Name = "Hide Chat/Teams icon (Windows 11)"; Action = { $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Backup-RegistryValue -Path $p -Name "TaskbarMn"; Set-ItemProperty -Path $p -Name "TaskbarMn" -Value 0 -Type DWord } }
        @{ Name = "Enable Ultimate Performance power plan"; Action = { Enable-UltimatePerformancePlan } }
        @{ Name = "Clean temporary files"; Action = { Clear-TemporaryFiles } }
        @{ Name = "Flush DNS cache"; Action = { ipconfig /flushdns | Out-Null } }
        @{ Name = "Left-align taskbar icons (Windows 11)"; Action = { $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Backup-RegistryValue -Path $p -Name "TaskbarAl"; Set-ItemProperty -Path $p -Name "TaskbarAl" -Value 0 -Type DWord } }
    )

    for ($i = 0; $i -lt $checklist.Count; $i++) {
        Write-Host ("  {0,2}. {1}" -f ($i + 1), $checklist[$i].Name) -ForegroundColor White
    }
    Write-Host ""
    $selection = Read-Host "Select tweaks to apply, comma-separated (e.g. 1,4,8) or 'all' (0 to cancel)"

    if ([string]::IsNullOrWhiteSpace($selection) -or $selection -eq '0') { return }

    if ($selection.Trim() -eq 'all') {
        $indices = 0..($checklist.Count - 1)
    }
    else {
        $indices = $selection -split ',' | ForEach-Object {
            $n = 0
            if ([int]::TryParse($_.Trim(), [ref]$n)) { $n - 1 }
        } | Where-Object { $_ -ge 0 -and $_ -lt $checklist.Count } | Select-Object -Unique
    }

    if (-not $indices -or $indices.Count -eq 0) {
        Write-Host "`n[X] No valid tweaks selected." -ForegroundColor $Script:Colors.Error
        Wait-ForUser
        return
    }

    $selectedSteps = $indices | ForEach-Object { $checklist[$_] }
    Write-Log "Applying quick tweak checklist: $(($selectedSteps | ForEach-Object { $_.Name }) -join '; ')" -Level Info -Category "Checklist"

    # Some checklist actions (Block-TelemetryAdvanced, Clear-TemporaryFiles,
    # Enable-UltimatePerformancePlan) are full functions with their own
    # confirmation/pause and progress bar - suppress those so the checklist
    # really does apply everything in one uninterrupted pass.
    $Script:SkipConfirmations = $true
    $Script:SkipPauses = $true
    try {
        Invoke-TweakSequence -Title "Quick Tweak Checklist" -Steps $selectedSteps -Category "Checklist" | Out-Null
    }
    finally {
        $Script:SkipConfirmations = $false
        $Script:SkipPauses = $false
    }

    Wait-ForUser
}

#endregion

#region Backup Comparison

function Global:Compare-Backups {
    Write-Host "`n[COMPARE TWO BACKUPS]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title

    $backupFiles = Get-ChildItem -Path $PSScriptRoot -Filter "WinTweaker_Backup_*.json" | Sort-Object LastWriteTime -Descending

    if ($backupFiles.Count -lt 2) {
        Write-Host "`n[!] Need at least 2 backups to compare (found $($backupFiles.Count))." -ForegroundColor $Script:Colors.Warning
        Write-Host "  Use 'Backup Current Settings' (Category 8) to create more." -ForegroundColor $Script:Colors.Info
        Wait-ForUser
        return
    }

    Write-Host "`nAvailable backups:" -ForegroundColor $Script:Colors.Info
    for ($i = 0; $i -lt [Math]::Min($backupFiles.Count, 15); $i++) {
        Write-Host "  $($i + 1). $($backupFiles[$i].Name) - $(Get-Date $backupFiles[$i].LastWriteTime -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor White
    }
    Write-Host ""

    $firstChoice = Read-Host "Select the OLDER backup (number)"
    $secondChoice = Read-Host "Select the NEWER backup (number)"

    $i1 = 0; $i2 = 0
    if (-not [int]::TryParse($firstChoice, [ref]$i1) -or -not [int]::TryParse($secondChoice, [ref]$i2) -or
        $i1 -lt 1 -or $i1 -gt $backupFiles.Count -or $i2 -lt 1 -or $i2 -gt $backupFiles.Count) {
        Write-Host "`n[X] Invalid selection." -ForegroundColor $Script:Colors.Error
        Wait-ForUser
        return
    }

    $older = @(Get-Content -Path $backupFiles[$i1 - 1].FullName -Raw | ConvertFrom-Json)
    $newer = @(Get-Content -Path $backupFiles[$i2 - 1].FullName -Raw | ConvertFrom-Json)

    function Get-EntryKey($entry) {
        if ($entry.Type -eq 'Registry') { return "Registry|$($entry.Path)|$($entry.Name)" }
        else { return "Service|$($entry.Name)" }
    }

    $olderMap = @{}
    foreach ($e in $older) { $olderMap[(Get-EntryKey $e)] = $e }
    $newerMap = @{}
    foreach ($e in $newer) { $newerMap[(Get-EntryKey $e)] = $e }

    $addedKeys = $newerMap.Keys | Where-Object { -not $olderMap.ContainsKey($_) }
    $removedKeys = $olderMap.Keys | Where-Object { -not $newerMap.ContainsKey($_) }
    $changedKeys = $newerMap.Keys | Where-Object {
        $olderMap.ContainsKey($_) -and (
            ($newerMap[$_].Type -eq 'Registry' -and $newerMap[$_].Value -ne $olderMap[$_].Value) -or
            ($newerMap[$_].Type -eq 'Service' -and ($newerMap[$_].StartType -ne $olderMap[$_].StartType -or $newerMap[$_].Status -ne $olderMap[$_].Status))
        )
    }

    Write-Host "`n  Comparing:" -ForegroundColor $Script:Colors.Highlight
    Write-Host "    Older: $($backupFiles[$i1 - 1].Name)" -ForegroundColor DarkGray
    Write-Host "    Newer: $($backupFiles[$i2 - 1].Name)" -ForegroundColor DarkGray

    if ($addedKeys.Count -eq 0 -and $removedKeys.Count -eq 0 -and $changedKeys.Count -eq 0) {
        Write-Host "`n  [OK] No differences - both backups captured the same tracked settings." -ForegroundColor $Script:Colors.Success
    }
    else {
        if ($addedKeys.Count -gt 0) {
            Write-Host "`n  + NEWLY TRACKED ($($addedKeys.Count)):" -ForegroundColor Green
            $addedKeys | ForEach-Object { Write-Host "      $_" -ForegroundColor White }
        }
        if ($removedKeys.Count -gt 0) {
            Write-Host "`n  - NO LONGER TRACKED ($($removedKeys.Count)):" -ForegroundColor Red
            $removedKeys | ForEach-Object { Write-Host "      $_" -ForegroundColor White }
        }
        if ($changedKeys.Count -gt 0) {
            Write-Host "`n  ~ VALUE CHANGED ($($changedKeys.Count)):" -ForegroundColor Yellow
            foreach ($k in $changedKeys) {
                $o = $olderMap[$k]; $n = $newerMap[$k]
                if ($n.Type -eq 'Registry') {
                    Write-Host "      $k : '$($o.Value)' -> '$($n.Value)'" -ForegroundColor White
                }
                else {
                    Write-Host "      $k : StartType '$($o.StartType)'->'$($n.StartType)', Status '$($o.Status)'->'$($n.Status)'" -ForegroundColor White
                }
            }
        }
    }

    Write-Log "Compared backups: $($backupFiles[$i1 - 1].Name) vs $($backupFiles[$i2 - 1].Name)" -Level Info -Category "Tools"
    Wait-ForUser
}

#endregion

#region TPM & Secure Boot Check

function Global:Test-TpmSecureBoot {
    Write-Host "`n[TPM & SECURE BOOT CHECK]" -ForegroundColor $Script:Colors.Title
    Write-Host "============================================================" -ForegroundColor $Script:Colors.Title
    Write-Host "Checking Windows 11 hardware readiness requirements..." -ForegroundColor $Script:Colors.Info
    Write-Host ""

    Write-Host "  TPM (Trusted Platform Module):" -ForegroundColor $Script:Colors.Highlight
    try {
        $tpm = Get-Tpm -ErrorAction Stop
        $tpmOk = $tpm.TpmPresent -and $tpm.TpmReady
        $color = if ($tpmOk) { $Script:Colors.Success } else { $Script:Colors.Warning }
        Write-Host "    Present: $($tpm.TpmPresent) | Ready: $($tpm.TpmReady) | Enabled: $($tpm.TpmEnabled)" -ForegroundColor $color
        if ($tpmOk) {
            Write-Host "    [OK] TPM meets Windows 11 requirements" -ForegroundColor $Script:Colors.Success
        }
        else {
            Write-Host "    [!] TPM is missing, disabled, or not ready - check UEFI/BIOS settings" -ForegroundColor $Script:Colors.Warning
        }
    }
    catch {
        Write-Host "    [!] Could not query TPM status (Get-Tpm unavailable or no TPM present)" -ForegroundColor $Script:Colors.Warning
    }

    Write-Host "`n  Secure Boot:" -ForegroundColor $Script:Colors.Highlight
    try {
        $secureBoot = Confirm-SecureBootUEFI -ErrorAction Stop
        if ($secureBoot) {
            Write-Host "    [OK] Secure Boot is ENABLED" -ForegroundColor $Script:Colors.Success
        }
        else {
            Write-Host "    [!] Secure Boot is DISABLED - enable it in UEFI/BIOS for Windows 11" -ForegroundColor $Script:Colors.Warning
        }
    }
    catch {
        Write-Host "    [!] Could not determine Secure Boot status (legacy BIOS, or command unsupported)" -ForegroundColor $Script:Colors.Warning
    }

    Write-Host "`n  CPU generation / core count:" -ForegroundColor $Script:Colors.Highlight
    $hw = Get-HardwareProfile
    Write-Host "    $($hw.CPU.Name) - $($hw.CPU.Cores) cores / $($hw.CPU.Threads) threads" -ForegroundColor White
    Write-Host "    [i] Windows 11 requires an 8th-gen Intel Core / Zen 2 AMD Ryzen or newer;" -ForegroundColor DarkGray
    Write-Host "      this cannot be verified automatically - check Microsoft's CPU list." -ForegroundColor DarkGray

    Write-Log "Ran TPM & Secure Boot readiness check" -Level Info -Category "Monitoring"
    Wait-ForUser
}

#endregion

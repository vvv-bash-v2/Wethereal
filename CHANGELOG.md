# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.11.0] - 2026-08-26 - Tool completeness: CLI single-tweak mode, Doctor mode, clean uninstall, conflict scanner, 3 more languages

### Added

- **`-Tweak <Name>` CLI mode**: runs exactly one named tweak unattended, then
  exits (`.\Win-Tweaker.ps1 -Tweak Optimize-DiskIO`) - for scripted/scheduled
  use when a whole profile is more than needed. Restricted to a curated
  `$Script:CliSafeTweaks` allow-list (~50 functions across Categories 1-5, 9
  and 13, plus two read-only Pro Suite diagnostics): every entry was verified
  to have no Read-Host prompt beyond the plain y/N Confirm-Action that
  -Silent/-Tweak already bypass, so an unattended run can never hang waiting
  on input. Explicitly excludes anything with a menu/free-text prompt
  (Optimize-DNS, Enable-DnsOverHttps, Show-GameProfiles, Optimize-
  SearchIndexing, Set-ClassicContextMenu, Set-TaskbarAlignment, Set-
  HostsAdBlock, Find-ThirdPartyAdware, the game-aware watcher toggles,
  Set-WetherealLanguage) and anything destructive/high-consequence
  (Uninstall-XboxGameBar, Disable-CoreIsolation, Invoke-FullRollback,
  Invoke-WetherealUninstall) - those stay menu-only by design.
- **`-Doctor` CLI mode / Configuration Drift Check** (`Test-
  ConfigurationDrift`, Pro Suite > 7): compares every registry value and
  service Wethereal has ever recorded (the lifetime master backup's
  original, pre-Wethereal value) against its current live value. If the
  current value now matches what it was BEFORE Wethereal touched it, that
  tweak has been silently reverted - by a Windows Update, a conflicting
  tool, or a manual change back - and is reported instead of the user
  discovering it by accident. `-Doctor` runs this headlessly and exits 0
  (clean) or 1 (drift found), suitable for a scheduled health-check job.
- **Clean Uninstall Wizard** (`Invoke-WetherealUninstall`, Pro Suite > 9):
  rolls back every tracked registry/service change (like Full Rollback),
  removes every scheduled task Wethereal created (Auto Re-Apply, Game-Aware
  Update Pause, Game-Aware Notification Mute), and deletes Wethereal's own
  generated files (log, master backup, config, telemetry/language settings,
  watcher scripts, backup/report files). Does not delete the Wethereal
  script files themselves - PowerShell can't reliably delete a script that's
  actively running, so that step is left to the user (delete the folder).
- **Conflicting Optimizer Scanner** (`Find-ConflictingOptimizers`, Pro
  Suite > 8): scans installed programs for other optimization/cleaner tools
  (CCleaner, Advanced SystemCare, IObit Driver Booster, Wise Care 365, Glary
  Utilities, Auslogics BoostSpeed, System Mechanic, TuneUp Utilities, AVG
  TuneUp, Norton Utilities, Ashampoo WinOptimizer, Razer Cortex, PC Cleaner
  Pro) that write to many of the same registry keys as Wethereal - a common,
  non-obvious cause of "my changes keep reverting". These are legitimate
  tools, not malware (distinct from the existing adware scanner) - nothing
  is removed automatically, just flagged.
- **3 more languages**: French, German and Portuguese added alongside
  English/Spanish (`Set-WetherealLanguage`, Pro Suite > 6) - same 18-key
  menu/category translation set as ES, ASCII-only per the rest of the
  codebase (accents stripped: e/e, u/ue, ç/c, etc.).

## [4.10.0] - 2026-08-26 - 4 more options in Category 13: DoH, component/driver store cleanup, NAT diagnostic

### Added

- **15. Enable DNS-over-HTTPS** (`Enable-DnsOverHttps`): registers DoH
  templates for Cloudflare/Google/Quad9 via Windows 11's native `netsh dns
  add encryption`, then points active adapters at the chosen provider -
  encrypts DNS lookups end-to-end. Fails gracefully with a clear message on
  Windows 10, where the feature doesn't exist.
- **16. Clean Up Windows Component Store** (`Clear-ComponentStore`): runs
  `Dism /Online /Cleanup-Image /StartComponentCleanup` to remove superseded
  update files from WinSxS. Deliberately does not use `/ResetBase` (that
  would remove the ability to uninstall recent updates) and does not report
  a "GB freed" figure, since raw WinSxS folder size is documented by
  Microsoft as misleading due to hardlinks.
- **17. Clean Up Old Driver Packages** (`Clear-OldDriverPackages`):
  enumerates the Driver Store via `pnputil /enum-drivers`, groups packages
  by their original .inf name, and removes every version except the newest
  per group. Never passes `/force`, so `pnputil` safely skips any package
  still bound to a device instead of removing it out from under a working
  driver.
- **18. NAT / Multiplayer Connectivity Diagnostic** (`Test-
  NatConnectivity`): informational only, makes no changes. Reports the
  active network's Private/Public classification, Windows Firewall's
  default inbound action per profile, and whether the UPnP-related services
  (SSDP Discovery, UPnP Device Host) are running - the Windows-side signals
  that most often explain "strict NAT" complaints. Router-side NAT type
  isn't visible from Windows and is called out as such.
- **Apply All** (now option 19) extended to also run the two new safe,
  non-interactive cleanups (component store, old driver packages).
  DNS-over-HTTPS stays out since it needs the user's provider choice; the
  NAT diagnostic stays out as informational-only, same as the category's
  other read-only checks.

## [4.9.0] - 2026-08-26 - 7 more options in Category 13

### Added

- **8. Win32PrioritySeparation Tuning** (`Set-Win32PrioritySeparation`):
  the classic short/fixed-quantum + foreground-boost scheduler tweak
  (`0x26`) so the foreground game gets CPU time slices tuned for
  responsiveness instead of Windows' background-service-friendly default.
- **9. Disable Hibernation Entirely** (`Disable-Hibernation`): `powercfg -h
  off`, removing `hiberfil.sys` and freeing disk space roughly equal to
  installed RAM. Distinct from Disable Fast Startup (option 3) - Fast
  Startup alone can leave the hibernation file allocated since it's built
  on the same subsystem. Reports the estimated space to be freed before
  asking for confirmation.
- **10. Classic Windows Search** (`Set-ClassicWindowsSearch`): disables
  Bing web results in Start Menu search (`BingSearchEnabled`,
  `DisableSearchBoxSuggestions`), local-files-only search.
- **11. Schedule Storage Sense Auto-Cleanup** (`Set-StorageSenseSchedule`):
  configures Windows' native Storage Sense for weekly automatic cleanup of
  temp files, old Recycle Bin items and old Downloads (30+ days) -
  complements the manual Clear Temporary Files tweak with a "set once"
  schedule.
- **12. Network Bufferbloat / Latency-Under-Load Test**
  (`Test-NetworkBufferbloat`): informational only, makes no changes.
  Measures baseline ping to a public host, then measures it again while
  generating real download load, and reports the latency increase - the
  actual cause of ping spikes when something else on the network is
  downloading during a game. Best-effort: reports baseline-only if the
  load-generation download fails for any reason.
- **13. Reschedule Defender Full Scan (Off-Hours)** (`Set-
  DefenderScanSchedule`): moves the periodic full scan to 3:00 AM daily via
  `Set-MpPreference`, so it never kicks in mid-session. Real-time
  protection is completely unaffected - only the scan schedule changes.
- **14. Uninstall Xbox Game Bar & Xbox App** (`Uninstall-XboxGameBar`): the
  "nuclear" option, distinct from `Disable-GameBarOverlayPopup` (which only
  suppresses the popup while leaving apps installed) - actually removes the
  Game Bar overlay and Xbox app packages. Strong on-screen warning about
  losing Game Pass app access/cloud saves; manual opt-in only, never wired
  into Apply All.
- **Apply All** (now option 15) extended to include the five new safe,
  one-shot tweaks (Win32PrioritySeparation, hibernation removal, classic
  search, Storage Sense and Defender scheduling). The notification-mute
  watcher, GPU driver check, bufferbloat test, and Xbox uninstall remain
  intentionally excluded (opt-in/informational/destructive).

## [4.8.0] - 2026-08-26 - New Category 13: Advanced Performance & Compatibility

### Added

- **New menu category (13 of 13)**: `Modules-SuperOptimizerExtras.ps1`,
  wired into the main menu and `Main()` exactly like Categories 1 and 2 -
  each tweak is its own numbered option, plus an "Apply All" (option 8) that
  runs the safe, non-watcher tweaks with a restore point first. Everything
  after Category 12 in the main menu (Quick Actions 14-20, Advanced Tools
  21-25, Professional Tools 26-29) shifted up by one number to make room;
  the option-range prompt is now "(0-29)".
- **1. Disable CPU C-States** (`Disable-CpuCStates`): disables CPU idle
  sleep states via `powercfg` for the lowest possible wake-from-idle
  latency - the same trick used by competitive-gaming/BIOS "responsiveness"
  presets. Reversible via Undo (restores C-States to enabled).
- **2. Disable USB Selective Suspend + PCIe ASPM** (`Disable-
  UsbPcieSuspend`): stops USB devices and the PCIe bus from dropping into
  low-power link states that need to renegotiate on demand - a real source
  of micro-stutter. Reversible via Undo.
- **3. Disable Fast Startup** (`Disable-FastStartup`): turns off hybrid
  boot (`HiberbootEnabled`), preventing the classic "worked yesterday"
  staleness after an update caused by hibernating the kernel session
  instead of a full shutdown.
- **4. Check & Install Missing Prerequisites** (`Install-
  MissingPrerequisites`): detects missing VC++ 2015-2022 Redistributable
  (x86/x64, via the real Uninstall registry entries) and the legacy
  DirectX End-User Runtime (many older titles still need it even though
  DX12 ships with Windows), and offers to install exactly what's missing
  via winget / the official Microsoft installer.
- **5. Auto-Mute Notifications While Gaming** (`Set-
  GameAwareNotificationMute`): same watcher-script + 5-minute scheduled-
  task pattern as the Windows Update auto-pause, reused here to mute toast
  notifications while a detected game is running. (Toggling the real Focus
  Assist UI setting requires an undocumented, Windows-build-dependent
  binary blob with no stable schema - muting `ToastEnabled` achieves the
  same practical outcome through one simple, reliable DWORD instead.)
  Manual opt-in, like the Update auto-pause.
- **6. GPU Driver Version Check** (`Test-GpuDriverVersion`): reports the
  installed driver version/age per GPU and flags anything over ~6 months
  old, with a link to the vendor's official driver page. Deliberately does
  not scrape vendor pages to guess "the latest version" - no stable public
  API exists for that and scraping is fragile/against most vendors' ToS.
- **7. Audio Latency Tweaks** (`Optimize-AudioLatency`): disables automatic
  volume ducking during communications activity (`UserDuckingPreference`),
  and disables built-in sound-effects processing on every playback device
  that exposes the property (`PKEY_AudioEndpoint_Disable_SysFx`) - devices
  whose driver doesn't expose it are skipped individually, not treated as
  a failure.
- **8. Apply All Advanced Performance Optimizations**
  (`Invoke-AllAdvancedPerformanceOptimizations`): creates a restore point,
  then runs C-States, USB/PCIe power management, Fast Startup,
  prerequisites, and audio tweaks in sequence. The two watcher/informational
  features (notification mute, GPU driver check) are intentionally excluded
  from "Apply All" since they're opt-in background services / read-only
  checks, not one-shot tweaks - run them individually if wanted.
- Added the `Cat13` menu string in both EN and ES locales; script
  description updated from "190+ tweaks across 12 categories" to "200+
  tweaks across 13 categories".

## [4.7.0] - 2026-08-26 - Thermal/RAM diagnostics, bulk game tuning, game-aware Update pause, expanded report

### Added

- **Thermal throttling detector** (`Get-ThermalThrottleStatus` / `Test-ThermalThrottling`,
  Monitoring > 6): fast heuristic compares live CPU clock speed against its
  rated max under load; offers a definitive 20-second `powercfg /energy`
  scan on request. The fast check also feeds the HTML report.
- **Memory speed check** (`Get-MemorySpeedStatus` / `Test-MemorySpeed`,
  Monitoring > 7): flags RAM running below its rated speed (XMP/DOCP/EXPO
  not enabled in BIOS) and offers to launch Windows Memory Diagnostic.
- **Path MTU Black Hole Detection**: `Optimize-TCPIP` now enables
  `EnablePMTUBHDetect`/`EnablePMTUDiscovery` so a router silently dropping
  fragmentation-needed ICMP no longer causes random connection stalls.
- **Bulk per-game tuning** (`Register-AllInstalledGames`, Pro Gaming Tools > 8):
  applies the existing Above-Normal-CPU-priority + High-performance-GPU
  tuning to every detected installed game's main .exe in one pass, instead
  of pasting one path at a time via Per-Game Process Tuning. Shares game
  detection with the Defender-exclusions tweak via a new `Get-
  DetectedGameFolders` helper (was duplicated, now one implementation).
  Wired into Apply All Gaming Optimizations, Low-End Gaming, Gaming and
  Maximum Performance.
- **Windows Update auto-pause while gaming** (`Set-GameAwareUpdatePause`,
  Automation > 5): writes a small watcher script and a 5-minute scheduled
  task that pauses `wuauserv` the moment a detected game process starts and
  resumes it once no monitored game is running - smarter than the
  Presentation profile's fixed 7-day pause. Manual opt-in only, like the
  other scheduled-task features.
- **Explorer/taskbar cleanup**: `Tweak-FileExplorer`/Taskbar tweaks now also
  disable Windows Ink Workspace, the News and Interests/Widgets background
  service, and recently/frequently used items in File Explorer.
- **Browser performance**: `Optimize-Browsers` now forces hardware
  acceleration via policy for Edge and Chrome, and prints an informational
  audit of each browser's largest installed extensions by disk footprint
  (extensions are never removed automatically - this is a "go check these"
  pointer, not a destructive step).

### Changed - Optimization Report

- Added a **Hardware Health & Gaming Readiness** section: thermal
  throttling status, memory speed status, Path MTU Black Hole Detection
  state, and a count of detected game library folders.
- The **Settings Changed This Session** table now also lists Defender
  exclusions added this session, not just registry values and services.
- Thermal throttling and underclocked RAM now count toward the
  Optimization Score's open-issues list, same as the existing checks.

## [4.6.0] - 2026-08-26 - 10 new optimizations: latency, safety, Windows 11 privacy, smarter GUI

### Added

- **MSI Mode for GPU/NVMe interrupts** (`Enable-MSIModeInterrupts`, Pro Gaming
  Tools > 6): switches display adapters and storage controllers from legacy
  line-based interrupts to Message Signaled Interrupts, which can reduce
  input lag/micro-stutter caused by shared IRQs. Safe and reversible.
- **Core Isolation / Memory Integrity (VBS) toggle** (`Disable-CoreIsolation`,
  Pro Gaming Tools > 7): opt-in only, with an explicit on-screen security
  trade-off warning before it runs. Not wired into any automatic profile -
  deliberately manual-only given what it turns off.
- **Automatic Windows Defender exclusions for installed games**
  (`Add-DefenderGameExclusions`, Gaming menu > 9): detects every Steam
  library (parsed from `libraryfolders.vdf`, not just the default path)
  plus Epic Games, Origin, Battle.net, Riot Games, GOG Galaxy and Ubisoft
  Connect, and excludes them from real-time scanning to cut asset-streaming
  stutter. Real-time protection itself stays fully on. Wired into Apply All
  Gaming Optimizations, Low-End Gaming, and the Gaming profile.
- **Disable Windows Recall and Copilot**: added to Advanced Telemetry
  Blocking (and therefore to the Privacy profile and Apply All Privacy) -
  sets the official `DisableAIDataAnalysis` and `TurnOffWindowsCopilot`
  policies plus hides the taskbar Copilot button.
- **"Recommended for you" panel in the GUI**: a banner under the header now
  reads the detected RAM, disk type (SSD/HDD) and GPU vendor and suggests
  Low-End Gaming (under 8 GB RAM), Gaming (discrete GPU present) or Maximum
  Performance (general-purpose hardware), with a one-click "Apply
  Recommended" button that runs the same profile pipeline as the Profiles tab.

### Improved

- **SysMain/Superfetch is now SSD-aware**: it used to be disabled
  unconditionally in Windows Services Optimization, which actually hurts
  performance on HDD-only systems (Superfetch's whole point is masking HDD
  seek latency). New shared `Test-SystemDriveIsSSD` helper checks the real
  OS drive media type; SysMain is now only disabled when it's confirmed SSD/
  NVMe, and left alone otherwise. The same helper now also feeds the GUI's
  hardware-based profile recommendation.
- **Restore point before "Apply All"**: `Invoke-AllSystemOptimizations` and
  `Apply-AllGamingOptimizations` now create a system restore point first,
  matching the safety net that profiles already had - previously only
  `Invoke-OptimizationProfile` did this.
- **Temporary file cleanup now shows size BEFORE deleting**, not just after:
  scans every temp/cache location up front, prints "About to free ~X GB",
  then asks for confirmation with that number in hand instead of clearing
  blind and reporting the total afterward.
- **TRIM handling now reports actual status** instead of blindly re-running
  `fsutil behavior set` every time: queries `DisableDeleteNotify` first and
  logs whether TRIM was already enabled or had to be turned back on.
- HAGS (Hardware-Accelerated GPU Scheduling) was already implemented in
  `Optimize-GPU` - verified still correct, no changes needed.

## [4.5.0] - 2026-08-26 - Automatically suppress the Xbox Game Bar overlay popup

### Added

- New `Disable-GameBarOverlayPopup` tweak (Modules-GamingNetwork.ps1) that
  permanently kills the "Do you want to open Xbox Game Bar?" / ms-gamingoverlay
  popup that Windows shows the first time a fullscreen game (or Game DVR
  trying to broadcast) tries to invoke the Game Bar overlay. Just removing
  the Xbox Game Bar app isn't enough - Windows still tries to fire the
  ms-gamingoverlay: protocol, and with no handler registered it falls back
  to the "How do you want to open this?" chooser dialog. This tweak sets:
  - `HKCU:\Software\Microsoft\GameBar`: `ShowStartupPanel = 0`,
    `GamePanelStartupTipIndex = 3`, `UseNexusForGameBarEnabled = 0`
    (suppresses the startup/first-run tip that IS the popup).
  - `HKCU:\System\GameConfigStore`: `GameDVR_Enabled = 0`.
  - `HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR`:
    `AppCaptureEnabled = 0`, `HistoricalCaptureEnabled = 0`.
  - `HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR`: `AllowGameDVR = 0`
    - the real kill switch (Group Policy level, applied because Wethereal
    already runs elevated): stops Windows from ever trying to broadcast/
    launch the overlay again, so the popup can't come back even if Game
    Bar is reinstalled or a Windows Update resets the user-level keys.
  - Every value is captured through `Backup-RegistryValue` first, so it's
    fully covered by Undo / Restore / Full Rollback like every other tweak.
- Wired in automatically wherever a "complete" optimization run happens, so
  no extra menu or confirmation is needed - it's just always applied:
  `Invoke-AllSystemOptimizations` (System Performance > Apply All),
  `Apply-AllGamingOptimizations` (Gaming > Apply All), `Optimize-LowEndGaming`,
  `Optimize-Streaming`, and the Gaming / MaxPerformance optimization profiles.

## [4.4.4] - 2026-08-26 - CRITICAL HOTFIX: backup/undo functions unreachable from closured tweak steps

### 🐛 Bug Fixes

- Real-world run logs showed every service-disable step in "Windows
  Services Optimization" (and several other tweaks that call
  `Backup-ServiceState` / `Backup-RegistryValue` from inside a
  dynamically-built step) failing with:
  `The term 'Backup-ServiceState' is not recognized as the name of a
  cmdlet, function, script file, or operable program.`
- Root cause: several tweak functions build their `$steps` array inside a
  `ForEach-Object` loop (e.g. looping over the list of services to
  disable) and call `.GetNewClosure()` on each step's `Action` scriptblock
  so it correctly captures that iteration's loop variable (without it,
  every closure would end up disabling only the LAST service in the
  list — a real, separate bug that `GetNewClosure()` was there to
  prevent). The side effect: `GetNewClosure()` rebinds the scriptblock to
  a brand-new, isolated dynamic module session state. That new session
  state can still see PowerShell cmdlets and any truly **global**
  function, but it cannot see functions that only exist in the
  intermediate "script scope" that Win-Tweaker.ps1 and its dot-sourced
  modules were defining them in - so calls to shared helpers like
  `Backup-ServiceState`, `Backup-RegistryValue`, `Write-Log`,
  `Confirm-Action`, etc. silently failed the moment they were reached
  from inside one of these closures.
- Fixed by declaring every one of Wethereal's ~150 top-level functions
  (across `Win-Tweaker.ps1` and all 12 `Modules-*.ps1` files) with the
  `Global:` scope modifier (e.g. `function Global:Backup-ServiceState`).
  This makes them resolve correctly from literally anywhere in the
  process - including from inside a `GetNewClosure()`-bound scriptblock,
  a WPF GUI button's `Add_Click` handler, or any future closure pattern -
  without changing how any of them are called. Two genuinely private,
  nested helper functions (`Measure-QuickBenchmark`,
  `Get-EntryKey`) were intentionally left local since they're never
  called from outside their enclosing function.
- Net effect: every tweak that backs up state before changing it (which
  is most of them - this is also what powers Undo/Restore/Rollback/the
  audit report) now actually records that backup instead of throwing a
  swallowed-by-try/catch warning, across every module.

## [4.4.3] - 2026-08-25 - CRITICAL HOTFIX: permanently eliminate the mojibake/parse-error bug

### 🐛 Bug Fixes

- The "Unexpected token", "hash literal was incomplete", and "ampersand (&)
  character is not allowed" parse errors kept coming back even after the
  original UTF-8 BOM fix, because the BOM is fragile: it gets silently
  stripped by many common ways of moving a file onto a Windows machine
  (browser "Save As" from a raw GitHub view, copy-pasting into Notepad,
  some sync/download tools, some editors' "Save" action). Whenever that
  happens, Windows PowerShell 5.1 falls back to reading the file with the
  system ANSI codepage, mangles every embedded emoji into multi-byte
  mojibake, and that mojibake occasionally contains a stray `"` or `&`
  byte that breaks the parser before the script can even run.
- Root-caused and fixed for good: **every `.ps1` file in the project is now
  100% pure ASCII.** All ~200 emoji and Unicode symbols (🔒 🎮 🚀 ⚠ ✓ ✗ ═ █
  ║ etc., plus a few stray accented characters in Spanish comments) have
  been replaced with plain ASCII tags (`[LOCK]`, `[GAME]`, `[BOOST]`,
  `[!]`, `[OK]`, `[X]`, `=`, `#`, `|`, ...). Box-drawing banners/borders
  were rebuilt with `+`/`=`/`|` and re-measured so they still line up.
  Because the source is now plain ASCII, the file parses identically
  whether or not it carries a BOM, no matter how it was copied, cloned,
  downloaded, or re-saved — this entire bug class is no longer possible.
- The UTF-8 BOM itself was left in place on every file as a harmless
  extra safety net, but it is no longer load-bearing for correctness.

## [4.4.2] - 2026-08-22 - HOTFIX: GUI window too large, opened off-screen on smaller displays

### 🐛 Bug Fixes

- The GUI's default size (840×1240) was too large for smaller/laptop
  screens (1366×768 and similar) and could open partially off-screen.
  Reduced the default startup size to 700×980, and added a runtime check
  against `SystemParameters.WorkArea` (the actual visible screen area,
  excluding the taskbar) that shrinks the window further on smaller or
  scaled displays — it now always opens fully on-screen regardless of
  monitor size. Still resizable up to the full work area afterward.

## [4.4.1] - 2026-08-22 - GUI window: draggable custom title bar (WinUtil-style chrome)

### 🎉 Changes

- The GUI (`-Gui`) now uses `WindowStyle="None"` for a clean, chromeless
  window like WinUtil's, with a slim custom title bar (36px) that:
  - Is draggable — click and drag anywhere on it to move the window
    (double-click to maximize/restore)
  - Has custom minimize and close buttons (Segoe Fluent icons), with a
    red hover highlight on close matching native Windows 11 behavior
  - The window keeps a subtle 1px border outline since removing the native
    chrome also removes the OS-drawn window edge
  - Still resizable by dragging any edge (`ResizeMode="CanResize"`)

## [4.4.0] - 2026-08-22 - Pro Suite, Streaming/Presentation profiles, WinUtil-style GUI

### 🐛 Critical bug fix

- **`$Script:ConfigBackup` was declared as a hashtable (`@{}`) but every backup
  function appended to it with `+=` expecting array semantics.** On a
  Hashtable, `+=` invokes the `+` merge operator, which throws
  "Item has already been added" on the very next call once two entries share
  a key (every entry has a `Type` key) — silently breaking Restore Previous
  Settings, Undo, Export Configuration, Compare Backups and the report's
  "Settings Changed" table for everything after the FIRST tweak applied in a
  session. Fixed by initializing it as an array (`@()`). This shipped in
  4.0.0's redesign and is fixed here; anyone on 4.0.0-4.3.0 should update.

### 🎉 New: Category 12 — Pro Suite (`Modules-ProSuite.ps1`, new module)

- **⏮️ Full Rollback**: a new `Wethereal_MasterBackup.json` now accumulates
  the first-ever value of every registry/service setting Wethereal touches,
  across ALL sessions (not just the current one) — Full Rollback replays the
  whole file, undoing everything Wethereal has ever changed on the machine
- **🕵️ Third-Party Adware/Bloatware Scanner**: scans the Uninstall registry
  (not just Microsoft Store apps) for known toolbar/PUP/fake-optimizer
  patterns (Conduit, MyWebSearch, Ask Toolbar, PC Optimizer Pro, etc.) and
  lets you uninstall matches
- **💽 SSD/Disk Health Check**: reads S.M.A.R.T. reliability counters
  (temperature, SSD wear %, read/write errors, power-on hours) per physical
  disk
- **📊 Opt-in local usage telemetry**: honestly scoped — Wethereal has no
  analytics backend, so this only counts locally which tweaks you apply
  most; an optional user-supplied webhook URL can receive the same events if
  you're centralizing stats across machines you manage yourself
- **🔏 Code-signing**: generates a local self-signed code-signing
  certificate, trusts it, and signs every `.ps1` file — clearly labeled as a
  local-trust mechanism, not a substitute for a real CA-issued certificate
  for public distribution
- **🌐 EN/ES language toggle**: translates the main menu, category names and
  common prompts; individual tweak descriptions deep in each category remain
  English-only for now (full line-by-line translation of 190+ tweaks is a
  larger follow-up project, noted honestly rather than claimed as done)

### 🎉 New profiles: Streaming and Presentation/Battery

- **📡 Streaming**: frees the GPU hardware encoder from Windows' own Game
  DVR capture, mutes toast notifications, removes network throttling, High
  Performance power plan, and gives OBS Studio Above Normal CPU priority if
  installed
- **🔋 Presentation / Battery**: the inverse profile — mutes notifications,
  Balanced power plan, keeps the screen from sleeping mid-presentation,
  pauses Windows Update for a week

### 🎉 Rebuilt GUI: WinUtil-style WPF interface

- Replaced the WinForms button-launcher with a proper WPF/XAML interface
  styled after Chris Titus Tech's WinUtil: a left sidebar of tabs (Install /
  Tweaks / Profiles / Updates / Info), a searchable, checkbox-driven tweak
  list (24 curated tweaks across 6 groups) and app catalog (from the App
  Manager), and a live log + progress bar built into the window itself —
  Tweaks/Install/Profiles/Updates no longer need to alt-tab to the console
  (only the other, less-common console categories still do, and the Info
  tab says so plainly)

### 🔧 Other changes

- Main menu restructured for category 12: Quick Actions now starts at 13
  (was 12), Advanced Tools at 20 (was 19), Professional Tools at 25 (was
  24) — everything shifted by +1 to make room. Option-range prompt updated
  to `(0-28)`.

## [4.3.0] - 2026-08-22 - Pro Gaming Tools, Automation & Updates, GUI

### 🎉 New: Category 10 — Pro Gaming Tools (`Modules-ProGamingTools.ps1`, new module)

- **🔥 Overclock / Undervolt Guide**: purely informational — Wethereal never
  touches voltages/clocks directly. Detects your CPU/GPU vendor(s) and points
  you at the right official tool (AMD Ryzen Master, Intel XTU, MSI
  Afterburner) with a safe starting point for each
- **🧭 CPU/GPU Bottleneck Detector**: an ~8 second synthetic CPU load while
  sampling CPU and GPU (`\GPU Engine(*)\Utilization Percentage`) performance
  counters, with a verdict on which one is more likely limiting your FPS
- **🎯 Per-Game Process Tuning**: applies Windows' own per-executable hooks
  (Above Normal CPU priority via Image File Execution Options,
  "High performance" GPU preference) scoped to one game's `.exe` only —
  curated list includes Valorant, CS2, Fortnite, Apex Legends, League of
  Legends, Warzone, or any custom executable
- **🧹 Clean GPU Driver Reinstall**: best-effort DDU-style clean-up via
  `pnputil` (removes matched third-party driver packages) plus known driver
  cache folders — clearly labeled as best-effort, not a Safe-Mode-level DDU
  replacement, with a direct link to the vendor's official driver page after
- **📟 FPS Overlay**: detects/launches RivaTuner Statistics Server, or offers
  to install MSI Afterburner (which bundles it) via winget if missing

### 🎉 New: Category 11 — Automation & Updates (`Modules-SystemAutomation.ps1`, new module)

- **⬆️ Self-Update**: checks the GitHub repo for a newer version, backs up
  current script files, and downloads/replaces them in place
- **📈 Before/After Benchmark**: runs a quick CPU/RAM benchmark, applies a
  profile of your choice, benchmarks again, and reports the real measured
  difference — with an honest note that this is a CPU/RAM signal, not an FPS
  benchmark
- **💾 Virtual Memory / Pagefile Manager**: reports detected RAM with a sizing
  recommendation, and lets you set system-managed, a custom fixed size, or
  (with strong warnings) disable the pagefile entirely
- **⏰ Scheduled Profile Re-Apply**: registers a scheduled task to silently
  re-run a profile at logon, weekly, or event-triggered right after Windows
  Update installs updates (Event ID 19) — since Windows Update sometimes
  resets services/telemetry/tasks Wethereal had disabled

### 🎉 New: Graphical interface (`Modules-GUI.ps1`, new module, `-Gui` switch)

- `.\Win-Tweaker.ps1 -Gui` opens a WinForms quick-launch window (dark,
  PowerShell-terminal palette) with one-click buttons for all 5 profiles and
  all 11 categories. It's a launcher over the existing console functions, not
  a rebuild of every menu as native controls — category buttons bring the
  console window to the front since those still run as interactive prompts;
  profile buttons run fully from the GUI with a confirmation dialog first.
  Needs an STA PowerShell session; the tool detects and warns if it isn't one.

### 🔧 Other changes

- Main menu restructured again for categories 10-11: everything from the old
  10-25 range shifted to 12-27. Updated the two in-app text references that
  pointed at the old option numbers, and the option-range prompt to `(0-27)`.

## [4.2.0] - 2026-08-22 - Ultimate Extras, Low-End Gaming profile, silent CLI mode

### 🎉 New: Category 9 — Extras & App Manager (`Modules-UltimateExtras.ps1`, new module)

- **📦 App Manager (Install)**: curated catalog of 20+ common apps (browsers,
  7-Zip, VLC, Discord, Steam, VS Code, PowerToys, CPU-Z/GPU-Z/HWMonitor,
  runtimes, …) installed via `winget`, multi-select by number or `all`
- **🗑️ App Manager (Uninstall)**: lists every winget-managed package
  currently installed and lets you multi-select which to remove
- **⬆️ Update All Apps**: `winget upgrade --all`
- **🚀 Ultimate Performance Power Plan**: surfaces and activates Windows'
  hidden Ultimate Performance power scheme (more aggressive than "High
  performance")
- **🖱️ Classic Right-Click Context Menu**: restores the full Windows
  10-style context menu on Windows 11 (toggle on/off)
- **📌 Taskbar Alignment**: left-align or center-align taskbar icons on
  Windows 11
- **🚫 Hosts File Ad-Blocking**: appends a curated ad/telemetry domain block
  list to the hosts file, with automatic backup and a one-click restore
- **✅ Quick Tweak Checklist**: pick any combination of 10 common, safe,
  independent tweaks (telemetry, dark mode, Game Bar, Cortana, Widgets, Chat
  icon, Ultimate Performance, temp cleanup, DNS flush, taskbar alignment) and
  apply them all in one pass instead of hunting through menus
- **🔍 Compare Two Backups**: diffs two `WinTweaker_Backup_*.json` files and
  reports what was newly tracked, no longer tracked, or changed value
  between them
- **🔐 TPM & Secure Boot Check**: reports TPM presence/readiness and Secure
  Boot status for Windows 11 hardware-readiness auditing

### 🎉 New: Low-End Gaming / Max FPS profile

- 5th optimization profile (`Category 2, Option 8`, and profile picker
  option 5), purpose-built for budget/low-spec PCs. Composes the existing
  CPU/GPU/memory/visual-effects/service/network/input-lag tweaks with new
  FPS-specific ones: `SystemResponsiveness=0` (stops Windows reserving CPU
  for background tasks away from the foreground game), disabling background
  apps, hiding Widgets/Chat icons, and trimming a couple of low-value
  services. Aimed at users going from ~100 FPS to ~150-200 FPS in lighter
  titles on modest hardware.

### 🎉 New: Unattended / silent CLI mode

- `.\Win-Tweaker.ps1 -Silent -ProfileName LowEndGaming` (or any of the 5
  profile names) applies a profile with zero prompts and exits — for
  scripted/fleet deployment. `-Silent` without `-ProfileName` now fails fast
  with a clear error instead of hanging on a prompt.

### 🔧 Other changes

- Main menu restructured: category 9 ("Extras & App Manager") added after
  "Tools & Utilities"; every option from the old 9-24 range shifted to
  10-25 accordingly. Updated the two in-app text references that pointed at
  the old option numbers.
- Menu option-range prompt updated to `(0-25)`.

## [4.1.0] - 2026-08-22 - Menu renumbering & detailed HTML report

### 🎉 Changes

- **Fixed main menu numbering**: options 14 ("Restore Previous Settings") and 15
  ("View Optimization Log") were being drawn at the very bottom of the menu,
  under the "PROFESSIONAL TOOLS" section, even though their numbers belong
  right after option 13 — so the visible list jumped straight from 13 to 16.
  They're now printed in their correct numeric position, right after option
  13 in the QUICK ACTIONS block. The underlying option numbers/behavior are
  unchanged (no switch/case logic changed), only where they're displayed.
- Fixed the "Select an option" prompt on the main menu, which said
  `(0-15)` even though valid choices go up to 24
- **Optimization Report is now far more detailed** (`New-OptimizationReport`):
  - Optimization score (0-100) computed from live checks (unnecessary
    services running, telemetry blocked, visual effects, disk headroom)
  - CPU/GPU vendor badges (color-coded per vendor) from the hardware
    detection module, including every GPU on hybrid systems
  - Full disk table per fixed drive with a visual used-space bar
  - New "Settings Changed This Session" table listing every registry value
    and service Wethereal has modified, with the original (pre-change) value
    it backed up — so the report doubles as an audit trail
  - Optimization log expanded from the last 20 to the last 50 entries
  - Dynamic recommendations based on what the live analysis actually found
  - Report now shows the real running version (`$Script:Version`) instead of
    a hardcoded "2.1.0" left over from an earlier release
  - Report generation now shows its own progress bar per gathering step

## [4.0.1] - 2026-08-22 - HOTFIX: UTF-8 BOM (fixes script failing to parse on Windows PowerShell 5.1)

### 🐛 Bug Fixes

- **Critical: script failed to run at all on Windows PowerShell 5.1** with parser
  errors like `Token '’ Privacy Focused"' inesperado` and
  `No se permite usar el carácter de Y comercial (&)`. Root cause: none of the
  `.ps1` files carried a UTF-8 byte-order-mark (BOM). Windows PowerShell 5.1
  (unlike PowerShell 7/pwsh) reads a BOM-less script using the system's
  legacy ANSI code page instead of UTF-8 — on a Spanish-locale machine that's
  Windows-1252 — so every emoji (🔒, 🎮, 📊, …) in the source, which is stored
  as multi-byte UTF-8, was misdecoded byte-by-byte into mojibake. Some of
  those misdecoded bytes happened to land on `"` and `&`, which broke string
  literals and tripped the "reserved for future use" `&` operator error.
  - Fix: added a UTF-8 BOM (`EF BB BF`) to the start of all 8 `.ps1` files.
    File content is otherwise unchanged; this only changes how the very first
    bytes tell the interpreter which encoding to use.

## [4.0.0] - 2026-08-22 - ADAPTIVE HARDWARE EDITION: AMD Support & Live Progress

### 🎉 New Features

- **🧠 Automatic hardware platform detection** (`Modules-HardwareDetection.ps1`, new module)
  - Detects CPU vendor (Intel / AMD) via `Win32_Processor`, including Intel hybrid
    P-core/E-core CPUs
  - Detects **every** installed GPU, not just the first — correctly represents
    hybrid laptops (e.g. Intel iGPU + AMD/NVIDIA dGPU)
  - Startup banner and system-info bar now show the detected platform (e.g.
    "AMD CPU / hybrid GPU setup (AMD + NVIDIA)")
  - Every optimization category adapts automatically: no more manual vendor
    selection required
- **🔴 Full AMD CPU (Ryzen) optimization pass** (`Optimize-AMDCPU`) — power plan
  selection, core-parking/CCX scheduling, AMD Ryzen power scheme detection,
  performance boost policy
- **🔵 Full Intel CPU optimization pass** (`Optimize-IntelCPU`) — Speed Shift
  (HWP), P-core scheduling bias on hybrid CPUs, performance boost policy
- **🔴 Expanded AMD Radeon GPU optimizations** (`Optimize-AMD`) — now on par with
  the NVIDIA/Intel GPU passes: telemetry, ReLive, Radeon Anti-Lag, overlay
  control
- **📊 Live progress bars on every optimization step** — a shared
  `Invoke-TweakSequence` engine now drives every tweak function with a native
  `Write-Progress` bar plus a per-step checklist, so the user always sees
  exactly what is being applied, in real time
- **↩️ Working Undo/Restore/Export** — these were previously stub menu items
  ("coming in next update"); Undo now actually reverts the last change,
  Restore actually replays a backup file's registry/service entries, and
  Export actually writes a JSON snapshot

### 🐛 Bug Fixes

- Removed `Export-ModuleMember -Function *` from all six dot-sourced modules —
  it threw a non-terminating error on every launch because these files are
  loaded with `. $moduleFile`, not `Import-Module`
- Fixed `Invoke-OptimizationProfile` calling non-existent functions
  (`Clean-TemporaryFiles`, `Configure-WindowsFeaturesPrivacy`,
  `Configure-CameraMicrophonePrivacy`, `Configure-NetworkPrivacy`) that would
  abort the Work/Privacy profiles partway through
  (correct names: `Clear-TemporaryFiles`, `Set-WindowsFeaturesPrivacy`, etc.)
  - Profiles also now apply silently instead of prompting for confirmation and
    a keypress after every single sub-tweak
- Fixed `Test-NetworkSpeed`'s DNS check always reporting "Failed" — the result
  variable was set inside a `Measure-Command` scriptblock, which runs in its
  own child scope
  - Fixed the Windows Update "pause" messages in `Set-WindowsUpdates`
  printing literal text like `.AddDays(7).ToString('yyyy-MM-dd')` instead of
  the actual resume date (broken string-interpolation subexpression)
- Fixed `Get-WmiObject` (deprecated, unavailable on PowerShell 7+) in
  `Optimize-NetworkAdapter`; replaced with `Get-CimInstance`/`Set-CimInstance`
- Tightened the bloatware-detection pattern list — it previously matched bare
  words like `Netflix`, `Facebook`, `Farm`, `Candy`, `Bubble` against every
  installed app name, risking removal of apps the user actually wanted to
  keep; patterns are now scoped to real package identifiers
- Fixed a backup/restore correctness bug where re-touching the same registry
  value or service twice in one session overwrote the backed-up "original"
  value with an already-modified one, making restore a no-op
- Removed dead-end duplicate menu entries (`Show-ProfilesMenu` stub in the
  Tools menu now correctly opens the real profile picker)

## [3.5.0] - 2025-12-18 - PROFESSIONAL EDITION: Ultimate Diagnostic Tools

### 🎉 New Professional Features

- **🏥 Comprehensive System Health Check**: 10-point diagnostic system

  - Disk health analysis with space warnings
  - Memory usage monitoring
  - Windows Update status verification
  - Antivirus protection check
  - System uptime tracking
  - Event log error analysis
  - Startup program count
  - Temporary files size check
  - Network connectivity test
  - Health score calculation (0-100)
  - Automated recommendations

- **📝 Registry Optimizer**: Safe registry performance tweaks

  - Menu show delay reduction
  - Aero Shake disable
  - Snap Assist optimization
  - Taskbar animations disable
  - Icon cache optimization
  - Thumbnail cache tuning
  - Windows Search optimization
  - Cortana disable
  - Automatic backup before changes

- **⚙️ Intelligent Service Optimizer**: Smart service management

  - Identifies safe-to-disable services
  - Automatic service state backup
  - Telemetry service removal
  - Xbox services optimization
  - Superfetch/SysMain control
  - Windows Search management
  - Detailed optimization reporting

- **🔄 Windows Update Manager**: Complete update control
  - Pause updates (7 or 30 days)
  - Resume updates
  - Check for updates
  - Disable/Enable automatic updates
  - Update service management
  - Safety warnings for critical changes

### Enhanced

- **Menu System**: Expanded from 20 to 24 options
- **Professional Tools Section**: New dedicated category
- **Module Architecture**: Added 7th module (`Modules-FinalEnhancements.ps1`)
- **Optimization Count**: Increased to 135+
- **Health Monitoring**: Comprehensive 10-point system check

### Technical

- Added `Modules-FinalEnhancements.ps1` with 500+ lines
- Implemented health scoring algorithm
- Enhanced service backup system
- Registry optimization with safety checks
- Total codebase now exceeds 5,500 lines

### Statistics

- **Total Optimizations**: 135+
- **Menu Options**: 24
- **Functions**: 90+
- **Module Files**: 7
- **Lines of Code**: 5,500+

## [3.0.0] - 2025-12-18 - MAJOR RELEASE: ADVANCED TOOLS EDITION

### 🎉 Major New Features

- **📊 Real-Time Performance Dashboard**: Live monitoring of CPU, Memory, Disk, and Network

  - 30-second continuous monitoring
  - Color-coded performance indicators
  - Process count tracking
  - Auto-refresh every second

- **🌐 Network Speed Test**: Comprehensive network diagnostics

  - DNS resolution testing
  - Ping/latency measurement
  - Download speed estimation
  - Network adapter information

- **🚀 Startup Impact Analyzer**: Advanced startup program analysis

  - Scans Registry Run keys
  - Checks Startup folders
  - Analyzes Task Scheduler logon triggers
  - Impact classification (High/Medium/Low)
  - Detailed recommendations

- **🌡️ System Temperature Monitor**: Hardware temperature tracking

  - WMI thermal zone detection
  - CPU load alternative metrics
  - Temperature warnings (color-coded)

- **🔄 One-Click Restore**: Simplified backup restoration

  - Lists last 10 backups
  - One-click restore functionality
  - Automatic undo stack restoration

- **💾 Automatic Backup System**: Enhanced backup capabilities
  - Auto-backup before major changes
  - JSON-based backup format
  - Timestamp-based file naming
  - Comprehensive system state capture

### Enhanced

- **Menu System**: Expanded from 15 to 20 options
- **Advanced Tools Section**: New dedicated section in main menu
- **Module Architecture**: Added 6th module (`Modules-Advanced.ps1`)
- **Error Handling**: Improved global error handling and logging
- **Exit Messages**: Updated to reflect Wethereal branding

### Technical

- Added `Modules-Advanced.ps1` with 400+ lines of new code
- Implemented automatic backup directory creation
- Enhanced error logging with dedicated error log file
- Improved module loading system
- Total codebase now exceeds 5,000 lines

### Statistics

- **Total Optimizations**: 130+
- **Menu Options**: 20
- **Functions**: 80+
- **Module Files**: 6
- **Lines of Code**: 5,000+

## [2.5.0] - 2025-12-18 - WETHEREAL EDITION

### Changed

- **🎨 Simplified ASCII Art**: Clean WINTHEREAL-only display
  - Removed extra "L-REAL" line per user request
  - Just "WINTHEREAL" in large ASCII art
  - Cleaner, more professional appearance
  - Consistent across startup and headers

### Enhanced

- **Visual Clarity**: Simplified branding
  - Single-line WINTHEREAL logo
  - Better readability
  - Professional minimalist design

### Technical

- Simplified ASCII art in `Show-Header` function
- Updated startup animation to match
- Removed redundant ASCII elements
- Optimized display formatting

## [2.3.0] - 2025-12-18 - WINTHEREAL PERFECTED

### Fixed

- **🎨 Corrected ASCII Art**: Fixed WINTHEREAL spelling
  - Now properly displays "WINTHEREAL" (WIN + THE + REAL)
  - Added second line with "L-REAL" to complete the name
  - Perfectly centered and aligned
  - Consistent across startup animation and all headers

### Enhanced

- **Visual Polish**: Improved ASCII art presentation
  - Better spacing and alignment
  - Enhanced visual hierarchy
  - Cleaner borders and separators
  - Professional typography

### Technical

- Updated ASCII art in `Show-Header` function
- Updated startup animation ASCII art
- Improved text padding and alignment
- Enhanced system info display formatting

## [2.2.0] - 2025-12-18 - WINTHEREAL EDITION

### Added

- **🎨 WinThereal ASCII Art Branding**: Professional ASCII art banner
  - Large "WINTHEREAL" ASCII logo in cyan
  - Displayed on startup and all menu screens
  - Live system information bar (CPU, GPU, RAM)
  - GPU vendor detection displayed in header
- **✨ Startup Animation**: Professional loading sequence
  - Animated initialization steps
  - Module loading progress
  - System configuration detection
  - GPU vendor scanning with detection display
  - "Press any key to continue" prompt
- **📊 Enhanced Header Display**: Live system stats
  - Real-time CPU information
  - GPU model with vendor badge (NVIDIA/AMD/Intel)
  - RAM capacity display
  - Automatic text truncation for long names

### Enhanced

- **Branding**: Renamed to "WinThereal" for professional identity
- **User Experience**: Polished startup sequence
- **Visual Design**: Cyan-themed professional interface
- **System Detection**: GPU vendor shown on every screen

### Technical

- Updated ASCII art rendering
- Added startup animation sequence
- Enhanced header function with live data
- Improved error handling for system info display

## [2.1.0] - 2025-12-18 - ENHANCED EDITION

### Added

- **🤖 Automated Profile System**: One-click optimization profiles
  - Gaming Profile: Applies all gaming-related optimizations
  - Work Profile: Balanced optimizations for productivity
  - Max Performance Profile: Applies ALL available optimizations
  - Privacy Profile: Maximum privacy and security tweaks
  - Auto-creates restore point before applying
  - Optional automatic restart after profile application
- **🎮 GPU-Specific Optimizations**: Vendor-specific tweaks
  - Auto-detects NVIDIA, AMD, or Intel GPU
  - NVIDIA: Disables telemetry services, optimizes power management
  - AMD: Disables user experience program, optimizes settings
  - Intel: Optimizes Intel graphics settings
- **🔍 System Analysis & Recommendations**: Pre-optimization analysis
  - Scans for unnecessary services, low disk space, high startup programs
  - Analyzes visual effects, telemetry status
  - Generates optimization score (0-100)
  - Provides specific recommendations with menu references
- **📈 Advanced HTML Reporting**: Professional optimization reports
  - Generates comprehensive HTML reports
  - Includes system information, optimization log summary
  - Beautiful responsive design with tables and styling
  - Auto-opens in browser after generation
- **🗑️ Enhanced Bloatware Detection**: Smart app removal
  - Scans for 30+ bloatware patterns
  - Shows app size and install date
  - Interactive selection for removal
  - Detects manufacturer bloatware and unused apps

### Enhanced

- **Main Menu**: Expanded from 11 to 15 options
- **Profile System**: Fully functional automated application
- **Logging**: Enhanced with better categorization
- **Error Handling**: Improved throughout all modules
- **User Experience**: Better prompts and confirmations

### Technical

- Added `Modules-Enhancements.ps1` (5th module file)
- New functions: 10+ enhancement functions
- Total code: 3,500+ → 4,200+ lines
- Module files: 4 → 5 files

## [2.0.0] - 2025-12-18 - ULTIMATE EDITION

### Added

- **MAJOR UPGRADE**: Expanded from 16 to 50+ optimization options
- **8 Category Menu System**: Organized optimizations into logical categories
- **Gaming & Graphics Category** (7 options):
  - Gaming mode optimizations
  - Input lag reduction (mouse/keyboard)
  - Network gaming tweaks
  - Fullscreen optimizations
  - Audio optimizations for gaming
  - Frame rate optimizations
- **Network & Internet Category** (6 options):
  - Advanced TCP/IP tweaks
  - DNS optimizations (Google, Cloudflare, Quad9)
  - Network adapter power management
  - QoS configuration
  - Browser optimizations
- **Privacy & Security Category** (8 options):
  - Advanced telemetry blocking
  - Tracking & ads disabling
  - Bloatware removal (30+ pre-installed apps)
  - Windows features privacy controls
  - Camera & microphone privacy
  - Network privacy settings
  - Security hardening (DEP, SMBv1 disable)
- **Cleanup & Maintenance Category** (8 options):
  - Advanced disk cleanup (Windows.old, delivery optimization)
  - Event log management
  - Scheduled tasks optimization
  - Context menu cleanup
  - Search indexing optimization
- **Advanced Tweaks Category** (8 options):
  - Boot & shutdown optimization
  - File Explorer tweaks (show extensions, hidden files)
  - Taskbar & start menu tweaks
  - Notification configuration
  - Windows Defender optimization
  - Font rendering & ClearType
  - Registry performance tweaks
- **Monitoring & System Info Category** (5 options):
  - System information dashboard
  - Performance benchmark
  - Resource monitor integration
  - Optimization history viewer
  - System health check
- **Tools & Utilities Category** (7 options):
  - Optimization profiles (Gaming, Work, Max Performance, Privacy)
  - Enhanced backup/restore functionality
  - Granular undo capabilities
  - Configuration export/import
- **Modular Architecture**: Separated code into module files for better organization
- **Enhanced Logging**: Added category-based logging with severity levels
- **Undo Stack**: Track all changes for granular rollback
- **Configuration Profiles**: Pre-defined optimization profiles for different use cases

### Enhanced

- **System Performance Category**: Expanded to 8 options
  - Added CPU core parking disable
  - Added GPU hardware-accelerated scheduling
  - Added advanced memory management
  - Added disk I/O optimizations
  - Added Windows Update optimizations
- **Improved UI**: Color-coded menus with emoji icons
- **Better Organization**: Logical grouping of related optimizations
- **Enhanced Safety**: More comprehensive backup before each change

### Changed

- Reorganized menu from flat 16-option list to 8-category system
- Updated version to 2.0.0 ULTIMATE EDITION
- Improved helper functions with better error handling
- Enhanced logging with categories and severity levels

### Technical

- Total lines of code: 1,088 → 3,500+ lines
- Menu options: 16 → 50+ options
- Categories: 3 → 8 categories
- Module files: 1 → 4 files (main + 3 modules)
- Functions: 19 → 60+ functions

## [1.0.0] - 2025-12-18

### Added

- Initial release of Windows Performance Tweaker
- Interactive menu-driven interface with 16 options
- Performance optimization features:
  - Windows Services optimization
  - Visual Effects optimization
  - Disk cleanup and temporary file removal
  - Network settings optimization
  - Telemetry and privacy tweaks
  - Power settings optimization
  - Startup program management
  - Storage optimization (SSD/HDD)
  - Memory optimization
  - Registry performance tweaks
  - System maintenance tools
- Safety features:
  - System restore point creation
  - Settings backup and restore functionality
  - Detailed logging system
  - Administrator privilege checking
- "Apply All Optimizations" feature for one-click optimization
- Color-coded user interface
- Comprehensive error handling
- Detailed documentation in README.md

### Security

- Requires administrator privileges for all system modifications
- Automatic backup of all modified settings
- System restore point creation before major changes

## [Unreleased]

### Planned Features

- GUI version using Windows Forms
- Scheduled optimization tasks
- Performance benchmarking before/after
- Custom optimization profiles
- Export/import optimization configurations
- Automatic update checker
- More granular control over individual tweaks
- Windows 12 compatibility (when released)

---

For more information, see [README.md](README.md)

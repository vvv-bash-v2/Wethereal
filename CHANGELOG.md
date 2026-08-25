# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

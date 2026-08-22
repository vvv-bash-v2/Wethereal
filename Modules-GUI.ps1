# Wethereal Ultimate Edition - Graphical Interface Module
# A lightweight WinForms front-end over the existing console functions —
# it does not reimplement any tweak logic, it just gives quick-launch
# buttons for profiles and categories. Live progress/output still prints
# to the console window behind it (Write-Host/Write-Progress are unchanged),
# since rebuilding every menu as native GUI controls would duplicate the
# whole tool in a second UI framework.

#region Graphical Interface

function Show-GraphicalMenu {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
        Write-Host "⚠ The GUI needs a Single-Threaded Apartment session. Relaunch with:" -ForegroundColor $Script:Colors.Warning
        Write-Host "    powershell -STA -File `"$PSCommandPath`" -Gui" -ForegroundColor White
        Write-Host "  Attempting to continue anyway — some dialogs may misbehave.`n" -ForegroundColor DarkGray
    }

    $hw = Get-HardwareProfile
    [System.Windows.Forms.Application]::EnableVisualStyles()

    # ---- Palette (matches the PowerShell-terminal aesthetic used elsewhere) ----
    $bgDark = [System.Drawing.Color]::FromArgb(255, 8, 11, 20)
    $bgPanel = [System.Drawing.Color]::FromArgb(255, 15, 20, 34)
    $bgButton = [System.Drawing.Color]::FromArgb(255, 20, 27, 46)
    $accentBlue = [System.Drawing.Color]::FromArgb(255, 83, 145, 254)
    $accentGreen = [System.Drawing.Color]::FromArgb(255, 22, 198, 12)
    $textMain = [System.Drawing.Color]::FromArgb(255, 232, 236, 244)
    $textMuted = [System.Drawing.Color]::FromArgb(255, 140, 153, 188)
    $fontMono = New-Object System.Drawing.Font("Consolas", 10)
    $fontMonoBold = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
    $fontTitle = New-Object System.Drawing.Font("Consolas", 20, [System.Drawing.FontStyle]::Bold)

    # ---- Main window ----
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Wethereal v$($Script:Version) - Graphical Console"
    $form.Size = New-Object System.Drawing.Size(980, 720)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = $bgDark
    $form.ForeColor = $textMain
    $form.Font = $fontMono
    $form.FormBorderStyle = "FixedSingle"
    $form.MaximizeBox = $false

    # ---- Header ----
    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "WETHEREAL"
    $lblTitle.Font = $fontTitle
    $lblTitle.ForeColor = $textMain
    $lblTitle.Location = New-Object System.Drawing.Point(24, 18)
    $lblTitle.AutoSize = $true
    $form.Controls.Add($lblTitle)

    $lblSub = New-Object System.Windows.Forms.Label
    $gpuText = if ($hw.GPUs.Count -eq 0) { "no GPU detected" } else { ($hw.GPUs | ForEach-Object { "$($_.Name) [$($_.Vendor)]" }) -join " + " }
    $lblSub.Text = "v$($Script:Version)  |  $($hw.CPU.Vendor) CPU  |  $gpuText"
    $lblSub.Font = $fontMono
    $lblSub.ForeColor = $textMuted
    $lblSub.Location = New-Object System.Drawing.Point(26, 54)
    $lblSub.AutoSize = $true
    $form.Controls.Add($lblSub)

    # ---- Status log ----
    $logBox = New-Object System.Windows.Forms.TextBox
    $logBox.Multiline = $true
    $logBox.ScrollBars = "Vertical"
    $logBox.ReadOnly = $true
    $logBox.BackColor = $bgPanel
    $logBox.ForeColor = $accentGreen
    $logBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $logBox.Location = New-Object System.Drawing.Point(24, 560)
    $logBox.Size = New-Object System.Drawing.Size(920, 100)
    $logBox.BorderStyle = "FixedSingle"
    $form.Controls.Add($logBox)

    function Add-GuiLog([string]$text) {
        $timestamp = Get-Date -Format 'HH:mm:ss'
        $logBox.AppendText("[$timestamp] $text`r`n")
    }

    Add-GuiLog "Ready. Live progress for actions prints in the console window behind this one."

    # ---- Helper to build a styled button ----
    function New-StyledButton([string]$text, [int]$x, [int]$y, [int]$w, [int]$h, [System.Drawing.Color]$accent) {
        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $text
        $btn.Location = New-Object System.Drawing.Point($x, $y)
        $btn.Size = New-Object System.Drawing.Size($w, $h)
        $btn.BackColor = $bgButton
        $btn.ForeColor = $textMain
        $btn.FlatStyle = "Flat"
        $btn.FlatAppearance.BorderColor = $accent
        $btn.FlatAppearance.BorderSize = 1
        $btn.Font = $fontMonoBold
        $btn.TextAlign = "MiddleCenter"
        return $btn
    }

    # ---- Quick Profiles panel ----
    $lblProfiles = New-Object System.Windows.Forms.Label
    $lblProfiles.Text = "QUICK PROFILES"
    $lblProfiles.ForeColor = $accentBlue
    $lblProfiles.Font = $fontMonoBold
    $lblProfiles.Location = New-Object System.Drawing.Point(26, 92)
    $lblProfiles.AutoSize = $true
    $form.Controls.Add($lblProfiles)

    $profileKeys = @($Script:Profiles.Keys)
    $px = 24; $py = 118
    foreach ($key in $profileKeys) {
        $prof = $Script:Profiles[$key]
        $btn = New-StyledButton -text $prof.Name -x $px -y $py -w 296 -h 46 -accent $accentGreen
        $btn.Add_Click({
                param($sender, $e)
                $chosenKey = $sender.Tag
                $profDef = $Script:Profiles[$chosenKey]
                $result = [System.Windows.Forms.MessageBox]::Show(
                    "Apply '$($profDef.Name)'?`n`n$($profDef.Description)`n`nWatch the console window for live progress.",
                    "Confirm Profile", "YesNo", "Question")
                if ($result -eq "Yes") {
                    Add-GuiLog "Applying profile: $($profDef.Name)..."
                    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
                    try {
                        $Script:SkipConfirmations = $true
                        $Script:SkipPauses = $true
                        Invoke-OptimizationProfile -ProfileName $chosenKey
                    }
                    finally {
                        $Script:SkipConfirmations = $false
                        $Script:SkipPauses = $false
                        $form.Cursor = [System.Windows.Forms.Cursors]::Default
                    }
                    Add-GuiLog "Finished: $($profDef.Name)"
                }
            })
        $btn.Tag = $key
        $form.Controls.Add($btn)
        $px += 316
        if ($px -gt 24 + 316 * 2) { $px = 24; $py += 56 }
    }

    # ---- Categories panel ----
    $catY = $py + 70
    $lblCats = New-Object System.Windows.Forms.Label
    $lblCats.Text = "CATEGORIES (opens the console menu)"
    $lblCats.ForeColor = $accentBlue
    $lblCats.Font = $fontMonoBold
    $lblCats.Location = New-Object System.Drawing.Point(26, $catY)
    $lblCats.AutoSize = $true
    $form.Controls.Add($lblCats)

    $categories = @(
        @{ Name = "System Performance"; Fn = { Show-SystemPerformanceMenu } }
        @{ Name = "Gaming & Graphics"; Fn = { Show-GamingMenu } }
        @{ Name = "Network & Internet"; Fn = { Show-NetworkMenu } }
        @{ Name = "Privacy & Security"; Fn = { Show-PrivacyMenu } }
        @{ Name = "Cleanup & Maintenance"; Fn = { Show-CleanupMenu } }
        @{ Name = "Advanced Tweaks"; Fn = { Show-AdvancedMenu } }
        @{ Name = "Monitoring"; Fn = { Show-MonitoringMenu } }
        @{ Name = "Tools & Utilities"; Fn = { Show-ToolsMenu } }
        @{ Name = "Extras & App Manager"; Fn = { Show-UltimateExtrasMenu } }
        @{ Name = "Pro Gaming Tools"; Fn = { Show-ProGamingToolsMenu } }
        @{ Name = "Automation & Updates"; Fn = { Show-AutomationMenu } }
    )

    $cx = 24; $cy = $catY + 26
    foreach ($cat in $categories) {
        $btn = New-StyledButton -text $cat.Name -x $cx -y $cy -w 296 -h 40 -accent $accentBlue
        $btn.Add_Click({
                param($sender, $e)
                Add-GuiLog "Opening console menu: $($sender.Text) — switch to the console window."
                $fn = $sender.Tag
                # Bring the console window to the foreground so Read-Host prompts are visible.
                try {
                    Add-Type -Name Win32ShowWindow -Namespace Wethereal -MemberDefinition '
                        [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
                        [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
                    ' -ErrorAction SilentlyContinue
                    $hwnd = [Wethereal.Win32ShowWindow]::GetConsoleWindow()
                    if ($hwnd -ne [IntPtr]::Zero) { [Wethereal.Win32ShowWindow]::SetForegroundWindow($hwnd) | Out-Null }
                }
                catch {}
                & $fn
                Add-GuiLog "Returned from: $($sender.Text)"
            })
        $btn.Tag = $cat.Fn
        $form.Controls.Add($btn)
        $cx += 316
        if ($cx -gt 24 + 316 * 2) { $cx = 24; $cy += 50 }
    }

    # ---- Footer ----
    $btnExit = New-Object System.Windows.Forms.Button
    $btnExit.Text = "Close GUI (return to console menu)"
    $btnExit.Location = New-Object System.Drawing.Point(24, 526)
    $btnExit.Size = New-Object System.Drawing.Size(920, 30)
    $btnExit.BackColor = $bgButton
    $btnExit.ForeColor = $textMain
    $btnExit.FlatStyle = "Flat"
    $btnExit.FlatAppearance.BorderColor = $textMuted
    $btnExit.Add_Click({ $form.Close() })
    $form.Controls.Add($btnExit)

    [System.Windows.Forms.Application]::Run($form)
}

#endregion

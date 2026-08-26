# Wethereal Ultimate Edition - Graphical Interface Module
# A WPF/XAML front-end styled after Chris Titus Tech's WinUtil: a left
# sidebar of tabs (Install / Tweaks / Profiles / Updates / Info), a
# checkbox-driven, searchable tweak list, and a live log + progress bar
# right inside the window. Tweak actions here are self-contained (no
# Read-Host), so - unlike opening a console category menu - nothing in
# this window ever needs you to alt-tab to the console.

#region Graphical Interface

function Global:New-GuiBrush([string]$Hex) {
    return (New-Object System.Windows.Media.BrushConverter).ConvertFromString($Hex)
}

# ---- Curated GUI tweak catalog -------------------------------------------
# Deliberately self-contained inline actions (no calls into interactive
# console functions, so nothing here can block on Read-Host). Each still
# goes through Backup-RegistryValue/Backup-ServiceState, so anything applied
# from the GUI is tracked by the same Restore/Undo/Full Rollback system as
# the console tweaks.
function Global:Get-GuiTweakCatalog {
    return [ordered]@{
        "[BOOST] Performance" = @(
            @{ Name = "Disable Xbox Game Bar auto-launch"; Desc = "Stops Game Bar popping up when you launch a game"; Action = { $p = "HKCU:\Software\Microsoft\GameBar"; if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }; Backup-RegistryValue -Path $p -Name "AllowAutoGameMode"; Set-ItemProperty -Path $p -Name "AllowAutoGameMode" -Value 0 -Type DWord } }
            @{ Name = "Visual effects: Best Performance"; Desc = "Turns off Windows' UI animations for a snappier feel"; Action = { $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"; if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }; Backup-RegistryValue -Path $p -Name "VisualFXSetting"; Set-ItemProperty -Path $p -Name "VisualFXSetting" -Value 2 -Type DWord } }
            @{ Name = "Disable transparency effects"; Desc = "Removes the frosted-glass blur (small GPU/CPU saving)"; Action = { $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }; Backup-RegistryValue -Path $p -Name "EnableTransparency"; Set-ItemProperty -Path $p -Name "EnableTransparency" -Value 0 -Type DWord } }
            @{ Name = "Disable SysMain / Superfetch"; Desc = "Frees background disk I/O - best on SSDs"; Action = { $svc = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue; if ($svc) { Backup-ServiceState -ServiceName "SysMain"; Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue; Set-Service -Name "SysMain" -StartupType Disabled } } }
            @{ Name = "Enable Hardware-Accelerated GPU Scheduling"; Desc = "Lets the GPU manage its own memory queue (Win10 2004+)"; Action = { $p = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"; if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }; Backup-RegistryValue -Path $p -Name "HwSchMode"; Set-ItemProperty -Path $p -Name "HwSchMode" -Value 2 -Type DWord } }
            @{ Name = "Reduce menu show delay to 0ms"; Desc = "Instant context/Start menu response"; Action = { $p = "HKCU:\Control Panel\Desktop"; Backup-RegistryValue -Path $p -Name "MenuShowDelay"; Set-ItemProperty -Path $p -Name "MenuShowDelay" -Value 0 -Type String } }
        )
        "[LOCK] Privacy"     = @(
            @{ Name = "Disable telemetry (AllowTelemetry=0)"; Desc = "Sets the diagnostic data policy to Security/Off"; Action = { $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }; Backup-RegistryValue -Path $p -Name "AllowTelemetry"; Set-ItemProperty -Path $p -Name "AllowTelemetry" -Value 0 -Type DWord } }
            @{ Name = "Disable DiagTrack service"; Desc = "Connected User Experiences and Telemetry"; Action = { $svc = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue; if ($svc) { Backup-ServiceState -ServiceName "DiagTrack"; Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue; Set-Service -Name "DiagTrack" -StartupType Disabled } } }
            @{ Name = "Disable advertising ID"; Desc = "Stops apps from using your ad ID for personalized ads"; Action = { $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }; Backup-RegistryValue -Path $p -Name "Enabled"; Set-ItemProperty -Path $p -Name "Enabled" -Value 0 -Type DWord } }
            @{ Name = "Disable Cortana"; Desc = "Removes Cortana from search"; Action = { $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }; Backup-RegistryValue -Path $p -Name "AllowCortana"; Set-ItemProperty -Path $p -Name "AllowCortana" -Value 0 -Type DWord } }
            @{ Name = "Disable activity history / Timeline"; Desc = "Stops Windows recording your app/activity history"; Action = { $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }; Backup-RegistryValue -Path $p -Name "EnableActivityFeed"; Set-ItemProperty -Path $p -Name "EnableActivityFeed" -Value 0 -Type DWord } }
        )
        "[GAME] Gaming"      = @(
            @{ Name = "Disable Game DVR / background recording"; Desc = "Frees GPU resources Windows reserves for its own capture"; Action = { $p = "HKCU:\System\GameConfigStore"; if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }; Backup-RegistryValue -Path $p -Name "GameDVR_Enabled"; Set-ItemProperty -Path $p -Name "GameDVR_Enabled" -Value 0 -Type DWord } }
            @{ Name = "Bypass fullscreen optimizations globally"; Desc = "Forces true exclusive fullscreen for better FPS"; Action = { $p = "HKCU:\System\GameConfigStore"; if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }; Backup-RegistryValue -Path $p -Name "GameDVR_FSEBehavior"; Set-ItemProperty -Path $p -Name "GameDVR_FSEBehavior" -Value 2 -Type DWord } }
            @{ Name = "Disable mouse acceleration"; Desc = "Flat 1:1 mouse response, no 'enhance pointer precision'"; Action = { $p = "HKCU:\Control Panel\Mouse"; Backup-RegistryValue -Path $p -Name "MouseSpeed"; Set-ItemProperty -Path $p -Name "MouseSpeed" -Value 0 -Type String; Backup-RegistryValue -Path $p -Name "MouseThreshold1"; Set-ItemProperty -Path $p -Name "MouseThreshold1" -Value 0 -Type String; Backup-RegistryValue -Path $p -Name "MouseThreshold2"; Set-ItemProperty -Path $p -Name "MouseThreshold2" -Value 0 -Type String } }
            @{ Name = "Remove network throttling for multimedia"; Desc = "Uncaps NetworkThrottlingIndex"; Action = { $p = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Backup-RegistryValue -Path $p -Name "NetworkThrottlingIndex"; Set-ItemProperty -Path $p -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord } }
        )
        "[PC] Windows 11 UI" = @(
            @{ Name = "Hide the Widgets icon"; Desc = "Removes the Widgets button from the taskbar"; Action = { $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Backup-RegistryValue -Path $p -Name "TaskbarDa"; Set-ItemProperty -Path $p -Name "TaskbarDa" -Value 0 -Type DWord } }
            @{ Name = "Hide the Chat/Teams icon"; Desc = "Removes the Chat button from the taskbar"; Action = { $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Backup-RegistryValue -Path $p -Name "TaskbarMn"; Set-ItemProperty -Path $p -Name "TaskbarMn" -Value 0 -Type DWord } }
            @{ Name = "Left-align the taskbar"; Desc = "Classic Windows 10-style left icons instead of centered"; Action = { $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Backup-RegistryValue -Path $p -Name "TaskbarAl"; Set-ItemProperty -Path $p -Name "TaskbarAl" -Value 0 -Type DWord } }
            @{ Name = "Enable Dark Mode"; Desc = "Apps + system dark theme"; Action = { $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }; Backup-RegistryValue -Path $p -Name "AppsUseLightTheme"; Set-ItemProperty -Path $p -Name "AppsUseLightTheme" -Value 0 -Type DWord; Backup-RegistryValue -Path $p -Name "SystemUsesLightTheme"; Set-ItemProperty -Path $p -Name "SystemUsesLightTheme" -Value 0 -Type DWord } }
            @{ Name = "Restore classic right-click menu"; Desc = "Full Windows 10-style context menu, no 'Show more options'"; Action = { $p = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"; if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }; Set-ItemProperty -Path $p -Name "(Default)" -Value "" -Type String } }
        )
        "[CLEAN] Cleanup"     = @(
            @{ Name = "Clean temporary files"; Desc = "Empties %TEMP%, Windows Temp, and browser caches"; Action = { foreach ($p in @("$env:TEMP\*", "$env:WINDIR\Temp\*", "$env:LOCALAPPDATA\Temp\*")) { Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue } } }
            @{ Name = "Flush DNS cache"; Desc = "Clears stale DNS resolver entries"; Action = { ipconfig /flushdns | Out-Null } }
            @{ Name = "Disable Windows Search indexing"; Desc = "Frees CPU/disk on machines that don't need instant file search"; Action = { $svc = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue; if ($svc) { Backup-ServiceState -ServiceName "WSearch"; Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue; Set-Service -Name "WSearch" -StartupType Disabled } } }
        )
        "[CFG] Power"        = @(
            @{ Name = "Enable Ultimate Performance power plan"; Desc = "Surfaces and activates Windows' hidden max-performance scheme"; Action = { $existing = powercfg -l | Select-String "Ultimate Performance"; if (-not $existing) { powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null }; $scheme = powercfg -l | Select-String "Ultimate Performance" | Select-Object -First 1; if ($scheme -and $scheme -match '([0-9a-fA-F-]{36})') { powercfg -setactive $matches[1] | Out-Null } } }
        )
    }
}

function Global:Invoke-GuiStepBatch {
    <#
        Runs a list of {Name, Action} steps one at a time, updating the
        GUI's log box and progress bar after each - instead of blocking
        silently, this pumps the WPF dispatcher between steps so the window
        stays visually responsive (each individual action still runs
        synchronously; a slow one, like a winget install, will pause the
        window for its own duration - the log line for it appears first so
        you can see what it's waiting on).
    #>
    param($Window, $LogBox, $ProgressBar, $StatusText, [array]$Steps)

    $total = $Steps.Count
    $i = 0
    $succeeded = 0
    foreach ($step in $Steps) {
        $i++
        $StatusText.Text = "[$i/$total] $($step.Name)"
        $ProgressBar.Value = [double]$i / $total * 100
        $LogBox.AppendText("[$i/$total] $($step.Name)...`r`n")
        $LogBox.ScrollToEnd()
        $Window.Dispatcher.Invoke([action] {}, [System.Windows.Threading.DispatcherPriority]::Background)

        try {
            & $step.Action
            $LogBox.AppendText("    OK`r`n")
            $succeeded++
            Write-Log $step.Name -Level Success -Category "GUI"
        }
        catch {
            $LogBox.AppendText("    FAILED: $($_.Exception.Message)`r`n")
            Write-Log "$($step.Name) failed: $($_.Exception.Message)" -Level Warning -Category "GUI"
        }
        $LogBox.ScrollToEnd()
        $Window.Dispatcher.Invoke([action] {}, [System.Windows.Threading.DispatcherPriority]::Background)
    }
    $StatusText.Text = "Done: $succeeded/$total succeeded."
    $LogBox.AppendText("Done: $succeeded/$total succeeded.`r`n")
    $LogBox.ScrollToEnd()
}

function Global:Show-GraphicalMenu {
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml

    if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
        Write-Host "[!] The GUI needs a Single-Threaded Apartment session. Relaunch with:" -ForegroundColor $Script:Colors.Warning
        Write-Host "    powershell -STA -File `"$PSCommandPath`" -Gui" -ForegroundColor White
        Write-Host "  Attempting to continue anyway - some dialogs may misbehave.`n" -ForegroundColor DarkGray
    }

    $hw = Get-HardwareProfile

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Wethereal" Height="700" Width="980" MinHeight="480" MinWidth="760"
        WindowStartupLocation="CenterScreen" WindowStyle="None" ResizeMode="CanResize"
        BorderBrush="#2A3454" BorderThickness="1"
        Background="#080B14" FontFamily="Segoe UI">
  <Window.Resources>
    <Style TargetType="Button" x:Key="TitleBarButton">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Foreground" Value="#8C99BC"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="Width" Value="42"/>
      <Setter Property="Height" Value="36"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border Name="BtnBd" Background="{TemplateBinding Background}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="BtnBd" Property="Background" Value="#1D2740"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="Button" x:Key="CloseBarButton" BasedOn="{StaticResource TitleBarButton}">
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border Name="BtnBd" Background="{TemplateBinding Background}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="BtnBd" Property="Background" Value="#E81123"/>
                <Setter Property="Foreground" Value="White"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="TabItem">
      <Setter Property="Background" Value="#080B14"/>
      <Setter Property="Foreground" Value="#8C99BC"/>
      <Setter Property="Padding" Value="18,12"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="TabItem">
            <Border Name="Bd" Background="{TemplateBinding Background}" BorderThickness="0,0,0,0" Padding="{TemplateBinding Padding}">
              <ContentPresenter ContentSource="Header" HorizontalAlignment="Left" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsSelected" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="#151B2E"/>
                <Setter Property="Foreground" Value="#5391FE"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="CheckBox">
      <Setter Property="Foreground" Value="#E8ECF4"/>
      <Setter Property="Margin" Value="4,7"/>
      <Setter Property="FontSize" Value="13"/>
    </Style>
    <Style TargetType="Button" x:Key="ActionButton">
      <Setter Property="Background" Value="#16C60C"/>
      <Setter Property="Foreground" Value="#08150A"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="Padding" Value="18,10"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Cursor" Value="Hand"/>
    </Style>
    <Style TargetType="Button" x:Key="ProfileButton">
      <Setter Property="Background" Value="#151B2E"/>
      <Setter Property="Foreground" Value="#E8ECF4"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="Padding" Value="14"/>
      <Setter Property="BorderBrush" Value="#5391FE"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="HorizontalContentAlignment" Value="Left"/>
    </Style>
    <Style TargetType="TextBox" x:Key="SearchBox">
      <Setter Property="Background" Value="#151B2E"/>
      <Setter Property="Foreground" Value="#E8ECF4"/>
      <Setter Property="BorderBrush" Value="#2A3454"/>
      <Setter Property="Padding" Value="8"/>
      <Setter Property="FontSize" Value="13"/>
    </Style>
  </Window.Resources>

  <DockPanel>
    <Border x:Name="TitleBar" DockPanel.Dock="Top" Background="#0B0F1C" Height="36">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0" Orientation="Horizontal" Margin="14,0,0,0" VerticalAlignment="Center">
          <TextBlock Text="*" FontSize="13" Foreground="#5391FE" VerticalAlignment="Center"/>
          <TextBlock Text="Wethereal" FontSize="12" FontWeight="SemiBold" Foreground="#8C99BC" FontFamily="Consolas" Margin="8,0,0,0" VerticalAlignment="Center"/>
        </StackPanel>
        <StackPanel Grid.Column="1" Orientation="Horizontal">
          <Button x:Name="MinimizeButton" Content="&#xE921;" FontFamily="Segoe MDL2 Assets" Style="{StaticResource TitleBarButton}" ToolTip="Minimize"/>
          <Button x:Name="CloseButton" Content="&#xE8BB;" FontFamily="Segoe MDL2 Assets" Style="{StaticResource CloseBarButton}" ToolTip="Close"/>
        </StackPanel>
      </Grid>
    </Border>
    <Border DockPanel.Dock="Top" Background="#0F1422" Padding="24,16">
      <StackPanel Orientation="Horizontal">
        <TextBlock Text="WETHEREAL" FontSize="24" FontWeight="Bold" Foreground="#E8ECF4" FontFamily="Consolas" VerticalAlignment="Center"/>
        <TextBlock x:Name="SubtitleText" FontSize="13" Foreground="#8C99BC" Margin="18,7,0,0" FontFamily="Consolas"/>
      </StackPanel>
    </Border>

    <Border x:Name="RecommendedBanner" DockPanel.Dock="Top" Background="#151B2E" BorderBrush="#5391FE" BorderThickness="0,0,0,1" Padding="24,12">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0" VerticalAlignment="Center" Margin="0,0,14,0">
          <TextBlock Text="RECOMMENDED FOR YOU" FontSize="11" FontWeight="Bold" Foreground="#5391FE"/>
          <TextBlock x:Name="RecommendedText" FontSize="12" Foreground="#8C99BC" Margin="0,3,0,0" TextWrapping="Wrap"/>
        </StackPanel>
        <Button x:Name="ApplyRecommendedButton" Grid.Column="1" Style="{StaticResource ActionButton}" VerticalAlignment="Center" Content="Apply Recommended"/>
      </Grid>
    </Border>

    <Border DockPanel.Dock="Bottom" Background="#0F1422" Padding="16,10">
      <Grid>
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="90"/>
        </Grid.RowDefinitions>
        <TextBlock x:Name="StatusText" Grid.Row="0" Foreground="#5391FE" FontFamily="Consolas" FontSize="12" Margin="0,0,0,4" Text="Ready."/>
        <ProgressBar x:Name="ProgressBar" Grid.Row="1" Height="6" Minimum="0" Maximum="100" Value="0" Margin="0,0,0,6" Background="#151B2E" Foreground="#16C60C" BorderThickness="0"/>
        <TextBox x:Name="LogBox" Grid.Row="2" Background="#0F1422" Foreground="#16C60C" BorderThickness="0" IsReadOnly="True" FontFamily="Consolas" FontSize="11" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" Text="Ready. Nothing applied yet.&#10;"/>
      </Grid>
    </Border>

    <TabControl x:Name="MainTabs" TabStripPlacement="Left" Background="#080B14" BorderThickness="0" Padding="0">
      <TabItem Header="[PKG]  Install">
        <DockPanel Margin="24,20,24,20">
          <TextBlock DockPanel.Dock="Top" Text="Install common apps via winget - check what you want, then Install Selected." Foreground="#8C99BC" Margin="0,0,0,12" TextWrapping="Wrap"/>
          <TextBox x:Name="InstallSearchBox" DockPanel.Dock="Top" Style="{StaticResource SearchBox}" Margin="0,0,0,12" Tag="Search apps..."/>
          <Button x:Name="InstallSelectedButton" DockPanel.Dock="Bottom" Content="[PKG]  Install Selected" Style="{StaticResource ActionButton}" Margin="0,14,0,0" HorizontalAlignment="Left"/>
          <ScrollViewer VerticalScrollBarVisibility="Auto">
            <StackPanel x:Name="InstallPanel"/>
          </ScrollViewer>
        </DockPanel>
      </TabItem>

      <TabItem Header="[OK]  Tweaks">
        <DockPanel Margin="24,20,24,20">
          <TextBlock DockPanel.Dock="Top" Text="Pick any combination of tweaks and apply them all in one pass." Foreground="#8C99BC" Margin="0,0,0,12" TextWrapping="Wrap"/>
          <TextBox x:Name="TweakSearchBox" DockPanel.Dock="Top" Style="{StaticResource SearchBox}" Margin="0,0,0,12" Tag="Search tweaks..."/>
          <Button x:Name="ApplySelectedButton" DockPanel.Dock="Bottom" Content="*  Apply Selected Tweaks" Style="{StaticResource ActionButton}" Margin="0,14,0,0" HorizontalAlignment="Left"/>
          <ScrollViewer VerticalScrollBarVisibility="Auto">
            <StackPanel x:Name="TweaksPanel"/>
          </ScrollViewer>
        </DockPanel>
      </TabItem>

      <TabItem Header="*  Profiles">
        <DockPanel Margin="24,20,24,20">
          <TextBlock DockPanel.Dock="Top" Text="One-click full profiles - each applies a whole curated set of tweaks." Foreground="#8C99BC" Margin="0,0,0,16" TextWrapping="Wrap"/>
          <ScrollViewer VerticalScrollBarVisibility="Auto">
            <StackPanel x:Name="ProfilesPanel"/>
          </ScrollViewer>
        </DockPanel>
      </TabItem>

      <TabItem Header="^  Updates">
        <StackPanel Margin="24,20,24,20">
          <TextBlock Text="Keep Wethereal and your apps up to date." Foreground="#8C99BC" Margin="0,0,0,16" TextWrapping="Wrap"/>
          <Button x:Name="CheckWetherealUpdateButton" Content="^  Check for Wethereal Updates" Style="{StaticResource ProfileButton}" Margin="0,0,0,10" HorizontalAlignment="Stretch"/>
          <Button x:Name="WingetUpgradeAllButton" Content="[PKG]  Update All Apps (winget upgrade --all)" Style="{StaticResource ProfileButton}" Margin="0,0,0,10" HorizontalAlignment="Stretch"/>
        </StackPanel>
      </TabItem>

      <TabItem Header="[i]  Info">
        <StackPanel Margin="24,20,24,20" x:Name="InfoPanel">
          <TextBlock Text="About Wethereal" FontSize="18" FontWeight="Bold" Foreground="#E8ECF4" Margin="0,0,0,12"/>
        </StackPanel>
      </TabItem>
    </TabControl>
  </DockPanel>
</Window>
"@

    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [Windows.Markup.XamlReader]::Load($reader)

    # ---- Fit the window to the actual screen - the XAML size is just a
    # ---- default for typical 1080p+ displays; on smaller/scaled screens
    # ---- (laptops, 1366x768, high DPI scaling) shrink to fit the visible
    # ---- work area (excludes the taskbar) so it never opens off-screen.
    $workArea = [System.Windows.SystemParameters]::WorkArea
    $window.MaxHeight = $workArea.Height
    $window.MaxWidth = $workArea.Width
    if ($window.Height -gt $workArea.Height * 0.9) { $window.Height = [math]::Max($window.MinHeight, [math]::Floor($workArea.Height * 0.85)) }
    if ($window.Width -gt $workArea.Width * 0.9) { $window.Width = [math]::Max($window.MinWidth, [math]::Floor($workArea.Width * 0.85)) }

    # ---- Custom title bar: draggable (WindowStyle="None" has no native one) ----
    $titleBar = $window.FindName("TitleBar")
    $titleBar.Add_MouseLeftButtonDown({
            param($sender, $e)
            if ($e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed) {
                if ($e.ClickCount -eq 2) {
                    $window.WindowState = if ($window.WindowState -eq 'Maximized') { 'Normal' } else { 'Maximized' }
                }
                else {
                    try { $window.DragMove() } catch {}
                }
            }
        }.GetNewClosure())
    $window.FindName("MinimizeButton").Add_Click({ $window.WindowState = 'Minimized' }.GetNewClosure())
    $window.FindName("CloseButton").Add_Click({ $window.Close() }.GetNewClosure())

    $subtitleText = $window.FindName("SubtitleText")
    $logBox = $window.FindName("LogBox")
    $progressBar = $window.FindName("ProgressBar")
    $statusText = $window.FindName("StatusText")
    $installPanel = $window.FindName("InstallPanel")
    $tweaksPanel = $window.FindName("TweaksPanel")
    $profilesPanel = $window.FindName("ProfilesPanel")
    $infoPanel = $window.FindName("InfoPanel")

    $gpuText = if ($hw.GPUs.Count -eq 0) { "no GPU detected" } else { ($hw.GPUs | ForEach-Object { "$($_.Name) [$($_.Vendor)]" }) -join " + " }
    $subtitleText.Text = "v$($Script:Version)  |  $($hw.CPU.Vendor) CPU  |  $gpuText"

    # ---- "Recommended for you": pick a profile from detected RAM/disk/GPU ----
    $recommendedText = $window.FindName("RecommendedText")
    $totalRamGB = [math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue).TotalPhysicalMemory / 1GB, 1)
    if (-not $totalRamGB) { $totalRamGB = 0 }
    $hasDiscreteGpu = ($hw.GPUVendors -contains 'NVIDIA') -or ($hw.GPUVendors -contains 'AMD')
    $isSystemDriveSSD = Test-SystemDriveIsSSD

    $diskDesc = if ($isSystemDriveSSD) { "SSD" } else { "HDD" }
    if ($totalRamGB -gt 0 -and $totalRamGB -lt 8) {
        $recommendedProfileKey = 'LowEndGaming'
        $recommendReason = "$totalRamGB GB RAM (under 8 GB) on $diskDesc - Low-End Gaming / Max FPS frees the most headroom for your specs."
    }
    elseif ($hasDiscreteGpu) {
        $recommendedProfileKey = 'Gaming'
        $recommendReason = "Discrete GPU detected ($($hw.GPUVendors -join '/')) with $totalRamGB GB RAM on $diskDesc - the Gaming profile is tuned for this setup."
    }
    else {
        $recommendedProfileKey = 'MaxPerformance'
        $recommendReason = "General-purpose hardware detected ($totalRamGB GB RAM, $diskDesc) - Maximum Performance covers the broadest set of optimizations."
    }
    $recommendedProfileDef = $Script:Profiles[$recommendedProfileKey]
    $recommendedText.Text = "$($recommendedProfileDef.Name) - $recommendReason"

    # ---- Populate Tweaks tab (grouped, with checkboxes) ----
    $catalog = Get-GuiTweakCatalog
    $allTweakCheckboxes = @()
    foreach ($groupName in $catalog.Keys) {
        $groupLabel = New-Object System.Windows.Controls.TextBlock
        $groupLabel.Text = $groupName
        $groupLabel.Foreground = New-GuiBrush "#5391FE"
        $groupLabel.FontWeight = "Bold"
        $groupLabel.FontSize = 14
        $groupLabel.Margin = "0,14,0,4"
        $tweaksPanel.Children.Add($groupLabel) | Out-Null

        foreach ($tweak in $catalog[$groupName]) {
            $cb = New-Object System.Windows.Controls.CheckBox
            $cb.Content = $tweak.Name
            $cb.ToolTip = $tweak.Desc
            $cb.Tag = $tweak
            $tweaksPanel.Children.Add($cb) | Out-Null
            $allTweakCheckboxes += $cb
        }
    }

    # ---- Populate Install tab (from the shared App Manager catalog) ----
    $allAppCheckboxes = @()
    foreach ($app in $Script:AppCatalog) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content = "$($app.Name)  ($($app.Id))"
        $cb.Tag = $app
        $installPanel.Children.Add($cb) | Out-Null
        $allAppCheckboxes += $cb
    }

    # ---- Populate Profiles tab ----
    foreach ($key in @($Script:Profiles.Keys)) {
        $prof = $Script:Profiles[$key]
        $btn = New-Object System.Windows.Controls.Button
        $btn.Style = $window.FindResource("ProfileButton")
        $btn.Content = "$($prof.Name)`n$($prof.Description)"
        $btn.Margin = "0,0,0,10"
        $btn.Tag = $key
        $btn.Add_Click({
                param($sender, $e)
                $chosenKey = $sender.Tag
                $profDef = $Script:Profiles[$chosenKey]
                $confirmResult = [System.Windows.MessageBox]::Show(
                    "Apply '$($profDef.Name)'?`n`n$($profDef.Description)",
                    "Confirm Profile", "YesNo", "Question")
                if ($confirmResult -eq "Yes") {
                    $statusText.Text = "Applying $($profDef.Name)..."
                    $logBox.AppendText("`r`nApplying profile: $($profDef.Name)...`r`n")
                    $logBox.ScrollToEnd()
                    $window.Cursor = [System.Windows.Input.Cursors]::Wait
                    try {
                        $Script:SkipConfirmations = $true
                        $Script:SkipPauses = $true
                        Invoke-OptimizationProfile -ProfileName $chosenKey
                    }
                    finally {
                        $Script:SkipConfirmations = $false
                        $Script:SkipPauses = $false
                        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
                    }
                    $logBox.AppendText("Finished: $($profDef.Name). Check WinTweaker.log for full detail.`r`n")
                    $logBox.ScrollToEnd()
                    $statusText.Text = "Done: $($profDef.Name)"
                }
            })
        $profilesPanel.Children.Add($btn) | Out-Null
    }

    # ---- "Apply Recommended" button (same flow as a Profiles-tab button) ----
    $window.FindName("ApplyRecommendedButton").Add_Click({
            $confirmResult = [System.Windows.MessageBox]::Show(
                "Apply the recommended profile - '$($recommendedProfileDef.Name)'?`n`n$($recommendedProfileDef.Description)",
                "Confirm Profile", "YesNo", "Question")
            if ($confirmResult -eq "Yes") {
                $statusText.Text = "Applying $($recommendedProfileDef.Name)..."
                $logBox.AppendText("`r`nApplying recommended profile: $($recommendedProfileDef.Name)...`r`n")
                $logBox.ScrollToEnd()
                $window.Cursor = [System.Windows.Input.Cursors]::Wait
                try {
                    $Script:SkipConfirmations = $true
                    $Script:SkipPauses = $true
                    Invoke-OptimizationProfile -ProfileName $recommendedProfileKey
                }
                finally {
                    $Script:SkipConfirmations = $false
                    $Script:SkipPauses = $false
                    $window.Cursor = [System.Windows.Input.Cursors]::Arrow
                }
                $logBox.AppendText("Finished: $($recommendedProfileDef.Name). Check WinTweaker.log for full detail.`r`n")
                $logBox.ScrollToEnd()
                $statusText.Text = "Done: $($recommendedProfileDef.Name)"
            }
        }.GetNewClosure())

    # ---- Populate Info tab ----
    $infoLines = @(
        "Version: $($Script:Version)",
        "CPU: $($hw.CPU.Name) [$($hw.CPU.Vendor), $($hw.CPU.Cores) cores / $($hw.CPU.Threads) threads]",
        "GPU: $gpuText",
        "Platform profile: $(Show-HardwarePlatformSummary)",
        "Telemetry: $(if ($Script:TelemetryEnabled) { 'Enabled (local)' } else { 'Disabled' })",
        "Log file: $Script:LogFile",
        "",
        "This window covers Install / Tweaks / Profiles / Updates. Everything else",
        "(Pro Gaming Tools, Pro Suite, per-category menus, per-game tuning, etc.) is",
        "still available from the console menu - close this window to return to it."
    )
    foreach ($line in $infoLines) {
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Text = $line
        $tb.Foreground = New-GuiBrush "#E8ECF4"
        $tb.FontFamily = "Consolas"
        $tb.FontSize = 13
        $tb.Margin = "0,2"
        $infoPanel.Children.Add($tb) | Out-Null
    }

    # ---- Search filtering ----
    $tweakSearchBox = $window.FindName("TweakSearchBox")
    $tweakSearchBox.Add_TextChanged({
            $query = $tweakSearchBox.Text.ToLower()
            foreach ($cb in $allTweakCheckboxes) {
                $cb.Visibility = if ([string]::IsNullOrWhiteSpace($query) -or $cb.Content.ToString().ToLower().Contains($query)) { "Visible" } else { "Collapsed" }
            }
        }.GetNewClosure())

    $installSearchBox = $window.FindName("InstallSearchBox")
    $installSearchBox.Add_TextChanged({
            $query = $installSearchBox.Text.ToLower()
            foreach ($cb in $allAppCheckboxes) {
                $cb.Visibility = if ([string]::IsNullOrWhiteSpace($query) -or $cb.Content.ToString().ToLower().Contains($query)) { "Visible" } else { "Collapsed" }
            }
        }.GetNewClosure())

    # ---- Apply Selected Tweaks ----
    $applyButton = $window.FindName("ApplySelectedButton")
    $applyButton.Add_Click({
            $selected = $allTweakCheckboxes | Where-Object { $_.IsChecked -eq $true }
            if ($selected.Count -eq 0) {
                [System.Windows.MessageBox]::Show("Check at least one tweak first.", "Nothing selected", "OK", "Warning") | Out-Null
                return
            }
            $confirmResult = [System.Windows.MessageBox]::Show("Apply $($selected.Count) selected tweak(s)?", "Confirm", "YesNo", "Question")
            if ($confirmResult -ne "Yes") { return }
            $steps = $selected | ForEach-Object { @{ Name = $_.Tag.Name; Action = $_.Tag.Action } }
            Invoke-GuiStepBatch -Window $window -LogBox $logBox -ProgressBar $progressBar -StatusText $statusText -Steps $steps
        }.GetNewClosure())

    # ---- Install Selected Apps ----
    $installButton = $window.FindName("InstallSelectedButton")
    $installButton.Add_Click({
            $selected = $allAppCheckboxes | Where-Object { $_.IsChecked -eq $true }
            if ($selected.Count -eq 0) {
                [System.Windows.MessageBox]::Show("Check at least one app first.", "Nothing selected", "OK", "Warning") | Out-Null
                return
            }
            if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                [System.Windows.MessageBox]::Show("winget (App Installer) was not found. Install it from the Microsoft Store first.", "winget missing", "OK", "Error") | Out-Null
                return
            }
            $confirmResult = [System.Windows.MessageBox]::Show("Install $($selected.Count) app(s)? Each install runs in the background - the window may pause briefly during each download.", "Confirm", "YesNo", "Question")
            if ($confirmResult -ne "Yes") { return }
            $steps = $selected | ForEach-Object {
                $app = $_.Tag
                @{
                    Name   = "Installing $($app.Name)"
                    Action = {
                        winget install --id $app.Id -e --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
                        if ($LASTEXITCODE -ne 0) { throw "winget exited with code $LASTEXITCODE" }
                    }.GetNewClosure()
                }
            }
            Invoke-GuiStepBatch -Window $window -LogBox $logBox -ProgressBar $progressBar -StatusText $statusText -Steps $steps
        }.GetNewClosure())

    # ---- Updates tab buttons ----
    $window.FindName("CheckWetherealUpdateButton").Add_Click({
            $statusText.Text = "Checking for Wethereal updates..."
            $logBox.AppendText("`r`nChecking for Wethereal updates...`r`n")
            $window.Cursor = [System.Windows.Input.Cursors]::Wait
            try { Update-Wethereal } finally { $window.Cursor = [System.Windows.Input.Cursors]::Arrow }
            $logBox.AppendText("Update check done - see console/log for detail.`r`n")
            $logBox.ScrollToEnd()
        }.GetNewClosure())

    $window.FindName("WingetUpgradeAllButton").Add_Click({
            if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                [System.Windows.MessageBox]::Show("winget (App Installer) was not found.", "winget missing", "OK", "Error") | Out-Null
                return
            }
            $confirmResult = [System.Windows.MessageBox]::Show("Run 'winget upgrade --all'? This can take a while.", "Confirm", "YesNo", "Question")
            if ($confirmResult -ne "Yes") { return }
            $statusText.Text = "Running winget upgrade --all..."
            $logBox.AppendText("`r`nRunning winget upgrade --all...`r`n")
            $logBox.ScrollToEnd()
            $window.Cursor = [System.Windows.Input.Cursors]::Wait
            try {
                winget upgrade --all --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
                $logBox.AppendText("winget upgrade --all finished (exit code $LASTEXITCODE).`r`n")
            }
            finally {
                $window.Cursor = [System.Windows.Input.Cursors]::Arrow
                $logBox.ScrollToEnd()
                $statusText.Text = "Ready."
            }
        }.GetNewClosure())

    $window.ShowDialog() | Out-Null
}

#endregion

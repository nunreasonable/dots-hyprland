$IiClassicConsole = $Host.Name -eq 'ConsoleHost' -and -not $env:WT_SESSION -and -not $env:TERM_PROGRAM
$IiConsoleHasGlyphs = $true
if ($IiClassicConsole) {
    $IiConsoleHasGlyphs = $false
    try {
        if (-not ('Ii.Windows.ConsoleFont' -as [type])) {
            Add-Type -Namespace Ii.Windows -Name ConsoleFont -MemberDefinition @'
                [StructLayout(LayoutKind.Sequential)]
                public struct COORD { public short X; public short Y; }

                [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
                public struct CONSOLE_FONT_INFOEX {
                    public uint cbSize;
                    public uint nFont;
                    public COORD dwFontSize;
                    public uint FontFamily;
                    public uint FontWeight;
                    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
                    public string FaceName;
                }

                [DllImport("kernel32.dll", SetLastError = true)]
                public static extern bool GetCurrentConsoleFontEx(IntPtr hConsoleOutput, bool bMaximumWindow, ref CONSOLE_FONT_INFOEX lpConsoleCurrentFontEx);
                [DllImport("kernel32.dll", SetLastError = true)]
                public static extern bool SetCurrentConsoleFontEx(IntPtr hConsoleOutput, bool bMaximumWindow, ref CONSOLE_FONT_INFOEX lpConsoleCurrentFontEx);
                [DllImport("kernel32.dll", SetLastError = true)]
                public static extern IntPtr GetStdHandle(int nStdHandle);
'@
        }

        $iiStdOut = [Ii.Windows.ConsoleFont]::GetStdHandle(-11)
        $iiFont = New-Object Ii.Windows.ConsoleFont+CONSOLE_FONT_INFOEX
        $iiFont.cbSize = [Runtime.InteropServices.Marshal]::SizeOf($iiFont)

        if ([Ii.Windows.ConsoleFont]::GetCurrentConsoleFontEx($iiStdOut, $false, [ref]$iiFont)) {
            if ($iiFont.FaceName -match '(?i)Nerd ?Font|\bNF\b') {
                $IiConsoleHasGlyphs = $true
            } else {
                $iiWanted = New-Object Ii.Windows.ConsoleFont+CONSOLE_FONT_INFOEX
                $iiWanted.cbSize = $iiFont.cbSize
                $iiWanted.dwFontSize = $iiFont.dwFontSize
                $iiWanted.FontFamily = $iiFont.FontFamily
                $iiWanted.FontWeight = $iiFont.FontWeight
                $iiWanted.FaceName = 'JetBrainsMono NF'
                [Ii.Windows.ConsoleFont]::SetCurrentConsoleFontEx($iiStdOut, $false, [ref]$iiWanted) | Out-Null

                $iiCheck = New-Object Ii.Windows.ConsoleFont+CONSOLE_FONT_INFOEX
                $iiCheck.cbSize = $iiFont.cbSize
                if ([Ii.Windows.ConsoleFont]::GetCurrentConsoleFontEx($iiStdOut, $false, [ref]$iiCheck)) {
                    $IiConsoleHasGlyphs = $iiCheck.FaceName -match '(?i)JetBrainsMono ?NF|JetBrainsMono Nerd Font'
                }
            }
        }
    } catch { }
}

$IiOhMyPoshThemeName = if ($IiConsoleHasGlyphs) { 'ii.omp.json' } else { 'ii.plain.omp.json' }
$IiOhMyPoshTheme = Join-Path $env:LOCALAPPDATA "quickshell\State\user\generated\terminal\$IiOhMyPoshThemeName"
if ((Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $IiOhMyPoshTheme)) {
    oh-my-posh init pwsh --config $IiOhMyPoshTheme | Invoke-Expression
} elseif (Get-Command starship -ErrorAction SilentlyContinue) {
    $IiStarshipConfigName = if ($IiClassicConsole) { 'starship-plain.toml' } else { 'starship.toml' }
    $env:STARSHIP_CONFIG = Join-Path $PSScriptRoot $IiStarshipConfigName

    function global:Invoke-Starship-TransientFunction {
        &starship module character
    }

    Invoke-Expression (&starship init powershell)
    Enable-TransientPrompt
}

$IiSequencesPath = Join-Path $env:LOCALAPPDATA 'quickshell\State\user\generated\terminal\sequences.txt'
if (Test-Path -LiteralPath $IiSequencesPath) {
    if ($Host.Name -eq 'ConsoleHost' -and -not $env:WT_SESSION) {
        try {
            if (-not ('Ii.Windows.ConsoleVt' -as [type])) {
                Add-Type -Namespace Ii.Windows -Name ConsoleVt -MemberDefinition @'
                    [DllImport("kernel32.dll", SetLastError = true)]
                    public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
                    [DllImport("kernel32.dll", SetLastError = true)]
                    public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
                    [DllImport("kernel32.dll", SetLastError = true)]
                    public static extern IntPtr GetStdHandle(int nStdHandle);
'@
            }
            $iiStdOut = [Ii.Windows.ConsoleVt]::GetStdHandle(-11)
            $iiConsoleMode = 0
            if ([Ii.Windows.ConsoleVt]::GetConsoleMode($iiStdOut, [ref]$iiConsoleMode)) {
                [Ii.Windows.ConsoleVt]::SetConsoleMode($iiStdOut, $iiConsoleMode -bor 0x4) | Out-Null
            }
        } catch { }
    }
    [Console]::Out.Write([IO.File]::ReadAllText($IiSequencesPath))
}

if ($IiClassicConsole) {
    try {
        if (-not ('Ii.Windows.ConsoleLook' -as [type])) {
            Add-Type -Namespace Ii.Windows -Name ConsoleLook -MemberDefinition @'
                [StructLayout(LayoutKind.Sequential)]
                public struct COORD { public short X; public short Y; }
                [StructLayout(LayoutKind.Sequential)]
                public struct SMALL_RECT { public short Left; public short Top; public short Right; public short Bottom; }
                [StructLayout(LayoutKind.Sequential)]
                public struct CONSOLE_SCREEN_BUFFER_INFOEX {
                    public uint cbSize;
                    public COORD dwSize;
                    public COORD dwCursorPosition;
                    public ushort wAttributes;
                    public SMALL_RECT srWindow;
                    public COORD dwMaximumWindowSize;
                    public ushort wPopupAttributes;
                    public int bFullscreenSupported;
                    [MarshalAs(UnmanagedType.ByValArray, SizeConst = 16)]
                    public uint[] ColorTable;
                }
                [StructLayout(LayoutKind.Sequential)]
                public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
                [StructLayout(LayoutKind.Sequential)]
                public struct MONITORINFO { public uint cbSize; public RECT rcMonitor; public RECT rcWork; public uint dwFlags; }

                [DllImport("kernel32.dll", SetLastError = true)]
                public static extern IntPtr GetStdHandle(int nStdHandle);
                [DllImport("kernel32.dll", SetLastError = true)]
                public static extern bool GetConsoleScreenBufferInfoEx(IntPtr hConsoleOutput, ref CONSOLE_SCREEN_BUFFER_INFOEX info);
                [DllImport("kernel32.dll", SetLastError = true)]
                public static extern bool SetConsoleScreenBufferInfoEx(IntPtr hConsoleOutput, ref CONSOLE_SCREEN_BUFFER_INFOEX info);
                [DllImport("kernel32.dll")]
                public static extern IntPtr GetConsoleWindow();
                [DllImport("user32.dll")]
                public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
                [DllImport("user32.dll")]
                public static extern IntPtr MonitorFromWindow(IntPtr hWnd, uint flags);
                [DllImport("user32.dll")]
                public static extern bool GetMonitorInfoW(IntPtr hMonitor, ref MONITORINFO info);
                [DllImport("user32.dll")]
                public static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
                [DllImport("user32.dll")]
                public static extern int GetWindowLongW(IntPtr hWnd, int index);
                [DllImport("user32.dll")]
                public static extern int SetWindowLongW(IntPtr hWnd, int index, int value);
                [DllImport("user32.dll")]
                public static extern bool SetLayeredWindowAttributes(IntPtr hWnd, uint key, byte alpha, uint flags);
'@
        }

        $iiStdOut = [Ii.Windows.ConsoleLook]::GetStdHandle(-11)

        $iiTerm = @{}
        if (Test-Path -LiteralPath $IiSequencesPath) {
            foreach ($iiMatch in [regex]::Matches([IO.File]::ReadAllText($IiSequencesPath), '\](?:4;(\d+)|(1[01]));(?:\[\d+\])?#([0-9A-Fa-f]{6})')) {
                $iiIndex = if ($iiMatch.Groups[1].Success) { [int]$iiMatch.Groups[1].Value } else { 100 + [int]$iiMatch.Groups[2].Value }
                if (($iiIndex -lt 16 -or $iiIndex -ge 110) -and -not $iiTerm.ContainsKey($iiIndex)) {
                    $iiHex = $iiMatch.Groups[3].Value
                    $iiTerm[$iiIndex] = [Convert]::ToUInt32($iiHex.Substring(0, 2), 16) -bor
                        ([Convert]::ToUInt32($iiHex.Substring(2, 2), 16) -shl 8) -bor
                        ([Convert]::ToUInt32($iiHex.Substring(4, 2), 16) -shl 16)
                }
            }
        }

        $iiInfo = New-Object Ii.Windows.ConsoleLook+CONSOLE_SCREEN_BUFFER_INFOEX
        $iiInfo.cbSize = [Runtime.InteropServices.Marshal]::SizeOf($iiInfo)
        $iiDefaultBack = if ($iiTerm.ContainsKey(111)) { $iiTerm[111] } else { $iiTerm[0] }
        $iiDefaultFore = if ($iiTerm.ContainsKey(110)) { $iiTerm[110] } else { $iiTerm[7] }
        if ($iiTerm.ContainsKey(0) -and $iiTerm.ContainsKey(15) -and [Ii.Windows.ConsoleLook]::GetConsoleScreenBufferInfoEx($iiStdOut, [ref]$iiInfo)) {
            $iiAnsiOf = 0, 4, 2, 6, 1, 5, 3, 7
            for ($iiSlot = 0; $iiSlot -lt 16; $iiSlot++) {
                $iiInfo.ColorTable[$iiSlot] = $iiTerm[$iiAnsiOf[$iiSlot % 8] + ($iiSlot -band 8)]
            }
            $iiFillBack = ($iiInfo.wAttributes -shr 4) -band 0xF
            $iiFillFore = $iiInfo.wAttributes -band 0xF
            if ($iiFillBack -ne $iiFillFore) {
                $iiInfo.ColorTable[$iiFillBack] = $iiDefaultBack
                $iiInfo.ColorTable[$iiFillFore] = $iiDefaultFore
            }
            $iiView = $iiInfo.srWindow
            $iiView.Right = $iiView.Right + 1
            $iiView.Bottom = $iiView.Bottom + 1
            $iiInfo.srWindow = $iiView
            [Ii.Windows.ConsoleLook]::SetConsoleScreenBufferInfoEx($iiStdOut, [ref]$iiInfo) | Out-Null
        }

        $iiWindow = [Ii.Windows.ConsoleLook]::GetConsoleWindow()
        $iiRect = New-Object Ii.Windows.ConsoleLook+RECT
        $iiMonitorInfo = New-Object Ii.Windows.ConsoleLook+MONITORINFO
        $iiMonitorInfo.cbSize = [Runtime.InteropServices.Marshal]::SizeOf($iiMonitorInfo)
        $iiMonitor = [Ii.Windows.ConsoleLook]::MonitorFromWindow($iiWindow, 2)
        if ($iiWindow -ne [IntPtr]::Zero -and [Ii.Windows.ConsoleLook]::GetWindowRect($iiWindow, [ref]$iiRect) -and
            [Ii.Windows.ConsoleLook]::GetMonitorInfoW($iiMonitor, [ref]$iiMonitorInfo)) {
            $iiWork = $iiMonitorInfo.rcWork
            $iiWidth = [Math]::Min($iiRect.Right - $iiRect.Left, $iiWork.Right - $iiWork.Left)
            $iiHeight = [Math]::Min($iiRect.Bottom - $iiRect.Top, $iiWork.Bottom - $iiWork.Top)
            $iiX = [Math]::Max($iiWork.Left, [Math]::Min($iiRect.Left, $iiWork.Right - $iiWidth))
            $iiY = [Math]::Max($iiWork.Top, [Math]::Min($iiRect.Top, $iiWork.Bottom - $iiHeight))
            if ($iiX -ne $iiRect.Left -or $iiY -ne $iiRect.Top -or
                $iiWidth -ne ($iiRect.Right - $iiRect.Left) -or $iiHeight -ne ($iiRect.Bottom - $iiRect.Top)) {
                [Ii.Windows.ConsoleLook]::SetWindowPos($iiWindow, [IntPtr]::Zero, $iiX, $iiY, $iiWidth, $iiHeight, 0x14) | Out-Null
            }
        }

        $iiConfigPath = Join-Path $env:LOCALAPPDATA 'illogical-impulse\config.json'
        $iiTransparent = $false
        if (Test-Path -LiteralPath $iiConfigPath) {
            $iiTransparent = (Get-Content -LiteralPath $iiConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json).appearance.transparency.enable -eq $true
        }
        if ($iiTransparent -and $iiWindow -ne [IntPtr]::Zero) {
            $iiExStyle = [Ii.Windows.ConsoleLook]::GetWindowLongW($iiWindow, -20)
            [Ii.Windows.ConsoleLook]::SetWindowLongW($iiWindow, -20, $iiExStyle -bor 0x80000) | Out-Null
            [Ii.Windows.ConsoleLook]::SetLayeredWindowAttributes($iiWindow, 0, 230, 2) | Out-Null
        }
    } catch { }
}

function global:Clear-HostAnsi {
    [Console]::Out.Write([char]27 + '[2J' + [char]27 + '[3J' + [char]27 + '[1;1H')
}
Set-Alias -Name clear -Value Clear-HostAnsi -Option AllScope -Scope Global -Force
Set-Alias -Name celar -Value Clear-HostAnsi -Option AllScope -Scope Global -Force
Set-Alias -Name claer -Value Clear-HostAnsi -Option AllScope -Scope Global -Force

if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
    if ($IiClassicConsole) {
        function global:ls { eza @args }
    } else {
        function global:ls { eza --icons=auto @args }
    }
}

$IiQsExePath = Join-Path $env:LOCALAPPDATA 'ii-windows\qs.exe'
if (Test-Path -LiteralPath $IiQsExePath) {
    function global:q { & $IiQsExePath -c ii @args }
}

if ($Host.Name -eq 'ConsoleHost' -and -not $global:__iiProfileBannerCleared) {
    $global:__iiProfileBannerCleared = $true
    $iiPreviousPrompt = ${function:global:prompt}
    function global:prompt {
        ${function:global:prompt} = $iiPreviousPrompt
        try { [Console]::Clear() } catch { }
        & $iiPreviousPrompt
    }
}

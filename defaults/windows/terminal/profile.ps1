<#
illogical-impulse shell integration for PowerShell (7 and Windows PowerShell 5.1 - everything
below sticks to syntax both understand: no `e escape, no ?? / ?:, no $PSStyle).

This is ii's equivalent of the dots' ~/.config/fish/config.fish (colors, starship, aliases) -
see that file for the Linux version this is kept in sync with. Nothing here touches $PROFILE
itself; no installer wires this up yet. Once one exists, it should add this block to both
$PROFILE files (CurrentUserCurrentHost for PowerShell 7 and for Windows PowerShell 5.1 are two
different files/locations; this same script works dot-sourced from either):

    # >>> illogical-impulse >>>
    if (Test-Path -LiteralPath "<install-dir>\config\ii\defaults\windows\terminal\profile.ps1") {
        . "<install-dir>\config\ii\defaults\windows\terminal\profile.ps1"
    }
    # <<< illogical-impulse <<<

(<install-dir> is wherever the installer stages the `ii` config, e.g.
"$env:LOCALAPPDATA\ii-windows\config\ii" - see tools/install.ps1's $InstallDir/$QsExe for the
one this ships next to). The Test-Path guard means a reinstall/uninstall that removes this file
doesn't leave a broken profile behind.
#>

# No greeting: unlike fish (which prints one unless `set fish_greeting` is used), neither
# PowerShell host prints a startup greeting of its own, so there's nothing to suppress here.

# No greeting, like config.fish's empty fish_greeting: the copyright banner comes before any
# profile and its -NoLogo switch can't be set from here (Windows Terminal's own settings.json
# names the command line), so a session that just started, with only the banner on screen,
# starts from a clear screen. The actual clearing happens at the bottom of this file, once the
# prompt this script ends up installing is known - see the comment there for why.

# Nerd Font glyphs in the prompt: Windows Terminal is always fine (its own font/fallback stack
# shows them, and this never touches a Windows Terminal session - checked via $env:WT_SESSION).
# The classic console (conhost: this host opened without Windows Terminal, e.g. ii's terminal
# bind falling back, or Windows+R > powershell) draws its own text with GDI and only shows what
# its *current console font* actually contains - that font is a per-user Windows setting
# (console properties / the registry), almost never a Nerd Font out of the box, so the glyphs
# ii.omp.json and starship.toml use come out as boxes there.
#
# $IiConsoleHasGlyphs resolves that once per session, cheaply (conhost only; Windows Terminal
# short-circuits to $true without any of the checks below):
#   1. GetCurrentConsoleFontEx reads the font this console window is already using. If its face
#      name already looks like a patched Nerd Font (the nerd-fonts patcher's own naming:
#      "...Nerd Font", "...NF", "...Nerd Font Mono" - case-insensitive), nothing to do.
#   2. Otherwise, try switching *this console window only* to "JetBrainsMono NF" - the family
#      name the Nerd Font patcher registers for the font the installer ships (see
#      build/package-stage/fonts/JetBrainsMonoNerdFont-*.ttf; whether install.ps1 actually
#      registers it per-user is for the integrator to confirm on the VM, hence the verification
#      below rather than assuming success). SetCurrentConsoleFontEx only affects the window
#      that's open right now - like ENABLE_VIRTUAL_TERMINAL_PROCESSING above, Windows throws
#      this away with the window; nothing persists past the session, no other console is
#      touched, and Windows Terminal is never involved.
#   3. SetCurrentConsoleFontEx can return success without the font actually existing (it falls
#      back silently), so the only reliable check is reading the font back and comparing the
#      face name GetCurrentConsoleFontEx now reports. If it doesn't match, the font isn't
#      installed (or this build of Windows refused it) and the glyphs still won't show - fall
#      back to the plain prompt instead of guessing.
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

        $iiStdOut = [Ii.Windows.ConsoleFont]::GetStdHandle(-11) # STD_OUTPUT_HANDLE
        $iiFont = New-Object Ii.Windows.ConsoleFont+CONSOLE_FONT_INFOEX
        $iiFont.cbSize = [Runtime.InteropServices.Marshal]::SizeOf($iiFont)

        if ([Ii.Windows.ConsoleFont]::GetCurrentConsoleFontEx($iiStdOut, $false, [ref]$iiFont)) {
            if ($iiFont.FaceName -match '(?i)Nerd ?Font|\bNF\b') {
                $IiConsoleHasGlyphs = $true
            } else {
                $iiWanted = New-Object Ii.Windows.ConsoleFont+CONSOLE_FONT_INFOEX
                $iiWanted.cbSize = $iiFont.cbSize
                $iiWanted.dwFontSize = $iiFont.dwFontSize # keep the size the user already has
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
    } catch { } # $IiConsoleHasGlyphs stays $false; the plain prompt always works
}

# Prompt: Oh My Posh with ii's theme (generated in the shell's current colors by
# services/WindowsTerminalTheme.qml), else Starship with ii's starship.toml like on Linux -
# ii.omp.json/starship.toml when $IiConsoleHasGlyphs, otherwise the plain-glyph variant
# WindowsTerminalTheme.qml writes next to it (ii.plain.omp.json) or starship-plain.toml next to
# this file, same colors and layout, ASCII/plain-Unicode symbols instead of Nerd Font icons.
# Both with a transient prompt (the full prompt collapses to the character once a command
# finishes, same as config.fish's starship_transient_prompt_func).
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

# Colors: ii writes OSC 4/10/11/12... escape sequences here whenever the Material theme
# changes (services/WindowsTerminalTheme.qml, the Windows equivalent of applycolor.sh's
# apply_anyterm()); printing it on every new shell is what makes a freshly opened tab pick up
# the current theme instead of waiting for the next change.
#
# Windows Terminal always has VT processing on and understands OSC 4 already. The classic
# console (conhost, opened by ii's own terminal binds when the user hasn't set Windows Terminal
# as default) needs ENABLE_VIRTUAL_TERMINAL_PROCESSING turned on for *this* output handle first -
# off by default for a plain console session - before it will act on any of this instead of
# printing the raw escape bytes; its own OSC 4 support arrived in Windows 10 1809 (build 17763),
# which every Windows version this project supports (10 2004+/19041, 11) already clears, so
# there's no older-conhost palette fallback to carry here. SetConsoleMode only changes this
# console window's mode for as long as the window is open - Windows throws that away with the
# window, nothing persists past the session or reaches other windows.
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
            # STD_OUTPUT_HANDLE = -11, ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004. GetConsoleMode
            # returns false (no throw) when the handle isn't actually a console - e.g. output
            # redirected to a file - so this is a no-op there instead of corrupting a stream.
            $iiStdOut = [Ii.Windows.ConsoleVt]::GetStdHandle(-11)
            $iiConsoleMode = 0
            if ([Ii.Windows.ConsoleVt]::GetConsoleMode($iiStdOut, [ref]$iiConsoleMode)) {
                [Ii.Windows.ConsoleVt]::SetConsoleMode($iiStdOut, $iiConsoleMode -bor 0x4) | Out-Null
            }
        } catch { }
    }
    [Console]::Out.Write([IO.File]::ReadAllText($IiSequencesPath))
}

# The classic console, continued: two things its VT support doesn't cover.
#   - Colors: conhost takes OSC 4 for SGR colors, but has no default background/foreground
#     (OSC 10/11) - its text and background are entries of its own 16-color table, and Windows
#     PowerShell's console settings point the background at entry 5 (DarkMagenta, repainted that
#     dark blue). So the same term0..15 also go into that table, through
#     SetConsoleScreenBufferInfoEx, with the screen set to term7 on term0 like a terminal's
#     default colors. The console table orders colors blue-green-red where ANSI is
#     red-green-blue, hence the index map.
#   - Placement: conhost sizes a new window to the rows and columns in its settings (120x50 for
#     Windows PowerShell) and, when that doesn't fit, clamps it to the work area's size but at
#     the monitor's corner - under ii's bar. The window goes back inside the work area.
# Both only last as long as this window, like the console mode above.
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
        $iiMonitor = [Ii.Windows.ConsoleLook]::MonitorFromWindow($iiWindow, 2) # MONITOR_DEFAULTTONEAREST
        if ($iiWindow -ne [IntPtr]::Zero -and [Ii.Windows.ConsoleLook]::GetWindowRect($iiWindow, [ref]$iiRect) -and
            [Ii.Windows.ConsoleLook]::GetMonitorInfoW($iiMonitor, [ref]$iiMonitorInfo)) {
            $iiWork = $iiMonitorInfo.rcWork
            $iiWidth = [Math]::Min($iiRect.Right - $iiRect.Left, $iiWork.Right - $iiWork.Left)
            $iiHeight = [Math]::Min($iiRect.Bottom - $iiRect.Top, $iiWork.Bottom - $iiWork.Top)
            $iiX = [Math]::Max($iiWork.Left, [Math]::Min($iiRect.Left, $iiWork.Right - $iiWidth))
            $iiY = [Math]::Max($iiWork.Top, [Math]::Min($iiRect.Top, $iiWork.Bottom - $iiHeight))
            if ($iiX -ne $iiRect.Left -or $iiY -ne $iiRect.Top -or
                $iiWidth -ne ($iiRect.Right - $iiRect.Left) -or $iiHeight -ne ($iiRect.Bottom - $iiRect.Top)) {
                # SWP_NOZORDER | SWP_NOACTIVATE
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
    } catch { } # the console keeps its own colors and place; nothing else depends on this
}

# Aliases

# kitty doesn't clear scrollback properly on Linux, so config.fish works around it with a raw
# ANSI clear instead of the shell's own clear command; ported as-is for the three same misspelt
# names (claer/celar are typos ii's Linux config keeps on purpose).
function global:Clear-HostAnsi {
    [Console]::Out.Write([char]27 + '[2J' + [char]27 + '[3J' + [char]27 + '[1;1H')
}
# PowerShell ships `clear`/`cls` as aliases to Clear-Host, which outrank a same-named function -
# repointing the alias (instead of just defining a function) is what actually overrides them.
Set-Alias -Name clear -Value Clear-HostAnsi -Option AllScope -Scope Global -Force
Set-Alias -Name celar -Value Clear-HostAnsi -Option AllScope -Scope Global -Force
Set-Alias -Name claer -Value Clear-HostAnsi -Option AllScope -Scope Global -Force

if (Get-Command eza -ErrorAction SilentlyContinue) {
    # `ls` is normally an alias to Get-ChildItem, which would otherwise shadow the function below.
    Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
    if ($IiClassicConsole) {
        function global:ls { eza @args }
    } else {
        function global:ls { eza --icons=auto @args }
    }
}

# `q` opens ii itself, same as config.fish's `alias q 'qs -c ii'` - qs.exe is the console-mode
# launcher tools/install.ps1 ships next to qsw.exe (the windowed one Start Menu/autostart use).
$IiQsExePath = Join-Path $env:LOCALAPPDATA 'ii-windows\qs.exe'
if (Test-Path -LiteralPath $IiQsExePath) {
    function global:q { & $IiQsExePath -c ii @args }
}

# Banner clearing (see the "No greeting" comment near the top): wrap whatever `prompt` function
# is in effect now - the default one, or Oh My Posh's/Starship's from above - so the very first
# prompt draw of a fresh window clears the screen first, then puts itself back and gets out of
# the way. Checking CursorTop before any of this ran (the old approach) was never reliable: a
# clear 3 lines in only works if the banner is exactly that tall, and Windows PowerShell 5.1
# prints its own extra "Loading personal and system profiles took Xms." line *after* this whole
# script returns whenever profile loading crosses its 500ms threshold, i.e. after any CursorTop
# check this script could have made - so that line would survive a clear timed from here. Timing
# the clear from the prompt instead means it always runs after everything the host itself prints
# before a prompt, in every combination of host (conhost/Windows Terminal) and PowerShell version
# this needs to cover.
#
# Guarded on a flag the global scope keeps for the life of the process, so dot-sourcing this file
# again later in the same window - by hand, or because $PROFILE ends up doing it twice - never
# wraps a second time and never clears whatever the user has since typed or run.
if ($Host.Name -eq 'ConsoleHost' -and -not $global:__iiProfileBannerCleared) {
    $global:__iiProfileBannerCleared = $true
    $iiPreviousPrompt = ${function:global:prompt}
    function global:prompt {
        ${function:global:prompt} = $iiPreviousPrompt
        try { [Console]::Clear() } catch { }
        & $iiPreviousPrompt
    }
}

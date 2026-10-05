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

# Prompt: Oh My Posh with ii's theme (generated in the shell's current colors by
# services/WindowsTerminalTheme.qml), else Starship with ii's starship.toml like on Linux. Both
# with a transient prompt (the full prompt collapses to the character once a command finishes,
# same as config.fish's starship_transient_prompt_func).
$IiOhMyPoshTheme = Join-Path $env:LOCALAPPDATA 'quickshell\State\user\generated\terminal\ii.omp.json'
if ((Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $IiOhMyPoshTheme)) {
    oh-my-posh init pwsh --config $IiOhMyPoshTheme | Invoke-Expression
} elseif (Get-Command starship -ErrorAction SilentlyContinue) {
    $env:STARSHIP_CONFIG = Join-Path $PSScriptRoot 'starship.toml'

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
    function global:ls { eza --icons=auto @args }
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

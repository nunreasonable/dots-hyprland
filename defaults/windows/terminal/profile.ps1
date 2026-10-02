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

# Starship prompt, with transient prompt (collapses the full prompt to just the character once
# a command finishes, same as config.fish's starship_transient_prompt_func).
if (Get-Command starship -ErrorAction SilentlyContinue) {
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
$IiSequencesPath = Join-Path $env:LOCALAPPDATA 'quickshell\State\user\generated\terminal\sequences.txt'
if (Test-Path -LiteralPath $IiSequencesPath) {
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

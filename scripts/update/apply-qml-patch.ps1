param(
    [Parameter(Mandatory = $true)][string]$Zip,
    [Parameter(Mandatory = $true)][string]$Label,
    [Parameter(Mandatory = $true)][string]$InstallDir,
    [Parameter(Mandatory = $true)][string]$LiveDir
)

$ErrorActionPreference = 'Stop'
$InstallDir = [IO.Path]::GetFullPath($InstallDir)
$LiveDir = [IO.Path]::GetFullPath($LiveDir)
$configDir = Join-Path $InstallDir 'config\ii'
$prevDir = Join-Path $InstallDir 'config\ii.prev'
$badDir = Join-Path $InstallDir 'config\ii.bad'
$patchFile = Join-Path $InstallDir 'PATCH'
$failedFile = Join-Path $InstallDir 'PATCH-FAILED'
$logFile = Join-Path $InstallDir 'patch.log'
$qsw = Join-Path $InstallDir 'qsw.exe'
$qs = Join-Path $InstallDir 'qs.exe'
$work = Join-Path $env:TEMP ('ii-qml-patch-' + [Guid]::NewGuid().ToString('N'))

function Log([string]$text) {
    $line = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + ' ' + $text
    [IO.File]::AppendAllText($logFile, $line + "`r`n", (New-Object Text.UTF8Encoding $false))
}

function ShellProcesses {
    @(Get-Process qsw -ErrorAction SilentlyContinue | Where-Object { $_.Path -and ([IO.Path]::GetFullPath($_.Path) -ieq $qsw) })
}

function StopShell {
    foreach ($p in ShellProcesses) {
        try { & $qs kill --pid $p.Id 2>&1 | Out-Null } catch {}
        if (-not $p.WaitForExit(10000)) {
            try { Stop-Process -Id $p.Id -Force -ErrorAction Stop } catch {}
            [void]$p.WaitForExit(5000)
        }
    }
}

function Mirror([string]$from, [string]$to) {
    & robocopy $from $to /MIR /R:2 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy $from -> $to failed with $LASTEXITCODE" }
}

function StartShell {
    Start-Process -FilePath $qsw -ArgumentList '-c', 'ii' -WorkingDirectory $InstallDir | Out-Null
}

function ClearQmlCache {
    $cache = Join-Path $env:LOCALAPPDATA 'quickshell\cache\qmlcache'
    if (Test-Path -LiteralPath $cache) { Remove-Item -LiteralPath $cache -Recurse -Force -ErrorAction SilentlyContinue }
}

$previousLabel = ''
if (Test-Path -LiteralPath $patchFile) { $previousLabel = ([IO.File]::ReadAllText($patchFile)).Trim() }
$swapped = $false

try {
    Log "applying $Label from $Zip"
    New-Item -ItemType Directory -Force -Path $work | Out-Null
    & tar.exe -xf $Zip -C $work
    if ($LASTEXITCODE -ne 0) { throw "tar failed with $LASTEXITCODE" }
    $newDir = Join-Path $work 'ii'
    if (-not (Test-Path -LiteralPath (Join-Path $newDir 'shell.qml'))) { throw 'the patch has no ii\shell.qml' }

    StopShell

    if (Test-Path -LiteralPath $prevDir) { Remove-Item -LiteralPath $prevDir -Recurse -Force }
    Move-Item -LiteralPath $configDir -Destination $prevDir
    $swapped = $true
    Move-Item -LiteralPath $newDir -Destination $configDir
    Mirror $configDir $LiveDir
    ClearQmlCache
    [IO.File]::WriteAllText($patchFile, $Label, (New-Object Text.UTF8Encoding $false))
    Log "installed $Label"

    StartShell
    Start-Sleep -Seconds 25
    if ((ShellProcesses).Count -eq 0) { throw 'the shell did not stay up after the patch' }
    if (Test-Path -LiteralPath $failedFile) { Remove-Item -LiteralPath $failedFile -Force -ErrorAction SilentlyContinue }
    Log "$Label is running"
}
catch {
    Log ("failed: " + $_.Exception.Message)
    if ($swapped) {
        try {
            StopShell
            if (Test-Path -LiteralPath $badDir) { Remove-Item -LiteralPath $badDir -Recurse -Force }
            if (Test-Path -LiteralPath $configDir) { Move-Item -LiteralPath $configDir -Destination $badDir }
            Move-Item -LiteralPath $prevDir -Destination $configDir
            Mirror $configDir $LiveDir
            ClearQmlCache
            if ($previousLabel -ne '') { [IO.File]::WriteAllText($patchFile, $previousLabel, (New-Object Text.UTF8Encoding $false)) }
            elseif (Test-Path -LiteralPath $patchFile) { Remove-Item -LiteralPath $patchFile -Force }
            Log 'restored the previous QML'
        }
        catch { Log ("restore failed: " + $_.Exception.Message) }
    }
    [IO.File]::WriteAllText($failedFile, $Label, (New-Object Text.UTF8Encoding $false))
    if ((ShellProcesses).Count -eq 0) { StartShell }
}
finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $Zip -Force -ErrorAction SilentlyContinue
}

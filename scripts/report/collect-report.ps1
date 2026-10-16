param(
    [string]$Version = '',
    [string]$Screens = '',
    [string]$Style = '',
    [string]$Family = '',
    [switch]$IncludeDump
)

$ErrorActionPreference = 'Continue'
$utf8 = New-Object Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$work = Join-Path $env:TEMP "ii-windows-report-$stamp"
New-Item -ItemType Directory -Force $work | Out-Null

$userPattern = '(?i)(Users[\\/]+)' + [regex]::Escape($env:USERNAME) + '(?=[\\/"]|$)'
function Scrub([string]$text) {
    if (-not $env:USERNAME) { return $text }
    return [regex]::Replace($text, $userPattern, '$1<user>')
}

function ReadShared([string]$path) {
    try {
        $share = [IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete
        $stream = New-Object IO.FileStream($path, [IO.FileMode]::Open, [IO.FileAccess]::Read, $share)
        $reader = New-Object IO.StreamReader($stream, [Text.Encoding]::UTF8)
        $text = $reader.ReadToEnd()
        $reader.Dispose()
        return @($text -split "`r?`n")
    } catch {
        return $null
    }
}

function ReadHead([string]$path, [int]$count) {
    try {
        $share = [IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete
        $stream = New-Object IO.FileStream($path, [IO.FileMode]::Open, [IO.FileAccess]::Read, $share)
        $reader = New-Object IO.StreamReader($stream, [Text.Encoding]::UTF8)
        $lines = for ($i = 0; $i -lt $count -and -not $reader.EndOfStream; $i++) { $reader.ReadLine() }
        $reader.Dispose()
        return ($lines -join "`n")
    } catch {
        return ''
    }
}

function CopyText([string]$source, [string]$name, [int]$head, [int]$tail) {
    if (-not (Test-Path -LiteralPath $source)) { return }
    $lines = ReadShared $source
    if ($null -eq $lines) { return }
    if ($lines.Count -gt ($head + $tail)) {
        $omitted = $lines.Count - $head - $tail
        $lines = @($lines[0..($head - 1)]) + @("... $omitted lines omitted ...") + @($lines[($lines.Count - $tail)..($lines.Count - 1)])
    }
    $text = Scrub ($lines -join "`r`n")
    [IO.File]::WriteAllText((Join-Path $work $name), $text, $utf8)
}

$runRoot = Join-Path $env:LOCALAPPDATA 'quickshell\run\by-id'
$logs = @(Get-ChildItem -Path $runRoot -Directory -ErrorAction SilentlyContinue |
    Sort-Object CreationTime -Descending |
    ForEach-Object { Get-Item -LiteralPath (Join-Path $_.FullName 'log.log') -ErrorAction SilentlyContinue } |
    Where-Object { $_ -and $_.Length -gt 0 -and (ReadHead $_.FullName 5) -match 'shell\.qml' } |
    Select-Object -First 2)
$index = 0
foreach ($log in $logs) {
    $index++
    $label = if ($index -eq 1) { 'log-latest.txt' } else { 'log-previous.txt' }
    CopyText $log.FullName $label 500 50000
}

$install = Join-Path $env:LOCALAPPDATA 'ii-windows'
CopyText (Join-Path $install 'setup.log') 'setup-log.txt' 200 3000

if ($IncludeDump) {
    $dump = Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA 'quickshell') -Recurse -Filter '*.dmp' -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($dump) { Copy-Item -LiteralPath $dump.FullName (Join-Path $work ('crash-' + $dump.Name)) }
}

$info = New-Object Collections.Generic.List[string]
if (-not $Version -and (Test-Path (Join-Path $install 'VERSION'))) { $Version = (Get-Content (Join-Path $install 'VERSION') -Raw).Trim() }
$info.Add("ii-windows: $Version")
$qsw = Join-Path $install 'qsw.exe'
if (Test-Path $qsw) {
    $rev = Select-String -LiteralPath $qsw -Pattern 'revision [0-9a-f]{7}' -List | Select-Object -First 1
    if ($rev) { $info.Add("quickshell: " + $rev.Matches[0].Value) }
}
$info.Add("visual style: $Style, panel family: $Family")

$os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
if ($os) { $info.Add("windows: $($os.Caption) $($cv.DisplayVersion) build $($os.BuildNumber).$($cv.UBR) $($os.OSArchitecture)") }
$info.Add("ui language: " + (Get-Culture).Name + " / " + (Get-UICulture).Name)

$cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
if ($cpu) { $info.Add("cpu: " + $cpu.Name.Trim()) }
if ($os) { $info.Add("ram: " + [math]::Round($os.TotalVisibleMemorySize / 1MB, 1) + " GB") }
foreach ($gpu in @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue)) {
    $info.Add("gpu: $($gpu.Name) (driver $($gpu.DriverVersion))")
}
$info.Add("screens: $Screens")

function OneLine([string]$text) {
    return ($text -replace '\s+', ' ').Trim()
}

try {
    $panels = @(Get-CimInstance -Namespace root/wmi -ClassName WmiMonitorBrightness -OperationTimeoutSec 15 -ErrorAction Stop)
    if ($panels.Count -eq 0) { $info.Add("brightness (wmi): no instances") }
    foreach ($panel in $panels) {
        $info.Add("brightness (wmi): $($panel.InstanceName) current $($panel.CurrentBrightness) active $($panel.Active) levels $($panel.Levels)")
    }
} catch {
    $info.Add("brightness (wmi): " + (OneLine $_.Exception.Message))
}
try {
    foreach ($link in @(Get-CimInstance -Namespace root/wmi -ClassName WmiMonitorConnectionParams -OperationTimeoutSec 15 -ErrorAction Stop)) {
        $info.Add("monitor connection (wmi): $($link.InstanceName) output $($link.VideoOutputTechnology) active $($link.Active)")
    }
} catch {
    $info.Add("monitor connection (wmi): " + (OneLine $_.Exception.Message))
}

$systemFonts = @(Get-ChildItem (Join-Path $env:WINDIR 'Fonts') -File -ErrorAction SilentlyContinue).Count
$userFonts = @(Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts') -File -ErrorAction SilentlyContinue).Count
$info.Add("fonts: $systemFonts for all users, $userFonts for this user")
$registered = @()
foreach ($key in 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts', 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts') {
    $props = Get-ItemProperty $key -ErrorAction SilentlyContinue
    if ($props) { $registered += $props.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } | ForEach-Object Name }
}
foreach ($family in 'Google Sans Flex', 'Material Symbols', 'JetBrainsMono', 'Readex Pro', 'Space Grotesk') {
    $hits = @($registered | Where-Object { $_ -like "*$family*" }).Count
    $info.Add("installed '$family' entries: $hits")
}
$info.Add("ii processes: " + @(Get-Process qsw -ErrorAction SilentlyContinue).Count)
[IO.File]::WriteAllText((Join-Path $work 'system-info.txt'), (Scrub ($info -join "`r`n")), $utf8)

$desktop = [Environment]::GetFolderPath('Desktop')
if (-not $desktop -or -not (Test-Path $desktop)) { $desktop = $env:TEMP }
$zip = Join-Path $desktop "ii-windows-report-$stamp.zip"
Compress-Archive -Path (Join-Path $work '*') -DestinationPath $zip -Force
Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
if (-not (Test-Path $zip)) {
    [Console]::Error.WriteLine("Couldn't write $zip")
    exit 1
}
Write-Output $zip

$ErrorActionPreference = "SilentlyContinue"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$claudeDir = Join-Path $env:USERPROFILE ".claude"
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$window = 5 * 3600
$cutoff = $now - 2 * $window

$sessions = New-Object System.Collections.ArrayList
foreach ($file in (Get-ChildItem -LiteralPath (Join-Path $claudeDir "sessions") -Filter "*.json" -File)) {
    try {
        $session = Get-Content -Raw -Encoding UTF8 -LiteralPath $file.FullName | ConvertFrom-Json
    } catch {
        continue
    }
    if ($session.pid -and (Get-Process -Id ([int]$session.pid) -ErrorAction SilentlyContinue)) {
        [void]$sessions.Add([ordered]@{
            name = [string]$session.name
            status = [string]$session.status
            cwd = [string]$session.cwd
        })
    }
}

$timestampPattern = [regex]'"timestamp"\s*:\s*"([^"]+)"'
$requestPattern = [regex]'"requestId"\s*:\s*"([^"]+)"'
$messagePattern = [regex]'"id"\s*:\s*"(msg_[^"]+)"'
$inputPattern = [regex]'"input_tokens"\s*:\s*(\d+)'
$outputPattern = [regex]'"output_tokens"\s*:\s*(\d+)'
$cachePattern = [regex]'"cache_creation_input_tokens"\s*:\s*(\d+)'

function Get-Count($pattern, $line) {
    $match = $pattern.Match($line)
    if ($match.Success) { return [long]$match.Groups[1].Value }
    return [long]0
}

$entries = @{}
foreach ($file in (Get-ChildItem -LiteralPath (Join-Path $claudeDir "projects") -Filter "*.jsonl" -File -Recurse -Depth 1)) {
    if (([DateTimeOffset]$file.LastWriteTimeUtc).ToUnixTimeSeconds() -lt $cutoff) { continue }
    $reader = $null
    try {
        $stream = [System.IO.File]::Open($file.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $reader = New-Object System.IO.StreamReader($stream)
        while ($null -ne ($line = $reader.ReadLine())) {
            if (-not $line.Contains('"usage"')) { continue }
            $timestamp = $timestampPattern.Match($line)
            if (-not $timestamp.Success) { continue }
            $parsed = [DateTimeOffset]::MinValue
            if (-not [DateTimeOffset]::TryParse($timestamp.Groups[1].Value, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal, [ref]$parsed)) { continue }
            $ts = $parsed.ToUnixTimeSeconds()
            if ($ts -lt $cutoff) { continue }
            $key = "$($messagePattern.Match($line).Groups[1].Value)|$($requestPattern.Match($line).Groups[1].Value)"
            $count = (Get-Count $inputPattern $line) + (Get-Count $outputPattern $line) + (Get-Count $cachePattern $line)
            $entries[$key] = [pscustomobject]@{ ts = $ts; count = $count }
        }
    } catch {
    } finally {
        if ($reader) { $reader.Dispose() }
    }
}

$tokens = [long]0
$start = $null
foreach ($entry in @($entries.Values | Sort-Object ts)) {
    $ts = $entry.ts
    if ($null -eq $start -or $ts -ge $start + $window) {
        $start = $ts - ($ts % 3600)
        $tokens = [long]0
    }
    $tokens += $entry.count
}
if ($null -eq $start -or $now -ge $start + $window) {
    $tokens = [long]0
    $start = $null
}

$resetsAt = 0
if ($null -ne $start) { $resetsAt = $start + $window }

[ordered]@{
    sessions = @($sessions)
    tokens = $tokens
    resetsAt = $resetsAt
} | ConvertTo-Json -Compress -Depth 4

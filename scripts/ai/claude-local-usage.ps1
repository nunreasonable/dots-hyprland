param([double]$Since = 0)

$ErrorActionPreference = "SilentlyContinue"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$configDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE ".claude" }
$root = Join-Path $configDir "projects"
if ($Since -le 0) { $Since = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - 7 * 86400 }
$sinceUtc = [DateTimeOffset]::FromUnixTimeSeconds([long]$Since).UtcDateTime

$timestampPattern = [regex]'"timestamp":"(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?Z?)"'
$modelPattern = [regex]'"model":"([^"]+)"'
$idPattern = [regex]'"message":\{[^{}]*?"id":"([^"]+)"'
$tokenPatterns = [ordered]@{
    input = [regex]'"input_tokens":(\d+)'
    output = [regex]'"output_tokens":(\d+)'
    cacheWrite = [regex]'"cache_creation_input_tokens":(\d+)'
    cacheRead = [regex]'"cache_read_input_tokens":(\d+)'
}

$seen = New-Object 'System.Collections.Generic.HashSet[string]'
$models = [ordered]@{}
$files = 0

if (Test-Path -LiteralPath $root) {
    foreach ($path in [IO.Directory]::EnumerateFiles($root, "*.jsonl", [IO.SearchOption]::AllDirectories)) {
        if ([IO.File]::GetLastWriteTimeUtc($path) -lt $sinceUtc) { continue }
        $files++
        $reader = $null
        try {
            $stream = [IO.File]::Open($path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete)
            $reader = New-Object IO.StreamReader($stream, [Text.Encoding]::UTF8)
            while ($null -ne ($line = $reader.ReadLine())) {
                if (-not $line.Contains('"usage"') -or -not $line.Contains('"type":"assistant"')) { continue }
                $stamps = $timestampPattern.Matches($line)
                if ($stamps.Count -eq 0) { continue }
                $when = [DateTimeOffset]::Parse($stamps[$stamps.Count - 1].Groups[1].Value, [Globalization.CultureInfo]::InvariantCulture).UtcDateTime
                if ($when -lt $sinceUtc) { continue }
                $id = $idPattern.Match($line)
                if ($id.Success -and -not $seen.Add($id.Groups[1].Value)) { continue }
                $match = $modelPattern.Match($line)
                $model = if ($match.Success) { $match.Groups[1].Value } else { "unknown" }
                if ($model.StartsWith("<")) { continue }
                if (-not $models.Contains($model)) {
                    $models[$model] = [ordered]@{ input = [long]0; output = [long]0; cacheWrite = [long]0; cacheRead = [long]0; messages = [long]0 }
                }
                $entry = $models[$model]
                foreach ($field in $tokenPatterns.Keys) {
                    $value = $tokenPatterns[$field].Match($line)
                    if ($value.Success) { $entry[$field] += [long]$value.Groups[1].Value }
                }
                $entry["messages"] += 1
            }
        } catch {
        } finally {
            if ($reader) { $reader.Dispose() }
        }
    }
}

[ordered]@{ since = $Since; files = $files; models = $models } | ConvertTo-Json -Compress -Depth 4

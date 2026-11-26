$ErrorActionPreference = "SilentlyContinue"
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false } catch {}

$tailBytes = 2000000
$headBytes = 65536
$maxSessions = 40
$claudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE ".claude" }
$utf8 = New-Object System.Text.UTF8Encoding $false

function Read-Lines([string]$path, [long]$start, [int]$length, [bool]$skipFirst) {
    $stream = [System.IO.File]::Open($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        [void]$stream.Seek($start, [System.IO.SeekOrigin]::Begin)
        $buffer = New-Object byte[] $length
        $read = $stream.Read($buffer, 0, $length)
        $lines = $utf8.GetString($buffer, 0, $read).Split("`n")
        if ($skipFirst) { $lines = if ($lines.Count -gt 1) { $lines[1..($lines.Count - 1)] } else { @() } }
        return ,$lines
    } finally {
        $stream.Dispose()
    }
}

function Get-Text($content) {
    if ($content -is [string]) { return $content }
    $parts = @()
    foreach ($block in @($content)) {
        if ($block.type -eq "text") { $parts += [string]$block.text }
    }
    return ($parts -join " ")
}

function Get-Number($value) {
    if ($null -eq $value) { return [long]0 }
    return [long]$value
}

function Get-Session($file) {
    $size = $file.Length
    $start = [Math]::Max([long]0, $size - $tailBytes)
    $length = [int][Math]::Min([long]$tailBytes, $size)
    $info = [ordered]@{
        id = [IO.Path]::GetFileNameWithoutExtension($file.Name)
        file = $file.FullName
        mtime = ([DateTimeOffset]$file.LastWriteTimeUtc).ToUnixTimeSeconds()
        cwd = ""
        title = ""
        lastPrompt = ""
        model = ""
        effort = ""
        contextTokens = [long]0
        costUsd = 0
        tasks = @()
    }
    $creates = @{}
    $tasks = @{}
    $order = New-Object System.Collections.ArrayList
    $lastCwd = ""
    $lastUsage = $null
    foreach ($line in (Read-Lines $file.FullName $start $length ($start -gt 0))) {
        if ($line.Length -eq 0) { continue }
        $kind = if ($line.Contains('"type":"custom-title"')) { "custom-title" }
            elseif ($line.Contains('"type":"last-prompt"')) { "last-prompt" }
            elseif ($line.Contains('"type":"cost-state"')) { "cost-state" }
            elseif ($line.Contains('"type":"assistant"')) { "assistant" }
            elseif ($line.Contains('"toolUseResult":{"task":')) { "task-result" }
            else { "" }
        if ($kind -eq "") { continue }
        if ($kind -eq "assistant" -and -not $line.Contains('"TaskCreate"') -and -not $line.Contains('"TaskUpdate"')) {
            if ($line.Contains('"usage"') -and -not $line.Contains('"isSidechain":true')) { $lastUsage = $line }
            continue
        }
        try { $entry = $line | ConvertFrom-Json } catch { continue }
        if ($entry.cwd) { $lastCwd = [string]$entry.cwd }
        switch ($kind) {
            "custom-title" { $info.title = [string]$entry.customTitle }
            "last-prompt" { $info.lastPrompt = [string]$entry.lastPrompt }
            "cost-state" { if ($entry.totalCostUSD) { $info.costUsd = $entry.totalCostUSD } }
            "assistant" {
                if ($entry.message.usage -and -not $entry.isSidechain) { $lastUsage = $line }
                foreach ($block in @($entry.message.content)) {
                    if ($block.type -ne "tool_use") { continue }
                    if ($block.name -eq "TaskCreate") { $creates[[string]$block.id] = $block.input }
                    elseif ($block.name -eq "TaskUpdate") {
                        $task = $tasks[[string]$block.input.taskId]
                        if ($task -and $block.input.status) { $task.status = [string]$block.input.status }
                    }
                }
            }
            "task-result" {
                foreach ($block in @($entry.message.content)) {
                    if ($block.type -ne "tool_result" -or -not $creates.ContainsKey([string]$block.tool_use_id)) { continue }
                    $created = $creates[[string]$block.tool_use_id]
                    $taskId = [string]$entry.toolUseResult.task.id
                    $subject = if ($entry.toolUseResult.task.subject) { [string]$entry.toolUseResult.task.subject } else { [string]$created.subject }
                    $tasks[$taskId] = [ordered]@{ id = $taskId; subject = $subject; activeForm = [string]$created.activeForm; status = "pending" }
                    [void]$order.Add($taskId)
                }
            }
        }
    }
    if ($lastUsage) {
        try {
            $entry = $lastUsage | ConvertFrom-Json
            $usage = $entry.message.usage
            $info.model = [string]$entry.message.model
            $info.effort = [string]$entry.effort
            $info.contextTokens = (Get-Number $usage.input_tokens) + (Get-Number $usage.cache_read_input_tokens) + (Get-Number $usage.cache_creation_input_tokens)
        } catch {}
    }
    $info.tasks = @($order | ForEach-Object { $tasks[$_] } | Where-Object { $_.status -ne "deleted" })

    $prompt = ""
    foreach ($line in (Read-Lines $file.FullName 0 ([int][Math]::Min([long]$headBytes, $size)) $false)) {
        if (-not $line.Contains('"cwd"') -and -not $line.Contains('"custom-title"')) { continue }
        try { $entry = $line | ConvertFrom-Json } catch { continue }
        if (-not $info.cwd -and $entry.cwd) { $info.cwd = [string]$entry.cwd }
        if (-not $prompt) {
            if ($entry.type -eq "custom-title") { $prompt = [string]$entry.customTitle }
            elseif ($entry.type -eq "user" -and -not $entry.isMeta) {
                $text = (Get-Text $entry.message.content).Trim()
                if ($text -and -not $text.StartsWith("<")) { $prompt = $text }
            }
        }
        if ($info.cwd -and $prompt) { break }
    }
    if (-not $info.cwd) { $info.cwd = $lastCwd }
    if (-not $info.title) { $info.title = if ($prompt) { $prompt } else { $info.lastPrompt } }
    $info.title = ($info.title -replace '\s+', ' ').Trim()
    if ($info.title.Length -gt 200) { $info.title = $info.title.Substring(0, 200) }
    $info.lastPrompt = ($info.lastPrompt -replace '\s+', ' ').Trim()
    if ($info.lastPrompt.Length -gt 400) { $info.lastPrompt = $info.lastPrompt.Substring(0, 400) }
    return $info
}

$files = Get-ChildItem -LiteralPath (Join-Path $claudeDir "projects") -Filter "*.jsonl" -File -Recurse -Depth 1 |
    Sort-Object LastWriteTimeUtc -Descending | Select-Object -First $maxSessions
$sessions = New-Object System.Collections.ArrayList
foreach ($file in $files) {
    try { [void]$sessions.Add((Get-Session $file)) } catch {}
}
$json = ConvertTo-Json -InputObject ([ordered]@{ sessions = @($sessions) }) -Depth 6 -Compress
[Console]::Out.Write($json)

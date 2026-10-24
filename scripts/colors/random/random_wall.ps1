param(
    [Parameter(Mandatory = $true)][ValidateSet("konachan", "osu")][string]$Source,
    [string]$UserAgent = "",
    [string]$Current = "",
    [switch]$Spicy,
    [switch]$OnlyYuri,
    [string]$ExtraTags = ""
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Test-Challenge($record) {
    $response = $record.Exception.Response
    $mitigated = ""
    $server = ""
    $status = 0
    if ($response) {
        try { $mitigated = "$($response.Headers['cf-mitigated'])" } catch {}
        try { $server = "$($response.Headers['Server'])" } catch {}
        try { $status = [int]$response.StatusCode } catch {}
    }
    $text = "$($record.ErrorDetails.Message) $($record.Exception.Message)"
    return $mitigated -eq "challenge" -or $text -match "Just a moment|cf-chl|challenge-platform" -or ($server -match "cloudflare" -and $status -in 403, 503)
}

trap {
    $message = if (Test-Challenge $_) { "IIW-ERROR:challenge:$Source" } else { "IIW-ERROR:" + (("$($_.Exception.Message)" -split "`r?`n")[0]) }
    [Console]::Error.WriteLine($message.Substring(0, [Math]::Min(300, $message.Length)))
    exit 1
}

$dir = Join-Path ([Environment]::GetFolderPath("MyPictures")) "Wallpapers"
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$web = @{ UseBasicParsing = $true }
if ($UserAgent -ne "") { $web.UserAgent = $UserAgent }

if ($Source -eq "konachan") {
    $tags = @("width:>=1600", "height:>=900", "score:>=30")
    if ($Spicy) {
        $site = "https://konachan.com"
    } else {
        $site = "https://konachan.net"
        $tags += "rating:safe"
    }
    if ($OnlyYuri) { $tags += "yuri" }
    if ($Spicy -and $ExtraTags.Trim() -ne "") {
        $room = 5 - $tags.Count
        $extra = @($ExtraTags.Trim() -split "\s+" | Where-Object { $_ -notmatch "^(order|limit|page):" } | Select-Object -First ([Math]::Max(0, $room)))
        $tags += $extra
    }
    $tags += "order:random"

    $query = [Uri]::EscapeDataString($tags -join " ")
    try {
        $response = Invoke-RestMethod @web "$site/post.json?limit=20&tags=$query"
    } catch {
        if (-not ($Spicy -and (Test-Challenge $_))) { throw }
        Write-Output "IIW-NOTE:konachan-fallback"
        $site = "https://konachan.net"
        $tags = @("width:>=1600", "height:>=900", "score:>=30", "rating:safe")
        if ($OnlyYuri) { $tags += "yuri" }
        $tags += "order:random"
        $query = [Uri]::EscapeDataString($tags -join " ")
        $response = Invoke-RestMethod @web "$site/post.json?limit=20&tags=$query"
    }
    $posts = @($response)
    if ($posts.Count -eq 0) { throw "Konachan returned no posts for: $($tags -join ' ')" }
    $post = $posts | Where-Object { $_.height -gt 0 -and ($_.width / $_.height) -ge 1.5 -and ($_.width / $_.height) -le 2.4 } | Select-Object -First 1
    if (-not $post) { $post = $posts[0] }
    $link = $post.file_url
    if ("$($post.id)" -notmatch '^\d{1,12}$') { throw "Unexpected post id" }
    $name = "konachan-$($post.id)"
} else {
    $backgrounds = (Invoke-RestMethod @web "https://osu.ppy.sh/api/v2/seasonal-backgrounds").backgrounds
    $link = ($backgrounds | Get-Random).url
    $name = "osu-" + ([IO.Path]::GetFileNameWithoutExtension(([Uri]$link).AbsolutePath) -replace '[^A-Za-z0-9_-]', '_')
}

if (-not $link) { throw "No image link" }
$uri = [Uri]$link
if ($uri.Scheme -ne "https") { throw "Unexpected image link" }
$ext = [IO.Path]::GetExtension($uri.AbsolutePath).ToLowerInvariant()
if ($ext -notin @(".jpg", ".jpeg", ".png", ".webp")) { throw "Unexpected image type" }
$out = Join-Path $dir "$name$ext"
$part = "$out.part"

try {
    Invoke-WebRequest @web $link -OutFile $part
    Move-Item -Force -LiteralPath $part -Destination $out
} catch {
    Remove-Item -Force -ErrorAction SilentlyContinue -LiteralPath $part
    throw
}

$current = $Current.Replace("/", "\")
foreach ($prefix in @("konachan-", "osu-")) {
    Get-ChildItem -LiteralPath $dir -File -Filter "$prefix*" |
        Where-Object { $_.Extension -ne ".part" } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -Skip 10 |
        Where-Object { $_.FullName -ne $current -and $_.FullName -ne $out } |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

$out.Replace("\", "/")

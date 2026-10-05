param(
    [Parameter(Mandatory = $true)][ValidateSet("konachan", "osu")][string]$Source,
    [string]$UserAgent = "",
    [string]$Current = ""
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$dir = Join-Path ([Environment]::GetFolderPath("MyPictures")) "Wallpapers"
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$web = @{ UseBasicParsing = $true }
if ($UserAgent -ne "") { $web.UserAgent = $UserAgent }

if ($Source -eq "konachan") {
    $page = Get-Random -Minimum 1 -Maximum 1001
    $posts = Invoke-RestMethod @web "https://konachan.net/post.json?tags=rating%3Asafe&limit=1&page=$page"
    $link = $posts[0].file_url
} else {
    $backgrounds = (Invoke-RestMethod @web "https://osu.ppy.sh/api/v2/seasonal-backgrounds").backgrounds
    $link = ($backgrounds | Get-Random).url
}

$ext = [IO.Path]::GetExtension(([Uri]$link).AbsolutePath)
$out = Join-Path $dir "random_wallpaper$ext"
if ($out -eq $Current.Replace("/", "\")) { $out = Join-Path $dir "random_wallpaper-1$ext" }

Invoke-WebRequest @web $link -OutFile $out
$out.Replace("\", "/")

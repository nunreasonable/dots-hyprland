# Windows counterpart of random_konachan_wall.sh / random_osu_wall.sh: downloads a random
# wallpaper to Pictures\Wallpapers and prints its path. The caller (QuickConfig.qml, welcome.qml)
# applies it with Wallpapers.apply(), which is what the Linux scripts do through switchwall.sh.
param(
    [Parameter(Mandatory = $true)][ValidateSet("konachan", "osu")][string]$Source,
    [string]$UserAgent = "",
    [string]$Current = ""
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue" # Invoke-WebRequest's progress bar slows downloads down
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$dir = Join-Path ([Environment]::GetFolderPath("MyPictures")) "Wallpapers"
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# Windows PowerShell refuses User-Agent in -Headers; it has its own parameter.
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
# Same name as the current wallpaper: use the other one, so the file in use isn't overwritten.
if ($out -eq $Current.Replace("/", "\")) { $out = Join-Path $dir "random_wallpaper-1$ext" }

Invoke-WebRequest @web $link -OutFile $out
$out.Replace("\", "/")

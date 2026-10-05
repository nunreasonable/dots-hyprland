# Windows counterpart to record.sh, driven by ScreenshotAction.qml. Only a fallback: the shell
# records natively (Quickshell.Windows.ScreenRecorder) unless that is unavailable.
#
#   record.ps1 -X -Y -Width -Height [-Sound] [-SaveDir dir] -PidFile file   start a recording
#   record.ps1 -Stop -PidFile file                                         stop it
#
# Start launches ffmpeg (gdigrab) on a desktop region and writes "<pid>`n<output file>" to the
# PID file, so stopping targets exactly that process. ffmpeg can't be asked to stop gracefully
# from another process (no SIGINT on Windows, and its stdin isn't ours), so it records to
# Matroska, which stays playable when the process is killed, and Stop remuxes that to the .mp4
# record.sh would have produced (stream copy, no re-encode).
#
# X/Y/Width/Height are physical-pixel, virtual-desktop coordinates (gdigrab's "desktop" spans
# every monitor with (0,0) at the primary's top-left, like HyprlandMonitor.x/y).
#
# Output on stdout, for ScreenshotAction.qml: "nosound" when sound was asked for but there is no
# loopback capture device, and on stop "saved <file>".
param(
    [int]$X,
    [int]$Y,
    [int]$Width,
    [int]$Height,
    [switch]$Sound,
    [string]$SaveDir = "",
    [switch]$Stop,
    [Parameter(Mandatory = $true)][string]$PidFile
)

$ErrorActionPreference = "Stop"

if ($Stop) {
    if (-not (Test-Path $PidFile)) { exit 0 }
    $pidValue, $mkv = Get-Content $PidFile
    Remove-Item -Force $PidFile

    $proc = Get-Process -Id $pidValue -ErrorAction SilentlyContinue
    if ($proc -and $proc.ProcessName -eq "ffmpeg") {
        Stop-Process -Id $pidValue -Force
        $proc.WaitForExit(5000) | Out-Null
    }

    if ($mkv -and (Test-Path $mkv)) {
        $mp4 = [IO.Path]::ChangeExtension($mkv, ".mp4")
        & ffmpeg -hide_banner -loglevel error -y -i $mkv -c copy -movflags +faststart $mp4
        if ($LASTEXITCODE -eq 0 -and (Test-Path $mp4)) {
            Remove-Item -Force $mkv
            "saved $mp4"
        } else {
            "saved $mkv"
        }
    }
    exit 0
}

$RecordingDir = if ($SaveDir -ne "") { $SaveDir } else { Join-Path $env:USERPROFILE "Videos" }
New-Item -ItemType Directory -Force -Path $RecordingDir | Out-Null

$stamp = Get-Date -Format "yyyy-MM-dd_HH.mm.ss"
$outFile = Join-Path $RecordingDir "recording_$stamp.mkv"

$ffmpegArgs = @(
    "-hide_banner", "-nostdin",
    "-f", "gdigrab",
    "-offset_x", $X,
    "-offset_y", $Y,
    "-video_size", "${Width}x${Height}",
    "-framerate", "30",
    "-i", "desktop"
)

if ($Sound) {
    # What the speakers play is only reachable through a loopback capture device: the driver's
    # "Stereo Mix" (off by default in Sound settings, localized name) or a virtual cable.
    $list = (& ffmpeg -hide_banner -list_devices true -f dshow -i dummy 2>&1 | Out-String)
    $loopback = [regex]::Matches($list, '"([^"]+)" \(audio\)') |
        ForEach-Object { $_.Groups[1].Value } |
        Where-Object { $_ -match 'Stereo ?Mix|Mixagem est|Mezcla est|Mixage st|What U Hear|Wave Out|Loopback|CABLE Output|virtual-audio-capturer' } |
        Select-Object -First 1

    if ($loopback) {
        $ffmpegArgs += @("-f", "dshow", "-i", "audio=$loopback", "-c:a", "aac")
    } else {
        "nosound"
    }
}

$ffmpegArgs += @("-c:v", "libx264", "-preset", "veryfast", "-pix_fmt", "yuv420p", "-y", $outFile)

# Windows PowerShell joins -ArgumentList with spaces and no quoting; device names and profile
# paths have spaces.
function Format-Arg([string]$a) {
    if ($a -match '[\s"]') { '"' + ($a -replace '"', '\"') + '"' } else { $a }
}
$argLine = ($ffmpegArgs | ForEach-Object { Format-Arg "$_" }) -join " "

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $PidFile) | Out-Null
$proc = Start-Process -FilePath "ffmpeg" -ArgumentList $argLine -WindowStyle Hidden -PassThru
Set-Content -Path $PidFile -Value "$($proc.Id)`n$outFile" -NoNewline

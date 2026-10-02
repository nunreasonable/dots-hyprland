# Windows counterpart to record.sh: starts an ffmpeg capture of a desktop region and writes its
# PID to -PidFile so a later run of ScreenshotAction.qml's stopWindowsRecording() can find and
# kill that exact process (replacing record.sh's own `pgrep wf-recorder` toggle, and `pidof
# wf-recorder` in RegionSelection.qml's checkRecordingProc - see windowsRecordingStatusCommand()
# in ScreenshotAction.qml). Stopping does NOT go through this script: it only needs the PID
# file, so it's done inline from QML/PowerShell without starting ffmpeg again.
#
# Only ever invoked by ScreenshotAction.qml's startWindowsRecording(), which has already
# confirmed ffmpeg is on PATH (see windowsRecordingStatusCommand(); this script assumes it is).
#
# X/Y/Width/Height are physical-pixel, virtual-desktop-global coordinates (gdigrab's "desktop"
# source spans every monitor, with (0,0) at the primary monitor's top-left - same convention as
# HyprlandMonitor.x/y in the native window tracker, which is what the caller adds to the
# region's monitor-local coordinates before calling this script).
param(
    [Parameter(Mandatory = $true)][int]$X,
    [Parameter(Mandatory = $true)][int]$Y,
    [Parameter(Mandatory = $true)][int]$Width,
    [Parameter(Mandatory = $true)][int]$Height,
    [switch]$Sound,
    [string]$SaveDir = "",
    [Parameter(Mandatory = $true)][string]$PidFile
)

$RecordingDir = if ($SaveDir -ne "") { $SaveDir } else { Join-Path $env:USERPROFILE "Videos" }
New-Item -ItemType Directory -Force -Path $RecordingDir | Out-Null

$stamp = Get-Date -Format "yyyy-MM-dd_HH.mm.ss"
$outFile = Join-Path $RecordingDir "recording_$stamp.mp4"

$ffmpegArgs = @(
    "-f", "gdigrab",
    "-offset_x", $X,
    "-offset_y", $Y,
    "-video_size", "${Width}x${Height}",
    "-framerate", "30",
    "-i", "desktop"
)

if ($Sound) {
    # Best-effort WASAPI loopback of the default playback device (needs a build with the wasapi
    # indev, e.g. the winget Gyan.FFmpeg package the "ffmpeg missing" notice points to). Not
    # verified on the target yet - BUILD-ONLY MODE, see docs/AGENTS.md - check this first if
    # "record with sound" comes back silent.
    $ffmpegArgs += @("-f", "wasapi", "-i", "default")
}

$ffmpegArgs += @("-pix_fmt", "yuv420p", "-y", $outFile)

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $PidFile) | Out-Null
$proc = Start-Process -FilePath "ffmpeg" -ArgumentList $ffmpegArgs -WindowStyle Hidden -PassThru
Set-Content -Path $PidFile -Value $proc.Id -NoNewline

param(
    [int]$X,
    [int]$Y,
    [int]$Width,
    [int]$Height,
    [switch]$Sound,
    [switch]$Mic,
    [string]$SaveDir = "",
    [switch]$Stop,
    [Parameter(Mandatory = $true)][string]$PidFile
)

$ErrorActionPreference = "Stop"

if ($Stop) {
    if (-not (Test-Path $PidFile)) { exit 0 }
    $pidValue, $mkv = Get-Content -Encoding UTF8 $PidFile
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

$audioInputs = @()
if ($Sound -or $Mic) {
    $list = (& ffmpeg -hide_banner -list_devices true -f dshow -i dummy 2>&1 | Out-String)
    $audioDevices = @([regex]::Matches($list, '"([^"]+)" \(audio\)') | ForEach-Object { $_.Groups[1].Value })
    $loopbackPattern = 'Stereo ?Mix|Mixagem est|Mezcla est|Mixage st|What U Hear|Wave Out|Loopback|CABLE Output|virtual-audio-capturer'
}

if ($Sound) {
    $loopback = $audioDevices | Where-Object { $_ -match $loopbackPattern } | Select-Object -First 1
    if ($loopback) {
        $audioInputs += $loopback
    } else {
        "nosound"
    }
}

if ($Mic) {
    $consent = 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone'
    $consentValues = @(
        (Get-ItemProperty -Path "HKLM:\$consent" -Name Value -ErrorAction SilentlyContinue).Value,
        (Get-ItemProperty -Path "HKCU:\$consent" -Name Value -ErrorAction SilentlyContinue).Value,
        (Get-ItemProperty -Path "HKCU:\$consent\NonPackaged" -Name Value -ErrorAction SilentlyContinue).Value
    )
    if ($consentValues -contains 'Deny') {
        "micblocked"
    } else {
        $microphone = $audioDevices | Where-Object { $_ -notmatch $loopbackPattern } | Select-Object -First 1
        if ($microphone) {
            $audioInputs += $microphone
        } else {
            "nomic"
        }
    }
}

foreach ($device in $audioInputs) {
    $ffmpegArgs += @("-f", "dshow", "-i", "audio=$device")
}
if ($audioInputs.Count -eq 2) {
    $ffmpegArgs += @("-filter_complex", "[1:a][2:a]amix=inputs=2:duration=longest:normalize=0,alimiter=limit=0.95[a]", "-map", "0:v", "-map", "[a]")
}
if ($audioInputs.Count -gt 0) {
    $ffmpegArgs += @("-c:a", "aac")
}

$ffmpegArgs += @("-c:v", "libx264", "-preset", "veryfast", "-pix_fmt", "yuv420p", "-y", $outFile)

function Format-Arg([string]$a) {
    if ($a -match '[\s"]') { '"' + ($a -replace '"', '\"') + '"' } else { $a }
}
$argLine = ($ffmpegArgs | ForEach-Object { Format-Arg "$_" }) -join " "

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $PidFile) | Out-Null
$proc = Start-Process -FilePath "ffmpeg" -ArgumentList $argLine -WindowStyle Hidden -PassThru
Set-Content -Encoding UTF8 -Path $PidFile -Value "$($proc.Id)`n$outFile" -NoNewline

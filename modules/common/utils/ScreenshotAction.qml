pragma ComponentBehavior: Bound
pragma Singleton
import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import Qt.labs.synchronizer
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    enum Action {
        Copy,
        Edit,
        Search,
        CharRecognition,
        Record,
        RecordWithSound
    }

    property string imageSearchEngineBaseUrl: Config.options.search.imageSearch.imageSearchEngineBaseUrl
    property string fileUploadApiEndpoint: "https://uguu.se/upload"

    // Windows only: requestId (from WindowsNative.ocr.recognizeText) -> cropped temp file to
    // delete once the result comes back. See runWindows()'s CharRecognition case and the
    // Connections below.
    property var _pendingOcr: ({})

    Connections {
        target: (Platform.isWindows && WindowsNative.ready) ? WindowsNative.ocr : null
        function onRecognized(requestId, text, ok, error) {
            const path = root._pendingOcr[requestId];
            delete root._pendingOcr[requestId];
            if (path) Quickshell.execDetached(["cmd", "/c", "del", "/f", "/q", path.replace(/\//g, "\\")]);

            if (ok) {
                WindowsNative.clipboard.copyText(text);
                const preview = text.length > 200 ? text.slice(0, 200) + "…" : text;
                Notifications.sendDesktop(Translation.tr("Text copied"), preview || Translation.tr("(no text found)"));
            } else {
                Notifications.sendDesktop(Translation.tr("Text recognition failed"), error);
            }
        }
    }

    function timestampForFilename() {
        const d = new Date();
        const pad = n => String(n).padStart(2, "0");
        return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}_${pad(d.getHours())}.${pad(d.getMinutes())}.${pad(d.getSeconds())}`;
    }

    // Windows equivalent of getCommand(): rather than building a shell pipeline, it calls the
    // native crop/clipboard/OCR/recorder helpers (WindowsNative.*) directly and shells out only
    // for the pieces that still need an external tool (curl.exe for image search, ffmpeg when
    // the native recorder is unavailable). monitorOffsetX/Y (physical pixels, HyprlandMonitor.x/y)
    // are only used for Record/RecordWithSound, to turn the region's per-monitor coordinates
    // into virtual-desktop-global ones.
    function runWindows(x, y, width, height, screenshotPath, action, saveDir = "", monitorOffsetX = 0, monitorOffsetY = 0) {
        if (!WindowsNative.ready || !WindowsNative.screenshot || !WindowsNative.clipboard) {
            console.warn("[Region Selector] Windows native helpers not ready, skipping snip.");
            return;
        }

        const rx = Math.round(x);
        const ry = Math.round(y);
        const rw = Math.round(width);
        const rh = Math.round(height);
        const cleanupRaw = () => Quickshell.execDetached(["cmd", "/c", "del", "/f", "/q", screenshotPath.replace(/\//g, "\\")]);

        switch (action) {
            case ScreenshotAction.Action.Copy: {
                const savePath = saveDir === ""
                    ? `${screenshotPath}-crop.png`
                    : `${saveDir}/screenshot-${root.timestampForFilename()}.png`;
                if (WindowsNative.screenshot.cropToFile(screenshotPath, rx, ry, rw, rh, savePath)) {
                    WindowsNative.clipboard.copyImageFile(savePath);
                    if (saveDir === "") Quickshell.execDetached(["cmd", "/c", "del", "/f", "/q", savePath.replace(/\//g, "\\")]);
                }
                cleanupRaw();
                break;
            }
            case ScreenshotAction.Action.Edit: {
                const cropPath = `${screenshotPath}-crop.png`;
                if (WindowsNative.screenshot.cropToFile(screenshotPath, rx, ry, rw, rh, cropPath)) {
                    // mspaint ships with every Windows 10/11 install and accepts a file to open
                    // for editing, the closest match to swappy/satty's "crop then annotate" step.
                    Quickshell.execDetached(["mspaint", cropPath]);
                }
                cleanupRaw();
                break;
            }
            case ScreenshotAction.Action.Search: {
                if (WindowsNative.screenshot.cropToFile(screenshotPath, rx, ry, rw, rh, screenshotPath)) {
                    // No jq on Windows; PowerShell's own JSON parsing replaces it.
                    const psCommand = `$resp = curl.exe -s -F "files[]=@${screenshotPath}" ${root.fileUploadApiEndpoint} | ConvertFrom-Json; `
                        + `Start-Process ("${root.imageSearchEngineBaseUrl}" + $resp.files[0].url); `
                        + `Remove-Item -Force '${screenshotPath}'`;
                    Quickshell.execDetached(["powershell", "-NoProfile", "-WindowStyle", "Hidden", "-Command", psCommand]);
                } else {
                    cleanupRaw();
                }
                break;
            }
            case ScreenshotAction.Action.CharRecognition: {
                const cropPath = `${screenshotPath}-crop.png`;
                if (WindowsNative.screenshot.cropToFile(screenshotPath, rx, ry, rw, rh, cropPath) && WindowsNative.ocr) {
                    const requestId = WindowsNative.ocr.recognizeText(cropPath);
                    root._pendingOcr[requestId] = cropPath;
                }
                cleanupRaw();
                break;
            }
            case ScreenshotAction.Action.Record:
                root.startWindowsRecording(rx + monitorOffsetX, ry + monitorOffsetY, rw, rh, false);
                break;
            case ScreenshotAction.Action.RecordWithSound:
                root.startWindowsRecording(rx + monitorOffsetX, ry + monitorOffsetY, rw, rh, true);
                break;
            default:
                console.warn("[Region Selector] Unknown snip action, skipping snip.");
        }
    }

    // Native recorder (Quickshell's ScreenRecorder: Windows.Graphics.Capture + Media Foundation,
    // no ffmpeg needed). Null/false where it can't work (Windows N without the Media Feature
    // Pack, older Quickshell builds); record.ps1 + ffmpeg remain the fallback there.
    readonly property QtObject windowsRecorder: (Platform.isWindows && WindowsNative.ready) ? WindowsNative.screenRecorder : null
    readonly property bool windowsNativeRecorder: root.windowsRecorder?.available ?? false
    readonly property bool windowsNativeRecording: root.windowsNativeRecorder && root.windowsRecorder.recording

    Connections {
        target: root.windowsNativeRecorder ? root.windowsRecorder : null
        function onStarted(path) {
            Notifications.sendDesktop(Translation.tr("Starting recording"), FileUtils.fileNameForPath(path));
        }
        function onFinished(path) {
            Notifications.sendDesktop(Translation.tr("Recording Stopped"), path);
        }
        function onFailed(reason) {
            Notifications.sendDesktop(Translation.tr("Recording failed"), reason);
        }
        function onSoundUnavailable(reason) {
            Notifications.sendDesktop(Translation.tr("Recording without sound"), reason);
        }
    }

    function startWindowsRecording(x, y, width, height, sound) {
        const saveDir = Config.options.screenRecord.savePath;
        if (root.windowsNativeRecorder) {
            // Notifications come from the Connections above (started/failed).
            root.windowsRecorder.start(Math.round(x), Math.round(y), Math.round(width), Math.round(height), sound, saveDir);
            return;
        }

        // yuv420p needs even dimensions; shaving at most 1px off is unnoticeable.
        const evenW = width - (width % 2);
        const evenH = height - (height % 2);
        const args = [
            "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", root.windowsRecordScript,
            "-X", String(Math.round(x)), "-Y", String(Math.round(y)),
            "-Width", String(evenW), "-Height", String(evenH),
            "-PidFile", Directories.recordingPidFile
        ];
        if (saveDir) args.push("-SaveDir", saveDir);
        if (sound) args.push("-Sound");
        windowsRecordProc.command = args;
        windowsRecordProc.running = true;
        Notifications.sendDesktop(Translation.tr("Starting recording"), Translation.tr("Recording region…"));
    }

    function stopWindowsRecording() {
        if (root.windowsNativeRecording) {
            root.windowsRecorder.stop();
            return;
        }
        windowsRecordProc.command = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
            root.windowsRecordScript, "-Stop", "-PidFile", Directories.recordingPidFile];
        windowsRecordProc.running = true;
    }

    // Record screen (the overlay's recorder widget; record.sh --fullscreen on Linux): stops a
    // running recording, otherwise records the whole of `monitor` (a HyprlandMonitor, whose
    // x/y/width/height are physical pixels on Windows).
    function toggleWindowsScreenRecording(monitor, sound) {
        if (!monitor) return;
        if (root.windowsNativeRecorder) {
            if (root.windowsNativeRecording) root.windowsRecorder.stop();
            else root.startWindowsRecording(monitor.x, monitor.y, monitor.width, monitor.height, sound);
            return;
        }
        windowsScreenToggleProc.monitor = monitor;
        windowsScreenToggleProc.sound = sound;
        windowsScreenToggleProc.running = true;
    }

    Process {
        // ffmpeg fallback of toggleWindowsScreenRecording(): same status check as the region
        // selector's (see windowsRecordingStatusCommand()).
        id: windowsScreenToggleProc
        property var monitor: null
        property bool sound: false
        command: root.windowsRecordingStatusCommand()
        onExited: (exitCode, exitStatus) => {
            const m = windowsScreenToggleProc.monitor;
            if (exitCode === 0) root.stopWindowsRecording();
            else if (exitCode === 2) root.startWindowsRecording(m.x, m.y, m.width, m.height, windowsScreenToggleProc.sound);
            else root.offerFfmpegInstall();
        }
    }

    // Shown when recording was asked for, the native recorder is unavailable and ffmpeg isn't
    // on PATH either: offers installing ffmpeg with winget, in a console the user can watch
    // (winget may ask to accept its source agreements there).
    property int _ffmpegNoticeId: -1
    function offerFfmpegInstall() {
        const reason = root.windowsRecorder?.unavailableReason ?? "";
        const body = (reason ? Translation.tr("Built-in recording is unavailable: %1.").arg(reason) + " " : "")
            + Translation.tr("Recording can use ffmpeg instead (the shell may need a restart to find it after installing).");
        root._ffmpegNoticeId = Notifications.sendDesktop(Translation.tr("Recording needs ffmpeg"), body,
            ["-A", `install=${Translation.tr("Install with winget")}`]) ?? -1;
    }
    Connections {
        target: Platform.isWindows ? Notifications : null
        function onDesktopActionInvoked(id, action) {
            if (id !== root._ffmpegNoticeId || action !== "install") return;
            root._ffmpegNoticeId = -1;
            Quickshell.execDetached(["powershell", "-NoProfile", "-Command",
                "Start-Process winget -ArgumentList 'install','--exact','--id','Gyan.FFmpeg'"]);
        }
    }

    readonly property string windowsRecordScript: FileUtils.trimFileProtocol(`${Directories.scriptPath}/videos/record.ps1`)

    Process {
        // record.ps1 reports on stdout: "nosound" (no loopback device for -Sound) when starting,
        // "saved <file>" once a stopped recording is remuxed.
        id: windowsRecordProc
        stdout: SplitParser {
            onRead: line => {
                if (line === "nosound") {
                    Notifications.sendDesktop(Translation.tr("Recording without sound"),
                        Translation.tr("No loopback device found. Enable \"Stereo Mix\" in Windows sound settings (Recording devices) or install a virtual audio cable."));
                } else if (line.startsWith("saved ")) {
                    Notifications.sendDesktop(Translation.tr("Recording Stopped"), line.slice(6));
                }
            }
        }
    }

    // Command for RegionSelection.qml's checkRecordingProc on Windows: exit 0 if a recording ii
    // started is still running (mirrors `pidof wf-recorder`'s "found" case), exit 1 if not and
    // ffmpeg isn't on PATH either (caller should notify and bail instead of showing the region
    // UI), exit 2 if not recording and ffmpeg is available (proceed normally).
    function windowsRecordingStatusCommand() {
        const pidFile = Directories.recordingPidFile;
        const script = `if (Test-Path '${pidFile}') { `
            + `$p = Get-Content '${pidFile}' -ErrorAction SilentlyContinue; `
            + `if ($p -and (Get-Process -Id $p -ErrorAction SilentlyContinue)) { exit 0 }; `
            + `Remove-Item -Force '${pidFile}' -ErrorAction SilentlyContinue }; `
            + `if (Get-Command ffmpeg -ErrorAction SilentlyContinue) { exit 2 } else { exit 1 }`;
        return ["powershell", "-NoProfile", "-Command", script];
    }

    function getCommand(x, y, width, height, screenshotPath, action, saveDir = "") {
        // Set command for action
        const rx = Math.round(x);
        const ry = Math.round(y);
        const rw = Math.round(width);
        const rh = Math.round(height);
        const cropBase = `magick ${StringUtils.shellSingleQuoteEscape(screenshotPath)} `
            + `-crop ${rw}x${rh}+${rx}+${ry} +repage`
        const cropToStdout = `${cropBase} -`
        const cropInPlace = `${cropBase} '${StringUtils.shellSingleQuoteEscape(screenshotPath)}'`
        const cleanup = `rm '${StringUtils.shellSingleQuoteEscape(screenshotPath)}'`
        const slurpRegion = `${rx},${ry} ${rw}x${rh}`
        const uploadAndGetUrl = (filePath) => {
            return `curl -sF files[]=@'${StringUtils.shellSingleQuoteEscape(filePath)}' ${root.fileUploadApiEndpoint} | jq -r '.files[0].url'`
        }
        const annotationCommand = `${Config.options.regionSelector.annotation.useSatty ? "satty" : "swappy"} -f -`;
        switch (action) {
            case ScreenshotAction.Action.Copy:
                if (saveDir === "") {
                    // not saving the screenshot, just copy to clipboard
                    return ["bash", "-c", `${cropToStdout} | wl-copy && ${cleanup}`]
                    break;
                }
                return [
                    "bash", "-c",
                    `mkdir -p '${StringUtils.shellSingleQuoteEscape(saveDir)}' && \
                    saveFileName="screenshot-$(date '+%Y-%m-%d_%H.%M.%S').png" && \
                    savePath="${saveDir}/$saveFileName" && \
                    ${cropToStdout} | tee >(wl-copy) > "$savePath" && \
                    ${cleanup}`
                ]

                break;
            case ScreenshotAction.Action.Edit:
                return ["bash", "-c", `${cropToStdout} | ${annotationCommand} && ${cleanup}`]
                break;
            case ScreenshotAction.Action.Search:
                return ["bash", "-c", `${cropInPlace} && xdg-open "${root.imageSearchEngineBaseUrl}$(${uploadAndGetUrl(screenshotPath)})" && ${cleanup}`]
                break;
            case ScreenshotAction.Action.CharRecognition:
                return ["bash", "-c", `${cropInPlace} && tesseract '${StringUtils.shellSingleQuoteEscape(screenshotPath)}' stdout -l $(tesseract --list-langs | awk 'NR>1{print $1}' | tr '\\n' '+' | sed 's/\\+$/\\n/') | wl-copy && ${cleanup}`]
                break;
            case ScreenshotAction.Action.Record:
                return ["bash", "-c", `${Directories.recordScriptPath} --region '${slurpRegion}'`]
                break;
            case ScreenshotAction.Action.RecordWithSound:
                return ["bash", "-c", `${Directories.recordScriptPath} --region '${slurpRegion}' --sound`]
                break;
            default:
                console.warn("[Region Selector] Unknown snip action, skipping snip.");
                return;
        }
    }
}

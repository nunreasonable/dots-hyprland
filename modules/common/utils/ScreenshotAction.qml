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
            if (path) Quickshell.execDetached(["cmd", "/c", "del", "/f", "/q", path]);

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
    // native crop/clipboard/OCR helpers (WindowsNative.screenshot/clipboard/ocr) directly and
    // shells out only for the pieces that still need an external tool (curl.exe for image
    // search, ffmpeg for recording). monitorOffsetX/Y (physical pixels, HyprlandMonitor.x/y)
    // are only used for Record/RecordWithSound, to turn the region's per-monitor coordinates
    // into gdigrab's virtual-desktop-global ones.
    function runWindows(x, y, width, height, screenshotPath, action, saveDir = "", monitorOffsetX = 0, monitorOffsetY = 0) {
        if (!WindowsNative.ready || !WindowsNative.screenshot || !WindowsNative.clipboard) {
            console.warn("[Region Selector] Windows native helpers not ready, skipping snip.");
            return;
        }

        const rx = Math.round(x);
        const ry = Math.round(y);
        const rw = Math.round(width);
        const rh = Math.round(height);
        const cleanupRaw = () => Quickshell.execDetached(["cmd", "/c", "del", "/f", "/q", screenshotPath]);

        switch (action) {
            case ScreenshotAction.Action.Copy: {
                const savePath = saveDir === ""
                    ? `${screenshotPath}-crop.png`
                    : `${saveDir}/screenshot-${root.timestampForFilename()}.png`;
                if (WindowsNative.screenshot.cropToFile(screenshotPath, rx, ry, rw, rh, savePath)) {
                    WindowsNative.clipboard.copyImageFile(savePath);
                    if (saveDir === "") Quickshell.execDetached(["cmd", "/c", "del", "/f", "/q", savePath]);
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

    function startWindowsRecording(x, y, width, height, sound) {
        // yuv420p needs even dimensions; shaving at most 1px off is unnoticeable.
        const evenW = width - (width % 2);
        const evenH = height - (height % 2);
        const saveDir = Config.options.screenRecord.savePath;
        const scriptPath = `${Directories.scriptPath}/videos/record.ps1`;
        const args = [
            "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", scriptPath,
            "-X", String(Math.round(x)), "-Y", String(Math.round(y)),
            "-Width", String(evenW), "-Height", String(evenH),
            "-PidFile", Directories.recordingPidFile
        ];
        if (saveDir) args.push("-SaveDir", saveDir);
        if (sound) args.push("-Sound");
        Quickshell.execDetached(args);
        Notifications.sendDesktop(Translation.tr("Starting recording"), Translation.tr("Recording region…"));
    }

    function stopWindowsRecording() {
        const pidFile = Directories.recordingPidFile;
        Quickshell.execDetached(["powershell", "-NoProfile", "-Command",
            `if (Test-Path '${pidFile}') { $p = Get-Content '${pidFile}'; Stop-Process -Id $p -Force -ErrorAction SilentlyContinue; Remove-Item -Force '${pidFile}' }`
        ]);
        Notifications.sendDesktop(Translation.tr("Recording Stopped"), Translation.tr("Stopped"));
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

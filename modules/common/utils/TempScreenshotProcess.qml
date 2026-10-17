import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Item {
    id: root
    property bool running: false
    property string screenshotDir: Directories.screenshotTemp
    required property ShellScreen screen
    readonly property string requestTag: Platform.isWindows ? `-${Date.now().toString(36)}${Math.floor(Math.random() * 0xffffff).toString(36)}` : ""
    property string screenshotPath: `${screenshotDir}/image-${FileUtils.sanitizeFilename(screen?.name ?? "")}${requestTag}`
    signal exited(int exitCode, int exitStatus)

    Process {
        id: linuxProc
        running: root.running && !Platform.isWindows
        command: ["bash", "-c", `mkdir -p '${StringUtils.shellSingleQuoteEscape(root.screenshotDir)}' && grim -o '${StringUtils.shellSingleQuoteEscape(root.screen.name)}' '${StringUtils.shellSingleQuoteEscape(root.screenshotPath)}'`]
        onExited: (exitCode, exitStatus) => {
            root.running = false;
            root.exited(exitCode, exitStatus);
        }
    }

    property int windowsRequestId: -1
    property string windowsOwnedPath: ""

    function captureWindows() {
        if (!root.running) return;
        root.releaseWindows();
        const shot = WindowsNative.ready ? WindowsNative.screenshot : null;
        root.windowsOwnedPath = root.screenshotPath;
        if (shot && typeof shot.captureScreenAsync === "function") {
            const requestId = shot.captureScreenAsync(root.screen.name, root.windowsOwnedPath);
            root.windowsRequestId = requestId;
            if (requestId < 0) Qt.callLater(() => root.finishWindows(requestId, false));
            return;
        }
        const ok = shot ? shot.captureScreen(root.screen.name, root.windowsOwnedPath) : false;
        Qt.callLater(() => root.finishWindows(-1, ok));
    }

    function releaseWindows() {
        const shot = WindowsNative.ready ? WindowsNative.screenshot : null;
        if (root.windowsRequestId > 0 && typeof shot?.cancelCapture === "function")
            shot.cancelCapture(root.windowsRequestId);
        root.windowsRequestId = -1;
        const path = root.windowsOwnedPath;
        root.windowsOwnedPath = "";
        if (path.length === 0 || !shot) return;
        if (typeof shot.discardCapture === "function") {
            shot.discardCapture(path);
            return;
        }
        shot.releaseCapture(path);
        WindowsNative.fsUtils?.removeFile(path);
    }

    function finishWindows(requestId, ok) {
        if (requestId !== root.windowsRequestId) return;
        root.windowsRequestId = -1;
        if (!ok) console.warn("[TempScreenshotProcess] Native capture failed for", root.screen.name);
        root.running = false;
        root.exited(ok ? 0 : 1, 0);
    }

    Connections {
        target: Platform.isWindows && WindowsNative.ready ? WindowsNative.screenshot : null
        function onCaptureFinished(requestId, ok) {
            root.finishWindows(requestId, ok);
        }
    }

    onRunningChanged: {
        if (!running || !Platform.isWindows) return;
        Qt.callLater(root.captureWindows);
    }

    Component.onDestruction: {
        if (Platform.isWindows) root.releaseWindows();
    }
}

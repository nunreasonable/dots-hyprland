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
    property string screenshotPath: `${screenshotDir}/image-${FileUtils.sanitizeFilename(screen.name)}`
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

    function captureWindows() {
        if (!root.running) return;
        const shot = WindowsNative.ready ? WindowsNative.screenshot : null;
        if (shot && typeof shot.captureScreenAsync === "function") {
            root.windowsRequestId = shot.captureScreenAsync(root.screen.name, root.screenshotPath);
            if (root.windowsRequestId < 0) Qt.callLater(() => root.finishWindows(false));
            return;
        }
        const ok = shot ? shot.captureScreen(root.screen.name, root.screenshotPath) : false;
        Qt.callLater(() => root.finishWindows(ok));
    }

    function finishWindows(ok) {
        root.windowsRequestId = -1;
        if (!ok) console.warn("[TempScreenshotProcess] Native capture failed for", root.screen.name);
        root.running = false;
        root.exited(ok ? 0 : 1, 0);
    }

    Connections {
        target: Platform.isWindows && WindowsNative.ready ? WindowsNative.screenshot : null
        function onCaptureFinished(requestId, ok) {
            if (requestId === root.windowsRequestId) root.finishWindows(ok);
        }
    }

    onRunningChanged: {
        if (!running || !Platform.isWindows) return;
        Qt.callLater(root.captureWindows);
    }

    Component.onDestruction: {
        if (!Platform.isWindows || !WindowsNative.ready || !WindowsNative.screenshot) return;
        if (root.windowsRequestId > 0 && typeof WindowsNative.screenshot.cancelCapture === "function")
            WindowsNative.screenshot.cancelCapture(root.windowsRequestId);
        WindowsNative.screenshot.releaseCapture(root.screenshotPath);
    }
}

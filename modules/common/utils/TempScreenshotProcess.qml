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

    function captureWindows() {
        if (!root.running) return;
        const ok = (WindowsNative.ready && WindowsNative.screenshot)
            ? WindowsNative.screenshot.captureScreen(root.screen.name, root.screenshotPath)
            : false;
        if (!ok) console.warn("[TempScreenshotProcess] Native capture failed for", root.screen.name);
        Qt.callLater(() => {
            root.running = false;
            root.exited(ok ? 0 : 1, 0);
        });
    }

    onRunningChanged: {
        if (!running || !Platform.isWindows) return;
        Qt.callLater(root.captureWindows);
    }
}

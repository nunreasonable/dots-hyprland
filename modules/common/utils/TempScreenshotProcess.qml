import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

// Captures `screen` to `screenshotPath` and fires `exited` when done - a full-screen temp
// screenshot for the region selector / screen translator / waffle screen snip to crop from.
// On Linux this wraps a real `Process` running grim (unchanged). On Windows there's no process
// to spawn: it calls the native, already-blocking `WindowsNative.screenshot.captureScreen()`
// (see src/windows/system/screenshot.*) directly and synthesizes the same exited(exitCode, 0)
// signal a moment later, so every caller (which only ever sets `screen`/`screenshotDir`/
// `screenshotPath` and listens for `onExited`) needs no changes.
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
            // `running` reads like a Process's: false again once the capture is done (callers
            // check it to know whether the screenshot is still pending).
            root.running = false;
            root.exited(exitCode, exitStatus);
        }
    }

    onRunningChanged: {
        if (!running || !Platform.isWindows) return;
        const ok = (WindowsNative.ready && WindowsNative.screenshot)
            ? WindowsNative.screenshot.captureScreen(root.screen.name, root.screenshotPath)
            : false;
        if (!ok) console.warn("[TempScreenshotProcess] Native capture failed for", root.screen.name);
        // Deferred, not emitted inline: callers (RegionSelection.qml etc.) wire up onExited
        // right after setting `running`, same event-loop tick as this change, and a real
        // Process's exited would never fire synchronously from its own running:true binding.
        Qt.callLater(() => {
            root.running = false;
            root.exited(ok ? 0 : 1, 0);
        });
    }
}

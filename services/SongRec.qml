pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    enum MonitorSource { Monitor, Input }

    property var monitorSource: SongRec.MonitorSource.Monitor
    property int timeoutInterval: Config.options.musicRecognition.interval
    property int timeoutDuration: Config.options.musicRecognition.timeout
    readonly property bool running: recognizeMusicProc.running || windowsRecognizeProc.running

    function toggleRunning(running) {
        if (Platform.isWindows) {
            root.toggleRunningWindows(running);
            return;
        }
        if (recognizeMusicProc.running && !running === true) root.manuallyStopped = true;
        if (running != undefined) {
            recognizeMusicProc.running = running
        } else {
            recognizeMusicProc.running = !root.running
        }
        musicReconizedProc.running = false
    }

    function toggleMonitorSource(source) {
        if (source !== undefined) {
            root.monitorSource = source
            return
        }
        root.monitorSource = (root.monitorSource === SongRec.MonitorSource.Monitor) ? SongRec.MonitorSource.Input : SongRec.MonitorSource.Monitor
    }
    function monitorSourceToString(source) {
        if (source === SongRec.MonitorSource.Monitor) {
            return "monitor"
        } else {
            return "input"
        }
    }
    readonly property string monitorSourceString: monitorSourceToString(monitorSource)
    property var recognizedTrack: ({ title:"", subtitle:"", url:""})
    property bool manuallyStopped: false

    function handleRecognition(jsonText) {
        try {
            var obj = JSON.parse(jsonText)
            root.recognizedTrack = {
                title: obj.track.title,
                subtitle: obj.track.subtitle,
                url: obj.track.url
            }
            if (Platform.isWindows) root.notifyRecognizedWindows()
            else musicReconizedProc.running = true
        } catch(e) {
            Notifications.sendDesktop(Translation.tr("Couldn't recognize music"), Translation.tr("Perhaps what you're listening to is too niche"), ["-a", "Shell"])
        }
    }

    // --- Windows ---------------------------------------------------------------------------
    // songrec.exe is SongRec's recognizer built for Windows (GPL-3.0, shipped separately - see
    // the README). Its `recognize` does what recognize-music.sh does around `songrec listen`:
    // records the default output device (WASAPI loopback, --loopback) or the default
    // microphone, asks Shazam every `interval` seconds, prints the first match as Shazam's JSON
    // and exits, or exits empty-handed after `timeout` seconds.

    property string windowsSongrecPath: ""
    property int windowsNotificationId: -1
    // Snapshot of monitorSource for the run in flight, so a device error names the source
    // that was actually recorded even if the toggle is flipped again before songrec.exe exits.
    property var windowsRunMonitorSource: SongRec.MonitorSource.Monitor

    function toggleRunningWindows(running) {
        const start = running !== undefined ? running : !windowsRecognizeProc.running;
        if (!start) {
            if (windowsRecognizeProc.running) {
                root.manuallyStopped = true;
                // running = false only posts WM_CLOSE, which a console program never sees.
                windowsRecognizeProc.signal(9);
            }
            return;
        }
        if (windowsRecognizeProc.running) return;

        const fsUtils = WindowsNative.fsUtils;
        // Without FsUtils.findExecutable (older qs.exe), let CreateProcess search qs.exe's
        // folder and PATH for it.
        const path = (fsUtils && typeof fsUtils.findExecutable === "function")
            ? fsUtils.findExecutable("songrec.exe") : "songrec.exe";
        if (!path) {
            Notifications.sendDesktop(
                Translation.tr("Couldn't recognize music"),
                Translation.tr("Music recognition needs songrec.exe next to qs.exe or on PATH"),
                ["-a", "Shell"]
            );
            return;
        }
        root.windowsSongrecPath = path;
        root.windowsRunMonitorSource = root.monitorSource;
        root.manuallyStopped = false;
        windowsRecognizeProc.running = true;
    }

    function handleWindowsExit(exitCode, text) {
        // 2-4 are songrec.exe's own exit codes for these (see toolchain/songrec/songrec-win).
        if (exitCode === 2) {
            Notifications.sendDesktop(Translation.tr("Couldn't recognize music"),
                root.windowsRunMonitorSource === SongRec.MonitorSource.Monitor
                    ? Translation.tr("Couldn't record the system sound")
                    : Translation.tr("Couldn't record the microphone"),
                ["-a", "Shell"]);
        } else if (exitCode === 3) {
            Notifications.sendDesktop(Translation.tr("Couldn't recognize music"), Translation.tr("Couldn't reach Shazam. Check your connection"), ["-a", "Shell"]);
        } else if (exitCode === 4) {
            Notifications.sendDesktop(Translation.tr("Couldn't recognize music"), Translation.tr("Shazam is limiting requests from your IP. Try again later or raise the interval"), ["-a", "Shell"]);
        } else if (exitCode !== 0) {
            Notifications.sendDesktop(Translation.tr("Couldn't recognize music"), Translation.tr("songrec.exe failed (exit code %1)").arg(exitCode), ["-a", "Shell"]);
        } else {
            root.handleRecognition(text);
        }
    }

    function notifyRecognizedWindows() {
        root.windowsNotificationId = Notifications.sendDesktop(
            Translation.tr("Music Recognized"),
            root.recognizedTrack.title + " - " + root.recognizedTrack.subtitle,
            ["-A", "Shazam", "-A", "YouTube", "-a", "Shell"]
        );
    }

    Connections {
        target: Platform.isWindows ? Notifications : null
        function onDesktopActionInvoked(id, action) {
            if (id !== root.windowsNotificationId) return;
            // Unnamed -A actions are numbered like notify-send's ("0" = Shazam, "1" = YouTube).
            if (action === "0") {
                Qt.openUrlExternally(root.recognizedTrack.url);
            } else if (action === "1") {
                Qt.openUrlExternally("https://www.youtube.com/results?search_query=" + encodeURIComponent(root.recognizedTrack.title + " - " + root.recognizedTrack.subtitle));
            }
        }
    }

    Process {
        id: windowsRecognizeProc
        running: false
        command: [root.windowsSongrecPath, "recognize", "--json",
            "--request-interval", String(root.timeoutInterval),
            "--timeout", String(root.timeoutDuration),
            ...(root.monitorSource === SongRec.MonitorSource.Monitor ? ["--loopback"] : [])]
        stdout: StdioCollector {
            id: windowsRecognizeStdout
        }
        onExited: (exitCode, exitStatus) => {
            if (root.manuallyStopped) {
                root.manuallyStopped = false;
                return;
            }
            root.handleWindowsExit(exitCode, windowsRecognizeStdout.text);
        }
    }

    // --- Linux -----------------------------------------------------------------------------

    Process {
        id: recognizeMusicProc
        running: false
        command: [`${Directories.scriptPath}/musicRecognition/recognize-music.sh`, "-i", root.timeoutInterval, "-t", root.timeoutDuration, "-s", root.monitorSourceString]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.manuallyStopped) {
                    root.manuallyStopped = false
                    return
                }
                handleRecognition(this.text)
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 1) {
                Notifications.sendDesktop(Translation.tr("Couldn't recognize music"), Translation.tr("Make sure you have songrec installed"), ["-a", "Shell"])
            }
        }
    }

    Process {
        id: musicReconizedProc
        running: false
        command: [
            "notify-send",
            Translation.tr("Music Recognized"), 
            root.recognizedTrack.title + " - " + root.recognizedTrack.subtitle, 
            "-A", "Shazam",
            "-A", "YouTube",
            "-a", "Shell"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text === "") return
                if (this.text == 0) {
                    Qt.openUrlExternally(root.recognizedTrack.url);
                } else {
                    Qt.openUrlExternally("https://www.youtube.com/results?search_query=" + root.recognizedTrack.title + " - " + root.recognizedTrack.subtitle);
                }
            }
        }
    }
}
pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool packageManagerRunning: false
    property bool downloadRunning: false

    function refresh() {
        packageManagerRunning = false;
        downloadRunning = false;
        if (Platform.isWindows) {
            windowsCheckDelay.restart();
            return;
        }
        detectPackageManagerProc.running = false;
        detectPackageManagerProc.running = true;
        detectDownloadProc.running = false;
        detectDownloadProc.running = true;
    }

    Process {
        id: detectPackageManagerProc
        command: ["bash", "-c", "pidof yay paru dnf zypper apt apx xbps snap apk yum epsi pikman || ls /var/lib/pacman/db.lck"]
        onExited: (exitCode, exitStatus) => {
            root.packageManagerRunning = (exitCode === 0);
        }
    }

    Process {
        id: detectDownloadProc
        command: ["bash", "-c", "pidof curl wget aria2c yt-dlp || ls ~/Downloads | grep -E '\.crdownload$|\.part$'"]
        onExited: (exitCode, exitStatus) => {
            root.downloadRunning = (exitCode === 0);
        }
    }

    property list<string> windowsPackageManagerProcessNames: [
        "winget.exe",
        "appinstallercli.exe",
        "msiexec.exe",
        "wuauclt.exe",
        "usoclient.exe",
        "mousocoreworker.exe",
        "tiworker.exe",
    ]

    Process {
        id: detectPackageManagerProcWin
        command: ["tasklist.exe", "/FO", "CSV", "/NH"]
        stdout: StdioCollector {
            id: packageManagerCollector
            onStreamFinished: {
                const runningLower = packageManagerCollector.text.toLowerCase();
                root.packageManagerRunning = root.windowsPackageManagerProcessNames.some(
                    name => runningLower.includes(name)
                );
            }
        }
    }

    property list<string> windowsPartialDownloadExtensions: [".crdownload", ".part", ".partial", ".download"]

    function detectDownloadsWindows() {
        const fs = WindowsNative.fsUtils;
        if (!fs)
            return;
        const files = fs.listDir(FileUtils.trimFileProtocol(Directories.downloads));
        root.downloadRunning = files.some(name => {
            const lower = name.toLowerCase();
            return root.windowsPartialDownloadExtensions.some(ext => lower.endsWith(ext));
        });
    }

    Timer {
        id: windowsCheckDelay
        interval: 250
        onTriggered: {
            detectPackageManagerProcWin.running = false;
            detectPackageManagerProcWin.running = true;
            root.detectDownloadsWindows();
        }
    }
}

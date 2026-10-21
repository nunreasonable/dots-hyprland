pragma Singleton

import qs.services
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool collecting: false
    property string zipPath: ""
    property string lastError: ""
    property bool includeCrashDump: false
    readonly property string newIssueUrl: "https://github.com/nunreasonable/ii-windows/issues/new"
    readonly property var styleNames: ({
            "ii": "illogical-impulse (ii)",
            "end4pc": "end4-pC",
            "nabyscape": "NabyScape"
        })

    function bugReportUrl(zip) {
        const fields = {
            "template": "bug_report.yml",
            "version": SelfUpdate.installedVersion,
            "windows": `${SystemInfo.distroName}, build ${SystemInfo.windowsBuild}`,
            "style": root.styleNames[Config.options.appearance.visualStyle] ?? "",
            "family": Config.options.panelFamily,
            "logs": `Problem report: ${zip.split(/[\\/]/).pop()} (drag the zip here)`
        };
        const query = Object.keys(fields).filter(key => fields[key]).map(key => `${key}=${encodeURIComponent(fields[key])}`).join("&");
        return `${root.newIssueUrl}?${query}`;
    }

    function collect() {
        if (!Platform.isWindows || root.collecting)
            return;
        root.collecting = true;
        root.zipPath = "";
        root.lastError = "";
        const screens = Quickshell.screens.map(s => `${s.name} ${s.width}x${s.height} x${s.devicePixelRatio}`).join("; ");
        const command = ["powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", FileUtils.trimFileProtocol(`${Directories.scriptPath}/report/collect-report.ps1`), "-Version", SelfUpdate.installedVersion, "-Screens", screens, "-Style", Config.options.appearance.visualStyle, "-Family", Config.options.panelFamily];
        if (root.includeCrashDump)
            command.push("-IncludeDump");
        reportProc.command = command;
        reportProc.running = true;
    }

    Process {
        id: reportProc
        stdout: StdioCollector {
            id: reportOut
        }
        stderr: StdioCollector {
            id: reportErr
        }
        onExited: (exitCode, exitStatus) => {
            root.collecting = false;
            const lines = reportOut.text.trim().split("\n");
            const last = (lines[lines.length - 1] ?? "").trim();
            if (exitCode === 0 && last.toLowerCase().endsWith(".zip")) {
                root.zipPath = last;
                Quickshell.execDetached(["explorer.exe", `/select,${last}`]);
                Qt.openUrlExternally(root.bugReportUrl(last));
                return;
            }
            const error = reportErr.text.trim().split("\n")[0] ?? "";
            root.lastError = error.length > 0 ? error : Translation.tr("PowerShell exited with code %1").arg(exitCode);
        }
    }
}

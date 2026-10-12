pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property alias checking: checkUpdatesProc.running
    property int count: 0

    readonly property bool updateAdvised: available && count > Config.options.updates.adviseUpdateThreshold
    readonly property bool updateStronglyAdvised: available && count > Config.options.updates.stronglyAdviseUpdateThreshold

    function load() {}
    function refresh() {
        if (!available) return;
        print("[Updates] Checking for system updates")
        checkUpdatesProc.running = true;
    }

    function wingetUpgradeCount(text) {
        const lines = text.split(/\r?\n/);
        let dividerIndex = -1;
        for (let i = 0; i < lines.length; i++) {
            const trimmed = lines[i].trim();
            if (trimmed.length >= 5 && /^-+$/.test(trimmed)) {
                dividerIndex = i;
                break;
            }
        }
        if (dividerIndex === -1)
            return 0;
        let n = 0;
        for (let i = dividerIndex + 1; i < lines.length; i++) {
            const trimmed = lines[i].trim();
            if (trimmed.length === 0 || /^-+$/.test(trimmed))
                break;
            n++;
        }
        return n;
    }

    Timer {
        interval: Config.options.updates.checkInterval * 60 * 1000
        repeat: true
        running: Config.ready && Config.options.updates.enableCheck
        onTriggered: {
            print("[Updates] Periodic update check due")
            root.refresh();
        }
    }

    Process {
        id: checkAvailabilityProc
        running: Config.ready && Config.options.updates.enableCheck
        command: Platform.isWindows ? ["winget.exe", "--version"] : ["which", "checkupdates"]
        onExited: (exitCode, exitStatus) => {
            root.available = (exitCode === 0);
            root.refresh();
        }
    }

    Process {
        id: checkUpdatesProc
        command: Platform.isWindows
            ? ["winget.exe", "upgrade", "--disable-interactivity", "--accept-source-agreements"]
            : ["bash", "-c", "checkupdates | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.count = Platform.isWindows ? root.wingetUpgradeCount(text) : parseInt(text.trim());
            }
        }
    }
}

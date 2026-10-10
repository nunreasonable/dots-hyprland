pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property int version: 1
    readonly property string terminalAppId: "Microsoft.WindowsTerminal_8wekyb3d8bbwe!App"

    function load() {}

    readonly property bool _pending: Platform.isWindows && Config.ready
        && (Config.options.windowsPort.pinsVersion ?? 0) < root.version
        && DesktopEntries.applications.values.length > 0

    on_PendingChanged: {
        if (root._pending)
            Qt.callLater(root.migrate);
    }

    function _replace(list, map) {
        const result = [];
        for (const id of list) {
            const key = id.toLowerCase();
            const next = map.hasOwnProperty(key) ? map[key] : id;
            if (next && !result.some(existing => existing.toLowerCase() === next.toLowerCase()))
                result.push(next);
        }
        return result;
    }

    function migrate() {
        if (!root._pending)
            return;

        const hasTerminal = DesktopEntries.byId(root.terminalAppId) !== null;
        const dockTerminal = hasTerminal ? root.terminalAppId : "powershell";
        const launcherExplorer = DesktopEntries.byId("explorer")?.id ?? "";
        const launcherTerminal = DesktopEntries.byId(dockTerminal)?.id ?? "";
        const terminalKey = root.terminalAppId.toLowerCase();

        const dock = Config.options.dock;
        dock.pinnedApps = root._replace(dock.pinnedApps, {
            "org.kde.dolphin": "explorer",
            "kitty": dockTerminal,
            [terminalKey]: dockTerminal
        });

        const launcher = Config.options.launcher;
        launcher.pinnedApps = root._replace(launcher.pinnedApps, {
            "org.kde.dolphin": launcherExplorer,
            "kitty": launcherTerminal,
            "cmake-gui": "",
            [terminalKey]: launcherTerminal
        });

        Config.options.windowsPort.pinsVersion = root.version;
    }
}

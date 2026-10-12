pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.common

Singleton {
    id: root

    readonly property var autostart: Config.options.hyprland.autostartApps
    property bool startedAtBoot: false

    function splitCommand(cmd) {
        const matches = cmd.trim().match(/"[^"]*"|\S+/g) || [];
        return matches.map(part => part.replace(/^"|"$/g, ""));
    }

    function resolveCommand(cmd) {
        const parts = root.splitCommand(cmd ?? "");
        if (parts.length === 0)
            return null;

        const direct = WindowsNative.fsUtils?.findExecutable(parts[0]) ?? "";
        if (direct)
            return [direct, ...parts.slice(1)];

        const trimmed = cmd.trim();
        const entry = DesktopEntries.byId(trimmed) ?? DesktopEntries.heuristicLookup(trimmed);
        if (entry && entry.command && entry.command.length > 0)
            return entry.command;

        return null;
    }

    Component {
        id: moveTimerComponent
        Timer {
            id: moveTimer
            property int pid: 0
            property int workspace: 1
            property int attempts: 0
            interval: 400
            repeat: true
            onTriggered: {
                Hyprland.dispatch(`movetoworkspace ${moveTimer.workspace},pid:${moveTimer.pid}`);
                moveTimer.attempts += 1;
                if (moveTimer.attempts >= 15) {
                    moveTimer.stop();
                    moveTimer.destroy();
                }
            }
        }
    }

    function moveToWorkspace(pid, workspace) {
        const timer = moveTimerComponent.createObject(root, {
            pid: pid,
            workspace: workspace
        });
        timer.start();
    }

    Component {
        id: processComponent
        Process {}
    }

    function launchEntry(entry) {
        if (!entry || !entry.cmd)
            return;

        const argv = root.resolveCommand(entry.cmd);
        if (!argv) {
            console.warn("[WindowsAutostartApps] Could not resolve", entry.cmd);
            return;
        }

        const proc = processComponent.createObject(root, {
            command: argv,
            running: true
        });

        const workspace = entry.workspace ?? 1;

        const tryMove = () => {
            if (!proc.processId)
                return;
            proc.processIdChanged.disconnect(tryMove);
            root.moveToWorkspace(proc.processId, workspace);
        };

        if (proc.processId)
            tryMove();
        else
            proc.processIdChanged.connect(tryMove);
    }

    Component {
        id: delayTimerComponent
        Timer {
            id: delayTimer
            property var entry: null
            repeat: false
            onTriggered: {
                root.launchEntry(delayTimer.entry);
                delayTimer.destroy();
            }
        }
    }

    function launchAll() {
        for (const entry of root.autostart.apps ?? []) {
            if (!entry.cmd)
                continue;

            if ((entry.delay ?? 0) > 0) {
                const timer = delayTimerComponent.createObject(root, {
                    entry: entry,
                    interval: entry.delay * 1000
                });
                timer.start();
            } else {
                root.launchEntry(entry);
            }
        }
    }

    function runAllNow() {
        for (const entry of root.autostart.apps ?? []) {
            if (entry.cmd)
                root.launchEntry(entry);
        }
    }

    function runAtStartup() {
        if (!Platform.isWindows || root.startedAtBoot || !root.autostart.enable)
            return;
        root.startedAtBoot = true;
        root.launchAll();
    }
}

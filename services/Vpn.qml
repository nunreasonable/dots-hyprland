pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common

Singleton {
    id: root

    property list<var> profiles: []
    property list<string> activeUuids: []
    property string selectedUuid: ""
    property bool busy: connectProc.running || disconnectProc.running || actionProc.running
    property string pendingUuid: ""

    signal dialogRequested()

    readonly property var activeProfile: profiles.find(p => activeUuids.includes(p.uuid)) ?? null
    readonly property var selectedProfile: activeProfile ?? profiles.find(p => p.uuid === selectedUuid) ?? profiles[0] ?? null
    readonly property bool available: profiles.length > 0
    readonly property bool connected: activeProfile !== null

    function splitFields(line) {
        const fields = [];
        let current = "";
        for (let i = 0; i < line.length; i++) {
            if (line[i] === "\\" && line[i + 1] === ":") {
                current += ":";
                i++;
            } else if (line[i] === ":") {
                fields.push(current);
                current = "";
            } else {
                current += line[i];
            }
        }
        fields.push(current);
        return fields;
    }

    function psQuote(value) {
        return `'${String(value).replace(/'/g, "''")}'`;
    }

    function refresh() {
        if (Platform.isWindows) {
            if (!listProcWin.running)
                listProcWin.running = true;
            return;
        }
        if (!listProc.running)
            listProc.running = true;
    }

    function toggle() {
        const profile = root.selectedProfile;
        if (!profile) {
            root.dialogRequested();
            return;
        }
        if (root.busy)
            return;
        if (root.connected) {
            root.pendingUuid = "";
            if (Platform.isWindows)
                disconnectProc.command = ["rasdial", root.activeProfile.uuid, "/DISCONNECT"];
            else
                disconnectProc.command = ["nmcli", "connection", "down", "uuid", root.activeProfile.uuid];
            disconnectProc.running = true;
        } else {
            root.connectTo(profile.uuid);
        }
    }

    function connectTo(uuid) {
        if (root.busy)
            return;
        if (root.connected && root.activeProfile.uuid !== uuid) {
            root.pendingUuid = uuid;
            if (Platform.isWindows)
                disconnectProc.command = ["rasdial", root.activeProfile.uuid, "/DISCONNECT"];
            else
                disconnectProc.command = ["nmcli", "connection", "down", "uuid", root.activeProfile.uuid];
            disconnectProc.running = true;
            return;
        }
        root.pendingUuid = "";
        if (Platform.isWindows)
            connectProc.command = ["rasdial", uuid];
        else
            connectProc.command = ["nmcli", "connection", "up", "uuid", uuid];
        connectProc.running = true;
    }

    function remove(uuid) {
        if (Platform.isWindows) {
            actionProc.command = ["powershell", "-NoProfile", "-Command", `Remove-VpnConnection -Name ${root.psQuote(uuid)} -Force -ErrorAction Stop`];
        } else {
            actionProc.command = ["nmcli", "connection", "delete", "uuid", uuid];
        }
        actionProc.running = true;
    }

    function importFile(path) {
        if (Platform.isWindows) {
            root.notifyFailure(Translation.tr("Importing VPN config files isn't supported on Windows. Add the connection in Settings > Network > VPN instead."));
            return;
        }
        const type = path.toLowerCase().endsWith(".ovpn") ? "openvpn" : "wireguard";
        actionProc.command = ["nmcli", "connection", "import", "type", type, "file", path];
        actionProc.running = true;
    }

    function pickAndImport() {
        if (Platform.isWindows) {
            root.notifyFailure(Translation.tr("Importing VPN config files isn't supported on Windows. Add the connection in Settings > Network > VPN instead."));
            return;
        }
        if (!pickerProc.running)
            pickerProc.running = true;
    }

    function notifyFailure(message) {
        Notifications.sendDesktop("VPN", message, ["-a", "Shell"]);
    }

    Timer {
        running: GlobalStates.sidebarRightOpen
        interval: 4000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: listProc
        command: ["bash", "-c", "nmcli -t -f NAME,UUID,TYPE connection show; echo :::ACTIVE; nmcli -t -f UUID connection show --active"]
        stdout: StdioCollector {
            id: listCollector
            onStreamFinished: {
                const parts = listCollector.text.split(":::ACTIVE");
                const activeUuids = (parts[1] ?? "").split("\n").map(l => l.trim()).filter(l => l.length > 0);
                const profiles = (parts[0] ?? "").split("\n").filter(l => l.trim().length > 0).map(line => {
                    const fields = root.splitFields(line);
                    return {
                        name: fields[0] ?? "",
                        uuid: fields[1] ?? "",
                        type: fields[2] ?? ""
                    };
                }).filter(p => p.type === "vpn" || p.type === "wireguard");
                root.profiles = profiles;
                root.activeUuids = activeUuids;
            }
        }
    }

    Process {
        id: listProcWin
        command: ["powershell", "-NoProfile", "-Command", "Get-VpnConnection -ErrorAction SilentlyContinue | Select-Object Name,ConnectionStatus | ConvertTo-Json -Compress"]
        stdout: StdioCollector {
            id: listWinCollector
            onStreamFinished: {
                let parsed = [];
                const text = listWinCollector.text.trim();
                if (text.length > 0) {
                    try {
                        const data = JSON.parse(text);
                        parsed = Array.isArray(data) ? data : [data];
                    } catch (e) {
                        parsed = [];
                    }
                }
                root.profiles = parsed.map(entry => ({
                            name: entry.Name ?? "",
                            uuid: entry.Name ?? "",
                            type: "vpn"
                        })).filter(p => p.uuid !== "");
                root.activeUuids = parsed.filter(entry => entry.ConnectionStatus === "Connected").map(entry => entry.Name);
            }
        }
    }

    Process {
        id: connectProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.notifyFailure(Translation.tr("Failed to connect."));
            root.refresh();
        }
    }
    Process {
        id: disconnectProc
        onExited: (exitCode, exitStatus) => {
            if (root.pendingUuid !== "") {
                const next = root.pendingUuid;
                root.pendingUuid = "";
                root.connectTo(next);
            } else {
                root.refresh();
            }
        }
    }
    Process {
        id: actionProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.notifyFailure(Translation.tr("VPN action failed."));
            root.refresh();
        }
    }
    Process {
        id: pickerProc
        command: ["bash", "-c", "kdialog --getopenfilename \"$HOME\" '*.conf *.ovpn|VPN configs' 2>/dev/null || zenity --file-selection --file-filter='*.conf *.ovpn' 2>/dev/null"]
        stdout: StdioCollector {
            id: pickerCollector
            onStreamFinished: {
                const path = pickerCollector.text.trim();
                if (path.length > 0)
                    root.importFile(path);
            }
        }
    }
}

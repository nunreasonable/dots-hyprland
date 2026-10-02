pragma Singleton
pragma ComponentBehavior: Bound

// Took many bits from https://github.com/caelestia-dots/shell (GPLv3)

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services.network
import qs.modules.common

/**
 * Network service: nmcli on Linux, the native WlanAPI/INetworkListManager-backed
 * `WindowsNative.network` (Quickshell.Windows' Network singleton) on Windows.
 */
Singleton {
    id: root

    property bool wifi: true
    // On Windows this is a live binding onto WindowsNative.network; the Linux process handlers
    // below imperatively overwrite it (and everything else in this block), which detaches that
    // binding there and is a no-op on Windows, since those processes never run there (same
    // pattern as services/ResourceUsage.qml).
    property bool ethernet: Platform.isWindows ? (WindowsNative.network ? WindowsNative.network.ethernetConnected : false) : false

    property bool wifiEnabled: Platform.isWindows ? (WindowsNative.network ? WindowsNative.network.wifiRadioOn : false) : false
    property bool wifiScanning: Platform.isWindows ? (WindowsNative.network ? WindowsNative.network.wifiScanning : false) : false
    property bool wifiConnecting: Platform.isWindows ? (WindowsNative.network ? WindowsNative.network.wifiConnecting : false) : connectProc.running
    property WifiAccessPoint wifiConnectTarget
    readonly property list<WifiAccessPoint> wifiNetworks: []
    readonly property WifiAccessPoint active: wifiNetworks.find(n => n.active) ?? null
    readonly property list<var> friendlyWifiNetworks: [...wifiNetworks].sort((a, b) => {
        if (a.active && !b.active)
            return -1;
        if (!a.active && b.active)
            return 1;
        return b.strength - a.strength;
    })
    property string wifiStatus: Platform.isWindows ? (WindowsNative.network ? WindowsNative.network.wifiStatus : "disabled") : "disconnected"
    // True on 24H2+ when Wi-Fi scan/connection-state queries are blocked because Settings >
    // Privacy > Location (or "let desktop apps access your location") is off. Windows-only;
    // always false on Linux. WifiDialog/WifiControl show a hint + button to fix it.
    readonly property bool wifiNeedsLocationPermission: Platform.isWindows && WindowsNative.network ? WindowsNative.network.needsLocationPermission : false

    property string networkName: Platform.isWindows ? (WindowsNative.network ? (WindowsNative.network.ethernetConnected ? Translation.tr("Ethernet") : WindowsNative.network.activeSsid) : "") : ""
    property int networkStrength: Platform.isWindows ? (WindowsNative.network ? WindowsNative.network.activeSignalQuality : 0) : 0

    // Windows: `networks.values` is a live list of native NetworkWifiNetwork objects (reused
    // across rescans, so their own properties update in place); mirror it into wifiNetworks the
    // same way getNetworks.onStreamFinished below mirrors nmcli's parsed list.
    readonly property list<var> winWifiNetworksRaw: (Platform.isWindows && WindowsNative.network) ? WindowsNative.network.networks.values : []
    onWinWifiNetworksRawChanged: {
        const rNetworks = root.wifiNetworks;
        const destroyed = rNetworks.filter(rn => !winWifiNetworksRaw.includes(rn.lastIpcObject));
        for (const network of destroyed)
            rNetworks.splice(rNetworks.indexOf(network), 1).forEach(n => n.destroy());

        for (const native of winWifiNetworksRaw) {
            if (!rNetworks.some(n => n.lastIpcObject === native))
                rNetworks.push(apComp.createObject(root, {
                    lastIpcObject: native
                }));
        }
    }

    Connections {
        target: Platform.isWindows ? WindowsNative.network : null
        function onWifiConnectResult(ssid, success, reason) {
            if (root.wifiConnectTarget && root.wifiConnectTarget.ssid === ssid) {
                root.wifiConnectTarget.askingPassword = !success;
                root.wifiConnectTarget = null;
            }
        }
    }
    property string materialSymbol: root.ethernet
        ? "lan"
        : (root.wifiEnabled && root.wifiStatus === "connected")
            ? (
                (root.active?.strength ?? 0) > 83 ? "signal_wifi_4_bar" :
                (root.active?.strength ?? 0) > 67 ? "network_wifi" :
                (root.active?.strength ?? 0) > 50 ? "network_wifi_3_bar" :
                (root.active?.strength ?? 0) > 33 ? "network_wifi_2_bar" :
                (root.active?.strength ?? 0) > 17 ? "network_wifi_1_bar" :
                "signal_wifi_0_bar"
            )
            : (root.wifiStatus === "connecting")
                ? "signal_wifi_statusbar_not_connected"
                : (root.wifiStatus === "disconnected")
                    ? "wifi_find"
                    : (root.wifiStatus === "disabled")
                        ? "signal_wifi_off"
                        : "signal_wifi_bad"

    // Control
    function enableWifi(enabled = true): void {
        if (Platform.isWindows) {
            if (WindowsNative.network) WindowsNative.network.setWifiRadioEnabled(enabled);
            return;
        }
        const cmd = enabled ? "on" : "off";
        enableWifiProc.exec(["nmcli", "radio", "wifi", cmd]);
    }

    function toggleWifi(): void {
        enableWifi(!wifiEnabled);
    }

    function rescanWifi(): void {
        if (Platform.isWindows) {
            if (WindowsNative.network) WindowsNative.network.scanWifiNetworks();
            return;
        }
        wifiScanning = true;
        rescanProcess.running = true;
    }

    // Windows: starts/stops the periodic background rescan (see network.hpp); call with true
    // while ii's Wi-Fi list is on screen (WifiDialog/WifiControl do this on show/hide, mirroring
    // how BluetoothDialog ties Bluetooth.defaultAdapter.discovering to its own visibility) and
    // false otherwise. No-op on Linux, where live updates instead come from `nmcli monitor`.
    function setWifiListVisible(visible: bool): void {
        if (!Platform.isWindows || !WindowsNative.network) return;
        WindowsNative.network.setWifiListVisible(visible);
    }

    function openWifiLocationSettings(): void {
        if (Platform.isWindows) WindowsNative.network?.openLocationSettings();
    }

    function connectToWifiNetwork(accessPoint: WifiAccessPoint): void {
        if (Platform.isWindows) {
            accessPoint.askingPassword = false;
            root.wifiConnectTarget = accessPoint;
            // Same effective UX as nmcli: an open or already-known network connects right away,
            // a secured network with no saved profile goes straight to the password prompt
            // instead of a doomed-to-fail attempt with an empty passphrase.
            if (accessPoint.isSecure && !accessPoint.lastIpcObject?.hasProfile) {
                accessPoint.askingPassword = true;
                root.wifiConnectTarget = null;
                return;
            }
            WindowsNative.network?.connectToNetwork(accessPoint.ssid, "");
            return;
        }
        accessPoint.askingPassword = false;
        root.wifiConnectTarget = accessPoint;
        // We use this instead of `nmcli connection up SSID` because this also creates a connection profile
        connectProc.exec(["nmcli", "dev", "wifi", "connect", accessPoint.ssid])

    }

    function disconnectWifiNetwork(): void {
        if (Platform.isWindows) {
            WindowsNative.network?.disconnectActive();
            return;
        }
        if (active) disconnectProc.exec(["nmcli", "connection", "down", active.ssid]);
    }

    function openPublicWifiPortal() {
        if (Platform.isWindows) {
            Qt.openUrlExternally("https://nmcheck.gnome.org/");
            return;
        }
        Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"]) // From some StackExchange thread, seems to work
    }

    function changePassword(network: WifiAccessPoint, password: string, username = ""): void {
        // TODO: enterprise wifi with username
        network.askingPassword = false;
        if (Platform.isWindows) {
            root.wifiConnectTarget = network;
            WindowsNative.network?.connectToNetwork(network.ssid, password);
            return;
        }
        changePasswordProc.exec({
            "environment": {
                "PASSWORD": password,
                "SSID": network.ssid
            },
            "command": ["bash", "-c", 'nmcli connection modify "$SSID" wifi-sec.psk "$PASSWORD"']
        })
    }

    Process {
        id: enableWifiProc
    }

    Process {
        id: connectProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: SplitParser {
            onRead: line => {
                // print(line)
                getNetworks.running = true
            }
        }
        stderr: SplitParser {
            onRead: line => {
                // print("err:", line)
                if (line.includes("Secrets were required")) {
                    root.wifiConnectTarget.askingPassword = true
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.wifiConnectTarget.askingPassword = (exitCode !== 0)
            root.wifiConnectTarget = null
        }
    }

    Process {
        id: disconnectProc
        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
    }

    Process {
        id: changePasswordProc
        onExited: { // Re-attempt connection after changing password
            connectProc.running = false
            connectProc.running = true
        }
    }

    Process {
        id: rescanProcess
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: SplitParser {
            onRead: {
                wifiScanning = false;
                getNetworks.running = true;
            }
        }
    }

    // Status update
    function update() {
        updateConnectionType.startCheck();
        wifiStatusProcess.running = true
        updateNetworkName.running = true;
        updateNetworkStrength.running = true;
    }

    Process {
        id: subscriber
        running: !Platform.isWindows
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root.update()
        }
    }

    Process {
        id: updateConnectionType
        property string buffer
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE d status && nmcli -t -f CONNECTIVITY g"]
        running: !Platform.isWindows
        function startCheck() {
            buffer = "";
            updateConnectionType.running = true;
        }
        stdout: SplitParser {
            onRead: data => {
                updateConnectionType.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            const lines = updateConnectionType.buffer.trim().split('\n');
            const connectivity = lines.pop() // none, limited, full
            let hasEthernet = false;
            let hasWifi = false;
            let wifiStatus = "disconnected";
            lines.forEach(line => {
                if (line.includes("ethernet") && line.includes("connected"))
                    hasEthernet = true;
                else if (line.includes("wifi:")) {
                    if (line.includes("disconnected")) {
                        wifiStatus = "disconnected"
                    }
                    else if (line.includes("connected")) {
                        hasWifi = true;
                        wifiStatus = "connected"

                        if (connectivity === "limited") {
                            hasWifi = false;
                            wifiStatus = "limited"
                        }
                    }
                    else if (line.includes("connecting")) {
                        wifiStatus = "connecting"
                    }
                    else if (line.includes("unavailable")) {
                        wifiStatus = "disabled"
                    }
                }
            });
            root.wifiStatus = wifiStatus;
            root.ethernet = hasEthernet;
            root.wifi = hasWifi;
        }
    }

    Process {
        id: updateNetworkName
        command: ["sh", "-c", "nmcli -t -f NAME c show --active | head -1"]
        running: !Platform.isWindows
        stdout: SplitParser {
            onRead: data => {
                root.networkName = data;
            }
        }
    }

    Process {
        id: updateNetworkStrength
        running: !Platform.isWindows
        command: ["sh", "-c", "nmcli -f IN-USE,SIGNAL,SSID device wifi | awk '/^\\*/{if (NR!=1) {print $2}}'"]
        stdout: SplitParser {
            onRead: data => {
                root.networkStrength = parseInt(data);
            }
        }
    }

    Process {
        id: wifiStatusProcess
        command: ["nmcli", "radio", "wifi"]
        Component.onCompleted: running = !Platform.isWindows
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
            }
        }
    }

    Process {
        id: getNetworks
        running: !Platform.isWindows
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const rep = new RegExp("\\\\:", "g");
                const rep2 = new RegExp(PLACEHOLDER, "g");

                const allNetworks = text.trim().split("\n").map(n => {
                    const net = n.replace(rep, PLACEHOLDER).split(":");
                    return {
                        active: net[0] === "yes",
                        strength: parseInt(net[1]),
                        frequency: parseInt(net[2]),
                        ssid: net[3],
                        bssid: net[4]?.replace(rep2, ":") ?? "",
                        security: net[5] || ""
                    };
                }).filter(n => n.ssid && n.ssid.length > 0);

                // Group networks by SSID and prioritize connected ones
                const networkMap = new Map();
                for (const network of allNetworks) {
                    const existing = networkMap.get(network.ssid);
                    if (!existing) {
                        networkMap.set(network.ssid, network);
                    } else {
                        // Prioritize active/connected networks
                        if (network.active && !existing.active) {
                            networkMap.set(network.ssid, network);
                        } else if (!network.active && !existing.active) {
                            // If both are inactive, keep the one with better signal
                            if (network.strength > existing.strength) {
                                networkMap.set(network.ssid, network);
                            }
                        }
                        // If existing is active and new is not, keep existing
                    }
                }

                const wifiNetworks = Array.from(networkMap.values());

                const rNetworks = root.wifiNetworks;

                const destroyed = rNetworks.filter(rn => !wifiNetworks.find(n => n.frequency === rn.frequency && n.ssid === rn.ssid && n.bssid === rn.bssid));
                for (const network of destroyed)
                    rNetworks.splice(rNetworks.indexOf(network), 1).forEach(n => n.destroy());

                for (const network of wifiNetworks) {
                    const match = rNetworks.find(n => n.frequency === network.frequency && n.ssid === network.ssid && n.bssid === network.bssid);
                    if (match) {
                        match.lastIpcObject = network;
                    } else {
                        rNetworks.push(apComp.createObject(root, {
                            lastIpcObject: network
                        }));
                    }
                }
            }
        }
    }

    Component {
        id: apComp

        WifiAccessPoint {}
    }
}

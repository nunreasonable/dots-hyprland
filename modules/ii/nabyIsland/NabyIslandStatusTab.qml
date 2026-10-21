pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell

Item {
    id: root

    readonly property var pages: [
        { id: "overview", name: Translation.tr("Overview") },
        { id: "hardware", name: Translation.tr("Hardware") },
        { id: "network", name: Translation.tr("Network") },
        { id: "storage", name: Translation.tr("Storage") },
    ]
    readonly property string page: root.pages.some(p => p.id === Persistent.states.nabyIsland.statusPage) ? Persistent.states.nabyIsland.statusPage : "overview"

    implicitHeight: pageLoader.y + pageLoader.implicitHeight

    function percent(value) {
        return `${(Math.max(0, value) * 100).toFixed(1)}%`;
    }

    function usage(used, total) {
        return `${ResourceUsage.kbToGbString(used)} / ${ResourceUsage.kbToGbString(total)}`;
    }

    function rate(bytesPerSecond) {
        const units = ["B/s", "KB/s", "MB/s", "GB/s"];
        let value = Math.max(0, Number(bytesPerSecond) || 0);
        let unit = 0;
        while (value >= 1024 && unit < units.length - 1) {
            value /= 1024;
            unit++;
        }
        return `${value.toFixed(unit > 0 && value < 100 ? 1 : 0)} ${units[unit]}`;
    }

    component StatRow: Item {
        id: row
        property string label: ""
        property string value: ""
        property real bar: -1
        width: parent?.width ?? 0
        height: row.bar >= 0 ? 38 : 26

        StyledText {
            anchors.left: parent.left
            y: 2
            width: parent.width * 0.42
            text: row.label
            color: "#ffffff"
            opacity: 0.6
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        StyledText {
            anchors.right: parent.right
            y: 0
            width: parent.width * 0.58
            horizontalAlignment: Text.AlignRight
            text: row.value
            color: "#ffffff"
            font.pixelSize: 14
            elide: Text.ElideLeft
        }

        Rectangle {
            visible: row.bar >= 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            width: parent.width
            height: 4
            radius: 2
            color: Qt.rgba(1, 1, 1, 0.16)

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, row.bar))
                height: parent.height
                radius: parent.radius
                color: "#ffffff"

                Behavior on width {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    StyledText {
        id: clock
        x: 0
        y: 0
        text: DateTime.time
        color: "#ffffff"
        font.pixelSize: 40
        font.weight: Font.DemiBold
        font.variableAxes: ({ "wght": 600 })
    }

    StyledText {
        id: date
        anchors.top: clock.bottom
        x: 0
        text: DateTime.longDate
        color: "#ffffff"
        opacity: 0.6
        font.pixelSize: 12
    }

    NabyIslandSubTabs {
        id: subTabs
        anchors.top: date.bottom
        anchors.topMargin: 12
        x: -6
        model: root.pages
        current: root.page
        onSelected: id => Persistent.states.nabyIsland.statusPage = id
    }

    Loader {
        id: pageLoader
        anchors.top: subTabs.bottom
        anchors.topMargin: 14
        width: parent.width
        sourceComponent: root.page === "hardware" ? hardwarePage : root.page === "network" ? networkPage : root.page === "storage" ? storagePage : overviewPage
    }

    Component {
        id: overviewPage

        Column {
            spacing: 8

            StatRow {
                label: Translation.tr("CPU")
                value: root.percent(ResourceUsage.cpuUsage)
                bar: ResourceUsage.cpuUsage
            }

            StatRow {
                label: Translation.tr("Memory")
                value: root.usage(ResourceUsage.memoryUsed, ResourceUsage.memoryTotal)
                bar: ResourceUsage.memoryUsedPercentage
            }

            StatRow {
                label: Translation.tr("System uptime")
                value: DateTime.uptime
            }
        }
    }

    Component {
        id: hardwarePage

        Column {
            spacing: 8
            readonly property bool wantsTemp: ResourceUsage.cpuTempAvailable

            Component.onCompleted: {
                if (wantsTemp)
                    ResourceUsage.cpuTempConsumers++;
            }
            Component.onDestruction: {
                if (wantsTemp)
                    ResourceUsage.cpuTempConsumers--;
            }

            StatRow {
                visible: ResourceUsage.maxAvailableCpuString !== "--" && !ResourceUsage.maxAvailableCpuString.startsWith("NaN")
                label: Platform.isWindows ? Translation.tr("Processor") : Translation.tr("Max frequency")
                value: ResourceUsage.maxAvailableCpuString
            }

            StatRow {
                visible: ResourceUsage.cpuTempAvailable && ResourceUsage.cpuTemp > 0
                label: Translation.tr("CPU temperature")
                value: `${Math.round(ResourceUsage.cpuTemp)} °C`
            }

            StatRow {
                visible: ResourceUsage.swapTotal > 1
                label: Translation.tr("Swap")
                value: root.usage(ResourceUsage.swapUsed, ResourceUsage.swapTotal)
                bar: ResourceUsage.swapUsedPercentage
            }

            StatRow {
                visible: SystemInfo.distroName.length > 0 && SystemInfo.distroName !== "Unknown"
                label: Translation.tr("System")
                value: SystemInfo.distroName
            }

            StatRow {
                visible: SystemInfo.hostname.length > 0
                label: Translation.tr("Device name")
                value: SystemInfo.hostname
            }
        }
    }

    Component {
        id: networkPage

        Column {
            id: networkColumn
            spacing: 8
            readonly property bool wantsSpeed: Platform.isWindows
            readonly property bool wifiConnected: !Network.ethernet && Network.wifiStatus === "connected"
            readonly property int strength: Platform.isWindows ? Network.networkStrength : (Network.active?.strength ?? 0)
            readonly property string statusText: {
                if (Network.ethernet)
                    return Translation.tr("Connected");
                switch (Network.wifiStatus) {
                case "connected":
                    return Translation.tr("Connected");
                case "connecting":
                    return Translation.tr("Connecting");
                case "limited":
                    return Translation.tr("Limited");
                case "disabled":
                    return Translation.tr("Wi-Fi off");
                default:
                    return Translation.tr("Disconnected");
                }
            }

            Component.onCompleted: {
                if (wantsSpeed)
                    ResourceUsage.networkConsumers++;
            }
            Component.onDestruction: {
                if (wantsSpeed)
                    ResourceUsage.networkConsumers--;
            }

            StatRow {
                label: Translation.tr("Connection")
                value: Network.networkName.length > 0 ? Network.networkName : Translation.tr("Not connected")
            }

            StatRow {
                label: Translation.tr("Status")
                value: networkColumn.statusText
            }

            StatRow {
                visible: Network.ethernet || networkColumn.wifiConnected
                label: Translation.tr("Type")
                value: Network.ethernet ? Translation.tr("Ethernet") : Translation.tr("Wi-Fi")
            }

            StatRow {
                visible: networkColumn.wifiConnected && networkColumn.strength > 0
                label: Translation.tr("Signal")
                value: `${networkColumn.strength}%`
                bar: networkColumn.strength / 100
            }

            StatRow {
                visible: networkColumn.wantsSpeed
                label: Translation.tr("Download speed")
                value: root.rate(ResourceUsage.networkDownloadBytesPerSecond)
            }

            StatRow {
                visible: networkColumn.wantsSpeed
                label: Translation.tr("Upload speed")
                value: root.rate(ResourceUsage.networkUploadBytesPerSecond)
            }
        }
    }

    Component {
        id: storagePage

        Column {
            spacing: 8

            Component.onCompleted: ResourceUsage.diskConsumers++
            Component.onDestruction: ResourceUsage.diskConsumers--

            StatRow {
                label: Platform.isWindows ? Translation.tr("System drive (%1)").arg(Quickshell.env("SystemDrive") || "C:") : Translation.tr("System drive (%1)").arg("/")
                value: ResourceUsage.diskUsed > 0 ? root.usage(ResourceUsage.diskUsed, ResourceUsage.diskTotal) : "…"
                bar: ResourceUsage.diskUsed > 0 ? ResourceUsage.diskUsedPercentage : 0
            }

            StatRow {
                visible: ResourceUsage.diskUsed > 0
                label: Translation.tr("Free space")
                value: ResourceUsage.kbToGbString(ResourceUsage.diskFree)
            }
        }
    }
}

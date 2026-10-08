pragma ComponentBehavior: Bound

import "CheatsheetSystemFormat.js" as Fmt
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    property bool loadAsync: false

    readonly property var monitor: Platform.isWindows ? WindowsNative.systemMonitor : null

    readonly property var rawGpus: root.monitor?.gpus ?? []
    readonly property var gpus: [...root.rawGpus].sort((a, b) => (a.integrated ? 1 : 0) - (b.integrated ? 1 : 0))
    property int currentGpuIndex: 0
    readonly property var currentGpu: root.gpus.length > 0 ? root.gpus[Math.min(root.currentGpuIndex, root.gpus.length - 1)] : null

    readonly property var disks: root.monitor?.disks ?? []
    readonly property var totalDiskBytes: root.disks.reduce((sum, d) => sum + (Fmt.isNum(d.sizeBytes) ? d.sizeBytes : 0), 0)

    readonly property var dedicatedVramTotal: root.gpus.reduce((sum, g) => sum + (Fmt.isNum(g.vramTotal) ? g.vramTotal : 0), 0)
    readonly property var dedicatedVramUsed: root.gpus.reduce((sum, g) => sum + (Fmt.isNum(g.vramUsed) ? g.vramUsed : 0), 0)

    property list<real> cpuUsageHistory: []
    property var gpuUsageHistories: ({})
    readonly property var currentGpuUsageHistory: root.gpuUsageHistories[root.currentGpuIndex] ?? []

    function pushHistory(list, value) {
        const next = [...list, Fmt.isNum(value) ? value : 0];
        if (next.length > 60) next.shift();
        return next;
    }

    onCurrentGpuIndexChanged: {
        if (!(root.currentGpuIndex in root.gpuUsageHistories)) {
            const next = Object.assign({}, root.gpuUsageHistories);
            next[root.currentGpuIndex] = [];
            root.gpuUsageHistories = next;
        }
    }

    Connections {
        target: root.monitor
        function onUpdated() {
            root.cpuUsageHistory = root.pushHistory(root.cpuUsageHistory, root.monitor?.cpuUsage);
            if (root.currentGpu) {
                const next = Object.assign({}, root.gpuUsageHistories);
                next[root.currentGpuIndex] = root.pushHistory(next[root.currentGpuIndex] ?? [], root.currentGpu.usage);
                root.gpuUsageHistories = next;
            }
        }
    }

    readonly property int cardSpacing: 16
    readonly property int minCardWidth: 320
    readonly property real layoutWidth: root.width - 2 * Appearance.rounding.small
    readonly property int cardColumns: Math.max(1, Math.min(3, Math.floor((root.layoutWidth + root.cardSpacing) / (root.minCardWidth + root.cardSpacing))))
    readonly property real cardWidth: (root.layoutWidth - (root.cardColumns - 1) * root.cardSpacing) / root.cardColumns
    readonly property int gaugeSpacing: root.cardWidth >= 420 ? 24 : 12
    readonly property int gaugeSlot: Math.floor((root.cardWidth - 32 - 2 * root.gaugeSpacing) / 3)
    readonly property int gaugeSize: Math.max(56, Math.min(104, root.gaugeSlot - 12))

    implicitWidth: (QsWindow?.window?.screen.width ?? 1280) * 0.7
    implicitHeight: (QsWindow?.window?.screen.height ?? 800) * 0.7

    Loader {
        id: contentLoader
        property bool wasLoaded: false
        anchors.fill: parent
        active: !Platform.isWindows || root.SwipeView.isCurrentItem || root.loadAsync || contentLoader.wasLoaded
        asynchronous: root.loadAsync
        onLoaded: contentLoader.wasLoaded = true

        sourceComponent: Item {
            StyledFlickable {
                id: flickable
                anchors.fill: parent
                anchors.margins: Appearance.rounding.small
                clip: true
                contentWidth: width
                contentHeight: mainColumn.implicitHeight

                ColumnLayout {
                    id: mainColumn
                    width: flickable.width
                    spacing: 16

                    Flow {
                        Layout.fillWidth: true
                        spacing: 8

                        CheatsheetSystemHeaderChip {
                            icon: "computer"
                            text: Fmt.dash(root.monitor?.hostName)
                        }
                        CheatsheetSystemHeaderChip {
                            icon: "desktop_windows"
                            text: [root.monitor?.osName, root.monitor?.osVersion].filter(s => s && s.length > 0).join(" ") || "—"
                        }
                        CheatsheetSystemHeaderChip {
                            icon: "tag"
                            text: Fmt.dash(root.monitor?.osBuild)
                        }
                        CheatsheetSystemHeaderChip {
                            icon: "developer_board"
                            text: [root.monitor?.boardVendor, root.monitor?.boardModel].filter(s => s && s.length > 0).join(" ") || "—"
                        }
                        CheatsheetSystemHeaderChip {
                            icon: "schedule"
                            text: {
                                const parts = Fmt.durationParts(root.monitor?.uptimeSeconds);
                                return parts ? Translation.tr("Up %1").arg(parts) : "—";
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: root.cardColumns
                        columnSpacing: root.cardSpacing
                        rowSpacing: root.cardSpacing

                        CheatsheetSystemCard {
                            icon: "memory"
                            Layout.preferredWidth: 1
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignTop
                            label: Translation.tr("CPU")
                            title: Fmt.dash(Fmt.cpuName(root.monitor?.cpuName))
                            subtitle: [
                                Translation.tr("%1 cores").arg(root.monitor?.cpuCores || "—"),
                                Translation.tr("%1 threads").arg(root.monitor?.cpuThreads || "—"),
                                Fmt.isNum(root.monitor?.cpuMaxMhz) ? Translation.tr("up to %1").arg(Fmt.ghzString(root.monitor.cpuMaxMhz)) : "",
                                (root.monitor?.cpuL3Bytes ?? 0) > 0 ? Translation.tr("L3 %1").arg(Fmt.mibString(root.monitor.cpuL3Bytes)) : ""
                            ].filter(part => part.length > 0).join(" · ")

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter
                                spacing: root.gaugeSpacing

                                CheatsheetSystemGauge {
                                    ringSize: root.gaugeSize
                                    value: Fmt.clamp01(root.monitor?.cpuUsage)
                                    bigText: Fmt.percentString(root.monitor?.cpuUsage)
                                    caption: Translation.tr("Usage")
                                }
                                CheatsheetSystemGauge {
                                    ringSize: root.gaugeSize
                                    value: Fmt.isNum(root.monitor?.cpuTemperature) ? Fmt.clamp01(root.monitor.cpuTemperature / 100) : 0
                                    bigText: Fmt.celsiusString(root.monitor?.cpuTemperature)
                                    caption: Translation.tr("Temperature")
                                    ringColor: Appearance.colors.colTertiary
                                }
                                CheatsheetSystemGauge {
                                    ringSize: root.gaugeSize
                                    value: (Fmt.isNum(root.monitor?.cpuMhz) && Fmt.isNum(root.monitor?.cpuMaxMhz) && root.monitor.cpuMaxMhz > 0) ? Fmt.clamp01(root.monitor.cpuMhz / root.monitor.cpuMaxMhz) : 0
                                    bigText: Fmt.ghzNumber(root.monitor?.cpuMhz)
                                    smallText: Fmt.isNum(root.monitor?.cpuMhz) ? "GHz" : ""
                                    caption: Translation.tr("Clock")
                                    ringColor: Appearance.colors.colSecondary
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 6
                                spacing: 4

                                StyledText {
                                    text: Translation.tr("CPU usage")
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                }
                                Graph {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 56
                                    values: root.cpuUsageHistory
                                    alignment: Graph.Alignment.Right
                                }
                            }
                        }

                        CheatsheetSystemCard {
                            icon: "monitor"
                            Layout.preferredWidth: 1
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignTop
                            label: Translation.tr("GPU")
                            title: Fmt.dash(root.currentGpu?.name)
                            subtitle: Translation.tr("%1 VRAM · %2")
                                .arg(Fmt.sizeString(root.currentGpu?.vramTotal, 0))
                                .arg(Fmt.dash(root.currentGpu?.driverVersion))

                            RowLayout {
                                visible: root.gpus.length > 1
                                Layout.alignment: Qt.AlignRight
                                spacing: 4

                                MaterialSymbol {
                                    text: "chevron_left"
                                    iconSize: Appearance.font.pixelSize.large
                                    color: Appearance.colors.colSubtext
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root.currentGpuIndex = (root.currentGpuIndex - 1 + root.gpus.length) % root.gpus.length
                                    }
                                }
                                StyledText {
                                    text: (root.currentGpuIndex + 1) + " / " + root.gpus.length
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                }
                                MaterialSymbol {
                                    text: "chevron_right"
                                    iconSize: Appearance.font.pixelSize.large
                                    color: Appearance.colors.colSubtext
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root.currentGpuIndex = (root.currentGpuIndex + 1) % root.gpus.length
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter
                                spacing: root.gaugeSpacing

                                CheatsheetSystemGauge {
                                    ringSize: root.gaugeSize
                                    value: Fmt.clamp01(root.currentGpu?.usage)
                                    bigText: Fmt.percentString(root.currentGpu?.usage)
                                    caption: Translation.tr("Usage")
                                }
                                CheatsheetSystemGauge {
                                    ringSize: root.gaugeSize
                                    value: Fmt.isNum(root.currentGpu?.temperature) ? Fmt.clamp01(root.currentGpu.temperature / 100) : 0
                                    bigText: Fmt.celsiusString(root.currentGpu?.temperature)
                                    caption: Translation.tr("Temperature")
                                    ringColor: Appearance.colors.colTertiary
                                }
                                CheatsheetSystemGauge {
                                    ringSize: root.gaugeSize
                                    value: Fmt.ratio(root.currentGpu?.vramUsed, root.currentGpu?.vramTotal)
                                    bigText: Fmt.isNum(root.currentGpu?.vramUsed) ? Fmt.bytesToGiB(root.currentGpu.vramUsed).toFixed(1) : "—"
                                    smallText: Fmt.isNum(root.currentGpu?.vramTotal) ? ("/ " + Fmt.sizeString(root.currentGpu.vramTotal, 0)) : ""
                                    caption: Translation.tr("VRAM")
                                    ringColor: Appearance.colors.colSecondary
                                }
                            }

                            Flow {
                                Layout.fillWidth: true
                                Layout.topMargin: 2
                                spacing: 16

                                CheatsheetSystemStatChip {
                                    icon: "bolt"
                                    text: Fmt.wattsString(root.currentGpu?.powerWatts)
                                }
                                CheatsheetSystemStatChip {
                                    icon: "speed"
                                    text: Fmt.mhzString(root.currentGpu?.clockMhz)
                                }
                                CheatsheetSystemStatChip {
                                    icon: "memory"
                                    text: Fmt.mhzString(root.currentGpu?.memoryClockMhz)
                                }
                                CheatsheetSystemStatChip {
                                    icon: "mode_fan"
                                    text: Fmt.isNum(root.currentGpu?.fanRpm) ? (root.currentGpu.fanRpm === 0 ? Translation.tr("Fan stopped") : (Math.round(root.currentGpu.fanRpm) + " RPM")) : "—"
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 6
                                spacing: 4

                                StyledText {
                                    text: Translation.tr("GPU usage")
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                }
                                Graph {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 56
                                    values: root.currentGpuUsageHistory
                                    alignment: Graph.Alignment.Right
                                }
                            }
                        }

                        CheatsheetSystemCard {
                            icon: "memory_alt"
                            Layout.preferredWidth: 1
                            Layout.columnSpan: root.cardColumns === 2 ? 2 : 1
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignTop
                            label: Translation.tr("Memory")
                            title: Translation.tr("%1 RAM").arg(Fmt.sizeString(root.monitor?.memoryTotal))
                            subtitle: Translation.tr("%1 swap").arg(Fmt.sizeString(root.monitor?.swapTotal))

                            CheatsheetSystemUsageBar {
                                label: Translation.tr("RAM")
                                valueText: Fmt.usedTotalString(root.monitor?.memoryUsed, root.monitor?.memoryTotal)
                                percentText: Fmt.percentString(Fmt.ratio(root.monitor?.memoryUsed, root.monitor?.memoryTotal))
                                ratio: Fmt.ratio(root.monitor?.memoryUsed, root.monitor?.memoryTotal)
                            }
                            CheatsheetSystemUsageBar {
                                label: Translation.tr("Swap")
                                valueText: Fmt.usedTotalString(root.monitor?.swapUsed, root.monitor?.swapTotal)
                                percentText: Fmt.percentString(Fmt.ratio(root.monitor?.swapUsed, root.monitor?.swapTotal))
                                ratio: Fmt.ratio(root.monitor?.swapUsed, root.monitor?.swapTotal)
                                barColor: Appearance.colors.colTertiary
                            }
                            CheatsheetSystemUsageBar {
                                label: Translation.tr("VRAM")
                                valueText: Fmt.usedTotalString(root.dedicatedVramUsed, root.dedicatedVramTotal)
                                percentText: Fmt.percentString(Fmt.ratio(root.dedicatedVramUsed, root.dedicatedVramTotal))
                                ratio: Fmt.ratio(root.dedicatedVramUsed, root.dedicatedVramTotal)
                                barColor: Appearance.colors.colSecondary
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 10

                        RowLayout {
                            spacing: 10
                            MaterialSymbol {
                                text: "storage"
                                iconSize: Appearance.font.pixelSize.huge
                                color: Appearance.colors.colOnLayer0
                            }
                            StyledText {
                                text: Translation.tr("Storage")
                                font.pixelSize: Appearance.font.pixelSize.larger
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer0
                            }
                            StyledText {
                                text: Translation.tr("%1 drive(s) · %2 total").arg(root.disks.length).arg(Fmt.sizeString(root.totalDiskBytes))
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Repeater {
                                model: root.disks

                                delegate: CheatsheetSystemDiskCard {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    disk: modelData
                                }
                            }
                        }
                    }
                }
            }

            ScrollEdgeFade {
                target: flickable
                vertical: true
                color: Appearance.colors.colLayer0Base
            }
        }
    }
}

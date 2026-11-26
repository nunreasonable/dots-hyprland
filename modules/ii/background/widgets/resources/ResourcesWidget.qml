import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root
    Component.onCompleted: {
        ResourceUsage.diskConsumers++;
        ResourceUsage.networkConsumers++;
    }
    Component.onDestruction: {
        ResourceUsage.diskConsumers--;
        ResourceUsage.networkConsumers--;
    }

    configEntryName: "resources"
    hoverEnabled: true

    property real cardSpacing: 12
    property real cardHeight: 120
    property real widgetWidth: 420
    property real cardWidth: (widgetWidth - cardSpacing * 2) / 3
    property bool isVertical: root.configEntry.vertical ?? false
    property bool hasBattery: Battery.available
    readonly property bool isCaractere: StyleTheme.key === "caractere"

    function formatBytesPerSec(bytesPerSec) {
        if (!bytesPerSec || bytesPerSec <= 0)
            return "0 KB/s";
        const kb = bytesPerSec / 1024;
        if (kb < 1024)
            return kb.toFixed(kb < 10 ? 1 : 0) + " KB/s";
        return (kb / 1024).toFixed(1) + " MB/s";
    }

    implicitWidth: root.isCaractere ? (caractereLoader.item?.implicitWidth ?? root.widgetWidth) : row.implicitWidth
    implicitHeight: root.isCaractere ? (caractereLoader.item?.implicitHeight ?? 0) : row.implicitHeight

    component StatCard: WidgetCard {
        id: statCard
        property string icon: ""
        property string value: ""
        property string label: ""
        property int shape: MaterialShape.Shape.Cookie12Sided
        property color bgColor: Appearance.colors.colPrimaryContainer
        property color shapeColor: Appearance.colors.colPrimary

        implicitWidth: root.cardWidth
        implicitHeight: root.cardHeight
        widget: root
        color: statCard.bgColor

        ColumnLayout {
            anchors {
                fill: parent
                margins: 14
            }
            spacing: -4

            MaterialShapeWrappedMaterialSymbol {
                Layout.alignment: Qt.AlignRight
                shape: statCard.shape
                color: statCard.shapeColor
                colSymbol: Appearance.colors.colOnPrimary
                text: statCard.icon
                iconSize: 18
                fill: 1
                padding: 6
                implicitWidth: 34
                implicitHeight: 34
            }

            Item { Layout.fillHeight: true }

            StyledText {
                text: statCard.value
                font.pixelSize: Appearance.font.pixelSize.hugeass
                font.weight: Font.Bold
                color: Appearance.colors.colOnPrimaryContainer
            }

            StyledText {
                text: statCard.label
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnPrimaryContainer
                opacity: 0.6
            }
        }
    }

    Loader {
        id: caractereLoader
        active: root.isCaractere
        visible: active

        sourceComponent: CaractereCellFrame {
            id: sysFrame
            title: "system"
            implicitWidth: root.widgetWidth
            implicitHeight: sysColumn.implicitHeight + 28
            background: Appearance.colors.colLayer0

            Column {
                id: sysColumn
                x: 16
                y: 16
                width: parent.width - 32
                spacing: 6

                CaractereCellMetrics {
                    id: sysMetrics
                }
                readonly property int meterCells: Math.max(6, sysMetrics.cols(sysColumn.width) - 14)

                StyledText {
                    color: StyleTheme.current.termFg ?? Appearance.colors.colOnLayer0
                    font.pixelSize: 11
                    text: "cpu  " + CaractereGlyphs.meterText(ResourceUsage.cpuUsage, sysColumn.meterCells) + "  " + Math.round(ResourceUsage.cpuUsage * 100) + "%"
                }
                StyledText {
                    color: StyleTheme.current.termAccent ?? Appearance.colors.colPrimary
                    font.pixelSize: 11
                    text: CaractereGlyphs.brailleGraph(ResourceUsage.cpuUsageHistory, sysColumn.meterCells + 7)
                }
                StyledText {
                    color: StyleTheme.current.termFg ?? Appearance.colors.colOnLayer0
                    font.pixelSize: 11
                    text: "mem  " + CaractereGlyphs.meterText(ResourceUsage.memoryUsedPercentage, sysColumn.meterCells) + "  " + (ResourceUsage.memoryUsed / (1024 * 1024)).toFixed(1) + "/" + Math.round(ResourceUsage.memoryTotal / (1024 * 1024)) + "G"
                }
                StyledText {
                    visible: !root.hasBattery
                    color: StyleTheme.current.termFg ?? Appearance.colors.colOnLayer0
                    font.pixelSize: 11
                    text: "dsk  " + CaractereGlyphs.meterText(ResourceUsage.diskUsedPercentage, sysColumn.meterCells) + "  " + Math.round(ResourceUsage.diskUsedPercentage * 100) + "%"
                }
                StyledText {
                    visible: root.hasBattery
                    color: StyleTheme.current.termFg ?? Appearance.colors.colOnLayer0
                    font.pixelSize: 11
                    text: "bat  " + CaractereGlyphs.meterText(Battery.percentage, sysColumn.meterCells) + "  " + Math.round(Battery.percentage * 100) + "%"
                }
                StyledText {
                    color: StyleTheme.current.termWeak ?? Appearance.colors.colSubtext
                    font.pixelSize: 11
                    text: "net  ↓ " + root.formatBytesPerSec(ResourceUsage.networkDownloadBytesPerSecond) + "  ↑ " + root.formatBytesPerSec(ResourceUsage.networkUploadBytesPerSecond)
                }
            }
        }
    }

    Grid {
        id: row
        visible: !root.isCaractere
        columns: root.isVertical ? 1 : 3
        rows: root.isVertical ? 3 : 1
        spacing: root.cardSpacing

        Behavior on columns {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        StatCard {
            icon: "planner_review"
            value: Math.round(ResourceUsage.cpuUsage * 100) + "%"
            label: Translation.tr("CPU")
            shape: MaterialShape.Shape.Gem
        }
        StatCard {
            icon: "memory"
            value: Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%"
            label: Translation.tr("RAM")
            shape: MaterialShape.Shape.Cookie4Sided
            bgColor: Appearance.colors.colSecondaryContainer
            shapeColor: Appearance.colors.colSecondary
        }
        StatCard {
            icon: root.hasBattery ? "battery_full" : "storage"
            value: root.hasBattery
                ? Math.round(Battery.percentage * 100) + "%"
                : Math.round(ResourceUsage.diskUsedPercentage * 100) + "%"
            label: root.hasBattery ? Translation.tr("Battery") : Translation.tr("Disk")
            shape: MaterialShape.Shape.Cookie12Sided
            bgColor: Appearance.colors.colTertiaryContainer
            shapeColor: Appearance.colors.colTertiary
        }
    }
    WidgetFlipHandle {
        anchorItem: root
        hoverActive: root.containsMouse
        locked: Config.options.background.widgetsLocked
        onClicked: {
            root.isVertical = !root.isVertical
            root.configEntry.vertical = root.isVertical
        }
    }
}

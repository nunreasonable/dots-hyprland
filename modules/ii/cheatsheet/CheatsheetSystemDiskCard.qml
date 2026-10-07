pragma ComponentBehavior: Bound
import "CheatsheetSystemFormat.js" as Fmt
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var disk

    readonly property string model: disk.model && disk.model.length > 0 ? disk.model : Fmt.dash("")
    readonly property string kind: disk.kind && disk.kind.length > 0 ? disk.kind : Fmt.dash("")
    readonly property string subtitle: [root.kind, Fmt.sizeString(disk.sizeBytes), Translation.tr("Disk %1").arg(disk.number)].join(" · ")

    Layout.fillWidth: true
    implicitHeight: mainColumn.implicitHeight + mainColumn.anchors.margins * 2
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    border.width: 1
    border.color: Appearance.colors.colLayer0Border

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            MaterialSymbol {
                text: Fmt.diskIcon(root.disk.kind)
                iconSize: Appearance.font.pixelSize.huge
                color: Appearance.colors.colOnLayer1
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                StyledText {
                    Layout.fillWidth: true
                    text: root.model
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.subtitle
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }
            }

            CheatsheetSystemStatChip {
                icon: "thermostat"
                text: Fmt.celsiusString(root.disk.temperature)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: root.disk.volumes ?? []

                delegate: CheatsheetSystemUsageBar {
                    required property var modelData
                    Layout.fillWidth: true
                    icon: "folder"
                    label: [modelData.mount, modelData.fs].filter(s => s && s.length > 0).join(" · ")
                    valueText: Fmt.usedTotalString(modelData.usedBytes, modelData.totalBytes)
                    percentText: Fmt.percentString(Fmt.ratio(modelData.usedBytes, modelData.totalBytes))
                    ratio: Fmt.ratio(modelData.usedBytes, modelData.totalBytes)
                }
            }
        }
    }
}

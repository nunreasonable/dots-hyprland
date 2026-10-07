import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property string icon: ""
    property string label: ""
    property string valueText: "—"
    property string percentText: "—"
    property real ratio: 0
    property color barColor: Appearance.colors.colPrimary

    Layout.fillWidth: true
    spacing: 4

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        MaterialSymbol {
            visible: root.icon.length > 0
            text: root.icon
            iconSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colSubtext
        }
        StyledText {
            text: root.label
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
        }
        Item { Layout.fillWidth: true }
        StyledText {
            text: root.valueText
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }
        StyledText {
            text: root.percentText
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer1
        }
    }

    StyledProgressBar {
        Layout.fillWidth: true
        valueBarHeight: 6
        from: 0
        to: 1
        value: root.ratio
        highlightColor: root.barColor
    }
}

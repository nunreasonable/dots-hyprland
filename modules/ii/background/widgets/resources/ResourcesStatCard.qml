import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick

Rectangle {
    id: root

    property string icon: ""
    property real percentValue: 0
    property string label: ""

    implicitWidth: 92
    implicitHeight: 92
    radius: Appearance.rounding.large
    color: Appearance.colors.colLayer0Base
    border.width: 1
    border.color: Appearance.colors.colLayer0Border

    Column {
        anchors.centerIn: parent
        spacing: 4

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: 26
            implicitHeight: 26
            radius: Appearance.rounding.full
            color: Appearance.colors.colLayer1Base

            MaterialSymbol {
                anchors.centerIn: parent
                text: root.icon
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer1
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(root.percentValue * 100) + "%"
            font.pixelSize: Appearance.font.pixelSize.huge
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer0
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }
    }
}

import QtQuick
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property real percentage: 0
    property bool charging: false
    property bool low: false
    property bool vertical: false

    AquarioTube {
        anchors.fill: parent
        value: root.percentage
        bubbles: false
        topColor: root.low ? AquarioTheme.alarmTop : AquarioTheme.waterTop
        bottomColor: root.low ? AquarioTheme.alarmBottom : AquarioTheme.waterBottom
    }

    Row {
        anchors.centerIn: parent
        rotation: root.vertical ? 90 : 0
        spacing: 0

        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.charging && root.percentage < 1
            text: "bolt"
            fill: 1
            iconSize: Appearance.font.pixelSize.smaller
            color: AquarioTheme.text
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.percentage * 100)
            font.pixelSize: 12
            font.weight: Font.Bold
            color: AquarioTheme.text
        }
    }
}

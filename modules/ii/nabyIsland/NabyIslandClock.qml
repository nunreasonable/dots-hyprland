import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Item {
    id: root

    property bool compact: true

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.compact ? 0 : -2
        spacing: 0

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: DateTime.time
            color: "#ffffff"
            font.pixelSize: root.compact ? 15 : 30
            font.weight: Font.DemiBold
            font.variableAxes: ({ "wght": root.compact ? 650 : 600 })
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !root.compact
            text: DateTime.longDate
            color: "#ffffff"
            opacity: 0.65
            font.pixelSize: 13
        }
    }
}

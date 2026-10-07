import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Column {
    id: root

    property real value: 0
    property string bigText: "—"
    property string smallText: ""
    property string caption: ""
    property int ringSize: 104
    property int lineWidth: 6
    property color ringColor: Appearance.colors.colPrimary

    spacing: 8

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: root.ringSize
        implicitHeight: root.ringSize

        CircularProgress {
            anchors.fill: parent
            implicitSize: root.ringSize
            lineWidth: root.lineWidth
            value: root.value
            colPrimary: root.ringColor
            colSecondary: Appearance.colors.colLayer2
        }

        Column {
            anchors.centerIn: parent
            spacing: 0

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.bigText
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
            StyledText {
                visible: root.smallText.length > 0
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.smallText
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.caption
        font.pixelSize: Appearance.font.pixelSize.small
        color: Appearance.colors.colSubtext
    }
}

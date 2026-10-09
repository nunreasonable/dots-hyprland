import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

RowLayout {
    id: diTimersRoot
    required property Item di
    anchors {
        fill: parent
        leftMargin: 8
        rightMargin: 10
    }
    spacing: 6

    Item {
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 16
        implicitHeight: 16

        MaterialSymbol {
            anchors.fill: parent
            text: diTimersRoot.di.timerRunning() ? "pause" : "play_arrow"
            fill: 1
            iconSize: 16
            color: Appearance.colors.colOnLayer0
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: diTimersRoot.di.toggleActiveTimer()
        }
    }

    Item {
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 16
        implicitHeight: 16

        MaterialSymbol {
            anchors.fill: parent
            text: "stop_circle"
            fill: 1
            iconSize: 16
            color: Appearance.colors.colOnLayer0
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: diTimersRoot.di.resetActiveTimer()
        }
    }

    Item {
        Layout.fillWidth: true
    }

    StyledText {
        Layout.alignment: Qt.AlignVCenter
        text: diTimersRoot.di.timerValueText()
        font.pixelSize: Appearance.font.pixelSize.small
        font.features: {
            "tnum": 1
        }
        color: Appearance.colors.colOnLayer0
    }
}

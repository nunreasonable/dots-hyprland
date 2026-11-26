import QtQuick
import qs.modules.common

Item {
    id: root

    property real radius: 0
    property bool rim: false
    property bool solid: AquarioTheme.transparent && !AquarioTheme.blurred
    property color solidColor: AquarioTheme.glassSolid
    property real glossHeight: Math.min(root.height * 0.5, 64)
    property real glossAlpha: AquarioTheme.glossAlpha

    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        visible: root.solid
        radius: root.radius
        color: root.solidColor
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.rgba(1, 1, 1, root.glossAlpha)
            }
            GradientStop {
                position: Math.min(1, root.glossHeight / Math.max(1, root.height))
                color: Qt.rgba(1, 1, 1, 0)
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.rim
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: AquarioTheme.rimOuter
        antialiasing: true

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, root.radius - 1)
            color: "transparent"
            border.width: 1.5
            border.color: AquarioTheme.rimInner
            antialiasing: true
        }
    }
}

import QtQuick
import qs.modules.common

Item {
    id: root

    property bool on: false
    property real size: 7
    property color onColor: StyleTheme.current?.ledOn ?? "#3CCDAA"
    property color offColor: StyleTheme.current?.ledOff ?? "#8A8F92"

    implicitWidth: root.size
    implicitHeight: root.size

    Rectangle {
        visible: root.on
        anchors.centerIn: parent
        width: root.size * 2.6
        height: root.size * 2.6
        radius: width / 2
        color: root.onColor
        opacity: 0.25
    }

    Rectangle {
        anchors.centerIn: parent
        width: root.size
        height: root.size
        radius: width / 2
        color: root.on ? root.onColor : root.offColor

        Behavior on color {
            enabled: Appearance.animationsEnabled
            ColorAnimation {
                duration: 80
            }
        }
    }
}

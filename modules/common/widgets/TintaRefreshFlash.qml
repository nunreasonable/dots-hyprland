import QtQuick
import qs.modules.common

Rectangle {
    id: root

    property real flashRadius: 0

    anchors.fill: parent
    z: 99
    radius: root.flashRadius
    color: StyleTheme.elevation.color ?? "black"
    visible: StyleTheme.key === "tinta" && flashTimer.running

    function flash() {
        if (StyleTheme.key === "tinta" && StyleTheme.current.requestFlash())
            flashTimer.restart();
    }

    Timer {
        id: flashTimer
        interval: 70
        repeat: false
    }
}

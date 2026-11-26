import QtQuick
import qs.modules.common

Rectangle {
    id: root

    property real borderWidth: StyleTheme.surface.borderWidth
    property real ringWidth: StyleTheme.surface.ringWidth

    anchors.fill: parent
    z: 50
    visible: StyleTheme.surface.frame
    color: "transparent"
    border.width: root.borderWidth
    border.color: StyleTheme.surface.borderColor ?? "transparent"
    antialiasing: true

    Rectangle {
        anchors.fill: parent
        anchors.margins: root.borderWidth
        radius: Math.max(0, root.radius - root.borderWidth)
        color: "transparent"
        border.width: root.ringWidth
        border.color: StyleTheme.surface.ringColor ?? "transparent"
        antialiasing: true
    }
}

import QtQuick
import qs.modules.common

Rectangle {
    id: root

    property real ringWidth: SekaiTheme.ringWidth

    anchors.fill: parent
    z: 50
    visible: SekaiTheme.active
    color: "transparent"
    border.width: SekaiTheme.borderWidth
    border.color: SekaiTheme.outline
    antialiasing: true

    Rectangle {
        anchors.fill: parent
        anchors.margins: SekaiTheme.borderWidth
        radius: Math.max(0, root.radius - SekaiTheme.borderWidth)
        color: "transparent"
        border.width: root.ringWidth
        border.color: SekaiTheme.ring
        antialiasing: true
    }
}

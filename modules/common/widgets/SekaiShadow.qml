import QtQuick
import qs.modules.common

Item {
    id: root

    property real radius: 0

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.bottom
    height: SekaiTheme.shadowOffset
    z: -3
    visible: SekaiTheme.active
    clip: true

    Rectangle {
        width: root.width
        height: root.parent.height
        y: SekaiTheme.shadowOffset - root.parent.height
        radius: root.radius
        color: SekaiTheme.shadow
        antialiasing: true
    }
}

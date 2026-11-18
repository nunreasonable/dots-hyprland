import QtQuick
import qs.modules.common

Item {
    id: root

    property real radius: 0

    anchors.left: parent ? parent.left : undefined
    anchors.right: parent ? parent.right : undefined
    anchors.top: parent ? parent.bottom : undefined
    height: SekaiTheme.shadowOffset
    z: -3
    visible: SekaiTheme.active
    clip: true

    Rectangle {
        width: root.width
        height: root.parent?.height ?? 0
        y: SekaiTheme.shadowOffset - height
        radius: root.radius
        color: SekaiTheme.shadow
        antialiasing: true
    }
}

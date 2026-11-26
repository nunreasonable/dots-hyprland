import QtQuick
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property real radius: 0
    readonly property bool floating: Config.options.bar.cornerStyle === 1

    RisoInk {
        anchors.fill: parent
        visible: root.floating
        radius: root.radius
    }

    Rectangle {
        visible: !root.floating
        anchors.left: parent.left
        anchors.right: parent.right
        y: Config.options.bar.bottom ? 0 : parent.height - height
        height: StyleTheme.surface.borderWidth
        color: StyleTheme.surface.borderColor ?? "transparent"
    }
}

import QtQuick
import qs.modules.common

Item {
    id: root

    property Item target: parent
    property real radius: 0
    property real lift: 0
    readonly property real dx: StyleTheme.elevation.x + root.lift
    readonly property real dy: StyleTheme.elevation.y + root.lift
    readonly property color color: StyleTheme.elevation.color ?? "transparent"

    x: root.target === root.parent ? 0 : (root.target?.x ?? 0)
    y: root.target === root.parent ? 0 : (root.target?.y ?? 0)
    width: root.target?.width ?? 0
    height: root.target?.height ?? 0
    z: -3
    visible: StyleTheme.hardShadow

    Loader {
        active: StyleTheme.key === "riso"
        sourceComponent: RisoRegister {
            shadow: root
        }
    }

    Item {
        y: root.height
        width: root.width + root.dx
        height: root.dy
        clip: true

        Rectangle {
            x: root.dx
            y: root.dy - root.height
            width: root.width
            height: root.height
            radius: root.radius
            color: root.color
            antialiasing: true
        }
    }

    Item {
        x: root.width
        width: root.dx
        height: root.height
        clip: true

        Rectangle {
            x: root.dx - root.width
            y: root.dy
            width: root.width
            height: root.height
            radius: root.radius
            color: root.color
            antialiasing: true
        }
    }
}

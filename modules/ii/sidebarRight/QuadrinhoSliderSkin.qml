import QtQuick
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    required property var slider
    readonly property real track: Math.min(root.height, root.slider.trackWidth)
    readonly property real start: root.slider.leftPadding
    readonly property real span: root.slider.effectiveDraggingWidth

    Rectangle {
        id: rail
        x: root.start
        y: (root.height - root.track) / 2
        width: root.span
        height: root.track
        color: QuadrinhoTheme.paper
        border.width: 2
        border.color: QuadrinhoTheme.ink

        QuadrinhoTone {
            x: 2
            y: 2
            width: Math.max(0, root.slider.visualPosition * root.span - 2)
            height: rail.height - 4
            density: 60
        }
    }
}

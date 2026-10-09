import QtQuick
import qs.modules.common
import qs

Rectangle {
    id: root
    required property var widget
    property bool blurred: Config.options.background.widgets.blurWidgets
    property bool shadowed: Config.options.background.widgets.shadow
    property color tint: Appearance.colors.colLayer1
    property real tintOpacity: 0.55

    radius: Appearance.rounding?.verylarge ?? 30
    color: Appearance.colors.colPrimaryContainer

    StyledRectangularShadow {
        target: root
        z: -2
        visible: root.shadowed
    }

    Loader {
        anchors.fill: parent
        anchors.margins: root.blurred ? -1 : 0
        active: !Platform.isWindows && root.blurred && root.widget !== null && root.widget.wallpaperItem !== null
        visible: active
        sourceComponent: FastBlurred {
            blurSource: root.widget.wallpaperItem
            cardRadius: root.radius + 1
            tint: root.tint
            tintOpacity: root.tintOpacity
            trackX: root.widget.x + root.x
            trackY: root.widget.y + root.y
        }
    }
}

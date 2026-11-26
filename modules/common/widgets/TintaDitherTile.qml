import QtQuick
import Quickshell
import qs.modules.common

Item {
    id: root

    readonly property real dpr: Screen.devicePixelRatio || 1
    readonly property url tilePath: Qt.resolvedUrl(Quickshell.shellPath(Appearance.m3colors.darkmode ? "assets/images/tinta-dither-dark.png" : "assets/images/tinta-dither-light.png"))

    clip: true

    Image {
        source: root.tilePath
        sourceSize: Qt.size(4, 4)
        smooth: false
        mipmap: false
        fillMode: Image.Tile
        horizontalAlignment: Image.AlignLeft
        verticalAlignment: Image.AlignTop

        width: root.width * root.dpr
        height: root.height * root.dpr
        scale: 1 / root.dpr
        transformOrigin: Item.TopLeft
    }
}

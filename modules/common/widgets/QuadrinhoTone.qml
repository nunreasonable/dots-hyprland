import QtQuick
import QtQuick.Window
import qs.modules.common

Item {
    id: root

    property int density: 30
    readonly property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1

    clip: true

    Image {
        width: Math.ceil(root.width * root.dpr)
        height: Math.ceil(root.height * root.dpr)
        scale: 1 / root.dpr
        transformOrigin: Item.TopLeft
        fillMode: Image.Tile
        horizontalAlignment: Image.AlignLeft
        verticalAlignment: Image.AlignTop
        smooth: false
        cache: true
        source: QuadrinhoTheme.tone(root.density)
    }
}

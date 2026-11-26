import QtQuick
import QtQuick.Shapes
import qs.modules.common

Item {
    id: root

    property real radius: 0

    Image {
        id: tile
        source: StyleTheme.texture.source
        visible: false
    }

    ShaderEffectSource {
        id: tiled
        sourceItem: tile
        width: tile.implicitWidth
        height: tile.implicitHeight
        wrapMode: ShaderEffectSource.Repeat
        hideSource: true
        visible: false
    }

    Shape {
        anchors.fill: parent
        opacity: StyleTheme.texture.opacity

        ShapePath {
            strokeWidth: -1
            strokeColor: "transparent"
            fillItem: tiled

            PathRectangle {
                width: root.width
                height: root.height
                radius: root.radius
            }
        }
    }
}

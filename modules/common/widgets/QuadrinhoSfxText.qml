import QtQuick
import QtQuick.Shapes
import qs.modules.common

Item {
    id: root

    property string text: ""
    property real pixelSize: 64
    property string family: QuadrinhoTheme.sfxFont
    property color fill: QuadrinhoTheme.spot
    property color ink: QuadrinhoTheme.ink
    property real outline: 4
    property real shadow: 0

    readonly property real pad: root.outline + 2
    readonly property rect bounds: metrics.font.pixelSize > 0 && metrics.font.family !== "" ? metrics.tightBoundingRect(root.text) : Qt.rect(0, 0, 0, 0)

    FontMetrics {
        id: metrics
        font.family: root.family
        font.pixelSize: root.pixelSize
    }

    implicitWidth: root.bounds.width + root.pad * 2 + root.shadow
    implicitHeight: root.bounds.height + root.pad * 2 + root.shadow

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.ink
            strokeColor: root.shadow > 0 ? root.ink : "transparent"
            strokeWidth: root.shadow > 0 ? root.outline * 2 : 0
            joinStyle: ShapePath.RoundJoin

            PathText {
                x: root.pad + root.shadow - root.bounds.x
                y: root.pad + root.shadow
                text: root.shadow > 0 ? root.text : ""
                font.family: root.family
                font.pixelSize: root.pixelSize
            }
        }

        ShapePath {
            fillColor: root.ink
            strokeColor: root.ink
            strokeWidth: root.outline * 2
            joinStyle: ShapePath.RoundJoin

            PathText {
                x: root.pad - root.bounds.x
                y: root.pad
                text: root.text
                font.family: root.family
                font.pixelSize: root.pixelSize
            }
        }

        ShapePath {
            fillColor: root.fill
            strokeColor: "transparent"
            strokeWidth: 0

            PathText {
                x: root.pad - root.bounds.x
                y: root.pad
                text: root.text
                font.family: root.family
                font.pixelSize: root.pixelSize
            }
        }
    }
}

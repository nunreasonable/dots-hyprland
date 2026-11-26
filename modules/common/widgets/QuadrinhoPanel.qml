import QtQuick
import QtQuick.Shapes
import qs.modules.common

Item {
    id: root

    property color fill: QuadrinhoTheme.paper
    property color ink: QuadrinhoTheme.ink
    property real line: QuadrinhoTheme.line
    property int tone: 0

    property real topLeftX: 0
    property real topLeftY: 0
    property real topRightX: 0
    property real topRightY: 0
    property real bottomLeftX: 0
    property real bottomLeftY: 0
    property real bottomRightX: 0
    property real bottomRightY: 0
    readonly property bool slanted: root.topLeftX !== 0 || root.topLeftY !== 0 || root.topRightX !== 0 || root.topRightY !== 0 || root.bottomLeftX !== 0 || root.bottomLeftY !== 0 || root.bottomRightX !== 0 || root.bottomRightY !== 0

    Rectangle {
        visible: !root.slanted
        anchors.fill: parent
        color: root.fill
        border.width: root.line
        border.color: root.ink

        QuadrinhoTone {
            visible: root.tone > 0
            anchors.fill: parent
            anchors.margins: root.line
            density: root.tone
        }
    }

    Shape {
        visible: root.slanted
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.fill
            strokeColor: root.ink
            strokeWidth: root.line
            joinStyle: ShapePath.MiterJoin

            PathPolyline {
                readonly property real h: root.line / 2
                path: [Qt.point(root.topLeftX + h, root.topLeftY + h), Qt.point(root.width - root.topRightX - h, root.topRightY + h), Qt.point(root.width - root.bottomRightX - h, root.height - root.bottomRightY - h), Qt.point(root.bottomLeftX + h, root.height - root.bottomLeftY - h), Qt.point(root.topLeftX + h, root.topLeftY + h)]
            }
        }
    }
}

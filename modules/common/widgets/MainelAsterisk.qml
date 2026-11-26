import QtQuick
import QtQuick.Shapes
import qs.modules.common

Item {
    id: root

    property real size: 20
    property color color: MainelTheme.jadeMid
    property real strokeWidthRatio: 0.26
    property real baseRotation: 15
    property bool spinning: false
    property int stepDuration: 400

    implicitWidth: root.size
    implicitHeight: root.size

    readonly property real cx: root.width / 2
    readonly property real cy: root.height / 2
    readonly property real r: root.size / 2
    readonly property real dxDiag: root.r * 0.8660254
    readonly property real dyDiag: root.r * 0.5

    property int stepIndex: 0
    rotation: root.baseRotation + root.stepIndex * 60

    Behavior on rotation {
        enabled: Appearance.animationsEnabled
        NumberAnimation {
            duration: 120 * Appearance.animationScale
            easing.type: Easing.OutQuad
        }
    }

    Timer {
        interval: root.stepDuration
        running: root.spinning && Appearance.animationsEnabled
        repeat: true
        onTriggered: root.stepIndex = (root.stepIndex + 1) % 6
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        antialiasing: true

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.size * root.strokeWidthRatio
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            startX: root.cx
            startY: root.cy - root.r
            PathLine {
                x: root.cx
                y: root.cy + root.r
            }
        }
        ShapePath {
            strokeColor: root.color
            strokeWidth: root.size * root.strokeWidthRatio
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            startX: root.cx - root.dxDiag
            startY: root.cy - root.dyDiag
            PathLine {
                x: root.cx + root.dxDiag
                y: root.cy + root.dyDiag
            }
        }
        ShapePath {
            strokeColor: root.color
            strokeWidth: root.size * root.strokeWidthRatio
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            startX: root.cx - root.dxDiag
            startY: root.cy + root.dyDiag
            PathLine {
                x: root.cx + root.dxDiag
                y: root.cy - root.dyDiag
            }
        }
    }
}

import QtQuick
import QtQuick.Shapes
import qs.modules.common

Item {
    id: root

    property real value: 0
    property bool smooth: true
    property bool bubbles: root.height >= 14
    property color topColor: AquarioTheme.jadeTop
    property color bottomColor: AquarioTheme.jadeBottom
    readonly property real radius: root.height / 2
    readonly property real edge: water.x + water.shown * water.width

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            GradientStop {
                position: 0
                color: AquarioTheme.dark ? "#1affffff" : "#f2ffffff"
            }
            GradientStop {
                position: 1
                color: AquarioTheme.dark ? "#0dffffff" : "#bfe6f4fa"
            }
        }
        border.width: 1
        border.color: AquarioTheme.rimOuter
    }

    AquarioWater {
        id: water
        anchors.fill: parent
        anchors.margins: root.height >= 14 ? 2 : 1
        horizontal: true
        radius: height / 2
        level: root.value
        smooth: root.smooth
        tilt: height * 0.3
        topColor: root.topColor
        bottomColor: root.bottomColor
    }

    Rectangle {
        x: root.radius * 0.7
        y: root.height * 0.16
        width: Math.max(0, Math.min(root.edge - root.height * 0.3, root.width - root.radius * 0.7) - x)
        height: Math.max(1.5, root.height * 0.22)
        radius: height / 2
        visible: root.height >= 10
        color: AquarioTheme.dark ? "#33ffffff" : "#66ffffff"
    }

    Shape {
        anchors.fill: parent
        visible: root.bubbles
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 1.2
            strokeColor: AquarioTheme.bubble
            fillColor: "transparent"

            PathAngleArc {
                moveToStart: true
                centerX: root.width * 0.2
                centerY: root.height * 0.6
                radiusX: root.edge > root.width * 0.2 + root.height * 0.4 ? root.height * 0.12 : 0
                radiusY: radiusX
                startAngle: 0
                sweepAngle: 360
            }
            PathAngleArc {
                moveToStart: true
                centerX: root.width * 0.42
                centerY: root.height * 0.38
                radiusX: root.edge > root.width * 0.42 + root.height * 0.4 ? root.height * 0.09 : 0
                radiusY: radiusX
                startAngle: 0
                sweepAngle: 360
            }
            PathAngleArc {
                moveToStart: true
                centerX: root.width * 0.62
                centerY: root.height * 0.66
                radiusX: root.edge > root.width * 0.62 + root.height * 0.4 ? root.height * 0.07 : 0
                radiusY: radiusX
                startAngle: 0
                sweepAngle: 360
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: root.radius - 1
        color: "transparent"
        border.width: 1
        border.color: AquarioTheme.rimInner
    }
}

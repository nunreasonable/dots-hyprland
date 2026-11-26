import QtQuick
import QtQuick.Shapes
import qs.modules.common

Item {
    id: root

    property real radius: 0
    property bool filled: false
    property bool rim: true
    property real rise: 1

    anchors.fill: parent

    onFilledChanged: {
        if (root.filled && AquarioTheme.moving && root.visible && root.width > 0)
            burst.restart();
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        opacity: root.filled ? 1 : 0
        gradient: Gradient {
            GradientStop {
                position: 0
                color: AquarioTheme.cellTop
            }
            GradientStop {
                position: 1
                color: AquarioTheme.cellBottom
            }
        }

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        Rectangle {
            x: Math.min(root.radius * 0.7, parent.width / 4)
            y: Math.max(3, parent.height * 0.08)
            width: parent.width - 2 * x
            height: Math.max(4, parent.height * 0.12)
            radius: height / 2
            color: "#59ffffff"
        }
    }

    Shape {
        anchors.fill: parent
        visible: burst.running
        opacity: 1 - root.rise
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 1.3
            strokeColor: "#e6ffffff"
            fillColor: "transparent"

            PathAngleArc {
                moveToStart: true
                centerX: root.width * 0.3
                centerY: root.height * (0.9 - 0.6 * root.rise)
                radiusX: 3.5
                radiusY: 3.5
                sweepAngle: 360
            }
            PathAngleArc {
                moveToStart: true
                centerX: root.width * 0.52
                centerY: root.height * (1 - 0.75 * root.rise)
                radiusX: 2.5
                radiusY: 2.5
                sweepAngle: 360
            }
            PathAngleArc {
                moveToStart: true
                centerX: root.width * 0.72
                centerY: root.height * (0.95 - 0.5 * root.rise)
                radiusX: 3
                radiusY: 3
                sweepAngle: 360
            }
        }
    }

    NumberAnimation {
        id: burst
        target: root
        property: "rise"
        from: 0
        to: 1
        duration: 400
        easing.type: Easing.OutQuad
    }

    Rectangle {
        anchors.fill: parent
        visible: root.rim
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: AquarioTheme.rimOuter

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, root.radius - 1)
            color: "transparent"
            border.width: 1.5
            border.color: root.filled ? "#59ffffff" : AquarioTheme.rimInner
        }
    }
}

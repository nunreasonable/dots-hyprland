import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property color color: "transparent"
    property real cornerRadius: 24
    property real strength: 0.55
    readonly property bool lit: root.color.a > 0
    property color shownColor: root.color

    opacity: root.lit ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutCubic
        }
    }
    Behavior on shownColor {
        ColorAnimation {
            duration: 400
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: root.width - 24
                centerY: root.height
                centerRadius: Math.max(root.width, root.height) * 0.78
                focalX: root.width - 24
                focalY: root.height
                GradientStop {
                    position: 0
                    color: Qt.rgba(root.shownColor.r, root.shownColor.g, root.shownColor.b, root.strength)
                }
                GradientStop {
                    position: 0.45
                    color: Qt.rgba(root.shownColor.r, root.shownColor.g, root.shownColor.b, root.strength * 0.35)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(root.shownColor.r, root.shownColor.g, root.shownColor.b, 0)
                }
            }

            PathRectangle {
                x: 0
                y: 0
                width: root.width
                height: root.height
                radius: root.cornerRadius
                topLeftRadius: 0
                topRightRadius: 0
            }
        }
    }
}

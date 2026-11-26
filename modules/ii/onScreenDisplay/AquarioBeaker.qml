import QtQuick
import QtQuick.Shapes
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property real value: 0
    property string icon: ""
    property string name: ""
    property real from: 0
    property real to: 1
    readonly property real level: Math.max(0, Math.min(1, (root.value - root.from) / Math.max(0.0001, root.to - root.from)))

    implicitWidth: 84 + 2 * Appearance.sizes.elevationMargin
    implicitHeight: 250 + 2 * Appearance.sizes.elevationMargin

    StyledRectangularShadow {
        target: body
        visible: StyleTheme.softShadow
    }

    Rectangle {
        id: body
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        radius: width / 2
        color: Appearance.colors.colUiBackground

        AquarioGlass {
            radius: body.radius
            rim: true
            glossHeight: 70
        }

        Item {
            id: tube
            anchors.fill: parent
            anchors.margins: 9

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: AquarioTheme.dark ? "#14ffffff" : "#8cffffff"
                border.width: 1
                border.color: AquarioTheme.rimOuter
            }

            AquarioWater {
                id: water
                anchors.fill: parent
                anchors.margins: 3
                level: root.level
            }

            Shape {
                anchors.fill: water
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: 1.3
                    strokeColor: AquarioTheme.bubble
                    fillColor: "transparent"

                    PathAngleArc {
                        moveToStart: true
                        centerX: water.width * 0.32
                        centerY: water.height * 0.9
                        radiusX: water.surface < water.height * 0.84 ? 5 : 0
                        radiusY: radiusX
                        sweepAngle: 360
                    }
                    PathAngleArc {
                        moveToStart: true
                        centerX: water.width * 0.6
                        centerY: water.height * 0.74
                        radiusX: water.surface < water.height * 0.68 ? 3.5 : 0
                        radiusY: radiusX
                        sweepAngle: 360
                    }
                    PathAngleArc {
                        moveToStart: true
                        centerX: water.width * 0.42
                        centerY: water.height * 0.56
                        radiusX: water.surface < water.height * 0.5 ? 2.5 : 0
                        radiusY: radiusX
                        sweepAngle: 360
                    }
                }
            }

            Rectangle {
                x: 7
                y: tube.width * 0.3
                width: 7
                height: tube.height - tube.width * 0.6
                radius: width / 2
                color: AquarioTheme.dark ? "#1fffffff" : "#59ffffff"
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: AquarioTheme.rimInner
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 18
                spacing: 2

                MaterialSymbol {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.icon
                    fill: 1
                    iconSize: 20
                    color: water.surface < 28 ? AquarioTheme.onWater : AquarioTheme.text
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Math.round(root.value * 100)
                    font.pixelSize: 26
                    font.weight: Font.Bold
                    color: water.surface < 56 ? AquarioTheme.onWater : AquarioTheme.text
                }
            }
        }
    }
}

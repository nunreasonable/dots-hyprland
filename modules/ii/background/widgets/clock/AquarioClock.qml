import QtQuick
import QtQuick.Shapes
import qs.services
import qs.modules.common

Item {
    id: root

    property string text: DateTime.time
    property string date: ""
    property real pixelSize: 90
    property real level: Math.max(0.06, Number(DateTime.minuteStr) / 60)
    readonly property font face: Qt.font({
        family: AquarioTheme.font,
        weight: Font.ExtraBold,
        pixelSize: root.pixelSize
    })
    readonly property rect glyphs: probe.boundingRect
    readonly property real surface: Math.max(0.01, Math.min(0.96, 1 - root.level))
    readonly property real outline: Math.max(2, root.pixelSize / 40)

    readonly property real digitsHeight: root.glyphs.height + root.pixelSize * 0.3

    implicitWidth: Math.max(root.glyphs.x + root.glyphs.width + root.outline * 3, datePill.visible ? datePill.width : 0)
    implicitHeight: root.digitsHeight + (datePill.visible ? datePill.height : root.pixelSize * 0.22)

    Shape {
        id: probe
        visible: false

        ShapePath {
            strokeWidth: -1
            fillColor: "transparent"

            PathText {
                x: root.outline * 2
                y: 0
                font: root.face
                text: root.text
            }
        }
    }

    Shape {
        y: root.pixelSize * 0.14 - root.glyphs.y
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: AquarioTheme.dark ? "#59000000" : "#330d3243"
            strokeWidth: root.outline * 3
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin

            PathText {
                x: root.outline * 2
                y: 0
                font: root.face
                text: root.text
            }
        }

        ShapePath {
            strokeColor: "#ffffff"
            strokeWidth: root.outline
            joinStyle: ShapePath.RoundJoin
            fillGradient: LinearGradient {
                x1: 0
                y1: root.glyphs.y
                x2: 0
                y2: root.glyphs.y + root.glyphs.height
                GradientStop {
                    position: 0
                    color: AquarioTheme.dark ? "#a6ffffff" : "#f2ffffff"
                }
                GradientStop {
                    position: root.surface - 0.005
                    color: AquarioTheme.dark ? "#73e3f6fb" : "#d9e3f4fa"
                }
                GradientStop {
                    position: root.surface
                    color: "#ffffff"
                }
                GradientStop {
                    position: root.surface + 0.025
                    color: AquarioTheme.waterTop
                }
                GradientStop {
                    position: 1
                    color: AquarioTheme.waterBottom
                }
            }

            PathText {
                x: root.outline * 2
                y: 0
                font: root.face
                text: root.text
            }
        }
    }

    Rectangle {
        id: datePill
        visible: root.date !== ""
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.digitsHeight
        width: dateText.implicitWidth + 28
        height: dateText.implicitHeight + 10
        radius: height / 2
        color: AquarioTheme.dark ? "#d90d2536" : "#e6f3fafd"
        border.width: 1
        border.color: AquarioTheme.rimOuter

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: height / 2
            color: "transparent"
            border.width: 1.5
            border.color: AquarioTheme.rimInner
        }

        Text {
            id: dateText
            anchors.centerIn: parent
            text: root.date
            color: AquarioTheme.text
            font.family: AquarioTheme.font
            font.weight: Font.Bold
            font.pixelSize: Math.max(14, Math.round(root.pixelSize * 0.2))
        }
    }
}

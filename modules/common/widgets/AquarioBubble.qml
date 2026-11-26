import QtQuick
import qs.modules.common

Item {
    id: root

    property real diameter: 22
    property real level: 0
    property bool deep: false

    implicitWidth: root.diameter
    implicitHeight: root.diameter

    Rectangle {
        id: sphere
        anchors.fill: parent
        radius: width / 2
        border.width: 1
        border.color: AquarioTheme.rimOuter
        gradient: Gradient {
            GradientStop {
                position: 0
                color: AquarioTheme.dark ? "#1affffff" : "#d4ebf4"
            }
            GradientStop {
                position: 1
                color: AquarioTheme.dark ? "#40ffffff" : "#fbfeff"
            }
        }
    }

    AquarioWater {
        anchors.fill: parent
        anchors.margins: 1.5
        level: root.level
        topColor: root.deep ? AquarioTheme.waterTop : Qt.lighter(AquarioTheme.waterTop, 1.08)
        bottomColor: root.deep ? AquarioTheme.waterDeep : AquarioTheme.waterBottom
        meniscus: 0.8
    }

    Rectangle {
        x: root.diameter * 0.2
        y: root.diameter * 0.12
        width: root.diameter * 0.36
        height: root.diameter * 0.2
        radius: height / 2
        rotation: -28
        color: AquarioTheme.dark ? "#40ffffff" : "#f2ffffff"
    }
}

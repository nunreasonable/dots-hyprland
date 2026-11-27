import QtQuick
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property real value: 0
    property string icon: ""
    property string name: ""

    readonly property int percent: Math.round(Math.max(0, root.value) * 100)

    implicitWidth: 300
    implicitHeight: 118

    onPercentChanged: if (QuadrinhoTheme.motion)
        punch.restart()
    Component.onCompleted: if (QuadrinhoTheme.motion)
        slam.restart()

    Item {
        id: frame
        anchors.fill: parent
        anchors.topMargin: caption.height / 2

        NumberAnimation {
            id: slam
            target: frame
            property: "scale"
            from: 1.04
            to: 1
            duration: 90
        }

        QuadrinhoPanel {
            anchors.fill: parent
        }

        QuadrinhoSpeedLines {
            anchors.fill: parent
            anchors.margins: QuadrinhoTheme.line
            focusX: 0.66
            focusY: 0.5
            clearX: 0.26
            clearY: 0.34
            count: 64
        }

        Rectangle {
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -6
            width: 58
            height: 50
            radius: height / 2
            color: QuadrinhoTheme.paper
            border.width: 2
            border.color: QuadrinhoTheme.ink

            MaterialSymbol {
                anchors.centerIn: parent
                text: root.icon
                iconSize: 30
                fill: 1
                color: QuadrinhoTheme.ink
            }
        }

        QuadrinhoSfxText {
            id: number
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -6
            x: parent.width * 0.66 - width / 2
            rotation: -6
            text: root.percent
            pixelSize: 58
            outline: 3
            shadow: 3

            NumberAnimation {
                id: punch
                target: number
                property: "scale"
                from: 1.12
                to: 1
                duration: 90
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: 12
            }
            height: 12
            color: QuadrinhoTheme.paper
            border.width: 2
            border.color: QuadrinhoTheme.ink

            QuadrinhoTone {
                x: 2
                y: 2
                width: Math.max(0, Math.min(1, root.value)) * (parent.width - 4)
                height: parent.height - 4
                density: 60
            }
        }
    }

    QuadrinhoCaption {
        id: caption
        x: 14
        text: root.name
    }
}

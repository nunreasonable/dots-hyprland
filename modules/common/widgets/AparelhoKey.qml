import QtQuick
import qs.modules.common

Item {
    id: root

    property bool pressed: false
    property bool jade: false
    property bool dark: false
    property bool showLed: false
    property bool ledOn: false
    property real radius: StyleTheme.surface.radiusInner ?? 6
    property real restTravel: 3
    property real pressedTravel: 1
    default property alias content: capContent.data

    readonly property color fillColor: root.jade ? (root.pressed ? (StyleTheme.current?.jadePressed ?? "#22977C") : (StyleTheme.current?.jade ?? "#3CCDAA")) : root.dark ? (root.pressed ? (StyleTheme.current?.keyDarkPressed ?? "#111213") : (StyleTheme.current?.keyDarkFill ?? "#2A2B2E")) : (root.pressed ? (StyleTheme.current?.keyLightPressed ?? "#A4A8AB") : (StyleTheme.current?.keyLightFill ?? "#E9EAEA"))
    readonly property color edgeLightColor: StyleTheme.current?.edgeLight ?? "#F2F3F3"
    readonly property color edgeDarkColor: StyleTheme.current?.edgeDark ?? "#8E9296"
    readonly property real travel: root.pressed ? root.pressedTravel : root.restTravel

    Rectangle {
        id: base
        anchors.fill: parent
        anchors.topMargin: root.restTravel
        radius: root.radius
        color: root.edgeDarkColor
    }

    Rectangle {
        id: cap
        width: parent.width
        height: parent.height - root.travel
        radius: root.radius
        color: root.fillColor
        border.width: 1
        border.color: root.edgeDarkColor
        antialiasing: true

        Behavior on height {
            enabled: Appearance.animationsEnabled
            NumberAnimation {
                duration: root.pressed ? 40 : 90
                easing.type: Easing.OutQuad
            }
        }

        Rectangle {
            visible: !root.pressed
            width: parent.width - 2
            height: 1
            x: 1
            y: 1
            radius: 1
            color: root.edgeLightColor
            opacity: 0.8
        }

        Item {
            id: capContent
            anchors.fill: parent
        }

        AparelhoLed {
            visible: root.showLed
            on: root.ledOn
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.max(2, parent.height * 0.12)
        }
    }
}

import QtQuick
import qs.modules.common

Item {
    id: root

    property color fillColor: SekaiTheme.fill
    property Gradient fillGradient: null
    property real cornerRadius: root.capHeight / 2
    property real ringWidth: SekaiTheme.ringWidth
    property real borderWidth: SekaiTheme.borderWidth
    property real shadowOffset: SekaiTheme.shadowOffset
    property color outlineColor: SekaiTheme.outline
    property color ringColor: SekaiTheme.ring
    property color shadowColor: SekaiTheme.shadow
    property bool pressed: false
    readonly property real capHeight: Math.max(0, root.height - root.shadowOffset)
    default property alias content: cap.data

    Rectangle {
        y: root.shadowOffset
        width: root.width
        height: root.capHeight
        radius: Math.min(root.cornerRadius, height / 2)
        color: root.shadowColor
        antialiasing: true
    }

    Item {
        id: cap
        width: root.width
        height: root.capHeight
        y: root.pressed ? root.shadowOffset : 0

        Behavior on y {
            NumberAnimation {
                duration: root.pressed ? 80 : 260
                easing.type: root.pressed ? Easing.OutQuad : Easing.OutBack
                easing.overshoot: root.pressed ? 0 : 2.2
            }
        }

        Rectangle {
            id: outline
            anchors.fill: parent
            radius: Math.min(root.cornerRadius, height / 2)
            color: root.outlineColor
            antialiasing: true

            Rectangle {
                id: ring
                anchors.fill: parent
                anchors.margins: root.borderWidth
                radius: Math.max(0, outline.radius - root.borderWidth)
                color: root.ringColor
                antialiasing: true

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: root.ringWidth
                    radius: Math.max(0, ring.radius - root.ringWidth)
                    color: root.fillColor
                    gradient: root.fillGradient
                    antialiasing: true
                }
            }
        }
    }
}

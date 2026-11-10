import QtQuick

SequentialAnimation {
    id: root

    required property Item target
    property bool grow: true

    NumberAnimation {
        target: root.target
        property: "scale"
        to: root.grow ? 1.12 : 0.86
        duration: 90
        easing.type: Easing.OutQuad
    }
    NumberAnimation {
        target: root.target
        property: "scale"
        to: 1
        duration: 300
        easing.type: Easing.OutBack
        easing.overshoot: 2.2
    }
}

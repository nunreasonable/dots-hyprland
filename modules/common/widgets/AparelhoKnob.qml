import QtQuick
import qs.modules.common

Item {
    id: root

    property real value: 0 // 0..1
    property real stepSize: 0.1
    property int ticks: 11
    property real diameter: 48
    property real minAngle: -135
    property real maxAngle: 135

    signal moved

    readonly property real angle: root.minAngle + root.value * (root.maxAngle - root.minAngle)
    readonly property color rimColor: StyleTheme.surface.fill ?? "#C9CBCC"
    readonly property color rimBorder: StyleTheme.surface.borderColor ?? "#8E9296"
    readonly property color accentColor: StyleTheme.palette.accent ?? "#3CCDAA"
    readonly property color legendFaintColor: StyleTheme.current?.legendFaint ?? "#62676A"
    readonly property color pointerColor: StyleTheme.current?.keyDarkFill ?? "#2A2B2E"

    implicitWidth: root.diameter
    implicitHeight: root.diameter

    function setValue(v) {
        const clamped = Math.max(0, Math.min(1, v));
        if (clamped === root.value)
            return;
        root.value = clamped;
        root.moved();
    }

    Repeater {
        model: root.ticks
        delegate: Rectangle {
            id: tick
            required property int index
            readonly property real tickAngle: root.minAngle + (index / (root.ticks - 1)) * (root.maxAngle - root.minAngle)
            readonly property real rad: tickAngle * Math.PI / 180
            readonly property real tickRadius: root.diameter / 2 - 2
            readonly property bool lit: index <= Math.round(root.value * (root.ticks - 1))
            width: 2
            height: 5
            radius: 1
            color: tick.lit ? root.accentColor : root.legendFaintColor
            x: root.diameter / 2 + Math.sin(tick.rad) * tick.tickRadius - width / 2
            y: root.diameter / 2 - Math.cos(tick.rad) * tick.tickRadius - height / 2
            rotation: tick.tickAngle
        }
    }

    Rectangle {
        id: rim
        anchors.centerIn: parent
        width: root.diameter - 14
        height: root.diameter - 14
        radius: width / 2
        color: root.rimColor
        border.width: 2
        border.color: root.rimBorder
        antialiasing: true

        Rectangle {
            id: pointer
            width: 3
            height: parent.height / 2 - 5
            radius: 1.5
            color: root.pointerColor
            anchors.horizontalCenter: parent.horizontalCenter
            y: 5
            transformOrigin: Item.Bottom
            rotation: root.angle
            antialiasing: true

            Behavior on rotation {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: 30
                    easing.type: Easing.OutQuad
                }
            }
        }

        Rectangle {
            width: 6
            height: 6
            radius: 3
            color: root.accentColor
            anchors.centerIn: parent
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        property real pressY: 0
        property real pressValue: 0

        onPressed: mouse => {
            dragArea.pressY = mouse.y;
            dragArea.pressValue = root.value;
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return;
            const dy = dragArea.pressY - mouse.y;
            root.setValue(dragArea.pressValue + dy / 150);
        }
        onWheel: event => {
            root.setValue(root.value + (event.angleDelta.y > 0 ? root.stepSize : -root.stepSize));
        }
    }
}

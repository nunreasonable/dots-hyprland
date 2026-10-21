import QtQuick

Item {
    id: root

    property real value: 0
    property bool live: true
    property bool alwaysShowKnob: false
    readonly property bool pressed: mouse.pressed
    readonly property real shownValue: Math.max(0, Math.min(1, mouse.pressed ? mouse.dragValue : root.value))

    signal moved(real value)

    implicitHeight: 14
    opacity: root.enabled ? 1 : 0.5

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: mouse.containsMouse || mouse.pressed ? 4 : 3
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.22)

        Rectangle {
            width: track.width * root.shownValue
            height: parent.height
            radius: parent.radius
            color: "#ffffff"
        }
    }

    Rectangle {
        visible: root.enabled && (root.alwaysShowKnob || mouse.containsMouse || mouse.pressed)
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(root.width - width, track.width * root.shownValue - width / 2))
        width: 10
        height: 10
        radius: 5
        color: "#ffffff"
    }

    MouseArea {
        id: mouse
        property real dragValue: 0

        function valueAt(x) {
            return Math.max(0, Math.min(1, x / Math.max(1, root.width)));
        }

        anchors.fill: parent
        anchors.topMargin: -4
        anchors.bottomMargin: -4
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onPressed: event => {
            mouse.dragValue = mouse.valueAt(event.x);
            if (root.live)
                root.moved(mouse.dragValue);
        }
        onPositionChanged: event => {
            if (!mouse.pressed)
                return;
            mouse.dragValue = mouse.valueAt(event.x);
            if (root.live)
                root.moved(mouse.dragValue);
        }
        onReleased: {
            if (!root.live)
                root.moved(mouse.dragValue);
        }
    }
}

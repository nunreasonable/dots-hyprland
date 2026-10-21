import QtQuick

Rectangle {
    id: root

    property bool highlighted: false
    property bool wheelEnabled: false
    property color colNormal: "transparent"
    property color colHover: Qt.rgba(1, 1, 1, 0.1)
    property color colPressed: Qt.rgba(1, 1, 1, 0.18)
    property color colHighlighted: "#ffffff"
    property color colHighlightedHover: "#ececec"
    readonly property bool hovered: mouse.containsMouse
    readonly property bool pressed: mouse.pressed

    signal clicked
    signal wheelMoved(int steps)

    radius: height / 2
    opacity: root.enabled ? 1 : 0.4
    color: {
        if (root.highlighted)
            return mouse.containsMouse ? root.colHighlightedHover : root.colHighlighted;
        if (mouse.pressed)
            return root.colPressed;
        return mouse.containsMouse ? root.colHover : root.colNormal;
    }

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onWheel: wheel => {
            if (!root.wheelEnabled) {
                wheel.accepted = false;
                return;
            }
            const steps = wheel.angleDelta.y > 0 ? 1 : wheel.angleDelta.y < 0 ? -1 : 0;
            if (steps !== 0)
                root.wheelMoved(steps);
            wheel.accepted = steps !== 0;
        }
    }
}

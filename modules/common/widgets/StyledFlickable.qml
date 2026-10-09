import QtQuick
import QtQuick.Controls
import qs.modules.common

Flickable {
    id: root
    maximumFlickVelocity: 3500
    boundsBehavior: Flickable.DragOverBounds

    property real mouseScrollFactor: Config?.options.interactions.scrolling.mouseScrollFactor ?? 50
    property real mouseScrollDeltaThreshold: Config?.options.interactions.scrolling.mouseScrollDeltaThreshold ?? 120
    property real touchpadSensitivity: Config?.options.interactions.scrolling.touchpadSensitivity ?? 3.75
    // Accumulated scroll destination so wheel deltas stack while animating
    property real scrollTargetY: 0

    ScrollBar.vertical: StyledScrollBar {}

    InertialScrollEngine {
        id: inertialScrollEngine
        flickable: root
        touchpadSensitivity: root.touchpadSensitivity
    }

    MouseArea {
        visible: Config?.options.interactions.scrolling.fasterTouchpadScroll
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function(wheelEvent) {
            if (Math.abs(wheelEvent.angleDelta.y) >= root.mouseScrollDeltaThreshold) {
                const delta = wheelEvent.angleDelta.y / root.mouseScrollDeltaThreshold;
                const maxY = Math.max(0, root.contentHeight - root.height);
                const base = scrollAnim.running ? root.scrollTargetY : root.contentY;
                var targetY = Math.max(0, Math.min(base - delta * root.mouseScrollFactor, maxY));
                root.scrollTargetY = targetY;
                root.contentY = targetY;
            } else {
                inertialScrollEngine._handleTouchpad(wheelEvent);
            }
            wheelEvent.accepted = true;
        }
    }

    Behavior on contentY {
        enabled: !inertialScrollEngine.touchpadActive
        NumberAnimation {
            id: scrollAnim
            duration: Appearance.animation.scroll.duration
            easing.type: Appearance.animation.scroll.type
            easing.bezierCurve: Appearance.animation.scroll.bezierCurve
        }
    }

    // Keep target synced when not animating (e.g., drag/flick or programmatic changes)
    onContentYChanged: {
        if (!scrollAnim.running) {
            root.scrollTargetY = root.contentY;
        }
    }
}

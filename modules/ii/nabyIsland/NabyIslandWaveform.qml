pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.utils
import QtQuick
import Quickshell

Item {
    id: root

    property bool playing: false
    property int barCount: 18
    property real maxBarHeight: 20
    property real minBarHeight: 3
    property real barWidth: 3
    property real barSpacing: 2
    property color color: "#ffffff"
    readonly property bool live: root.playing && root.visible && (QsWindow.window?.visible ?? false)
    readonly property list<real> points: root.live ? AudioSpectrum.points : []

    implicitWidth: root.barCount * root.barWidth + (root.barCount - 1) * root.barSpacing
    implicitHeight: root.maxBarHeight

    SpectrumConsumer {
        active: root.live
    }

    function barHeight(index) {
        const count = root.points.length;
        if (count === 0)
            return root.minBarHeight;
        const half = root.barCount / 2;
        const distance = Math.abs(index - (root.barCount - 1) / 2);
        const band = Math.min(count - 1, Math.floor(distance / half * count * 0.7));
        const value = root.points[band] ?? 0;
        return Math.max(root.minBarHeight, Math.min(root.maxBarHeight, value / 1000 * root.maxBarHeight));
    }

    Row {
        anchors.centerIn: parent
        spacing: root.barSpacing

        Repeater {
            model: root.barCount

            Rectangle {
                required property int index
                anchors.verticalCenter: parent.verticalCenter
                width: root.barWidth
                height: root.barHeight(index)
                radius: root.barWidth / 2
                color: root.color
                opacity: root.playing ? 0.95 : 0.35

                Behavior on height {
                    enabled: root.live
                    NumberAnimation {
                        duration: 80
                        easing.type: Easing.OutQuad
                    }
                }
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }
    }
}

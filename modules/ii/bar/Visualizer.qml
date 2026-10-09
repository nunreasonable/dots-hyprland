import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    property color contentColor: Appearance.colors.colOnLayer0
    property bool contentColorOverridden: false
    property bool vertical: Config.options.bar.vertical
    property bool mirrored: false
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property bool isPlaying: activePlayer?.isPlaying ?? false
    readonly property list<real> points: AudioSpectrum.points
    property int barCount: 20
    property real dotSize: 3
    property real dotSpacing: 3
    property real maxBarHeight: (vertical ? Appearance.sizes.verticalBarWidth : Appearance.sizes.barHeight) * 0.7
    property real maxVisualizerValue: 1000

    implicitWidth: vertical ? Appearance.sizes.verticalBarWidth : barCount * (dotSize + dotSpacing)
    implicitHeight: vertical ? barCount * (dotSize + dotSpacing) : Appearance.sizes.barHeight

    function pointValue(index) {
        if (!root.isPlaying || root.points.length === 0)
            return root.dotSize;
        const rawIndex = (root.vertical && root.mirrored) ? (root.barCount - 1 - index) : index;
        const v = root.points[Math.floor(rawIndex * root.points.length / root.barCount)] ?? 0;
        return Math.max(root.dotSize, (v / root.maxVisualizerValue) * root.maxBarHeight);
    }

    transform: Scale {
        xScale: !root.vertical && root.mirrored ? -1 : 1
        origin.x: root.width / 2
    }

    Row {
        visible: !root.vertical
        anchors.centerIn: parent
        spacing: root.dotSpacing

        Repeater {
            model: root.vertical ? 0 : root.barCount
            Rectangle {
                required property int index
                width: root.dotSize
                height: root.pointValue(index)
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: root.contentColor
                opacity: root.isPlaying ? 0.85 : 0.3
                Behavior on height {
                    NumberAnimation {
                        duration: 80
                        easing.type: Easing.OutQuad
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                    }
                }
            }
        }
    }

    Column {
        visible: root.vertical
        anchors.centerIn: parent
        spacing: root.dotSpacing

        Repeater {
            model: root.vertical ? root.barCount : 0
            Rectangle {
                required property int index
                height: root.dotSize
                width: root.pointValue(index)
                radius: height / 2
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.contentColorOverridden ? root.contentColor : Appearance.colors.colPrimary
                opacity: root.isPlaying ? 0.85 : 0.3
                Behavior on width {
                    NumberAnimation {
                        duration: 80
                        easing.type: Easing.OutQuad
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                    }
                }
            }
        }
    }
}

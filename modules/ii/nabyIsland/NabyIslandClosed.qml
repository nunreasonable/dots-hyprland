pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.utils
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root

    property MprisPlayer player: null
    readonly property bool playing: root.player?.isPlaying ?? false
    readonly property bool live: root.playing && (QsWindow.window?.visible ?? false)
    readonly property list<real> points: root.live ? AudioSpectrum.points : []
    readonly property int barCount: 18
    readonly property real maxBarHeight: 20

    SpectrumConsumer {
        active: root.live
    }

    function barHeight(index) {
        const count = root.points.length;
        if (count === 0)
            return 3;
        const half = root.barCount / 2;
        const distance = Math.abs(index - (root.barCount - 1) / 2);
        const band = Math.min(count - 1, Math.floor(distance / half * count * 0.7));
        const value = root.points[band] ?? 0;
        return Math.max(3, Math.min(root.maxBarHeight, value / 1000 * root.maxBarHeight));
    }

    NabyIslandCover {
        id: cover
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        height: 22
        radius: 6
        artUrl: root.player?.trackArtUrl ?? ""
    }

    Row {
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.barCount

            Rectangle {
                required property int index
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: root.barHeight(index)
                radius: 1.5
                color: "#ffffff"
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

    StyledText {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: DateTime.time
        color: "#ffffff"
        font.pixelSize: 14
        font.weight: Font.DemiBold
        font.variableAxes: ({ "wght": 650 })
    }
}

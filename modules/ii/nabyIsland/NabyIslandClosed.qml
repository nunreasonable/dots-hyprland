pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root

    property MprisPlayer player: null

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

    NabyIslandWaveform {
        anchors.centerIn: parent
        playing: root.player?.isPlaying ?? false
        barCount: 18
        maxBarHeight: 20
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

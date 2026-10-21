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
    property bool showWaveform: true
    property string indicatorKind: ""
    property real recordingSince: 0

    signal indicatorActivated

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
        anchors.horizontalCenterOffset: root.indicatorKind !== "" ? -14 : 0
        visible: root.showWaveform
        playing: root.player?.isPlaying ?? false
        barCount: 18
        maxBarHeight: 20
    }

    StyledText {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        visible: root.indicatorKind === ""
        text: DateTime.time
        color: "#ffffff"
        font.pixelSize: 14
        font.weight: Font.DemiBold
        font.variableAxes: ({ "wght": 650 })
    }

    Loader {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        active: root.indicatorKind !== ""
        sourceComponent: NabyIslandIndicator {
            kind: root.indicatorKind
            recordingSince: root.recordingSince
            onActivated: root.indicatorActivated()
        }
    }
}

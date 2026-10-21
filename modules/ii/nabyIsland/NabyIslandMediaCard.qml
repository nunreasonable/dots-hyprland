pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root

    property MprisPlayer player: null
    readonly property bool playing: root.player?.isPlaying ?? false
    readonly property real length: root.player?.length ?? 0
    readonly property real position: root.player?.position ?? 0
    readonly property bool hasLength: root.length > 0
    readonly property real volume: Audio.sink?.audio?.volume ?? 0
    readonly property bool muted: Audio.sink?.audio?.muted ?? false
    readonly property bool busy: progress.pressed || volumeSlider.pressed

    Component.onCompleted: root.player?.positionChanged()

    Timer {
        running: root.playing
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player?.positionChanged()
    }

    component IconButton: RippleButton {
        id: iconButton
        property string iconName: ""
        property real symbolSize: 22
        implicitWidth: 32
        implicitHeight: 32
        buttonRadius: 16
        colBackground: "transparent"
        colBackgroundHover: Qt.rgba(1, 1, 1, 0.12)
        colRipple: Qt.rgba(1, 1, 1, 0.22)
        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            text: iconButton.iconName
            iconSize: iconButton.symbolSize
            fill: 1
            color: "#ffffff"
        }
    }

    NabyIslandCover {
        id: cover
        x: 16
        y: 12
        width: 56
        height: 56
        radius: 12
        artUrl: root.player?.trackArtUrl ?? ""
    }

    ColumnLayout {
        anchors.left: cover.right
        anchors.leftMargin: 12
        anchors.right: playButton.left
        anchors.rightMargin: 12
        anchors.verticalCenter: cover.verticalCenter
        spacing: 0

        StyledText {
            Layout.fillWidth: true
            text: StringUtils.cleanMusicTitle(root.player?.trackTitle ?? "") || Translation.tr("No media")
            color: "#ffffff"
            font.pixelSize: 15
            font.weight: Font.DemiBold
            font.variableAxes: ({ "wght": 600 })
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            maximumLineCount: 1
        }

        StyledText {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.player?.trackArtist ?? ""
            color: "#ffffff"
            opacity: 0.6
            font.pixelSize: 12
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            maximumLineCount: 1
        }
    }

    RippleButton {
        id: playButton
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: cover.verticalCenter
        implicitWidth: 44
        implicitHeight: 44
        buttonRadius: 22
        colBackground: "#ffffff"
        colBackgroundHover: "#e8e8e8"
        colRipple: "#c8c8c8"
        downAction: () => root.player?.togglePlaying()
        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            text: root.playing ? "pause" : "play_arrow"
            iconSize: 28
            fill: 1
            color: "#000000"
        }
    }

    NabyIslandSlider {
        id: progress
        x: 16
        y: 76
        width: root.width - 32
        height: 14
        enabled: root.hasLength && (root.player?.canSeek ?? false)
        live: false
        value: root.hasLength ? root.position / root.length : 0
        onMoved: value => {
            if (!root.player || !root.hasLength)
                return;
            root.player.position = value * root.length;
            root.player.positionChanged();
        }
    }

    StyledText {
        anchors.left: progress.left
        y: 92
        visible: root.hasLength
        text: StringUtils.friendlyTimeForSeconds(root.position)
        color: "#ffffff"
        opacity: 0.6
        font.pixelSize: 11
    }

    StyledText {
        anchors.right: progress.right
        y: 92
        visible: root.hasLength
        text: StringUtils.friendlyTimeForSeconds(root.length)
        color: "#ffffff"
        opacity: 0.6
        font.pixelSize: 11
    }

    Row {
        x: 12
        y: 108
        spacing: 2

        IconButton {
            iconName: "skip_previous"
            enabled: root.player?.canGoPrevious ?? false
            downAction: () => root.player?.previous()
        }

        IconButton {
            iconName: "skip_next"
            enabled: root.player?.canGoNext ?? false
            downAction: () => root.player?.next()
        }
    }

    IconButton {
        id: volumeButton
        anchors.right: volumeSlider.left
        anchors.rightMargin: 6
        y: 108
        symbolSize: 20
        enabled: Audio.sink !== null
        iconName: root.muted || root.volume <= 0 ? "volume_off" : root.volume < 0.5 ? "volume_down" : "volume_up"
        downAction: () => Audio.toggleMute()
    }

    NabyIslandSlider {
        id: volumeSlider
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: volumeButton.verticalCenter
        width: 110
        height: 14
        enabled: Audio.sink !== null
        alwaysShowKnob: true
        value: root.muted ? 0 : root.volume
        onMoved: value => {
            if (!Audio.sink?.audio)
                return;
            if (Audio.sink.audio.muted)
                Audio.sink.audio.muted = false;
            Audio.sink.audio.volume = value;
        }
    }
}

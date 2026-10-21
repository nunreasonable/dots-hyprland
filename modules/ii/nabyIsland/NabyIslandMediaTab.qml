pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root

    property MprisPlayer player: null
    property bool hasMedia: false
    readonly property bool playing: root.player?.isPlaying ?? false
    readonly property real length: root.player?.length ?? 0
    readonly property real position: root.player?.position ?? 0
    readonly property bool hasLength: root.length > 0
    readonly property real volume: Audio.sink?.audio?.volume ?? 0
    readonly property bool muted: Audio.sink?.audio?.muted ?? false
    readonly property list<MprisPlayer> players: MprisController.players

    implicitHeight: root.hasMedia ? 212 : 160

    Component.onCompleted: root.player?.positionChanged()

    Timer {
        running: root.hasMedia && root.playing
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player?.positionChanged()
    }

    function nextPlayer() {
        if (root.players.length < 2)
            return;
        const index = root.players.indexOf(root.player);
        MprisController.manualPlayer = root.players[(index + 1) % root.players.length];
    }

    function setVolume(value) {
        if (!Audio.sink?.audio)
            return;
        if (Audio.sink.audio.muted)
            Audio.sink.audio.muted = false;
        Audio.sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    component ControlButton: NabyIslandButton {
        id: controlButton
        property string iconName: ""
        property real symbolSize: 26
        width: 40
        height: 40

        MaterialSymbol {
            anchors.centerIn: parent
            text: controlButton.iconName
            iconSize: controlButton.symbolSize
            fill: 1
            color: "#ffffff"
        }
    }

    Item {
        anchors.fill: parent
        visible: root.hasMedia

        NabyIslandCover {
            id: cover
            x: 0
            y: 2
            width: 116
            height: 116
            radius: 16
            artUrl: root.player?.trackArtUrl ?? ""
        }

        Item {
            id: infoColumn
            anchors.left: cover.right
            anchors.leftMargin: 18
            anchors.right: parent.right
            y: 0
            height: 124

            StyledText {
                id: title
                width: parent.width
                text: StringUtils.cleanMusicTitle(root.player?.trackTitle ?? "") || Translation.tr("No media")
                color: "#ffffff"
                font.pixelSize: 17
                font.weight: Font.DemiBold
                font.variableAxes: ({ "wght": 600 })
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                maximumLineCount: 1
            }

            StyledText {
                anchors.top: title.bottom
                anchors.topMargin: 2
                width: parent.width
                visible: text.length > 0
                text: root.player?.trackArtist ?? ""
                color: "#ffffff"
                opacity: 0.6
                font.pixelSize: 12
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                maximumLineCount: 1
            }

            Row {
                id: controls
                anchors.horizontalCenter: parent.horizontalCenter
                y: 46
                spacing: 10

                ControlButton {
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "skip_previous"
                    enabled: root.player?.canGoPrevious ?? false
                    onClicked: root.player?.previous()
                }

                NabyIslandButton {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 52
                    height: 52
                    highlighted: true
                    enabled: root.player?.canTogglePlaying ?? false
                    onClicked: root.player?.togglePlaying()

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.playing ? "pause" : "play_arrow"
                        iconSize: 32
                        fill: 1
                        color: "#000000"
                    }
                }

                ControlButton {
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "skip_next"
                    enabled: root.player?.canGoNext ?? false
                    onClicked: root.player?.next()
                }
            }

            NabyIslandWaveform {
                anchors.horizontalCenter: controls.horizontalCenter
                anchors.top: controls.bottom
                anchors.topMargin: 6
                playing: root.playing
                barCount: 30
                maxBarHeight: 22
                barWidth: 3
                barSpacing: 2.5
            }
        }

        StyledText {
            anchors.left: parent.left
            anchors.bottom: progress.top
            visible: root.hasLength
            text: StringUtils.friendlyTimeForSeconds(root.position)
            color: "#ffffff"
            opacity: 0.6
            font.pixelSize: 11
        }

        StyledText {
            anchors.right: parent.right
            anchors.bottom: progress.top
            visible: root.hasLength
            text: StringUtils.friendlyTimeForSeconds(root.length)
            color: "#ffffff"
            opacity: 0.6
            font.pixelSize: 11
        }

        NabyIslandSlider {
            id: progress
            x: 0
            y: 146
            width: parent.width
            height: 16
            enabled: root.hasLength && (root.player?.canSeek ?? false)
            live: false
            alwaysShowKnob: true
            value: root.hasLength ? root.position / root.length : 0
            onMoved: value => {
                if (!root.player || !root.hasLength)
                    return;
                root.player.position = value * root.length;
                root.player.positionChanged();
            }
        }

        NabyIslandButton {
            id: playerButton
            x: -8
            y: 176
            height: 32
            width: playerRow.implicitWidth + 20
            enabled: root.players.length > 1
            opacity: 1
            colHover: root.players.length > 1 ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
            onClicked: root.nextPlayer()

            Row {
                id: playerRow
                anchors.centerIn: parent
                spacing: 6

                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "music_note"
                    iconSize: 18
                    color: "#ffffff"
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 200)
                    text: root.player?.identity || Translation.tr("Media")
                    color: "#ffffff"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                }

                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.players.length > 1
                    text: "unfold_more"
                    iconSize: 16
                    color: "#ffffff"
                    opacity: 0.7
                }
            }
        }

        NabyIslandButton {
            anchors.right: parent.right
            anchors.rightMargin: -8
            anchors.verticalCenter: playerButton.verticalCenter
            height: 32
            width: volumeRow.implicitWidth + 20
            enabled: Audio.sink !== null
            wheelEnabled: true
            onClicked: Audio.toggleMute()
            onWheelMoved: steps => root.setVolume(root.volume + steps * 0.05)

            Row {
                id: volumeRow
                anchors.centerIn: parent
                spacing: 6

                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.muted || root.volume <= 0 ? "volume_off" : root.volume < 0.5 ? "volume_down" : "volume_up"
                    iconSize: 18
                    color: "#ffffff"
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.muted ? Translation.tr("Muted") : `${Math.round(root.volume * 100)}%`
                    color: "#ffffff"
                    opacity: 0.7
                    font.pixelSize: 12
                }
            }
        }
    }

    Column {
        anchors.centerIn: parent
        visible: !root.hasMedia
        spacing: 6

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 56
            height: 56
            radius: 28
            color: Qt.rgba(1, 1, 1, 0.08)

            MaterialSymbol {
                anchors.centerIn: parent
                text: "headphones"
                iconSize: 28
                color: "#ffffff"
                opacity: 0.8
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Translation.tr("Nothing playing")
            color: "#ffffff"
            font.pixelSize: 15
            font.weight: Font.DemiBold
            font.variableAxes: ({ "wght": 600 })
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Translation.tr("Play something and it shows up here")
            color: "#ffffff"
            opacity: 0.55
            font.pixelSize: 12
        }
    }
}

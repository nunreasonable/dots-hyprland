import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.models
import qs.modules.common.utils
import qs.modules.settingsPc.widgets as SP

Item {
    id: root

    readonly property var player: MprisController.activePlayer
    readonly property bool playing: player?.isPlaying ?? false
    readonly property bool hasShuffle: (player?.shuffleSupported ?? false) && (player?.canControl ?? false)
    readonly property bool hasLoop: (player?.loopSupported ?? false) && (player?.canControl ?? false)
    readonly property bool canSeek: player?.canSeek ?? false

    function seekBy(seconds) {
        if (!player || !canSeek)
            return;
        const length = player.length > 0 ? player.length : Number.MAX_VALUE;
        player.position = Math.max(0, Math.min(length, player.position + seconds));
    }

    function formatTime(seconds) {
        const total = Math.max(0, Math.floor(seconds || 0));
        const m = Math.floor(total / 60);
        const s = total % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    readonly property string artUrl: root.player?.trackArtUrl ?? ""
    readonly property bool artIsLocal: Platform.isWindows && String(root.artUrl).startsWith("file:")
    readonly property string artFilePath: `${Directories.coverArt}/${Qt.md5(root.artUrl)}`
    property bool artDownloaded: false
    readonly property string resolvedArtPath: root.artIsLocal ? root.artUrl : (root.artDownloaded ? (Platform.isWindows ? `file:///${root.artFilePath}` : Qt.resolvedUrl(root.artFilePath)) : "")

    onArtUrlChanged: {
        if (!root.artUrl) {
            root.artDownloaded = false;
            return;
        }
        if (root.artIsLocal) {
            root.artDownloaded = true;
            return;
        }
        coverDownloader.targetFile = root.artUrl;
        coverDownloader.artFilePath = root.artFilePath;
        root.artDownloaded = false;
        if (Platform.isWindows && WindowsNative.fsUtils?.classify(root.artFilePath) === "file") {
            root.artDownloaded = true;
            return;
        }
        coverDownloader.running = true;
    }

    Process {
        id: coverDownloader
        property string targetFile: root.artUrl
        property string artFilePath: root.artFilePath
        command: Platform.isWindows
            ? ["curl", "-4", "-sSL", "-o", artFilePath, "--url", targetFile]
            : ["bash", "-c", '[ -f "$2" ] || curl -4 -sSL -o "$2" --url "$1"', "art", targetFile, artFilePath]
        onExited: (exitCode, exitStatus) => {
            root.artDownloaded = !Platform.isWindows || exitCode === 0;
        }
    }

    ColorQuantizer {
        id: artQuantizer
        source: root.resolvedArtPath
        depth: 0
        rescaleSize: 1
    }

    readonly property color artDominantColor: artQuantizer.colors.length > 0
        ? ColorUtils.mix(artQuantizer.colors[0], Appearance.colors.colPrimaryContainer, 0.8)
        : Appearance.colors.colPrimary

    property QtObject blendedColors: AdaptedMaterialScheme {
        color: root.artDominantColor
    }

    readonly property var colors: (root.player !== null && root.resolvedArtPath !== "") ? root.blendedColors : Appearance.colors

    readonly property list<real> visualizerPoints: AudioSpectrum.points

    SpectrumConsumer {
        active: root.player !== null
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16
        visible: root.player === null

        MaterialSymbol {
            Layout.alignment: Qt.AlignHCenter
            text: "music_off"
            iconSize: Appearance.font.pixelSize.huge * 1.5
            color: Appearance.colors.colSubtext
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Translation.tr("Nothing is playing")
            color: Appearance.colors.colSubtext
        }
    }

    WaveVisualizer {
        visible: root.player !== null
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * 0.4
        live: root.playing
        points: root.visualizerPoints
        color: root.colors.colPrimary
    }

    RowLayout {
        anchors.fill: parent
        visible: root.player !== null
        spacing: 24

        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: root.width * 0.46
            Layout.maximumWidth: root.width * 0.46
            spacing: 12

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    id: artCard
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: Math.min(parent.width, parent.height)
                    height: width
                    radius: Appearance.rounding.large
                    color: root.colors.colSecondaryContainer

                    Image {
                        id: artImage
                        anchors.fill: parent
                        source: root.resolvedArtPath
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        sourceSize: Qt.size(artCard.width * 2, artCard.height * 2)
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: artCard.width
                                height: artCard.height
                                radius: artCard.radius
                            }
                        }
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        visible: artImage.status !== Image.Ready
                        text: "music_note"
                        fill: 1
                        iconSize: 96
                        color: root.colors.colPrimary
                    }
                }
            }

            ColumnLayout {
                id: infoColumn
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: root.player?.trackTitle || Translation.tr("Nothing playing")
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 34
                    font.weight: Font.Bold
                    color: root.colors.colOnLayer0
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.player?.trackArtist ?? ""
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Appearance.font.pixelSize.larger
                    color: root.colors.colSubtext
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: controlsLayout.implicitHeight + 28
                radius: Appearance.rounding.large
                color: Qt.rgba(0, 0, 0, 0.28)

                ColumnLayout {
                    id: controlsLayout
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        StyledText {
                            text: root.formatTime(root.player?.position)
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: root.colors.colOnLayer0
                        }

                        StyledSlider {
                            Layout.fillWidth: true
                            configuration: StyledSlider.Configuration.Wavy
                            enabled: root.player?.canSeek ?? false
                            highlightColor: root.colors.colPrimary
                            trackColor: root.colors.colSecondaryContainer
                            handleColor: root.colors.colPrimary
                            value: (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1)
                            onMoved: root.player.position = value * root.player.length
                        }

                        StyledText {
                            text: "-" + root.formatTime((root.player?.length ?? 0) - (root.player?.position ?? 0))
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: root.colors.colOnLayer0
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        RippleButton {
                            implicitWidth: 40
                            implicitHeight: 40
                            buttonRadius: 20
                            toggled: root.hasShuffle && (root.player?.shuffle ?? false)
                            enabled: root.hasShuffle || root.canSeek
                            colBackground: "transparent"
                            colBackgroundHover: root.colors.colSecondaryContainerHover
                            colBackgroundToggled: root.colors.colSecondaryContainerActive
                            colBackgroundToggledHover: root.colors.colSecondaryContainerActive
                            colRipple: root.colors.colSecondaryContainerActive
                            downAction: () => {
                                if (root.hasShuffle)
                                    root.player.shuffle = !root.player.shuffle;
                                else
                                    root.seekBy(-10);
                            }
                            contentItem: Item {
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: root.hasShuffle ? "shuffle" : "replay_10"
                                    iconSize: 20
                                    color: root.colors.colOnLayer0
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        RippleButton {
                            implicitWidth: 48
                            implicitHeight: 48
                            buttonRadius: 24
                            colBackground: "transparent"
                            colBackgroundHover: root.colors.colSecondaryContainerHover
                            colRipple: root.colors.colSecondaryContainerActive
                            downAction: () => root.player?.previous()
                            contentItem: Item {
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "fast_rewind"
                                    iconSize: 26
                                    fill: 1
                                    color: root.colors.colOnLayer0
                                }
                            }
                        }

                        RippleButton {
                            implicitWidth: 64
                            implicitHeight: 64
                            buttonRadius: root.playing ? Appearance.rounding.large : 32
                            colBackground: root.colors.colPrimary
                            colBackgroundHover: root.colors.colPrimaryHover
                            colRipple: root.colors.colPrimaryActive
                            downAction: () => root.player?.togglePlaying()
                            contentItem: Item {
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: root.playing ? "pause" : "play_arrow"
                                    iconSize: 32
                                    fill: 1
                                    color: root.colors.colOnPrimary
                                }
                            }
                        }

                        RippleButton {
                            implicitWidth: 48
                            implicitHeight: 48
                            buttonRadius: 24
                            colBackground: "transparent"
                            colBackgroundHover: root.colors.colSecondaryContainerHover
                            colRipple: root.colors.colSecondaryContainerActive
                            downAction: () => root.player?.next()
                            contentItem: Item {
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "fast_forward"
                                    iconSize: 26
                                    fill: 1
                                    color: root.colors.colOnLayer0
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        RippleButton {
                            implicitWidth: 40
                            implicitHeight: 40
                            buttonRadius: 20
                            toggled: root.hasLoop && (root.player?.loopState ?? 0) !== 0
                            enabled: root.hasLoop || root.canSeek
                            colBackground: "transparent"
                            colBackgroundHover: root.colors.colSecondaryContainerHover
                            colBackgroundToggled: root.colors.colSecondaryContainerActive
                            colBackgroundToggledHover: root.colors.colSecondaryContainerActive
                            colRipple: root.colors.colSecondaryContainerActive
                            downAction: () => {
                                if (root.hasLoop)
                                    root.player.loopState = root.player.loopState === 0 ? 2 : 0;
                                else
                                    root.seekBy(10);
                            }
                            contentItem: Item {
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: root.hasLoop ? "repeat" : "forward_10"
                                    iconSize: 20
                                    color: root.colors.colOnLayer0
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.rounding.large
            color: "transparent"

            Lyrics {
                id: lyricsView
                anchors.fill: parent
                fontScale: 1.8
                animateTransitions: true
                lineSpacing: 28
                textAlignment: Text.AlignHCenter
                textColor: root.colors.colOnLayer0
                activeColor: root.colors.colPrimary
                indicatorColor: root.colors.colSecondaryContainer
            }

            SP.StyledComboBoxSearch {
                id: playerSelector

                readonly property var players: Array.from(MprisController.players)
                readonly property int activeIndex: players.findIndex(p => p === MprisController.activePlayer)

                visible: players.length > 1
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 14
                width: Math.min(300, parent.width - 28)
                popupAbove: true
                splitIndicator: true
                textRole: "displayName"
                model: players.map(p => ({ displayName: `${p.identity ?? p.desktopEntry ?? Translation.tr("Unknown")} · ${p.trackTitle || "—"}`, icon: "music_note" }))
                onActivated: index => MprisController.manualPlayer = players[index]

                function syncIndex() {
                    playerSelector.currentIndex = playerSelector.activeIndex;
                }
                onActiveIndexChanged: Qt.callLater(syncIndex)
                onModelChanged: Qt.callLater(syncIndex)
                onCountChanged: Qt.callLater(syncIndex)
                Component.onCompleted: syncIndex()

                colBackground: root.colors.colSecondaryContainer
                colBackgroundHover: root.colors.colSecondaryContainerHover
                colBackgroundActive: root.colors.colSecondaryContainerActive
                colText: root.colors.colOnSecondaryContainer
                colAccent: root.colors.colPrimary
                colOnAccent: root.colors.colOnPrimary
                colPopup: Qt.rgba(root.colors.colLayer1.r, root.colors.colLayer1.g, root.colors.colLayer1.b, 1)
                colSelected: root.colors.colSecondaryContainer
                colSelectedHover: root.colors.colSecondaryContainerHover
                colSelectedActive: root.colors.colSecondaryContainerActive
                colOnSelected: root.colors.colOnSecondaryContainer
                colItemHover: root.colors.colSecondaryContainerHover
                colItemActive: root.colors.colSecondaryContainerActive
                colOnItem: root.colors.colOnLayer1
                colSearch: root.colors.colLayer0
                colOnSearch: root.colors.colOnLayer1
                colSearchHint: root.colors.colSubtext
            }
        }
    }
}

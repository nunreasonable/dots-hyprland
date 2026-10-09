pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root
    required property MprisPlayer player

    property var artUrl: root.player?.trackArtUrl ?? ""
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl)
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    property bool downloaded: false
    readonly property bool artIsLocal: Platform.isWindows && String(root.artUrl ?? "").startsWith("file:")
    property string displayedArtFilePath: root.artIsLocal ? root.artUrl : (root.downloaded ? (Platform.isWindows ? `file:///${artFilePath}` : Qt.resolvedUrl(artFilePath)) : "")

    readonly property bool useArtColors: Config.options.sidebar.media.artColors
    property color artDominantColor: {
        if (!root.useArtColors) return Appearance.colors.colPrimaryContainer;
        if (!root.artUrl || root.artUrl.length === 0) return Appearance.m3colors.m3secondaryContainer;
        return ColorUtils.mix((colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary), Appearance.colors.colPrimaryContainer, 0.8);
    }
    property QtObject blendedColors: AdaptedMaterialScheme {
        color: root.artDominantColor
    }

    readonly property bool useShape: Config.options.sidebar.media.shapeArt
    readonly property int materialShape: ShapeUtils.getShape(Config.options.sidebar.media.artShape)
    readonly property bool blurredBackground: Config.options.sidebar.media.blurredBackground
    readonly property bool showLyrics: Config.options.sidebar.media.showLyrics

    implicitWidth: 200
    implicitHeight: background.implicitHeight

    Timer {
        running: root.player?.playbackState === MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: root.player?.positionChanged()
    }

    onArtFilePathChanged: {
        if (!root.artUrl || root.artUrl.length === 0)
            return;
        if (root.artIsLocal)
            return;
        coverArtDownloader.targetFile = root.artUrl;
        coverArtDownloader.artFilePath = root.artFilePath;
        root.downloaded = false;
        if (Platform.isWindows && WindowsNative.fsUtils?.classify(root.artFilePath) === "file") {
            root.downloaded = true;
            return;
        }
        coverArtDownloader.running = true;
    }

    Process {
        id: coverArtDownloader
        property string targetFile: root.artUrl
        property string artFilePath: root.artFilePath
        command: Platform.isWindows
            ? ["curl", "-4", "-sSL", targetFile, "-o", artFilePath]
            : ["bash", "-c", `[ -f ${artFilePath} ] || curl -4 -sSL '${targetFile}' -o '${artFilePath}'`]
        onExited: (exitCode, exitStatus) => {
            root.downloaded = !Platform.isWindows || exitCode === 0;
        }
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0
        rescaleSize: 1
    }

    StyledRectangularShadow {
        target: background
    }

    Rectangle {
        id: background
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        implicitHeight: contentColumn.implicitHeight + 32
        radius: Appearance.rounding.normal
        color: ColorUtils.applyAlpha(root.blendedColors.colLayer0, 1)
        clip: true

        Rectangle {
            id: cardMask
            visible: false
            layer.enabled: Platform.isWindows
            width: background.width
            height: background.height
            radius: background.radius
        }

        StyledImage {
            id: blurredArt
            anchors.fill: parent
            visible: root.blurredBackground && root.displayedArtFilePath !== ""
            source: root.displayedArtFilePath
            fillMode: Image.PreserveAspectCrop
            cache: false
            asynchronous: true

            layer.enabled: root.blurredBackground
            layer.effect: StyledBlurEffect {
                source: blurredArt
                autoPaddingEnabled: !Platform.isWindows
                maskEnabled: Platform.isWindows
                maskSource: Platform.isWindows ? cardMask : null
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }

            Rectangle {
                anchors.fill: parent
                color: ColorUtils.transparentize(root.blendedColors.colLayer0, 0.25)
            }
        }

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            Item {
                id: artBox
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(140, background.width * 0.5)
                Layout.preferredHeight: Layout.preferredWidth

                Rectangle {
                    id: plainArt
                    anchors.fill: parent
                    visible: !root.useShape
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colPrimaryContainer

                    layer.enabled: !root.useShape
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: plainArt.width
                            height: plainArt.height
                            radius: plainArt.radius
                        }
                    }

                    StyledImage {
                        anchors.fill: parent
                        source: root.displayedArtFilePath
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        antialiasing: true
                        sourceSize.width: artBox.width * 2
                        sourceSize.height: artBox.height * 2
                    }
                }

                MaterialShape {
                    id: shapedArt
                    anchors.fill: parent
                    visible: root.useShape
                    shape: root.materialShape
                    color: Appearance.colors.colPrimaryContainer

                    layer.enabled: root.useShape
                    layer.effect: OpacityMask {
                        maskSource: MaterialShape {
                            width: shapedArt.width
                            height: shapedArt.height
                            shape: root.materialShape
                        }
                    }

                    StyledImage {
                        anchors.fill: parent
                        source: root.displayedArtFilePath
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        antialiasing: true
                        sourceSize.width: artBox.width * 2
                        sourceSize.height: artBox.height * 2
                    }
                }

                MaterialSymbol {
                    visible: root.displayedArtFilePath === ""
                    anchors.centerIn: parent
                    fill: 1
                    text: "music_note"
                    color: Appearance.colors.colPrimary
                    iconSize: Appearance.font.pixelSize.hugeass + 50
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.DemiBold
                    color: root.blendedColors.colOnLayer0
                    elide: Text.ElideRight
                    text: StringUtils.cleanMusicTitle(root.player?.trackTitle) || Translation.tr("Not playing")
                }
                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: root.blendedColors.colSubtext
                    elide: Text.ElideRight
                    text: root.player?.trackArtist ?? ""
                }
            }

            Loader {
                id: lyricsLoader
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                active: root.showLyrics && root.player !== null
                visible: active
                sourceComponent: Lyrics {
                    textAlignment: Text.AlignHCenter
                    textColor: root.blendedColors.colOnLayer0
                    activeColor: root.blendedColors.colPrimary
                    indicatorColor: root.blendedColors.colPrimaryContainer
                    lineSpacing: 2
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 18

                Item { Layout.fillWidth: true }

                TrackChangeButton {
                    iconName: "skip_previous"
                    downAction: () => root.player?.previous()
                }

                RippleButton {
                    implicitWidth: 48
                    implicitHeight: 48
                    buttonRadius: (root.player?.isPlaying ?? false) ? Appearance.rounding.normal : 24
                    colBackground: (root.player?.isPlaying ?? false) ? root.blendedColors.colPrimary : root.blendedColors.colSecondaryContainer
                    colBackgroundHover: (root.player?.isPlaying ?? false) ? root.blendedColors.colPrimaryHover : root.blendedColors.colSecondaryContainerHover
                    colRipple: (root.player?.isPlaying ?? false) ? root.blendedColors.colPrimaryActive : root.blendedColors.colSecondaryContainerActive
                    downAction: () => root.player?.togglePlaying()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        iconSize: Appearance.font.pixelSize.huge
                        fill: 1
                        color: (root.player?.isPlaying ?? false) ? root.blendedColors.colOnPrimary : root.blendedColors.colOnSecondaryContainer
                        text: (root.player?.isPlaying ?? false) ? "pause" : "play_arrow"
                    }
                }

                TrackChangeButton {
                    iconName: "skip_next"
                    downAction: () => root.player?.next()
                }

                Item { Layout.fillWidth: true }
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: Math.max(sliderLoader.implicitHeight, progressBarLoader.implicitHeight)

                Loader {
                    id: sliderLoader
                    anchors.fill: parent
                    active: root.player?.canSeek ?? false
                    sourceComponent: StyledSlider {
                        configuration: StyledSlider.Configuration.Wavy
                        highlightColor: root.blendedColors.colPrimary
                        trackColor: root.blendedColors.colSecondaryContainer
                        handleColor: root.blendedColors.colPrimary
                        value: (root.player?.length ?? 0) > 0 ? (root.player.position / root.player.length) : 0
                        onMoved: {
                            if (root.player)
                                root.player.position = value * root.player.length;
                        }
                    }
                }

                Loader {
                    id: progressBarLoader
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                    }
                    active: !(root.player?.canSeek ?? false)
                    sourceComponent: StyledProgressBar {
                        wavy: root.player?.isPlaying ?? false
                        highlightColor: root.blendedColors.colPrimary
                        trackColor: root.blendedColors.colSecondaryContainer
                        value: (root.player?.length ?? 0) > 0 ? (root.player.position / root.player.length) : 0
                    }
                }
            }
        }
    }

    component TrackChangeButton: RippleButton {
        id: trackChangeButton
        implicitWidth: 36
        implicitHeight: 36
        buttonRadius: 18
        property var iconName
        colBackground: "transparent"
        colBackgroundHover: root.blendedColors.colSecondaryContainerHover
        colRipple: root.blendedColors.colSecondaryContainerActive
        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            iconSize: Appearance.font.pixelSize.huge
            fill: 1
            color: root.blendedColors.colOnSecondaryContainer
            text: trackChangeButton.iconName
        }
    }
}

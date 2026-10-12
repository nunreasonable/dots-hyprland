import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import qs.modules.common.functions

import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

Item {
    id: root
    property color contentColor: Appearance.colors.colOnSecondaryContainer
    property bool contentColorOverridden: false
    signal styleEditorRequested
    property bool classic: false
    property bool vertical: false
    property bool borderless: Config.options.bar.borderless
    property bool isMaterial: Config.options.bar.cornerStyle === 3 || Config.options.bar.cornerStyle === 4
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string artUrl: activePlayer?.trackArtUrl ?? ""
    readonly property string trackTitle: activePlayer?.trackTitle ?? ""
    readonly property string trackArtist: activePlayer?.trackArtist ?? ""
    readonly property bool isPlaying: activePlayer?.isPlaying ?? false
    readonly property bool hasTrack: root.trackTitle.length > 0
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media")
    readonly property string displayText: Config.options.bar.media.onlyTitle ? root.cleanedTitle : `${root.cleanedTitle}${root.activePlayer?.trackArtist ? ' • ' + root.activePlayer.trackArtist : ''}`

    Layout.fillHeight: true
    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : root.isMaterial ? materialRow.implicitWidth : root.classic ? rowLayout.implicitWidth + rowLayout.spacing * 2 : Math.max(Config.options.bar.media.minWidth, Math.min(rowLayout.implicitWidth + 8, Config.options.bar.media.maxWidth))
    implicitHeight: root.vertical ? (root.isMaterial ? 32 : verticalProgress.implicitHeight + 12) : Appearance.sizes.barHeight

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: activePlayer.positionChanged()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        onPressed: event => {
            if (event.button === Qt.MiddleButton) {
                activePlayer.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                activePlayer.previous();
            } else if (event.button === Qt.ForwardButton || (event.button === Qt.RightButton && root.classic)) {
                activePlayer.next();
            } else if (event.button === Qt.LeftButton) {
                GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
            }
        }
        onClicked: event => {
            if (event.button === Qt.RightButton && !root.classic)
                activePlayer?.next();
        }
        onPressAndHold: event => {
            if (event.button === Qt.RightButton && !root.classic)
                root.styleEditorRequested();
        }
    }

    Loader {
        id: verticalProgress
        active: root.vertical && !root.isMaterial
        visible: active
        anchors.centerIn: parent
        sourceComponent: ClippedFilledCircularProgress {
            implicitSize: 20
            lineWidth: Appearance.rounding.unsharpen
            value: root.activePlayer?.position / root.activePlayer?.length
            colPrimary: root.contentColor
            enableAnimation: false
            Item {
                anchors.centerIn: parent
                width: 20
                height: 20
                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: 1
                    text: root.activePlayer?.isPlaying ? "pause" : "music_note"
                    iconSize: Appearance.font.pixelSize.normal
                    color: root.contentColor
                }
            }
        }
    }

    Rectangle {
        visible: root.vertical && root.isMaterial
        anchors.centerIn: parent
        color: Appearance.colors.colSecondaryContainer
        radius: Appearance.rounding.full
        implicitWidth: 32
        implicitHeight: 32

        MaterialSymbol {
            anchors.centerIn: parent
            fill: 1
            text: root.isPlaying ? "pause" : "music_note"
            iconSize: Appearance.font.pixelSize.normal
            color: root.contentColor
        }
    }

    RowLayout {
        id: rowLayout
        visible: !root.vertical && !root.isMaterial
        spacing: 4
        anchors.fill: parent

        ClippedFilledCircularProgress {
            id: mediaCircProg
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: root.classic ? 0 : 3
            lineWidth: Appearance.rounding.unsharpen
            value: activePlayer?.position / activePlayer?.length
            implicitSize: 20
            colPrimary: root.contentColor
            enableAnimation: false

            Item {
                anchors.centerIn: parent
                width: mediaCircProg.implicitSize
                height: mediaCircProg.implicitSize

                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: 1
                    text: activePlayer?.isPlaying ? "pause" : "music_note"
                    iconSize: Appearance.font.pixelSize.normal
                    color: root.contentColor
                }
            }
        }

        StyledText {
            visible: Config.options.bar.verbose
            width: rowLayout.width - (CircularProgress.size + rowLayout.spacing * 2)
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.rightMargin: root.classic ? rowLayout.spacing : 0
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            color: root.contentColorOverridden ? root.contentColor : Appearance.colors.colOnLayer1
            text: root.displayText
        }
    }

    Loader {
        id: materialRow
        active: !root.vertical && root.isMaterial
        visible: active
        anchors.centerIn: parent
        sourceComponent: RowLayout {
            spacing: 6

            Loader {
                active: !root.hasTrack
                visible: active
                Layout.alignment: Qt.AlignVCenter
                sourceComponent: RowLayout {
                    spacing: 6

                    UserAvatar {
                        implicitWidth: 26
                        implicitHeight: 26
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: -2
                        iconSize: Appearance.font.pixelSize.normal
                    }

                    ColumnLayout {
                        spacing: -3
                        Layout.alignment: Qt.AlignVCenter
                        Layout.topMargin: 2

                        StyledText {
                            text: Config.options.profile.displayName === "" ? SystemInfo.username : Config.options.profile.displayName
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: root.contentColor
                            elide: Text.ElideRight
                            Layout.maximumWidth: 120
                        }

                        StyledText {
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: root.contentColor
                            opacity: 0.7
                            elide: Text.ElideRight
                            Layout.rightMargin: 8
                            Layout.maximumWidth: 120
                            text: SystemInfo.distroName
                        }
                    }
                }
            }

            Loader {
                active: root.hasTrack
                visible: active
                Layout.alignment: Qt.AlignVCenter
                sourceComponent: RowLayout {
                    spacing: 6

                    Rectangle {
                        id: artRect
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colSecondaryContainer
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: -2

                        StyledImage {
                            id: artImage
                            anchors.fill: parent
                            source: root.artUrl
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: artRect.width * 2
                            sourceSize.height: artRect.height * 2
                            visible: root.artUrl !== "" && status === Image.Ready
                            layer.enabled: visible
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: artRect.width
                                    height: artRect.height
                                    radius: artRect.radius
                                }
                            }
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            fill: 1
                            text: "music_note"
                            iconSize: Appearance.font.pixelSize.normal
                            color: root.contentColor
                            visible: !artImage.visible
                        }
                    }

                    ColumnLayout {
                        spacing: -4
                        Layout.alignment: Qt.AlignVCenter
                        Layout.topMargin: 2

                        StyledText {
                            id: artistText
                            text: root.trackArtist
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: root.contentColor
                            elide: Text.ElideRight
                            Layout.maximumWidth: 120
                        }

                        StyledText {
                            Layout.topMargin: root.trackArtist.length === 0 ? -13 : 0
                            text: StringUtils.cleanMusicTitle(root.trackTitle) || Translation.tr("No media")
                            font.pixelSize: Appearance.font.pixelSize.smallie
                            color: root.contentColor
                            elide: Text.ElideRight
                            opacity: 0.7
                            Layout.maximumWidth: 120
                        }
                    }

                    RippleButton {
                        implicitWidth: 40
                        implicitHeight: 23
                        buttonRadius: root.isPlaying ? Appearance.rounding.normal : 13
                        colBackground: root.isPlaying ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerLow
                        colBackgroundHover: root.isPlaying ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimaryContainerHover
                        colRipple: root.isPlaying ? Appearance.colors.colPrimaryActive : Appearance.colors.colPrimaryContainerActive
                        downAction: () => root.activePlayer?.togglePlaying()
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            text: root.isPlaying ? "pause" : "play_arrow"
                            iconSize: Appearance.font.pixelSize.large
                            fill: 1
                            color: root.isPlaying ? Appearance.colors.colOnPrimary : Appearance.colors.colOnPrimaryContainer
                        }
                    }

                    RippleButton {
                        implicitWidth: 26
                        implicitHeight: 26
                        Layout.leftMargin: -4
                        Layout.rightMargin: -2
                        buttonRadius: 13
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                        colRipple: Appearance.colors.colPrimaryContainerActive
                        downAction: () => root.activePlayer?.next()
                        altAction: () => root.activePlayer?.previous()
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            text: "skip_next"
                            iconSize: Appearance.font.pixelSize.large
                            fill: 1
                            color: root.contentColor
                        }
                    }
                }
            }
        }
    }
}

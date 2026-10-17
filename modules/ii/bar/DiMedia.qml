import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.utils

Item {
    id: diMediaRoot
    required property Item di
    anchors.fill: parent

    readonly property var player: diMediaRoot.di.activePlayer
    readonly property string artUrl: diMediaRoot.player?.trackArtUrl ?? ""
    readonly property var screenName: diMediaRoot.QsWindow.window?.screen?.name
    readonly property bool barContentShown: GlobalStates.isBarContentShown(diMediaRoot.screenName)

    Rectangle {
        id: artMask
        width: diMediaRoot.di.isMaterial ? diMediaRoot.di.pillHeight : diMediaRoot.di.pillHeight - 8
        height: diMediaRoot.di.isMaterial ? diMediaRoot.di.pillHeight : diMediaRoot.di.pillHeight - 8
        anchors {
            left: parent.left
            leftMargin: diMediaRoot.di.isMaterial ? 0 : 4
            verticalCenter: parent.verticalCenter
        }
        radius: diMediaRoot.di.isMaterial ? Appearance.rounding.full : (Appearance.rounding?.small ?? 8)
        color: Appearance.colors.colLayer1

        StyledImage {
            id: artImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: diMediaRoot.artUrl
            sourceSize.width: artMask.width * 2
            sourceSize.height: artMask.height * 2
            visible: diMediaRoot.artUrl !== "" && status === Image.Ready
            layer.enabled: visible
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: artMask.width
                    height: artMask.height
                    radius: artMask.radius
                }
            }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: "music_note"
            iconSize: 14
            color: Appearance.colors.colOnLayer1
            visible: !artImage.visible
        }
    }

    StyledText {
        id: trackTitleMetrics
        visible: false
        text: diMediaRoot.player?.trackTitle ?? ""
        font.pixelSize: Appearance.font.pixelSize.smaller
        font.weight: Font.DemiBold
    }

    StyledText {
        id: trackArtistMetrics
        visible: false
        text: diMediaRoot.player?.trackArtist ?? ""
        font.pixelSize: Appearance.font.pixelSize.smallest
    }

    ColumnLayout {
        id: trackInfoColumn
        anchors {
            left: artMask.right
            leftMargin: 8
            verticalCenter: parent.verticalCenter
            right: mediaControlsRow.visible ? mediaControlsRow.left : (visualizerCanvas.visible ? visualizerCanvas.left : (islandVisualizer.visible ? islandVisualizer.left : parent.right))
            rightMargin: 8
        }
        spacing: diMediaRoot.di.isMaterial ? -2 : -4
        opacity: diMediaRoot.di.mediaTrackInfoVisible ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: diMediaRoot.player?.trackTitle ?? ""
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer0
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            maximumLineCount: 1
        }
        StyledText {
            Layout.fillWidth: true
            text: diMediaRoot.player?.trackArtist ?? ""
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: Appearance.colors.colOnLayer0
            opacity: 0.7
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            maximumLineCount: 1
        }

        readonly property real widestLineWidth: Math.max(trackTitleMetrics.implicitWidth, trackArtistMetrics.implicitWidth)

        readonly property real computedContentWidth: artMask.width + (diMediaRoot.di.isMaterial ? 14 : 8) + trackInfoColumn.widestLineWidth + 12 + (mediaControlsRow.visible ? mediaControlsRow.implicitWidth : (visualizerCanvas.visible ? visualizerCanvas.width : (islandVisualizer.visible ? islandVisualizer.width : 0))) + (diMediaRoot.di.isMaterial ? 0 : 4) + 10

        onComputedContentWidthChanged: diMediaRoot.di.mediaTextContentWidth = trackInfoColumn.computedContentWidth
        Component.onCompleted: diMediaRoot.di.mediaTextContentWidth = trackInfoColumn.computedContentWidth
    }

    MouseArea {
        anchors.fill: trackInfoColumn
        cursorShape: Qt.PointingHandCursor
        onClicked: GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen
    }

    WaveVisualizer {
        id: visualizerCanvas
        anchors {
            right: mediaControlsRow.visible ? mediaControlsRow.left : parent.right
            rightMargin: mediaControlsRow.visible ? 6 : 10
            verticalCenter: parent.verticalCenter
        }
        width: diMediaRoot.di.isMaterial ? 60 : 50
        height: diMediaRoot.di.isMaterial ? diMediaRoot.di.pillHeight * 1.5 : diMediaRoot.di.pillHeight * 0.85
        live: (diMediaRoot.player?.isPlaying ?? false) && diMediaRoot.barContentShown
        points: AudioSpectrum.points
        maxVisualizerValue: 1000
        smoothing: 2
        color: Appearance.colors.colOnLayer0
        visible: Config.options.bar.dynamicIsland.visualizerStyle === "wave"
    }

    SpectrumConsumer {
        active: visualizerCanvas.visible && (visualizerCanvas.QsWindow.window?.visible ?? false) && diMediaRoot.barContentShown
    }

    Visualizer {
        id: islandVisualizer
        anchors {
            right: parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        height: diMediaRoot.di.isMaterial ? diMediaRoot.di.pillHeight * 1.5 : diMediaRoot.di.pillHeight * 0.85
        vertical: false
        isMaterial: false
        barCount: 5
        dotSize: 3
        dotSpacing: 3
        maxBarHeight: diMediaRoot.di.isMaterial ? diMediaRoot.di.pillHeight * 1.5 : diMediaRoot.di.pillHeight * 0.85
        contentColor: Appearance.colors.colOnLayer0
        visible: !Config.options.bar.dynamicIsland.showMediaControls && Config.options.bar.dynamicIsland.visualizerStyle === "dots"
    }

    RowLayout {
        id: mediaControlsRow
        anchors {
            right: parent.right
            rightMargin: diMediaRoot.di.isMaterial ? 4 : 8
            verticalCenter: parent.verticalCenter
        }
        spacing: diMediaRoot.di.isMaterial ? -2 : -4
        visible: Config.options.bar.dynamicIsland.showMediaControls

        Item {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 20
            implicitHeight: 20
            visible: diMediaRoot.player?.canGoPrevious ?? false

            MaterialSymbol {
                anchors.centerIn: parent
                text: "skip_previous"
                fill: 1
                iconSize: diMediaRoot.di.isMaterial ? 20 : 16
                color: Appearance.colors.colOnLayer0
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: diMediaRoot.player?.previous()
            }
        }

        Item {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 22
            implicitHeight: 22

            MaterialSymbol {
                anchors.centerIn: parent
                text: diMediaRoot.player?.isPlaying ? "pause" : "play_arrow"
                fill: 1
                iconSize: diMediaRoot.di.isMaterial ? 20 : 18
                color: Appearance.colors.colOnLayer0
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: diMediaRoot.player?.togglePlaying()
            }
        }

        Item {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 20
            implicitHeight: 20
            visible: diMediaRoot.player?.canGoNext ?? false

            MaterialSymbol {
                anchors.centerIn: parent
                text: "skip_next"
                fill: 1
                iconSize: diMediaRoot.di.isMaterial ? 20 : 16
                color: Appearance.colors.colOnLayer0
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: diMediaRoot.player?.next()
            }
        }
    }
}

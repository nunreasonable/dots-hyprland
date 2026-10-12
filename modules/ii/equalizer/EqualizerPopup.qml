pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris

Scope {
    id: root

    readonly property real popupWidth: 820
    readonly property real popupHeight: 600
    readonly property real popupRounding: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1

    readonly property string equalizerPosition: {
        if (Config.options.bar.layouts.leftLayout.includes("media")) return "left"
        if (Config.options.bar.layouts.middleLayout.includes("media")) return "center"
        if (Config.options.bar.layouts.rightLayout.includes("media")) return "right"
        return "center"
    }

    readonly property bool barVertical: Config.options.bar.vertical
    readonly property string barEdge: {
        if (!barVertical) return Config.options.bar.bottom ? "bottom" : "top"
        return Config.options.bar.bottom ? "right" : "left"
    }
    readonly property real gap: Config.options.bar.cornerStyle === 3 ? Appearance.sizes.hyprlandGapsOut : 0
    readonly property bool cornerStyleReducesGap: Config.options.bar.cornerStyle === 1 || Config.options.bar.cornerStyle === 2
    readonly property real barThickness: barVertical ? Appearance.sizes.verticalBarWidth : Appearance.sizes.barHeight

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property var artUrl: activePlayer?.trackArtUrl ?? ""
    readonly property string artFilePath: `${Directories.coverArt}/${Qt.md5(root.artUrl)}`
    readonly property bool artIsLocal: Platform.isWindows && String(root.artUrl ?? "").startsWith("file:")

    property string displayedArtFilePath: ""
    property string colorSourceFilePath: ""

    function syncArt() {
        if (!root.artUrl || root.artUrl.length === 0) {
            root.displayedArtFilePath = ""
            root.colorSourceFilePath = ""
            return
        }
        root.displayedArtFilePath = root.artUrl
        if (root.artIsLocal || root.artUrl.startsWith("file://")) {
            root.colorSourceFilePath = root.artUrl
            return
        }
        coverArtDownloader.targetFile = root.artUrl
        coverArtDownloader.targetPath = root.artFilePath
        if (Platform.isWindows && WindowsNative.fsUtils?.classify(root.artFilePath) === "file") {
            root.colorSourceFilePath = `file:///${root.artFilePath}`
            return
        }
        coverArtDownloader.running = true
    }
    readonly property color artDominantColor: ColorUtils.mix(
        (colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary),
        Appearance.colors.colPrimaryContainer,
        0.8) || Appearance.m3colors.m3secondaryContainer
    readonly property QtObject blendedColors: AdaptedMaterialScheme {
        color: root.artDominantColor
    }

    Component.onCompleted: root.syncArt()
    onArtFilePathChanged: root.syncArt()

    Process {
        id: coverArtDownloader
        property string targetFile: root.artUrl
        property string targetPath: root.artFilePath
        command: Platform.isWindows
            ? ["curl", "-4", "-sSL", "-o", targetPath, "--url", targetFile]
            : ["bash", "-c", `[ -f ${targetPath} ] || curl -4 -sSL '${targetFile}' -o '${targetPath}'`]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) root.colorSourceFilePath = Platform.isWindows ? `file:///${root.artFilePath}` : Qt.resolvedUrl(root.artFilePath)
        }
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.colorSourceFilePath
        depth: 0
        rescaleSize: 1
    }

    Loader {
        id: equalizerLoader
        active: GlobalStates.equalizerOpen

        sourceComponent: PanelWindow {
            id: panelWindow
            visible: true

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            implicitWidth: root.popupWidth
            implicitHeight: root.popupHeight
            color: "transparent"
            WlrLayershell.namespace: "quickshell:equalizer"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors {
                top: true
                left: true
            }
            margins {
                top: {
                    if (root.barEdge === "top") return root.barThickness + (root.cornerStyleReducesGap ? -root.gap - 6 : root.gap)
                    if (root.barEdge === "bottom") return panelWindow.screen.height - root.barThickness - (root.cornerStyleReducesGap ? -root.gap : root.gap) - root.popupHeight
                    if (root.equalizerPosition === "left") return 0
                    if (root.equalizerPosition === "right") return panelWindow.screen.height - root.popupHeight - root.gap
                    return (panelWindow.screen.height - root.popupHeight) / 2
                }
                left: {
                    if (root.barEdge === "left") return root.barThickness + (root.cornerStyleReducesGap ? -root.gap : root.gap)
                    if (root.barEdge === "right") return panelWindow.screen.width - root.barThickness - (root.cornerStyleReducesGap ? -root.gap : root.gap) - root.popupWidth
                    if (root.equalizerPosition === "left") return 0
                    if (root.equalizerPosition === "right") return panelWindow.screen.width - root.popupWidth - root.gap
                    return (panelWindow.screen.width - root.popupWidth) / 2
                }
            }

            mask: Region {
                item: cardBackground
            }

            Component.onCompleted: GlobalFocusGrab.addDismissable(panelWindow)
            Component.onDestruction: GlobalFocusGrab.removeDismissable(panelWindow)
            Connections {
                target: GlobalFocusGrab
                function onDismissed() { GlobalStates.equalizerOpen = false }
            }

            StyledRectangularShadow {
                target: cardBackground
            }

            Rectangle {
                id: cardBackground
                anchors.fill: parent
                anchors.margins: Appearance.sizes.elevationMargin
                radius: root.popupRounding
                color: ColorUtils.applyAlpha(root.blendedColors.colLayer0, 1)
                border.width: 2
                border.color: Qt.rgba(0, 0, 0, 0.55)

                Behavior on color {
                    ColorAnimation { duration: 420; easing.type: Easing.OutCubic }
                }

                layer.enabled: !Platform.isWindows
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: cardBackground.width
                        height: cardBackground.height
                        radius: cardBackground.radius
                    }
                }

                Rectangle {
                    id: cardMask
                    visible: false
                    layer.enabled: Platform.isWindows
                    width: cardBackground.width
                    height: cardBackground.height
                    radius: cardBackground.radius
                }

                Image {
                    id: blurredArt
                    anchors.fill: parent
                    source: root.displayedArtFilePath
                    sourceSize.width: cardBackground.width
                    sourceSize.height: cardBackground.height
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    antialiasing: true
                    asynchronous: true
                    visible: root.displayedArtFilePath.length > 0
                    opacity: blurredArt.status === Image.Ready ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
                    }

                    layer.enabled: true
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
                        color: ColorUtils.transparentize(Appearance.colors.colScrim, eqView.dimAmount)

                        Behavior on color {
                            ColorAnimation { duration: 420; easing.type: Easing.OutCubic }
                        }
                    }
                }

                WaveVisualizer {
                    anchors.fill: parent
                    live: root.activePlayer?.isPlaying ?? false
                    points: GlobalStates.visualizerPoints
                    maxVisualizerValue: 1000
                    smoothing: 2
                    color: root.blendedColors.colPrimary
                    mask: Platform.isWindows ? cardMask : null

                    Behavior on color {
                        ColorAnimation { duration: 420; easing.type: Easing.OutCubic }
                    }
                }

                EqualizerView {
                    id: eqView
                    anchors.fill: parent
                    blendedColors: root.blendedColors
                    player: root.activePlayer
                    displayedArtFilePath: root.displayedArtFilePath
                    onCloseRequested: GlobalStates.equalizerOpen = false
                }
            }
        }
    }
}

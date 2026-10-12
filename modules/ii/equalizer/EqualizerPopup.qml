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

// Standalone popup, opened only via the "equalizer" button inside the media
// popup's controls (PlayerControl.qml / SidebarMediaCard.qml / DockMedia.qml) -
// there is no separate bar icon for it. Sized on its own terms - nothing here
// references Appearance.sizes.mediaControlsWidth.
//
// Visually styled like the media cards (blurred now-playing art, wave
// visualizer, border), even though this popup isn't tied to any one
// player/track - it just reflects whatever MprisController.activePlayer
// currently is, same as the bar's media widget.
//
// Uses the same Loader-active pattern as modules/ii/mediaControls/MediaControls.qml:
// the PanelWindow is created/destroyed by the Loader in step with
// GlobalStates.equalizerOpen, so the popup's entrance/exit is whatever native
// map/unmap animation the compositor already plays for every other layer-shell
// surface - the same "pop" you see opening media - rather than a hand-rolled
// QML slide.
Scope {
    id: root

    readonly property real popupWidth: 820
    readonly property real popupHeight: 600
    readonly property real popupRounding: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1

    // No standalone "equalizer" bar entry - it only opens via the button
    // inside the media controls/cards, so position it the same way the
    // media controls popup itself is positioned (wherever "media" sits in
    // the bar layout).
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

    // Now-playing art, purely decorative here (same download-cache approach
    // the media cards use) - if nothing is playing this just stays blank
    // and the card falls back to a plain tinted background.
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
            // Layer-shell surfaces don't get keyboard input by default - this
            // popup has text fields (custom preset naming, Last.fm key), which
            // need the surface to actually be grantable keyboard focus.
            // OnDemand means it only takes focus when something inside asks
            // for it.
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

                // root.blendedColors settles onto new album art in place -
                // without this, the whole card would hard-snap to the new
                // tint the instant it resolves instead of easing into it.
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
                    // Fades in once the async load actually finishes, rather
                    // than popping straight to a fully-loaded frame the
                    // instant `visible` flips true.
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
                        // Neutral dark scrim, no color tint - keeps the
                        // blurred art readable without recoloring it from
                        // matugen's blend. Alpha is user-controlled via
                        // eqView.dimAmount (persisted alongside the curve).
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

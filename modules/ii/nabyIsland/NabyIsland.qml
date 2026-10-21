pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris

Scope {
    id: root

    readonly property MprisPlayer player: MprisController.activePlayer
    readonly property bool hasMedia: root.player !== null && ((root.player.trackTitle ?? "") !== "" || root.player.isPlaying)

    readonly property var targetScreen: Quickshell.screens.find(s => s.name === Config.options.nabyIsland.screen) ?? Quickshell.screens[0] ?? null
    readonly property var monitor: root.targetScreen ? Hyprland.monitorFor(root.targetScreen) : null
    readonly property bool coveredByFullscreen: {
        const monitor = root.monitor;
        if (!monitor)
            return false;
        return HyprlandData.windowList.some(win => win.monitor == monitor.id && win.workspace?.id === monitor.activeWorkspace?.id
            && (win.fullscreen ?? 0) > 0 && !win.minimized && (win.focusHistoryID ?? -1) === 0);
    }
    readonly property bool shown: root.targetScreen !== null && !GlobalStates.screenLocked && !root.coveredByFullscreen

    property bool hoverShown: false
    property bool open: false
    property bool windowLarge: false
    readonly property string mode: root.open ? "open" : root.hoverShown ? "hover" : "closed"

    readonly property int flare: 10
    readonly property int closedHeight: 38
    readonly property int closedMediaWidth: 260
    readonly property int closedIdleWidth: 200
    readonly property size mediaCardSize: Qt.size(380, 150)
    readonly property size clockCardSize: Qt.size(240, 84)
    readonly property int openWidth: 460
    readonly property int openMinHeight: 170
    readonly property int openMaxHeight: 456
    readonly property real openHeight: Math.max(root.openMinHeight, Math.min(root.openMaxHeight, panelLoader.item?.implicitHeight ?? 320))
    readonly property size bodySize: {
        if (root.mode === "closed")
            return Qt.size(root.hasMedia ? root.closedMediaWidth : root.closedIdleWidth, root.closedHeight);
        if (root.mode === "open")
            return Qt.size(root.openWidth, root.openHeight);
        return root.hasMedia ? root.mediaCardSize : root.clockCardSize;
    }
    readonly property real bodyRadius: root.mode === "closed" ? 18 : root.mode === "open" ? 26 : 24
    readonly property int windowWidth: 2 * Math.ceil(Math.max(root.mediaCardSize.width * 1.12, root.openWidth + 16) / 2) + 2 * root.flare
    readonly property int windowHeight: root.windowLarge ? root.openMaxHeight + 16 : Math.ceil(root.mediaCardSize.height * 1.12)

    component QuickFadeLoader: Loader {
        property bool shown: true
        opacity: shown ? 1 : 0
        visible: opacity > 0
        active: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 120 * Appearance.animationScale
                easing.type: Easing.OutCubic
            }
        }
    }

    function setHovered(hovered) {
        if (hovered) {
            leaveTimer.stop();
            if (!root.hoverShown)
                enterTimer.restart();
        } else {
            enterTimer.stop();
            if (root.hoverShown)
                leaveTimer.restart();
        }
    }

    function openPanel() {
        if (!root.shown || root.open)
            return;
        shrinkTimer.stop();
        root.windowLarge = true;
        root.open = true;
    }

    function closePanel() {
        if (!root.open)
            return;
        root.open = false;
        shrinkTimer.restart();
    }

    function togglePanel() {
        if (root.open)
            root.closePanel();
        else
            root.openPanel();
    }

    onOpenChanged: {
        if (!root.open) {
            GlobalFocusGrab.removeDismissable(islandWindow);
            return;
        }
        Qt.callLater(() => {
            if (!root.open)
                return;
            GlobalFocusGrab.addDismissable(islandWindow);
            panelLoader.forceActiveFocus();
        });
    }

    onShownChanged: {
        if (root.shown)
            return;
        enterTimer.stop();
        leaveTimer.stop();
        root.hoverShown = false;
        root.closePanel();
        shrinkTimer.stop();
        root.windowLarge = false;
    }

    Connections {
        target: GlobalFocusGrab
        function onDismissed() {
            root.closePanel();
        }
    }

    Timer {
        id: enterTimer
        interval: 150
        onTriggered: root.hoverShown = true
    }

    Timer {
        id: leaveTimer
        interval: 400
        onTriggered: {
            if (islandWindow.busy) {
                leaveTimer.restart();
                return;
            }
            root.hoverShown = false;
        }
    }

    Timer {
        id: shrinkTimer
        interval: Appearance.animation.elementMove.duration + 150
        onTriggered: {
            if (!root.open)
                root.windowLarge = false;
        }
    }

    PanelWindow {
        id: islandWindow
        screen: root.targetScreen
        visible: root.shown
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:nabyIsland"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        readonly property bool busy: mediaCard.item?.busy ?? false

        anchors.top: true
        implicitWidth: root.windowWidth
        implicitHeight: root.windowHeight

        mask: Region {
            item: body
        }

        RoundCorner {
            corner: RoundCorner.CornerEnum.TopRight
            implicitSize: root.flare
            color: "#000000"
            x: body.x - root.flare
            y: 0
        }

        RoundCorner {
            corner: RoundCorner.CornerEnum.TopLeft
            implicitSize: root.flare
            color: "#000000"
            x: body.x + body.width
            y: 0
        }

        Rectangle {
            id: body
            x: (root.windowWidth - body.width) / 2
            y: 0
            width: root.bodySize.width
            height: root.bodySize.height
            radius: root.bodyRadius
            topLeftRadius: 0
            topRightRadius: 0
            color: "#000000"
            clip: true

            Behavior on width {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }
            Behavior on height {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }
            Behavior on radius {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }

            HoverHandler {
                onHoveredChanged: root.setHovered(hovered)
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.mode !== "open"
                onClicked: root.openPanel()
            }

            QuickFadeLoader {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.closedMediaWidth
                height: root.closedHeight
                shown: root.mode === "closed" && root.hasMedia
                sourceComponent: NabyIslandClosed {
                    player: root.player
                }
            }

            QuickFadeLoader {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.closedIdleWidth
                height: root.closedHeight
                shown: root.mode === "closed" && !root.hasMedia
                sourceComponent: NabyIslandClock {
                    compact: true
                }
            }

            FadeLoader {
                id: mediaCard
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.mediaCardSize.width
                height: root.mediaCardSize.height
                shown: root.mode === "hover" && root.hasMedia
                sourceComponent: NabyIslandMediaCard {
                    player: root.player
                }
            }

            FadeLoader {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.clockCardSize.width
                height: root.clockCardSize.height
                shown: root.mode === "hover" && !root.hasMedia
                sourceComponent: NabyIslandClock {
                    compact: false
                }
            }

            FadeLoader {
                id: panelLoader
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.openWidth
                shown: root.mode === "open"
                focus: root.open
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.closePanel();
                        event.accepted = true;
                    }
                }
                sourceComponent: NabyIslandPanel {
                    player: root.player
                    hasMedia: root.hasMedia
                    cornerRadius: body.radius
                    onCloseRequested: root.closePanel()
                }
            }
        }
    }

    IpcHandler {
        target: "nabyIsland"

        function toggle(): void {
            root.togglePanel();
        }
        function open(): void {
            root.openPanel();
        }
        function close(): void {
            root.closePanel();
        }
    }
}

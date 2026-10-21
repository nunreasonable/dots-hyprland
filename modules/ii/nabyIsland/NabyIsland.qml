pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
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
    readonly property string mode: root.open ? "open" : root.hoverShown ? "hover" : "closed"

    readonly property int flare: 10
    readonly property int closedHeight: 38
    readonly property int closedMediaWidth: 260
    readonly property int closedIdleWidth: 200
    readonly property size mediaCardSize: Qt.size(380, 150)
    readonly property size clockCardSize: Qt.size(240, 84)
    readonly property size bodySize: {
        if (root.mode === "closed")
            return Qt.size(root.hasMedia ? root.closedMediaWidth : root.closedIdleWidth, root.closedHeight);
        return root.hasMedia ? root.mediaCardSize : root.clockCardSize;
    }
    readonly property real bodyRadius: root.mode === "closed" ? 18 : 24
    readonly property int windowWidth: 2 * Math.ceil((root.mediaCardSize.width * 1.12) / 2) + 2 * root.flare
    readonly property int windowHeight: Math.ceil(root.mediaCardSize.height * 1.12)

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

    onShownChanged: {
        if (root.shown)
            return;
        enterTimer.stop();
        leaveTimer.stop();
        root.hoverShown = false;
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

    PanelWindow {
        id: islandWindow
        screen: root.targetScreen
        visible: root.shown
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:nabyIsland"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
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
                shown: root.mode !== "closed" && root.hasMedia
                sourceComponent: NabyIslandMediaCard {
                    player: root.player
                }
            }

            FadeLoader {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.clockCardSize.width
                height: root.clockCardSize.height
                shown: root.mode !== "closed" && !root.hasMedia
                sourceComponent: NabyIslandClock {
                    compact: false
                }
            }
        }
    }
}

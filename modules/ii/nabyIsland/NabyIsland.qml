pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.utils
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

    readonly property bool followCursor: Config.options.nabyIsland.followCursor
    readonly property string cursorScreenName: root.followCursor ? (Hyprland.focusedMonitor?.name ?? "") : ""
    property string followedScreenName: ""
    readonly property string wantedScreenName: root.followCursor && root.followedScreenName !== "" ? root.followedScreenName : Config.options.nabyIsland.screen
    readonly property var targetScreen: Quickshell.screens.find(s => s.name === root.wantedScreenName) ?? Quickshell.screens[0] ?? null
    readonly property string screenName: root.targetScreen?.name ?? ""
    readonly property var monitor: root.targetScreen ? Hyprland.monitorFor(root.targetScreen) : null
    readonly property bool coveredByFullscreen: {
        const monitor = root.monitor;
        if (!monitor)
            return false;
        return HyprlandData.windowList.some(win => win.monitor == monitor.id && win.workspace?.id === monitor.activeWorkspace?.id
            && (win.fullscreen ?? 0) > 0 && !win.minimized && (win.focusHistoryID ?? -1) === 0);
    }
    readonly property bool shown: root.targetScreen !== null && !GlobalStates.screenLocked && !GlobalStates.sessionOpen && !root.coveredByFullscreen

    property bool hoverShown: false
    property bool pointerInside: false
    property bool open: false
    property bool windowLarge: false
    readonly property string mode: root.open ? "open" : root.hoverShown ? "hover" : root.transientKind !== "" ? "transient" : "closed"

    readonly property string takeoverScreen: root.shown ? root.screenName : ""
    readonly property bool takeoverOsd: root.shown && Config.options.nabyIsland.showOsd
    readonly property bool takeoverNotifications: root.shown && Config.options.nabyIsland.showNotifications && !root.open && !root.hoverShown
    onTakeoverScreenChanged: GlobalStates.nabyIslandScreen = root.takeoverScreen
    onTakeoverOsdChanged: GlobalStates.nabyIslandOsd = root.takeoverOsd
    onTakeoverNotificationsChanged: GlobalStates.nabyIslandNotifications = root.takeoverNotifications

    readonly property string osdScreenName: Hyprland.focusedMonitor?.name ?? ""
    readonly property string notificationScreenName: Config.options.notifications.forceMonitor.enable ? Config.options.notifications.forceMonitor.name : (Hyprland.focusedMonitor?.name ?? "")
    readonly property bool osdActive: (GlobalStates.osdVolumeOpen || GlobalStates.osdBrightnessOpen) && GlobalStates.nabyIslandTakes("osd", root.osdScreenName)
    readonly property var latestNotification: Notifications.popupList.length > 0 ? Notifications.popupList[Notifications.popupList.length - 1] : null
    readonly property bool notificationActive: root.latestNotification !== null && GlobalStates.nabyIslandTakes("notifications", root.notificationScreenName)
    property bool batteryAlertActive: false
    property string batteryAlertKind: ""
    readonly property string transientKind: root.osdActive ? "osd" : root.batteryAlertActive ? "battery" : root.notificationActive ? "notification" : ""

    property var lastNotification: null
    property int shownNotificationId: -1
    property real shownNotificationTime: 0
    readonly property var shownNotification: root.mode === "transient" && root.transientKind === "notification" ? root.latestNotification : null
    readonly property bool notificationHeld: root.shownNotification !== null && root.pointerInside

    readonly property bool recording: Platform.isWindows && ScreenshotAction.windowsNativeRecording
    property real recordingSince: 0
    readonly property string timerKind: {
        if (!Config.options.nabyIsland.showTimers)
            return "";
        if (TimerService.pomodoroRunning)
            return "pomodoro";
        if (TimerService.countdownRunning)
            return "countdown";
        if (TimerService.stopwatchRunning)
            return "stopwatch";
        if (TimerService.pomodoroSecondsLeft < TimerService.pomodoroLapDuration)
            return "pomodoro";
        if (TimerService.countdownDuration > 0 && TimerService.countdownSecondsLeft < TimerService.countdownDuration)
            return "countdown";
        return TimerService.stopwatchTime > 0 ? "stopwatch" : "";
    }
    readonly property string indicatorKind: root.recording ? "recording" : root.timerKind

    readonly property int flare: 10
    readonly property int closedHeight: 38
    readonly property int closedMediaWidth: (Config.options.nabyIsland.showWaveform ? 260 : 210) + (root.indicatorKind !== "" ? 30 : 0)
    readonly property int closedIdleWidth: 200
    readonly property size mediaCardSize: Qt.size(380, 150)
    readonly property size clockCardSize: Qt.size(240, 84)
    readonly property size osdSize: Qt.size(280, root.closedHeight)
    readonly property size batterySize: Qt.size(260, root.closedHeight)
    readonly property size notificationSize: Qt.size(380, 56)
    readonly property int openWidth: 460
    readonly property int openMinHeight: 170
    readonly property int openMaxHeight: 456
    readonly property real openHeight: Math.max(root.openMinHeight, Math.min(root.openMaxHeight, panelLoader.item?.implicitHeight ?? 320))
    readonly property size bodySize: {
        switch (root.mode) {
        case "closed":
            return Qt.size(root.hasMedia ? root.closedMediaWidth : root.closedIdleWidth, root.closedHeight);
        case "open":
            return Qt.size(root.openWidth, root.openHeight);
        case "transient":
            return root.transientKind === "osd" ? root.osdSize : root.transientKind === "battery" ? root.batterySize : root.notificationSize;
        default:
            return root.hasMedia ? root.mediaCardSize : root.clockCardSize;
        }
    }
    readonly property real bodyRadius: root.mode === "open" ? 26 : root.mode === "hover" ? 24 : root.bodySize.height > root.closedHeight ? 22 : 18
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

    function syncTakeover() {
        GlobalStates.nabyIslandScreen = root.takeoverScreen;
        GlobalStates.nabyIslandOsd = root.takeoverOsd;
        GlobalStates.nabyIslandNotifications = root.takeoverNotifications;
    }

    Component.onCompleted: {
        root.syncTakeover();
        if (root.recording)
            root.recordingSince = Date.now();
        if (root.cursorScreenName !== "")
            root.followedScreenName = root.cursorScreenName;
    }

    Component.onDestruction: {
        GlobalStates.nabyIslandScreen = "";
        GlobalStates.nabyIslandOsd = false;
        GlobalStates.nabyIslandNotifications = false;
    }

    function scheduleFollow() {
        if (!root.followCursor || root.cursorScreenName === "" || root.cursorScreenName === root.screenName)
            followTimer.stop();
        else
            followTimer.restart();
    }

    onCursorScreenNameChanged: root.scheduleFollow()
    onFollowCursorChanged: {
        if (!root.followCursor)
            root.followedScreenName = "";
        root.scheduleFollow();
    }
    onHoverShownChanged: {
        if (!root.hoverShown)
            root.scheduleFollow();
    }

    Timer {
        id: followTimer
        interval: 600
        onTriggered: {
            if (!root.followCursor || root.cursorScreenName === "" || root.open || root.hoverShown)
                return;
            root.followedScreenName = root.cursorScreenName;
        }
    }

    function setHovered(hovered) {
        root.pointerInside = hovered;
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

    function openFocus() {
        Persistent.states.nabyIsland.tab = "focus";
        if (root.timerKind !== "")
            Persistent.states.nabyIsland.focusMode = root.timerKind === "countdown" ? "timer" : root.timerKind;
        root.openPanel();
    }

    onOpenChanged: {
        if (!root.open) {
            GlobalFocusGrab.removeDismissable(islandWindow);
            root.scheduleFollow();
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
        root.pointerInside = false;
        root.hoverShown = false;
        root.closePanel();
        shrinkTimer.stop();
        root.windowLarge = false;
    }

    onTransientKindChanged: {
        if (root.transientKind === "" && root.pointerInside && !root.hoverShown && !root.open)
            enterTimer.restart();
    }

    onLatestNotificationChanged: {
        if (root.latestNotification)
            root.lastNotification = root.latestNotification;
    }

    onShownNotificationChanged: {
        const notif = root.shownNotification;
        if (!notif || notif.notificationId === root.shownNotificationId)
            return;
        root.shownNotificationId = notif.notificationId;
        root.shownNotificationTime = notif.time;
        notificationTimer.interval = Config.options.notifications.timeout;
        notificationTimer.restart();
        if (root.notificationHeld)
            root.holdNotification();
    }

    onNotificationHeldChanged: {
        if (root.notificationHeld) {
            root.holdNotification();
        } else if (root.shownNotificationId !== -1) {
            notificationTimer.interval = 1500;
            notificationTimer.restart();
        }
    }

    function holdNotification() {
        notificationTimer.stop();
        Notifications.cancelTimeout(root.shownNotificationId);
    }

    function expireNotifications() {
        if (!GlobalStates.nabyIslandTakes("notifications", root.notificationScreenName))
            return;
        const upTo = root.shownNotificationTime;
        Notifications.popupList.filter(n => n.time <= upTo).forEach(n => Notifications.timeoutNotification(n.notificationId));
    }

    Timer {
        id: notificationTimer
        onTriggered: root.expireNotifications()
    }

    function triggerBatteryAlert(kind) {
        root.batteryAlertKind = kind;
        root.batteryAlertActive = true;
        batteryAlertTimer.restart();
    }

    Timer {
        id: batteryAlertTimer
        interval: 4000
        onTriggered: root.batteryAlertActive = false
    }

    Connections {
        target: Battery
        function onIsCriticalAndNotChargingChanged() {
            if (Battery.isCriticalAndNotCharging)
                root.triggerBatteryAlert("critical");
        }
        function onIsLowAndNotChargingChanged() {
            if (Battery.isLowAndNotCharging && !Battery.isCriticalAndNotCharging)
                root.triggerBatteryAlert("low");
        }
        function onIsPluggedInChanged() {
            if (Battery.isPluggedIn && Battery.available)
                root.triggerBatteryAlert("charging");
        }
    }

    onRecordingChanged: root.recordingSince = root.recording ? Date.now() : 0

    Connections {
        target: GlobalFocusGrab
        function onDismissed() {
            root.closePanel();
        }
    }

    Timer {
        id: enterTimer
        interval: 150
        onTriggered: {
            if (root.transientKind === "")
                root.hoverShown = true;
        }
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
                width: Math.min(body.width, root.closedMediaWidth)
                height: root.closedHeight
                shown: root.mode === "closed" && root.hasMedia
                sourceComponent: NabyIslandClosed {
                    player: root.player
                    showWaveform: Config.options.nabyIsland.showWaveform
                    indicatorKind: root.indicatorKind
                    recordingSince: root.recordingSince
                    onIndicatorActivated: root.openFocus()
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
                    indicatorKind: root.indicatorKind
                    recordingSince: root.recordingSince
                    onIndicatorActivated: root.openFocus()
                }
            }

            QuickFadeLoader {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.osdSize.width
                height: root.osdSize.height
                shown: root.mode === "transient" && root.transientKind === "osd"
                sourceComponent: NabyIslandOsd {
                    fallbackScreen: root.targetScreen
                }
            }

            QuickFadeLoader {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.batterySize.width
                height: root.batterySize.height
                shown: root.mode === "transient" && root.transientKind === "battery"
                sourceComponent: NabyIslandBattery {
                    kind: root.batteryAlertKind
                }
            }

            QuickFadeLoader {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.notificationSize.width
                height: root.notificationSize.height
                shown: root.mode === "transient" && root.transientKind === "notification"
                sourceComponent: NabyIslandNotification {
                    notification: root.lastNotification
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

pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root

    function pick() {
        GlobalStates.colorPickerOpen = true;
    }

    function dismiss() {
        GlobalStates.colorPickerOpen = false;
        GlobalStates.colorPickerAction = "copy";
    }

    function finish(hex) {
        const action = GlobalStates.colorPickerAction;
        root.dismiss();
        if (!hex)
            return;
        if (action === "accent") {
            Wallpapers.setAccentColor(hex);
            return;
        }
        Quickshell.clipboardText = hex;
        Notifications.sendDesktop(Translation.tr("Color copied"), hex, ["-a", "Shell"]);
    }

    function openOnCursorScreen() {
        const cursor = WindowsNative.input?.cursorPosition() ?? {};
        const cursorScreen = Quickshell.screens.find(s => s.name === cursor.screen);
        const focusedScreen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name);
        const screen = cursorScreen ?? focusedScreen ?? Quickshell.screens[0];
        if (!screen) {
            root.dismiss();
            return;
        }
        pickerLoader.lockedScreen = screen;
        pickerLoader.initialX = cursorScreen ? cursor.x : -1;
        pickerLoader.initialY = cursorScreen ? cursor.y : -1;
        pickerLoader.active = true;
    }

    property double lastPanelClose: 0
    readonly property int settleDelay: 150
    readonly property int panelCloseDelay: 350

    function notePanelState(open) {
        if (open)
            return;
        root.lastPanelClose = Date.now();
        if (settleTimer.running) {
            settleTimer.interval = root.panelCloseDelay;
            settleTimer.restart();
        }
    }

    Component.onCompleted: {
        if (GlobalStates.colorPickerOpen)
            root.dismiss();
    }

    Timer {
        id: settleTimer
        interval: root.settleDelay
        repeat: false
        onTriggered: {
            if (GlobalStates.colorPickerOpen)
                root.openOnCursorScreen();
        }
    }

    Connections {
        target: GlobalStates
        function onColorPickerOpenChanged() {
            if (GlobalStates.colorPickerOpen) {
                const panelJustClosed = Date.now() - root.lastPanelClose < 100;
                settleTimer.interval = panelJustClosed ? root.panelCloseDelay : root.settleDelay;
                settleTimer.restart();
            } else {
                settleTimer.stop();
                pickerLoader.active = false;
            }
        }
        function onSidebarLeftOpenChanged() {
            root.notePanelState(GlobalStates.sidebarLeftOpen);
        }
        function onSidebarRightOpenChanged() {
            root.notePanelState(GlobalStates.sidebarRightOpen);
        }
        function onOverviewOpenChanged() {
            root.notePanelState(GlobalStates.overviewOpen);
        }
    }

    Loader {
        id: pickerLoader
        property var lockedScreen: null
        property real initialX: -1
        property real initialY: -1
        active: false

        sourceComponent: ColorPickerPanel {
            screen: pickerLoader.lockedScreen
            pointerX: pickerLoader.initialX
            pointerY: pickerLoader.initialY
            onDismiss: root.dismiss()
            onPicked: hex => root.finish(hex)
        }
    }

    IpcHandler {
        target: "colorPicker"

        function pick() {
            root.pick();
        }
    }

    GlobalShortcut {
        name: "colorPicker"
        description: "Picks a color on the screen and copies its hex code"
        onPressed: root.pick()
    }
}

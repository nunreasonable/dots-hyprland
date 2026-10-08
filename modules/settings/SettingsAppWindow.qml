import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.common

FloatingWindow {
    id: root
    property bool forceShown: false
    property bool shownOnce: false

    signal closeRequested

    function activate() {
        if (!root.visible)
            return;
        if (root.minimized)
            root.minimized = false;
        const backingWindow = content.Window.window;
        if (backingWindow) {
            backingWindow.raise();
            backingWindow.requestActivate();
        }
        if (Platform.isWindows) {
            focusGrab.active = false;
            focusGrab.active = true;
        }
    }

    visible: content.pageShown || root.forceShown
    title: "illogical-impulse Settings"
    implicitWidth: 1100
    implicitHeight: 750
    minimumSize: Qt.size(750, 500)
    color: Appearance.m3colors.m3background

    onClosed: root.closeRequested()
    onVisibleChanged: {
        if (!root.visible || root.shownOnce)
            return;
        root.shownOnce = true;
        root.activate();
    }

    Timer {
        interval: 3000
        running: !content.pageShown && !root.forceShown
        onTriggered: root.forceShown = true
    }

    SettingsContent {
        id: content
        anchors.fill: parent
        onCloseRequested: root.closeRequested()
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        onActiveChanged: {
            if (focusGrab.active)
                Qt.callLater(() => focusGrab.active = false);
        }
    }
}

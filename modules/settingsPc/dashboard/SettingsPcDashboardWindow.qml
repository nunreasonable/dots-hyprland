import QtQuick
import Quickshell
import qs.modules.common

FloatingWindow {
    id: root

    signal closeRequested

    function activate() {
        if (!root.visible)
            return;
        const backingWindow = content.Window.window;
        if (backingWindow) {
            backingWindow.raise();
            backingWindow.requestActivate();
        }
    }

    property bool centered: false
    function center() {
        const backingWindow = content.Window.window;
        if (root.centered || !backingWindow || !root.screen)
            return;
        backingWindow.x = root.screen.x + Math.round((root.screen.width - backingWindow.width) / 2);
        const barOnTop = !Config.options.bar.bottom && !Config.options.bar.vertical;
        const top = root.screen.y + (barOnTop ? Appearance.sizes.barHeight + 8 : 0) + 32;
        backingWindow.y = Math.max(top, root.screen.y + Math.round((root.screen.height - backingWindow.height) / 2));
        root.centered = true;
    }

    function goToTarget(target) {
        content.goToTarget(target);
    }

    visible: true
    title: "illogical-impulse Settings"
    readonly property real screenWidth: root.screen?.width ?? 1920
    readonly property real screenHeight: root.screen?.height ?? 1080
    implicitWidth: Math.min(1100, root.screenWidth - 80)
    implicitHeight: Math.min(700, root.screenHeight - 140)
    minimumSize: Qt.size(Math.min(900, root.implicitWidth), Math.min(600, root.implicitHeight))
    color: Qt.rgba(Appearance.colors.colUiBackground.r, Appearance.colors.colUiBackground.g, Appearance.colors.colUiBackground.b, 1)

    onClosed: root.closeRequested()
    onVisibleChanged: {
        if (!root.visible)
            return;
        Qt.callLater(root.center);
        Qt.callLater(root.activate);
    }

    SettingsPcDashboardContent {
        id: content
        anchors.fill: parent
        onCloseRequested: root.closeRequested()
    }
}

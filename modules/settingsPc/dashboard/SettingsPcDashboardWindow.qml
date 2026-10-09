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

    function goToTarget(target) {
        content.goToTarget(target);
    }

    visible: true
    title: "illogical-impulse Settings"
    implicitWidth: 1100
    implicitHeight: 700
    minimumSize: Qt.size(900, 600)
    color: Appearance.m3colors.m3background

    onClosed: root.closeRequested()
    onVisibleChanged: {
        if (root.visible)
            Qt.callLater(root.activate);
    }

    SettingsPcDashboardContent {
        id: content
        anchors.fill: parent
        onCloseRequested: root.closeRequested()
    }
}

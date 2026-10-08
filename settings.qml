//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
//@ pragma Env IIW_PROCESS=settings

// Adjust this to make the app smaller or larger
//@ pragma Env QT_SCALE_FACTOR=1

import QtQuick
import QtQuick.Controls
import Quickshell
import qs.modules.common
import qs.modules.settings

ApplicationWindow {
    id: root
    property bool forceShown: false

    visible: content.pageShown || root.forceShown
    onClosing: Qt.quit()
    title: "illogical-impulse Settings"

    Component.onCompleted: {
        if (Platform.isWindows && Quickshell.env("IIW_WATCH_FILES") !== "1")
            Quickshell.watchFiles = false;
        Config.readWriteDelay = 0;
    }

    minimumWidth: 750
    minimumHeight: 500
    width: 1100
    height: 750
    color: Appearance.m3colors.m3background

    Timer {
        interval: 3000
        running: !content.pageShown && !root.forceShown
        onTriggered: root.forceShown = true
    }

    SettingsContent {
        id: content
        anchors.fill: parent
        asynchronousFirstPage: false
        onCloseRequested: root.close()
    }
}

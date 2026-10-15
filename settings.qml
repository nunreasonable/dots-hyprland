//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
//@ pragma Env IIW_PROCESS=settings

// Adjust this to make the app smaller or larger
//@ pragma Env QT_SCALE_FACTOR=1

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.settings
import qs.modules.settingsPc

ApplicationWindow {
    id: root
    property bool forceShown: false
    readonly property bool wantsPcLayout: Config.options.appearance.settingsLayout === "end4pc"
    property bool pcLayout: false
    property bool layoutChosen: false
    readonly property bool pageShown: contentLoader.item?.pageShown ?? false
    property bool handingOff: Platform.isWindows

    visible: (root.pageShown || root.forceShown) && !root.handingOff
    onClosing: Qt.quit()
    title: "illogical-impulse Settings"

    function chooseLayout() {
        if (!Config.ready || root.layoutChosen)
            return;
        root.pcLayout = root.wantsPcLayout;
        root.layoutChosen = true;
    }

    Component.onCompleted: {
        if (Platform.isWindows && Quickshell.env("IIW_WATCH_FILES") !== "1")
            Quickshell.watchFiles = false;
        Config.readWriteDelay = 0;
        root.chooseLayout();
        if (root.handingOff)
            shellHandoff.running = true;
    }

    Process {
        id: shellHandoff
        command: ["qsw", "-p", Quickshell.shellPath(""), "ipc", "call", "settings", "open"]
        onExited: (exitCode, exitStatus) => {
            if (!root.handingOff)
                return;
            if (exitCode === 0)
                Qt.quit();
            else
                root.handingOff = false;
        }
    }

    Timer {
        interval: 4000
        running: root.handingOff
        onTriggered: root.handingOff = false
    }

    onPageShownChanged: {
        if (root.pageShown)
            root.forceShown = true;
    }

    onWantsPcLayoutChanged: layoutSwitchTimer.restart()

    Connections {
        target: Config
        function onReadyChanged() {
            root.chooseLayout();
        }
    }

    Timer {
        id: layoutSwitchTimer
        interval: 0
        onTriggered: {
            if (!root.layoutChosen || root.pcLayout === root.wantsPcLayout)
                return;
            root.pcLayout = root.wantsPcLayout;
        }
    }

    minimumWidth: 750
    minimumHeight: 500
    width: 1100
    height: 750
    color: Appearance.m3colors.m3background

    Timer {
        interval: 3000
        running: !root.pageShown && !root.forceShown && !root.handingOff
        onTriggered: root.forceShown = true
    }

    Loader {
        id: contentLoader
        anchors.fill: parent
        active: root.layoutChosen && !root.handingOff
        sourceComponent: root.pcLayout ? pcContentComponent : iiContentComponent
    }

    Component {
        id: iiContentComponent

        SettingsContent {
            asynchronousFirstPage: false
            onCloseRequested: root.close()
        }
    }

    Component {
        id: pcContentComponent

        SettingsPcContent {
            asynchronousFirstPage: false
            onCloseRequested: root.close()
            Component.onCompleted: Qt.callLater(() => focusContent())
        }
    }
}

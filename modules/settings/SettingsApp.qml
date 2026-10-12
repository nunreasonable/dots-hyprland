pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.settingsPc as SettingsPc
import qs.modules.settingsPc.dashboard as SettingsPcDashboard

Singleton {
    id: root
    property bool isOpen: false
    property var target: null
    readonly property bool wantsPcLayout: (Config.options?.appearance?.settingsLayout ?? "ii") === "end4pc"
    readonly property bool wantsDashboard: Config.options?.settings?.style === "dashboard"
    property bool pcLayout: false
    property bool dashboardMode: false
    property bool handoff: false
    readonly property var activeLoader: root.pcLayout ? pcLoader : windowLoader

    function load() {
    }

    function ensureSource(pc = root.pcLayout) {
        if (pc) {
            if (pcLoader.source == "")
                pcLoader.source = Qt.resolvedUrl(root.dashboardMode ? "../settingsPc/dashboard/SettingsPcDashboardWindow.qml" : "../settingsPc/SettingsPcPanel.qml");
        } else if (windowLoader.source == "") {
            windowLoader.source = Qt.resolvedUrl("SettingsAppWindow.qml");
        }
    }

    function open() {
        if (!root.isOpen) {
            root.pcLayout = root.wantsPcLayout;
            root.dashboardMode = root.wantsDashboard;
        }
        root.ensureSource();
        if (root.isOpen && root.activeLoader.item) {
            root.activeLoader.item.activate();
            root.applyTarget();
            return;
        }
        root.isOpen = true;
    }

    function openAt(pageId, label, section, subsection) {
        root.target = {
            page: pageId,
            label: label ?? "",
            section: section ?? "",
            subsection: subsection ?? ""
        };
        root.open();
    }

    function applyTarget() {
        if (!root.target || !root.pcLayout || !pcLoader.item)
            return;
        const target = root.target;
        root.target = null;
        pcLoader.item.goToTarget(target);
    }

    function close() {
        root.handoff = false;
        root.isOpen = false;
        root.target = null;
    }

    function finishHandoff() {
        if (root.handoff && root.activeLoader.item && root.activeLoader.item.visible)
            handoffTimer.restart();
    }

    function toggle() {
        if (root.isOpen)
            root.close();
        else
            root.open();
    }

    onWantsPcLayoutChanged: layoutSwitchTimer.restart()
    onWantsDashboardChanged: layoutSwitchTimer.restart()

    Timer {
        id: layoutSwitchTimer
        interval: 0
        onTriggered: {
            if (root.pcLayout === root.wantsPcLayout && root.dashboardMode === root.wantsDashboard)
                return;
            const reopen = root.isOpen;
            if (reopen && root.dashboardMode === root.wantsDashboard) {
                root.ensureSource(root.wantsPcLayout);
                root.handoff = true;
                handoffLimit.restart();
                root.pcLayout = root.wantsPcLayout;
                root.finishHandoff();
                return;
            }
            root.isOpen = false;
            root.pcLayout = root.wantsPcLayout;
            if (root.dashboardMode !== root.wantsDashboard) {
                root.dashboardMode = root.wantsDashboard;
                pcLoader.source = "";
            }
            if (reopen) {
                root.ensureSource();
                root.isOpen = true;
            }
        }
    }

    Timer {
        id: handoffTimer
        interval: 300
        onTriggered: root.handoff = false
    }

    Timer {
        id: handoffLimit
        interval: 3500
        onTriggered: root.handoff = false
    }

    Connections {
        target: root.handoff ? root.activeLoader.item : null
        function onVisibleChanged() {
            root.finishHandoff();
        }
    }

    LazyLoader {
        id: windowLoader
        active: root.isOpen && (!root.pcLayout || root.handoff)
        onItemChanged: root.finishHandoff()
    }

    LazyLoader {
        id: pcLoader
        active: root.isOpen && (root.pcLayout || root.handoff)
        onItemChanged: {
            root.applyTarget();
            root.finishHandoff();
        }
    }

    Connections {
        target: windowLoader.item
        function onCloseRequested() {
            if (!root.pcLayout)
                root.close();
        }
    }

    Connections {
        target: pcLoader.item
        function onCloseRequested() {
            if (root.pcLayout)
                root.close();
        }
    }

    IpcHandler {
        target: "settings"

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }

        function toggle(): void {
            root.toggle();
        }
    }

    GlobalShortcut {
        name: "settingsOpen"
        description: "Opens the settings window"

        onPressed: root.open()
    }

    GlobalShortcut {
        name: "settingsToggle"
        description: "Toggles the settings window"

        onPressed: root.toggle()
    }
}

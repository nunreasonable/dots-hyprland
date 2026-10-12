//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
//@ pragma Env IIW_PROCESS=shell

// Remove two slashes below and adjust the value to change the UI scale
////@ pragma Env QT_SCALE_FACTOR=1

import "modules/common"
import "services"
import "panelFamilies"
import "modules/settings"

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root
    settings.watchFiles: !Platform.isWindows || Quickshell.env("IIW_WATCH_FILES") === "1"

    // Stuff for every panel family
    ReloadPopup {}

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Hyprsunset.load()
        FirstRunExperience.load()
        if (!Platform.isWindows) {
            ConflictKiller.load()
            Cliphist.refresh()
            Updates.load()
        }
        Wallpapers.load()
        VisualStyle.load()
        PeripheralBattery.load()
        if (Platform.isWindows) {
            WindowsTerminalTheme.load()
            WindowsPins.load()
            SettingsApp.load()
        }
    }

    Timer {
        running: FirstRunExperience.welcomePending
        interval: PanelLoaderQueue.drained ? 0 : 10000
        onTriggered: FirstRunExperience.launchWelcome()
    }


    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.taskbar
        property: "hoverOnly"
        value: Config.options.windowsPort.taskbarHoverOnly && !Config.options.windowsPort.nativeTaskbar
    }
    readonly property bool nativeTaskbarTakesOver: Platform.isWindows && Config.ready && WindowsNative.ready && Config.options.panelFamily === "ii" && Config.options.windowsPort.nativeTaskbar && Config.options.windowsPort.taskbarHoverOnly
    onNativeTaskbarTakesOverChanged: {
        if (root.nativeTaskbarTakesOver)
            Qt.callLater(() => WindowsNative.taskbar.turnOffAutoHide());
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.desktopLayer
        property: "enabled"
        value: Config.options.windowsPort.backgroundBehindIcons
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.tiling
        property: "enabled"
        value: Config.options.windowsPort.tiling.enable
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.tiling
        property: "gapsIn"
        value: Config.options.windowsPort.tiling.gapsIn
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.tiling
        property: "gapsOut"
        value: Config.options.windowsPort.tiling.gapsOut
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.tiling
        property: "preserveSplit"
        value: Config.options.windowsPort.tiling.preserveSplit
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.tiling
        property: "excluded"
        value: Config.options.windowsPort.tiling.excluded
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.tiling
        property: "layout"
        value: Config.options.hyprland.general.layout
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.tiling
        property: "smartSplit"
        value: Config.options.windowsPort.tiling.smartSplit
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.tiling
        property: "forceSplit"
        value: Config.options.windowsPort.tiling.forceSplit
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.tiling
        property: "defaultSplitRatio"
        value: Config.options.windowsPort.tiling.defaultSplitRatio
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.tiling
        property: "masterNewStatus"
        value: Config.options.windowsPort.tiling.master.newStatus
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.tiling
        property: "masterNewOnTop"
        value: Config.options.windowsPort.tiling.master.newOnTop
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.tiling
        property: "masterOrientation"
        value: Config.options.windowsPort.tiling.master.orientation
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.tiling
        property: "masterFactor"
        value: Config.options.windowsPort.tiling.master.mfact
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.windowManager
        property: "borders"
        value: Config.options.hyprland.general.borderSize <= 0 ? "none" : Config.options.hyprland.general.borderColor.enable ? "colors" : "system"
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.windowManager
        property: "activeBorderColor"
        value: root.windowBorderColor(Config.options.hyprland.general.borderColor.activeRole, Config.options.hyprland.general.borderColor.activeOpacity)
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.windowManager
        property: "inactiveBorderColor"
        value: root.windowBorderColor(Config.options.hyprland.general.borderColor.inactiveRole, Config.options.hyprland.general.borderColor.inactiveOpacity)
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.windowManager
        property: "corners"
        value: Config.options.windowsPort.decoration.corners
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.windowManager
        property: "workspaceBackAndForth"
        value: Config.options.windowsPort.binds.workspaceBackAndForth
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.windowManager
        property: "warpOnChangeWorkspace"
        value: Config.options.windowsPort.cursor.warpOnChangeWorkspace
    }
    function windowBorderColor(role, opacity) {
        const c = Qt.color(Appearance.getColorFromName(role));
        const b = Appearance.m3colors.m3background;
        const a = Math.max(0, Math.min(1, opacity * c.a));
        return Qt.rgba(c.r * a + b.r * (1 - a), c.g * a + b.g * (1 - a), c.b * a + b.b * (1 - a), 1);
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.superDrag
        property: "enabled"
        value: Config.options.windowsPort.superDrag
    }
    Binding {
        when: Platform.isWindows && WindowsNative.ready
        target: WindowsNative.desktopLayer
        property: "aboveIcons"
        value: ["quickshell:backgroundWidgets"]
    }
    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.blur
        property: "enabled"
        value: !Config.options.windowsPort.gameMode.enable
    }

    // Panel families
    property list<string> families: ["ii", "waffle"]
    function cyclePanelFamily() {
        if (Platform.isWindows) {
            if (Config.options.panelFamily !== "ii")
                Config.options.panelFamily = "ii";
            else
                Config.options.windowsPort.nativeTaskbar = !Config.options.windowsPort.nativeTaskbar;
            return;
        }
        const currentIndex = families.indexOf(Config.options.panelFamily)
        const nextIndex = (currentIndex + 1) % families.length
        Config.options.panelFamily = families[nextIndex]
    }

    property bool lookReady: MaterialThemeLoader.ready && Translation.ready
    Timer {
        id: lookTimeout
        interval: 1500
        running: Config.ready && !root.lookReady
        onTriggered: root.lookReady = true
    }

    component PanelFamilyLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && root.lookReady && Config.options.panelFamily === identifier && extraCondition
    }
    
    PanelFamilyLoader {
        identifier: "ii"
        component: IllogicalImpulseFamily {}
    }

    PanelFamilyLoader {
        identifier: "waffle"
        component: WaffleFamily {}
    }


    // Shortcuts
    IpcHandler {
        target: "panelFamily"

        function cycle(): void {
            root.cyclePanelFamily()
        }
    }

    GlobalShortcut {
        name: "panelFamilyCycle"
        description: "Cycles panel family"

        onPressed: root.cyclePanelFamily()
    }
}


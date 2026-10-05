//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Remove two slashes below and adjust the value to change the UI scale
////@ pragma Env QT_SCALE_FACTOR=1

import "modules/common"
import "services"
import "panelFamilies"

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    // Stuff for every panel family
    ReloadPopup {}

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Hyprsunset.load()
        FirstRunExperience.load()
        ConflictKiller.load()
        Cliphist.refresh()
        Wallpapers.load()
        WindowsTerminalTheme.load()
        Updates.load()
    }


    Binding {
        when: Platform.isWindows && Config.ready && WindowsNative.ready
        target: WindowsNative.taskbar
        property: "hoverOnly"
        value: Config.options.windowsPort.taskbarHoverOnly
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
        when: Platform.isWindows && WindowsNative.ready
        target: WindowsNative.desktopLayer
        property: "aboveIcons"
        value: ["quickshell:backgroundWidgets"]
    }

    // Panel families
    property list<string> families: ["ii", "waffle"]
    function cyclePanelFamily() {
        const currentIndex = families.indexOf(Config.options.panelFamily)
        const nextIndex = (currentIndex + 1) % families.length
        Config.options.panelFamily = families[nextIndex]
    }

    component PanelFamilyLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && Config.options.panelFamily === identifier && extraCondition
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


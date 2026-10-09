pragma Singleton
import qs.modules.common
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property list<string> styles: ["ii", "end4pc"]
    readonly property string selected: Config.options.appearance.visualStyle
    readonly property string applied: Config.options.appearance.visualStyleApplied

    function load() {
        syncTimer.restart();
    }

    function sync() {
        if (!Config.ready || !root.styles.includes(root.selected) || root.selected === root.applied)
            return;
        root.applyPreset(root.selected);
    }

    function applyPreset(style) {
        const pc = style === "end4pc";
        Config.options.bar.utilButtons.showColorPicker = pc;
        Config.options.bar.utilButtons.showDarkModeToggle = !pc;
        Config.options.bar.utilButtons.showKeyboardToggle = !pc;
        Config.options.bar.workspaces.alwaysShowNumbers = pc;
        Config.options.bar.workspaces.showAppIcons = !pc;
        Config.options.bar.resources.alwaysShowSwap = !pc;
        Config.options.bar.resources.showValue = !pc;
        Config.options.bar.utilButtons.showWallpaperToggle = pc;
        Config.options.bar.layouts.leftLayout = pc ? BarLayouts.end4pcLeft : BarLayouts.classicLeft;
        Config.options.bar.layouts.middleLayout = pc ? BarLayouts.end4pcMiddle : BarLayouts.classicMiddle;
        Config.options.bar.layouts.rightLayout = pc ? BarLayouts.end4pcRight : BarLayouts.classicRight;
        Config.options.sidebar.quickSliders.enable = pc;
        Config.options.appearance.settingsLayout = style;
        Config.options.appearance.visualStyleApplied = style;
    }

    onSelectedChanged: syncTimer.restart()

    Timer {
        id: syncTimer
        interval: 0
        onTriggered: root.sync()
    }

    Connections {
        target: Config
        function onReadyChanged() {
            syncTimer.restart();
        }
    }
}

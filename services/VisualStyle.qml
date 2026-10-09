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

    readonly property int presetVersion: 1

    function sync() {
        if (!Config.ready || !root.styles.includes(root.selected))
            return;
        if (root.selected !== root.applied) {
            root.applyPreset(root.selected);
            return;
        }
        if ((Config.options.appearance.visualStylePresetVersion ?? 0) < root.presetVersion)
            root.upgradePreset(root.applied);
    }

    function upgradePreset(style) {
        const pc = style === "end4pc";
        if (pc)
            root.applyNewKeys(pc);
        Config.options.appearance.visualStylePresetVersion = root.presetVersion;
    }

    function applyNewKeys(pc) {
        Config.options.bar.resources.showValue = !pc;
        Config.options.bar.utilButtons.showWallpaperToggle = pc;
        Config.options.bar.layouts.leftLayout = pc ? BarLayouts.end4pcLeft : BarLayouts.classicLeft;
        Config.options.bar.layouts.middleLayout = pc ? BarLayouts.end4pcMiddle : BarLayouts.classicMiddle;
        Config.options.bar.layouts.rightLayout = pc ? BarLayouts.end4pcRight : BarLayouts.classicRight;
        Config.options.sidebar.banner = pc;
        Config.options.sidebar.sectionOrder = pc ? ["banner", "quickToggles", "sliders", "media", "notifications", "bottom"] : ["banner", "sliders", "quickToggles", "media", "notifications", "bottom"];
    }

    function applyPreset(style) {
        const pc = style === "end4pc";
        Config.options.bar.utilButtons.showColorPicker = pc;
        Config.options.bar.utilButtons.showDarkModeToggle = !pc;
        Config.options.bar.utilButtons.showKeyboardToggle = !pc;
        Config.options.bar.workspaces.alwaysShowNumbers = pc;
        Config.options.bar.workspaces.showAppIcons = !pc;
        Config.options.bar.resources.alwaysShowSwap = !pc;
        Config.options.sidebar.quickSliders.enable = pc;
        Config.options.appearance.settingsLayout = style;
        root.applyNewKeys(pc);
        Config.options.appearance.visualStylePresetVersion = root.presetVersion;
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

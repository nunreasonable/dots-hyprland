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
            root.applyNewKeys(pc, style);
        Config.options.appearance.visualStylePresetVersion = root.presetVersion;
    }

    function defaultLayout(style) {
        const pc = style === "end4pc";
        return {
            left: pc ? BarLayouts.end4pcLeft : BarLayouts.classicLeft,
            middle: pc ? BarLayouts.end4pcMiddle : BarLayouts.classicMiddle,
            right: pc ? BarLayouts.end4pcRight : BarLayouts.classicRight
        };
    }

    function isDefaultLayout(style) {
        const layouts = Config.options.bar.layouts;
        const defaults = root.defaultLayout(style);
        return BarLayouts.sameList(layouts.leftLayout, defaults.left)
            && BarLayouts.sameList(layouts.middleLayout, defaults.middle)
            && BarLayouts.sameList(layouts.rightLayout, defaults.right);
    }

    function switchLayout(from, to) {
        const layouts = Config.options.bar.layouts;
        const kept = layouts.kept;
        const custom = !root.styles.some(style => root.isDefaultLayout(style));
        if (custom && !root.styles.includes(from))
            return;
        if (custom && from !== to) {
            kept[from + "Left"] = [...layouts.leftLayout];
            kept[from + "Middle"] = [...layouts.middleLayout];
            kept[from + "Right"] = [...layouts.rightLayout];
        }
        const restore = kept[to + "Left"].length + kept[to + "Middle"].length + kept[to + "Right"].length > 0;
        const next = restore ? {
            left: [...kept[to + "Left"]],
            middle: [...kept[to + "Middle"]],
            right: [...kept[to + "Right"]]
        } : root.defaultLayout(to);
        if (custom && from === to && !restore)
            return;
        layouts.leftLayout = next.left;
        layouts.middleLayout = next.middle;
        layouts.rightLayout = next.right;
        kept[to + "Left"] = [];
        kept[to + "Middle"] = [];
        kept[to + "Right"] = [];
    }

    function applyNewKeys(pc, from) {
        Config.options.bar.resources.showValue = !pc;
        Config.options.bar.utilButtons.showWallpaperToggle = pc;
        root.switchLayout(from, pc ? "end4pc" : "ii");
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
        root.applyNewKeys(pc, root.applied);
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

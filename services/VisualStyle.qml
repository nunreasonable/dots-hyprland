pragma Singleton
import qs.modules.common
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var entries: StyleTheme.all.filter(entry => entry.selectable)
    readonly property list<string> styles: root.entries.map(entry => entry.key)
    readonly property list<string> layoutStyles: ["ii", "end4pc"]
    readonly property var options: root.entries.map(entry => ({
                displayName: entry.displayName,
                icon: entry.icon,
                value: entry.key
            }))
    readonly property string hints: root.entries.filter(entry => entry.hint !== "").map(entry => " " + entry.hint).join("")
    readonly property string selected: Config.options.appearance.visualStyle
    readonly property string applied: Config.options.appearance.visualStyleApplied

    function load() {
        syncTimer.restart();
    }

    readonly property int presetVersion: 2

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
        const pc = root.entry(style).layout === "end4pc";
        const version = Config.options.appearance.visualStylePresetVersion ?? 0;
        if (pc && version < 1)
            root.applyNewKeys(pc, style);
        if (version < 2)
            root.addBattery();
        Config.options.appearance.visualStylePresetVersion = root.presetVersion;
    }

    function addBattery() {
        const layouts = Config.options.bar.layouts;
        const right = BarLayouts.end4pcRight.filter(name => name !== "batteryIndicator");
        if (BarLayouts.sameList(layouts.leftLayout, BarLayouts.end4pcLeft) && BarLayouts.sameList(layouts.middleLayout, BarLayouts.end4pcMiddle) && BarLayouts.sameList(layouts.rightLayout, right))
            layouts.rightLayout = BarLayouts.end4pcRight;
    }

    function entry(style) {
        return StyleTheme.entry(style) ?? StyleTheme.all[0];
    }

    function reportName(style) {
        return StyleTheme.entry(style)?.reportName ?? "";
    }

    function layoutStyle(style) {
        return StyleTheme.entry(style)?.layout ?? style;
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
        const custom = !root.layoutStyles.some(style => root.isDefaultLayout(style));
        if (custom && !root.layoutStyles.includes(from))
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
        root.switchLayout(root.layoutStyle(from), pc ? "end4pc" : "ii");
        Config.options.sidebar.banner = pc;
        Config.options.sidebar.sectionOrder = pc ? ["banner", "quickToggles", "sliders", "media", "notifications", "bottom"] : ["banner", "sliders", "quickToggles", "media", "notifications", "bottom"];
    }

    function applyIsland(naby) {
        const was = root.entry(root.applied).island;
        Config.options.nabyIsland.enable = naby;
        if (!Platform.isWindows || naby === was)
            return;
        if (naby) {
            Config.options.nabyIsland.keptNativeTaskbar = Config.options.windowsPort.nativeTaskbar;
            Config.options.windowsPort.nativeTaskbar = true;
        } else {
            Config.options.windowsPort.nativeTaskbar = Config.options.nabyIsland.keptNativeTaskbar;
        }
    }

    readonly property var managedKeys: ["bar.utilButtons.showColorPicker", "bar.utilButtons.showDarkModeToggle", "bar.utilButtons.showKeyboardToggle", "bar.utilButtons.showWallpaperToggle", "bar.workspaces.alwaysShowNumbers", "bar.workspaces.showAppIcons", "bar.resources.alwaysShowSwap", "bar.resources.showValue", "sidebar.quickSliders.enable", "sidebar.banner", "sidebar.sectionOrder"]

    function rememberedKeys() {
        const keys = [...root.managedKeys];
        for (const entry of StyleTheme.all) {
            for (const key in entry.preset) {
                if (!keys.includes(key))
                    keys.push(key);
            }
        }
        return keys;
    }

    function readKept() {
        try {
            return JSON.parse(Config.options.appearance.visualStyleKept || "{}") ?? {};
        } catch (e) {
            return {};
        }
    }

    function nestedValue(key) {
        let value = Config.options;
        for (const part of key.split("."))
            value = value?.[part];
        return value !== null && typeof value === "object" && value.length !== undefined ? Array.from(value) : value;
    }

    function rememberChoices(style) {
        const kept = root.readKept();
        const values = {};
        for (const key of root.rememberedKeys()) {
            const value = root.nestedValue(key);
            if (value !== undefined)
                values[key] = value;
        }
        kept[style] = values;
        Config.options.appearance.visualStyleKept = JSON.stringify(kept);
    }

    function restoreChoices(style) {
        const values = root.readKept()[style];
        if (!values)
            return;
        for (const key in values)
            Config.setNestedValue(key, values[key]);
    }

    function applyTweaks(entry) {
        for (const other of StyleTheme.all) {
            for (const key in other.preset) {
                if (!(key in entry.preset))
                    Config.setNestedValue(key, other.preset[key][1]);
            }
        }
        for (const key in entry.preset)
            Config.setNestedValue(key, entry.preset[key][0]);
    }

    function applyPreset(style) {
        root.rememberChoices(root.applied);
        const entry = root.entry(style);
        const pc = entry.layout === "end4pc";
        Config.options.bar.utilButtons.showColorPicker = pc;
        Config.options.bar.utilButtons.showDarkModeToggle = !pc;
        Config.options.bar.utilButtons.showKeyboardToggle = !pc;
        Config.options.bar.workspaces.alwaysShowNumbers = pc;
        Config.options.bar.workspaces.showAppIcons = !pc;
        Config.options.bar.resources.alwaysShowSwap = !pc;
        Config.options.sidebar.quickSliders.enable = pc;
        Config.options.appearance.settingsLayout = entry.settingsLayout;
        root.applyIsland(entry.island);
        root.applyNewKeys(pc, root.applied);
        root.applyTweaks(entry);
        root.restoreChoices(style);
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

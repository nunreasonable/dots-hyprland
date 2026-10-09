pragma Singleton
import qs
import qs.modules.common
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var classicLeft: ["leftSidebarButton", "activeWindow"]
    readonly property var classicMiddle: ["resources", "media", "workspaces", "clockWidget", "utilButtons", "batteryIndicator"]
    readonly property var classicRight: ["sysTray", "systemIcons"]
    readonly property var end4pcLeft: ["launcherButton", "workspaces", "activeWindow"]
    readonly property var end4pcMiddle: ["clockWidget"]
    readonly property var end4pcRight: ["sysTray", "utilButtons", "systemIcons", "powerButton"]

    readonly property var multipleAllowed: ["visualizer", "divisor"]
    readonly property var middleOnly: ["dynamicIsland"]

    readonly property var widgets: [
        { id: "leftSidebarButton", name: Translation.tr("Left Sidebar Button"), icon: "left_panel_open", file: "LeftSidebarButton.qml" },
        { id: "launcherButton", name: Translation.tr("Launcher Button"), icon: "search", file: "LauncherButton.qml" },
        { id: "workspaces", name: Translation.tr("Workspaces"), icon: "steppers", file: "Workspaces.qml" },
        { id: "activeWindow", name: Translation.tr("Active Window"), icon: "subtitles", file: "ActiveWindow.qml" },
        { id: "media", name: Translation.tr("Media"), icon: "music_note", file: "Media.qml" },
        { id: "visualizer", name: Translation.tr("Visualizer"), icon: "graphic_eq", file: "Visualizer.qml" },
        { id: "resources", name: Translation.tr("Resources"), icon: "empty_dashboard", file: "Resources.qml" },
        { id: "clockWidget", name: Translation.tr("Clock and date"), icon: "schedule", file: "ClockWidget.qml" },
        { id: "utilButtons", name: Translation.tr("Util Buttons"), icon: "toggle_on", file: "UtilButtons.qml" },
        { id: "sysTray", name: Translation.tr("Tray"), icon: "inbox", file: "SysTray.qml" },
        { id: "systemIcons", name: Translation.tr("System Icons"), icon: "info", file: "SystemIcons.qml" },
        { id: "batteryIndicator", name: Translation.tr("Battery"), icon: "battery_android_frame_full", file: "BatteryIndicator.qml" },
        { id: "bluetooth", name: Translation.tr("Bluetooth"), icon: "bluetooth", file: "Bluetooth.qml" },
        { id: "networkSpeed", name: Translation.tr("Network Speed"), icon: "network_check", file: "NetworkSpeed.qml", linuxOnly: true },
        { id: "weatherBar", name: Translation.tr("Weather"), icon: "flare", file: "weather/WeatherBar.qml" },
        { id: "hyprlandXkbIndicator", name: Translation.tr("Keyboard Layout"), icon: "keyboard", file: "HyprlandXkbIndicator.qml" },
        { id: "powerButton", name: Translation.tr("Power Button"), icon: "power_settings_new", file: "PowerButton.qml" },
        { id: "divisor", name: Translation.tr("Divider"), icon: "horizontal_distribute", file: "Divisor.qml" },
        { id: "dynamicIsland", name: Translation.tr("Dynamic Island"), icon: "nest_wifi_pro", file: "DynamicIsland.qml" },
        { id: "aiUsage", name: Translation.tr("AI Usage"), icon: "neurology", file: "AiUsage.qml" }
    ]

    readonly property var supportedWidgets: root.widgets.filter(widget => !(widget.linuxOnly && Platform.isWindows))
    readonly property var supportedIds: root.supportedWidgets.map(widget => widget.id)

    readonly property var leftLayout: root.filter(Config.options.bar.layouts.leftLayout)
    readonly property var middleLayout: root.filter(Config.options.bar.layouts.middleLayout)
    readonly property var rightLayout: root.filter(Config.options.bar.layouts.rightLayout)

    readonly property bool classic: root.sameList(Config.options.bar.layouts.leftLayout, root.classicLeft)
        && root.sameList(Config.options.bar.layouts.middleLayout, root.classicMiddle)
        && root.sameList(Config.options.bar.layouts.rightLayout, root.classicRight)

    readonly property bool centerOnly: !root.classic && root.leftLayout.length === 0 && root.rightLayout.length === 0
    readonly property string barEdge: Config.options.bar.vertical ? (Config.options.bar.bottom ? "right" : "left") : (Config.options.bar.bottom ? "bottom" : "top")
    readonly property real windowsFrameInset: (Platform.isWindows && root.frameVisibleFor(root.barEdge)) ? Config.options.bar.frameThickness : 0

    readonly property real barZone: {
        if (root.centerOnly && Config.options.bar.showFrame && Config.options.bar.centerOnlyReserveFrame)
            return Config.options.bar.frameThickness;
        const thickness = Config.options.bar.vertical ? Appearance.sizes.baseVerticalBarWidth : Appearance.sizes.baseBarHeight;
        const base = Config.options.bar.autoHide.enable ? 0 : thickness + (Config.options.bar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0);
        return base + root.windowsFrameInset;
    }

    function barOnScreen(screenName) {
        if (!GlobalStates.barOpen || GlobalStates.screenLocked)
            return false;
        if (Platform.isWindows && Config.options.windowsPort.nativeTaskbar)
            return false;
        const list = Config.options.bar.screenList;
        return !list || list.length === 0 || list.includes(screenName);
    }

    function frameVisibleFor(side) {
        if (!Config.options.bar.showFrame)
            return false;
        if (Config.options.bar.cornerStyle === 0 && side === root.barEdge)
            return root.centerOnly || !Config.options.bar.showBackground;
        return true;
    }

    readonly property var usedIds: {
        const used = [...root.leftLayout, ...root.middleLayout, ...root.rightLayout];
        if (used.includes("dynamicIsland"))
            used.push(Config.options.bar.dynamicIsland.leftWidget, Config.options.bar.dynamicIsland.rightWidget);
        return used;
    }

    function sameList(a, b) {
        if (!a || a.length !== b.length)
            return false;
        for (let i = 0; i < b.length; i++) {
            if (a[i] !== b[i])
                return false;
        }
        return true;
    }

    function filter(layout) {
        const result = [];
        for (let i = 0; i < (layout?.length ?? 0); i++) {
            if (root.supportedIds.includes(layout[i]))
                result.push(layout[i]);
        }
        return result;
    }

    function find(id) {
        return root.widgets.find(widget => widget.id === id) ?? null;
    }

    function file(id) {
        return root.find(id)?.file ?? "";
    }

    function name(id) {
        return root.find(id)?.name ?? id;
    }

    function isUsed(id) {
        return root.usedIds.includes(id);
    }

    function availableFor(section) {
        const layouts = Config.options.bar.layouts;
        const used = [...layouts.leftLayout, ...layouts.middleLayout, ...layouts.rightLayout];
        if (section === "middle" && root.middleLayout.includes("dynamicIsland"))
            return [];
        return root.supportedWidgets.filter(widget => {
            if (root.middleOnly.includes(widget.id) && (section !== "middle" || Config.options.bar.vertical || root.middleLayout.length > 0))
                return false;
            return !used.includes(widget.id) || root.multipleAllowed.includes(widget.id);
        });
    }
}

import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions

QtObject {
    id: root

    function roleColor(name) {
        if (name === "black")
            return "black";
        return Appearance.colors["col" + name.charAt(0).toUpperCase() + name.slice(1)] ?? Appearance.getColorFromName(name);
    }

    function access(path) {
        const keys = path.split(".");
        const last = keys.pop();
        const parent = () => keys.reduce((node, key) => node[key], Config.options);
        return {
            get: () => parent()[last],
            set: value => {
                parent()[last] = value;
            }
        };
    }

    function controlFor(e) {
        if (!e || !e.key)
            return null;
        const own = root.custom[e.key];
        if (own)
            return e.type === "action" && own.label === undefined && e.label !== undefined ? Object.assign({ label: e.label }, own) : own;
        if (e.key.indexOf(":") >= 0)
            return null;
        const a = root.access(e.key);
        const factor = e.factor ?? 1;
        switch (e.type) {
        case "toggle":
            return { type: "switch", get: () => Boolean(a.get()), set: a.set };
        case "spin":
            return { type: "spin", get: () => Math.round(Number(a.get()) * factor), set: v => a.set(v / factor), from: e.from ?? 0, to: e.to ?? 100, stepSize: e.step ?? 1 };
        case "slider":
            return { type: "slider", get: () => Number(a.get()) * factor, set: v => a.set(v / factor), from: e.from ?? 0, to: e.to ?? 1, stopIndicatorValues: e.stops ?? [], usePercentTooltip: e.percent !== false };
        case "text":
            return { type: "text", get: a.get, set: a.set, list: e.list === true };
        case "duration":
            return { type: "duration", get: a.get, set: a.set };
        default:
            return {
                type: "select",
                get: a.get,
                set: a.set,
                get options() {
                    return e.colors ? e.colors.map(name => ({ value: name, color: root.roleColor(name) })) : (e.options ?? []);
                }
            };
        }
    }

    readonly property var heroes: [
        { id: "hero:visualstyle", type: "visualstyle", title: Translation.tr("Visual style"), section: Translation.tr("Interface"), kw: "visual style look theme illogical-impulse ii end4-pc nabyscape sekaipop" },
        { id: "hero:style", type: "style", title: Translation.tr("Settings panel style"), section: Translation.tr("Interface"), kw: "settings panel style default minimal dashboard window overlay" },
        { id: "hero:blur", type: "toggle", key: "background.showBlur", title: Translation.tr("Blur wallpaper"), icon: "blur_on", section: Translation.tr("Desktop") },
        { id: "hero:transparency", type: "toggle", key: "appearance.transparency.enable", title: Translation.tr("Transparency"), icon: "opacity", section: Translation.tr("Interface") },
        { id: "hero:tiling", type: "toggle", os: "windows", key: "windowsPort.tiling.enable", title: Translation.tr("Tiling"), icon: "dashboard", section: Translation.tr("System") },
        { id: "hero:collage", type: "toggle", key: "custom:collageEnable", title: Translation.tr("Multiple wallpapers"), icon: "grid_view", section: Translation.tr("Desktop") },
        { id: "hero:schemes", type: "schemes", os: "windows", title: Translation.tr("Color scheme"), section: Translation.tr("Interface"), kw: "named color scheme palette primary secondary accent catppuccin gruvbox nord dracula tokyo everforest" },
        { id: "hero:barpos", type: "barpos", title: Translation.tr("Bar position"), section: Translation.tr("Bar"), kw: "bar position top bottom left right vertical" },
        { id: "hero:centered", type: "toggle", key: "background.centeredWallpaper", title: Translation.tr("Centered wallpaper"), icon: "filter_center_focus", section: Translation.tr("Desktop") },
        { id: "hero:uibg", type: "select", w: 2, key: "appearance.uiBackground", title: Translation.tr("UI background"), icon: "format_color_fill", section: Translation.tr("Interface"), kw: "ui background oled black amoled themed dark surface layer panels sidebars", options: [{ displayName: Translation.tr("Themed"), icon: "palette", value: "themed" }, { displayName: Translation.tr("OLED"), icon: "contrast", value: "oled" }] },
        { id: "hero:palette", type: "palette", key: "custom:colorSchemeType", when: () => (Config.options.appearance.palette.namedScheme ?? "") === "", title: Translation.tr("Palette style"), icon: "auto_awesome", section: Translation.tr("Interface"), kw: "palette style scheme auto content expressive fidelity fruit salad monochrome neutral rainbow tonal spot material you dynamic" }
    ]

    readonly property var custom: ({
        "custom:resetBarWidgetStyles": {
          type: "action",
          run: () => { Config.options.bar.widgetStyles = []; }
        },
        "custom:notifForceMonitorName": {
          type: "combo",
          get: () => Config.options.notifications.forceMonitor.name,
          set: v => { Config.options.notifications.forceMonitor.name = v; },
          get options() {
            const names = Quickshell.screens.map(screen => screen.name);
            const current = Config.options.notifications.forceMonitor.name;
            return names
              .concat(current.length > 0 && !names.includes(current) ? [current] : [])
              .map(name => ({ displayName: name, value: name }));
          }
        },
        "custom:barWorkspacesNumberStyle": {
          type: "select",
          get: () => JSON.stringify(Config.options.bar.workspaces.numberMap),
          set: v => { Config.options.bar.workspaces.numberMap = JSON.parse(v); },
          options: [
            { displayName: Translation.tr("Normal"), icon: "timer_10", value: '[]' },
            { displayName: Translation.tr("Han chars"), icon: "square_dot", value: '["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]' },
            { displayName: Translation.tr("Roman"), icon: "account_balance", value: '["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"]' }
          ]
        },
        "custom:nowPlayingSecondsOnScreen": {
          type: "spin",
          get: () => Math.round(Config.options.media.nowPlaying.duration / 1000),
          set: v => { Config.options.media.nowPlaying.duration = v * 1000; },
          from: 1, to: 10, stepSize: 1
        },
        "custom:nowPlayingMove": {
          type: "action",
          run: () => {
            if (Platform.isWindows)
              GlobalStates.nowPlayingPositionRequested();
            else
              Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("shell.qml"), "ipc", "call", "nowPlaying", "position"]);
          }
        },
        "custom:nowPlayingResetPosition": {
          type: "action",
          run: () => {
            Persistent.states.nowPlaying.x = -1;
            Persistent.states.nowPlaying.y = -1;
            Persistent.states.nowPlaying.screen = "";
          }
        },
        "custom:wallpaperLightDarkMode": {
          type: "select",
          get: () => Appearance.m3colors.darkmode,
          set: v => { Wallpapers.setMode(v); },
          options: [
            { displayName: Translation.tr("Light"), icon: "light_mode", value: false },
            { displayName: Translation.tr("Dark"), icon: "dark_mode", value: true }
          ]
        },
        "custom:colorSchemeType": {
          type: "select",
          get: () => Config.options.appearance.palette.type,
          set: v => { Config.options.appearance.palette.type = v; Wallpapers.reapplyPalette(); },
          options: [
            { displayName: Translation.tr("Auto"), icon: "auto_awesome", value: "auto" },
            { displayName: Translation.tr("Content"), icon: "image", value: "scheme-content" },
            { displayName: Translation.tr("Expressive"), icon: "palette", value: "scheme-expressive" },
            { displayName: Translation.tr("Fidelity"), icon: "equal", value: "scheme-fidelity" },
            { displayName: Translation.tr("Fruit Salad"), icon: "nutrition", value: "scheme-fruit-salad" },
            { displayName: Translation.tr("Monochrome"), icon: "invert_colors", value: "scheme-monochrome" },
            { displayName: Translation.tr("Neutral"), icon: "tonality", value: "scheme-neutral" },
            { displayName: Translation.tr("Rainbow"), icon: "gradient", value: "scheme-rainbow" },
            { displayName: Translation.tr("Tonal Spot"), icon: "lens", value: "scheme-tonal-spot" }
          ]
        },
        "custom:openWallpaperPicker": {
          type: "action",
          run: () => { Wallpapers.openPicker(); }
        },
        "custom:randomWallpaperKonachan": {
          type: "action",
          run: () => { RandomWallpaper.fetch("konachan"); }
        },
        "custom:randomWallpaperOsu": {
          type: "action",
          run: () => { RandomWallpaper.fetch("osu"); }
        },
        "custom:accentColorOverride": {
          type: "text",
          get: () => Config.options.appearance.palette.accentColor,
          set: v => {
            const value = v.trim();
            if (value === Config.options.appearance.palette.accentColor) return;
            if (value === "") Wallpapers.setAccentColor("clear");
            else if (/^#?[0-9a-fA-F]{6}$/.test(value)) Wallpapers.setAccentColor(value);
          }
        },
        "custom:timeFormat": {
          type: "select",
          get: () => Config.options.time.format,
          set: v => {
            if (!Platform.isWindows && v === "hh:mm") {
              Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME12\\b/TIME/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
            } else if (!Platform.isWindows) {
              Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME\\b/TIME12/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
            }
            Config.options.time.format = v;
          },
          options: [
            { displayName: Translation.tr("24h"), value: "hh:mm" },
            { displayName: Translation.tr("12h am/pm"), value: "h:mm ap" },
            { displayName: Translation.tr("12h AM/PM"), value: "h:mm AP" }
          ]
        },
        "custom:pomodoroFocusMinutes": {
          type: "spin",
          get: () => Math.round(Config.options.time.pomodoro.focus / 60),
          set: v => { Config.options.time.pomodoro.focus = v * 60; },
          from: 5, to: 120, stepSize: 5
        },
        "custom:pomodoroBreakMinutes": {
          type: "spin",
          get: () => Math.round(Config.options.time.pomodoro.breakTime / 60),
          set: v => { Config.options.time.pomodoro.breakTime = v * 60; },
          from: 1, to: 60, stepSize: 1
        },
        "custom:pomodoroLongBreakMinutes": {
          type: "spin",
          get: () => Math.round(Config.options.time.pomodoro.longBreak / 60),
          set: v => { Config.options.time.pomodoro.longBreak = v * 60; },
          from: 1, to: 60, stepSize: 1
        },
        "custom:interfaceLanguage": {
          type: "combo",
          get: () => Config.options.language.ui,
          set: v => { Config.options.language.ui = v; },
          get options() {
            return [{ displayName: Translation.tr("Auto (System)"), value: "auto" }]
              .concat(Translation.allAvailableLanguages.map(lang => ({ displayName: lang, value: lang })));
          }
        },
        "custom:showWelcomeScreenNow": {
          type: "action",
          run: () => { GlobalStates.welcomeScreenOpen = true; }
        },
        "custom:expandCollapsedSections": { type: "action", run: () => { Config.options.settings.collapsedSections = []; } },
        "custom:mediaArtShape": {
          type: "select",
          get: () => Config.options.sidebar.media.artShape,
          set: v => { Config.options.sidebar.media.artShape = v; },
          get options() { return GlobalStates.centeredShapeOptions.map(shape => ({ displayName: shape, value: shape })); }
        },
        "custom:hotCornerBottomLeft": {
          type: "select",
          get: () => Config.options.sidebar.cornerOpen.bottomLeftAction,
          set: v => { Config.options.sidebar.cornerOpen.bottomLeftAction = v; },
          get options() { return GlobalStates.hotCornerOptions; }
        },
        "custom:hotCornerBottomRight": {
          type: "select",
          get: () => Config.options.sidebar.cornerOpen.bottomRightAction,
          set: v => { Config.options.sidebar.cornerOpen.bottomRightAction = v; },
          get options() { return GlobalStates.hotCornerOptions; }
        },
        "custom:googleLensSelectionType": {
          type: "select",
          get: () => Config.options.search.imageSearch.useCircleSelection ? "circle" : "rectangles",
          set: v => { Config.options.search.imageSearch.useCircleSelection = (v === "circle"); },
          options: [
            { icon: "activity_zone", value: "rectangles", displayName: Translation.tr("Rectangular selection") },
            { icon: "gesture", value: "circle", displayName: Translation.tr("Circle to Search") }
          ]
        },
        "custom:fontMain": { type: "select", get: () => Config.options.appearance.fonts.main, set: v => { Config.options.appearance.fonts.main = v; }, get options() { return SettingsPages.fontOptions(Config.options.appearance.fonts.main); } },
        "custom:fontNumbers": { type: "select", get: () => Config.options.appearance.fonts.numbers, set: v => { Config.options.appearance.fonts.numbers = v; }, get options() { return SettingsPages.fontOptions(Config.options.appearance.fonts.numbers); } },
        "custom:fontTitle": { type: "select", get: () => Config.options.appearance.fonts.title, set: v => { Config.options.appearance.fonts.title = v; }, get options() { return SettingsPages.fontOptions(Config.options.appearance.fonts.title); } },
        "custom:fontMonospace": { type: "select", get: () => Config.options.appearance.fonts.monospace, set: v => { Config.options.appearance.fonts.monospace = v; }, get options() { return SettingsPages.fontOptions(Config.options.appearance.fonts.monospace); } },
        "custom:fontIconNerd": { type: "select", get: () => Config.options.appearance.fonts.iconNerd, set: v => { Config.options.appearance.fonts.iconNerd = v; }, get options() { return SettingsPages.fontOptions(Config.options.appearance.fonts.iconNerd); } },
        "custom:fontReading": { type: "select", get: () => Config.options.appearance.fonts.reading, set: v => { Config.options.appearance.fonts.reading = v; }, get options() { return SettingsPages.fontOptions(Config.options.appearance.fonts.reading); } },
        "custom:fontExpressive": { type: "select", get: () => Config.options.appearance.fonts.expressive, set: v => { Config.options.appearance.fonts.expressive = v; }, get options() { return SettingsPages.fontOptions(Config.options.appearance.fonts.expressive); } },
        "custom:wallhavenApiKey": {
          type: "text",
          secret: true,
          get: () => WallhavenSearch.apiKey,
          set: v => { WallhavenSearch.setApiKey(v); }
        },
        "custom:wallhavenDefaultSort": {
          type: "select",
          get: () => Config.options.wallpaperSelector.wallhavenSorting,
          set: v => { Config.options.wallpaperSelector.wallhavenSorting = v; WallhavenSearch.sorting = v; },
          options: [
            { displayName: Translation.tr("Relevance"), value: "relevance" },
            { displayName: Translation.tr("Date Added"), value: "date_added" },
            { displayName: Translation.tr("Top List"), value: "toplist" },
            { displayName: Translation.tr("Random"), value: "random" }
          ]
        },
        "custom:wallhavenOrder": {
          type: "select",
          get: () => Config.options.wallpaperSelector.wallhavenOrder,
          set: v => { Config.options.wallpaperSelector.wallhavenOrder = v; WallhavenSearch.order = v; },
          options: [
            { displayName: Translation.tr("Descending"), icon: "arrow_downward", value: "desc" },
            { displayName: Translation.tr("Ascending"), icon: "arrow_upward", value: "asc" }
          ]
        },
        "custom:wallhavenTopRange": {
          type: "select",
          get: () => Config.options.wallpaperSelector.wallhavenTopRange,
          set: v => { Config.options.wallpaperSelector.wallhavenTopRange = v; WallhavenSearch.topRange = v; },
          options: [
            { displayName: Translation.tr("1 Day"), icon: "today", value: "1d" },
            { displayName: Translation.tr("1 Week"), icon: "view_week", value: "1w" },
            { displayName: Translation.tr("1 Month"), icon: "calendar_month", value: "1m" },
            { displayName: Translation.tr("1 Year"), icon: "event_repeat", value: "1y" }
          ]
        },
        "custom:wallhavenCategoryGeneral": {
          type: "switch",
          get: () => Config.options.wallpaperSelector.wallhavenCategories.charAt(0) === "1",
          set: v => {
            const c = Config.options.wallpaperSelector.wallhavenCategories;
            Config.options.wallpaperSelector.wallhavenCategories = (v ? "1" : "0") + c.charAt(1) + c.charAt(2);
            WallhavenSearch.categories = Config.options.wallpaperSelector.wallhavenCategories;
          }
        },
        "custom:wallhavenCategoryAnime": {
          type: "switch",
          get: () => Config.options.wallpaperSelector.wallhavenCategories.charAt(1) === "1",
          set: v => {
            const c = Config.options.wallpaperSelector.wallhavenCategories;
            Config.options.wallpaperSelector.wallhavenCategories = c.charAt(0) + (v ? "1" : "0") + c.charAt(2);
            WallhavenSearch.categories = Config.options.wallpaperSelector.wallhavenCategories;
          }
        },
        "custom:wallhavenCategoryPeople": {
          type: "switch",
          get: () => Config.options.wallpaperSelector.wallhavenCategories.charAt(2) === "1",
          set: v => {
            const c = Config.options.wallpaperSelector.wallhavenCategories;
            Config.options.wallpaperSelector.wallhavenCategories = c.charAt(0) + c.charAt(1) + (v ? "1" : "0");
            WallhavenSearch.categories = Config.options.wallpaperSelector.wallhavenCategories;
          }
        },
        "custom:wallhavenPuritySfw": {
          type: "switch",
          get: () => Config.options.wallpaperSelector.wallhavenPurity.charAt(0) === "1",
          set: v => {
            const p = Config.options.wallpaperSelector.wallhavenPurity;
            Config.options.wallpaperSelector.wallhavenPurity = (v ? "1" : "0") + p.charAt(1) + p.charAt(2);
            WallhavenSearch.purity = Config.options.wallpaperSelector.wallhavenPurity;
          }
        },
        "custom:wallhavenPuritySketchy": {
          type: "switch",
          get: () => Config.options.wallpaperSelector.wallhavenPurity.charAt(1) === "1" && SpicyStuff.allowed,
          set: v => {
            if (!SpicyStuff.allowed) return;
            const p = Config.options.wallpaperSelector.wallhavenPurity;
            Config.options.wallpaperSelector.wallhavenPurity = p.charAt(0) + (v ? "1" : "0") + p.charAt(2);
            WallhavenSearch.purity = Config.options.wallpaperSelector.wallhavenPurity;
          }
        },
        "custom:wallhavenPuritySpicy": {
          type: "switch",
          get: () => Config.options.wallpaperSelector.wallhavenPurity.charAt(2) === "1" && SpicyStuff.allowed,
          set: v => {
            if (!SpicyStuff.allowed) return;
            const p = Config.options.wallpaperSelector.wallhavenPurity;
            Config.options.wallpaperSelector.wallhavenPurity = p.charAt(0) + p.charAt(1) + (v ? "1" : "0");
            WallhavenSearch.purity = Config.options.wallpaperSelector.wallhavenPurity;
          }
        },
        "custom:wallhavenAspectRatio": {
          type: "select",
          get: () => Config.options.wallpaperSelector.wallhavenRatios,
          set: v => { Config.options.wallpaperSelector.wallhavenRatios = v; WallhavenSearch.ratios = v; },
          options: [
            { displayName: Translation.tr("Any"), icon: "crop_free", value: "" },
            { displayName: "16x9", icon: "crop_16_9", value: "16x9" },
            { displayName: "21x9", icon: "panorama_wide_angle", value: "21x9" },
            { displayName: "9x16", icon: "crop_portrait", value: "9x16" },
            { displayName: "1x1", icon: "crop_square", value: "1x1" }
          ]
        },
        "custom:wallhavenColorFilter": {
          type: "text",
          get: () => Config.options.wallpaperSelector.wallhavenColors ?? "",
          set: v => { Config.options.wallpaperSelector.wallhavenColors = v; WallhavenSearch.colors = v; }
        },
        "custom:syncWallpaper": {
            type: "switch",
            get: () => Config.options.background.lockWall === "",
            set: v => {
                if (v)
                    Wallpapers.setLockWallpaper("");
                else
                    Wallpapers.openSelectorFor("lockWall");
            }
        },
        "custom:openLockScreenSettings": {
            type: "action",
            run: () => {
                WindowsNative.wallpaper?.openLockScreenPersonalizationSettings();
            }
        },
        "custom:collageEnable": {
            type: "switch",
            get: () => Config.options.background.collage.enable,
            set: v => {
                if (v && !Config.options.background.collage.enable)
                    Collage.reset();
                Config.options.background.collage.enable = v;
            }
        },
        "custom:collageReset": {
            type: "action",
            run: () => {
                Collage.reset();
            }
        },
        "custom:konachanSpicy": {
            type: "switch",
            get: () => Config.options.background.konachanSpicy && SpicyStuff.allowed,
            set: v => {
                if (SpicyStuff.allowed)
                    Config.options.background.konachanSpicy = v;
            }
        },
        "custom:confirmAge": {
            type: "action",
            run: () => {
                SpicyStuff.confirmAge();
            }
        },
        "custom:clockFontFamily": {
            type: "combo",
            get: () => Config.options.background.widgets.clock.digital.font.family,
            set: v => {
                Config.options.background.widgets.clock.digital.font.family = v;
            },
            get options() {
                return SettingsPages.fontOptions(Config.options.background.widgets.clock.digital.font.family);
            }
        },
        "custom:cookieDialStyle": {
            type: "select",
            get: () => Config.options.background.widgets.clock.cookie.dialNumberStyle,
            set: v => {
                Config.options.background.widgets.clock.cookie.dialNumberStyle = v;
                if (v !== "dots" && v !== "full") {
                    Config.options.background.widgets.clock.cookie.hourMarks = false;
                }
                if (v === "numbers") {
                    Config.options.background.widgets.clock.cookie.timeIndicators = false;
                }
            },
            options: [
                { displayName: "", icon: "block", value: "none" },
                { displayName: Translation.tr("Dots"), icon: "graph_6", value: "dots" },
                { displayName: Translation.tr("Full"), icon: "history_toggle_off", value: "full" },
                { displayName: Translation.tr("Numbers"), icon: "counter_1", value: "numbers" },
            ]
        },
        "custom:sysTilingLayout": {
            type: "select",
            get: () => ["master", "scrolling"].includes(Config.options.hyprland.general.layout) ? Config.options.hyprland.general.layout : "dwindle",
            set: v => { Config.options.hyprland.general.layout = v; },
            options: [
                { displayName: Translation.tr("Dwindle"), icon: "browse", value: "dwindle" },
                { displayName: Translation.tr("Master"), icon: "auto_awesome_mosaic", value: "master" },
                { displayName: Translation.tr("Scrolling"), icon: "view_carousel", value: "scrolling" }
            ]
        },
        "custom:sysScrollingWidthPresets": {
            type: "text",
            get: () => Config.options.windowsPort.tiling.scrolling.widthPresets.map(v => Math.round(v * 100)).join(", "),
            set: v => {
                const items = v.split(",").map(s => parseFloat(s)).filter(n => n >= 10 && n <= 100);
                const shown = Config.options.windowsPort.tiling.scrolling.widthPresets.map(n => Math.round(n * 100)).join(", ");
                if (items.map(n => Math.round(n)).join(", ") !== shown)
                    Config.options.windowsPort.tiling.scrolling.widthPresets = items.length > 0 ? items.map(n => n / 100) : [1 / 3, 0.5, 2 / 3, 1];
            }
        },
        "custom:sysWindowBorders": {
            type: "select",
            get: () => Config.options.hyprland.general.borderSize <= 0 ? "none" : (Config.options.hyprland.general.borderColor.enable ? "colors" : "system"),
            set: v => {
                Config.options.hyprland.general.borderSize = v === "none" ? 0 : Math.max(1, Config.options.hyprland.general.borderSize);
                Config.options.hyprland.general.borderColor.enable = v === "colors";
            },
            options: [
                { displayName: Translation.tr("System"), icon: "desktop_windows", value: "system" },
                { displayName: Translation.tr("Palette"), icon: "palette", value: "colors" },
                { displayName: Translation.tr("None"), icon: "block", value: "none" }
            ]
        },
        "custom:sysCursorWarpWorkspace": {
            type: "switch",
            get: () => Config.options.windowsPort.cursor.warpOnChangeWorkspace !== 0,
            set: v => { Config.options.windowsPort.cursor.warpOnChangeWorkspace = v ? 1 : 0; }
        },
        "custom:sysKeyboardRepeatDelay": {
            type: "select",
            get: () => WindowsNative.inputSettings?.keyboardRepeatDelay ?? 0,
            set: v => { if (WindowsNative.inputSettings) WindowsNative.inputSettings.keyboardRepeatDelay = v; },
            options: [
                { displayName: Translation.tr("Short"), icon: "bolt", value: 0 },
                { displayName: Translation.tr("Medium-short"), icon: "timer", value: 1 },
                { displayName: Translation.tr("Medium-long"), icon: "av_timer", value: 2 },
                { displayName: Translation.tr("Long"), icon: "hourglass_empty", value: 3 }
            ]
        },
        "custom:sysKeyboardRepeatRate": {
            type: "spin",
            get: () => WindowsNative.inputSettings?.keyboardRepeatRate ?? 0,
            set: v => { if (WindowsNative.inputSettings) WindowsNative.inputSettings.keyboardRepeatRate = v; },
            from: 0, to: 31, stepSize: 1
        },
        "custom:sysNumlockDefault": {
            type: "switch",
            get: () => WindowsNative.inputSettings?.numLockOnAtSignIn ?? false,
            set: v => { if (WindowsNative.inputSettings) WindowsNative.inputSettings.numLockOnAtSignIn = v; }
        },
        "custom:sysKeyboardLayout": {
            type: "combo",
            get: () => WindowsNative.keyboard?.currentLayoutCode ?? "",
            set: v => { if (WindowsNative.keyboard) WindowsNative.keyboard.activateLayout(v); },
            get options() { return (WindowsNative.keyboard?.layoutCodes ?? []).map(code => ({ displayName: code, value: code })); }
        },
        "custom:sysPointerSpeed": {
            type: "spin",
            get: () => WindowsNative.inputSettings?.pointerSpeed ?? 10,
            set: v => { if (WindowsNative.inputSettings) WindowsNative.inputSettings.pointerSpeed = v; },
            from: 1, to: 20, stepSize: 1
        },
        "custom:sysEnhancePointerPrecision": {
            type: "switch",
            get: () => WindowsNative.inputSettings?.enhancePointerPrecision ?? false,
            set: v => { if (WindowsNative.inputSettings) WindowsNative.inputSettings.enhancePointerPrecision = v; }
        },
        "custom:sysSwapMouseButtons": {
            type: "switch",
            get: () => WindowsNative.inputSettings?.leftHanded ?? false,
            set: v => { if (WindowsNative.inputSettings) WindowsNative.inputSettings.leftHanded = v; }
        },
        "custom:sysHidePointerTyping": {
            type: "switch",
            get: () => WindowsNative.inputSettings?.hidePointerWhileTyping ?? false,
            set: v => { if (WindowsNative.inputSettings) WindowsNative.inputSettings.hidePointerWhileTyping = v; }
        },
        "custom:sysWheelScrollLines": {
            type: "spin",
            get: () => WindowsNative.inputSettings?.wheelScrollLines ?? 3,
            set: v => { if (WindowsNative.inputSettings) WindowsNative.inputSettings.wheelScrollLines = v; },
            from: 1, to: 100, stepSize: 1
        },
        "custom:sysFocusFollowsMouse": {
            type: "switch",
            get: () => WindowsNative.inputSettings?.focusFollowsMouse ?? false,
            set: v => { if (WindowsNative.inputSettings) WindowsNative.inputSettings.focusFollowsMouse = v; }
        },
        "custom:sysRaiseOnFocus": {
            type: "switch",
            get: () => WindowsNative.inputSettings?.raiseOnFocus ?? false,
            set: v => { if (WindowsNative.inputSettings) WindowsNative.inputSettings.raiseOnFocus = v; }
        },
        "custom:sysFocusDelayMs": {
            type: "spin",
            get: () => WindowsNative.inputSettings?.focusFollowsMouseDelayMs ?? 0,
            set: v => { if (WindowsNative.inputSettings) WindowsNative.inputSettings.focusFollowsMouseDelayMs = v; },
            from: 0, to: 5000, stepSize: 50
        },
        "custom:sysTouchpadEnabled": {
            type: "switch",
            get: () => WindowsNative.inputSettings?.touchpadEnabled ?? true,
            set: v => { if (WindowsNative.inputSettings) WindowsNative.inputSettings.touchpadEnabled = v; }
        },
        "custom:sysTouchpadTapToClick": {
            type: "switch",
            get: () => WindowsNative.inputSettings?.touchpadTapToClick ?? true,
            set: v => { if (WindowsNative.inputSettings) WindowsNative.inputSettings.touchpadTapToClick = v; }
        },
        "custom:sysTouchpadNaturalScroll": {
            type: "switch",
            get: () => WindowsNative.inputSettings?.touchpadNaturalScroll ?? false,
            set: v => { if (WindowsNative.inputSettings) WindowsNative.inputSettings.touchpadNaturalScroll = v; }
        },
        "custom:sysTouchpadSensitivity": {
            type: "select",
            get: () => WindowsNative.inputSettings?.touchpadSensitivity ?? 2,
            set: v => { if (WindowsNative.inputSettings) WindowsNative.inputSettings.touchpadSensitivity = v; },
            options: [
                { displayName: Translation.tr("Most sensitive"), icon: "touch_app", value: 0 },
                { displayName: Translation.tr("High sensitivity"), icon: "ads_click", value: 1 },
                { displayName: Translation.tr("Medium sensitivity"), icon: "mouse", value: 2 },
                { displayName: Translation.tr("Low sensitivity"), icon: "front_hand", value: 3 },
                { displayName: Translation.tr("Least sensitive"), icon: "pan_tool", value: 4 }
            ]
        },
        "custom:sysCursorScheme": {
            type: "combo",
            get: () => WindowsNative.inputSettings?.cursorSchemeName ?? "",
            set: v => { if (WindowsNative.inputSettings) WindowsNative.inputSettings.setCursorScheme(v); },
            get options() {
                return (WindowsNative.inputSettings?.cursorSchemeNames ?? []).map((name, i) => ({
                    displayName: WindowsNative.inputSettings?.cursorSchemeLabels[i] ?? name, value: name
                }));
            }
        },
        "custom:sysCursorSize": {
            type: "spin",
            get: () => WindowsNative.inputSettings?.cursorSize ?? 1,
            set: v => { if (WindowsNative.inputSettings) WindowsNative.inputSettings.cursorSize = v; },
            from: 1, to: 15, stepSize: 1
        },
        "custom:sysLockAfterInactivity": {
            type: "switch",
            get: () => Config.options.windowsPort.idle.lock > 0,
            set: v => {
                if (v && Config.options.windowsPort.idle.lock <= 0) Config.options.windowsPort.idle.lock = 300;
                else if (!v && Config.options.windowsPort.idle.lock > 0) Config.options.windowsPort.idle.lock = 0;
            }
        },
        "custom:sysLockAfterMinutes": {
            type: "spin",
            get: () => Math.max(1, Math.round(Config.options.windowsPort.idle.lock / 60)),
            set: v => {
                if (Config.options.windowsPort.idle.lock > 0 && v * 60 !== Config.options.windowsPort.idle.lock)
                    Config.options.windowsPort.idle.lock = v * 60;
            },
            from: 1, to: 999, stepSize: 1
        },
        "custom:sysScreenOffAcMinutes": {
            type: "spin",
            get: () => WindowsNative.idlePower?.screenOffAcMinutes ?? 0,
            set: v => { if (WindowsNative.idlePower) WindowsNative.idlePower.screenOffAcMinutes = v; },
            from: 0, to: 999, stepSize: 1
        },
        "custom:sysSleepAcMinutes": {
            type: "spin",
            get: () => WindowsNative.idlePower?.sleepAcMinutes ?? 0,
            set: v => { if (WindowsNative.idlePower) WindowsNative.idlePower.sleepAcMinutes = v; },
            from: 0, to: 999, stepSize: 1
        },
        "custom:sysScreenOffDcMinutes": {
            type: "spin",
            get: () => WindowsNative.idlePower?.screenOffDcMinutes ?? 0,
            set: v => { if (WindowsNative.idlePower) WindowsNative.idlePower.screenOffDcMinutes = v; },
            from: 0, to: 999, stepSize: 1
        },
        "custom:sysSleepDcMinutes": {
            type: "spin",
            get: () => WindowsNative.idlePower?.sleepDcMinutes ?? 0,
            set: v => { if (WindowsNative.idlePower) WindowsNative.idlePower.sleepDcMinutes = v; },
            from: 0, to: 999, stepSize: 1
        },
        "custom:sysAutostartSelfEnabled": {
            type: "switch",
            get: () => WindowsNative.autostart?.selfStartupEnabled ?? false,
            set: v => {
                const autostart = WindowsNative.autostart;
                if (!autostart || v === autostart.selfStartupEnabled) return;
                autostart.setSelfStartup(v, "task");
            }
        },
        "custom:sysAutostartSelfMethod": {
            type: "select",
            get: () => WindowsNative.autostart?.selfStartupMethod || "task",
            set: v => {
                const autostart = WindowsNative.autostart;
                if (autostart && v !== autostart.selfStartupMethod) autostart.setSelfStartup(true, v);
            },
            options: [
                { displayName: Translation.tr("Scheduled task (starts sooner)"), icon: "bolt", value: "task" },
                { displayName: Translation.tr("Startup registry entry"), icon: "list_alt", value: "run" }
            ]
        },
        "custom:sysMenuTooltipAnimations": {
            type: "switch",
            get: () => WindowsNative.inputSettings?.clientAreaAnimations ?? true,
            set: v => { if (WindowsNative.inputSettings) WindowsNative.inputSettings.clientAreaAnimations = v; }
        },
        "custom:sysMinimizeMaximizeAnimations": {
            type: "switch",
            get: () => WindowsNative.inputSettings?.minimizeRestoreAnimations ?? true,
            set: v => { if (WindowsNative.inputSettings) WindowsNative.inputSettings.minimizeRestoreAnimations = v; }
        },
        "custom:svcVllmEndpoint": {
            type: "text",
            get: () => Config.options.ai.vllmEndpoint,
            set: v => {
                if (v !== Config.options.ai.vllmEndpoint) {
                    Config.options.ai.vllmEndpoint = v;
                    Ai.refreshLocalModels();
                }
            }
        },
        "custom:svcMicPrivacyAction": {
            type: "action",
            run: () => { Qt.openUrlExternally("ms-settings:privacy-microphone"); }
        },
        "custom:profDescriptionMode": {
            type: "select",
            get: () => Config.options.profile.descriptionText === "::uptime::" ? "uptime" : "distro",
            set: v => { Config.options.profile.descriptionText = v === "uptime" ? "::uptime::" : "::distro::"; },
            options: [
                { displayName: Translation.tr("Distro"), icon: "deployed_code", value: "distro" },
                { displayName: Translation.tr("Uptime"), icon: "timelapse", value: "uptime" }
            ]
        },
        "custom:aboutDistroDocs": { type: "action", run: () => { Qt.openUrlExternally(SystemInfo.documentationUrl); } },
        "custom:aboutDistroSupport": { type: "action", run: () => { Qt.openUrlExternally(SystemInfo.supportUrl); } },
        "custom:aboutDistroBugReport": { type: "action", run: () => { Qt.openUrlExternally(SystemInfo.bugReportUrl); } },
        "custom:aboutDistroPrivacyPolicy": { type: "action", run: () => { Qt.openUrlExternally(SystemInfo.privacyPolicyUrl); } },
        "custom:aboutDotfilesDocs": { type: "action", run: () => { Qt.openUrlExternally("https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/02usage/"); } },
        "custom:aboutDotfilesIssues": { type: "action", run: () => { Qt.openUrlExternally("https://github.com/end-4/dots-hyprland/issues"); } },
        "custom:aboutDotfilesDiscussions": { type: "action", run: () => { Qt.openUrlExternally("https://github.com/end-4/dots-hyprland/discussions"); } },
        "custom:aboutDotfilesDonate": { type: "action", run: () => { Qt.openUrlExternally("https://github.com/sponsors/end-4"); } },
        "custom:aboutIiWindowsGithub": { type: "action", run: () => { Qt.openUrlExternally("https://github.com/nunreasonable/dots-hyprland/tree/ii-windows"); } },
        "custom:aboutQuickshellWindowsGithub": { type: "action", run: () => { Qt.openUrlExternally("https://github.com/nunreasonable/quickshell/tree/windows"); } },
        "custom:aboutGoBackStable": { type: "action", run: () => { SelfUpdate.goBackToStable(); } },
        "custom:aboutWhatsNew": { type: "action", run: () => { Qt.openUrlExternally(SelfUpdate.htmlUrl); } },
        "custom:aboutUpdateNow": { type: "action", run: () => { SelfUpdate.startUpdate(); } },
        "custom:aboutApplyFix": { type: "action", run: () => { SelfUpdate.applyPatch(); } },
        "custom:aboutCheckForUpdates": { type: "action", run: () => { SelfUpdate.refresh(); } },
        "custom:aboutIncludeCrashDump": {
            type: "switch",
            get: () => ProblemReport.includeCrashDump,
            set: v => { ProblemReport.includeCrashDump = v; }
        },
        "custom:aboutReportProblem": { type: "action", run: () => { ProblemReport.collect(); } }
    })

    readonly property var sections: [
        {
          page: Translation.tr("General"), title: Translation.tr("Appearance"), icon: "palette",
          cards: [
            { type: "toggle", key: "appearance.extraBackgroundTint", title: Translation.tr("Extra background tint"), icon: "format_color_fill",
              kw: "mixes touch of accent color into panel backgrounds instead of flat tone" },
            { type: "text", os: "windows", key: "custom:accentColorOverride", title: Translation.tr("Accent color (hex)"), icon: "colorize",
              placeholder: "#a7c0ff", kw: "hex color like #a7c0ff, leave empty to use color extracted from wallpaper" }
          ]
        },
        {
          page: Translation.tr("General"), title: Translation.tr("Time"), icon: "nest_clock_farsight_analog",
          cards: [
            { type: "timepreview", key: "general:Time preview", title: Translation.tr("Preview"), icon: "schedule",
              kw: "clock time preview android clock" },
            { type: "select", w: 4, key: "custom:timeFormat", title: Translation.tr("Time format"), icon: "schedule",
              kw: "clock 24h 12h am pm" },
            { type: "toggle", key: "time.secondPrecision", title: Translation.tr("Second precision"), icon: "pace",
              kw: "enable if you want clocks to show seconds accurately" },
            { type: "toggle", key: "time.showDate", title: Translation.tr("Show date"), icon: "date_range",
              kw: "shows date next to time in bar clock" },
            { type: "text", key: "time.shortDateFormat", title: Translation.tr("Short date"), icon: "today",
              placeholder: "dd/MM", kw: "qt date format tokens" },
            { type: "text", key: "time.dateWithYearFormat", title: Translation.tr("Date with year"), icon: "calendar_today",
              placeholder: "dd/MM/yyyy", kw: "qt date format tokens" },
            { type: "text", key: "time.dateFormat", title: Translation.tr("Long date"), icon: "calendar_month",
              placeholder: "ddd, dd/MM", kw: "qt date format tokens" },
            { type: "spin", key: "custom:pomodoroFocusMinutes", title: Translation.tr("Focus (min)"), icon: "timer",
              from: 5, to: 120, step: 5 },
            { type: "spin", key: "custom:pomodoroBreakMinutes", title: Translation.tr("Short break (min)"), icon: "free_breakfast",
              from: 1, to: 60, step: 1 },
            { type: "spin", key: "custom:pomodoroLongBreakMinutes", title: Translation.tr("Long break (min)"), icon: "self_improvement",
              from: 1, to: 60, step: 1 },
            { type: "spin", key: "time.pomodoro.cyclesBeforeLongBreak", title: Translation.tr("Cycles before long break"), icon: "repeat",
              from: 1, to: 10, step: 1 }
          ]
        },
        {
          page: Translation.tr("General"), title: Translation.tr("Battery"), icon: "battery_android_full",
          cards: [
            { type: "spin", key: "battery.low", title: Translation.tr("Low warning"), icon: "warning",
              from: 0, to: 100, step: 5 },
            { type: "spin", key: "battery.critical", title: Translation.tr("Critical warning"), icon: "dangerous",
              from: 0, to: 100, step: 5 },
            { type: "toggle", key: "battery.automaticSuspend", title: Translation.tr("Automatic suspend"), icon: "pause",
              kw: "automatically suspends system when battery is low" },
            { type: "spin", key: "battery.suspend", title: Translation.tr("at"), icon: "battery_saver",
              from: 0, to: 100, step: 5, kw: "automatic suspend threshold percent, enabled when automatic suspend is on" },
            { type: "spin", key: "battery.full", title: Translation.tr("Full warning"), icon: "charger",
              from: 0, to: 101, step: 5 },
            { type: "toggle", key: "battery.peripheralNotify", title: Translation.tr("Notify on low peripheral battery"), icon: "notifications",
              kw: "bluetooth peripheral battery, warns when paired device own battery is running low" },
            { type: "spin", key: "battery.peripheralLow", title: Translation.tr("Low warning"), icon: "warning",
              from: 0, to: 100, step: 5, kw: "bluetooth peripheral battery, enabled when notify on low peripheral battery is on" },
            { type: "spin", key: "battery.peripheralCritical", title: Translation.tr("Critical warning"), icon: "dangerous",
              from: 0, to: 100, step: 5, kw: "bluetooth peripheral battery, enabled when notify on low peripheral battery is on" }
          ]
        },
        {
          page: Translation.tr("General"), title: Translation.tr("Audio"), icon: "volume_up",
          cards: [
            { type: "toggle", key: "audio.protection.enable", title: Translation.tr("Earbang protection"), icon: "hearing",
              kw: "prevents abrupt increments and restricts volume limit" },
            { type: "spin", key: "audio.protection.maxAllowedIncrease", title: Translation.tr("Max allowed increase"), icon: "arrow_warm_up",
              from: 0, to: 100, step: 2, kw: "enabled when earbang protection is on" },
            { type: "spin", key: "audio.protection.maxAllowed", title: Translation.tr("Volume limit"), icon: "vertical_align_top",
              from: 0, to: 154, step: 2, kw: "enabled when earbang protection is on" }
          ]
        },
        {
          page: Translation.tr("General"), title: Translation.tr("Sounds"), icon: "notification_sound",
          cards: [
            { type: "toggle", key: "sounds.battery", title: Translation.tr("Battery sounds"), icon: "battery_android_full" },
            { type: "toggle", key: "sounds.pomodoro", title: Translation.tr("Pomodoro sounds"), icon: "av_timer" }
          ]
        },
        {
          page: Translation.tr("General"), title: Translation.tr("Language"), icon: "language",
          cards: [
            { type: "combo", key: "custom:interfaceLanguage", title: Translation.tr("Interface Language"), icon: "language",
              kw: "locale translate auto system",
              w: 2 },
            { type: "page", pageId: "general", section: "Language", subsection: "Generate translation with Gemini", label: "Locale code",
              title: Translation.tr("Generate translation with Gemini"), icon: "translate",
              kw: "gemini ai translate generate locale code key api not available on windows yet", w: 2 }
          ]
        },
        {
          page: Translation.tr("General"), title: Translation.tr("External apps"), icon: "apps", os: "linux",
          cards: [
            { type: "text", w: 2, key: "apps.bluetooth", title: Translation.tr("Bluetooth settings"), icon: "bluetooth" },
            { type: "text", w: 2, key: "apps.network", title: Translation.tr("Wi-Fi settings"), icon: "wifi" },
            { type: "text", w: 2, key: "apps.networkEthernet", title: Translation.tr("Ethernet settings"), icon: "settings_ethernet" },
            { type: "text", w: 2, key: "apps.manageUser", title: Translation.tr("Manage user accounts"), icon: "manage_accounts" },
            { type: "text", w: 2, key: "apps.taskManager", title: Translation.tr("Task manager"), icon: "browse_activity" },
            { type: "text", w: 2, key: "apps.terminal", title: Translation.tr("Terminal (for shell actions)"), icon: "terminal" },
            { type: "text", w: 2, key: "apps.update", title: Translation.tr("System update"), icon: "system_update_alt" },
            { type: "text", w: 2, key: "apps.volumeMixer", title: Translation.tr("Volume mixer"), icon: "volume_up" },
            { type: "text", w: 2, key: "apps.changePassword", title: Translation.tr("Change password"), icon: "password" }
          ]
        },
        {
          page: Translation.tr("General"), title: Translation.tr("Startup"), icon: "rocket_launch",
          cards: [
            { type: "toggle", key: "welcome.showAtLogin", title: Translation.tr("Show the welcome screen when ii starts"), icon: "waving_hand" },
            { type: "action", key: "custom:showWelcomeScreenNow", title: Translation.tr("Show it now"), icon: "waving_hand" }
          ]
        },
        {
          page: Translation.tr("General"), title: Translation.tr("Troubleshooting"), icon: "bug_report",
          cards: [
            { type: "spin", key: "hacks.arbitraryRaceConditionDelay", title: Translation.tr("Delay (ms)"), icon: "hourglass_bottom",
              from: 0, to: 500, step: 5,
              kw: "race condition delay, some ui code waits before refreshing to avoid timing race, higher values feel slower" }
          ]
        },
        {
          page: Translation.tr("General"), title: Translation.tr("Work safety"), icon: "work_alert",
          cards: [
            { type: "toggle", key: "workSafety.enable.clipboard", title: Translation.tr("Hide clipboard images"), icon: "assignment" },
            { type: "toggle", key: "workSafety.enable.wallpaper", title: Translation.tr("Hide sussy wallpapers"), icon: "wallpaper" }
          ]
        },
        {
            page: Translation.tr("General"), title: Translation.tr("About"), icon: "info",
            cards: [
                { type: "action", key: "custom:aboutDistroDocs", title: Translation.tr("Distro documentation"), icon: "auto_stories",
                  label: Translation.tr("Documentation") },
                { type: "action", key: "custom:aboutDistroSupport", title: Translation.tr("Distro help & support"), icon: "support",
                  label: Translation.tr("Help & Support") },
                { type: "action", key: "custom:aboutDistroBugReport", title: Translation.tr("Report a distro bug"), icon: "bug_report",
                  label: Translation.tr("Report a Bug") },
                { type: "action", key: "custom:aboutDistroPrivacyPolicy", title: Translation.tr("Distro privacy policy"), icon: "policy",
                  label: Translation.tr("Privacy Policy") },
                { type: "action", key: "custom:aboutDotfilesDocs", title: Translation.tr("Dotfiles documentation"), icon: "auto_stories",
                  label: Translation.tr("Documentation") },
                { type: "action", key: "custom:aboutDotfilesIssues", title: Translation.tr("Dotfiles issues"), icon: "adjust",
                  label: Translation.tr("Issues") },
                { type: "action", key: "custom:aboutDotfilesDiscussions", title: Translation.tr("Dotfiles discussions"), icon: "forum",
                  label: Translation.tr("Discussions") },
                { type: "action", key: "custom:aboutDotfilesDonate", title: Translation.tr("Donate"), icon: "favorite",
                  label: Translation.tr("Donate") },
                { type: "action", key: "custom:aboutIiWindowsGithub", title: Translation.tr("ii for Windows on GitHub"), icon: "desktop_windows", os: "windows",
                  label: "GitHub" },
                { type: "action", key: "custom:aboutQuickshellWindowsGithub", title: Translation.tr("Quickshell for Windows on GitHub"), icon: "deployed_code", os: "windows",
                  label: "GitHub" }
            ]
        },
        {
            page: Translation.tr("General"), title: Translation.tr("Updates & Reports"), icon: "deployed_code_update", os: "windows",
            cards: [
                { type: "action", key: "custom:aboutGoBackStable", title: Translation.tr("Go back to stable"), icon: "history",
                  when: () => SelfUpdate.canGoBackToStable, kw: "preview unstable rollback stable version" },
                { type: "action", key: "custom:aboutWhatsNew", title: Translation.tr("What's new"), icon: "open_in_new",
                  when: () => SelfUpdate.updateAvailable },
                { type: "action", key: "custom:aboutUpdateNow", title: Translation.tr("Update"), icon: "system_update",
                  when: () => SelfUpdate.updateAvailable },
                { type: "action", key: "custom:aboutApplyFix", title: Translation.tr("Apply fix"), icon: "build",
                  when: () => SelfUpdate.patchAvailable, kw: "patch fix restart shell" },
                { type: "action", key: "custom:aboutCheckForUpdates", title: Translation.tr("Check for updates"), icon: "refresh",
                  when: () => !SelfUpdate.updateAvailable },
                { type: "toggle", key: "windowsPort.selfUpdate.enableCheck", title: Translation.tr("Check for updates automatically"), icon: "cloud_sync" },
                { type: "toggle", key: "windowsPort.selfUpdate.notify", title: Translation.tr("Notify me when a new version is available"), icon: "notifications" },
                { type: "toggle", key: "custom:aboutIncludeCrashDump", title: Translation.tr("Include the latest crash dump"), icon: "memory",
                  kw: "problem report crash dump logs clipboard chats privacy" },
                { type: "action", key: "custom:aboutReportProblem", title: Translation.tr("Report a problem"), icon: "bug_report",
                  kw: "logs windows build gpu screens fonts documents zip github issue" }
            ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Theme"), icon: "palette",
          cards: [
            { type: "select", key: "custom:wallpaperLightDarkMode", title: Translation.tr("Light / Dark mode"), icon: "dark_mode",
              kw: "light dark mode preference buttons wallpaper colors card" }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Automatic theme"), icon: "brightness_auto",
          cards: [
            { type: "select", os: "windows", key: "appearance.autoTheme.mode", title: Translation.tr("Automatic theme"), icon: "brightness_auto",
              kw: "switches between light and dark on its own, using light/dark buttons switches this back to off",
              options: [
                { displayName: Translation.tr("Off"), icon: "close", value: "off" },
                { displayName: Translation.tr("Follow Windows"), icon: "desktop_windows", value: "followWindows" },
                { displayName: Translation.tr("Schedule"), icon: "schedule", value: "schedule" }
              ] },
            { type: "select", os: "linux", key: "appearance.autoTheme.mode", title: Translation.tr("Automatic theme"), icon: "brightness_auto",
              options: [
                { displayName: Translation.tr("Off"), icon: "close", value: "off" },
                { displayName: Translation.tr("Schedule"), icon: "schedule", value: "schedule" }
              ] },
            { type: "text", key: "appearance.autoTheme.scheduleLightTime", title: Translation.tr("Light at"), icon: "light_mode",
              placeholder: "07:00", when: () => Config.options.appearance.autoTheme.mode === "schedule",
              kw: "format HH:mm 24-hour time" },
            { type: "text", key: "appearance.autoTheme.scheduleDarkTime", title: Translation.tr("Dark at"), icon: "dark_mode",
              placeholder: "19:00", when: () => Config.options.appearance.autoTheme.mode === "schedule",
              kw: "format HH:mm 24-hour time" }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Style"), icon: "style",
          cards: [
            { type: "combo", key: "appearance.sekaipop.theme", title: Translation.tr("SekaiPop theme"), icon: "colors",
              when: () => Config.options.appearance.visualStyle === "sekaipop",
              options: [
                { displayName: Translation.tr("Mint"), icon: "circle", value: "mint" },
                { displayName: Translation.tr("Indigo"), icon: "circle", value: "indigo" },
                { displayName: Translation.tr("Lime"), icon: "circle", value: "lime" },
                { displayName: Translation.tr("Rose"), icon: "circle", value: "rose" },
                { displayName: Translation.tr("Amber"), icon: "circle", value: "amber" },
                { displayName: Translation.tr("Violet"), icon: "circle", value: "violet" },
                { displayName: Translation.tr("Monochrome"), icon: "contrast", value: "mono" },
                { displayName: Translation.tr("Wallpaper"), icon: "wallpaper", value: "wallpaper" }
              ] },
            { type: "select", key: "appearance.settingsLayout", title: Translation.tr("Settings layout"), icon: "settings",
              options: [
                { displayName: "illogical-impulse", icon: "view_sidebar", value: "ii" },
                { displayName: "end4-pC", icon: "web_asset", value: "end4pc" }
              ] }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Panel style"), icon: "view_quilt", cards: [
            { type: "select", key: "panelFamily", title: Translation.tr("Panel style"), icon: "view_quilt", options: [
                { displayName: Translation.tr("illogical-impulse"), icon: "view_quilt", value: "ii" },
                { displayName: Translation.tr("Waffle"), icon: "widgets", value: "waffle" }
              ] }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Transparency"), icon: "opacity", cards: [
            { type: "toggle", key: "appearance.transparency.enable", title: Translation.tr("Enable"), icon: "check" },
            { type: "toggle", key: "appearance.transparency.automatic", title: Translation.tr("Auto transparency"), icon: "auto_awesome" },
            { type: "slider", key: "appearance.transparency.backgroundTransparency", title: Translation.tr("Background"), icon: "opacity", from: 0, to: 1, stops: [0.11], percent: true, when: () => !Config.options.appearance.transparency.automatic },
            { type: "slider", key: "appearance.transparency.contentTransparency", title: Translation.tr("Panel content"), icon: "opacity", from: 0, to: 1, stops: [0.57], percent: true, when: () => !Config.options.appearance.transparency.automatic }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Settings panel"), icon: "settings", cards: [
            { type: "select", key: "settings.style", title: Translation.tr("Style"), icon: "style", options: [
                { displayName: Translation.tr("Default"), icon: "settings_panorama", value: "default" },
                { displayName: Translation.tr("Minimal"), icon: "settings_heart", value: "minimal" },
                { displayName: Translation.tr("Dashboard"), icon: "dashboard", value: "dashboard" }
              ] },
            { type: "select", key: "settings.animationSpeed", title: Translation.tr("Dashboard animation speed"), icon: "speed", when: () => Config.options.settings.style === "dashboard", options: [
                { displayName: "1x", icon: "slow_motion_video", value: 1 },
                { displayName: "1.5x", icon: "play_arrow", value: 1.5 },
                { displayName: "2x", icon: "fast_forward", value: 2 },
                { displayName: "3x", icon: "bolt", value: 3 }
              ] },
            { type: "spin", key: "settings.borderSize", title: Translation.tr("Border width"), icon: "border_style", from: 0, to: 10, step: 1 },
            { type: "swatch", w: 2, key: "settings.borderColor", title: Translation.tr("Border color"), icon: "format_paint", colors: ["primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer", "layer0Border"] },
            { type: "toggle", key: "settings.keepOpen", title: Translation.tr("Keep open when clicking outside"), icon: "keep" },
            { type: "action", key: "custom:expandCollapsedSections", title: Translation.tr("Expand all collapsed sections"), icon: "expand_all", label: Translation.tr("Expand all collapsed sections") }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Left Sidebar"), icon: "splitscreen_left", cards: [
            { type: "select", key: "policies.ai", title: Translation.tr("AI"), icon: "smart_toy", kw: "left sidebar ai tab remove", options: [
                { displayName: Translation.tr("No"), icon: "close", value: 0 },
                { displayName: Translation.tr("Yes"), icon: "check", value: 1 },
                { displayName: Translation.tr("Local only"), icon: "sync_saved_locally", value: 2 }
              ] },
            { type: "select", key: "policies.weeb", title: Translation.tr("Weeb"), icon: "playing_cards", options: [
                { displayName: Translation.tr("No"), icon: "close", value: 0 },
                { displayName: Translation.tr("Yes"), icon: "check", value: 1 },
                { displayName: Translation.tr("Closet"), icon: "ev_shadow", value: 2 }
              ] },
            { type: "toggle", key: "sidebar.translator.enable", title: Translation.tr("Translator"), icon: "translate" },
            { type: "toggle", key: "sidebar.media.enable", title: Translation.tr("Media player"), icon: "music_note", kw: "left sidebar media tab intelligence translator anime" }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Right Sidebar"), icon: "splitscreen_right", cards: [
            { type: "toggle", key: "sidebar.keepRightSidebarLoaded", title: Translation.tr("Keep loaded"), icon: "bolt" },
            { type: "toggle", key: "sidebar.banner", title: Translation.tr("Banner"), icon: "image" },
            { type: "toggle", key: "sidebar.bottomGroup", title: Translation.tr("Bottom group"), icon: "bottom_navigation" },
            { type: "toggle", key: "sidebar.mediaPlayer", title: Translation.tr("Media player"), icon: "play_circle" },
            { type: "toggle", key: "sidebar.media.showLyrics", title: Translation.tr("Show lyrics"), icon: "lyrics", when: () => Config.options.sidebar.mediaPlayer },
            { type: "toggle", key: "sidebar.media.artColors", title: Translation.tr("Album colors"), icon: "palette", when: () => Config.options.sidebar.mediaPlayer },
            { type: "toggle", key: "sidebar.media.blurredBackground", title: Translation.tr("Blurred art background"), icon: "blur_on", when: () => Config.options.sidebar.mediaPlayer },
            { type: "toggle", key: "sidebar.media.shapeArt", title: Translation.tr("Shaped art"), icon: "shapes", when: () => Config.options.sidebar.mediaPlayer },
            { type: "combo", key: "custom:mediaArtShape", title: Translation.tr("Art shape"), icon: "category", when: () => Config.options.sidebar.mediaPlayer && Config.options.sidebar.media.shapeArt },
            { type: "select", key: "sidebar.quickToggles.style", title: Translation.tr("Quick toggles style"), icon: "toggle_on", options: [
                { displayName: Translation.tr("Classic"), icon: "password_2", value: "classic" },
                { displayName: Translation.tr("Android"), icon: "action_key", value: "android" }
              ] },
            { type: "spin", key: "sidebar.quickToggles.android.columns", title: Translation.tr("Toggle columns"), icon: "view_column", from: 1, to: 8, step: 1, when: () => Config.options.sidebar.quickToggles.style === "android" },
            { type: "toggle", key: "sidebar.quickSliders.enable", title: Translation.tr("Quick sliders"), icon: "tune" },
            { type: "toggle", key: "sidebar.quickSliders.showBrightness", title: Translation.tr("Brightness slider"), icon: "brightness_6", when: () => Config.options.sidebar.quickSliders.enable },
            { type: "toggle", key: "sidebar.quickSliders.showVolume", title: Translation.tr("Volume slider"), icon: "volume_up", when: () => Config.options.sidebar.quickSliders.enable },
            { type: "toggle", key: "sidebar.quickSliders.showMic", title: Translation.tr("Mic slider"), icon: "mic", when: () => Config.options.sidebar.quickSliders.enable }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Hot Corners"), icon: "call_to_action", cards: [
            { type: "toggle", key: "sidebar.cornerOpen.enable", title: Translation.tr("Enable"), icon: "call_to_action" },
            { type: "toggle", key: "sidebar.cornerOpen.clickless", title: Translation.tr("Hover to trigger"), icon: "ads_click" },
            { type: "toggle", key: "sidebar.cornerOpen.clicklessCornerEnd", title: Translation.tr("Absolute corner"), icon: "crop_free", when: () => !Config.options.sidebar.cornerOpen.clickless },
            { type: "spin", key: "sidebar.cornerOpen.clicklessCornerVerticalOffset", title: Translation.tr("Vertical offset"), icon: "vertical_align_center", from: 0, to: 20, step: 1 },
            { type: "toggle", key: "sidebar.cornerOpen.bottom", title: Translation.tr("Place at bottom"), icon: "position_bottom_left" },
            { type: "toggle", key: "sidebar.cornerOpen.valueScroll", title: Translation.tr("Value scroll"), icon: "unfold_more" },
            { type: "toggle", key: "sidebar.cornerOpen.visualize", title: Translation.tr("Visualize region"), icon: "visibility" },
            { type: "spin", key: "sidebar.cornerOpen.cornerRegionWidth", title: Translation.tr("Region width"), icon: "width", from: 1, to: 300, step: 1 },
            { type: "spin", key: "sidebar.cornerOpen.cornerRegionHeight", title: Translation.tr("Region height"), icon: "height", from: 1, to: 300, step: 1 },
            { type: "combo", key: "custom:hotCornerBottomLeft", title: Translation.tr("Bottom-left"), icon: "position_bottom_left" },
            { type: "combo", key: "custom:hotCornerBottomRight", title: Translation.tr("Bottom-right"), icon: "position_bottom_right" }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Overview"), icon: "overview_key", cards: [
            { type: "toggle", key: "overview.enable", title: Translation.tr("Enable"), icon: "overview_key" },
            { type: "toggle", key: "overview.centerIcons", title: Translation.tr("Center icons"), icon: "center_focus_strong" },
            { type: "select", key: "overview.style", title: Translation.tr("Style"), icon: "grid_view", options: [
                { displayName: Translation.tr("Default"), icon: "grid_on", value: "default" },
                { displayName: Translation.tr("Niri-like"), icon: "view_agenda", value: "niri" }
              ] },
            { type: "spin", key: "overview.scale", title: Translation.tr("Scale (%)"), icon: "zoom_in", from: 1, to: 100, step: 1, factor: 100 },
            { type: "spin", key: "overview.rows", title: Translation.tr("Rows"), icon: "table_rows", from: 1, to: 20, step: 1, when: () => Config.options.overview.style !== "niri" },
            { type: "spin", key: "overview.columns", title: Translation.tr("Columns"), icon: "view_column", from: 1, to: 20, step: 1, when: () => Config.options.overview.style !== "niri" },
            { type: "select", key: "overview.orderRightLeft", title: Translation.tr("Horizontal order"), icon: "swap_horiz", when: () => Config.options.overview.style !== "niri", options: [
                { displayName: Translation.tr("Left to right"), icon: "arrow_forward", value: 0 },
                { displayName: Translation.tr("Right to left"), icon: "arrow_back", value: 1 }
              ] },
            { type: "select", key: "overview.orderBottomUp", title: Translation.tr("Vertical order"), icon: "swap_vert", when: () => Config.options.overview.style !== "niri", options: [
                { displayName: Translation.tr("Top-down"), icon: "arrow_downward", value: 0 },
                { displayName: Translation.tr("Bottom-up"), icon: "arrow_upward", value: 1 }
              ] }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Dock"), icon: "dock_to_bottom", cards: [
            { type: "toggle", key: "dock.enable", title: Translation.tr("Enable"), icon: "dock_to_bottom" },
            { type: "toggle", key: "dock.showBackground", title: Translation.tr("Background"), icon: "layers" },
            { type: "toggle", key: "dock.hoverToReveal", title: Translation.tr("Hover to reveal"), icon: "visibility" },
            { type: "toggle", key: "dock.pinnedOnStartup", title: Translation.tr("Pinned on startup"), icon: "push_pin" },
            { type: "toggle", key: "dock.lockPinnedApps", title: Translation.tr("Lock the order of pinned apps"), icon: "lock" },
            { type: "toggle", key: "dock.showMedia", title: Translation.tr("Media player"), icon: "music_note" },
            { type: "toggle", key: "dock.showPinButton", title: Translation.tr("Pin button"), icon: "push_pin" },
            { type: "toggle", key: "dock.showAppsButton", title: Translation.tr("Apps button"), icon: "apps" },
            { type: "toggle", key: "dock.monochromeIcons", title: Translation.tr("Tint app icons"), icon: "palette" },
            { type: "toggle", key: "dock.showPreviews", title: Translation.tr("Window previews"), icon: "preview" },
            { type: "spin", key: "dock.iconSize", title: Translation.tr("Icon size"), icon: "photo_size_select_large", from: 20, to: 48, step: 1 },
            { type: "spin", key: "dock.iconSpacing", title: Translation.tr("Icon spacing"), icon: "space_bar", from: 0, to: 12, step: 1 },
            { type: "page", pageId: "interface", section: "Dock", subsection: "Show dock on", title: Translation.tr("Show dock on"), icon: "monitor", kw: "dock screen monitor which display show" }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Dock style"), icon: "call_to_action", cards: [
            { type: "select", key: "dock.style", title: Translation.tr("Style"), icon: "dock_to_bottom", kw: "dock hug float attached screen edge frame", options: [
                { displayName: Translation.tr("Float"), icon: "call_to_action", value: "float" },
                { displayName: Translation.tr("Hug"), icon: "dock_to_bottom", value: "hug" }
              ] },
            { type: "select", key: "dock.position", title: Translation.tr("Position"), icon: "dock_to_bottom", kw: "dock position left right bottom side edge", options: [
                { displayName: Translation.tr("Left"), icon: "dock_to_left", value: "left" },
                { displayName: Translation.tr("Bottom"), icon: "dock_to_bottom", value: "bottom" },
                { displayName: Translation.tr("Right"), icon: "dock_to_right", value: "right" }
              ] },
            { type: "spin", key: "dock.radius", title: Translation.tr("Corner radius"), icon: "rounded_corner", from: 0, to: 40, step: 1 },
            { type: "spin", key: "dock.height", title: Translation.tr("Height (px)"), icon: "height", from: 20, to: 200, step: 1 },
            { type: "spin", key: "dock.hoverRegionHeight", title: Translation.tr("Hover region height (px)"), icon: "swipe_up", from: 1, to: 50, step: 1, kw: "dock hover reveal strip edge height" },
            { type: "toggle", key: "dock.followFrameColor", title: Translation.tr("Follow frame color"), icon: "filter_frames", when: () => Config.options.dock.style === "hug" },
            { type: "toggle", key: "dock.showBorder", title: Translation.tr("Border"), icon: "border_style", when: () => Config.options.dock.style !== "hug" },
            { type: "spin", key: "dock.borderWidth", title: Translation.tr("Border width"), icon: "line_weight", from: 1, to: 10, step: 1, when: () => Config.options.dock.showBorder && Config.options.dock.style !== "hug" },
            { type: "swatch", w: 2, key: "dock.borderColor", title: Translation.tr("Border color"), icon: "format_paint", when: () => Config.options.dock.showBorder && Config.options.dock.style !== "hug", colors: ["layer0Border", "primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer", "layer1"] },
            { type: "swatch", w: 2, key: "dock.backgroundColor", title: Translation.tr("Background color"), icon: "palette", colors: ["layer0", "layer1", "primaryContainer", "secondaryContainer", "tertiaryContainer", "primary", "secondary", "tertiary"] },
            { type: "text", w: 2, key: "dock.ignoredAppRegexes", list: true, title: Translation.tr("Hidden apps"), icon: "visibility_off", placeholder: "explorer.exe, ^Shell_", kw: "dock hide apps regex explorer shell ignored" }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("NabyScape island"), icon: "toolbar", when: () => Config.options.appearance.visualStyle === "nabyscape" || Config.options.nabyIsland.enable, cards: [
            { type: "toggle", key: "nabyIsland.enable", title: Translation.tr("Enable"), icon: "check" },
            { type: "toggle", key: "nabyIsland.followCursor", title: Translation.tr("Follow the cursor's monitor"), icon: "arrow_selector_tool" },
            { type: "toggle", key: "nabyIsland.showOsd", title: Translation.tr("Volume and brightness"), icon: "volume_up" },
            { type: "toggle", key: "nabyIsland.showNotifications", title: Translation.tr("Notifications"), icon: "notifications" },
            { type: "toggle", key: "nabyIsland.showTimers", title: Translation.tr("Timers"), icon: "timer" },
            { type: "toggle", key: "nabyIsland.showWaveform", title: Translation.tr("Music waveform"), icon: "graphic_eq" },
            { type: "page", pageId: "interface", section: "NabyScape island", subsection: "Show the island on", title: Translation.tr("Show the island on"), icon: "monitor", kw: "naby island screen monitor which display primary" }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Lock screen"), icon: "lock", os: "linux", cards: [
            { type: "toggle", key: "lock.useHyprlock", title: Translation.tr("Use Hyprlock (instead of Quickshell)"), icon: "water_drop" },
            { type: "toggle", key: "lock.launchOnStartup", title: Translation.tr("Launch on startup"), icon: "account_circle" },
            { type: "toggle", key: "lock.security.requirePasswordToPower", title: Translation.tr("Require password to power off/restart"), icon: "settings_power" },
            { type: "toggle", key: "lock.security.unlockKeyring", title: Translation.tr("Also unlock keyring"), icon: "key_vertical" },
            { type: "toggle", key: "lock.centerClock", title: Translation.tr("Center clock"), icon: "center_focus_weak" },
            { type: "toggle", key: "lock.showLockedText", title: Translation.tr('Show "Locked" text'), icon: "info" },
            { type: "toggle", key: "lock.materialShapeChars", title: Translation.tr("Use varying shapes for password characters"), icon: "shapes" },
            { type: "toggle", key: "lock.blur.enable", title: Translation.tr("Enable blur"), icon: "blur_on" },
            { type: "spin", key: "lock.blur.extraZoom", title: Translation.tr("Extra wallpaper zoom (%)"), icon: "loupe", from: 1, to: 150, step: 2, factor: 100, when: () => Config.options.lock.blur.enable }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Overlay"), icon: "layers", cards: [
            { type: "toggle", key: "overlay.openingZoomAnimation", title: Translation.tr("Opening zoom"), icon: "high_density" },
            { type: "toggle", key: "overlay.darkenScreen", title: Translation.tr("Darken screen"), icon: "texture" },
            { type: "spin", key: "overlay.clickthroughOpacity", title: Translation.tr("Clickthrough widget opacity (%)"), icon: "opacity", from: 0, to: 100, step: 5, factor: 100 },
            { type: "text", w: 2, key: "overlay.floatingImage.imageSource", title: Translation.tr("Floating image source"), icon: "imagesmode" },
            { type: "spin", key: "overlay.floatingImage.scale", title: Translation.tr("Scale (%)"), icon: "loupe", from: 10, to: 500, step: 10, factor: 100 },
            { type: "text", w: 2, key: "crosshair.code", title: Translation.tr("Crosshair code"), icon: "point_scan", placeholder: Translation.tr("Crosshair code (in Valorant's format)"), kw: "crosshair valorant code overlay editor vcrdb" }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Region selector (screen snipping/Google Lens)"), icon: "screenshot_frame_2", cards: [
            { type: "toggle", key: "regionSelector.targetRegions.windows", title: Translation.tr("Windows"), icon: "select_window" },
            { type: "toggle", key: "regionSelector.targetRegions.layers", title: Translation.tr("Layers"), icon: "right_panel_open" },
            { type: "toggle", key: "regionSelector.targetRegions.content", title: Translation.tr("Content"), icon: "nearby" },
            { type: "toggle", key: "regionSelector.targetRegions.showLabel", title: Translation.tr("Show label"), icon: "label" },
            { type: "spin", key: "regionSelector.targetRegions.opacity", title: Translation.tr("Window/layer opacity (%)"), icon: "opacity", from: 0, to: 100, step: 5, factor: 100 },
            { type: "spin", key: "regionSelector.targetRegions.selectionPadding", title: Translation.tr("Selection padding (px)"), icon: "screenshot_frame_2", from: 0, to: 50, step: 1 },
            { type: "spin", key: "regionSelector.targetRegions.contentRegionOpacity", title: Translation.tr("Content region opacity (%)"), icon: "opacity", from: 0, to: 100, step: 5, factor: 100, os: "linux" },
            { type: "toggle", key: "regionSelector.annotation.useSatty", title: Translation.tr("Use Satty"), icon: "draw", os: "linux" },
            { type: "select", key: "custom:googleLensSelectionType", title: Translation.tr("Selection type"), icon: "ink_selection" },
            { type: "toggle", key: "regionSelector.rect.showAimLines", title: Translation.tr("Show aim lines"), icon: "point_scan" },
            { type: "spin", key: "regionSelector.circle.strokeWidth", title: Translation.tr("Stroke width"), icon: "eraser_size_3", from: 1, to: 20, step: 1 },
            { type: "spin", key: "regionSelector.circle.padding", title: Translation.tr("Padding"), icon: "screenshot_frame_2", from: 0, to: 100, step: 5 }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("On-screen display"), icon: "voting_chip", cards: [
            { type: "spin", key: "osd.timeout", title: Translation.tr("OSD timeout (ms)"), icon: "timer", from: 100, to: 3000, step: 100 },
            { type: "toggle", key: "osd.showBrightnessOutsideChanges", title: Translation.tr("Show the brightness indicator for changes made outside ii"), icon: "brightness_6" }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("On-screen keyboard"), icon: "keyboard", cards: [
            { type: "select", key: "osk.layout", title: Translation.tr("Layout"), icon: "keyboard_keys", options: [
                { displayName: Translation.tr("English (US)"), value: "English (US)" },
                { displayName: Translation.tr("German"), value: "German" },
                { displayName: Translation.tr("Russian"), value: "Russian" }
              ] },
            { type: "toggle", key: "osk.pinnedOnStartup", title: Translation.tr("Pinned on startup"), icon: "keep" }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Cheat sheet"), icon: "keyboard_command_key", cards: [
            { type: "select", w: 4, key: "cheatsheet.superKey", title: Translation.tr("Super key symbol"), icon: "keyboard_command_key", options: (["󰖳", "", "󰨡", "", "󰌽", "󰣇", "", "", "", "", "", "󱄛", "", "", "", "⌘", "󰀲", "󰟍", ""]).map(icon => ({ displayName: icon, value: icon })) },
            { type: "toggle", key: "cheatsheet.useMacSymbol", title: Translation.tr("Use macOS-like symbols for mods keys"), icon: "keyboard_option_key" },
            { type: "toggle", key: "cheatsheet.useFnSymbol", title: Translation.tr("Use symbols for function keys"), icon: "fn_key" },
            { type: "toggle", key: "cheatsheet.useMouseSymbol", title: Translation.tr("Use symbols for mouse"), icon: "mouse" },
            { type: "toggle", key: "cheatsheet.splitButtons", title: Translation.tr("Split buttons"), icon: "highlight_keyboard_focus" },
            { type: "spin", key: "cheatsheet.fontSize.key", title: Translation.tr("Keybind font size"), icon: "format_size", from: 8, to: 30, step: 1 },
            { type: "spin", key: "cheatsheet.fontSize.comment", title: Translation.tr("Description font size"), icon: "text_fields", from: 8, to: 30, step: 1 },
            { type: "toggle", key: "cheatsheet.hideElements", title: Translation.tr("Remove the Elements tab from the cheatsheet"), icon: "experiment" },
            { type: "toggle", key: "cheatsheet.aiUsage.enable", title: Translation.tr("AI usage tab"), icon: "data_usage" },
            { type: "spin", key: "cheatsheet.aiUsage.refreshSeconds", title: Translation.tr("AI usage refresh (seconds)"), icon: "update", from: 30, to: 900, step: 30, when: () => Config.options.cheatsheet.aiUsage.enable }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Interactions"), icon: "swipe", cards: [
            { type: "toggle", key: "interactions.scrolling.fasterTouchpadScroll", title: Translation.tr("Faster touchpad/mouse scrolling"), icon: "swipe" },
            { type: "spin", key: "interactions.scrolling.mouseScrollDeltaThreshold", title: Translation.tr("Mouse wheel detection threshold"), icon: "mouse", from: 1, to: 1000, step: 10, when: () => Config.options.interactions.scrolling.fasterTouchpadScroll },
            { type: "spin", key: "interactions.scrolling.mouseScrollFactor", title: Translation.tr("Mouse scroll factor"), icon: "mouse", from: 10, to: 2000, step: 10, when: () => Config.options.interactions.scrolling.fasterTouchpadScroll },
            { type: "spin", key: "interactions.scrolling.touchpadSensitivity", title: Translation.tr("Touchpad sensitivity"), icon: "swipe", from: 50, to: 2000, step: 10, factor: 100, when: () => Config.options.interactions.scrolling.fasterTouchpadScroll },
            { type: "spin", key: "interactions.scrolling.flingFriction", title: Translation.tr("Fling friction"), icon: "speed", from: 1, to: 500, step: 1, factor: 10000, when: () => Config.options.interactions.scrolling.fasterTouchpadScroll },
            { type: "spin", key: "interactions.scrolling.flingStopThreshold", title: Translation.tr("Fling stop threshold"), icon: "stop_circle", from: 1, to: 200, step: 1, factor: 1000, when: () => Config.options.interactions.scrolling.fasterTouchpadScroll },
            { type: "spin", key: "interactions.scrolling.bounceDamping", title: Translation.tr("Bounce damping"), icon: "vertical_align_center", from: 0, to: 100, step: 5, factor: 100, when: () => Config.options.interactions.scrolling.fasterTouchpadScroll },
            { type: "spin", key: "interactions.scrolling.wheelScrollAmount", title: Translation.tr("Wheel scroll amount"), icon: "mouse", from: 10, to: 2000, step: 10, when: () => Config.options.interactions.scrolling.fasterTouchpadScroll },
            { type: "spin", key: "interactions.scrolling.wheelDurationMin", title: Translation.tr("Minimum duration (ms)"), icon: "timer", from: 50, to: 1000, step: 10, when: () => Config.options.interactions.scrolling.fasterTouchpadScroll },
            { type: "spin", key: "interactions.scrolling.wheelDurationMax", title: Translation.tr("Maximum duration (ms)"), icon: "timer", from: 50, to: 2000, step: 10, when: () => Config.options.interactions.scrolling.fasterTouchpadScroll },
            { type: "toggle", key: "interactions.deadPixelWorkaround.enable", title: Translation.tr("Dead pixel workaround"), icon: "border_right" }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Media"), icon: "music_note", cards: [
            { type: "toggle", key: "media.filterDuplicatePlayers", title: Translation.tr("Filter duplicate players"), icon: "music_note" }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Waffle panel"), icon: "widgets", cards: [
            { type: "toggle", key: "waffles.tweaks.switchHandlePositionFix", title: Translation.tr("Fix switch handle position"), icon: "toggle_on" },
            { type: "toggle", key: "waffles.tweaks.smootherMenuAnimations", title: Translation.tr("Smoother menu animations"), icon: "menu_open" },
            { type: "toggle", key: "waffles.tweaks.smootherSearchBar", title: Translation.tr("Smoother search bar"), icon: "search" },
            { type: "toggle", key: "waffles.bar.bottom", title: Translation.tr("Bar at bottom"), icon: "vertical_align_bottom" },
            { type: "toggle", key: "waffles.bar.leftAlignApps", title: Translation.tr("Left-align apps"), icon: "format_align_left" },
            { type: "text", w: 2, key: "calendar.locale", title: Translation.tr("Locale for the calendar, e.g. en-GB"), icon: "language", placeholder: "en-GB" },
            { type: "toggle", key: "waffles.calendar.force2CharDayOfWeek", title: Translation.tr("Short day-of-week labels"), icon: "calendar_view_week" }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Calendar events"), icon: "event", os: "windows", cards: [
            { type: "toggle", key: "calendar.events.enable", title: Translation.tr("Show calendar events"), icon: "event" },
            { type: "spin", key: "calendar.events.refreshMinutes", title: Translation.tr("Refresh interval (minutes)"), icon: "update", from: 5, to: 180, step: 5 },
            { type: "page", pageId: "interface", section: "Calendar events", label: "Add calendar", title: Translation.tr("Manage calendar sources"), icon: "sync", kw: "calendar ical ics google outlook add remove refresh source credential manager" }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Wallpaper selector"), icon: "wallpaper", cards: [
            { type: "toggle", key: "wallpaperSelector.useSystemFileDialog", title: Translation.tr("System file picker"), icon: "ad" },
            { type: "toggle", key: "wallpaperSelector.showHomePath", title: Translation.tr("Home in quick access"), icon: "home" },
            { type: "toggle", key: "wallpaperSelector.closeAfterSelection", title: Translation.tr("Close after selection"), icon: "done" },
            { type: "toggle", key: "wallpaperSelector.showBlurBackground", title: Translation.tr("Blur background"), icon: "blur_on" },
            { type: "toggle", key: "wallpaperSelector.showSearchbar", title: Translation.tr("Search bar"), icon: "search" },
            { type: "spin", key: "wallpaperSelector.columns", title: Translation.tr("Grid columns"), icon: "grid_view", from: 3, to: 10, step: 1 },
            { type: "spin", key: "wallpaperSelector.changeInterval", title: Translation.tr("Change interval (min)"), icon: "timer", from: 0, to: 1440, step: 5, factor: 1 / 60000 },
            { type: "combo", key: "wallpaperSelector.sortMode", title: Translation.tr("Sort wallpapers by"), icon: "sort", options: [
                { displayName: Translation.tr("Newest first"), value: "time" },
                { displayName: Translation.tr("Oldest first"), value: "time_rev" },
                { displayName: Translation.tr("Name A-Z"), value: "name" },
                { displayName: Translation.tr("Name Z-A"), value: "name_rev" },
                { displayName: Translation.tr("Largest first"), value: "size" },
                { displayName: Translation.tr("Smallest first"), value: "size_rev" }
              ] },
            { type: "text", w: 2, key: "wallpaperSelector.userPath", title: Translation.tr("Custom wallpaper folder"), icon: "folder", placeholder: Translation.tr("e.g., C:/Users/you/Pictures") },
            { type: "text", w: 2, key: "wallpaperSelector.liveWallpapersPath", title: Translation.tr("Live wallpaper folder"), icon: "video_template", placeholder: Translation.tr("e.g., C:/Users/you/Videos/Wallpapers"), kw: "live wallpaper video folder desktop menu" },
            { type: "toggle", key: "background.pauseVideoWhenCovered", title: Translation.tr("Pause the live wallpaper when a window covers the desktop"), icon: "pause_circle" },
            { type: "text", w: 2, key: "wallpaperSelector.wppFolder", title: Translation.tr("Wpp folder"), icon: "folder_special" },
            { type: "text", w: 2, key: "wallpaperSelector.wppSpicyFolder", title: Translation.tr("Wpp (Spicy) folder"), icon: "whatshot", kw: "spicy wpp folder blurred restricted", when: () => SpicyStuff.allowed }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Wallhaven"), icon: "travel_explore", cards: [
            { type: "text", w: 2, key: "custom:wallhavenApiKey", title: Translation.tr("Wallhaven API key"), icon: "key", placeholder: Translation.tr("Optional — needed for Spicy results") },
            { type: "combo", key: "custom:wallhavenDefaultSort", title: Translation.tr("Default sort"), icon: "sort" },
            { type: "select", key: "custom:wallhavenOrder", title: Translation.tr("Order"), icon: "swap_vert" },
            { type: "select", key: "custom:wallhavenTopRange", title: Translation.tr("Top list range"), icon: "date_range" },
            { type: "toggle", key: "custom:wallhavenCategoryGeneral", title: Translation.tr("General"), icon: "category" },
            { type: "toggle", key: "custom:wallhavenCategoryAnime", title: Translation.tr("Anime"), icon: "animation" },
            { type: "toggle", key: "custom:wallhavenCategoryPeople", title: Translation.tr("People"), icon: "people" },
            { type: "toggle", key: "custom:wallhavenPuritySfw", title: "SFW", icon: "wb_sunny" },
            { type: "toggle", key: "custom:wallhavenPuritySketchy", title: Translation.tr("Sketchy"), icon: "warning", when: () => SpicyStuff.allowed },
            { type: "toggle", key: "custom:wallhavenPuritySpicy", title: Translation.tr("Spicy"), icon: "whatshot", when: () => SpicyStuff.allowed && WallhavenSearch.apiKey.length > 0 },
            { type: "select", key: "custom:wallhavenAspectRatio", title: Translation.tr("Aspect ratio"), icon: "aspect_ratio" },
            { type: "text", w: 2, key: "wallpaperSelector.wallhavenQuery", title: Translation.tr("Default search query"), icon: "search" },
            { type: "text", w: 2, key: "custom:wallhavenColorFilter", title: Translation.tr("Color filter"), icon: "palette", placeholder: Translation.tr("Comma-separated hex, e.g. cc0000,0066cc") },
            { type: "page", pageId: "interface", section: "Wallhaven", label: "I'm 18 or older", title: Translation.tr("Spicy Stuff access"), icon: "verified_user", kw: "spicy stuff age confirmation 18 wallhaven restriction" }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Fonts"), icon: "text_format", cards: [
            { type: "combo", key: "custom:fontMain", title: Translation.tr("Main font"), icon: "font_download", kw: "main font general ui text" },
            { type: "combo", key: "custom:fontNumbers", title: Translation.tr("Numbers font"), icon: "123", kw: "numbers font" },
            { type: "combo", key: "custom:fontTitle", title: Translation.tr("Title font"), icon: "title", kw: "title font headings" },
            { type: "combo", key: "custom:fontMonospace", title: Translation.tr("Monospace font"), icon: "space_bar", kw: "monospace font code terminal" },
            { type: "combo", key: "custom:fontIconNerd", title: Translation.tr("Nerd font icons"), icon: "emoticon", kw: "nerd font icons" },
            { type: "combo", key: "custom:fontReading", title: Translation.tr("Reading font"), icon: "book_ribbon", kw: "reading font large text blocks" },
            { type: "combo", key: "custom:fontExpressive", title: Translation.tr("Expressive font"), icon: "mood_heart", kw: "expressive font decorative" }
          ]
        },
        {
          page: Translation.tr("Interface"), title: Translation.tr("Color generation"), icon: "colors", cards: [
            { type: "toggle", key: "appearance.wallpaperTheming.enableAppsAndShell", title: Translation.tr("Shell & utilities"), icon: "hardware" },
            { type: "toggle", key: "appearance.wallpaperTheming.enableQtApps", title: Translation.tr("Qt apps"), icon: "tv_options_input_settings" },
            { type: "toggle", key: "appearance.wallpaperTheming.enableTerminal", title: Translation.tr("Terminal"), icon: "terminal" },
            { type: "toggle", key: "appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode", title: Translation.tr("Force dark mode in terminal"), icon: "dark_mode" },
            { type: "spin", key: "appearance.wallpaperTheming.terminalGenerationProps.harmony", title: Translation.tr("Terminal: Harmony (%)"), icon: "invert_colors", from: 0, to: 100, step: 10, factor: 100 },
            { type: "spin", key: "appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold", title: Translation.tr("Terminal: Harmonize threshold"), icon: "gradient", from: 0, to: 100, step: 10 },
            { type: "spin", key: "appearance.wallpaperTheming.terminalGenerationProps.termFgBoost", title: Translation.tr("Terminal: Foreground boost (%)"), icon: "format_color_text", from: 0, to: 100, step: 10, factor: 100 }
          ]
        },
        {
          page: Translation.tr("Bar"), title: Translation.tr("Screens"), icon: "monitor",
          cards: [
            { type: "page", pageId: "bar", section: "Screens", subsection: "Shown on monitors",
              label: "All monitors", title: Translation.tr("Monitors shown on"), icon: "monitor",
              kw: "monitor screen multi display bar visible all monitors per-monitor", w: 2 }
          ]
        },
        {
          page: Translation.tr("Bar"), title: Translation.tr("Bar layout"), icon: "view_week",
          cards: [
            { type: "barlayout", key: "bar:Layout editor", title: Translation.tr("Bar layout"), icon: "view_week",
              kw: "bar layout left center right widget order ii layout end4-pC layout reset classic configurable" }
          ]
        },
        {
          page: Translation.tr("Bar"), title: Translation.tr("Positioning & Styles"), icon: "pivot_table_chart",
          cards: [
            { type: "select", key: "bar.cornerStyle", title: Translation.tr("Bar style"), icon: "style", w: 4,
              kw: "corner hug float islands rect panel m3 split hug",
              options: [
                { displayName: Translation.tr("Hug"),       icon: "line_curve",     value: 0 },
                { displayName: Translation.tr("Split Hug"), icon: "splitscreen",    value: 6 },
                { displayName: Translation.tr("Float"),     icon: "page_header",    value: 1 },
                { displayName: Translation.tr("Rect"),      icon: "toolbar",        value: 2 },
                { displayName: Translation.tr("M3"),        icon: "interests",      value: 3 },
                { displayName: Translation.tr("M3 Hug"),    icon: "category",       value: 4 },
                { displayName: Translation.tr("Panel"),     icon: "call_to_action", value: 5 }
              ] },
            { type: "select", key: "bar.borderless", title: Translation.tr("Group style"), icon: "view_agenda",
              options: [
                { displayName: Translation.tr("Pills"),          icon: "location_chip", value: false },
                { displayName: Translation.tr("Line-separated"), icon: "split_scene",   value: true }
              ] },
            { type: "toggle", key: "bar.showBackground", title: Translation.tr("Bar background"), icon: "web_asset",
              kw: "show background enabled only when corner style is not m3 m3 hug split hug" },
            { type: "select", key: "bar.autoHide.enable", title: Translation.tr("Autohide"), icon: "visibility_off",
              options: [
                { displayName: Translation.tr("No"),  icon: "close", value: false },
                { displayName: Translation.tr("Yes"), icon: "check", value: true }
              ] },
            { type: "toggle", key: "bar.floatStyleShadow", title: Translation.tr("Shadow behind bar"), icon: "shadow",
              kw: "shadow only visible when corner style is float" },
            { type: "toggle", key: "bar.verbose", title: Translation.tr("Verbose"), icon: "subject",
              kw: "fuller text date clock center modules instead of compact icons" },
            { type: "swatch", w: 2, key: "bar.groupColor", title: Translation.tr("Group color"), icon: "brush",
              colors: ["primaryContainer", "secondaryContainer", "tertiaryContainer", "layer1", "layer0"] },
            { type: "select", w: 2, key: "appearance.fakeScreenRounding", title: Translation.tr("Screen rounded corners"), icon: "rounded_corner",
              kw: "fake screen rounding corners quick wallpaper popup",
              options: [
                { displayName: Translation.tr("No"),  icon: "close", value: 0 },
                { displayName: Translation.tr("Yes"), icon: "check", value: 1 },
                { displayName: Translation.tr("When not fullscreen"), icon: "fullscreen_exit", value: 2 }
              ] },
            { type: "action", key: "custom:resetBarWidgetStyles", title: Translation.tr("Reset widget styles"), icon: "format_color_reset",
              kw: "reset per-widget background border radius padding configurable layout only" },

            { type: "toggle", key: "bar.showFrame", title: Translation.tr("Screen frame"), icon: "crop_free" },
            { type: "toggle", key: "bar.followFrameColor", title: Translation.tr("Follow frame color"), icon: "format_paint",
              kw: "bar background uses the frame color, enabled only when show frame is on" },
            { type: "spin", key: "bar.frameThickness", title: Translation.tr("Frame thickness"), icon: "border_outer",
              from: 2, to: 10, step: 1 },
            { type: "swatch", w: 2, key: "bar.frameColor", title: Translation.tr("Frame color"), icon: "imagesearch_roller",
              colors: ["primaryContainer", "secondaryContainer", "tertiaryContainer", "layer0", "black"] },
            { type: "toggle", key: "bar.centerOnlyReserveFrame", title: Translation.tr("Overlap windows"), icon: "layers",
              kw: "when left and right sides of bar are empty, only frame reserves space, windows go under bar" },

            { type: "toggle", key: "bar.autoHide.pushWindows", title: Translation.tr("Push windows out of the way"), icon: "fit_screen",
              kw: "autohide reserve bar space so windows get pushed instead of going underneath, enabled when autohide on" },
            { type: "toggle", key: "bar.autoHide.showWhenPressingSuper.enable", title: Translation.tr("Show when holding Super"), icon: "keyboard_command_key",
              kw: "autohide super key reveal bar" },
            { type: "spin", key: "bar.autoHide.hoverRegionWidth", title: Translation.tr("Hover trigger region width (px)"), icon: "swipe",
              from: 0, to: 50, step: 1 },
            { type: "spin", key: "bar.autoHide.showWhenPressingSuper.delay", title: Translation.tr("Show delay when holding Super (ms)"), icon: "timer",
              from: 0, to: 1000, step: 10 }
          ]
        },
        {
          page: Translation.tr("Bar"), title: Translation.tr("Dynamic Island"), icon: "nest_wifi_pro", requires: "dynamicIsland",
          cards: [
            { type: "select", key: "bar.dynamicIsland.leftWidget", title: Translation.tr("Left widget"), icon: "right_panel_open",
              options: [
                { displayName: "", icon: "block", value: "none" },
                { displayName: Translation.tr("Clock and date"), icon: "schedule", value: "clockWidget" },
                { displayName: Translation.tr("Weather"), icon: "partly_cloudy_day", value: "weatherBar" }
              ] },
            { type: "select", key: "bar.dynamicIsland.rightWidget", title: Translation.tr("Right widget"), icon: "left_panel_open",
              options: [
                { displayName: "", icon: "block", value: "none" },
                { displayName: Translation.tr("System Icons"), icon: "settings", value: "systemIcons" },
                { displayName: Translation.tr("Tray"), icon: "apps", value: "sysTray" },
                { displayName: Translation.tr("Util Buttons"), icon: "widgets", value: "utilButtons" }
              ] },
            { type: "select", key: "bar.dynamicIsland.visualizerStyle", title: Translation.tr("Visualizer style"), icon: "graphic_eq",
              options: [
                { displayName: "", icon: "block", value: "none" },
                { displayName: Translation.tr("Dots"), icon: "steppers", value: "dots" },
                { displayName: Translation.tr("Wave"), icon: "ssid_chart", value: "wave" }
              ] },
            { type: "toggle", key: "bar.dynamicIsland.showMediaControls", title: Translation.tr("Media controls"), icon: "play_circle" }
          ]
        },
        {
          page: Translation.tr("Bar"), title: Translation.tr("Notifications"), icon: "notifications",
          cards: [
            { type: "combo", key: "notifications.position", title: Translation.tr("Popup position"), icon: "my_location",
              options: [
                { displayName: Translation.tr("Top left"), icon: "north_west", value: "top_left" },
                { displayName: Translation.tr("Top center"), icon: "north", value: "top_center" },
                { displayName: Translation.tr("Top right"), icon: "north_east", value: "top_right" },
                { displayName: Translation.tr("Bottom left"), icon: "south_west", value: "bottom_left" },
                { displayName: Translation.tr("Bottom center"), icon: "south", value: "bottom_center" },
                { displayName: Translation.tr("Bottom right"), icon: "south_east", value: "bottom_right" }
              ] },
            { type: "toggle", key: "notifications.forceMonitor.enable", title: Translation.tr("Force specific monitor"), icon: "monitor",
              kw: "multiple monitors notifications show on only one, enter monitor name" },
            { type: "combo", key: "custom:notifForceMonitorName", title: Translation.tr("Popup monitor"), icon: "desktop_windows",
              kw: "force monitor name eDP-1 enabled when force specific monitor is on" },
            { type: "toggle", key: "bar.indicators.notifications.showUnreadCount", title: Translation.tr("Unread count"), icon: "counter_1" },
            { type: "spin", key: "notifications.timeout", title: Translation.tr("Popup timeout (ms)"), icon: "timer",
              from: 1000, to: 60000, step: 1000 }
          ]
        },
        {
          page: Translation.tr("Bar"), title: Translation.tr("Tray"), icon: "inbox_customize",
          cards: [
            { type: "toggle", key: "tray.invertPinnedItems", title: Translation.tr("Pinned by default"), icon: "push_pin" },
            { type: "toggle", key: "tray.monochromeIcons", title: Translation.tr("Tint icons"), icon: "palette" },
            { type: "toggle", key: "tray.filterPassive", title: Translation.tr("Hide passive icons"), icon: "visibility_off",
              kw: "hides tray icons that report themselves as passive inactive" },
            { type: "toggle", key: "tray.showItemId", title: Translation.tr("Show item ID in tooltip"), icon: "label",
              kw: "appends tray icon internal id to tooltip, useful for pinning or filtering" }
          ]
        },
        {
          page: Translation.tr("Bar"), title: Translation.tr("Left sidebar button"), icon: "right_panel_open",
          cards: [
            { type: "text", key: "bar.topLeftIcon", title: Translation.tr("Top-left icon"), icon: "image", placeholder: "distro", kw: "distro os logo icon file name" },
            { type: "iconpicker", key: "bar:Icon picker", title: Translation.tr("Icon"), icon: "image",
              kw: "top-left icon distro logo icon picker grid custom icon color colorize" },
            { type: "text", w: 2, key: "custom.iconsPath", title: Translation.tr("Custom icons folder"), icon: "folder_open",
              placeholder: "~/Pictures/icons", kw: "icons path folder custom" },
            { type: "toggle", key: "custom.colorizeIcon", title: Translation.tr("Colorize icon"), icon: "colors" },
            { type: "swatch", w: 2, key: "custom.iconColor", title: Translation.tr("Icon color"), icon: "palette",
              colors: ["onLayer0", "primary", "secondary", "tertiary", "onPrimaryContainer", "onSecondaryContainer", "onTertiaryContainer"] }
          ]
        },
        {
          page: Translation.tr("Bar"), title: Translation.tr("Divider"), icon: "vertical_align_center", requires: "divisor",
          cards: [
            { type: "select", key: "bar.divider.style", title: Translation.tr("Divider style"), icon: "horizontal_rule",
              options: [
                { displayName: Translation.tr("Line"), icon: "more_vert", value: "rect" },
                { displayName: Translation.tr("Dot"), icon: "fiber_manual_record", value: "dot" },
                { displayName: Translation.tr("Space"), icon: "space_bar", value: "space" }
              ] },
            { type: "spin", key: "bar.divider.spacing", title: Translation.tr("Space width"), icon: "space_bar",
              from: 4, to: 400, step: 2, kw: "enabled only when divider style is space" }
          ]
        },
        {
          page: Translation.tr("Bar"), title: Translation.tr("Utility buttons"), icon: "buttons_alt", requires: "utilButtons",
          cards: [
            { type: "toggle", key: "bar.utilButtons.showScreenSnip", title: Translation.tr("Screen snip"), icon: "screenshot_region" },
            { type: "toggle", key: "bar.utilButtons.showColorPicker", title: Translation.tr("Color picker"), icon: "colorize" },
            { type: "toggle", key: "bar.utilButtons.showKeyboardToggle", title: Translation.tr("Keyboard toggle"), icon: "keyboard" },
            { type: "toggle", key: "bar.utilButtons.showMicToggle", title: Translation.tr("Mic toggle"), icon: "mic" },
            { type: "toggle", key: "bar.utilButtons.showDarkModeToggle", title: Translation.tr("Dark/Light toggle"), icon: "dark_mode" },
            { type: "toggle", key: "bar.utilButtons.showPerformanceProfileToggle", title: Translation.tr("Performance profile"), icon: "speed" },
            { type: "toggle", key: "bar.utilButtons.showScreenRecord", title: Translation.tr("Record screen"), icon: "screen_record" },
            { type: "toggle", key: "bar.utilButtons.showWallpaperToggle", title: Translation.tr("Wallpapers toggle"), icon: "wallpaper" }
          ]
        },
        {
          page: Translation.tr("Bar"), title: Translation.tr("Workspaces"), icon: "steppers", requires: "workspaces",
          cards: [
            { type: "select", w: 2, key: "bar.workspaces.style", title: Translation.tr("Workspaces style"), icon: "style",
              options: [
                { displayName: Translation.tr("Default"), icon: "view_carousel", value: "default" },
                { displayName: Translation.tr("GNOME"), icon: "more_horiz", value: "gnome" },
                { displayName: Translation.tr("Dots"), icon: "hdr_weak", value: "dots" },
                { displayName: Translation.tr("Ticks"), icon: "more_vert", value: "ticks" }
              ] },
            { type: "select", key: "bar.workspaces.indicatorStyle", title: Translation.tr("Indicator style"), icon: "more_horiz",
              kw: "enabled only when workspaces style is default",
              options: [
                { displayName: Translation.tr("Dots"), icon: "radio_button_checked", value: "dot" },
                { displayName: Translation.tr("Icons"), icon: "interests", value: "icon" }
              ] },
            { type: "spin", key: "bar.workspaces.shown", title: Translation.tr("Workspaces shown"), icon: "workspaces",
              from: 1, to: 30, step: 1 },
            { type: "toggle", key: "bar.workspaces.alwaysShowNumbers", title: Translation.tr("Always show numbers"), icon: "pin" },
            { type: "select", key: "custom:barWorkspacesNumberStyle", title: Translation.tr("Numbers style"), icon: "123",
              kw: "normal han chinese chars roman numerals" },
            { type: "toggle", key: "bar.workspaces.useNerdFont", title: Translation.tr("Use Nerd Font for numbers"), icon: "font_download",
              kw: "renders workspace numbers with nerd font glyph set, font must be installed" },
            { type: "spin", key: "bar.workspaces.showNumberDelay", title: Translation.tr("Number show delay when pressing Super (ms)"), icon: "touch_long",
              from: 0, to: 1000, step: 50 },
            { type: "toggle", key: "bar.workspaces.showAppIcons", title: Translation.tr("Show app icons"), icon: "apps" },
            { type: "toggle", key: "bar.workspaces.monochromeIcons", title: Translation.tr("Tint app icons"), icon: "palette" }
          ]
        },
        {
          page: Translation.tr("Bar"), title: Translation.tr("Resources"), icon: "empty_dashboard", requires: "resources",
          cards: [
            { type: "toggle", key: "bar.resources.alwaysShowRam", title: Translation.tr("RAM"), icon: "developer_board" },
            { type: "toggle", key: "bar.resources.alwaysShowDisk", title: Translation.tr("Disk"), icon: "hard_drive",
              kw: "usage of system drive on windows, root partition on linux" },
            { type: "toggle", os: "linux", key: "bar.resources.alwaysShowCpuTemp", title: Translation.tr("CPU temperature"), icon: "device_thermostat" },
            { type: "select", key: "bar.resources.style", title: Translation.tr("Style"), icon: "monitoring",
              options: [
                { displayName: Translation.tr("Filled"), icon: "incomplete_circle", value: "filled" },
                { displayName: Translation.tr("Outline"), icon: "circles", value: "outline" },
                { displayName: Translation.tr("Text"), icon: "text_fields", value: "text" }
              ] },
            { type: "toggle", key: "bar.resources.showValue", title: Translation.tr("Show percentage"), icon: "percent" },
            { type: "toggle", key: "bar.resources.alwaysShowCpu", title: Translation.tr("CPU"), icon: "memory" },
            { type: "toggle", key: "bar.resources.alwaysShowSwap", title: Translation.tr("Swap"), icon: "swap_horiz" },
            { type: "spin", key: "bar.resources.memoryWarningThreshold", title: Translation.tr("Memory warning threshold (%)"), icon: "memory",
              from: 0, to: 100, step: 5 },
            { type: "spin", key: "bar.resources.swapWarningThreshold", title: Translation.tr("Swap warning threshold (%)"), icon: "swap_horiz",
              from: 0, to: 100, step: 5 },
            { type: "spin", key: "bar.resources.cpuWarningThreshold", title: Translation.tr("CPU warning threshold (%)"), icon: "planner_review",
              from: 0, to: 100, step: 5 }
          ]
        },
        {
          page: Translation.tr("Bar"), title: Translation.tr("Media"), icon: "music_note",
          cards: [
            { type: "text", w: 2, key: "bar.media.preferredPlayer", title: Translation.tr("Preferred player"), icon: "play_circle",
              placeholder: "e.g. spotify, firefox", kw: "mpris spotify chrome firefox player music" },
            { type: "toggle", key: "bar.media.alwaysVisible", title: Translation.tr("Pin media controls"), icon: "push_pin",
              kw: "media controls stay open when clicking elsewhere" },
            { type: "toggle", key: "bar.media.showLyrics", title: Translation.tr("Show lyrics"), icon: "lyrics",
              kw: "synced lyrics in media controls, fetched from lrclib.net" },
            { type: "toggle", key: "bar.media.onlyTitle", title: Translation.tr("Only title"), icon: "title" },
            { type: "spin", key: "bar.media.maxWidth", title: Translation.tr("Max media width"), icon: "width",
              from: 100, to: 500, step: 10, kw: "enabled only on configurable layout" },
            { type: "spin", key: "bar.media.minWidth", title: Translation.tr("Min media width"), icon: "width_normal",
              from: 0, to: 500, step: 10, kw: "enabled only on configurable layout" }
          ]
        },
        {
          page: Translation.tr("Bar"), title: Translation.tr("Now Playing"), icon: "album",
          cards: [
            { type: "toggle", key: "media.nowPlaying.enable", title: Translation.tr("Show a pill when the track changes"), icon: "album" },
            { type: "spin", key: "custom:nowPlayingSecondsOnScreen", title: Translation.tr("Seconds on screen"), icon: "timer",
              from: 1, to: 10, step: 1 },
            { type: "spin", key: "media.nowPlaying.openDuration", title: Translation.tr("Opening animation (ms)"), icon: "slow_motion_video",
              from: 200, to: 3000, step: 100 },
            { type: "spin", key: "media.nowPlaying.closeDuration", title: Translation.tr("Closing animation (ms)"), icon: "speed",
              from: 200, to: 3000, step: 100 },
            { type: "toggle", key: "media.nowPlaying.flyFromBar", title: Translation.tr("Cover flies out of the bar"), icon: "flight" },
            { type: "spin", key: "media.nowPlaying.flyDuration", title: Translation.tr("Flight animation (ms)"), icon: "flight_takeoff",
              from: 200, to: 3000, step: 50 },
            { type: "spin", key: "media.nowPlaying.size", title: Translation.tr("Size (%)"), icon: "aspect_ratio",
              from: 60, to: 200, step: 10 },
            { type: "action", key: "custom:nowPlayingMove", title: Translation.tr("Move the pill"), icon: "drag_pan" },
            { type: "action", key: "custom:nowPlayingResetPosition", title: Translation.tr("Reset position"), icon: "restart_alt" }
          ]
        },
        {
          page: Translation.tr("Bar"), title: Translation.tr("AI Usage"), icon: "neurology", requires: "aiUsage",
          cards: [
            { type: "spin", key: "bar.aiUsage.tokenLimit", title: Translation.tr("Token limit per 5 hours"), icon: "token",
              from: 10000, to: 100000000, step: 100000 },
            { type: "spin", key: "bar.aiUsage.updateInterval", title: Translation.tr("Update interval (s)"), icon: "av_timer",
              from: 10, to: 3600, step: 10 }
          ]
        },
        {
          page: Translation.tr("Bar"), title: Translation.tr("Weather"), icon: "cloud", when: () => BarLayouts.classic,
          cards: [
            { type: "toggle", key: "bar.weather.enable", title: Translation.tr("Enable"), icon: "check" }
          ]
        },
        {
          page: Translation.tr("Bar"), title: Translation.tr("Tooltips"), icon: "tooltip",
          cards: [
            { type: "toggle", key: "bar.tooltips.enable", title: Translation.tr("Enable"), icon: "visibility" },
            { type: "toggle", key: "bar.tooltips.clickToShow", title: Translation.tr("Click to show"), icon: "ads_click",
              kw: "enabled only when tooltips are enabled" },
            { type: "select", key: "bar.tooltips.style", title: Translation.tr("Tooltip style"), icon: "tooltip",
              kw: "enabled only when tooltips are enabled",
              options: [
                { displayName: Translation.tr("Default"), icon: "tooltip", value: "default" },
                { displayName: Translation.tr("Morph"), icon: "join_inner", value: "morph" }
              ] }
          ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Wallpaper"), icon: "wallpaper",
            cards: [
            { type: "action", key: "custom:openWallpaperPicker", title: Translation.tr("Choose file"), icon: "wallpaper",
              kw: "pick wallpaper image on your system, ctrl+super+t" },
            { type: "action", key: "custom:randomWallpaperKonachan", title: Translation.tr("Random: Konachan"), icon: "ifl",
              when: () => Config.options.policies.weeb === 1,
              kw: "random anime wallpaper from konachan, saved to ~/Pictures/Wallpapers, weeb policy gate" },
            { type: "action", key: "custom:randomWallpaperOsu", title: Translation.tr("Random: osu! seasonal"), icon: "ifl",
              when: () => Config.options.policies.weeb === 1,
              kw: "random osu seasonal background, saved to ~/Pictures/Wallpapers, weeb policy gate" },
                { type: "page", pageId: "desktop", section: "Wallpaper",
                  title: Translation.tr("Wallpaper picker"), icon: "wallpaper",
                  kw: "wallpaper picker thumbnail main desktop lock screen per-desktop pick choose image preview collage click",
                  w: 2 },

                { type: "toggle", os: "windows", key: "background.desktopWallpapers.enable",
                  title: Translation.tr("A different wallpaper for each desktop"), icon: "view_carousel",
                  kw: "per desktop wallpaper windows" },

                { type: "toggle", key: "custom:syncWallpaper",
                  title: Translation.tr("Use same wallpaper for both"), icon: "sync" },

                { type: "toggle", key: "background.enableWallpaperPreview",
                  title: Translation.tr("Preview wallpaper"), icon: "preview" },

                { type: "combo", key: "background.wallpaperAnimation",
                  title: Translation.tr("Transitions"), icon: "animation",
                  options: [
                      { displayName: Translation.tr("None"), icon: "block", value: "" },
                      { displayName: Translation.tr("Circle"), icon: "circle", value: "circleSelect" },
                      { displayName: Translation.tr("Circle Pit"), icon: "blur_circular", value: "circlePit" },
                      { displayName: Translation.tr("Magic"), icon: "auto_awesome", value: "magic" },
                      { displayName: Translation.tr("Doom"), icon: "whatshot", value: "Doom" },
                      { displayName: Translation.tr("Peel"), icon: "layers", value: "Peel" },
                      { displayName: Translation.tr("Fade"), icon: "gradient", value: "transition" },
                      { displayName: Translation.tr("Pixelate"), icon: "grain", value: "pixelate" },
                      { displayName: Translation.tr("Stripes"), icon: "texture_minus", value: "stripes" },
                      { displayName: Translation.tr("CRT"), icon: "tv", value: "crt" },
                      { displayName: Translation.tr("Dissolve"), icon: "blur_on", value: "dissolve" },
                      { displayName: Translation.tr("Glitch"), icon: "bug_report", value: "glitch" },
                      { displayName: Translation.tr("Ripple"), icon: "water", value: "ripple" },
                      { displayName: Translation.tr("Shatter"), icon: "broken_image", value: "shatter" },
                      { displayName: Translation.tr("Colonies"), icon: "bubble_chart", value: "colonies" },
                      { displayName: Translation.tr("Pop ring"), icon: "radio_button_unchecked", value: "sekaiRing" },
                      { displayName: Translation.tr("Pop iris"), icon: "camera", value: "sekaiIris" },
                      { displayName: Translation.tr("Pop star"), icon: "star", value: "sekaiStar" },
                      { displayName: Translation.tr("Pop blocks"), icon: "grid_view", value: "sekaiBlocks" },
                      { displayName: Translation.tr("Random"), icon: "shuffle", value: "random" },
                  ] },

                { type: "toggle", key: "background.showBlur",
                  title: Translation.tr("Blur wall"), icon: "blur_on" },

                { type: "slider", key: "background.blurRadius",
                  title: Translation.tr("Blur Size"), icon: "blur_on", percent: false,
                  from: 1, to: 64, stops: [32] },

                { type: "select", key: "background.splitRatio",
                  title: Translation.tr("Split blur amount"), icon: "thumbnail_bar",
                  options: [
                      { displayName: "25%", icon: "thumbnail_bar", value: "25" },
                      { displayName: "50%", icon: "side_navigation", value: "50" },
                      { displayName: "100%", icon: "fullscreen", value: "100" },
                  ] },

                { type: "select", key: "background.splitSide",
                  title: Translation.tr("Split blur side"), icon: "align_horizontal_left",
                  options: [
                      { displayName: Translation.tr("Left"), icon: "align_horizontal_left", value: "left" },
                      { displayName: Translation.tr("Right"), icon: "align_horizontal_right", value: "right" },
                  ] },

                { type: "action", os: "windows", key: "custom:openLockScreenSettings",
                  when: () => !Config.options.background.lockScreenImageSupported,
                  title: Translation.tr("Open Windows lock screen settings"), icon: "open_in_new",
                  label: Translation.tr("Open Windows settings"),
                  kw: "lock screen image not supported windows settings personalization" },

                { type: "toggle", key: "background.hideWhenFullscreen",
                  title: Translation.tr("Hide when fullscreen"), icon: "fullscreen" },

                { type: "slider", os: "linux", key: "lock.blur.radius",
                  title: Translation.tr("Lock screen blur radius"), icon: "blur_on", percent: false,
                  from: 0, to: 250, stops: [100] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Centered wallpaper"), icon: "filter_center_focus",
            cards: [
                { type: "toggle", key: "background.centeredWallpaper",
                  title: Translation.tr("Enable"), icon: "wallpaper" },

                { type: "toggle", os: "linux", key: "background.centeredWallpaperOnlyWhenLocked",
                  title: Translation.tr("Only when locked"), icon: "lock",
                  when: () => Config.options.background.centeredWallpaper },

                { type: "shape", key: "background.centeredWallpaperShape",
                  when: () => Config.options.background.centeredWallpaper,
                  title: Translation.tr("Shape"), icon: "shapes",
                  options: ["Circle", "Square", "Slanted", "Arch", "Arrow", "SemiCircle", "Oval", "Pill",
                      "Triangle", "Diamond", "ClamShell", "Pentagon", "Gem", "Sunny", "VerySunny",
                      "Cookie4Sided", "Cookie6Sided", "Cookie7Sided", "Cookie9Sided", "Cookie12Sided",
                      "Ghostish", "Clover4Leaf", "Clover8Leaf", "Burst", "SoftBurst", "Flower",
                      "Puffy", "PuffyDiamond", "PixelCircle", "Bun", "Heart"] },

                { type: "swatch", w: 2, key: "background.centeredWallpaperColor",
                  when: () => Config.options.background.centeredWallpaper,
                  title: Translation.tr("Background Color"), icon: "palette",
                  colors: ["primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer", "layer1", "layer0"] },

                { type: "slider", key: "background.centeredWallpaperSize",
                  when: () => Config.options.background.centeredWallpaper,
                  title: Translation.tr("Size"), icon: "aspect_ratio", percent: false,
                  from: 400, to: 800, stops: [400] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Multiple wallpapers"), icon: "grid_view",
            cards: [
                { type: "toggle", key: "custom:collageEnable",
                  title: Translation.tr("Enable"), icon: "grid_view" },

                { type: "collagelayouts", key: "desktop:Collage layouts",
                  when: () => Config.options.background.collage.enable,
                  title: Translation.tr("Layouts"), icon: "dashboard_customize",
                  kw: "collage multiple wallpapers layout preset grid mosaic" },

                { type: "spin", key: "background.collage.gap",
                  when: () => Config.options.background.collage.enable,
                  title: Translation.tr("Gap"), icon: "space_bar",
                  from: 0, to: 80, step: 1 },

                { type: "spin", key: "background.collage.margin",
                  when: () => Config.options.background.collage.enable,
                  title: Translation.tr("Margin"), icon: "crop_free",
                  from: 0, to: 120, step: 1 },

                { type: "spin", key: "background.collage.radius",
                  when: () => Config.options.background.collage.enable,
                  title: Translation.tr("Corner radius"), icon: "rounded_corner",
                  from: 0, to: 60, step: 1 },

                { type: "action", key: "custom:collageReset",
                  when: () => Config.options.background.collage.enable,
                  title: Translation.tr("Reset"), icon: "restart_alt" },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Random Konachan wallpaper"), icon: "shuffle",
            when: () => Config.options.policies.weeb === 1,
            cards: [
                { type: "toggle", key: "custom:konachanSpicy",
                  title: Translation.tr("Spicy Stuff"), icon: "local_fire_department" },

                { type: "toggle", key: "background.konachanOnlyYuri",
                  title: Translation.tr("Only yuri"), icon: "favorite" },

                { type: "text", key: "background.konachanExtraTags",
                  title: Translation.tr("Extra tags"), icon: "sell", placeholder: Translation.tr("Extra tags") },

                { type: "action", key: "custom:confirmAge",
                  when: () => !SpicyStuff.allowed && SpicyStuff.needsAgeConfirmation,
                  title: Translation.tr("I'm 18 or older"), icon: "verified_user" },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Windows desktop"), icon: "desktop_windows", os: "windows",
            cards: [
                { type: "toggle", key: "windowsPort.backgroundBehindIcons",
                  title: Translation.tr("Put the background behind the desktop icons"), icon: "wallpaper" },

                { type: "toggle", key: "windowsPort.ownWallpaper",
                  title: Translation.tr("Draw ii's own wallpaper"), icon: "animation" },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Parallax"), icon: "sync_alt",
            cards: [
                { type: "toggle", key: "background.parallax.vertical",
                  title: Translation.tr("Vertical"), icon: "unfold_more_double" },

                { type: "toggle", key: "background.parallax.autoVertical",
                  title: Translation.tr("Automatic vertical"), icon: "screen_rotation" },

                { type: "toggle", key: "background.parallax.enableWorkspace",
                  title: Translation.tr("Depends on workspace"), icon: "counter_1" },

                { type: "toggle", key: "background.parallax.enableSidebar",
                  title: Translation.tr("Depends on sidebars"), icon: "side_navigation" },

                { type: "spin", key: "background.parallax.workspaceZoom", factor: 100,
                  title: Translation.tr("Preferred wallpaper zoom (%)"), icon: "loupe",
                  from: 10, to: 200, step: 1 },

                { type: "spin", key: "background.parallax.widgetsFactor", factor: 100,
                  title: Translation.tr("Widgets parallax strength (%)"), icon: "open_with",
                  from: 0, to: 300, step: 5 },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Clock"), icon: "schedule",
            cards: [
                { type: "toggle", key: "background.widgets.clock.enable",
                  title: Translation.tr("Enable"), icon: "schedule" },

                { type: "toggle", key: "background.widgets.clock.showOnlyWhenLocked",
                  title: Translation.tr("Show only when locked"), icon: "lock_clock" },

                { type: "select", key: "background.widgets.clock.placementStrategy",
                  title: Translation.tr("Placement strategy"), icon: "move",
                  options: [
                      { displayName: Translation.tr("Draggable"), icon: "drag_pan", value: "free" },
                      { displayName: Translation.tr("Least busy"), icon: "category", value: "leastBusy" },
                      { displayName: Translation.tr("Most busy"), icon: "shapes", value: "mostBusy" },
                  ] },

                { type: "select", key: "background.widgets.clock.style",
                  title: Translation.tr("Clock style"), icon: "nest_clock_farsight_analog",
                  options: [
                      { displayName: Translation.tr("Digital"), icon: "timer_10", value: "digital" },
                      { displayName: Translation.tr("Cookie"), icon: "cookie", value: "cookie" },
                      { displayName: Translation.tr("Pixel"), icon: "grid_view", value: "pixel" },
                      { displayName: Translation.tr("Big date"), icon: "today", value: "bigDate" },
                  ] },

                { type: "select", key: "background.widgets.clock.styleLocked",
                  title: Translation.tr("Clock style (locked)"), icon: "shield_watch",
                  options: [
                      { displayName: Translation.tr("Digital"), icon: "timer_10", value: "digital" },
                      { displayName: Translation.tr("Cookie"), icon: "cookie", value: "cookie" },
                      { displayName: Translation.tr("Pixel"), icon: "grid_view", value: "pixel" },
                      { displayName: Translation.tr("Big date"), icon: "today", value: "bigDate" },
                  ] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Pixel clock"), icon: "grid_view",
            when: () => Config.options.background.widgets.clock.style === "pixel",
            cards: [
                { type: "select", key: "background.widgets.clock.pixel.orientation",
                  title: Translation.tr("Pixel clock orientation"), icon: "screen_rotation",
                  options: [
                      { displayName: Translation.tr("Horizontal"), icon: "swap_horiz", value: "horizontal" },
                      { displayName: Translation.tr("Vertical"), icon: "swap_vert", value: "vertical" },
                  ] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Digital clock"), icon: "timer_10",
            when: () => (!Config.options.background.widgets.clock.showOnlyWhenLocked && Config.options.background.widgets.clock.style === "digital") || Config.options.background.widgets.clock.styleLocked === "digital",
            cards: [
                { type: "toggle", key: "background.widgets.clock.digital.vertical",
                  title: Translation.tr("Vertical"), icon: "vertical_distribute" },

                { type: "toggle", key: "background.widgets.clock.digital.animateChange",
                  title: Translation.tr("Animate time change"), icon: "animation" },

                { type: "toggle", key: "background.widgets.clock.digital.showDate",
                  title: Translation.tr("Show date"), icon: "date_range" },

                { type: "toggle", key: "background.widgets.clock.digital.adaptiveAlignment",
                  title: Translation.tr("Use adaptive alignment"), icon: "activity_zone" },

                { type: "select", key: "background.widgets.clock.color",
                  title: Translation.tr("Clock color"), icon: "format_color_fill",
                  options: [
                      { displayName: Translation.tr("Automatic"), icon: "wallpaper", value: "" },
                      { displayName: Translation.tr("Accent"), icon: "palette", value: "primary" },
                      { displayName: Translation.tr("Text"), icon: "format_color_text", value: "onLayer0" },
                  ] },

                { type: "combo", key: "custom:clockFontFamily",
                  title: Translation.tr("Font family"), icon: "font_download" },

                { type: "slider", key: "background.widgets.clock.digital.font.weight",
                  title: Translation.tr("Font weight"), icon: "format_bold", percent: false,
                  from: 1, to: 1000, stops: [350] },

                { type: "slider", key: "background.widgets.clock.digital.font.size",
                  title: Translation.tr("Font size"), icon: "format_size", percent: false,
                  from: 50, to: 700, stops: [90] },

                { type: "slider", key: "background.widgets.clock.digital.font.width",
                  title: Translation.tr("Font width"), icon: "fit_width", percent: false,
                  from: 25, to: 125, stops: [100] },

                { type: "slider", key: "background.widgets.clock.digital.font.roundness",
                  title: Translation.tr("Font roundness"), icon: "line_curve", percent: false,
                  from: 0, to: 100, stops: [] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Cookie clock"), icon: "cookie",
            when: () => (!Config.options.background.widgets.clock.showOnlyWhenLocked && Config.options.background.widgets.clock.style === "cookie") || Config.options.background.widgets.clock.styleLocked === "cookie",
            cards: [
                { type: "toggle", key: "background.widgets.clock.cookie.aiStyling",
                  title: Translation.tr("Auto styling with Gemini"), icon: "wand_stars" },

                { type: "toggle", key: "background.widgets.clock.cookie.useSineCookie",
                  title: Translation.tr("Use old sine wave cookie implementation"), icon: "airwave" },

                { type: "spin", key: "background.widgets.clock.cookie.sides",
                  title: Translation.tr("Sides"), icon: "add_triangle",
                  from: 0, to: 40, step: 1 },

                { type: "toggle", key: "background.widgets.clock.cookie.constantlyRotate",
                  title: Translation.tr("Constantly rotate"), icon: "autoplay" },

                { type: "toggle", key: "background.widgets.clock.cookie.hourMarks",
                  title: Translation.tr("Hour marks"), icon: "brightness_7" },

                { type: "toggle", key: "background.widgets.clock.cookie.timeIndicators",
                  title: Translation.tr("Digits in the middle"), icon: "timer_10" },

                { type: "select", key: "custom:cookieDialStyle",
                  title: Translation.tr("Dial style"), icon: "history_toggle_off" },

                { type: "select", key: "background.widgets.clock.cookie.hourHandStyle",
                  title: Translation.tr("Hour hand"), icon: "schedule",
                  options: [
                      { displayName: "", icon: "block", value: "hide" },
                      { displayName: Translation.tr("Classic"), icon: "radio", value: "classic" },
                      { displayName: Translation.tr("Hollow"), icon: "circle", value: "hollow" },
                      { displayName: Translation.tr("Fill"), icon: "eraser_size_5", value: "fill" },
                  ] },

                { type: "select", key: "background.widgets.clock.cookie.minuteHandStyle",
                  title: Translation.tr("Minute hand"), icon: "schedule",
                  options: [
                      { displayName: "", icon: "block", value: "hide" },
                      { displayName: Translation.tr("Classic"), icon: "radio", value: "classic" },
                      { displayName: Translation.tr("Thin"), icon: "line_end", value: "thin" },
                      { displayName: Translation.tr("Medium"), icon: "eraser_size_2", value: "medium" },
                      { displayName: Translation.tr("Bold"), icon: "eraser_size_4", value: "bold" },
                  ] },

                { type: "select", key: "background.widgets.clock.cookie.secondHandStyle",
                  title: Translation.tr("Second hand"), icon: "schedule",
                  options: [
                      { displayName: "", icon: "block", value: "hide" },
                      { displayName: Translation.tr("Classic"), icon: "radio", value: "classic" },
                      { displayName: Translation.tr("Line"), icon: "line_end", value: "line" },
                      { displayName: Translation.tr("Dot"), icon: "adjust", value: "dot" },
                  ] },

                { type: "select", key: "background.widgets.clock.cookie.dateStyle",
                  title: Translation.tr("Date style"), icon: "calendar_today",
                  options: [
                      { displayName: "", icon: "block", value: "hide" },
                      { displayName: Translation.tr("Bubble"), icon: "bubble_chart", value: "bubble" },
                      { displayName: Translation.tr("Border"), icon: "rotate_right", value: "border" },
                      { displayName: Translation.tr("Rect"), icon: "rectangle", value: "rect" },
                  ] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Quote"), icon: "format_quote",
            cards: [
                { type: "toggle", key: "background.widgets.clock.quote.enable",
                  title: Translation.tr("Enable"), icon: "format_quote" },

                { type: "toggle", key: "background.widgets.clock.quote.followClock",
                  title: Translation.tr("Follow clock font"), icon: "font_download" },

                { type: "text", key: "background.widgets.clock.quote.text", w: 2,
                  title: Translation.tr("Quote"), icon: "format_quote", placeholder: Translation.tr("Quote") },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Desktop widgets"), icon: "widgets",
            cards: [
                { type: "widgets", key: "desktop:Widgets",
                  title: Translation.tr("Desktop widgets"), icon: "widgets",
                  kw: "widgets desktop weather resources calendar custom text image card sticker images converter media notes quote greeting timers todo user card visualizer world clock enable disable toggle grid menu" },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Canvas"), icon: "drag_pan",
            cards: [
                { type: "page", pageId: "desktop", section: "Desktop widgets", subsection: "Show widgets on",
                  title: Translation.tr("Show widgets on"), icon: "tv_displays",
                  kw: "screen monitor display widgets show all per-monitor desktop",
                  w: 2 },

                { type: "toggle", key: "background.showGrid",
                  title: Translation.tr("Show grid while dragging"), icon: "grid_on" },

                { type: "toggle", key: "background.showSnapLines",
                  title: Translation.tr("Show snap lines"), icon: "straighten" },

                { type: "toggle", key: "background.widgetsLocked",
                  title: Translation.tr("Lock widget positions"), icon: "lock" },

                { type: "toggle", os: "linux", key: "background.widgets.shadow",
                  title: Translation.tr("Widget shadows"), icon: "shadow" },

                { type: "toggle", key: "lock.showWidgets",
                  title: Translation.tr("Show widgets on the lock screen"), icon: "lock_person" },

                { type: "toggle", os: "linux", key: "background.widgets.blurWidgets",
                  title: Translation.tr("Blur widget backgrounds"), icon: "blur_on" },

                { type: "slider", os: "linux", key: "background.widgets.blurRadius",
                  when: () => Config.options.background.widgets.blurWidgets,
                  title: Translation.tr("Widget blur radius"), icon: "aspect_ratio", percent: false,
                  from: 1, to: 64, stops: [32] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Widget: Calendar"), icon: "calendar_month",
            cards: [
                { type: "toggle", key: "background.widgets.calendar.enable", title: Translation.tr("Enable"), icon: "calendar_month" },
                { type: "select", key: "background.widgets.calendar.sizeMode",
                  title: Translation.tr("Size"), icon: "aspect_ratio",
                  options: [
                      { displayName: "1×1", icon: "crop_square", value: "1x1" },
                      { displayName: "1×2", icon: "crop_landscape", value: "1x2" },
                      { displayName: "2×2", icon: "crop_square", value: "2x2" },
                      { displayName: "2×3", icon: "crop_portrait", value: "2x3" },
                  ] },

                { type: "select", key: "background.widgets.calendar.placementStrategy",
                  title: Translation.tr("Calendar"), icon: "calendar_month",
                  options: [
                      { displayName: Translation.tr("Draggable"), icon: "drag_pan", value: "free" },
                      { displayName: Translation.tr("Least busy"), icon: "category", value: "leastBusy" },
                      { displayName: Translation.tr("Most busy"), icon: "shapes", value: "mostBusy" },
                  ] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Text"), icon: "text_fields",
            cards: [
                { type: "toggle", key: "background.widgets.customText.enable", title: Translation.tr("Enable"), icon: "text_fields" },
                { type: "text", key: "background.widgets.customText.content", w: 2,
                  title: Translation.tr("Text to display"), icon: "edit", placeholder: Translation.tr("Content") },

                { type: "text", key: "background.widgets.customText.fontFamily",
                  title: Translation.tr("Font family"), icon: "font_download", placeholder: Translation.tr("Font family") },

                { type: "select", key: "background.widgets.customText.alignment",
                  title: Translation.tr("Alignment"), icon: "format_align_center",
                  options: [
                      { displayName: "", icon: "format_align_left", value: "left" },
                      { displayName: "", icon: "format_align_center", value: "center" },
                      { displayName: "", icon: "format_align_right", value: "right" },
                  ] },

                { type: "slider", key: "background.widgets.customText.fontSize",
                  title: Translation.tr("Font size"), icon: "format_size", percent: false,
                  from: 12, to: 400, stops: [72] },

                { type: "toggle", os: "linux", key: "background.widgets.customText.shadow",
                  title: Translation.tr("Shadow"), icon: "shadow" },

                { type: "select", key: "background.widgets.customText.placementStrategy",
                  title: Translation.tr("Custom text"), icon: "text_fields",
                  options: [
                      { displayName: Translation.tr("Draggable"), icon: "drag_pan", value: "free" },
                      { displayName: Translation.tr("Least busy"), icon: "category", value: "leastBusy" },
                      { displayName: Translation.tr("Most busy"), icon: "shapes", value: "mostBusy" },
                  ] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Custom image"), icon: "imagesmode",
            cards: [
                { type: "toggle", key: "background.widgets.customImage.enable", title: Translation.tr("Enable"), icon: "imagesmode" },
                { type: "text", key: "background.widgets.customImage.path", w: 2,
                  title: Translation.tr("Image path"), icon: "folder_open", placeholder: Translation.tr("Or drop an image on the widget") },

                { type: "select", key: "background.widgets.customImage.shape",
                  title: Translation.tr("Shape"), icon: "category",
                  options: [
                      { displayName: "", icon: "circle", value: "Circle" },
                      { displayName: "", icon: "square", value: "Square" },
                      { displayName: "", icon: "cookie", value: "Cookie4Sided" },
                      { displayName: "", icon: "cookie", value: "Cookie7Sided" },
                      { displayName: "", icon: "bubble_chart", value: "Oval" },
                      { displayName: "", icon: "favorite", value: "Heart" },
                  ] },

                { type: "slider", key: "background.widgets.customImage.size",
                  title: Translation.tr("Size"), icon: "aspect_ratio", percent: false,
                  from: 80, to: 500, stops: [200] },

                { type: "select", key: "background.widgets.customImage.placementStrategy",
                  title: Translation.tr("Custom image"), icon: "sticky_note_2",
                  options: [
                      { displayName: Translation.tr("Draggable"), icon: "drag_pan", value: "free" },
                      { displayName: Translation.tr("Least busy"), icon: "category", value: "leastBusy" },
                      { displayName: Translation.tr("Most busy"), icon: "shapes", value: "mostBusy" },
                  ] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Widget: Image card"), icon: "image",
            cards: [
                { type: "toggle", key: "background.widgets.imageCard.enable", title: Translation.tr("Enable"), icon: "image" },
                { type: "text", key: "background.widgets.imageCard.path", w: 2,
                  title: Translation.tr("Image path"), icon: "folder_open", placeholder: Translation.tr("Or drop an image on the widget") },

                { type: "select", key: "background.widgets.imageCard.sizeMode",
                  title: Translation.tr("Size"), icon: "aspect_ratio",
                  options: [
                      { displayName: "1×1", icon: "crop_square", value: "1x1" },
                      { displayName: "1×2", icon: "crop_landscape", value: "1x2" },
                      { displayName: "2×2", icon: "crop_square", value: "2x2" },
                      { displayName: "2×3", icon: "crop_portrait", value: "2x3" },
                  ] },

                { type: "select", key: "background.widgets.imageCard.placementStrategy",
                  title: Translation.tr("Image card"), icon: "image",
                  options: [
                      { displayName: Translation.tr("Draggable"), icon: "drag_pan", value: "free" },
                      { displayName: Translation.tr("Least busy"), icon: "category", value: "leastBusy" },
                      { displayName: Translation.tr("Most busy"), icon: "shapes", value: "mostBusy" },
                  ] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Widget: Sticker"), icon: "sticky_note_2",
            cards: [
                { type: "toggle", key: "background.widgets.sticker.enable", title: Translation.tr("Enable"), icon: "sticky_note_2" },
                { type: "text", key: "background.widgets.sticker.path", w: 2,
                  title: Translation.tr("Image path"), icon: "folder_open", placeholder: Translation.tr("Or drop an image on the widget") },

                { type: "slider", key: "background.widgets.sticker.size",
                  title: Translation.tr("Size"), icon: "aspect_ratio", percent: false,
                  from: 60, to: 500, stops: [200] },

                { type: "slider", key: "background.widgets.sticker.outlineWidth",
                  title: Translation.tr("Outline width"), icon: "line_weight", percent: false,
                  from: 0, to: 24, stops: [8] },

                { type: "text", key: "background.widgets.sticker.outlineColor",
                  title: Translation.tr("Outline color"), icon: "format_color_fill", placeholder: "#ffffff" },

                { type: "select", key: "background.widgets.sticker.placementStrategy",
                  title: Translation.tr("Sticker"), icon: "sticky_note_2",
                  options: [
                      { displayName: Translation.tr("Draggable"), icon: "drag_pan", value: "free" },
                      { displayName: Translation.tr("Least busy"), icon: "category", value: "leastBusy" },
                      { displayName: Translation.tr("Most busy"), icon: "shapes", value: "mostBusy" },
                  ] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Widget: Image converter"), icon: "transform",
            cards: [
                { type: "toggle", key: "background.widgets.images.enable", title: Translation.tr("Enable"), icon: "transform" },
                { type: "select", key: "background.widgets.images.placementStrategy",
                  title: Translation.tr("Image converter"), icon: "transform",
                  options: [
                      { displayName: Translation.tr("Draggable"), icon: "drag_pan", value: "free" },
                      { displayName: Translation.tr("Least busy"), icon: "category", value: "leastBusy" },
                      { displayName: Translation.tr("Most busy"), icon: "shapes", value: "mostBusy" },
                  ] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Widget: Weather"), icon: "weather_mix",
            cards: [
                { type: "toggle", key: "background.widgets.weather.enable", title: Translation.tr("Enable"), icon: "weather_mix" },
                { type: "select", key: "background.widgets.weather.sizeMode",
                  title: Translation.tr("Size"), icon: "aspect_ratio",
                  options: [
                      { displayName: "1×1", icon: "crop_square", value: "1x1" },
                      { displayName: "1×2", icon: "crop_landscape", value: "1x2" },
                      { displayName: "1×3", icon: "crop_landscape", value: "1x3" },
                      { displayName: "2×2", icon: "crop_square", value: "2x2" },
                      { displayName: "2×3", icon: "crop_portrait", value: "2x3" },
                  ] },

                { type: "select", key: "background.widgets.weather.placementStrategy",
                  title: Translation.tr("Weather"), icon: "weather_mix",
                  options: [
                      { displayName: Translation.tr("Draggable"), icon: "drag_pan", value: "free" },
                      { displayName: Translation.tr("Least busy"), icon: "category", value: "leastBusy" },
                      { displayName: Translation.tr("Most busy"), icon: "shapes", value: "mostBusy" },
                  ] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Widget: Resources"), icon: "memory",
            cards: [
                { type: "toggle", key: "background.widgets.resources.enable", title: Translation.tr("Enable"), icon: "memory" },
                { type: "toggle", key: "background.widgets.resources.vertical",
                  title: Translation.tr("Stack vertically"), icon: "swap_horiz" },

                { type: "select", key: "background.widgets.resources.placementStrategy",
                  title: Translation.tr("Resources"), icon: "memory",
                  options: [
                      { displayName: Translation.tr("Draggable"), icon: "drag_pan", value: "free" },
                      { displayName: Translation.tr("Least busy"), icon: "category", value: "leastBusy" },
                      { displayName: Translation.tr("Most busy"), icon: "shapes", value: "mostBusy" },
                  ] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Widget: Media"), icon: "music_note",
            cards: [
                { type: "toggle", key: "background.widgets.media.enable", title: Translation.tr("Enable"), icon: "music_note" },
                { type: "select", key: "background.widgets.media.sizeMode",
                  title: Translation.tr("Size"), icon: "aspect_ratio",
                  options: [
                      { displayName: "1×1", icon: "crop_square", value: "1x1" },
                      { displayName: "1×2", icon: "crop_landscape", value: "1x2" },
                      { displayName: "2×2", icon: "crop_square", value: "2x2" },
                      { displayName: "1×3", icon: "crop_landscape", value: "1x3" },
                  ] },

                { type: "toggle", key: "background.widgets.media.showControls",
                  title: Translation.tr("Show controls"), icon: "tune" },

                { type: "toggle", key: "background.widgets.media.showTitles",
                  title: Translation.tr("Show titles"), icon: "title" },

                { type: "select", key: "background.widgets.media.backgroundShape",
                  title: Translation.tr("Background shape"), icon: "cookie",
                  options: [
                      { displayName: "", icon: "square", value: "Square" },
                      { displayName: "", icon: "cookie", value: "Cookie4Sided" },
                      { displayName: "", icon: "cookie", value: "Cookie7Sided" },
                      { displayName: "", icon: "cookie", value: "Cookie12Sided" },
                  ] },

                { type: "select", key: "background.widgets.media.placementStrategy",
                  title: Translation.tr("Media"), icon: "music_note",
                  options: [
                      { displayName: Translation.tr("Draggable"), icon: "drag_pan", value: "free" },
                      { displayName: Translation.tr("Least busy"), icon: "category", value: "leastBusy" },
                      { displayName: Translation.tr("Most busy"), icon: "shapes", value: "mostBusy" },
                  ] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Widget: Notes"), icon: "sticky_note_2",
            cards: [
                { type: "toggle", key: "background.widgets.notes.enable", title: Translation.tr("Enable"), icon: "sticky_note_2" },
                { type: "select", key: "background.widgets.notes.placementStrategy",
                  title: Translation.tr("Notes"), icon: "sticky_note_2",
                  options: [
                      { displayName: Translation.tr("Draggable"), icon: "drag_pan", value: "free" },
                      { displayName: Translation.tr("Least busy"), icon: "category", value: "leastBusy" },
                      { displayName: Translation.tr("Most busy"), icon: "shapes", value: "mostBusy" },
                  ] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Widget: Timers"), icon: "timer",
            cards: [
                { type: "toggle", key: "background.widgets.timers.enable", title: Translation.tr("Enable"), icon: "timer" },
                { type: "toggle", key: "background.widgets.timers.vertical",
                  title: Translation.tr("Stack vertically"), icon: "swap_horiz" },

                { type: "select", key: "background.widgets.timers.placementStrategy",
                  title: Translation.tr("Timers"), icon: "timer",
                  options: [
                      { displayName: Translation.tr("Draggable"), icon: "drag_pan", value: "free" },
                      { displayName: Translation.tr("Least busy"), icon: "category", value: "leastBusy" },
                      { displayName: Translation.tr("Most busy"), icon: "shapes", value: "mostBusy" },
                  ] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Widget: User card"), icon: "badge",
            cards: [
                { type: "toggle", key: "background.widgets.userCard.enable", title: Translation.tr("Enable"), icon: "badge" },
                { type: "select", key: "background.widgets.userCard.sizeMode",
                  title: Translation.tr("Size"), icon: "aspect_ratio",
                  options: [
                      { displayName: "1×1", icon: "crop_square", value: "1x1" },
                      { displayName: "1×2", icon: "crop_landscape", value: "1x2" },
                      { displayName: "2×2", icon: "crop_square", value: "2x2" },
                      { displayName: "2×3", icon: "crop_portrait", value: "2x3" },
                  ] },

                { type: "select", key: "background.widgets.userCard.placementStrategy",
                  title: Translation.tr("User card"), icon: "badge",
                  options: [
                      { displayName: Translation.tr("Draggable"), icon: "drag_pan", value: "free" },
                      { displayName: Translation.tr("Least busy"), icon: "category", value: "leastBusy" },
                      { displayName: Translation.tr("Most busy"), icon: "shapes", value: "mostBusy" },
                  ] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Visualizer"), icon: "graphic_eq",
            cards: [
                { type: "toggle", key: "background.widgets.visualizer.enable", title: Translation.tr("Enable"), icon: "graphic_eq" },
                { type: "select", key: "background.widgets.visualizer.style",
                  title: Translation.tr("Style"), icon: "equalizer",
                  options: [
                      { displayName: Translation.tr("Bars"), icon: "bar_chart", value: "bars" },
                      { displayName: Translation.tr("Mirror"), icon: "flip", value: "mirror" },
                      { displayName: Translation.tr("Aurora"), icon: "gradient", value: "aurora" },
                      { displayName: Translation.tr("Ring"), icon: "data_usage", value: "ring" },
                      { displayName: Translation.tr("Dots"), icon: "grain", value: "dots" },
                  ] },

                { type: "select", key: "background.widgets.visualizer.colorSource",
                  title: Translation.tr("Colors"), icon: "palette",
                  options: [
                      { displayName: Translation.tr("Theme"), icon: "palette", value: "theme" },
                      { displayName: Translation.tr("Album cover"), icon: "album", value: "cover" },
                  ] },

                { type: "slider", key: "background.widgets.visualizer.sensitivity", factor: 100,
                  title: Translation.tr("Sensitivity (%)"), icon: "speed", percent: false,
                  from: 10, to: 300, stops: [100] },

                { type: "select", key: "background.widgets.visualizer.placementStrategy",
                  title: Translation.tr("Visualizer"), icon: "graphic_eq",
                  options: [
                      { displayName: Translation.tr("Draggable"), icon: "drag_pan", value: "free" },
                      { displayName: Translation.tr("Least busy"), icon: "category", value: "leastBusy" },
                      { displayName: Translation.tr("Most busy"), icon: "shapes", value: "mostBusy" },
                  ] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Widget: World clock"), icon: "public",
            cards: [
                { type: "toggle", key: "background.widgets.worldClock.enable", title: Translation.tr("Enable"), icon: "public" },
                { type: "select", key: "background.widgets.worldClock.sizeMode",
                  title: Translation.tr("Size"), icon: "aspect_ratio",
                  options: [
                      { displayName: "2×2", icon: "crop_square", value: "2x2" },
                      { displayName: "4×1", icon: "view_column", value: "4x1" },
                  ] },

                { type: "toggle", key: "background.widgets.worldClock.vertical",
                  title: Translation.tr("Stack vertically"), icon: "swap_horiz" },

                { type: "spin", key: "background.widgets.worldClock.clockCount",
                  title: Translation.tr("Clocks shown"), icon: "numbers",
                  from: 1, to: 4, step: 1 },

                { type: "select", key: "background.widgets.worldClock.placementStrategy",
                  title: Translation.tr("World clock"), icon: "public",
                  options: [
                      { displayName: Translation.tr("Draggable"), icon: "drag_pan", value: "free" },
                      { displayName: Translation.tr("Least busy"), icon: "category", value: "leastBusy" },
                      { displayName: Translation.tr("Most busy"), icon: "shapes", value: "mostBusy" },
                  ] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Widget: Quote"), icon: "format_quote",
            cards: [
                { type: "toggle", key: "background.widgets.quote.enable",
                  title: Translation.tr("Enable"), icon: "check" },

                { type: "select", key: "background.widgets.quote.placementStrategy",
                  title: Translation.tr("Placement strategy"), icon: "move",
                  options: [
                      { displayName: Translation.tr("Draggable"), icon: "drag_pan", value: "free" },
                      { displayName: Translation.tr("Least busy"), icon: "category", value: "leastBusy" },
                      { displayName: Translation.tr("Most busy"), icon: "shapes", value: "mostBusy" },
                  ] },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Widget: Greeting"), icon: "waving_hand",
            cards: [
                { type: "toggle", key: "background.widgets.greeting.enable",
                  title: Translation.tr("Enable"), icon: "check" },

                { type: "select", key: "background.widgets.greeting.placementStrategy",
                  title: Translation.tr("Placement strategy"), icon: "move",
                  options: [
                      { displayName: Translation.tr("Draggable"), icon: "drag_pan", value: "free" },
                      { displayName: Translation.tr("Least busy"), icon: "category", value: "leastBusy" },
                      { displayName: Translation.tr("Most busy"), icon: "shapes", value: "mostBusy" },
                  ] },

                { type: "text", key: "background.widgets.greeting.name", w: 2,
                  title: Translation.tr("Name"), icon: "badge", placeholder: Translation.tr("Leave empty to use your account name") },
            ]
        },
        {
            page: Translation.tr("Desktop"), title: Translation.tr("Widget: Todo"), icon: "checklist",
            cards: [
                { type: "toggle", key: "background.widgets.todo.enable", title: Translation.tr("Enable"), icon: "checklist" },
                { type: "select", key: "background.widgets.todo.placementStrategy",
                  title: Translation.tr("To-Do"), icon: "checklist",
                  options: [
                      { displayName: Translation.tr("Draggable"), icon: "drag_pan", value: "free" },
                      { displayName: Translation.tr("Least busy"), icon: "category", value: "leastBusy" },
                      { displayName: Translation.tr("Most busy"), icon: "shapes", value: "mostBusy" },
                  ] },
            ]
        },
        {
          page: Translation.tr("System"), title: Translation.tr("Windows taskbar"), icon: "toolbar", os: "windows", cards: [
            { type: "toggle", key: "windowsPort.nativeTaskbar", title: Translation.tr("Use the Windows taskbar instead of ii's bar"), icon: "dock_to_bottom" },
            { type: "toggle", key: "windowsPort.taskbarHoverOnly", title: Translation.tr("Show only when the cursor touches its screen edge"), icon: "web_traffic", when: () => !Config.options.windowsPort.nativeTaskbar }
          ]
        },
        {
          page: Translation.tr("System"), title: Translation.tr("Windows tiling"), icon: "dashboard", os: "windows", cards: [
            { type: "toggle", key: "windowsPort.tiling.enable", title: Translation.tr("Tile windows"), icon: "grid_view" },
            { type: "toggle", key: "windowsPort.superDrag", title: Translation.tr("Super + drag moves and resizes windows"), icon: "open_with" },
            { type: "spin", key: "windowsPort.tiling.gapsIn", title: Translation.tr("Gap between windows (px)"), icon: "space_bar", from: 0, to: 64, step: 1 },
            { type: "spin", key: "windowsPort.tiling.gapsOut", title: Translation.tr("Gap to screen edges (px)"), icon: "space_dashboard", from: 0, to: 64, step: 1 },
            { type: "toggle", key: "windowsPort.tiling.preserveSplit", title: Translation.tr("Keep each split's direction"), icon: "splitscreen" },
            { type: "page", w: 2, pageId: "interface", section: "Windows tiling", title: Translation.tr("Apps that always float"), icon: "open_in_full", subtitle: Translation.tr("One per line: process name (notepad.exe), app id, window class, or title:<pattern>"), kw: "tiling exclude float always apps process window class title" }
          ]
        },
        {
            page: Translation.tr("System"), title: Translation.tr("Displays"), icon: "monitor", os: "windows",
            cards: [
                { type: "page", pageId: "system", section: "Displays", title: Translation.tr("Displays"), icon: "monitor", w: 2,
                  kw: "display monitor resolution refresh rate rotation scale hdr sdr brightness screen enabled primary main" }
            ]
        },
        {
            page: Translation.tr("System"), title: Translation.tr("Layout"), icon: "dashboard_customize", os: "windows",
            cards: [
                { type: "select", key: "custom:sysTilingLayout", title: Translation.tr("Tiling Layout"), icon: "browse",
                  kw: "dwindle master scrolling tiling layout window manager" }
            ]
        },
        {
            page: Translation.tr("System"), title: Translation.tr("Dwindle"), icon: "browse", os: "windows",
            when: () => !["master", "scrolling"].includes(Config.options.hyprland.general.layout),
            cards: [
                { type: "toggle", key: "windowsPort.tiling.smartSplit", title: Translation.tr("Smart split (follow the cursor)"), icon: "smart_toy" },
                { type: "select", key: "windowsPort.tiling.forceSplit", title: Translation.tr("Force split side"), icon: "splitscreen",
                  options: [
                      { displayName: Translation.tr("Auto"), icon: "auto_mode", value: 0 },
                      { displayName: Translation.tr("Left / top"), icon: "align_horizontal_left", value: 1 },
                      { displayName: Translation.tr("Right / bottom"), icon: "align_horizontal_right", value: 2 }
                  ] },
                { type: "spin", key: "windowsPort.tiling.defaultSplitRatio", title: Translation.tr("Default split ratio (%)"), icon: "percent",
                  from: 5, to: 95, step: 5, factor: 50 }
            ]
        },
        {
            page: Translation.tr("System"), title: Translation.tr("Master"), icon: "auto_awesome_mosaic", os: "windows",
            when: () => Config.options.hyprland.general.layout === "master",
            cards: [
                { type: "select", key: "windowsPort.tiling.master.newStatus", title: Translation.tr("New windows become"), icon: "add_box",
                  options: [
                      { displayName: Translation.tr("Master"), icon: "star", value: "master" },
                      { displayName: Translation.tr("Slave"), icon: "view_agenda", value: "slave" },
                      { displayName: Translation.tr("Inherit"), icon: "content_copy", value: "inherit" }
                  ] },
                { type: "toggle", key: "windowsPort.tiling.master.newOnTop", title: Translation.tr("New windows go on top of the stack"), icon: "vertical_align_top" },
                { type: "select", key: "windowsPort.tiling.master.orientation", title: Translation.tr("Master position"), icon: "screen_rotation",
                  options: [
                      { displayName: Translation.tr("Left"), icon: "align_horizontal_left", value: "left" },
                      { displayName: Translation.tr("Right"), icon: "align_horizontal_right", value: "right" },
                      { displayName: Translation.tr("Top"), icon: "align_vertical_top", value: "top" },
                      { displayName: Translation.tr("Bottom"), icon: "align_vertical_bottom", value: "bottom" },
                      { displayName: Translation.tr("Center"), icon: "align_horizontal_center", value: "center" }
                  ] },
                { type: "spin", key: "windowsPort.tiling.master.mfact", title: Translation.tr("Master size"), icon: "aspect_ratio",
                  from: 10, to: 90, step: 5, factor: 100 }
            ]
        },
        {
            page: Translation.tr("System"), title: Translation.tr("Scrolling"), icon: "view_carousel", os: "windows",
            when: () => Config.options.hyprland.general.layout === "scrolling",
            cards: [
                { type: "select", key: "windowsPort.tiling.scrolling.columnWidth", title: Translation.tr("New column width"), icon: "view_column",
                  options: [
                      { displayName: "1/3", icon: "view_week", value: 1 / 3 },
                      { displayName: "1/2", icon: "width_normal", value: 0.5 },
                      { displayName: "2/3", icon: "width_wide", value: 2 / 3 },
                      { displayName: Translation.tr("Full width"), icon: "width_full", value: 1 }
                  ] },
                { type: "text", key: "custom:sysScrollingWidthPresets", title: Translation.tr("Width presets"), icon: "width_normal", w: 2,
                  placeholder: "33, 50, 67, 100", kw: "scrolling column width presets percent niri" },
                { type: "select", key: "windowsPort.tiling.scrolling.center", title: Translation.tr("Center the focused column"), icon: "center_focus_strong",
                  options: [
                      { displayName: Translation.tr("When it doesn't fit"), icon: "fit_screen", value: "overflow" },
                      { displayName: Translation.tr("Always"), icon: "align_horizontal_center", value: "always" },
                      { displayName: Translation.tr("Never"), icon: "align_horizontal_left", value: "never" }
                  ] }
            ]
        },
        {
            page: Translation.tr("System"), title: Translation.tr("Borders and corners"), icon: "border_outer", os: "windows",
            when: () => parseInt(SystemInfo.windowsBuild) >= 22000,
            cards: [
                { type: "select", key: "custom:sysWindowBorders", title: Translation.tr("Window borders"), icon: "border_outer",
                  kw: "border system palette colors none dwm" },
                { type: "select", key: "windowsPort.decoration.corners", title: Translation.tr("Window corners"), icon: "rounded_corner",
                  options: [
                      { displayName: Translation.tr("Default"), icon: "settings_backup_restore", value: "default" },
                      { displayName: Translation.tr("Rounded"), icon: "rounded_corner", value: "round" },
                      { displayName: Translation.tr("Slightly rounded"), icon: "crop_square", value: "roundSmall" },
                      { displayName: Translation.tr("Square"), icon: "square", value: "square" }
                  ] }
            ]
        },
        {
            page: Translation.tr("System"), title: Translation.tr("Border Color Management"), icon: "border_color", os: "windows",
            when: () => parseInt(SystemInfo.windowsBuild) >= 22000 && Config.options.hyprland.general.borderSize > 0 && Config.options.hyprland.general.borderColor.enable,
            cards: [
                { type: "swatch", w: 2, key: "hyprland.general.borderColor.activeRole", title: Translation.tr("Active border"), icon: "border_color",
                  colors: ["primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer", "layer0Border"] },
                { type: "spin", key: "hyprland.general.borderColor.activeOpacity", title: Translation.tr("Active border opacity"), icon: "opacity",
                  from: 0, to: 100, step: 5, factor: 100 },
                { type: "swatch", w: 2, key: "hyprland.general.borderColor.inactiveRole", title: Translation.tr("Inactive border"), icon: "border_color",
                  colors: ["primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer", "layer0Border"] },
                { type: "spin", key: "hyprland.general.borderColor.inactiveOpacity", title: Translation.tr("Inactive border opacity"), icon: "opacity",
                  from: 0, to: 100, step: 5, factor: 100 }
            ]
        },
        {
            page: Translation.tr("System"), title: Translation.tr("Window opacity"), icon: "opacity", os: "windows",
            cards: [
                { type: "spin", key: "windowsPort.decoration.activeOpacity", title: Translation.tr("Focused window (%)"), icon: "select_window",
                  from: 10, to: 100, step: 5, factor: 100 },
                { type: "spin", key: "windowsPort.decoration.inactiveOpacity", title: Translation.tr("Other windows (%)"), icon: "opacity",
                  from: 10, to: 100, step: 5, factor: 100 }
            ]
        },
        {
            page: Translation.tr("System"), title: Translation.tr("Workspaces"), icon: "workspaces", os: "windows",
            cards: [
                { type: "toggle", key: "windowsPort.binds.workspaceBackAndForth", title: Translation.tr("Switching to the current workspace goes back"), icon: "swap_horiz" },
                { type: "toggle", key: "custom:sysCursorWarpWorkspace", title: Translation.tr("Move cursor to the new workspace"), icon: "ads_click" }
            ]
        },
        {
            page: Translation.tr("System"), title: Translation.tr("Keyboard"), icon: "keyboard", os: "windows",
            cards: [
                { type: "select", key: "custom:sysKeyboardRepeatDelay", title: Translation.tr("Repeat delay"), icon: "keyboard_return" },
                { type: "spin", key: "custom:sysKeyboardRepeatRate", title: Translation.tr("Repeat rate"), icon: "speed" },
                { type: "toggle", key: "custom:sysNumlockDefault", title: Translation.tr("Numlock by default"), icon: "numbers" },
                { type: "combo", key: "custom:sysKeyboardLayout", title: Translation.tr("Keyboard layout"), icon: "keyboard", w: 2 }
            ]
        },
        {
            page: Translation.tr("System"), title: Translation.tr("Mouse"), icon: "mouse", os: "windows",
            cards: [
                { type: "spin", key: "custom:sysPointerSpeed", title: Translation.tr("Pointer speed"), icon: "speed" },
                { type: "toggle", key: "custom:sysEnhancePointerPrecision", title: Translation.tr("Enhance pointer precision"), icon: "ads_click" },
                { type: "toggle", key: "custom:sysSwapMouseButtons", title: Translation.tr("Swap mouse buttons (left-handed)"), icon: "front_hand" },
                { type: "toggle", key: "custom:sysHidePointerTyping", title: Translation.tr("Hide pointer while typing"), icon: "keyboard_hide" },
                { type: "spin", key: "custom:sysWheelScrollLines", title: Translation.tr("Wheel scroll lines"), icon: "mouse" },
                { type: "toggle", key: "custom:sysFocusFollowsMouse", title: Translation.tr("Focus follows mouse"), icon: "mouse" },
                { type: "toggle", key: "custom:sysRaiseOnFocus", title: Translation.tr("Raise window on focus"), icon: "center_focus_strong",
                  kw: "focus follows mouse only takes effect when that is on" },
                { type: "spin", key: "custom:sysFocusDelayMs", title: Translation.tr("Delay before raising (ms)"), icon: "hourglass_empty",
                  kw: "focus follows mouse only takes effect when that is on" }
            ]
        },
        {
            page: Translation.tr("System"), title: Translation.tr("Touchpad"), icon: "touchpad_mouse", os: "windows",
            when: () => Boolean(WindowsNative.inputSettings?.touchpadAvailable),
            cards: [
                { type: "toggle", key: "custom:sysTouchpadEnabled", title: Translation.tr("Touchpad"), icon: "trackpad_input" },
                { type: "toggle", key: "custom:sysTouchpadTapToClick", title: Translation.tr("Tap to click"), icon: "touch_app" },
                { type: "toggle", key: "custom:sysTouchpadNaturalScroll", title: Translation.tr("Natural scrolling"), icon: "swap_vert" },
                { type: "select", key: "custom:sysTouchpadSensitivity", title: Translation.tr("Sensitivity"), icon: "touch_app" }
            ]
        },
        {
            page: Translation.tr("System"), title: Translation.tr("Cursor"), icon: "mouse", os: "windows",
            cards: [
                { type: "combo", key: "custom:sysCursorScheme", title: Translation.tr("Cursor scheme"), icon: "mouse", w: 2 },
                { type: "spin", key: "custom:sysCursorSize", title: Translation.tr("Cursor size"), icon: "zoom_in" }
            ]
        },
        {
            page: Translation.tr("System"), title: Translation.tr("Lock screen"), icon: "lock_clock", os: "windows",
            cards: [
                { type: "toggle", key: "custom:sysLockAfterInactivity", title: Translation.tr("Lock after inactivity"), icon: "lock_clock" },
                { type: "spin", key: "custom:sysLockAfterMinutes", when: () => Config.options.windowsPort.idle.lock > 0, title: Translation.tr("Lock after (minutes)"), icon: "timer",
                  kw: "only takes effect while lock after inactivity is on" }
            ]
        },
        {
            page: Translation.tr("System"), title: Translation.tr("Screen and sleep"), icon: "bedtime", os: "windows",
            cards: [
                { type: "spin", key: "custom:sysScreenOffAcMinutes", title: Translation.tr("Turn off screen after (minutes), plugged in"), icon: "monitor" },
                { type: "spin", key: "custom:sysSleepAcMinutes", title: Translation.tr("Sleep after (minutes), plugged in"), icon: "bedtime" },
                { type: "spin", key: "custom:sysScreenOffDcMinutes", title: Translation.tr("Turn off screen after (minutes), on battery"), icon: "battery_full",
                  when: () => Boolean(WindowsNative.idlePower?.hasBattery) },
                { type: "spin", key: "custom:sysSleepDcMinutes", title: Translation.tr("Sleep after (minutes), on battery"), icon: "battery_full",
                  when: () => Boolean(WindowsNative.idlePower?.hasBattery) }
            ]
        },
        {
            page: Translation.tr("System"), title: Translation.tr("Autostart"), icon: "rocket_launch", os: "windows",
            cards: [
                { type: "toggle", key: "custom:sysAutostartSelfEnabled", title: Translation.tr("Start ii when you sign in"), icon: "power_settings_new" },
                { type: "select", key: "custom:sysAutostartSelfMethod", title: Translation.tr("How ii starts"), icon: "rocket_launch",
                  when: () => Boolean(WindowsNative.autostart?.selfStartupEnabled) },
                { type: "page", pageId: "system", section: "Autostart", title: Translation.tr("Startup apps"), icon: "list_alt", w: 2,
                  kw: "autostart startup apps programs exe add remove browse scheduled task registry sign in" },
                { type: "page", pageId: "system", section: "Autostart", subsection: "Start with ii", title: Translation.tr("Start with ii"), icon: "workspaces", w: 2,
                  kw: "apps ii itself opens on start workspace launch" }
            ]
        },
        {
            page: Translation.tr("System"), title: Translation.tr("Animations"), icon: "animation", os: "windows",
            cards: [
                { type: "toggle", key: "windowsPort.panelAnimations", title: Translation.tr("Animate panels when they open and close"), icon: "side_navigation" },
                { type: "select", key: "windowsPort.panelAnimationStyle", title: Translation.tr("Animation style"), icon: "auto_awesome",
                  when: () => Config.options.windowsPort.panelAnimations,
                  options: [
                      { displayName: Translation.tr("Standard"), icon: "animation", value: "standard" },
                      { displayName: Translation.tr("Expressive"), icon: "auto_awesome", value: "expressive" }
                  ] },
                { type: "toggle", key: "custom:sysMenuTooltipAnimations", title: Translation.tr("Menu and tooltip animations"), icon: "check" },
                { type: "toggle", key: "custom:sysMinimizeMaximizeAnimations", title: Translation.tr("Minimize and maximize animations"), icon: "animation" }
            ]
        },
        {
            page: Translation.tr("Services"), title: Translation.tr("Web apps"), icon: "web_asset",
            cards: [
                { type: "webapps", key: "services:Webapps", title: Translation.tr("Webapps"), icon: "web_asset", kw: "webapp web app url shortcut start menu chromium edge site pwa open remove" }
            ]
        },
        {
            page: Translation.tr("Services"), title: Translation.tr("AI"), icon: "neurology",
            cards: [
                { type: "text", key: "ai.systemPrompt", title: Translation.tr("System prompt"), icon: "edit_note", w: 4 },
                { type: "select", key: "ai.tool", title: Translation.tr("Tool calling"), icon: "functions",
                  kw: "ai assistant functions search none web read edit shell config",
                  options: [
                      { displayName: Translation.tr("Search"), icon: "search", value: "search" },
                      { displayName: Translation.tr("Functions"), icon: "functions", value: "functions" },
                      { displayName: Translation.tr("None"), icon: "block", value: "none" }
                  ] },
                { type: "toggle", key: "sidebar.ai.textFadeIn", title: Translation.tr("Fade in sidebar response text"), icon: "text_fields" },
                { type: "text", key: "custom:svcVllmEndpoint", title: Translation.tr("Base URL"), icon: "dns", w: 2,
                  placeholder: "http://localhost:8000", kw: "vllm endpoint local openai compatible server model picker" },
                { type: "toggle", key: "ai.claudePanel.enable", title: Translation.tr("Claude Code panel"), icon: "asterisk",
                  kw: "claude code panel sessions terminal anserin spotlight" }
            ]
        },
        {
            page: Translation.tr("Services"), title: Translation.tr("Networking"), icon: "cell_tower",
            cards: [
                { type: "text", key: "networking.userAgent", title: Translation.tr("User agent (for services that require it)"), icon: "lan", w: 4 }
            ]
        },
        {
            page: Translation.tr("Services"), title: Translation.tr("Music Recognition"), icon: "music_cast",
            cards: [
                { type: "spin", key: "musicRecognition.timeout", title: Translation.tr("Timeout (s)"), icon: "timer_off", from: 10, to: 100, step: 2 },
                { type: "spin", key: "musicRecognition.interval", title: Translation.tr("Polling interval (s)"), icon: "av_timer", from: 2, to: 10, step: 1 }
            ]
        },
        {
            page: Translation.tr("Services"), title: Translation.tr("Resources"), icon: "memory",
            cards: [
                { type: "spin", key: "resources.updateInterval", title: Translation.tr("Polling interval (ms)"), icon: "av_timer", from: 100, to: 10000, step: 100 },
                { type: "spin", key: "resources.historyLength", title: Translation.tr("History length (samples)"), icon: "history", from: 10, to: 500, step: 10 }
            ]
        },
        {
            page: Translation.tr("Services"), title: Translation.tr("Save paths"), icon: "file_open",
            cards: [
                { type: "text", key: "screenRecord.savePath", title: Translation.tr("Video recording path"), icon: "video_file", w: 2 },
                { type: "toggle", key: "screenSnip.saveToFolder", title: Translation.tr("Save screenshots to a folder"), icon: "photo_library", os: "windows" },
                { type: "text", key: "screenSnip.savePath", title: Translation.tr("Screenshot folder (leave empty for Pictures\\Screenshots)"), icon: "screenshot_monitor", w: 2, os: "windows" },
                { type: "text", key: "screenSnip.savePath", title: Translation.tr("Screenshot path (empty = copy)"), icon: "screenshot_monitor", w: 2, os: "linux" }
            ]
        },
        {
            page: Translation.tr("Services"), title: Translation.tr("Screen recording"), icon: "screen_record",
            cards: [
                { type: "toggle", key: "screenRecord.systemAudio", title: Translation.tr("Record system audio"), icon: "volume_up" },
                { type: "toggle", key: "screenRecord.microphone", title: Translation.tr("Record microphone"), icon: "mic" },
                { type: "action", key: "custom:svcMicPrivacyAction", title: Translation.tr("Open microphone privacy settings"), icon: "mic_off", os: "windows",
                  label: Translation.tr("Open privacy settings"), kw: "windows privacy microphone blocked desktop apps recording" }
            ]
        },
        {
            page: Translation.tr("Services"), title: Translation.tr("Search"), icon: "search",
            cards: [
                { type: "toggle", key: "search.spotlight", title: Translation.tr("Spotlight search: Super opens search only, Super+Tab opens workspaces"), icon: "manage_search", w: 2 },
                { type: "toggle", key: "search.sloppy", title: Translation.tr("Levenshtein search"), icon: "manage_search",
                  kw: "levenshtein distance fuzzy typo search algorithm" },
                { type: "toggle", key: "search.prefix.showDefaultActionsWithoutPrefix", title: Translation.tr("Show command, math, and web search results without a prefix"), icon: "bolt", w: 2 },
                { type: "toggle", key: "search.clipboardPreviewPopup", title: Translation.tr("Clipboard previews"), icon: "preview" },
                { type: "text", key: "search.prefix.action", title: Translation.tr("Prefix: Action"), icon: "bolt" },
                { type: "text", key: "search.prefix.app", title: Translation.tr("Prefix: Apps"), icon: "apps" },
                { type: "text", key: "search.prefix.clipboard", title: Translation.tr("Prefix: Clipboard"), icon: "content_paste" },
                { type: "text", key: "search.prefix.emojis", title: Translation.tr("Prefix: Emojis"), icon: "mood" },
                { type: "text", key: "search.prefix.keybinds", title: Translation.tr("Prefix: Keybinds"), icon: "keyboard_command_key" },
                { type: "text", key: "search.prefix.symbols", title: Translation.tr("Prefix: Icons"), icon: "emoji_symbols", kw: "symbols icons prefix" },
                { type: "text", key: "search.prefix.math", title: Translation.tr("Math"), icon: "calculate", kw: "prefix calculator" },
                { type: "text", key: "search.prefix.shellCommand", title: Translation.tr("Prefix: Shell command"), icon: "terminal" },
                { type: "text", key: "search.prefix.webSearch", title: Translation.tr("Prefix: Web search"), icon: "travel_explore" },
                { type: "text", key: "search.engineBaseUrl", title: Translation.tr("Web search base URL"), icon: "travel_explore", w: 2 },
                { type: "text", key: "search.excludedSites", title: Translation.tr("Excluded sites"), icon: "block", w: 2, list: true,
                  placeholder: Translation.tr("e.g. quora.com, facebook.com"), kw: "excluded sites domains hidden web search suggestions" },
                { type: "text", key: "search.imageSearch.imageSearchEngineBaseUrl", title: Translation.tr("Base URL"), icon: "image_search", w: 2,
                  kw: "reverse image search screenshot selection" },
                { type: "spin", key: "search.nonAppResultDelay", title: Translation.tr("Delay (ms)"), icon: "timer", from: 0, to: 500, step: 10,
                  kw: "non app results calculator web search delay typing lag" }
            ]
        },
        {
            page: Translation.tr("Services"), title: Translation.tr("App updates"), icon: "deployed_code_update", os: "windows",
            cards: [
                { type: "toggle", key: "updates.enableCheck", title: Translation.tr("Count apps with available updates"), icon: "apps",
                  kw: "winget app updates available count" }
            ]
        },
        {
            page: Translation.tr("Services"), title: Translation.tr("Weather"), icon: "weather_mix",
            cards: [
                { type: "weathermap", key: "services:Weather map", title: Translation.tr("Weather location"), icon: "public",
                  kw: "weather map city location world" },
                { type: "toggle", key: "bar.weather.enableGPS", title: Translation.tr("Enable GPS based location"), icon: "assistant_navigation" },
                { type: "toggle", key: "bar.weather.useUSCS", title: Translation.tr("Fahrenheit unit"), icon: "thermometer" },
                { type: "spin", key: "bar.weather.fetchInterval", title: Translation.tr("Polling interval (m)"), icon: "av_timer", from: 5, to: 50, step: 5 },
                { type: "text", key: "bar.weather.city", title: Translation.tr("City name"), icon: "location_city", w: 2 }
            ]
        },
        {
            page: Translation.tr("Services"), title: Translation.tr("Translator"), icon: "translate",
            cards: [
                { type: "text", key: "language.translator.sourceLanguage", title: Translation.tr("Source language"), icon: "input" },
                { type: "text", key: "language.translator.targetLanguage", title: Translation.tr("Target language"), icon: "output" },
                { type: "spin", key: "sidebar.translator.delay", title: Translation.tr("Request delay (ms)"), icon: "av_timer", from: 0, to: 2000, step: 50 }
            ]
        },
        {
            page: Translation.tr("Services"), title: Translation.tr("Night light"), icon: "bedtime",
            cards: [
                { type: "toggle", key: "light.night.automatic", title: Translation.tr("Automatic"), icon: "schedule" },
                { type: "text", key: "light.night.from", title: Translation.tr("From"), icon: "wb_twilight", placeholder: "19:00" },
                { type: "text", key: "light.night.to", title: Translation.tr("To"), icon: "wb_sunny", placeholder: "06:30" },
                { type: "spin", key: "light.night.colorTemperature", title: Translation.tr("Temperature (K)"), icon: "thermostat", from: 1200, to: 6500, step: 100 },
                { type: "toggle", key: "light.antiFlashbang.enable", title: Translation.tr("Anti-flashbang (experimental)"), icon: "flash_off", os: "linux" }
            ]
        },
        {
            page: Translation.tr("Services"), title: Translation.tr("Booru"), icon: "photo_library",
            cards: [
                { type: "spin", key: "sidebar.booru.limit", title: Translation.tr("Images per request"), icon: "numbers", from: 1, to: 100, step: 1 },
                { type: "text", key: "sidebar.booru.zerochan.username", title: Translation.tr("Zerochan username"), icon: "person" }
            ]
        },
        {
            page: Translation.tr("Services"), title: Translation.tr("Sounds"), icon: "volume_up", os: "linux",
            cards: [
                { type: "text", key: "sounds.theme", title: Translation.tr("Sound theme name (in /usr/share/sounds)"), icon: "music_note", w: 2 }
            ]
        },
        {
            page: Translation.tr("Services"), title: Translation.tr("Update thresholds"), icon: "deployed_code_update", os: "linux",
            cards: [
                { type: "spin", key: "updates.adviseUpdateThreshold", title: Translation.tr("Advise update threshold (packages)"), icon: "update", from: 0, to: 1000, step: 5 },
                { type: "spin", key: "updates.stronglyAdviseUpdateThreshold", title: Translation.tr("Strongly advise threshold (packages)"), icon: "update", from: 0, to: 2000, step: 10 }
            ]
        },
        {
            page: Translation.tr("Services"), title: Translation.tr("Conflict killer"), icon: "block", os: "linux",
            cards: [
                { type: "toggle", key: "conflictKiller.autoKillTrays", title: Translation.tr("Automatically kill conflicting tray daemons"), icon: "inbox_customize" },
                { type: "toggle", key: "conflictKiller.autoKillNotificationDaemons", title: Translation.tr("Automatically kill conflicting notification daemons"), icon: "notifications_off" }
            ]
        },
        {
            page: Translation.tr("Services"), title: Translation.tr("Work safety triggers"), icon: "shield",
            cards: [
                { type: "text", key: "workSafety.triggerCondition.networkNameKeywords", title: Translation.tr("Suspicious network names"), icon: "wifi", w: 2, list: true,
                  placeholder: Translation.tr("e.g. airport, cafe, guest") },
                { type: "text", key: "workSafety.triggerCondition.fileKeywords", title: Translation.tr("Suspicious wallpaper keywords"), icon: "wallpaper", w: 2, list: true,
                  placeholder: Translation.tr("e.g. anime, booru, hentai") },
                { type: "text", key: "workSafety.triggerCondition.linkKeywords", title: Translation.tr("Unsafe link keywords"), icon: "link_off", w: 2, list: true,
                  placeholder: Translation.tr("e.g. hentai, porn, rule34") }
            ]
        },
        {
            page: Translation.tr("Profile"), title: Translation.tr("Avatar"), icon: "person",
            cards: [
                { type: "page", pageId: "profile", section: "Avatar", title: Translation.tr("Avatar"), icon: "person", w: 2,
                  kw: "avatar picture photo image drag drop windows account picture" }
            ]
        },
        {
            page: Translation.tr("Profile"), title: Translation.tr("Identity"), icon: "badge",
            cards: [
                { type: "text", key: "profile.displayName", title: Translation.tr("Display name"), icon: "badge",
                  kw: "display name username" },
                { type: "toggle", key: "profile.hideHostname", title: Translation.tr("Hide computer name"), icon: "visibility_off" },
                { type: "select", key: "custom:profDescriptionMode", title: Translation.tr("Description text"), icon: "subtitles" }
            ]
        },
        {
            page: Translation.tr("Profile"), title: Translation.tr("Presets"), icon: "wall_art",
            cards: [
                { type: "toggle", key: "profile.onlinePresets", title: Translation.tr("Show online presets"), icon: "cloud_download" },
                { type: "page", pageId: "profile", section: "Presets", title: Translation.tr("Presets"), icon: "wall_art", w: 2,
                  kw: "preset save load import export zip upload download github wallpaper theme apply rename remove folder" }
            ]
        },
        {
            page: Translation.tr("Profile"), title: Translation.tr("Browse Online"), icon: "link",
            when: () => Config.options.profile.onlinePresets,
            cards: [
                { type: "page", pageId: "profile", section: "Browse Online", title: Translation.tr("Browse Online"), icon: "link", w: 2,
                  kw: "online presets browse download gallery community refresh" }
            ]
        }
    ]
}

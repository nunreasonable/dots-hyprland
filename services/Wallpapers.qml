import qs
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

/**
 * Provides a list of wallpapers and an "apply" action that calls the existing
 * switchwall.sh script. Pretty much a limited file browsing service.
 */
Singleton {
    id: root

    property string thumbgenScriptPath: `${FileUtils.trimFileProtocol(Directories.scriptPath)}/thumbnails/thumbgen-venv.sh`
    property string generateThumbnailsMagickScriptPath: `${FileUtils.trimFileProtocol(Directories.scriptPath)}/thumbnails/generate-thumbnails-magick.sh`
    property url _requestedDirectory: Qt.resolvedUrl(root.defaultFolder)
    readonly property url directory: root._folderModel ? root._folderModel.folder : root._requestedDirectory
    readonly property string effectiveDirectory: FileUtils.trimFileProtocol(root.directory.toString())
    property url defaultFolder: Qt.resolvedUrl(`${Directories.pictures}/Wallpapers`)
    property var _folderModel: null
    property bool _folderModelFresh: false
    readonly property var folderModel: root._folderModel ?? emptyFolderModel
    property string searchQuery: ""
    readonly property list<string> imageExtensions: ["jpg", "jpeg", "png", "webp", "avif", "bmp", "svg"]
    readonly property list<string> videoExtensions: ["mp4", "webm", "mkv", "avi", "mov"]
    readonly property list<string> extensions: Platform.isWindows ? root.imageExtensions.concat(root.videoExtensions) : root.imageExtensions
    readonly property string stillPath: root.isVideoPath(Config.options.background.wallpaperPath) && Config.options.background.thumbnailPath
        ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath
    readonly property bool thumbnailGenerationRunning: thumbgenProc.running || _windowsThumbnailTotal > 0
    property real thumbnailGenerationProgress: 0
    readonly property string sortMode: Config.options?.wallpaperSelector.sortMode || "time"
    property string previewPath: ""
    property string confirmedPath: ""

    readonly property bool _shellProcess: {
        const process = Quickshell.env("IIW_PROCESS") ?? "";
        return process === "" || process === "shell";
    }
    readonly property bool perDesktop: Platform.isWindows && (Config.options.background.desktopWallpapers?.enable ?? false)
    readonly property bool collageShown: (Config.options.background.collage?.enable ?? false)
        && Config.options.panelFamily !== "waffle"
        && !(Config.options.windowsPort.backgroundBehindIcons && !Config.options.windowsPort.ownWallpaper)
    readonly property bool desktopWallpapersActive: root.perDesktop && !root.collageShown
    readonly property var desktopWallpaperPaths: Config.options.background.desktopWallpapers?.paths ?? ({})
    readonly property var desktops: root.perDesktop ? (WindowsNative.wallpaper?.desktops ?? []) : []
    readonly property string currentDesktopId: root.perDesktop ? (WindowsNative.wallpaper?.currentDesktop ?? "") : ""
    readonly property string currentDesktopWallpaper: root.desktopWallpaperFor(root.currentDesktopId)
    readonly property string selectorDesktopId: root._desktopForTarget(GlobalStates.wallpaperSelectorTarget)

    onCurrentDesktopWallpaperChanged: root._syncSystemWallpaper()

    readonly property string _colorSource: root.desktopWallpapersActive ? root.currentDesktopWallpaper : ""
    on_ColorSourceChanged: {
        if (Platform.isWindows && root._shellProcess) recolorTimer.restart();
    }

    Timer {
        id: recolorTimer
        interval: 300
        onTriggered: root._recolorForDesktop()
    }

    function _recolorForDesktop() {
        if (!Config.ready) return;
        const main = Config.options.background.wallpaperPath;
        if (!main) return;
        if (!root.isVideoPath(main)) {
            root._retheme(main, Appearance.m3colors.darkmode, false);
            return;
        }
        const still = Config.options.background.thumbnailPath;
        if (still && !root.isVideoPath(still)) root._retheme(still, Appearance.m3colors.darkmode, false, main);
    }

    signal changed()
    signal thumbnailGenerated(directory: string)
    signal thumbnailGeneratedFile(filePath: string)

    function load () {} // For forcing initialization

    function startPreview(path) {
        if (!path || path.length === 0) return;
        if (Platform.isWindows && root.isVideoPath(path)) return;
        if (!SpicyStuff.allowed && root.isInSpicyFolder(path)) return;
        root.previewPath = path;
    }

    function stopPreview() {
        root.previewPath = "";
    }

    Connections {
        target: Config.options.background
        function onWallpaperPathChanged() {
            root.confirmedPath = "";
            if (root._desktopToClear !== "") {
                const desktopId = root._desktopToClear;
                root._desktopToClear = "";
                root.clearDesktopWallpaper(desktopId);
            }
        }
    }

    function openSelectorFor(target) {
        if (Platform.isWindows) {
            GlobalStates.wallpaperSelectorTarget = target;
            GlobalStates.wallpaperSelectorOpen = true;
            return;
        }
        Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "wallpaperSelector", "openFor", target]);
    }

    property var _pendingLockFrame: null

    function setLockWallpaper(path) {
        const clean = path ? FileUtils.trimFileProtocol(path.toString()) : "";
        if (clean.length > 0 && !SpicyStuff.allowed && root.isInSpicyFolder(clean)) {
            console.warn("[Wallpapers] Not using a lock screen wallpaper from the Spicy Stuff folder:", SpicyStuff.restriction);
            return;
        }
        Config.options.background.lockWall = clean;
        if (Platform.isWindows) root._applyWindowsLockScreen(clean.length > 0 ? clean : root.stillPath);
    }

    function _syncWindowsLockScreen(path) {
        const wn = WindowsNative.wallpaper;
        if (!wn || typeof wn.lockScreenMode !== "function") return;
        if ((Config.options.background.lockWall ?? "") !== "") return;
        if (wn.lockScreenMode() !== "picture") return;
        root._applyWindowsLockScreen(path);
    }

    function _applyWindowsLockScreen(path) {
        const wn = WindowsNative.wallpaper;
        if (!wn || typeof wn.setLockScreenImage !== "function" || !path || path.length === 0) return;
        if (!root.isVideoPath(path)) {
            wn.setLockScreenImage(path);
            return;
        }
        if (!WindowsNative.thumbnailer) return;
        const frame = root._videoFramePath(path);
        root._pendingLockFrame = frame;
        WindowsNative.thumbnailer.generate(path, frame, 1920);
    }

    function adoptSystemWallpaper() {
        const wn = WindowsNative.wallpaper;
        if (!wn || !Config.ready || Config.options.background.wallpaperPath) return;
        const current = wn.currentWallpaper();
        const fallback = FileUtils.trimFileProtocol(`${Directories.assetsPath}/images/default_wallpaper.png`);
        root._retheme(current && current.length > 0 ? current : fallback, wn.isDarkMode(), false);
    }

    Connections {
        target: Platform.isWindows ? WindowsNative : null
        function onReadyChanged() {
            root.adoptSystemWallpaper();
            systemWallpaperTimer.restart();
        }
    }
    Connections {
        target: Platform.isWindows ? Config : null
        function onReadyChanged() {
            root.adoptSystemWallpaper();
            systemWallpaperTimer.restart();
        }
    }

    function followSystemWallpaper() {
        const wn = WindowsNative.wallpaper;
        if (!wn || !Config.ready || Config.options.windowsPort.ownWallpaper) return;
        const current = wn.currentWallpaper();
        if (!current || current.length === 0) return;
        const normalized = path => FileUtils.trimFileProtocol(path).replace(/\\/g, "/").toLowerCase();
        if (normalized(current) === normalized(Config.options.background.wallpaperPath)) return;
        if (root.isVideoPath(Config.options.background.wallpaperPath)
            && normalized(current) === normalized(Config.options.background.thumbnailPath)) return;
        if (root._isDesktopWallpaper(current)) return;
        if (root.desktopWallpapersActive && root.currentDesktopId !== "" && !root.isVideoPath(current)) {
            root._systemWallpaper = current;
            root._systemShowsOwn = true;
            root.setDesktopWallpaper(root.currentDesktopId, current);
            return;
        }
        root._retheme(current, wn.isDarkMode(), false);
    }

    Timer {
        id: systemWallpaperTimer
        property bool startup: true
        interval: startup ? 4000 : 500
        onTriggered: {
            startup = false;
            root.followSystemWallpaper();
        }
    }
    Connections {
        target: Platform.isWindows ? WindowsNative.desktopLayer : null
        function onWallpaperChanged() {
            systemWallpaperTimer.startup = false;
            systemWallpaperTimer.restart();
        }
    }

    function isVideoPath(path) {
        const lower = path.toLowerCase();
        return root.videoExtensions.some(ext => lower.endsWith(`.${ext}`));
    }

    function stillFor(path) {
        if (!path || !root.isVideoPath(path)) return path ?? "";
        if (root.normalizedPath(path) === root.normalizedPath(Config.options.background.wallpaperPath) && Config.options.background.thumbnailPath)
            return Config.options.background.thumbnailPath;
        return root._videoFramePath(path);
    }

    function openFallbackPicker(darkMode = Appearance.m3colors.darkmode, folder = "") {
        if (Platform.isWindows) {
            if (folder && folder.length > 0) root.setDirectory(folder);
            GlobalStates.wallpaperSelectorOpen = true;
            return;
        }
        Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", darkMode ? "dark" : "light"]);
    }

    function openPicker() {
        if (Platform.isWindows) {
            GlobalStates.wallpaperSelectorOpen = true;
            return;
        }
        Quickshell.execDetached(Directories.wallpaperSwitchScriptPath);
    }

    function normalizedPath(path) {
        const trimmed = FileUtils.trimFileProtocol((path ?? "").toString()).replace(/\\/g, "/").replace(/\/+$/, "");
        return Platform.isWindows ? trimmed.toLowerCase() : trimmed;
    }

    function canonicalPath(path) {
        const trimmed = FileUtils.trimFileProtocol((path ?? "").toString());
        if (Platform.isWindows && WindowsNative.fsUtils && trimmed.length > 0)
            return root.normalizedPath(WindowsNative.fsUtils.canonicalPath(trimmed));
        return root.normalizedPath(trimmed);
    }

    function isInSpicyFolder(path) {
        const base = root.canonicalPath(Config.options.wallpaperSelector.wppSpicyFolder);
        const target = root.canonicalPath(path);
        return base.length > 0 && (target === base || target.startsWith(base + "/"));
    }

    function desktopWallpaperFor(desktopId) {
        if (!root.desktopWallpapersActive || !desktopId) return "";
        const path = root.desktopWallpaperPaths[desktopId] ?? "";
        if (!path || root.isVideoPath(path)) return "";
        if (!SpicyStuff.allowed && root.isInSpicyFolder(path)) return "";
        if (WindowsNative.fsUtils && WindowsNative.fsUtils.classify(path) !== "file") return "";
        return path;
    }

    function wallpaperForDesktopIndex(index) {
        const desktop = root.desktops[index];
        return root.desktopWallpaperFor(desktop?.id ?? "") || Config.options.background.wallpaperPath;
    }

    function desktopLabel(desktopId) {
        const index = root.desktops.findIndex(desktop => desktop.id === desktopId);
        if (index === -1) return Translation.tr("This desktop");
        return root.desktops[index].name || Translation.tr("Desktop %1").arg(index + 1);
    }

    function _desktopForTarget(target) {
        if (!root.desktopWallpapersActive || target === "main" || target === "lockWall") return "";
        if (target.startsWith("desktop:")) return target.slice(8);
        return root.currentDesktopId;
    }

    function _targetDesktop() {
        return root._desktopForTarget(GlobalStates.wallpaperSelectorOpen ? GlobalStates.wallpaperSelectorTarget : "wallpaper");
    }

    function _isOwnDesktopWallpaper(path) {
        if (!root.perDesktop || !path) return false;
        const target = root.normalizedPath(path);
        return Object.values(root.desktopWallpaperPaths).some(own => root.normalizedPath(own) === target);
    }

    function _isDesktopWallpaper(path) {
        if (!root.perDesktop || !path) return false;
        return root.normalizedPath(path) === root.normalizedPath(root._systemWallpaper) || root._isOwnDesktopWallpaper(path);
    }

    function setDesktopWallpaper(desktopId, path) {
        if (!Platform.isWindows || !Config.ready || !desktopId) return;
        const clean = path ? FileUtils.trimFileProtocol(path.toString()) : "";
        if (clean.length > 0 && root.isVideoPath(clean)) return;
        if (clean.length > 0 && !SpicyStuff.allowed && root.isInSpicyFolder(clean)) {
            console.warn("[Wallpapers] Not using a desktop wallpaper from the Spicy Stuff folder:", SpicyStuff.restriction);
            return;
        }
        const next = Object.assign({}, root.desktopWallpaperPaths);
        if (clean.length > 0 && root.normalizedPath(clean) !== root.normalizedPath(Config.options.background.wallpaperPath))
            next[desktopId] = clean;
        else
            delete next[desktopId];
        if (JSON.stringify(next) === JSON.stringify(root.desktopWallpaperPaths)) return;
        Config.options.background.desktopWallpapers.paths = next;
    }

    function clearDesktopWallpaper(desktopId) {
        root.setDesktopWallpaper(desktopId, "");
    }

    function openSelectorForDesktop(desktopId) {
        root.openSelectorFor(desktopId ? `desktop:${desktopId}` : "main");
    }

    property string _desktopToClear: ""

    function _applyToDesktop(desktopId, path, darkMode) {
        if (root.isVideoPath(path)) {
            if (root.normalizedPath(path) === root.normalizedPath(Config.options.background.wallpaperPath)) {
                root.clearDesktopWallpaper(desktopId);
                if (darkMode !== Appearance.m3colors.darkmode)
                    root._retheme(Config.options.background.wallpaperPath, darkMode);
                return;
            }
            root._desktopToClear = desktopId;
            Config.options.appearance.palette.accentColor = "";
            root._retheme(path, darkMode);
            return;
        }
        root._desktopToClear = "";
        root.setDesktopWallpaper(desktopId, path);
        if (darkMode !== Appearance.m3colors.darkmode)
            root._retheme(Config.options.background.wallpaperPath, darkMode);
    }

    function apply(path, darkMode = Appearance.m3colors.darkmode) {
        if (!path || path.length === 0) return;
        if (!SpicyStuff.allowed && root.isInSpicyFolder(path)) {
            console.warn("[Wallpapers] Not applying a wallpaper from the Spicy Stuff folder:", SpicyStuff.restriction);
            return;
        }
        const desktopId = root._targetDesktop();
        if (desktopId !== "") {
            root._applyToDesktop(desktopId, path, darkMode);
            root.changed();
            return;
        }
        if (Platform.isWindows) {
            Config.options.appearance.palette.accentColor = "";
            root._retheme(path, darkMode);
        } else {
            root.confirmedPath = path;
            Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", darkMode ? "dark" : "light", "--image", path]);
        }
        root.changed()
    }

    function setMode(dark) {
        if (Config.options.appearance.autoTheme.mode !== "off") {
            Config.options.appearance.autoTheme.mode = "off";
        }
        if (Platform.isWindows) {
            root._retheme(Config.options.background.wallpaperPath, dark);
        } else {
            Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`]);
        }
    }

    function applyAutomaticMode(dark, applyToSystem = true) {
        if (Platform.isWindows) {
            root._retheme(Config.options.background.wallpaperPath, dark, applyToSystem);
        } else {
            Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`]);
        }
    }

    function reapplyPalette() {
        if (Platform.isWindows) {
            root._retheme(Config.options.background.wallpaperPath, Appearance.m3colors.darkmode);
        } else {
            Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --noswitch`]);
        }
    }

    function setAccentColor(hexOrClear) {
        if (Platform.isWindows) {
            if (hexOrClear === "clear") {
                Config.options.appearance.palette.accentColor = "";
            } else if (/^#?[0-9a-fA-F]{6}$/.test(hexOrClear ?? "")) {
                Config.options.appearance.palette.accentColor = hexOrClear.startsWith("#") ? hexOrClear : `#${hexOrClear}`;
            } else {
                GlobalStates.colorPickerAction = "accent";
                GlobalStates.colorPickerOpen = true;
                return;
            }
            root._retheme(Config.options.background.wallpaperPath, Appearance.m3colors.darkmode);
            return;
        }
        const args = [Directories.wallpaperSwitchScriptPath, "--noswitch", "--color"];
        if (hexOrClear) args.push(hexOrClear);
        Quickshell.execDetached(args);
    }

    property var _pendingVideo: null

    function _videoFramePath(path) {
        return `${Directories.videoFrames}/${Qt.md5(root.normalizedPath(path))}.png`;
    }

    readonly property bool systemDrawsWallpaper: Config.options.panelFamily !== "waffle"
        && Config.options.windowsPort.backgroundBehindIcons && !Config.options.windowsPort.ownWallpaper

    function _retheme(path, darkMode, applyToSystem = true, videoPath = "") {
        const wn = WindowsNative.wallpaper;
        if (!wn) return;
        if (!SpicyStuff.allowed && root.isInSpicyFolder(path)) {
            console.warn("[Wallpapers] Not using a wallpaper from the Spicy Stuff folder:", SpicyStuff.restriction);
            return;
        }

        const hasPath = !!path && path.length > 0;
        if (hasPath && root.isVideoPath(path)) {
            if (!WindowsNative.thumbnailer) {
                console.warn("[Wallpapers] Can't read a frame of the video yet, skipping:", path);
                return;
            }
            const frame = root._videoFramePath(path);
            root._pendingVideo = { video: path, frame: frame, darkMode: darkMode, applyToSystem: applyToSystem };
            WindowsNative.thumbnailer.generate(path, frame, 1920);
            return;
        }

        if (applyToSystem && !AutoTheme.followingWindows) wn.setDarkMode(darkMode);

        if (hasPath) {
            const target = videoPath.length > 0 ? videoPath : path;
            const changed = root.normalizedPath(target) !== root.normalizedPath(Config.options.background.wallpaperPath);
            const desktopKeepsOwn = root.desktopWallpapersActive && (root.systemDrawsWallpaper || root._nativeDesktopWallpapers) && root.currentDesktopWallpaper !== "";
            if (applyToSystem && !desktopKeepsOwn) {
                wn.setWallpaper(path, root.systemDrawsWallpaper);
                root._systemWallpaper = path;
                root._systemShowsOwn = false;
                if (root._desktopWallpapersSynced) desktopSyncTimer.restart();
            }
            Config.options.background.wallpaperPath = target;
            if (videoPath.length > 0) Config.options.background.thumbnailPath = path;
            if (applyToSystem && changed) root._syncWindowsLockScreen(path);
        }

        if (Config.options.appearance.wallpaperTheming.enableAppsAndShell === false) {
            return;
        }

        const namedScheme = Config.options.appearance.palette.namedScheme;
        const namedAccentColor = namedScheme ? ColorSchemes.currentAccent("primary", darkMode) : "";
        const hasNamedAccentColor = /^#[0-9a-fA-F]{6}$/.test(namedAccentColor ?? "");

        const accentColor = Config.options.appearance.palette.accentColor;
        const hasAccentColor = !hasNamedAccentColor && /^#[0-9a-fA-F]{6}$/.test(accentColor ?? "");
        if (!hasNamedAccentColor && !hasAccentColor && !hasPath) return;

        const matugenExe = wn.matugenPath();
        if (!matugenExe) {
            console.warn("[Wallpapers] matugen.exe not found next to qs.exe - Windows wallpaper theming unavailable");
            return;
        }

        const colorPath = hasPath && root.desktopWallpapersActive && root.currentDesktopWallpaper !== "" ? root.currentDesktopWallpaper : path;
        let schemeType = Config.options.appearance.palette.type || "auto";
        if (schemeType === "auto") {
            schemeType = hasPath && WindowsNative.imageTools
                ? WindowsNative.imageTools.schemeForImage(colorPath)
                : "scheme-tonal-spot";
        }

        const args = [matugenExe, "--source-color-index", "0", "-c", windowsMatugenConfig.path, "-m", darkMode ? "dark" : "light", "-t", schemeType];
        if (hasNamedAccentColor) {
            args.push("color", "hex", namedAccentColor);
        } else if (hasAccentColor) {
            args.push("color", "hex", accentColor);
        } else {
            args.push("image", colorPath);
        }

        const config = root._windowsMatugenConfigText();
        if (config === root._writtenMatugenConfig) {
            root._runMatugen(args);
            return;
        }
        root._pendingMatugen = args;
        if (config !== root._writingMatugenConfig) {
            root._writingMatugenConfig = config;
            windowsMatugenConfig.setText(config);
        }
    }

    property bool _nativeDesktopWallpapers: false
    property bool _desktopWallpapersSynced: false
    property bool _desktopSyncChecked: false
    property string _systemWallpaper: ""
    property bool _systemShowsOwn: false

    readonly property var _systemDesktopPaths: {
        const paths = {};
        if (!root.desktopWallpapersActive) return paths;
        for (const desktopId in root.desktopWallpaperPaths) {
            const own = root.desktopWallpaperFor(desktopId);
            if (own) paths[desktopId] = own;
        }
        return paths;
    }

    readonly property string _desktopSyncState: (!Platform.isWindows || !root._shellProcess || !Config.ready || !WindowsNative.wallpaper) ? ""
        : JSON.stringify([root.desktopWallpapersActive, root.systemDrawsWallpaper, root._systemDesktopPaths, root.stillPath,
            root.desktops.map(desktop => desktop.id)])
    on_DesktopSyncStateChanged: {
        if (root._desktopSyncState !== "") desktopSyncTimer.restart();
    }

    Timer {
        id: desktopSyncTimer
        interval: 100
        onTriggered: root._syncDesktopWallpapers()
    }

    function _syncDesktopWallpapers() {
        const wn = WindowsNative.wallpaper;
        if (!wn || !Config.ready || !root._shellProcess) return;
        const active = root.desktopWallpapersActive;
        if (!active && !root._desktopWallpapersSynced) return;
        const main = root.stillPath;
        if (!main || root.isVideoPath(main)) return;
        root._nativeDesktopWallpapers = wn.setDesktopWallpapers(root._systemDesktopPaths, main);
        root._desktopWallpapersSynced = active;
        root._desktopSyncChecked = true;
        root._syncSystemWallpaper();
    }

    function _syncSystemWallpaper() {
        const wn = WindowsNative.wallpaper;
        if (!wn || !Config.ready || !root._shellProcess || !root._desktopSyncChecked || root._nativeDesktopWallpapers) return;
        const main = root.stillPath;
        if (!main || root.isVideoPath(main)) return;
        if (root._systemWallpaper === "") {
            const shown = wn.currentWallpaper();
            root._systemShowsOwn = !!shown && root.normalizedPath(shown) !== root.normalizedPath(main)
                && root._isOwnDesktopWallpaper(shown);
            root._systemWallpaper = root._systemShowsOwn ? shown : main;
        }
        const own = (root.desktopWallpapersActive && root.systemDrawsWallpaper) ? root.currentDesktopWallpaper : "";
        if (own === "" && !root._systemShowsOwn) return;
        const target = own || main;
        root._systemShowsOwn = own !== "";
        if (root.normalizedPath(target) === root.normalizedPath(root._systemWallpaper)) return;
        root._systemWallpaper = target;
        wn.setWallpaperInBackground(target);
    }

    property var _pendingMatugen: null
    property string _writtenMatugenConfig: ""
    property string _writingMatugenConfig: ""

    function _runMatugen(args) {
        matugenProc.command = args;
        matugenProc.running = false;
        matugenProc.running = true;
    }

    function _windowsMatugenConfigText() {
        const toml = s => s.indexOf("'") === -1 ? `'${s}'` : JSON.stringify(s);
        const template = FileUtils.trimFileProtocol(Directories.windowsMatugenTemplatePath);
        return `[config]\nversion_check = false\n\n[templates.m3colors]\n`
            + `input_path = ${toml(template)}\n`
            + `output_path = ${toml(Directories.generatedMaterialThemePath)}\n`;
    }

    FileView {
        id: windowsMatugenConfig
        path: Platform.isWindows ? `${FileUtils.trimFileProtocol(Directories.state)}/user/generated/matugen-config.toml` : ""
        preload: false
        onSaved: {
            root._writtenMatugenConfig = root._writingMatugenConfig;
            root._writingMatugenConfig = "";
            if (!root._pendingMatugen) return;
            const args = root._pendingMatugen;
            root._pendingMatugen = null;
            root._runMatugen(args);
        }
        onSaveFailed: error => {
            root._pendingMatugen = null;
            root._writingMatugenConfig = "";
            console.warn("[Wallpapers] Could not write the matugen config:", error);
        }
    }

    Process {
        id: matugenProc
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) console.warn("[Wallpapers] matugen.exe:", text);
            }
        }
    }

    function setSortMode(mode) {
        if (!Config.ready) return;
        Config.options.wallpaperSelector.sortMode = mode;
    }

    function _sortField() {
        switch (root.sortMode) {
        case "name":
        case "name_rev":
            return FolderListModel.Name;
        case "size":
        case "size_rev":
            return FolderListModel.Size;
        default:
            return FolderListModel.Time;
        }
    }

    function _sortReversed() {
        return root.sortMode === "time_rev" || root.sortMode === "name_rev" || root.sortMode === "size_rev";
    }

    function select(filePath, isDirectory, darkMode = Appearance.m3colors.darkmode) {
        if (isDirectory) {
            root.setDirectory(filePath);
            return;
        }
        root.apply(filePath, darkMode);
    }

    function randomFromCurrentFolder(darkMode = Appearance.m3colors.darkmode) {
        const model = root.ensureFolderModel();
        if (model.status !== FolderListModel.Ready) {
            if (model.status === FolderListModel.Loading || root._folderModelFresh) {
                root._pendingRandom = true;
                root._pendingRandomDarkMode = darkMode;
            }
            return;
        }
        const files = [];
        for (let i = 0; i < model.count; i++) {
            if (!model.get(i, "fileIsDir") && !root.isVideoPath(model.get(i, "fileName")))
                files.push(model.get(i, "filePath"));
        }
        if (files.length === 0) return;
        const filePath = files[Math.floor(Math.random() * files.length)];
        print("Randomly selected wallpaper:", filePath);
        root.select(filePath, false, darkMode);
    }

    Process {
        id: validateDirProc
        property string nicePath: ""
        function setDirectoryIfValid(path) {
            validateDirProc.nicePath = FileUtils.trimFileProtocol(path).replace(/\/+$/, "")
            if (/^\/*$/.test(validateDirProc.nicePath)) validateDirProc.nicePath = "/";
            validateDirProc.exec([
                "bash", "-c",
                `if [ -d "${validateDirProc.nicePath}" ]; then echo dir; elif [ -f "${validateDirProc.nicePath}" ]; then echo file; else echo invalid; fi`
            ])
        }
        stdout: StdioCollector {
            onStreamFinished: {
                    root._setFolder(Qt.resolvedUrl(validateDirProc.nicePath))
                const result = text.trim()
                if (result === "dir") {
                } else if (result === "file") {
                    root._setFolder(Qt.resolvedUrl(FileUtils.parentDirectory(validateDirProc.nicePath)))
                } else {
                    // Ignore
                }
            }
        }
    }
    function setDirectory(path) {
        if (Platform.isWindows) {
            let nicePath = FileUtils.trimFileProtocol(path).replace(/\/+$/, "");
            if (/^\/*$/.test(nicePath)) nicePath = "/";
            const kind = WindowsNative.fsUtils ? WindowsNative.fsUtils.classify(nicePath) : "invalid";
            if (kind === "dir") {
                root._setFolder(FileUtils.folderUrl(nicePath));
            } else if (kind === "file") {
                root._setFolder(FileUtils.folderUrl(FileUtils.parentDirectory(nicePath)));
            }
            return;
        }
        validateDirProc.setDirectoryIfValid(path)
    }
    function navigateUp() {
        root.ensureFolderModel().navigateUp()
    }
    function navigateBack() {
        root.ensureFolderModel().navigateBack()
    }
    function navigateForward() {
        root.ensureFolderModel().navigateForward()
    }

    function _setFolder(url) {
        if (root._folderModel)
            root._folderModel.folder = url;
        else
            root._requestedDirectory = url;
    }

    function ensureFolderModel() {
        if (!root._folderModel) {
            root._folderModelFresh = true;
            root._folderModel = folderModelComponent.createObject(root);
        }
        return root._folderModel;
    }

    property string _pendingThumbnailSize: ""
    property bool _pendingRandom: false
    property bool _pendingRandomDarkMode: false

    function _onFolderModelStatus(status) {
        root._folderModelFresh = false;
        if (status === FolderListModel.Loading) return;
        const thumbnailSize = root._pendingThumbnailSize;
        const random = root._pendingRandom;
        root._pendingThumbnailSize = "";
        root._pendingRandom = false;
        if (status !== FolderListModel.Ready) return;
        if (thumbnailSize !== "") root._generateThumbnailsWindows(thumbnailSize, root.directory);
        if (random) root.randomFromCurrentFolder(root._pendingRandomDarkMode);
    }

    Connections {
        target: GlobalStates
        function onWallpaperSelectorOpenChanged() {
            if (GlobalStates.wallpaperSelectorOpen) root.ensureFolderModel();
        }
    }

    ListModel {
        id: emptyFolderModel
    }

    // Folder model
    Component {
        id: folderModelComponent
        FolderListModelWithHistory {
            folder: root._requestedDirectory
            caseSensitive: false
            nameFilters: root.extensions.map(ext => `*${root.searchQuery.split(" ").filter(s => s.length > 0).map(s => `*${s}*`)}*.${ext}`)
            showDirs: true
            showDotAndDotDot: false
            showOnlyReadable: true
            sortField: root._sortField()
            sortReversed: root._sortReversed()
            onStatusChanged: root._onFolderModelStatus(status)
        }
    }

    // Thumbnail generation
    function generateThumbnail(size: string) {
        if (!["normal", "large", "x-large", "xx-large"].includes(size)) throw new Error("Invalid thumbnail size");
        root.thumbnailGenerationProgress = 0
        if (!SpicyStuff.allowed && root.isInSpicyFolder(root.directory))
            return;
        if (Platform.isWindows) {
            root._generateThumbnailsWindows(size, root.directory);
            return;
        }
        thumbgenProc.directory = root.directory
        thumbgenProc.running = false
        thumbgenProc.command = [
            "bash", "-c",
            `${thumbgenScriptPath} --size ${size} --machine_progress -d ${FileUtils.trimFileProtocol(root.directory)} || ${generateThumbnailsMagickScriptPath} --size ${size} -d ${FileUtils.trimFileProtocol(root.directory)}`,
        ]
        // console.log("[Wallpapers] Updating thumbnails with command ", thumbgenProc.command.join(" "))
        thumbgenProc.running = true
    }
    Process {
        id: thumbgenProc
        property string directory
        stdout: SplitParser {
            onRead: data => {
                // print("thumb gen proc:", data)
                let match = data.match(/PROGRESS (\d+)\/(\d+)/)
                if (match) {
                    const completed = parseInt(match[1])
                    const total = parseInt(match[2])
                    root.thumbnailGenerationProgress = completed / total
                }
                match = data.match(/FILE (.+)/)
                if (match) {
                    const filePath = match[1]
                    root.thumbnailGeneratedFile(filePath)
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            // print("[Wallpapers] Thumbnail generation completed with exit code", exitCode)
            root.thumbnailGenerated(thumbgenProc.directory)
        }
    }

    property var _windowsPendingThumbnails: ({})
    property int _windowsThumbnailTotal: 0

    function _generateThumbnailsWindows(size, directory) {
        if (!WindowsNative.thumbnailer) return;
        const model = root.ensureFolderModel();
        if (model.status !== FolderListModel.Ready) {
            if (model.status === FolderListModel.Loading || root._folderModelFresh)
                root._pendingThumbnailSize = size;
            return;
        }
        const maxSize = Images.thumbnailSizes[size];
        const pending = {};
        for (let i = 0; i < model.count; i++) {
            if (model.get(i, "fileIsDir")) continue;
            const fileName = model.get(i, "fileName");
            if (!Images.isValidImageByName(fileName) && !root.isVideoPath(fileName)) continue;
            const filePath = model.get(i, "filePath");
            pending[FileUtils.trimFileProtocol(Images.thumbnailPathFor(filePath, size))] = filePath;
        }

        root._windowsPendingThumbnails = pending;
        root._windowsThumbnailTotal = Object.keys(pending).length;

        if (root._windowsThumbnailTotal === 0) {
            root.thumbnailGenerationProgress = 1;
            root.thumbnailGenerated(directory);
            return;
        }

        for (const outputPath in pending) {
            WindowsNative.thumbnailer.generate(pending[outputPath], outputPath, maxSize);
        }
    }

    Connections {
        target: WindowsNative.thumbnailer
        function onFinished(sourcePath, outputPath, ok) {
            if (root._pendingLockFrame && outputPath === root._pendingLockFrame) {
                root._pendingLockFrame = null;
                if (ok) WindowsNative.wallpaper?.setLockScreenImage(outputPath);
                else console.warn("[Wallpapers] Could not read a frame of the lock screen video");
                if (!root._pendingVideo || outputPath !== root._pendingVideo.frame) return;
            }
            const video = root._pendingVideo;
            if (video && outputPath === video.frame) {
                root._pendingVideo = null;
                if (ok) root._retheme(video.frame, video.darkMode, video.applyToSystem, video.video);
                else console.warn("[Wallpapers] Could not read a frame of", video.video);
                return;
            }
            if (!(outputPath in root._windowsPendingThumbnails)) return;
            delete root._windowsPendingThumbnails[outputPath];
            const remaining = Object.keys(root._windowsPendingThumbnails).length;
            root.thumbnailGenerationProgress = (root._windowsThumbnailTotal - remaining) / root._windowsThumbnailTotal;
            if (ok) root.thumbnailGeneratedFile(sourcePath);
            if (remaining === 0) {
                root._windowsThumbnailTotal = 0;
                root.thumbnailGenerated(root.directory);
            }
        }
    }

    Connections {
        target: WindowsNative.wallpaper
        function onLockScreenImageApplied(ok) {
            if (ok !== Config.options.background.lockScreenImageSupported)
                Config.options.background.lockScreenImageSupported = ok;
        }
    }

    Timer {
        id: changeIntervalTimer
        interval: Config.options?.wallpaperSelector.changeInterval ?? 0
        running: Config.ready && (Config.options?.wallpaperSelector.changeInterval ?? 0) > 0
        repeat: true
        onTriggered: root.randomFromCurrentFolder()
    }

    IpcHandler {
        target: "wallpapers"

        function apply(path: string): void {
            root.apply(path);
        }
    }
}

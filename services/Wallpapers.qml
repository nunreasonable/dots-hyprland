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
    readonly property list<string> extensions: [ // TODO: add videos
        "jpg", "jpeg", "png", "webp", "avif", "bmp", "svg"
    ]
    readonly property list<string> videoExtensions: ["mp4", "webm", "mkv", "avi", "mov"]
    readonly property bool thumbnailGenerationRunning: thumbgenProc.running || _windowsThumbnailTotal > 0
    property real thumbnailGenerationProgress: 0
    readonly property string sortMode: Config.options?.wallpaperSelector.sortMode || "time"

    signal changed()
    signal thumbnailGenerated(directory: string)
    signal thumbnailGeneratedFile(filePath: string)

    function load () {} // For forcing initialization

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

    function openFallbackPicker(darkMode = Appearance.m3colors.darkmode) {
        if (Platform.isWindows) {
            console.warn("[Wallpapers] Native file dialog not available on Windows yet, opening the in-shell picker instead");
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

    function apply(path, darkMode = Appearance.m3colors.darkmode) {
        if (!path || path.length === 0) return;
        if (Platform.isWindows) {
            Config.options.appearance.palette.accentColor = "";
            root._retheme(path, darkMode);
        } else {
            Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", darkMode ? "dark" : "light", "--image", path]);
        }
        root.changed()
    }

    function setMode(dark) {
        if (Platform.isWindows) {
            root._retheme(Config.options.background.wallpaperPath, dark);
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

    function _retheme(path, darkMode, applyToSystem = true) {
        const wn = WindowsNative.wallpaper;
        if (!wn) return;

        const hasPath = !!path && path.length > 0;
        if (hasPath && root.isVideoPath(path)) {
            console.warn("[Wallpapers] Video wallpapers are not supported on Windows, skipping:", path);
            return;
        }

        if (applyToSystem) wn.setDarkMode(darkMode);

        if (hasPath) {
            if (applyToSystem) wn.setWallpaper(path);
            Config.options.background.wallpaperPath = path;
        }

        if (Config.options.appearance.wallpaperTheming.enableAppsAndShell === false) {
            return;
        }

        const accentColor = Config.options.appearance.palette.accentColor;
        const hasAccentColor = /^#[0-9a-fA-F]{6}$/.test(accentColor ?? "");
        if (!hasAccentColor && !hasPath) return;

        const matugenExe = wn.matugenPath();
        if (!matugenExe) {
            console.warn("[Wallpapers] matugen.exe not found next to qs.exe - Windows wallpaper theming unavailable");
            return;
        }

        let schemeType = Config.options.appearance.palette.type || "auto";
        if (schemeType === "auto") {
            schemeType = hasPath && WindowsNative.imageTools
                ? WindowsNative.imageTools.schemeForImage(path)
                : "scheme-tonal-spot";
        }

        const args = [matugenExe, "--source-color-index", "0", "-c", windowsMatugenConfig.path, "-m", darkMode ? "dark" : "light", "-t", schemeType];
        if (hasAccentColor) {
            args.push("color", "hex", accentColor);
        } else {
            args.push("image", path);
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
        return root.sortMode === "time_rev" || root.sortMode === "name_rev" || root.sortMode === "size";
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
        if (model.count === 0) return;
        const randomIndex = Math.floor(Math.random() * model.count);
        const filePath = model.get(randomIndex, "filePath");
        const isDirectory = model.get(randomIndex, "fileIsDir");
        print("Randomly selected wallpaper:", filePath);
        root.select(filePath, isDirectory, darkMode);
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
                root._setFolder(Qt.resolvedUrl(nicePath));
            } else if (kind === "file") {
                root._setFolder(Qt.resolvedUrl(FileUtils.parentDirectory(nicePath)));
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
            if (!Images.isValidImageByName(fileName)) continue;
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

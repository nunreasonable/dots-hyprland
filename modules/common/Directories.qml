pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.functions
import QtCore
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell

Singleton {
    // XDG Dirs, with "file://"
    readonly property string home: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
    // On Windows, plain ConfigLocation is app-qualified (%LOCALAPPDATA%/quickshell),
    // unlike Linux where it's the bare XDG_CONFIG_HOME ii appends "illogical-impulse" to.
    // GenericConfigLocation gives the same bare %LOCALAPPDATA% root there.
    readonly property string config: StandardPaths.standardLocations(
        Platform.isWindows ? StandardPaths.GenericConfigLocation : StandardPaths.ConfigLocation)[0]
    // StateLocation is already app-qualified on both platforms (~/.local/state/quickshell,
    // %LOCALAPPDATA%/quickshell), so it needs no special-casing here.
    readonly property string state: StandardPaths.standardLocations(StandardPaths.StateLocation)[0]
    readonly property string cache: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0]
    readonly property string genericCache: StandardPaths.standardLocations(StandardPaths.GenericCacheLocation)[0]
    readonly property string documents: StandardPaths.standardLocations(StandardPaths.DocumentsLocation)[0]
    readonly property string downloads: StandardPaths.standardLocations(StandardPaths.DownloadLocation)[0]
    readonly property string pictures: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
    readonly property string music: StandardPaths.standardLocations(StandardPaths.MusicLocation)[0]
    readonly property string videos: StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]

    // Other dirs used by the shell, without "file://"
    property string assetsPath: Quickshell.shellPath("assets")
    property string scriptPath: Quickshell.shellPath("scripts")
    property string favicons: FileUtils.trimFileProtocol(`${Directories.cache}/media/favicons`)
    property string coverArt: FileUtils.trimFileProtocol(`${Directories.cache}/media/coverart`)
    // "/tmp/quickshell" has no equivalent on Windows; TempLocation gives a per-user temp dir there.
    readonly property string tempRoot: Platform.isWindows
        ? `${FileUtils.trimFileProtocol(StandardPaths.standardLocations(StandardPaths.TempLocation)[0])}/quickshell`
        : "/tmp/quickshell"
    property string tempImages: `${Directories.tempRoot}/media/images`
    property string booruPreviews: FileUtils.trimFileProtocol(`${Directories.cache}/media/boorus`)
    property string booruDownloads: FileUtils.trimFileProtocol(Directories.pictures  + "/homework")
    property string booruDownloadsNsfw: FileUtils.trimFileProtocol(Directories.pictures + "/homework/🌶️")
    property string latexOutput: FileUtils.trimFileProtocol(`${Directories.cache}/media/latex`)
    property string shellConfig: FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse`)
    property string shellConfigName: "config.json"
    property string shellConfigPath: `${Directories.shellConfig}/${Directories.shellConfigName}`
	property string todoPath: FileUtils.trimFileProtocol(`${Directories.state}/user/todo.json`)
	property string notesPath: FileUtils.trimFileProtocol(`${Directories.state}/user/notes.txt`)
	property string conflictCachePath: FileUtils.trimFileProtocol(`${Directories.cache}/conflict-killer`)
    property string notificationsPath: FileUtils.trimFileProtocol(`${Directories.cache}/notifications/notifications.json`)
    property string generatedMaterialThemePath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/colors.json`)
    property string generatedWallpaperCategoryPath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/wallpaper/category.txt`)
    property string cliphistDecode: FileUtils.trimFileProtocol(`${Directories.tempRoot}/media/cliphist`)
    property string screenshotTemp: `${Directories.tempRoot}/media/screenshot`
    // Windows only: PID of the ffmpeg process the region selector's recorder started, so a
    // second invocation (the "stop" toggle) can find and kill the right one. See
    // scripts/videos/record.ps1 and ScreenshotAction.qml's recording helpers.
    property string recordingPidFile: `${Directories.tempRoot}/media/recording.pid`
    property string wallpaperSwitchScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/colors/switchwall.sh`)
    // Windows: the m3colors template matugen.exe renders into colors.json. Wallpapers.qml writes
    // the matugen config pointing at it (and at the real StateLocation) at run time.
    property string windowsMatugenTemplatePath: Quickshell.shellPath("defaults/windows/matugen/colors.json")
    // Windows terminal theming (services/WindowsTerminalTheme.qml): the same two template
    // files Linux's applycolor.sh fills in by $placeholder substitution (scripts/colors/
    // terminal/), reused as-is since there's nothing shell-specific in them.
    property string terminalSchemeBasePath: Quickshell.shellPath("scripts/colors/terminal/scheme-base.json")
    property string terminalSequencesTemplatePath: Quickshell.shellPath("scripts/colors/terminal/sequences.txt")
    property string windowsTerminalSequencesPath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/terminal/sequences.txt`)
    // Windows: the Oh My Posh prompt theme, in ii's colors (services/WindowsTerminalTheme.qml)
    property string windowsTerminalOhMyPoshPath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/terminal/ii.omp.json`)
    // Second matugen.exe pass for terminalGenerationProps.forceDarkMode while ii itself is
    // light: generate_colors_material.py forces --mode dark for the terminal independently of
    // the (still light) colors.json matugen already wrote for ii's own UI; this is that, since
    // there's no Python/materialyoucolor on Windows to recompute it directly.
    property string windowsTerminalMaterialDarkConfigPath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/matugen-config-terminal-dark.toml`)
    property string windowsTerminalMaterialDarkPath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/terminal/material-dark.json`)
    // Windows Terminal's own JSON fragment (color scheme + profile updates) and the installed
    // app's settings.json, whose mtime gets nudged so already-open windows notice the fragment
    // changed (see WindowsTerminalTheme.nudgeWindowsTerminal()).
    property string windowsTerminalFragmentDir: `${(Quickshell.env("LOCALAPPDATA") || "").replace(/\\/g, "/")}/Microsoft/Windows Terminal/Fragments/illogical-impulse`
    property string windowsTerminalFragmentPath: `${Directories.windowsTerminalFragmentDir}/illogical-impulse.json`
    property string windowsTerminalSettingsJsonPath: `${(Quickshell.env("LOCALAPPDATA") || "").replace(/\\/g, "/")}/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json`
    property string defaultAiPrompts: Quickshell.shellPath("defaults/ai/prompts")
    property string userAiPrompts: FileUtils.trimFileProtocol(`${Directories.shellConfig}/ai/prompts`)
    property string userActions: FileUtils.trimFileProtocol(`${Directories.shellConfig}/actions`)
    property string aiChats: FileUtils.trimFileProtocol(`${Directories.state}/user/ai/chats`)
    property string aiTranslationScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/ai/gemini-translate.sh`)
    property string recordScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/videos/record.sh`)
    property string userAvatarPathAccountsService: Platform.isWindows ? "" : FileUtils.trimFileProtocol(`/var/lib/AccountsService/icons/${SystemInfo.username}`)
    property string userAvatarPathRicersAndWeirdSystems: FileUtils.trimFileProtocol(`${Directories.home}.face`)
    property string userAvatarPathRicersAndWeirdSystems2: FileUtils.trimFileProtocol(`${Directories.home}.face.icon`)
    // Windows account picture: first image under %APPDATA%/Microsoft/Windows/AccountPictures, or empty.
    property string userAvatarPathWindows: (Platform.isWindows && accountPicturesFolder.count > 0)
        ? FileUtils.trimFileProtocol(accountPicturesFolder.get(0, "filePath"))
        : ""

    FolderListModel {
        id: accountPicturesFolder
        folder: Platform.isWindows
            ? Qt.resolvedUrl(`file:///${(Quickshell.env("APPDATA") || "").replace(/\\/g, "/")}/Microsoft/Windows/AccountPictures`)
            : ""
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.bmp"]
        showDirs: false
        showHidden: false
        sortField: FolderListModel.Name
    }

    // Cleanup on init
    Component.onCompleted: {
        if (Platform.isWindows) {
            // Most Linux cache/cleanup dirs don't need pre-creating: Quickshell's FileView
            // creates parent directories on write (see fileview.cpp's dir.mkpath), which is
            // all the boot-critical paths here (config.json, state/user/*) need. latexOutput
            // is the exception: MicroTeX's own process writes the .svg directly (no FileView
            // involved), so the directory has to exist before LatexRenderer spawns it.
            Quickshell.execDetached(["powershell", "-NoProfile", "-Command",
                `New-Item -ItemType Directory -Force -Path "${latexOutput}" | Out-Null`]);
            return;
        }
        Quickshell.execDetached(["mkdir", "-p", `${shellConfig}`])
        Quickshell.execDetached(["mkdir", "-p", `${favicons}`])
        Quickshell.execDetached(["bash", "-c", `rm -rf '${coverArt}'; mkdir -p '${coverArt}'`])
        Quickshell.execDetached(["bash", "-c", `rm -rf '${booruPreviews}'; mkdir -p '${booruPreviews}'`])
        Quickshell.execDetached(["bash", "-c", `rm -rf '${latexOutput}'; mkdir -p '${latexOutput}'`])
        Quickshell.execDetached(["bash", "-c", `rm -rf '${cliphistDecode}'; mkdir -p '${cliphistDecode}'`])
        Quickshell.execDetached(["mkdir", "-p", `${aiChats}`])
        Quickshell.execDetached(["mkdir", "-p", `${userActions}`])
        Quickshell.execDetached(["rm", "-rf", `${tempImages}`])
    }
}

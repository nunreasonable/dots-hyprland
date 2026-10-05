pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Automatically reloads generated material colors.
 * It is necessary to run reapplyTheme() on startup because Singletons are lazily loaded.
 */
Singleton {
    id: root
    property string filePath: Directories.generatedMaterialThemePath

    function reapplyTheme() {
        themeFileView.reload()
    }

    property int failedReads: 0

    function applyColors(fileContent) {
        let json
        try {
            json = JSON.parse(fileContent)
        } catch (e) {
            if (root.failedReads++ < 20) {
                themeFileView.reload()
                delayedFileRead.restart()
            }
            return
        }
        root.failedReads = 0
        for (const key in json) {
            if (json.hasOwnProperty(key)) {
                // Convert snake_case to CamelCase
                const camelCaseKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
                const m3Key = `m3${camelCaseKey}`
                Appearance.m3colors[m3Key] = json[key]
            }
        }

        Appearance.m3colors.darkmode = (Appearance.m3colors.m3background.hslLightness < 0.5)

        // Best-effort accent color sync: there's no Linux equivalent (GTK/Qt/KDE apps read
        // Appearance.m3colors directly or through their own matugen templates), but on
        // Windows the taskbar/title bars/Start only ever see DWM's own accent color, so push
        // this palette's primary color into it too. See Wallpaper::setAccentColor() for why
        // only AccentColor/ColorizationColor are set, not the Explorer accent palette.
        if (Platform.isWindows && json.primary && WindowsNative.wallpaper) {
            WindowsNative.wallpaper.setAccentColor(json.primary)
        }
    }

    function resetFilePathNextTime() {
        resetFilePathNextWallpaperChange.enabled = true
    }

    Connections {
        id: resetFilePathNextWallpaperChange
        enabled: false
        target: Config.options.background
        function onWallpaperPathChanged() {
            root.filePath = ""
            root.filePath = Directories.generatedMaterialThemePath
            resetFilePathNextWallpaperChange.enabled = false
        }
    }

    Timer {
        id: delayedFileRead
        interval: Config.options?.hacks?.arbitraryRaceConditionDelay ?? 100
        repeat: false
        running: false
        onTriggered: {
            root.applyColors(themeFileView.text())
        }
    }

	FileView {
        id: themeFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        // On Windows this only exists after the first successful matugen.exe run
        // (services/Wallpapers.qml); a missing file before that, or matugen.exe missing or
        // failing, just means "use Appearance's built-in default palette", not an error
        // worth printing.
        printErrors: !Platform.isWindows
        onFileChanged: {
            this.reload()
            delayedFileRead.start()
        }
        onLoadedChanged: {
            const fileContent = themeFileView.text()
            root.applyColors(fileContent)
        }
        onLoadFailed: root.resetFilePathNextTime();
    }

    function toggleLightDark() {
        const currentlyDark = Appearance.m3colors.darkmode;
        Wallpapers.setMode(!currentlyDark);
    }

    GlobalShortcut {
        name: "toggleLightDark"
        description: "Toggles between dark theme and light theme"

        onPressed: {
            root.toggleLightDark();
        }
    }

    IpcHandler {
        target: "theme"

        function toggleLightDark(): void {
            root.toggleLightDark();
        }
    }
}

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
    property bool ready: false

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
            } else {
                root.ready = true
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

        if (Platform.isWindows)
            ColorSchemes.applySecondaryOverride()

        if (Platform.isWindows && json.primary)
            root.syncAccentColor(json.primary)
        root.ready = true
    }

    property string pendingAccentColor: ""

    function syncAccentColor(primary) {
        if (accentStartupDelay.waiting) {
            root.pendingAccentColor = primary
            return
        }
        if (WindowsNative.wallpaper)
            WindowsNative.wallpaper.setAccentColor(primary)
    }

    Timer {
        id: accentStartupDelay
        property bool waiting: Platform.isWindows
        running: Platform.isWindows
        interval: 10000
        onTriggered: {
            waiting = false
            const primary = root.pendingAccentColor
            root.pendingAccentColor = ""
            if (primary && WindowsNative.wallpaper)
                WindowsNative.wallpaper.setAccentColor(primary)
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
        printErrors: !Platform.isWindows
        onFileChanged: {
            this.reload()
            delayedFileRead.start()
        }
        onLoadedChanged: {
            const fileContent = themeFileView.text()
            root.applyColors(fileContent)
        }
        onLoadFailed: {
            root.ready = true;
            root.resetFilePathNextTime();
        }
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

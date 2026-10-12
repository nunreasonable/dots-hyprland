import QtQuick
import Quickshell.Windows as QSWin
import qs
import qs.modules.common

QSWin.VideoWallpaper {
    id: root

    property bool shown: true
    property bool covered: false

    source: Config.options.background.wallpaperPath
    playing: root.shown
        && !(root.covered && (Config.options.background.pauseVideoWhenCovered ?? true))
        && !GlobalStates.screenLocked
        && !(Config.options.windowsPort.gameMode.enable ?? false)
}

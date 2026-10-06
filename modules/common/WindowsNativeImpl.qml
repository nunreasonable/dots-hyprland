import Quickshell.Windows as QSWin
import QtQml

QtObject {
    readonly property QtObject session: QSWin.Session
    readonly property QtObject stats: QSWin.SystemStats
    readonly property QtObject brightness: QSWin.Brightness
    readonly property QtObject keyboard: QSWin.Keyboard
    readonly property QtObject clipboard: QSWin.Clipboard
    readonly property QtObject credentials: QSWin.Credentials
    readonly property QtObject input: QSWin.Input
    readonly property QtObject nightLight: QSWin.NightLight
    readonly property QtObject hotkeys: QSWin.Hotkeys
    readonly property QtObject notificationSettings: QSWin.NotificationSettings
    readonly property QtObject network: QSWin.Network
    readonly property QtObject wallpaper: QSWin.Wallpaper
    readonly property QtObject imageTools: QSWin.ImageTools
    readonly property QtObject thumbnailer: QSWin.Thumbnailer
    readonly property QtObject fsUtils: QSWin.FsUtils
    readonly property QtObject taskbar: QSWin.Taskbar
    readonly property QtObject desktopLayer: QSWin.DesktopLayer
    readonly property QtObject screenshot: QSWin.Screenshot
    readonly property QtObject ocr: QSWin.Ocr
    readonly property QtObject screenRecorder: QSWin.ScreenRecorder
    readonly property QtObject terminalColors: QSWin.TerminalColors
    readonly property QtObject tiling: QSWin.Tiling
    readonly property QtObject blur: QSWin.BackdropBlur
}

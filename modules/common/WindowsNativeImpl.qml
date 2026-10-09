import Quickshell
import Quickshell.Windows as QSWin
import QtQml

QtObject {
    id: root

    readonly property string process: Quickshell.env("IIW_PROCESS") ?? ""
    readonly property bool full: !root.process || root.process === "shell"

    readonly property QtObject session: QSWin.Session
    readonly property QtObject stats: root.full ? QSWin.SystemStats : null
    readonly property QtObject brightness: root.full ? QSWin.Brightness : null
    readonly property QtObject keyboard: root.full ? QSWin.Keyboard : null
    readonly property QtObject clipboard: root.full ? QSWin.Clipboard : null
    readonly property QtObject credentials: root.full ? QSWin.Credentials : null
    readonly property QtObject input: root.full ? QSWin.Input : null
    readonly property QtObject nightLight: root.full ? QSWin.NightLight : null
    readonly property QtObject hotkeys: root.full ? QSWin.Hotkeys : null
    readonly property QtObject notificationSettings: root.full ? QSWin.NotificationSettings : null
    readonly property QtObject network: root.full ? QSWin.Network : null
    readonly property QtObject wallpaper: QSWin.Wallpaper
    readonly property QtObject imageTools: QSWin.ImageTools
    readonly property QtObject thumbnailer: root.full ? QSWin.Thumbnailer : null
    readonly property QtObject fsUtils: QSWin.FsUtils
    readonly property QtObject taskbar: root.full ? QSWin.Taskbar : null
    readonly property QtObject desktopLayer: root.full ? QSWin.DesktopLayer : null
    readonly property QtObject screenshot: root.full ? QSWin.Screenshot : null
    readonly property QtObject ocr: root.full ? QSWin.Ocr : null
    readonly property QtObject screenRecorder: root.full ? QSWin.ScreenRecorder : null
    readonly property QtObject terminalColors: root.full ? QSWin.TerminalColors : null
    readonly property QtObject tiling: root.full ? QSWin.Tiling : null
    readonly property QtObject superDrag: root.full ? QSWin.SuperDrag : null
    readonly property QtObject audioVisualizer: root.full ? QSWin.AudioVisualizer : null
    readonly property QtObject blur: root.full ? QSWin.BackdropBlur : null
    readonly property QtObject systemMonitor: root.full ? QSWin.SystemMonitor : null
    readonly property QtObject fileIndex: root.full ? QSWin.FileIndex : null
    readonly property QtObject accountAge: root.full || root.process === "settings" || root.process === "welcome" ? QSWin.AccountAge : null
}

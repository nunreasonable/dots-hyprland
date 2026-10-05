pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string firstRunFilePath: `${Directories.state}/user/first_run.txt`
    property string firstRunFileContent: "This file is just here to confirm you've been greeted :>"
    property string firstRunNotifSummary: "Welcome!"
    property string firstRunNotifBody: "Hit Super+/ for a list of keybinds"
    property string defaultWallpaperPath: FileUtils.trimFileProtocol(`${Directories.assetsPath}/images/default_wallpaper.png`)
    property string welcomeQmlPath: FileUtils.trimFileProtocol(Quickshell.shellPath("welcome.qml"))

    function load() {
        firstRunFileView.reload()
    }

    function enableNextTime() {
        if (Platform.isWindows) {
            Quickshell.execDetached(["cmd", "/c", "del", "/f", "/q", FileUtils.trimFileProtocol(root.firstRunFilePath).replace(/\//g, "\\")])
            return
        }
        Quickshell.execDetached(["rm", "-f", root.firstRunFilePath])
    }
    function disableNextTime() {
        if (Platform.isWindows) {
            firstRunFileView.setText(root.firstRunFileContent)
            return
        }
        Quickshell.execDetached(["bash", "-c", `echo '${root.firstRunFileContent}' > '${root.firstRunFilePath}'`])
    }

    function handleFirstRun() {
        if (Platform.isWindows) {
            Wallpapers.adoptSystemWallpaper();
            Quickshell.execDetached(["qs", "-p", root.welcomeQmlPath]);
            return;
        }
        Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, root.defaultWallpaperPath])
        Quickshell.execDetached(["bash", "-c", `qs -p '${root.welcomeQmlPath}'`])
    }

    FileView {
        id: firstRunFileView
        path: Qt.resolvedUrl(firstRunFilePath)
        onLoadFailed: (error) => {
            if (error == FileViewError.FileNotFound) {
                firstRunFileView.setText(root.firstRunFileContent)
                root.handleFirstRun()
            }
        }
    }
}

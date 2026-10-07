import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell.Io
import Quickshell

QuickToggleButton {
    id: root
    toggled: false
    visible: false

    readonly property string windowsDefaultCliPath: "C:/Program Files/Cloudflare/Cloudflare WARP/warp-cli.exe"
    property string cliPath: Platform.isWindows ? "" : "warp-cli"

    contentItem: CustomIcon {
        id: distroIcon
        source: 'cloudflare-dns-symbolic'

        anchors.centerIn: parent
        width: 16
        height: 16
        colorize: true
        color: root.toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    onClicked: {
        if (Platform.isWindows && !root.cliPath) return;
        if (toggled) {
            root.toggled = false
            Quickshell.execDetached([root.cliPath, "disconnect"])
        } else {
            root.toggled = true
            Quickshell.execDetached([root.cliPath, "connect"])
        }
    }

    function locateWindowsCli() {
        const fs = WindowsNative.fsUtils;
        if (!fs || root.cliPath) return;
        const found = fs.classify(root.windowsDefaultCliPath) === "file"
            ? root.windowsDefaultCliPath
            : fs.findExecutable("warp-cli.exe");
        if (!found) return;
        root.cliPath = found;
        fetchActiveState.running = true;
    }

    Component.onCompleted: if (Platform.isWindows) root.locateWindowsCli()

    Connections {
        target: Platform.isWindows ? WindowsNative : null
        function onReadyChanged() { root.locateWindowsCli() }
    }

    Process {
        id: connectProc
        command: [root.cliPath, "connect"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                Notifications.sendDesktop(
                    Translation.tr("Cloudflare WARP"),
                    Translation.tr("Connection failed. Please inspect manually with the <tt>warp-cli</tt> command"),
                    ["-a", "Shell"]
                )
            }
        }
    }

    Process {
        id: registrationProc
        command: [root.cliPath, "registration", "new"]
        onExited: (exitCode, exitStatus) => {
            console.log("Warp registration exited with code and status:", exitCode, exitStatus)
            if (exitCode === 0) {
                connectProc.running = true
            } else {
                Notifications.sendDesktop(
                    Translation.tr("Cloudflare WARP"),
                    Translation.tr("Registration failed. Please inspect manually with the <tt>warp-cli</tt> command"),
                    ["-a", "Shell"]
                )
            }
        }
    }

    Process {
        id: fetchActiveState
        running: !Platform.isWindows
        command: Platform.isWindows ? [root.cliPath, "status"] : ["bash", "-c", "warp-cli status"]
        stdout: StdioCollector {
            id: warpStatusCollector
            onStreamFinished: {
                if (warpStatusCollector.text.length > 0) {
                    root.visible = true
                }
                if (warpStatusCollector.text.includes("Unable")) {
                    registrationProc.running = true
                } else if (warpStatusCollector.text.includes("Connected")) {
                    root.toggled = true
                } else if (warpStatusCollector.text.includes("Disconnected")) {
                    root.toggled = false
                }
            }
        }
    }
    StyledToolTip {
        text: Translation.tr("Cloudflare WARP (1.1.1.1)")
    }
}

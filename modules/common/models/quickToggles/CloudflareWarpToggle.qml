import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import Quickshell
import Quickshell.Io

QuickToggleModel {
    id: root
    name: Translation.tr("Cloudflare WARP")

    readonly property string windowsDefaultCliPath: "C:/Program Files/Cloudflare/Cloudflare WARP/warp-cli.exe"
    property string cliPath: Platform.isWindows ? "" : "warp-cli"

    available: !Platform.isWindows
    toggled: false
    icon: "cloud_lock"

    mainAction: () => {
        if (Platform.isWindows && !root.cliPath) return;
        if (toggled) {
            root.toggled = false
            Quickshell.execDetached([root.cliPath, "disconnect"])
        } else {
            root.toggled = true
            Quickshell.execDetached([root.cliPath, "connect"])
        }
    }

    Process {
        id: locateCli
        running: Platform.isWindows
        command: ["powershell.exe", "-NoProfile", "-NonInteractive", "-Command",
            `$p = '${root.windowsDefaultCliPath}'; if (Test-Path -LiteralPath $p) { $p } else { $c = Get-Command 'warp-cli.exe' -ErrorAction SilentlyContinue; if ($c) { $c.Source } }`]
        stdout: StdioCollector {
            id: locateCliCollector
            onStreamFinished: {
                const found = locateCliCollector.text.trim();
                if (found.length > 0) {
                    root.cliPath = found;
                    fetchActiveState.running = true;
                }
            }
        }
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
                    root.available = true
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
    tooltipText: Translation.tr("Cloudflare WARP (1.1.1.1)")
}

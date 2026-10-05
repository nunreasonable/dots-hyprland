pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

/**
 * Provides some system info: distro, username.
 */
Singleton {
    id: root
    property string distroName: "Unknown"
    property string distroId: "unknown"
    property string distroIcon: "linux-symbolic"
    property string username: "user"
    property string homeUrl: ""
    property string documentationUrl: ""
    property string supportUrl: ""
    property string bugReportUrl: ""
    property string privacyPolicyUrl: ""
    property string logo: ""
    property string desktopEnvironment: ""
    property string windowingSystem: ""

    // Windows: no /etc/os-release or whoami; the edition and version come from the registry
    // (WindowsNative.session.osInfo), the links are Microsoft's own.
    property string windowsBuild: ""
    function loadWindowsInfo() {
        const info = WindowsNative.session?.osInfo() ?? ({});
        root.distroName = [info.name ?? "Windows", info.version ?? ""].join(" ").trim();
        root.windowsBuild = info.build ?? "";
        root.distroId = "windows";
        // Windows 11's logo is Microsoft's four squares; Windows 10 (builds below 22000) has the
        // window in perspective. The symbolic icon is recolored (bar, sidebar); the About page
        // shows the logo as is, so it gets the colored one.
        const windows10 = parseInt(root.windowsBuild) < 22000;
        root.distroIcon = windows10 ? "windows10-symbolic" : "microsoft-symbolic";
        root.logo = windows10 ? "windows10-logo" : "windows11-logo";
        root.username = Quickshell.env("USERNAME") || "user";
        root.desktopEnvironment = "Windows";
        root.windowingSystem = "Win32";
        root.homeUrl = "https://www.microsoft.com/windows";
        root.documentationUrl = "https://support.microsoft.com/windows";
        root.supportUrl = "https://support.microsoft.com/contactus";
        root.bugReportUrl = "feedback-hub:"; // Feedback Hub app
        root.privacyPolicyUrl = "https://privacy.microsoft.com/privacystatement";
    }
    Connections {
        target: Platform.isWindows ? WindowsNative : null
        function onReadyChanged() {
            if (WindowsNative.ready) root.loadWindowsInfo();
        }
    }

    Timer {
        triggeredOnStart: true
        interval: 1
        running: true
        repeat: false
        onTriggered: {
            if (Platform.isWindows) {
                root.loadWindowsInfo();
                return;
            }
            getUsername.running = true
            fileOsRelease.reload()
            const textOsRelease = fileOsRelease.text()

            // Extract the friendly name (PRETTY_NAME field, fallback to NAME)
            const prettyNameMatch = textOsRelease.match(/^PRETTY_NAME=['"](.+?)['"]/m)
            const nameMatch = textOsRelease.match(/^NAME=['"](.+?)['"]/m)
            distroName = prettyNameMatch ? prettyNameMatch[1] : (nameMatch ? nameMatch[1].replace(/Linux/i, "").trim() : "Unknown")

            // Extract the ID
            const idMatch = textOsRelease.match(/^ID=['"]?(.+?)['"]?$/m)
            distroId = idMatch ? idMatch[1] : "unknown"

            // Extract additional URLs and logo
            const homeUrlMatch = textOsRelease.match(/^HOME_URL=['"](.+?)['"]/m)
            homeUrl = homeUrlMatch ? homeUrlMatch[1] : ""
            const documentationUrlMatch = textOsRelease.match(/^DOCUMENTATION_URL=['"](.+?)['"]/m)
            documentationUrl = documentationUrlMatch ? documentationUrlMatch[1] : ""
            const supportUrlMatch = textOsRelease.match(/^SUPPORT_URL=['"](.+?)['"]/m)
            supportUrl = supportUrlMatch ? supportUrlMatch[1] : ""
            const bugReportUrlMatch = textOsRelease.match(/^BUG_REPORT_URL=['"](.+?)['"]/m)
            bugReportUrl = bugReportUrlMatch ? bugReportUrlMatch[1] : ""
            const privacyPolicyUrlMatch = textOsRelease.match(/^PRIVACY_POLICY_URL=['"](.+?)['"]/m)
            privacyPolicyUrl = privacyPolicyUrlMatch ? privacyPolicyUrlMatch[1] : ""
            const logoFieldMatch = textOsRelease.match(/^LOGO=['"]?(.+?)['"]?$/m)
            logo = logoFieldMatch ? logoFieldMatch[1] : ""

            // Update the distroIcon property based on distroId
            switch (distroId) {
                case "artix":
                case "arch": distroIcon = "arch-symbolic"; break;
                case "manjaro": distroIcon = "manjaro-symbolic"; break;
                case "endeavouros": distroIcon = "endeavouros-symbolic"; break;
                case "cachyos": distroIcon = "cachyos-symbolic"; break;
                case "nixos": distroIcon = "nixos-symbolic"; break;
                case "fedora": distroIcon = "fedora-symbolic"; break;
                case "linuxmint":
                case "ubuntu":
                case "zorin":
                case "popos": distroIcon = "ubuntu-symbolic"; break;
                case "debian":
                case "raspbian":
                case "kali": distroIcon = "debian-symbolic"; break;
                case "funtoo":
                case "gentoo": distroIcon = "gentoo-symbolic"; break;
                default: distroIcon = "linux-symbolic"; break;
            }
            if (textOsRelease.toLowerCase().includes("nyarch")) {
                distroIcon = "nyarch-symbolic"
            }

            if (logo.trim().length === 0) {
                logo = distroIcon
            }

        }
    }

    Process {
        id: getUsername
        command: ["whoami"]
        stdout: SplitParser {
            onRead: data => {
                root.username = data.trim()
            }
        }
    }

    Process {
        id: getDesktopEnvironment
        running: !Platform.isWindows
        command: ["bash", "-c", "echo $XDG_CURRENT_DESKTOP,$WAYLAND_DISPLAY"]
        stdout: StdioCollector {
            id: deCollector
            onStreamFinished: {
                const [desktop, wayland] = deCollector.text.split(",")
                root.desktopEnvironment = desktop.trim()
                root.windowingSystem = wayland.trim().length > 0 ? "Wayland" : "X11" // Are there others? 🤔
            }
        }
    }

    FileView {
        id: fileOsRelease
        path: Platform.isWindows ? "" : "/etc/os-release" // see the Windows branch above
    }
}
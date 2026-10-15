import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "box"
        title: Translation.tr("Distro")
        
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            IconImage {
                implicitSize: 80
                source: Quickshell.iconPath(SystemInfo.logo)
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                // spacing: 10
                StyledText {
                    text: SystemInfo.distroName
                    font.pixelSize: Appearance.font.pixelSize.title
                }
                StyledText {
                    visible: SystemInfo.windowsBuild !== ""
                    text: Translation.tr("Build %1").arg(SystemInfo.windowsBuild)
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.normal
                    text: SystemInfo.homeUrl
                    textFormat: Text.MarkdownText
                    onLinkActivated: (link) => {
                        Qt.openUrlExternally(link)
                    }
                    PointingHandLinkHover {}
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 5

            RippleButtonWithIcon {
                materialIcon: "auto_stories"
                mainText: Translation.tr("Documentation")
                onClicked: {
                    Qt.openUrlExternally(SystemInfo.documentationUrl)
                }
            }
            RippleButtonWithIcon {
                materialIcon: "support"
                mainText: Translation.tr("Help & Support")
                onClicked: {
                    Qt.openUrlExternally(SystemInfo.supportUrl)
                }
            }
            RippleButtonWithIcon {
                materialIcon: "bug_report"
                mainText: Translation.tr("Report a Bug")
                onClicked: {
                    Qt.openUrlExternally(SystemInfo.bugReportUrl)
                }
            }
            RippleButtonWithIcon {
                materialIcon: "policy"
                materialIconFill: false
                mainText: Translation.tr("Privacy Policy")
                onClicked: {
                    Qt.openUrlExternally(SystemInfo.privacyPolicyUrl)
                }
            }
            
        }

    }
    ContentSection {
        visible: Platform.isWindows
        icon: "update"
        title: Translation.tr("ii-windows updates")

        NoticeBox {
            Layout.fillWidth: true
            visible: SelfUpdate.updateAvailable
            materialIcon: "new_releases"
            text: Translation.tr("Update available: %1 \"%2\"").arg(SelfUpdate.latestVersion).arg(SelfUpdate.releaseName)
                + (SelfUpdate.downloading ? "\n" + Translation.tr("Downloading the update…") : "")
                + (!SelfUpdate.downloading && SelfUpdate.lastError !== "" ? "\n" + SelfUpdate.lastError : "")

            RippleButtonWithIcon {
                materialIcon: "open_in_new"
                mainText: Translation.tr("What's new")
                onClicked: {
                    Qt.openUrlExternally(SelfUpdate.htmlUrl)
                }
            }
            RippleButtonWithIcon {
                materialIcon: "system_update"
                mainText: Translation.tr("Update")
                enabled: !SelfUpdate.downloading
                onClicked: {
                    SelfUpdate.startUpdate()
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: !SelfUpdate.updateAvailable
            wrapMode: Text.WordWrap
            color: Appearance.colors.colSubtext
            text: SelfUpdate.checking
                ? Translation.tr("Checking for updates…")
                : SelfUpdate.lastError !== ""
                    ? SelfUpdate.lastError
                    : SelfUpdate.installedVersion !== ""
                        ? Translation.tr("ii-windows %1 is up to date.").arg(SelfUpdate.installedVersion)
                        : Translation.tr("Couldn't determine the installed version.")
        }

        Flow {
            Layout.fillWidth: true
            visible: !SelfUpdate.updateAvailable
            spacing: 5

            RippleButtonWithIcon {
                materialIcon: "refresh"
                mainText: Translation.tr("Check for updates")
                enabled: !SelfUpdate.checking
                onClicked: {
                    SelfUpdate.refresh()
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "notifications"
            text: Translation.tr("Notify me when a new version is available")
            checked: Config.options.windowsPort.selfUpdate.notify
            onCheckedChanged: {
                if (checked !== Config.options.windowsPort.selfUpdate.notify)
                    Config.options.windowsPort.selfUpdate.notify = checked;
            }
        }
    }
    ContentSection {
        visible: Platform.isWindows
        icon: "bug_report"
        title: Translation.tr("Report a problem")

        StyledText {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Appearance.colors.colSubtext
            text: ProblemReport.collecting
                ? Translation.tr("Collecting the logs…")
                : ProblemReport.lastError !== ""
                    ? Translation.tr("Couldn't create the report: %1").arg(ProblemReport.lastError)
                    : ProblemReport.zipPath !== ""
                        ? Translation.tr("Saved %1. Attach it to the issue that just opened.").arg(ProblemReport.zipPath)
                        : Translation.tr("Saves ii's logs and some system info (Windows build, GPU, screens, fonts) to a zip on your Desktop and opens a new issue on GitHub. Your user name is taken out of the paths; have a look at the files before you send them. A crash dump helps with crashes, but it can hold bits of what ii had in memory, like clipboard text or chats, so it only goes in if you turn it on.")
        }

        ConfigSwitch {
            buttonIcon: "memory"
            text: Translation.tr("Include the latest crash dump")
            enabled: !ProblemReport.collecting
            checked: ProblemReport.includeCrashDump
            onCheckedChanged: {
                ProblemReport.includeCrashDump = checked;
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 5

            RippleButtonWithIcon {
                materialIcon: "bug_report"
                mainText: Translation.tr("Report a problem")
                enabled: !ProblemReport.collecting
                onClicked: {
                    ProblemReport.collect()
                }
            }
        }
    }
    ContentSection {
        icon: "folder_managed"
        title: Translation.tr("Dotfiles")

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            IconImage {
                implicitSize: 80
                source: Quickshell.iconPath("illogical-impulse")
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                // spacing: 10
                StyledText {
                    text: Translation.tr("illogical-impulse")
                    font.pixelSize: Appearance.font.pixelSize.title
                }
                StyledText {
                    text: "https://github.com/end-4/dots-hyprland"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    textFormat: Text.MarkdownText
                    onLinkActivated: (link) => {
                        Qt.openUrlExternally(link)
                    }
                    PointingHandLinkHover {}
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 5

            RippleButtonWithIcon {
                materialIcon: "auto_stories"
                mainText: Translation.tr("Documentation")
                onClicked: {
                    Qt.openUrlExternally("https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/02usage/")
                }
            }
            RippleButtonWithIcon {
                materialIcon: "adjust"
                materialIconFill: false
                mainText: Translation.tr("Issues")
                onClicked: {
                    Qt.openUrlExternally("https://github.com/end-4/dots-hyprland/issues")
                }
            }
            RippleButtonWithIcon {
                materialIcon: "forum"
                mainText: Translation.tr("Discussions")
                onClicked: {
                    Qt.openUrlExternally("https://github.com/end-4/dots-hyprland/discussions")
                }
            }
            RippleButtonWithIcon {
                materialIcon: "favorite"
                mainText: Translation.tr("Donate")
                onClicked: {
                    Qt.openUrlExternally("https://github.com/sponsors/end-4")
                }
            }
        }

        Flow {
            visible: Platform.isWindows
            Layout.fillWidth: true
            spacing: 5

            RippleButtonWithIcon {
                materialIcon: "desktop_windows"
                mainText: Translation.tr("ii for Windows")
                onClicked: {
                    Qt.openUrlExternally("https://github.com/nunreasonable/dots-hyprland/tree/ii-windows")
                }
            }
            RippleButtonWithIcon {
                materialIcon: "deployed_code"
                mainText: Translation.tr("Quickshell for Windows")
                onClicked: {
                    Qt.openUrlExternally("https://github.com/nunreasonable/quickshell/tree/windows")
                }
            }

            
        }
    }
}

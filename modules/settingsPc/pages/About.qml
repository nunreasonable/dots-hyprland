import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets as W
import qs.modules.settingsPc.widgets

ContentPage {
    id: page
    forceWidth: true
    bottomContentPadding: 35

    component HeroCard: Rectangle {
        id: hero
        property string iconSource: ""
        property string title: ""
        property string subtitle: ""
        property string link: ""
        property bool showPalette: false

        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        implicitHeight: heroRow.implicitHeight + 48
        radius: 24
        color: Appearance.colors.colLayer1

        RowLayout {
            id: heroRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 24
            spacing: 24

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 110
                implicitHeight: 110
                radius: 20
                color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.9)

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 72
                    source: hero.iconSource
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

                W.StyledText {
                    Layout.fillWidth: true
                    text: hero.title
                    font.pixelSize: Appearance.font.pixelSize.hugeass
                    font.weight: Font.ExtraBold
                    color: Appearance.colors.colOnSurface
                    elide: Text.ElideRight
                }

                W.StyledText {
                    Layout.fillWidth: true
                    visible: hero.subtitle.length > 0
                    text: hero.subtitle
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }

                W.StyledText {
                    Layout.fillWidth: true
                    visible: hero.link.length > 0
                    text: hero.link
                    font.pixelSize: Appearance.font.pixelSize.small
                    textFormat: Text.MarkdownText
                    elide: Text.ElideRight
                    onLinkActivated: link => {
                        Qt.openUrlExternally(link);
                    }
                    W.PointingHandLinkHover {}
                }

                Row {
                    visible: hero.showPalette
                    Layout.topMargin: 4
                    spacing: -6

                    Repeater {
                        model: [
                            Appearance.m3colors.m3primary,
                            Appearance.m3colors.m3secondary,
                            Appearance.m3colors.m3tertiary,
                            Appearance.m3colors.m3error,
                            Appearance.m3colors.m3primaryContainer,
                            Appearance.m3colors.m3secondaryContainer,
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: 28
                            height: 28
                            radius: width / 2
                            color: modelData
                            z: index
                            border.width: 2
                            border.color: Appearance.colors.colLayer1
                        }
                    }
                }
            }
        }
    }

    HeroCard {
        Layout.topMargin: 35
        iconSource: Quickshell.iconPath(SystemInfo.logo)
        title: SystemInfo.distroName
        subtitle: SystemInfo.windowsBuild !== "" ? Translation.tr("Build %1").arg(SystemInfo.windowsBuild) : ""
        link: SystemInfo.homeUrl
        showPalette: true
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.topMargin: -16
        columns: 2
        rowSpacing: 8
        columnSpacing: 8

        AboutCard {
            Layout.fillWidth: true
            icon: "auto_stories"
            iconShape: W.MaterialShape.Shape.Pentagon
            label: Translation.tr("Distro")
            value: Translation.tr("Documentation")
            clickAction: () => Qt.openUrlExternally(SystemInfo.documentationUrl)
        }
        AboutCard {
            Layout.fillWidth: true
            icon: "support"
            iconShape: W.MaterialShape.Shape.ClamShell
            label: Translation.tr("Distro")
            value: Translation.tr("Help & Support")
            clickAction: () => Qt.openUrlExternally(SystemInfo.supportUrl)
        }
        AboutCard {
            Layout.fillWidth: true
            icon: "bug_report"
            iconShape: W.MaterialShape.Shape.Cookie6Sided
            label: Translation.tr("Distro")
            value: Translation.tr("Report a Bug")
            clickAction: () => Qt.openUrlExternally(SystemInfo.bugReportUrl)
        }
        AboutCard {
            Layout.fillWidth: true
            icon: "policy"
            iconShape: W.MaterialShape.Shape.Gem
            label: Translation.tr("Distro")
            value: Translation.tr("Privacy Policy")
            clickAction: () => Qt.openUrlExternally(SystemInfo.privacyPolicyUrl)
        }
    }

    HeroCard {
        iconSource: Quickshell.iconPath("illogical-impulse")
        title: Translation.tr("illogical-impulse")
        link: "https://github.com/end-4/dots-hyprland"
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.topMargin: -16
        columns: 2
        rowSpacing: 8
        columnSpacing: 8

        AboutCard {
            Layout.fillWidth: true
            icon: "auto_stories"
            iconShape: W.MaterialShape.Shape.Sunny
            label: Translation.tr("Dotfiles")
            value: Translation.tr("Documentation")
            clickAction: () => Qt.openUrlExternally("https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/02usage/")
        }
        AboutCard {
            Layout.fillWidth: true
            icon: "adjust"
            iconShape: W.MaterialShape.Shape.Cookie9Sided
            label: Translation.tr("Dotfiles")
            value: Translation.tr("Issues")
            clickAction: () => Qt.openUrlExternally("https://github.com/end-4/dots-hyprland/issues")
        }
        AboutCard {
            Layout.fillWidth: true
            icon: "forum"
            iconShape: W.MaterialShape.Shape.Cookie12Sided
            label: Translation.tr("Dotfiles")
            value: Translation.tr("Discussions")
            clickAction: () => Qt.openUrlExternally("https://github.com/end-4/dots-hyprland/discussions")
        }
        AboutCard {
            Layout.fillWidth: true
            icon: "favorite"
            iconShape: W.MaterialShape.Shape.Heart
            label: Translation.tr("Dotfiles")
            value: Translation.tr("Donate")
            clickAction: () => Qt.openUrlExternally("https://github.com/sponsors/end-4")
        }
        AboutCard {
            visible: Platform.isWindows
            Layout.fillWidth: true
            icon: "desktop_windows"
            iconShape: W.MaterialShape.Shape.Square
            label: "GitHub"
            value: Translation.tr("ii for Windows")
            clickAction: () => Qt.openUrlExternally("https://github.com/nunreasonable/dots-hyprland/tree/ii-windows")
        }
        AboutCard {
            visible: Platform.isWindows
            Layout.fillWidth: true
            icon: "deployed_code"
            iconShape: W.MaterialShape.Shape.Burst
            label: "GitHub"
            value: Translation.tr("Quickshell for Windows")
            clickAction: () => Qt.openUrlExternally("https://github.com/nunreasonable/quickshell/tree/windows")
        }
    }
}

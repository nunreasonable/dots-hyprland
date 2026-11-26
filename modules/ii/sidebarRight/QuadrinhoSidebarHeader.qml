pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings

Item {
    id: root

    property bool editMode: false
    property string settingsQmlPath: ""
    signal editToggled

    implicitHeight: 78

    Item {
        id: avatarBox
        x: 6
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -3
        width: 58
        height: 58

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: QuadrinhoTheme.paper
            border.width: 2
            border.color: QuadrinhoTheme.ink
        }

        UserAvatar {
            anchors.fill: parent
            anchors.margins: 4
            iconSize: 34
            iconColor: QuadrinhoTheme.ink
            color: QuadrinhoTheme.paper
            layer.enabled: true
            layer.effect: MultiEffect {
                saturation: -1
                contrast: 0.15
            }
        }
    }

    ColumnLayout {
        anchors.left: avatarBox.right
        anchors.leftMargin: 12
        anchors.right: buttons.left
        anchors.rightMargin: 6
        anchors.verticalCenter: avatarBox.verticalCenter
        spacing: 0

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: Config.options.profile.displayName === "" ? SystemInfo.username : Config.options.profile.displayName
            color: QuadrinhoTheme.ink
            font.family: QuadrinhoTheme.boldFont
            font.weight: Font.Bold
            font.pixelSize: Appearance.font.pixelSize.huge
        }

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: Translation.tr("Up • %1").arg(DateTime.uptime)
            color: QuadrinhoTheme.ink
            font.family: QuadrinhoTheme.uiFont
            font.pixelSize: Appearance.font.pixelSize.smaller
        }
    }

    Row {
        id: buttons
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 2
        anchors.topMargin: 2
        spacing: 2

        HeaderButton {
            symbol: "edit"
            toggled: root.editMode
            tip: Translation.tr("Edit sidebar")
            onClicked: root.editToggled()
        }
        HeaderButton {
            symbol: "restart_alt"
            tip: Translation.tr("Reload Hyprland & Quickshell")
            onClicked: {
                if (!Platform.isWindows)
                    Quickshell.execDetached(["hyprctl", "reload"]);
                Quickshell.reload(true);
            }
        }
        HeaderButton {
            symbol: "settings"
            tip: Translation.tr("Settings")
            onClicked: {
                GlobalStates.sidebarRightOpen = false;
                if (Platform.isWindows)
                    SettingsApp.open();
                else
                    Quickshell.execDetached(["qs", "-p", root.settingsQmlPath]);
            }
        }
        HeaderButton {
            symbol: "power_settings_new"
            tip: Translation.tr("Session")
            onClicked: GlobalStates.sessionOpen = true
        }
    }

    component HeaderButton: RippleButton {
        id: button
        property string symbol
        property string tip
        implicitWidth: 34
        implicitHeight: 34
        buttonRadius: 0
        colBackground: "transparent"
        colBackgroundHover: Appearance.colors.colLayer1Hover
        colBackgroundToggled: QuadrinhoTheme.ink
        colBackgroundToggledHover: QuadrinhoTheme.ink
        colRipple: Appearance.colors.colLayer1Active
        colRippleToggled: Appearance.colors.colLayer1Active

        contentItem: MaterialSymbol {
            horizontalAlignment: Text.AlignHCenter
            text: button.symbol
            iconSize: 22
            color: button.toggled ? QuadrinhoTheme.paper : QuadrinhoTheme.ink
        }

        StyledToolTip {
            text: button.tip
        }
    }
}

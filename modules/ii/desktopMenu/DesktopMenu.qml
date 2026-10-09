pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: desktopMenuScope

    component DesktopMenuItem: RippleButton {
        id: itemRoot
        property string iconName: ""
        Layout.fillWidth: true
        implicitHeight: 36
        buttonRadius: Appearance.rounding.small
        colBackground: "transparent"

        contentItem: RowLayout {
            spacing: 10
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.fill: parent

            MaterialSymbol {
                text: itemRoot.iconName
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnLayer0
            }
            StyledText {
                Layout.fillWidth: true
                text: itemRoot.buttonText
                color: Appearance.colors.colOnLayer0
            }
        }
    }

    function openAt(screen, x, y) {
        if (!screen)
            return;
        GlobalStates.desktopMenuScreen = screen;
        GlobalStates.desktopMenuX = x;
        GlobalStates.desktopMenuY = y;
        GlobalStates.desktopMenuOpen = true;
    }

    function openOnCursorOrFocusedScreen() {
        if (Platform.isWindows) {
            const cursor = WindowsNative.input?.cursorPosition() ?? {};
            const cursorScreen = Quickshell.screens.find(s => s.name === cursor.screen);
            const focusedScreen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name);
            const screen = cursorScreen ?? focusedScreen ?? Quickshell.screens[0];
            if (!screen)
                return;
            desktopMenuScope.openAt(screen, cursorScreen ? cursor.x : screen.width / 2, cursorScreen ? cursor.y : screen.height / 2);
            return;
        }
        const screen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
        if (!screen)
            return;
        desktopMenuScope.openAt(screen, screen.width / 2, screen.height / 2);
    }

    function toggle() {
        if (GlobalStates.desktopMenuOpen) {
            GlobalStates.desktopMenuOpen = false;
            return;
        }
        desktopMenuScope.openOnCursorOrFocusedScreen();
    }

    IpcHandler {
        target: "desktopMenu"

        function toggle(): void {
            desktopMenuScope.toggle();
        }
        function open(): void {
            desktopMenuScope.openOnCursorOrFocusedScreen();
        }
        function close(): void {
            GlobalStates.desktopMenuOpen = false;
        }
    }

    GlobalShortcut {
        name: "desktopMenuToggle"
        description: "Toggles ii's desktop menu (wallpaper, settings) at the cursor"

        onPressed: desktopMenuScope.toggle()
    }

    LazyLoader {
        active: GlobalStates.desktopMenuOpen

        PanelWindow {
            id: root
            screen: GlobalStates.desktopMenuScreen
            visible: GlobalStates.desktopMenuOpen

            WlrLayershell.namespace: "quickshell:desktopMenu"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            mask: Region {
                item: menuCard
            }

            Keys.onEscapePressed: GlobalStates.desktopMenuOpen = false

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPressed: GlobalStates.desktopMenuOpen = false
            }

            StyledRectangularShadow {
                target: menuCard
            }
            Rectangle {
                id: menuCard
                x: Math.min(Math.max(GlobalStates.desktopMenuX, 0), Math.max(0, root.width - implicitWidth))
                y: Math.min(Math.max(GlobalStates.desktopMenuY, 0), Math.max(0, root.height - implicitHeight))
                implicitWidth: 240
                implicitHeight: menuColumn.implicitHeight + menuColumn.anchors.margins * 2
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                MouseArea {
                    anchors.fill: parent
                    onPressed: mouse => {
                        mouse.accepted = true;
                    }
                }

                ColumnLayout {
                    id: menuColumn
                    anchors {
                        fill: parent
                        margins: 6
                    }
                    spacing: 2

                    DesktopMenuItem {
                        iconName: "wallpaper"
                        buttonText: Translation.tr("Wallpaper & style")
                        onClicked: {
                            GlobalStates.desktopMenuOpen = false;
                            GlobalStates.wallpaperSelectorOpen = true;
                        }
                    }
                    DesktopMenuItem {
                        iconName: "add_photo_alternate"
                        buttonText: Translation.tr("Live wallpaper...")
                        onClicked: {
                            GlobalStates.desktopMenuOpen = false;
                            Wallpapers.openFallbackPicker();
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        Layout.bottomMargin: 2
                        height: 1
                        color: Appearance.colors.colOutlineVariant
                    }
                    DesktopMenuItem {
                        iconName: "settings"
                        buttonText: Translation.tr("Settings")
                        onClicked: {
                            GlobalStates.desktopMenuOpen = false;
                            SettingsApp.open();
                        }
                    }
                }
            }
        }
    }
}

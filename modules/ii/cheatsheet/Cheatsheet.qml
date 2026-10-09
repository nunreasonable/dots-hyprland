import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.synchronizer
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope { // Scope
    id: root
    property var tabButtonList: Platform.isWindows ? [
        {
            "icon": "keyboard",
            "name": Translation.tr("Keybinds")
        },
        {
            "icon": "monitor_heart",
            "name": Translation.tr("System")
        },
        {
            "icon": "experiment",
            "name": Translation.tr("Elements")
        },
    ] : [
        {
            "icon": "keyboard",
            "name": Translation.tr("Keybinds")
        },
        {
            "icon": "experiment",
            "name": Translation.tr("Elements")
        },
    ]
    readonly property int systemTabIndex: Platform.isWindows ? 1 : -1
    property bool open: false

    Loader {
        id: cheatsheetLoader
        property bool kept: false
        active: root.open || (Platform.isWindows && cheatsheetLoader.kept)
        asynchronous: Platform.isWindows && !root.open
        onLoaded: cheatsheetLoader.kept = true

        sourceComponent: PanelWindow { // Window
            id: cheatsheetRoot
            visible: root.open

            anchors {
                top: !Platform.isWindows
                bottom: !Platform.isWindows
                left: !Platform.isWindows
                right: !Platform.isWindows
            }

            function hide() {
                root.open = false;
            }
            exclusiveZone: 0
            implicitWidth: cheatsheetBackground.width + Appearance.sizes.elevationMargin * 2
            implicitHeight: cheatsheetBackground.height + Appearance.sizes.elevationMargin * 2
            WlrLayershell.namespace: "quickshell:cheatsheet"
            // Setting this value makes it take its sweet time to open
            // WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            mask: Region {
                item: cheatsheetBackground
            }

            Component.onCompleted: {
                if (cheatsheetRoot.visible)
                    GlobalFocusGrab.addDismissable(cheatsheetRoot);
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(cheatsheetRoot);
            }
            onVisibleChanged: {
                if (cheatsheetRoot.visible)
                    GlobalFocusGrab.addDismissable(cheatsheetRoot);
                else
                    GlobalFocusGrab.removeDismissable(cheatsheetRoot);
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    cheatsheetRoot.hide();
                }
            }

            // Background
            StyledRectangularShadow {
                target: cheatsheetBackground
            }
            Rectangle {
                id: cheatsheetBackground
                anchors.centerIn: parent
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                radius: Appearance.rounding.windowRounding
                property real padding: 20
                implicitWidth: cheatsheetColumnLayout.implicitWidth + padding * 2
                implicitHeight: cheatsheetColumnLayout.implicitHeight + padding * 2

                Keys.onPressed: event => { // Esc to close
                    if (event.key === Qt.Key_Escape) {
                        cheatsheetRoot.hide();
                    }
                    if (event.modifiers === Qt.ControlModifier) {
                        if (event.key === Qt.Key_PageDown) {
                            tabBar.incrementCurrentIndex();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_PageUp) {
                            tabBar.decrementCurrentIndex();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Tab) {
                            tabBar.setCurrentIndex((tabBar.currentIndex + 1) % root.tabButtonList.length);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Backtab) {
                            tabBar.setCurrentIndex((tabBar.currentIndex - 1 + root.tabButtonList.length) % root.tabButtonList.length);
                            event.accepted = true;
                        }
                    }
                }

                RippleButton { // Close button
                    id: closeButton
                    focus: cheatsheetRoot.visible
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.full
                    anchors {
                        top: parent.top
                        right: parent.right
                        topMargin: 20
                        rightMargin: 20
                    }

                    onClicked: {
                        cheatsheetRoot.hide();
                    }

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.title
                        text: "close"
                    }
                }

                ColumnLayout { // Real content
                    id: cheatsheetColumnLayout
                    anchors.centerIn: parent
                    spacing: 10

                    Toolbar {
                        Layout.alignment: Qt.AlignHCenter
                        enableShadow: false
                        ToolbarTabBar {
                            id: tabBar
                            tabButtonList: root.tabButtonList

                            Synchronizer on currentIndex {
                                property alias source: swipeView.currentIndex
                            }
                        }
                    }

                    SwipeView { // Content pages
                        id: swipeView
                        Layout.topMargin: 5
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10
                        currentIndex: Platform.isWindows ? 0 : Persistent.states.cheatsheet.tabIndex
                        onCurrentIndexChanged: {
                            Persistent.states.cheatsheet.tabIndex = currentIndex;
                        }
                        Component.onCompleted: {
                            if (Platform.isWindows)
                                currentIndex = Persistent.states.cheatsheet.tabIndex;
                        }

                        implicitWidth: Math.min(Math.max.apply(null, contentChildren.map(child => child.implicitWidth || 0)), (cheatsheetRoot.screen?.width ?? 100000) - (Appearance.sizes.elevationMargin + cheatsheetBackground.padding) * 2 - 32)
                        implicitHeight: Math.min(Math.max.apply(null, contentChildren.map(child => child.implicitHeight || 0)), (cheatsheetRoot.screen?.height ?? 100000) - (Appearance.sizes.elevationMargin + cheatsheetBackground.padding) * 2 - 140)

                        clip: true
                        layer.enabled: !Platform.isWindows
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: swipeView.width
                                height: swipeView.height
                                radius: Appearance.rounding.small
                            }
                        }

                        CheatsheetKeybinds {
                            loadAsync: Platform.isWindows && !root.open
                        }
                        Repeater {
                            model: Platform.isWindows ? 1 : 0
                            delegate: CheatsheetSystem {
                                loadAsync: Platform.isWindows && !root.open
                            }
                        }
                        CheatsheetPeriodicTable {
                            loadAsync: Platform.isWindows && !root.open
                        }
                    }
                }
            }
        }
    }

    Binding {
        when: Platform.isWindows && WindowsNative.ready && WindowsNative.systemMonitor !== null
        target: WindowsNative.systemMonitor
        property: "active"
        value: root.open && Persistent.states.cheatsheet.tabIndex === root.systemTabIndex
    }

    IpcHandler {
        target: "cheatsheet"

        function toggle(): void {
            root.open = !root.open;
        }

        function close(): void {
            root.open = false;
        }

        function open(): void {
            root.open = true;
        }
    }

    GlobalShortcut {
        name: "cheatsheetToggle"
        description: "Toggles cheatsheet on press"

        onPressed: {
            root.open = !root.open;
        }
    }

    GlobalShortcut {
        name: "cheatsheetOpen"
        description: "Opens cheatsheet on press"

        onPressed: {
            root.open = true;
        }
    }

    GlobalShortcut {
        name: "cheatsheetClose"
        description: "Closes cheatsheet on press"

        onPressed: {
            root.open = false;
        }
    }
}

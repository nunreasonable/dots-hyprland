pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    readonly property bool open: GlobalStates.claudePanelOpen
    property bool shown: false
    property string selectedId: ""
    readonly property var sessions: ClaudeCode.sessions
    readonly property var selected: ClaudeCode.sessionsById[root.selectedId] ?? root.sessions[0] ?? null

    function close() {
        GlobalStates.claudePanelOpen = false;
    }

    function step(delta) {
        if (root.sessions.length === 0)
            return;
        const index = root.sessions.findIndex(session => session.id === root.selected?.id);
        root.selectedId = root.sessions[Math.max(0, Math.min(root.sessions.length - 1, index + delta))].id;
    }

    function resume(session) {
        root.close();
        ClaudeCode.resume(session);
    }

    function start(folder) {
        root.close();
        ClaudeCode.start(folder);
    }

    function openFolder(folder) {
        root.close();
        ClaudeCode.openFolder(folder);
    }

    onOpenChanged: {
        if (root.open) {
            hideTimer.stop();
            Qt.callLater(() => root.shown = root.open);
        } else {
            root.shown = false;
            hideTimer.restart();
        }
    }

    Component.onCompleted: {
        if (root.open)
            Qt.callLater(() => root.shown = root.open);
    }

    Component.onDestruction: {
        GlobalStates.claudePanelOpen = false;
        ClaudeCode.active = false;
    }

    Binding {
        target: ClaudeCode
        property: "active"
        value: root.open
    }

    Timer {
        id: hideTimer
        interval: Appearance.animation.elementMoveFast.duration + 50
    }

    Loader {
        active: root.open || hideTimer.running

        sourceComponent: PanelWindow {
            id: panelWindow
            visible: true
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

            anchors {
                top: !Platform.isWindows
                bottom: !Platform.isWindows
                left: !Platform.isWindows
                right: !Platform.isWindows
            }

            readonly property real screenWidth: panelWindow.screen?.width ?? 1366
            readonly property real screenHeight: panelWindow.screen?.height ?? 768
            readonly property real sideWidth: Math.max(240, Math.min(300, Math.round(background.width * 0.26)))

            exclusiveZone: 0
            implicitWidth: background.width + Appearance.sizes.elevationMargin * 2
            implicitHeight: background.height + Appearance.sizes.elevationMargin * 2
            WlrLayershell.namespace: "quickshell:claudePanel"
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"

            mask: Region {
                x: background.x
                y: background.y
                width: root.open ? background.width : 0
                height: root.open ? background.height : 0
            }

            Component.onCompleted: {
                GlobalFocusGrab.addDismissable(panelWindow);
                Qt.callLater(() => background.forceActiveFocus());
            }
            Component.onDestruction: GlobalFocusGrab.removeDismissable(panelWindow)

            Connections {
                target: root
                function onOpenChanged() {
                    if (root.open) {
                        GlobalFocusGrab.addDismissable(panelWindow);
                        Qt.callLater(() => background.forceActiveFocus());
                    } else {
                        GlobalFocusGrab.removeDismissable(panelWindow);
                    }
                }
            }

            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    root.close();
                }
            }

            StyledRectangularShadow {
                target: background
                visible: !SekaiTheme.active
                opacity: background.opacity
                scale: background.scale
            }

            Rectangle {
                id: background
                anchors.centerIn: parent
                width: Math.min(1100, panelWindow.screenWidth - 80)
                height: Math.min(660, panelWindow.screenHeight - 120)
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                radius: Appearance.rounding.windowRounding
                focus: true
                opacity: root.shown ? 1 : 0
                scale: root.shown ? 1 : 0.96

                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on scale {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                SekaiShadow {
                    radius: background.radius
                }
                SekaiFrame {
                    radius: background.radius
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.close();
                    } else if (event.key === Qt.Key_Down) {
                        root.step(1);
                    } else if (event.key === Qt.Key_Up) {
                        root.step(-1);
                    } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && root.selected) {
                        root.resume(root.selected);
                    } else {
                        return;
                    }
                    event.accepted = true;
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        MaterialSymbol {
                            text: "asterisk"
                            iconSize: Appearance.font.pixelSize.title
                            color: Appearance.colors.colPrimary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                text: "Claude Code"
                                font.family: Appearance.font.family.title
                                font.pixelSize: Appearance.font.pixelSize.title
                                color: Appearance.colors.colOnLayer0
                            }
                            StyledText {
                                Layout.fillWidth: true
                                visible: root.sessions.length > 0
                                text: Translation.tr("%1 recent sessions").arg(root.sessions.length)
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                elide: Text.ElideRight
                            }
                        }

                        RippleButton {
                            implicitWidth: 40
                            implicitHeight: 40
                            buttonRadius: Appearance.rounding.full
                            enabled: !ClaudeCode.loading
                            onClicked: ClaudeCode.refresh()

                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: "refresh"
                                iconSize: Appearance.font.pixelSize.title
                            }

                            StyledToolTip {
                                text: Translation.tr("Refresh")
                            }
                        }

                        RippleButton {
                            implicitWidth: 40
                            implicitHeight: 40
                            buttonRadius: Appearance.rounding.full
                            onClicked: root.close()

                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: "close"
                                iconSize: Appearance.font.pixelSize.title
                            }

                            StyledToolTip {
                                text: Translation.tr("Close")
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 12

                        ClaudeSessionList {
                            Layout.preferredWidth: panelWindow.sideWidth
                            Layout.fillHeight: true
                            selectedId: root.selected?.id ?? ""
                            onSessionSelected: sessionId => root.selectedId = sessionId
                            onStartRequested: folder => root.start(folder)
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            RowLayout {
                                anchors.fill: parent
                                visible: root.selected !== null
                                spacing: 12

                                ClaudeSessionView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    session: root.selected
                                    onResumeRequested: root.resume(root.selected)
                                    onOpenFolderRequested: root.openFolder(root.selected?.cwd ?? "")
                                }

                                ClaudeSessionStats {
                                    Layout.preferredWidth: panelWindow.sideWidth
                                    Layout.fillHeight: true
                                    session: root.selected
                                }
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                visible: root.selected === null && !ClaudeCode.loaded
                                spacing: 12

                                MaterialLoadingIndicator {
                                    Layout.alignment: Qt.AlignHCenter
                                    loading: parent.visible
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: Translation.tr("Loading sessions...")
                                    color: Appearance.colors.colSubtext
                                }
                            }

                            PagePlaceholder {
                                shown: root.selected === null && ClaudeCode.loaded
                                icon: ClaudeCode.cliFound ? "asterisk" : "terminal"
                                title: ClaudeCode.cliFound ? Translation.tr("No sessions yet") : Translation.tr("Claude Code not found")
                                description: ClaudeCode.cliFound ? Translation.tr("Start a session with New session, or run claude in a terminal. It shows up here.") : Translation.tr("Install Claude Code and start a session in a terminal. Your sessions show up here.")
                                descriptionHorizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "claudePanel"

        function toggle(): void {
            GlobalStates.claudePanelOpen = !GlobalStates.claudePanelOpen;
        }

        function open(): void {
            GlobalStates.claudePanelOpen = true;
        }

        function close(): void {
            GlobalStates.claudePanelOpen = false;
        }
    }
}

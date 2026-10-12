pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.modules.common
import qs.modules.common.widgets

Singleton {
    id: root

    readonly property QtObject backend: WindowsNative.displays
    readonly property bool pending: root.backend?.pendingConfirmation ?? false
    readonly property int secondsLeft: root.backend?.confirmSecondsLeft ?? 0
    readonly property bool busy: root.backend?.busy ?? false

    function load() {
    }

    function keep() {
        root.backend?.keepChanges();
    }

    function revert() {
        root.backend?.revertChanges();
    }

    LazyLoader {
        active: root.pending

        component: PanelWindow {
            id: panel

            screen: {
                const name = root.backend?.primaryName ?? "";
                return Quickshell.screens.find(s => s.name === name)
                    ?? Quickshell.screens.find(s => s.x === 0 && s.y === 0)
                    ?? Quickshell.screens[0];
            }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:displayConfirm"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Component.onCompleted: GlobalFocusGrab.addDismissable(panel)
            Component.onDestruction: GlobalFocusGrab.removeDismissable(panel)

            Item {
                id: content
                anchors.fill: parent
                focus: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.revert();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.keep();
                        event.accepted = true;
                    }
                }

                WindowDialog {
                    anchors.fill: parent
                    backgroundWidth: 420
                    show: false
                    Component.onCompleted: show = true

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        iconSize: 26
                        text: "desktop_windows"
                        color: Appearance.colors.colSecondary
                    }

                    WindowDialogTitle {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Translation.tr("Keep these display settings?")
                    }

                    WindowDialogParagraph {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Translation.tr("Reverting to the previous display settings in %1 seconds.").arg(root.secondsLeft)
                    }

                    WindowDialogButtonRow {
                        Layout.bottomMargin: 10
                        Item {
                            Layout.fillWidth: true
                        }
                        DialogButton {
                            enabled: !root.busy
                            buttonText: Translation.tr("Revert")
                            onClicked: root.revert()
                        }
                        DialogButton {
                            enabled: !root.busy
                            buttonText: Translation.tr("Keep changes")
                            onClicked: root.keep()
                        }
                    }
                }
            }
        }
    }
}

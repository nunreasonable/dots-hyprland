import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: notificationPopup

    PanelWindow {
        id: root
        visible: (Notifications.popupList.length > 0) && !GlobalStates.screenLocked && !GlobalStates.dynamicIslandActive
        screen: Quickshell.screens.find(s => Config.options.notifications.forceMonitor.enable ? s.name === Config.options.notifications.forceMonitor.name : s.name === Hyprland.focusedMonitor?.name) ?? null

        property string position: {
            const raw = Config.options.notifications.position ?? "top_right";
            if (raw === "top") return "top_right";
            if (raw === "bottom") return "bottom_right";
            return raw;
        }
        readonly property bool isTop: root.position.startsWith("top")
        readonly property bool isBottom: root.position.startsWith("bottom")
        readonly property bool isLeft: root.position.endsWith("left")
        readonly property bool isRight: root.position.endsWith("right")
        readonly property bool isCenter: root.position.endsWith("center")

        WlrLayershell.namespace: "quickshell:notificationPopup"
        WlrLayershell.layer: WlrLayer.Overlay
        exclusiveZone: 0

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: Region {
            item: listview.contentItem
        }

        color: "transparent"
        implicitWidth: Appearance.sizes.notificationPopupWidth

        NotificationListView {
            id: listview
            anchors {
                top: parent.top
                bottom: parent.bottom
                topMargin: 4
                bottomMargin: 4
                leftMargin: 4
                rightMargin: 4
            }
            implicitWidth: parent.width - Appearance.sizes.elevationMargin * 2
            popup: true
            verticalLayoutDirection: root.isBottom ? ListView.BottomToTop : ListView.TopToBottom

            states: [
                State {
                    name: "left"
                    when: root.isLeft
                    AnchorChanges {
                        target: listview
                        anchors.left: listview.parent.left
                        anchors.right: undefined
                        anchors.horizontalCenter: undefined
                    }
                },
                State {
                    name: "center"
                    when: root.isCenter
                    AnchorChanges {
                        target: listview
                        anchors.left: undefined
                        anchors.right: undefined
                        anchors.horizontalCenter: listview.parent.horizontalCenter
                    }
                },
                State {
                    name: "right"
                    when: root.isRight
                    AnchorChanges {
                        target: listview
                        anchors.left: undefined
                        anchors.right: listview.parent.right
                        anchors.horizontalCenter: undefined
                    }
                }
            ]
        }
    }
}

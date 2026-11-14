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
        readonly property string targetScreenName: Config.options.notifications.forceMonitor.enable ? Config.options.notifications.forceMonitor.name : (Hyprland.focusedMonitor?.name ?? "")
        visible: (Notifications.popupList.length > 0) && !GlobalStates.screenLocked && !GlobalStates.islandShownOn(root.targetScreenName) && !GlobalStates.nabyIslandTakes("notifications", root.targetScreenName)
        screen: Quickshell.screens.find(s => s.name === root.targetScreenName) ?? null

        property string position: {
            if (SekaiTheme.active) return "bottom_right";
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
        exclusionMode: SekaiTheme.active ? ExclusionMode.Ignore : ExclusionMode.Normal

        anchors {
            top: true
            bottom: true
            left: root.isLeft
            right: root.isRight
        }

        mask: Region {
            item: listview.contentItem
        }

        color: "transparent"
        implicitWidth: Appearance.sizes.notificationPopupWidth + (SekaiTheme.active ? root.phonePadding * 2 : 0)

        readonly property real phonePadding: 14
        readonly property int popupCount: Notifications.popupList.length
        onVisibleChanged: {
            if (root.visible && SekaiTheme.active)
                phonePeekAnimation.restart();
        }
        onPopupCountChanged: {
            if (root.visible && SekaiTheme.active && !phonePeekAnimation.running && root.popupCount > 0)
                phoneNudgeAnimation.restart();
        }

        Item {
            id: phone
            anchors.fill: parent

            transform: Translate {
                id: phonePeek
            }
            NumberAnimation {
                id: phonePeekAnimation
                target: phonePeek
                property: "y"
                from: listview.contentHeight + root.phonePadding * 3
                to: 0
                duration: 480
                easing.type: Easing.OutBack
                easing.overshoot: 1.4
            }
            NumberAnimation {
                id: phoneNudgeAnimation
                target: phonePeek
                property: "y"
                from: 18
                to: 0
                duration: 300
                easing.type: Easing.OutBack
                easing.overshoot: 2.2
            }

            Loader {
                active: SekaiTheme.active
                x: listview.x - root.phonePadding
                y: phone.height - listview.contentHeight - root.phonePadding * 2
                width: listview.width + root.phonePadding * 2
                height: listview.contentHeight + root.phonePadding * 2 + 60
                sourceComponent: SekaiBlock {
                    cornerRadius: 34
                    ringWidth: 6
                    fillColor: SekaiTheme.dark ? SekaiTheme.deep : "#f6f6fa"
                }
            }

            NotificationListView {
                id: listview
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    topMargin: 4
                    bottomMargin: SekaiTheme.active ? root.phonePadding : 4
                    leftMargin: SekaiTheme.active ? root.phonePadding : 4
                    rightMargin: SekaiTheme.active ? root.phonePadding : 4
                }
                implicitWidth: parent.width - (SekaiTheme.active ? root.phonePadding * 2 : Appearance.sizes.elevationMargin * 2)
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
}

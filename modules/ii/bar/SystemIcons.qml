import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    property color contentColor: Appearance.colors.colOnLayer1
    property bool contentColorOverridden: false
    property bool vertical: Config.options.bar.vertical
    readonly property color iconColor: root.contentColorOverridden ? root.contentColor : Appearance.colors.colOnLayer1

    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth - 14 : flow.implicitWidth + 4
    implicitHeight: root.vertical ? flow.implicitHeight + 4 : Appearance.sizes.baseBarHeight - 8

    MouseArea {
        anchors.fill: parent
        onPressed: GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
    }

    Flow {
        id: flow
        anchors.centerIn: parent
        flow: root.vertical ? Flow.TopToBottom : Flow.LeftToRight
        spacing: root.vertical ? 6 : 10

        Item {
            id: volumeItem
            implicitWidth: volumeIcon.implicitWidth
            implicitHeight: volumeIcon.implicitHeight

            MaterialSymbol {
                id: volumeIcon
                anchors.centerIn: parent
                text: (Audio.sink?.audio?.muted ?? false) ? "volume_off" : "volume_up"
                iconSize: Appearance.font.pixelSize.larger
                color: root.iconColor
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onWheel: wheel => {
                    if (wheel.angleDelta.y > 0)
                        Audio.incrementVolume();
                    else if (wheel.angleDelta.y < 0)
                        Audio.decrementVolume();
                }
                onPressed: GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
            }
        }

        Revealer {
            reveal: Audio.source?.audio?.muted ?? false
            vertical: root.vertical
            MaterialSymbol {
                text: "mic_off"
                iconSize: Appearance.font.pixelSize.larger
                color: root.iconColor
            }
        }

        HyprlandXkbIndicator {
            vertical: root.vertical
            color: root.iconColor
        }

        MaterialSymbol {
            text: Network.materialSymbol
            iconSize: Appearance.font.pixelSize.larger
            color: root.iconColor
        }

        MaterialSymbol {
            visible: BluetoothStatus.available
            text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
            iconSize: Appearance.font.pixelSize.larger
            color: root.iconColor
        }

        Loader {
            active: Notifications.silent || Notifications.unread > 0
            visible: active
            sourceComponent: NotificationUnreadCount {
                contentColor: root.iconColor
            }
        }
    }
}

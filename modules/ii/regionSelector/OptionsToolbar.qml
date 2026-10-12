pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Options toolbar
Toolbar {
    id: root

    // Use a synchronizer on these
    property var action
    property var selectionMode
    // Signals
    signal dismiss()

    readonly property bool recording: root.action === RegionSelection.SnipAction.Record || root.action === RegionSelection.SnipAction.RecordWithSound

    ToolbarTabBar {
        id: tabBar
        tabButtonList: [
            {"icon": "activity_zone", "name": Translation.tr("Rect")},
            {"icon": "gesture", "name": Translation.tr("Circle")}
        ]
        currentIndex: root.selectionMode === RegionSelection.SelectionMode.RectCorners ? 0 : 1
        onCurrentIndexChanged: {
            root.selectionMode = currentIndex === 0 ? RegionSelection.SelectionMode.RectCorners : RegionSelection.SelectionMode.Circle;
        }
    }

    Rectangle {
        visible: root.recording
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 1
        implicitHeight: 24
        color: Appearance.colors.colOutlineVariant
    }

    IconToolbarButton {
        visible: root.recording
        text: Config.options.screenRecord.systemAudio ? "volume_up" : "volume_off"
        toggled: Config.options.screenRecord.systemAudio
        onClicked: Config.options.screenRecord.systemAudio = !Config.options.screenRecord.systemAudio
        StyledToolTip {
            text: Config.options.screenRecord.systemAudio ? Translation.tr("System audio: on") : Translation.tr("System audio: off")
        }
    }

    IconToolbarButton {
        visible: root.recording
        text: Config.options.screenRecord.microphone ? "mic" : "mic_off"
        toggled: Config.options.screenRecord.microphone
        onClicked: Config.options.screenRecord.microphone = !Config.options.screenRecord.microphone
        StyledToolTip {
            text: Config.options.screenRecord.microphone ? Translation.tr("Microphone: on") : Translation.tr("Microphone: off")
        }
    }
}

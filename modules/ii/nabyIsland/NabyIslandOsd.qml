import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    property var fallbackScreen: null

    readonly property string type: GlobalStates.osdIndicatorType
    readonly property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? root.fallbackScreen
    readonly property var brightnessMonitor: root.type === "brightness" && root.focusedScreen ? Brightness.getMonitorForScreen(root.focusedScreen) : null
    readonly property bool muted: root.type === "volume" && (Audio.sink?.audio?.muted ?? false)
    readonly property real value: {
        switch (root.type) {
        case "brightness":
            return root.brightnessMonitor?.brightness ?? 0.5;
        case "gamma":
            return (Hyprsunset.gamma ?? 50) / 100;
        default:
            return Audio.sink?.audio?.volume ?? 0;
        }
    }
    readonly property real from: root.type === "gamma" && !Platform.isWindows ? Hyprsunset.gammaLowerLimit / 100 : 0
    readonly property real fraction: Math.max(0, Math.min(1, (root.value - root.from) / Math.max(0.01, 1 - root.from)))
    readonly property string icon: {
        switch (root.type) {
        case "brightness":
            return Hyprsunset.temperatureActive ? "routine" : "light_mode";
        case "gamma":
            return "wb_twilight";
        default:
            if (root.muted)
                return "volume_off";
            if (root.value < 0.01)
                return "volume_mute";
            return root.value < 0.5 ? "volume_down" : "volume_up";
        }
    }

    MaterialSymbol {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        horizontalAlignment: Text.AlignHCenter
        text: root.icon
        iconSize: 20
        fill: 1
        color: "#ffffff"
    }

    Rectangle {
        id: track
        anchors.left: icon.right
        anchors.leftMargin: 12
        anchors.right: percent.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        radius: 3
        color: Qt.rgba(1, 1, 1, 0.2)

        Rectangle {
            width: Math.max(track.height, track.width * root.fraction)
            height: track.height
            radius: track.radius
            color: "#ffffff"
            opacity: root.muted ? 0.35 : 1
            visible: root.fraction > 0

            Behavior on width {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }

    StyledText {
        id: percent
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: 30
        horizontalAlignment: Text.AlignRight
        text: root.type === "gamma" ? `${Math.round(Hyprsunset.gamma ?? 50)}` : `${Math.round(root.value * 100)}`
        color: "#ffffff"
        opacity: root.muted ? 0.6 : 1
        font.pixelSize: 13
        font.weight: Font.DemiBold
        font.features: ({ "tnum": 1 })
    }
}

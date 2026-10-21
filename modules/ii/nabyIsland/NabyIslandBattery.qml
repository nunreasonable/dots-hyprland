import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Item {
    id: root

    property string kind: "low"

    readonly property color tint: root.kind === "charging" ? "#8be39a" : root.kind === "critical" ? "#ff6b6b" : "#ffb454"
    readonly property string label: {
        switch (root.kind) {
        case "critical":
            return Translation.tr("Critical Battery");
        case "charging":
            return Translation.tr("Charging");
        default:
            return Translation.tr("Low Battery");
        }
    }
    readonly property string icon: {
        if (root.kind === "charging")
            return "battery_android_frame_bolt";
        const pct = Battery.percentage;
        if (pct <= 0.1)
            return "battery_android_frame_alert";
        if (pct <= 0.2)
            return "battery_android_frame_1";
        return "battery_android_frame_2";
    }

    MaterialSymbol {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        iconSize: 20
        fill: 1
        color: root.tint
    }

    StyledText {
        anchors.left: icon.right
        anchors.leftMargin: 8
        anchors.right: percent.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: "#ffffff"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }

    StyledText {
        id: percent
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: `${Math.round(Battery.percentage * 100)}%`
        color: root.tint
        font.pixelSize: 13
        font.weight: Font.DemiBold
        font.features: ({ "tnum": 1 })
    }
}

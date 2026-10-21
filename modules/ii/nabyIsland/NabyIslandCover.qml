import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell.Widgets

ClippingRectangle {
    id: root

    property string artUrl: ""

    color: "#262626"

    StyledImage {
        id: art
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: root.artUrl
        visible: root.artUrl !== "" && status === Image.Ready
    }

    MaterialSymbol {
        anchors.centerIn: parent
        visible: !art.visible
        text: "music_note"
        iconSize: Math.round(root.width * 0.55)
        color: "#bdbdbd"
    }
}

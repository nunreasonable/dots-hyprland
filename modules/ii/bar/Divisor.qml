import QtQuick
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    property color contentColor: Appearance.colors.colOnLayer0
    property bool contentColorOverridden: false
    property bool vertical: Config.options.bar.vertical
    property real btnSize: 40
    property real btnSpacing: 2
    property string style: Config.options.bar.divider.style
    property int dividerSpacing: Config.options.bar.divider.spacing

    implicitWidth: root.vertical ? root.btnSize : (root.style === "space" ? root.dividerSpacing : root.style === "dot" ? dotText.implicitWidth + 10 : (1 + root.btnSpacing * 3))
    implicitHeight: root.vertical ? (root.style === "space" ? root.dividerSpacing : root.style === "dot" ? dotText.implicitHeight - 4 : (1 + root.btnSpacing * 3)) : root.btnSize

    Rectangle {
        visible: root.style === "rect"
        anchors.centerIn: parent
        width: root.vertical ? Math.round(root.btnSize * 0.6) : 1
        height: root.vertical ? 1 : Math.round(root.btnSize * 0.6)
        color: root.contentColorOverridden ? Qt.alpha(root.contentColor, 0.4) : Appearance.colors.colOutlineVariant
    }

    StyledText {
        id: dotText
        visible: root.style === "dot"
        anchors.centerIn: parent
        text: "• "
        color: root.contentColor
        font.pixelSize: Appearance.font.pixelSize.normal
    }
}

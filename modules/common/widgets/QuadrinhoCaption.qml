import QtQuick
import qs.modules.common

Rectangle {
    id: root

    property alias text: label.text
    property alias font: label.font
    property real horizontalPadding: 8
    property real verticalPadding: 3
    property real maximumWidth: 100000

    implicitWidth: Math.min(root.maximumWidth, label.implicitWidth + root.horizontalPadding * 2)
    implicitHeight: label.implicitHeight + root.verticalPadding * 2
    color: QuadrinhoTheme.ink

    Text {
        id: label
        anchors.fill: parent
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: root.horizontalPadding
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        color: QuadrinhoTheme.paper
        renderType: Text.NativeRendering
        font.family: QuadrinhoTheme.boldFont
        font.weight: Font.Bold
        font.pixelSize: Appearance.font.pixelSize.smaller
    }
}

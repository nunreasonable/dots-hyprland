import QtQuick
import qs.modules.common

Item {
    id: root

    required property string text
    property int minDigits: 0
    property bool framed: true
    property int pixelSize: 26
    property color bgColor: StyleTheme.current?.lcdBg ?? "#AEB9A8"
    property color onColor: StyleTheme.current?.lcdOn ?? "#1C211B"
    property color offColor: StyleTheme.current?.lcdOff ?? "#A5B09F"
    property color bezelColor: StyleTheme.surface.borderColor ?? "#8E9296"

    readonly property string shownText: root.text.length < root.minDigits ? " ".repeat(root.minDigits - root.text.length) + root.text : root.text
    readonly property string ghostText: root.shownText.replace(/[0-9]/g, "8")

    implicitWidth: label.implicitWidth + (root.framed ? 18 : 6)
    implicitHeight: label.implicitHeight + (root.framed ? 10 : 2)

    Rectangle {
        id: bezel
        visible: root.framed
        anchors.fill: parent
        radius: 4
        color: Qt.darker(root.bgColor, 1.15)
        border.width: 2
        border.color: root.bezelColor
    }

    Rectangle {
        id: screen
        anchors.fill: parent
        anchors.margins: root.framed ? 4 : 0
        radius: 2
        color: root.bgColor
        clip: true

        Text {
            id: ghost
            anchors.centerIn: parent
            text: root.ghostText
            font.family: "DSEG7 Classic"
            font.pixelSize: root.pixelSize
            renderType: Text.NativeRendering
            color: root.offColor
        }

        Text {
            id: label
            anchors.centerIn: parent
            text: root.shownText
            font.family: "DSEG7 Classic"
            font.pixelSize: root.pixelSize
            renderType: Text.NativeRendering
            color: root.onColor
        }
    }
}

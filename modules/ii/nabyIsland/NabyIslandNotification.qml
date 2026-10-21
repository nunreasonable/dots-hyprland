import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    property var notification: null

    readonly property string image: root.notification?.image ?? ""
    readonly property string appIcon: root.notification?.appIcon ?? ""

    function plain(text) {
        return (text ?? "").replace(/<[^>]*>/g, "").replace(/\s*\n\s*/g, " ").trim();
    }

    ClippingRectangle {
        id: iconBox
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 32
        height: 32
        radius: 10
        color: "#262626"

        StyledImage {
            id: image
            anchors.fill: parent
            visible: root.image !== "" && status === Image.Ready
            source: root.image
            fillMode: Image.PreserveAspectCrop
            cache: false
            asynchronous: true
        }

        IconImage {
            id: appIcon
            anchors.centerIn: parent
            visible: !image.visible && root.appIcon !== "" && status === Image.Ready
            implicitSize: 22
            asynchronous: true
            source: root.appIcon !== "" ? Quickshell.iconPath(root.appIcon, "image-missing") : ""
        }

        MaterialSymbol {
            anchors.centerIn: parent
            visible: !image.visible && !appIcon.visible
            text: NotificationUtils.findSuitableMaterialSymbol(root.notification?.summary ?? "")
            iconSize: 18
            fill: 1
            color: "#ffffff"
        }
    }

    Column {
        anchors.left: iconBox.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        StyledText {
            width: parent.width
            text: root.plain(root.notification?.summary) || root.plain(root.notification?.appName)
            textFormat: Text.PlainText
            color: "#ffffff"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            font.variableAxes: ({ "wght": 600 })
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            maximumLineCount: 1
        }

        StyledText {
            width: parent.width
            visible: text.length > 0
            text: root.plain(root.notification?.body)
            textFormat: Text.PlainText
            color: "#ffffff"
            opacity: 0.6
            font.pixelSize: 12
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            maximumLineCount: 1
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
    }
}

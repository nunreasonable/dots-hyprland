import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: diNotifsRoot
    required property Item di
    anchors.fill: parent

    readonly property var notif: diNotifsRoot.di.latestNotification
    readonly property bool hasIcon: (diNotifsRoot.notif?.appIcon ?? "") !== ""

    Item {
        id: iconSlot
        width: 24
        height: 24
        anchors {
            left: parent.left
            leftMargin: 4
            verticalCenter: parent.verticalCenter
        }

        IconImage {
            anchors.centerIn: parent
            visible: diNotifsRoot.hasIcon
            implicitSize: 20
            source: diNotifsRoot.hasIcon ? Quickshell.iconPath(diNotifsRoot.notif.appIcon, "image-missing") : ""
        }

        MaterialShapeWrappedMaterialSymbol {
            anchors.centerIn: parent
            visible: !diNotifsRoot.hasIcon
            wrappedShape: MaterialShape.Shape.Cookie12Sided
            color: Appearance.colors.colPrimary
            colSymbol: Appearance.colors.colOnPrimary
            text: "notifications"
            iconSize: 14
            fill: 1
            padding: 4
        }
    }

    ColumnLayout {
        anchors {
            left: iconSlot.right
            leftMargin: 6
            verticalCenter: parent.verticalCenter
            right: nowLabel.left
            rightMargin: 8
        }
        spacing: -4

        StyledText {
            Layout.fillWidth: true
            text: (diNotifsRoot.notif?.summary ?? "").replace(/\n/g, " ")
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer0
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            maximumLineCount: 1
        }
        StyledText {
            Layout.fillWidth: true
            text: (diNotifsRoot.notif?.body ?? "").replace(/\n/g, " ")
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: Appearance.colors.colOnLayer0
            opacity: 0.7
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            maximumLineCount: 1
        }
    }

    StyledText {
        id: nowLabel
        anchors {
            right: parent.right
            top: parent.top
            rightMargin: 10
            topMargin: 8
        }
        text: DateTime.time
        font.pixelSize: Appearance.font.pixelSize.small - 2
        color: Appearance.colors.colOnLayer0
        opacity: 0.8
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
    }
}

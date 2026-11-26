import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

DashboardCard {
    id: root

    property string title: ""
    property string icon: "tune"
    property var tileShape: MaterialShape.Shape.Cookie6Sided
    property string subtitle: Translation.tr("More options")

    signal opened()

    tint: hoverHandler.hovered ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1

    Behavior on tint {
        ColorAnimation { duration: 150 }
    }

    HoverHandler {
        id: hoverHandler
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        MaterialShapeWrappedMaterialSymbol {
            shape: root.tileShape
            text: root.icon
            iconSize: 24
            fill: 1
            padding: 10
            color: Appearance.colors.colSecondaryContainer
            colSymbol: Appearance.colors.colOnSecondaryContainer
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
                elide: Text.ElideRight
            }
            StyledText {
                Layout.fillWidth: true
                text: root.subtitle
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                opacity: 0.8
                elide: Text.ElideRight
            }
        }

        MaterialSymbol {
            text: "chevron_right"
            iconSize: 22
            color: Appearance.colors.colOnLayer1
            opacity: 0.6
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.opened()
    }
}

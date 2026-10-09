import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Rectangle {
    id: root

    property string imageSource: ""
    property string title: ""
    property string description: ""
    property var onApply: () => {}
    property var onRemove: () => {}

    implicitWidth: 260
    implicitHeight: contentColumn.implicitHeight + 14
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    ColumnLayout {
        id: contentColumn
        anchors { top: parent.top; left: parent.left; right: parent.right }
        spacing: 6

        RowLayout {
            Layout.leftMargin: 10
            Layout.topMargin: 6
            Layout.rightMargin: 8
            spacing: 10

            MaterialShapeWrappedMaterialSymbol {
                shape: MaterialShape.Shape.Circle
                text: root.title.length > 0 ? root.title.charAt(0).toUpperCase() : "?"
                iconSize: Appearance.font.pixelSize.normal
                implicitSize: 36
                color: Appearance.colors.colPrimaryContainer
                colSymbol: Appearance.colors.colOnPrimaryContainer
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                spacing: -4
                Layout.fillWidth: true
                StyledText {
                    Layout.fillWidth: true
                    text: root.title
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: root.description.length > 0
                    text: root.description
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }
            }
        }

        Rectangle {
            id: imageRect
            Layout.fillWidth: true
            Layout.bottomMargin: 4
            implicitHeight: 120
            color: Appearance.colors.colLayer2
            clip: true

            StyledImage {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: root.imageSource
                cache: true
                antialiasing: true
                sourceSize.width: 400
                sourceSize.height: 220
                visible: root.imageSource !== ""
            }

            MaterialSymbol {
                anchors.centerIn: parent
                visible: root.imageSource === ""
                text: "wallpaper"
                iconSize: Appearance.font.pixelSize.huge
                color: Appearance.colors.colSubtext
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 8
            Layout.bottomMargin: 6
            spacing: 8

            Item { Layout.fillWidth: true }

            GroupButton {
                bounce: false
                toggled: false
                leftRadius: height / 2
                rightRadius: height / 2
                implicitHeight: 34
                horizontalPadding: 14
                verticalPadding: 6
                colBackground: "transparent"
                colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colPrimaryContainerHover, 0.8)
                colBackgroundActive: Appearance.colors.colPrimaryContainerActive
                contentItem: StyledText {
                    text: Translation.tr("Remove")
                    color: Appearance.colors.colPrimary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.onRemove()
            }

            GroupButton {
                bounce: false
                toggled: false
                leftRadius: height / 2
                rightRadius: height / 2
                implicitHeight: 34
                horizontalPadding: 14
                verticalPadding: 6
                colBackground: Appearance.colors.colPrimaryContainer
                colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                colBackgroundActive: Appearance.colors.colPrimaryContainerActive
                contentItem: StyledText {
                    text: Translation.tr("Apply")
                    color: Appearance.colors.colOnPrimaryContainer
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.onApply()
            }
        }
    }
}

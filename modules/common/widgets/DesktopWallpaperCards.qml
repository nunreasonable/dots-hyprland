import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.services
import qs.modules.common
import qs.modules.common.widgets

GridLayout {
    id: root

    columns: Math.max(2, Math.min(4, Math.floor(root.width / 170)))
    columnSpacing: 8
    rowSpacing: 12

    Repeater {
        model: Wallpapers.desktops

        delegate: ColumnLayout {
            id: card

            required property var modelData
            required property int index
            readonly property string desktopId: card.modelData.id ?? ""
            readonly property string ownPath: Wallpapers.desktopWallpaperFor(card.desktopId)
            readonly property bool current: card.desktopId !== "" && card.desktopId === Wallpapers.currentDesktopId

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            spacing: 6

            Rectangle {
                id: cardBox
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(width * 9 / 16)
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2
                opacity: card.desktopId !== "" ? 1 : 0.5

                StyledImage {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: Wallpapers.stillFor(card.ownPath || Config.options.background.wallpaperPath)
                    cache: false
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: cardBox.width
                            height: cardBox.height
                            radius: cardBox.radius
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: cardBox.radius
                    color: "transparent"
                    border.width: card.current ? 3 : 0
                    border.color: Appearance.colors.colPrimary
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: card.desktopId !== ""
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Wallpapers.openSelectorForDesktop(card.desktopId)
                }
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: card.modelData.name || Translation.tr("Desktop %1").arg(card.index + 1)
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: card.current ? Font.DemiBold : Font.Medium
                color: Appearance.colors.colOnLayer1
            }

            StyledText {
                Layout.fillWidth: true
                visible: card.ownPath === ""
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: Translation.tr("Main wallpaper")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }

            RippleButtonWithIcon {
                Layout.alignment: Qt.AlignHCenter
                visible: card.ownPath !== ""
                materialIcon: "layers_clear"
                mainText: Translation.tr("Use the main one")
                onClicked: Wallpapers.clearDesktopWallpaper(card.desktopId)
            }
        }
    }
}

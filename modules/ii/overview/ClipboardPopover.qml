import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    property string entry: ""
    readonly property bool isImage: root.entry !== "" && Cliphist.entryIsImage(root.entry)
    readonly property bool pinned: root.entry !== "" && Cliphist.isPinned(root.entry)
    readonly property string previewText: root.entry !== "" ? Cliphist.entryText(root.entry).replace(/ ⏎ /g, "\n") : ""

    implicitWidth: 340
    implicitHeight: card.implicitHeight

    StyledRectangularShadow {
        target: card
    }
    Rectangle {
        id: card
        anchors.fill: parent
        implicitHeight: contentColumn.implicitHeight + contentColumn.anchors.margins * 2
        radius: Appearance.rounding.normal
        color: Appearance.colors.colBackgroundSurfaceContainer

        ColumnLayout {
            id: contentColumn
            anchors {
                fill: parent
                margins: 10
            }
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                MaterialSymbol {
                    text: root.isImage ? "image" : "notes"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    text: root.isImage ? Translation.tr("Image · %1x%2").arg(imagePreview.item?.imageWidth ?? 0).arg(imagePreview.item?.imageHeight ?? 0) : Translation.tr("Text · %1 characters").arg(root.previewText.length)
                }
                MaterialSymbol {
                    visible: root.pinned
                    text: "keep"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colPrimary
                }
            }

            Loader {
                id: imagePreview
                Layout.alignment: Qt.AlignHCenter
                active: root.isImage
                visible: active
                sourceComponent: CliphistImage {
                    entry: root.entry
                    maxWidth: 320
                    maxHeight: 280
                }
            }

            Flickable {
                visible: !root.isImage
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(280, textContent.implicitHeight)
                contentWidth: width
                contentHeight: textContent.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                StyledText {
                    id: textContent
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: root.previewText
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.small
                }
            }
        }
    }
}

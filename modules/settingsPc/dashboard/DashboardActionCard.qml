import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

DashboardCard {
    id: root

    property var control: null
    property string title: ""
    property string icon: "bolt"
    property var tileShape: MaterialShape.Shape.Cookie6Sided

    readonly property bool busy: root.control?.busy?.() ?? false
    readonly property string subtitleText: root.control?.subtitle?.() ?? ""

    tint: Appearance.colors.colLayer1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 0
        opacity: root.busy ? 0.6 : 1

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        RowLayout {
            Layout.fillWidth: true

            MaterialShapeWrappedMaterialSymbol {
                shape: root.tileShape
                text: root.icon
                iconSize: 24
                fill: 1
                padding: 10
                color: Appearance.colors.colSecondaryContainer
                colSymbol: Appearance.colors.colOnSecondaryContainer
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitHeight: 27
                implicitWidth: pillLabel.implicitWidth + 20
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.12)

                StyledText {
                    id: pillLabel
                    anchors.centerIn: parent
                    text: root.control?.label ?? Translation.tr("Run")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        Item { Layout.fillHeight: true }

        StyledText {
            Layout.fillWidth: true
            text: root.title
            font.pixelSize: Appearance.font.pixelSize.larger
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
            elide: Text.ElideRight
        }
        StyledText {
            visible: root.subtitleText !== ""
            text: root.subtitleText
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            opacity: 0.8
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.busy
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!root.control) return;
            Qt.callLater(() => root.control.run());
        }
    }
}

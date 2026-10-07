import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

RippleButton {
    id: root

    property bool selected: false
    property string title: ""
    property string subtitle: ""
    property string symbol: ""
    property string iconSource: ""
    property string imageSource: ""
    property string trailingSymbol: ""
    signal trailingClicked

    implicitHeight: 52
    buttonRadius: Appearance.rounding.normal
    colBackground: root.selected ? Appearance.colors.colSecondaryContainer : ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, 1)
    colBackgroundHover: root.selected ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colSecondaryContainerActive

    contentItem: RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        Item {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 32
            implicitHeight: 32

            MaterialSymbol {
                visible: root.iconSource === "" && root.imageSource === ""
                anchors.centerIn: parent
                text: root.symbol
                iconSize: Appearance.font.pixelSize.huge
                color: root.selected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
            }
            IconImage {
                visible: root.iconSource !== "" && root.imageSource === ""
                anchors.fill: parent
                source: root.iconSource
            }
            StyledImage {
                visible: root.imageSource !== ""
                anchors.fill: parent
                source: root.imageSource
                sourceSize.width: 64
                sourceSize.height: 64
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideMiddle
                font.pixelSize: Appearance.font.pixelSize.normal
                color: root.selected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
            }
            StyledText {
                visible: root.subtitle !== ""
                Layout.fillWidth: true
                text: root.subtitle
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }

        RippleButton {
            visible: root.trailingSymbol !== ""
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 32
            implicitHeight: 32
            buttonRadius: Appearance.rounding.full
            onClicked: root.trailingClicked()
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                text: root.trailingSymbol
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colSubtext
            }
        }
    }
}

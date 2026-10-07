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
    property string caption: ""
    property string symbol: ""
    property string iconSource: ""
    property string bigText: ""

    buttonRadius: Appearance.rounding.normal
    colBackground: root.selected ? Appearance.colors.colSecondaryContainer : ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, 1)
    colBackgroundHover: root.selected ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colSecondaryContainerActive

    contentItem: ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 6

        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: root.bigText !== "" ? bigTextItem.implicitWidth : 40
            implicitHeight: root.bigText !== "" ? bigTextItem.implicitHeight : 40

            IconImage {
                visible: root.iconSource !== ""
                anchors.fill: parent
                source: root.iconSource
            }
            MaterialSymbol {
                visible: root.iconSource === "" && root.bigText === ""
                anchors.centerIn: parent
                text: root.symbol
                iconSize: 28
                color: root.selected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
            }
            StyledText {
                id: bigTextItem
                visible: root.bigText !== ""
                anchors.centerIn: parent
                text: root.bigText
                font.pixelSize: 26
            }
        }

        StyledText {
            visible: root.caption !== ""
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.caption
            elide: Text.ElideRight
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: root.selected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
        }
    }
}

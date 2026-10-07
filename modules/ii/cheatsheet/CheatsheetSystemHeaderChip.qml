import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string icon: ""
    property string text: ""

    implicitHeight: 32
    implicitWidth: contentRow.implicitWidth + 24
    radius: Appearance.rounding.full
    color: Appearance.colors.colLayer1

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        MaterialSymbol {
            visible: root.icon.length > 0
            text: root.icon
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
        }
        StyledText {
            text: root.text
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
        }
    }
}

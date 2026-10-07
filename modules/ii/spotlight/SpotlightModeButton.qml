import qs.modules.common
import qs.modules.common.widgets
import QtQuick

RippleButton {
    id: root

    property string symbol: ""
    property string tooltip: ""

    implicitWidth: 48
    implicitHeight: 48
    buttonRadius: Appearance.rounding.full
    colBackground: Appearance.colors.colLayer0
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active

    contentItem: MaterialSymbol {
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        text: root.symbol
        iconSize: Appearance.font.pixelSize.larger
        color: Appearance.colors.colOnLayer0
    }

    StyledToolTip {
        text: root.tooltip
    }
}

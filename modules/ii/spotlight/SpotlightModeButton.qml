import qs.modules.common
import qs.modules.common.widgets
import QtQuick

RippleButton {
    id: root

    property string symbol: ""
    property string tooltip: ""

    implicitWidth: 48
    implicitHeight: 48 + (SekaiTheme.active ? SekaiTheme.shadowOffset : 0)
    buttonRadius: Appearance.rounding.full
    colBackground: SekaiTheme.active ? "transparent" : Appearance.colors.colLayer0
    colBackgroundHover: SekaiTheme.active ? "transparent" : Appearance.colors.colLayer1Hover
    colRipple: SekaiTheme.active ? "transparent" : Appearance.colors.colLayer1Active

    SekaiBlock {
        z: -1
        visible: SekaiTheme.active
        anchors.fill: parent
        pressed: root.down
        fillColor: root.hovered ? SekaiTheme.fillHover : SekaiTheme.fill
    }

    contentItem: MaterialSymbol {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: SekaiTheme.active ? (root.down ? SekaiTheme.shadowOffset / 2 : -SekaiTheme.shadowOffset / 2) : 0
        horizontalAlignment: Text.AlignHCenter
        text: root.symbol
        iconSize: Appearance.font.pixelSize.larger
        color: SekaiTheme.active ? SekaiTheme.text : Appearance.colors.colOnLayer0
    }

    StyledToolTip {
        text: root.tooltip
    }
}

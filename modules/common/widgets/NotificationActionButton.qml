import qs.modules.common
import qs.services
import QtQuick
import Quickshell.Services.Notifications

RippleButton {
    id: button
    property string buttonText
    property string urgency

    readonly property bool quadrinhoSpot: QuadrinhoTheme.active && button.buttonText !== "" && button.buttonText !== Translation.tr("Close")
    implicitHeight: 34
    leftPadding: 15
    rightPadding: 15
    buttonRadius: QuadrinhoTheme.active ? 0 : Appearance.rounding.small
    colBackground: button.quadrinhoSpot ? QuadrinhoTheme.spot : (urgency == NotificationUrgency.Critical) ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer4
    colBackgroundHover: button.quadrinhoSpot ? Qt.darker(QuadrinhoTheme.spot, 1.15) : (urgency == NotificationUrgency.Critical) ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colLayer4Hover
    colRipple: (urgency == NotificationUrgency.Critical) ? Appearance.colors.colSecondaryContainerActive : Appearance.colors.colLayer4Active

    contentItem: StyledText {
        horizontalAlignment: Text.AlignHCenter
        text: buttonText
        color: button.quadrinhoSpot ? QuadrinhoTheme.spotText : (urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
    }

    Loader {
        z: 1
        active: QuadrinhoTheme.active
        anchors.fill: parent
        sourceComponent: Rectangle {
            color: "transparent"
            border.width: 2
            border.color: QuadrinhoTheme.ink
        }
    }
}
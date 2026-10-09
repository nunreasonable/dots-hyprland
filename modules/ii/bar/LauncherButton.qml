import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: root
    property color contentColor: Appearance.colors.colOnLayer0
    property bool contentColorOverridden: false
    property bool vertical: Config.options.bar.vertical

    implicitWidth: 22
    implicitHeight: 22

    buttonRadius: Appearance.rounding.full
    colBackground: "transparent"
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active
    colBackgroundToggled: "transparent"
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive
    toggled: (Config.options.search.spotlight ?? false) ? GlobalStates.spotlightOpen : GlobalStates.overviewOpen

    onPressed: {
        if (Config.options.search.spotlight ?? false) {
            GlobalStates.spotlightMode = "";
            GlobalStates.spotlightOpen = !GlobalStates.spotlightOpen;
        } else {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }

    MaterialSymbol {
        anchors.centerIn: parent
        iconSize: 18
        text: "search"
        color: root.contentColor
    }
}

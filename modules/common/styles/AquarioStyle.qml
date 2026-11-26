import QtQuick
import qs.modules.common
import qs.services

StyleValues {
    key: "aquario"
    displayName: "Aquário"
    icon: "water_drop"
    hint: Translation.tr("Aquário turns the shell into glossy glass where every level is water: volume, brightness, battery and workspaces fill up and ripple when they change. Turn on transparency for blurred glass")
    layout: "end4pc"
    selectable: true

    surface.frame: true
    surface.borderWidth: 1
    surface.borderColor: AquarioTheme.rimOuter
    surface.ringWidth: 2
    surface.ringColor: AquarioTheme.rimInner
    surface.fill: AquarioTheme.card
    surface.fillHover: AquarioTheme.cardHover
    surface.radiusOuter: 28
    surface.radiusInner: Appearance.rounding.full

    type.ui: AquarioTheme.font
    type.display: AquarioTheme.font
    type.numbers: AquarioTheme.font
    type.uiAxes: ({})
    type.displayAxes: ({})
    type.numbersAxes: ({})

    palette.accent: AquarioTheme.waterDeep
    palette.onAccent: AquarioTheme.onWater
    palette.text: AquarioTheme.text
    palette.scheme: AquarioTheme.scheme
}

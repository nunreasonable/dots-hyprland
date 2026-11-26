import QtQuick
import qs.modules.common
import qs.services

StyleValues {
    key: "mainel"
    displayName: "Mainel"
    icon: "window"
    hint: Translation.tr("Mainel turns the new Illogical Windows logo into the whole system: every surface is a window split into jade-trimmed panes, inspired by the mainel that divides a window")
    selectable: true
    settingsLayout: "end4pc"

    surface.frame: true
    surface.barStrip: false
    surface.borderWidth: 0
    surface.ringWidth: 0
    surface.fill: MainelTheme.fill
    surface.fillHover: MainelTheme.fillElevated
    surface.radiusOuter: 18
    surface.radiusInner: 3
    surface.gap: 5

    elevation.kind: "soft"

    type.ui: "Google Sans Flex"
    type.display: "Google Sans Flex"
    type.numbers: "Google Sans Flex"
    type.uiAxes: ({ "wght": 480, "wdth": 100 })
    type.displayAxes: ({ "wght": 650, "wdth": 112 })
    type.numbersAxes: ({ "wght": 700, "wdth": 125, "ROND": 0 })

    motion.profile: "expressive"

    palette.accent: MainelTheme.jadeMid
    palette.onAccent: MainelTheme.onJade
    palette.text: MainelTheme.text
}

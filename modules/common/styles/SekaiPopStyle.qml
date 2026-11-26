import QtQuick
import qs.modules.common
import qs.services

StyleValues {
    key: "sekaipop"
    displayName: "SekaiPop"
    icon: "interests"
    hint: Translation.tr("SekaiPop draws the bar as outlined blocks with a hard shadow that sink when pressed, inspired by SekaiPop by Blapples")

    surface.frame: true
    surface.barStrip: false
    surface.borderWidth: SekaiTheme.borderWidth
    surface.borderColor: SekaiTheme.outline
    surface.ringWidth: SekaiTheme.ringWidth
    surface.ringColor: SekaiTheme.ring
    surface.fill: SekaiTheme.fill
    surface.fillHover: SekaiTheme.fillHover
    surface.radiusInner: Appearance.rounding.full
    surface.gap: 12

    elevation.kind: "hard"
    elevation.y: SekaiTheme.shadowOffset
    elevation.color: SekaiTheme.shadow

    palette.accent: SekaiTheme.accentA
    palette.onAccent: SekaiTheme.textOnAccent
    palette.text: SekaiTheme.text

    motion.wallpaperTransitions: ["sekaiRing", "sekaiIris", "sekaiStar", "sekaiBlocks"]
}

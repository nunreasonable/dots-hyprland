import QtQuick
import Quickshell
import qs.services
import qs.modules.common

StyleValues {
    id: root
    key: "caractere"
    displayName: "Caractere"
    icon: "terminal"
    hint: Translation.tr(
              "Caractere draws the whole shell on a character grid, TUI-style, in Departure Mono (JetBrains Mono NF at fractional scales) with the 16 terminal colors generated from your wallpaper")
    selectable: true
    settingsLayout: "end4pc"

    readonly property color termBg: Appearance.m3colors.term0
    readonly property color termFg: Appearance.m3colors.term7
    readonly property color termWeak: Appearance.m3colors.term8
    readonly property color termAccent: Appearance.m3colors.term6
    readonly property color termWorkspace: Appearance.m3colors.term4
    readonly property color termMatch: Appearance.m3colors.term3
    readonly property color termOk: Appearance.m3colors.term2
    readonly property color termError: Appearance.m3colors.term1
    readonly property color termApps: Appearance.m3colors.term5
    readonly property color termBg2: {
        const c = Qt.color(root.termBg);
        return Qt.hsla(c.hslHue, c.hslSaturation, Math.min(1, c.hslLightness + 0.06), c.a);
    }

    surface.frame: true
    surface.barStrip: true
    surface.borderWidth: 1
    surface.ringWidth: 0
    surface.borderColor: root.termWeak
    surface.fill: root.termBg2
    surface.fillHover: root.termAccent
    surface.radiusOuter: 0
    surface.radiusInner: 0
    surface.gap: 11

    elevation.kind: "none"

    readonly property real _scale: Quickshell.screens[0]?.devicePixelRatio ?? 1
    readonly property bool _departureCrisp: Math.abs(root._scale - Math.round(root._scale)) < 0.02
    readonly property string _resolvedFont: root._departureCrisp ? "Departure Mono" : "JetBrains Mono NF"

    type.ui: root._resolvedFont
    type.display: root._resolvedFont
    type.numbers: root._resolvedFont

    motion.profile: "stepped"

    palette.accent: root.termAccent
    palette.onAccent: root.termBg
    palette.text: root.termFg
    palette.scheme: WindowsTerminalTheme.generatedTermColors
}

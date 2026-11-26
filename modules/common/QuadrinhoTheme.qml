pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property bool active: StyleTheme.key === "quadrinho"
    readonly property bool flashback: Appearance.m3colors.darkmode
    readonly property bool motion: Appearance.animationsEnabled

    readonly property color paper: root.flashback ? "#000000" : "#ffffff"
    readonly property color ink: root.flashback ? "#f2f2f2" : "#000000"
    readonly property color spot: {
        const seed = Appearance.m3colors.m3primaryFixedDim;
        if (seed.hslSaturation < 0.12)
            return "#3a7bff";
        return Qt.hsla(seed.hslHue, 0.9, 0.56, 1);
    }
    readonly property real spotLuma: 0.299 * root.spot.r + 0.587 * root.spot.g + 0.114 * root.spot.b
    readonly property color spotText: root.spotLuma > 0.62 ? "#000000" : "#ffffff"

    readonly property int line: 3
    readonly property int pageLine: 4
    readonly property int gutter: 6
    readonly property int gutterWide: 12

    readonly property string sfxFont: "Dela Gothic One"
    readonly property string uiFont: "Zen Kaku Gothic New Medium"
    readonly property string boldFont: "Zen Kaku Gothic New"

    function tone(density) {
        const step = density >= 45 ? 60 : density >= 20 ? 30 : 10;
        return Qt.resolvedUrl(`../../assets/images/quadrinho/tone-${step}-${root.flashback ? "white" : "black"}.png`);
    }

    readonly property var scheme: {
        const dark = root.flashback;
        const paper = root.paper;
        const ink = root.ink;
        const grey = level => dark ? Qt.rgba(level, level, level, 1) : Qt.rgba(1 - level, 1 - level, 1 - level, 1);
        return {
            "m3background": paper,
            "m3onBackground": ink,
            "m3surface": paper,
            "m3surfaceDim": grey(0.04),
            "m3surfaceBright": dark ? grey(0.1) : paper,
            "m3surfaceContainerLowest": paper,
            "m3surfaceContainerLow": grey(0.04),
            "m3surfaceContainer": grey(0.08),
            "m3surfaceContainerHigh": grey(0.12),
            "m3surfaceContainerHighest": grey(0.16),
            "m3onSurface": ink,
            "m3surfaceVariant": grey(0.12),
            "m3onSurfaceVariant": ink,
            "m3inverseSurface": ink,
            "m3inverseOnSurface": paper,
            "m3outline": grey(0.65),
            "m3outlineVariant": ink,
            "m3shadow": "#000000",
            "m3scrim": "#000000",
            "m3surfaceTint": ink,
            "m3primary": ink,
            "m3onPrimary": paper,
            "m3primaryContainer": grey(0.16),
            "m3onPrimaryContainer": ink,
            "m3inversePrimary": paper,
            "m3secondary": ink,
            "m3onSecondary": paper,
            "m3secondaryContainer": grey(0.12),
            "m3onSecondaryContainer": ink,
            "m3tertiary": ink,
            "m3onTertiary": paper,
            "m3tertiaryContainer": grey(0.08),
            "m3onTertiaryContainer": ink,
            "m3error": ink,
            "m3onError": paper,
            "m3errorContainer": grey(0.16),
            "m3onErrorContainer": ink
        };
    }
}

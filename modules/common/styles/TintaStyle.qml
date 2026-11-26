import QtQuick
import qs.modules.common
import qs.services

StyleValues {
    id: root
    key: "tinta"
    displayName: "Tinta"
    icon: "tonality"
    hint: Translation.tr("Tinta turns the shell into an e-reader screen: gray paper, black ink, dot-dither shadows and a quick invert flash instead of animated motion")
    selectable: true

    readonly property bool night: Appearance.m3colors.darkmode
    readonly property color paper: root.night ? "#212224" : "#E6E7E2"
    readonly property color paperDesk: root.night ? "#161718" : "#D9DAD4"
    readonly property color ink: root.night ? "#C9CAC4" : "#141516"
    readonly property color inkWeak: root.night ? "#8C8E8A" : "#505356"

    surface.frame: true
    surface.barStrip: true
    surface.borderWidth: 2
    surface.borderColor: root.ink
    surface.fill: root.paper
    surface.fillHover: root.paperDesk
    surface.radiusOuter: 10
    surface.radiusInner: 6
    surface.gap: 10

    elevation.kind: "dither"
    elevation.x: 0
    elevation.y: 8
    elevation.color: root.ink

    type.ui: "Atkinson Hyperlegible Next"
    type.display: "Literata"
    type.numbers: "Atkinson Hyperlegible Next"
    type.uiAxes: ({
        "wght": 400
    })
    type.displayAxes: ({
        "wght": 600
    })
    type.numbersAxes: ({
        "wght": 400
    })

    motion.profile: "none"

    palette.accent: root.ink
    palette.onAccent: root.paper
    palette.text: root.ink
    palette.scheme: ({
        "m3background": root.paperDesk,
        "m3onBackground": root.ink,
        "m3surface": root.paper,
        "m3surfaceDim": root.paperDesk,
        "m3surfaceBright": root.paper,
        "m3surfaceContainerLowest": root.paperDesk,
        "m3surfaceContainerLow": root.paper,
        "m3surfaceContainer": root.paper,
        "m3surfaceContainerHigh": root.paper,
        "m3surfaceContainerHighest": root.paper,
        "m3onSurface": root.ink,
        "m3surfaceVariant": root.paper,
        "m3onSurfaceVariant": root.inkWeak,
        "m3inverseSurface": root.ink,
        "m3inverseOnSurface": root.paper,
        "m3outline": root.inkWeak,
        "m3outlineVariant": root.inkWeak,
        "m3shadow": root.ink,
        "m3scrim": root.ink,
        "m3surfaceTint": root.ink,
        "m3primary": root.ink,
        "m3onPrimary": root.paper,
        "m3primaryContainer": root.paper,
        "m3onPrimaryContainer": root.ink,
        "m3inversePrimary": root.paper,
        "m3secondary": root.inkWeak,
        "m3onSecondary": root.paper,
        "m3secondaryContainer": root.paper,
        "m3onSecondaryContainer": root.ink,
        "m3tertiary": root.inkWeak,
        "m3onTertiary": root.paper,
        "m3tertiaryContainer": root.paper,
        "m3onTertiaryContainer": root.ink,
        "m3error": root.ink,
        "m3onError": root.paper,
        "m3errorContainer": root.paper,
        "m3onErrorContainer": root.ink,
        "m3primaryFixed": root.paper,
        "m3primaryFixedDim": root.paper,
        "m3onPrimaryFixed": root.ink,
        "m3onPrimaryFixedVariant": root.inkWeak,
        "m3secondaryFixed": root.paper,
        "m3secondaryFixedDim": root.paper,
        "m3onSecondaryFixed": root.ink,
        "m3onSecondaryFixedVariant": root.inkWeak,
        "m3tertiaryFixed": root.paper,
        "m3tertiaryFixedDim": root.paper,
        "m3onTertiaryFixed": root.ink,
        "m3onTertiaryFixedVariant": root.inkWeak,
        "m3success": root.inkWeak,
        "m3onSuccess": root.paper,
        "m3successContainer": root.paper,
        "m3onSuccessContainer": root.ink
    })

    property real lastFlashAt: 0

    function requestFlash() {
        const now = Date.now();
        if (now - root.lastFlashAt < 500)
            return false;
        root.lastFlashAt = now;
        return true;
    }
}

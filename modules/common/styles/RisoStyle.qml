import QtQuick
import qs.modules.common
import qs.modules.common.functions
import qs.services

StyleValues {
    id: root

    key: "riso"
    displayName: "Riso"
    icon: "print"
    hint: Translation.tr("Riso prints the shell in two translucent inks, teal and fluorescent pink, slightly out of register, with paper grain")
    selectable: true

    readonly property bool darkPaper: Appearance.m3colors.darkmode
    readonly property color paper: root.darkPaper ? "#18181B" : "#F1F3F2"
    readonly property color inkA: root.darkPaper ? "#E8E8E6" : "#00838A"
    readonly property color inkB: "#FF48B0"
    readonly property color overprint: root.darkPaper ? "#FF9AD2" : root.multiply(root.inkA, root.inkB)
    readonly property color inkBTint: root.darkPaper ? "#5A2343" : "#FFD6EC"
    readonly property color text: root.darkPaper ? root.inkA : root.overprint
    readonly property int offset: 5

    function multiply(a, b) {
        return Qt.rgba(a.r * b.r, a.g * b.g, a.b * b.b, 1);
    }

    function tint(color, amount) {
        return ColorUtils.mix(color, root.paper, amount);
    }

    surface.frame: true
    surface.borderWidth: 2
    surface.borderColor: root.inkA
    surface.fillHover: root.inkBTint
    surface.radiusOuter: 20
    surface.radiusInner: 14
    surface.gap: 14

    elevation.kind: "ink"
    elevation.x: root.offset
    elevation.y: root.offset
    elevation.color: root.inkBTint

    type.ui: "Bricolage Grotesque"
    type.uiAxes: ({
            "wght": 500,
            "opsz": 14
        })
    type.display: "Bricolage Grotesque"
    type.displayAxes: ({
            "wght": 700,
            "opsz": 32
        })
    type.numbers: "Bricolage Grotesque"
    type.numbersAxes: ({
            "wght": 600,
            "opsz": 14
        })

    motion.profile: "snappy"

    texture.source: Qt.resolvedUrl("../../../assets/images/riso-grain.png")
    texture.opacity: 0.07

    palette.accent: root.inkB
    palette.onAccent: root.darkPaper ? root.paper : root.overprint
    palette.text: root.text
    palette.scheme: root.darkPaper ? ({
            "m3background": root.paper,
            "m3onBackground": root.text,
            "m3surface": root.paper,
            "m3surfaceDim": ColorUtils.mix("#000000", root.paper, 0.25),
            "m3surfaceBright": root.tint(root.inkA, 0.18),
            "m3surfaceContainerLowest": ColorUtils.mix("#000000", root.paper, 0.25),
            "m3surfaceContainerLow": root.tint(root.inkA, 0.03),
            "m3surfaceContainer": root.tint(root.inkA, 0.05),
            "m3surfaceContainerHigh": root.tint(root.inkA, 0.08),
            "m3surfaceContainerHighest": root.tint(root.inkA, 0.11),
            "m3onSurface": root.text,
            "m3surfaceVariant": root.tint(root.inkA, 0.18),
            "m3onSurfaceVariant": root.tint(root.inkA, 0.85),
            "m3inverseSurface": root.inkA,
            "m3inverseOnSurface": root.paper,
            "m3outline": root.tint(root.inkA, 0.7),
            "m3outlineVariant": root.tint(root.inkA, 0.3),
            "m3surfaceTint": root.inkA,
            "m3primary": root.inkA,
            "m3onPrimary": root.paper,
            "m3primaryContainer": root.tint(root.inkA, 0.2),
            "m3onPrimaryContainer": root.text,
            "m3inversePrimary": root.inkB,
            "m3secondary": root.inkB,
            "m3onSecondary": root.paper,
            "m3secondaryContainer": root.inkBTint,
            "m3onSecondaryContainer": root.text,
            "m3tertiary": root.overprint,
            "m3onTertiary": root.paper,
            "m3tertiaryContainer": root.tint(root.overprint, 0.2),
            "m3onTertiaryContainer": root.text
        }) : ({
            "m3background": root.paper,
            "m3onBackground": root.text,
            "m3surface": root.paper,
            "m3surfaceDim": root.tint(root.inkA, 0.1),
            "m3surfaceBright": root.paper,
            "m3surfaceContainerLowest": ColorUtils.mix("#FFFFFF", root.paper, 0.4),
            "m3surfaceContainerLow": root.tint(root.inkA, 0.03),
            "m3surfaceContainer": root.tint(root.inkA, 0.05),
            "m3surfaceContainerHigh": root.tint(root.inkA, 0.08),
            "m3surfaceContainerHighest": root.tint(root.inkA, 0.11),
            "m3onSurface": root.text,
            "m3surfaceVariant": root.tint(root.inkA, 0.18),
            "m3onSurfaceVariant": ColorUtils.mix(root.overprint, root.inkA, 0.65),
            "m3inverseSurface": root.overprint,
            "m3inverseOnSurface": root.paper,
            "m3outline": ColorUtils.mix(root.overprint, root.inkA, 0.5),
            "m3outlineVariant": root.tint(root.inkA, 0.35),
            "m3surfaceTint": root.inkA,
            "m3primary": root.inkA,
            "m3onPrimary": "#FFFFFF",
            "m3primaryContainer": root.tint(root.inkA, 0.2),
            "m3onPrimaryContainer": root.text,
            "m3inversePrimary": root.inkB,
            "m3secondary": root.inkB,
            "m3onSecondary": root.overprint,
            "m3secondaryContainer": root.inkBTint,
            "m3onSecondaryContainer": root.text,
            "m3tertiary": root.overprint,
            "m3onTertiary": root.paper,
            "m3tertiaryContainer": root.tint(root.overprint, 0.2),
            "m3onTertiaryContainer": root.text
        })
}

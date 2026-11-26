import QtQuick
import qs.modules.common
import qs.services

StyleValues {
    key: "aparelho"
    displayName: "Aparelho"
    icon: "tune"
    hint: Translation.tr("Aparelho turns the shell into a brushed-aluminium device: real keys, an LCD readout and a single jade key, inspired by Dieter Rams and the Teenage Engineering OP-1")
    layout: "ii"
    selectable: true

    readonly property bool dark: Appearance.m3colors.darkmode

    surface.frame: true
    surface.barStrip: true
    surface.borderWidth: 1
    surface.borderColor: dark ? "#0E0F10" : "#8E9296"
    surface.ringWidth: 1
    surface.ringColor: dark ? "#3A3D40" : "#F2F3F3"
    surface.fill: dark ? "#3A3C3F" : "#E9EAEA"
    surface.fillHover: dark ? "#1A1B1D" : "#A4A8AB"
    surface.radiusOuter: 14
    surface.radiusInner: 6
    surface.gap: 10

    palette.accent: "#3CCDAA"
    palette.onAccent: "#0E2A22"
    palette.text: dark ? "#C9CCCE" : "#2A2B2E"

    palette.scheme: dark ? ({
            "m3background": "#1D1E20",
            "m3onBackground": "#C9CCCE",
            "m3surface": "#1D1E20",
            "m3surfaceDim": "#0E0F10",
            "m3surfaceBright": "#3A3D40",
            "m3surfaceContainerLowest": "#0E0F10",
            "m3surfaceContainerLow": "#2A2B2E",
            "m3surfaceContainer": "#1D1E20",
            "m3surfaceContainerHigh": "#111214",
            "m3surfaceContainerHighest": "#0E0F10",
            "m3onSurface": "#C9CCCE",
            "m3surfaceVariant": "#3A3D40",
            "m3onSurfaceVariant": "#8C9194",
            "m3inverseSurface": "#C9CCCE",
            "m3inverseOnSurface": "#1D1E20",
            "m3outline": "#0E0F10",
            "m3outlineVariant": "#3A3D40",
            "m3primary": "#3CCDAA",
            "m3onPrimary": "#0E2A22",
            "m3primaryContainer": "#22977C",
            "m3onPrimaryContainer": "#0A1F1A",
            "m3secondary": "#8C9194",
            "m3onSecondary": "#0E0F10",
            "m3secondaryContainer": "#111214",
            "m3onSecondaryContainer": "#C9CCCE",
            "m3tertiary": "#3CCDAA",
            "m3onTertiary": "#0E2A22",
            "m3tertiaryContainer": "#1A1B1D",
            "m3onTertiaryContainer": "#C9CCCE"
        }) : ({
            "m3background": "#C9CBCC",
            "m3onBackground": "#2A2B2E",
            "m3surface": "#C9CBCC",
            "m3surfaceDim": "#8E9296",
            "m3surfaceBright": "#F2F3F3",
            "m3surfaceContainerLowest": "#F2F3F3",
            "m3surfaceContainerLow": "#E9EAEA",
            "m3surfaceContainer": "#C9CBCC",
            "m3surfaceContainerHigh": "#A4A8AB",
            "m3surfaceContainerHighest": "#8E9296",
            "m3onSurface": "#2A2B2E",
            "m3surfaceVariant": "#A4A8AB",
            "m3onSurfaceVariant": "#62676A",
            "m3inverseSurface": "#2A2B2E",
            "m3inverseOnSurface": "#F2F3F3",
            "m3outline": "#8E9296",
            "m3outlineVariant": "#F2F3F3",
            "m3primary": "#3CCDAA",
            "m3onPrimary": "#0E2A22",
            "m3primaryContainer": "#22977C",
            "m3onPrimaryContainer": "#F2F3F3",
            "m3secondary": "#62676A",
            "m3onSecondary": "#F2F3F3",
            "m3secondaryContainer": "#A4A8AB",
            "m3onSecondaryContainer": "#2A2B2E",
            "m3tertiary": "#3CCDAA",
            "m3onTertiary": "#0E2A22",
            "m3tertiaryContainer": "#E9EAEA",
            "m3onTertiaryContainer": "#2A2B2E"
        })

    type.ui: "Archivo"
    type.display: "Archivo"
    type.numbers: "DSEG7 Classic"
    type.uiAxes: ({
            "wght": 500,
            "wdth": 112
        })
    type.displayAxes: ({
            "wght": 650,
            "wdth": 112
        })

    motion.profile: "snappy"

    property color keyLightFill: dark ? "#3A3C3F" : "#E9EAEA"
    property color keyLightPressed: dark ? "#1A1B1D" : "#A4A8AB"
    property color keyDarkFill: dark ? "#111214" : "#2A2B2E"
    property color keyDarkPressed: dark ? "#000000" : "#111213"
    property color edgeLight: dark ? "#3A3D40" : "#F2F3F3"
    property color edgeDark: dark ? "#0E0F10" : "#8E9296"
    property color legend: dark ? "#C9CCCE" : "#2A2B2E"
    property color legendFaint: dark ? "#8C9194" : "#62676A"
    property color lcdBg: dark ? "#0F1A17" : "#AEB9A8"
    property color lcdOn: dark ? "#6FF0C8" : "#1C211B"
    property color lcdOff: dark ? "#17251F" : "#A5B09F"
    property color ledOn: "#3CCDAA"
    property color ledOff: "#8A8F92"
    property color jade: "#3CCDAA"
    property color jadePressed: "#22977C"
    property color paper: dark ? "#E9EBEB" : "#F7F8F8"
}

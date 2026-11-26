pragma Singleton
import QtQuick
import Quickshell
import qs.services
import qs.modules.common.functions

Singleton {
    id: root

    readonly property bool active: StyleTheme.key === "aquario"
    readonly property bool dark: Appearance.m3colors.darkmode
    readonly property bool transparent: Config.options.appearance.transparency.enable
    readonly property bool blurred: root.transparent && (!Platform.isWindows || (WindowsNative.blur?.available ?? false))
    readonly property bool moving: Appearance.animationsEnabled

    readonly property color source: MaterialThemeLoader.generated?.primary ?? "#1f98c2"
    readonly property bool follows: root.source.hslSaturation > 0.18

    function hue(c) {
        const base = Qt.color(c);
        return root.follows ? Qt.hsla(root.source.hslHue, base.hslSaturation, base.hslLightness, base.a) : base;
    }

    function tint(c) {
        return root.follows ? ColorUtils.mix(c, root.hue("#1f98c2"), 0.92) : Qt.color(c);
    }

    readonly property string font: "Rounded Mplus 1c"
    readonly property real waveAmplitude: 6
    readonly property int waveDuration: 600

    readonly property color text: root.dark ? "#e3f6fb" : "#0d3243"
    readonly property color textWeak: root.dark ? "#8fb3c2" : "#4f7182"
    readonly property color glass: root.tint(root.dark ? "#0b2030" : "#f3fafd")
    readonly property color glassSolid: root.tint(root.dark ? "#0d2536" : "#eaf6fb")
    readonly property color card: root.dark ? "#14ffffff" : "#a6ffffff"
    readonly property color cardHover: root.dark ? "#22ffffff" : "#d9ffffff"
    readonly property color rimInner: root.dark ? "#30ffffff" : "#e6ffffff"
    readonly property color rimOuter: root.dark ? "#4d000000" : "#240d3243"
    readonly property real glossAlpha: root.dark ? 0.12 : 0.55
    readonly property color waterTop: root.hue(root.dark ? "#7ff0ff" : "#6fe3f2")
    readonly property color waterBottom: root.hue("#1f98c2")
    readonly property color waterDeep: root.hue(root.dark ? "#1d84a9" : "#1a8ab3")
    readonly property color waterSoft: root.hue(root.dark ? "#1b4a60" : "#cdeff7")
    readonly property color jadeTop: root.hue("#6fe3d6")
    readonly property color jadeBottom: root.hue("#25a9c9")
    readonly property color alarmTop: "#ffb4a6"
    readonly property color alarmBottom: "#d9473a"
    readonly property color onWater: "#ffffff"
    readonly property color bubble: root.dark ? "#b3ffffff" : "#d9ffffff"

    readonly property var scheme: root.dark ? ({
            m3background: root.glass,
            m3onBackground: root.text,
            m3surface: root.glass,
            m3surfaceDim: root.tint("#081824"),
            m3surfaceBright: root.tint("#1d3e52"),
            m3surfaceContainerLowest: root.tint("#07161f"),
            m3surfaceContainerLow: root.tint("#102a3c"),
            m3surfaceContainer: root.tint("#143246"),
            m3surfaceContainerHigh: root.tint("#1a3b51"),
            m3surfaceContainerHighest: root.tint("#20465e"),
            m3onSurface: root.text,
            m3surfaceVariant: root.tint("#1e4257"),
            m3onSurfaceVariant: "#a9cad7",
            m3outline: root.textWeak,
            m3outlineVariant: root.tint("#2a4f63"),
            m3inverseSurface: "#e3f6fb",
            m3inverseOnSurface: "#0d3243",
            m3shadow: "#000000",
            m3primary: root.hue("#6fd8ef"),
            m3onPrimary: root.hue("#003548"),
            m3primaryContainer: root.hue("#155f7b"),
            m3onPrimaryContainer: root.hue("#d3f4fc"),
            m3secondary: root.hue("#8fd3e6"),
            m3onSecondary: root.hue("#06303f"),
            m3secondaryContainer: root.waterSoft,
            m3onSecondaryContainer: root.hue("#d3f1f8"),
            m3surfaceTint: root.hue("#6fd8ef")
        }) : ({
            m3background: root.glass,
            m3onBackground: root.text,
            m3surface: root.glass,
            m3surfaceDim: root.tint("#d9ecf4"),
            m3surfaceBright: "#ffffff",
            m3surfaceContainerLowest: "#ffffff",
            m3surfaceContainerLow: root.tint("#fafdfe"),
            m3surfaceContainer: root.tint("#edf7fb"),
            m3surfaceContainerHigh: root.tint("#e2f1f7"),
            m3surfaceContainerHighest: root.tint("#d6ebf3"),
            m3onSurface: root.text,
            m3surfaceVariant: root.tint("#d5e9f1"),
            m3onSurfaceVariant: "#33586a",
            m3outline: root.textWeak,
            m3outlineVariant: root.tint("#bcd7e2"),
            m3inverseSurface: "#0d3243",
            m3inverseOnSurface: "#e3f6fb",
            m3shadow: "#0d3243",
            m3primary: root.waterDeep,
            m3onPrimary: "#ffffff",
            m3primaryContainer: root.hue("#bdeef8"),
            m3onPrimaryContainer: root.hue("#003548"),
            m3secondary: root.hue("#3c8aa6"),
            m3onSecondary: "#ffffff",
            m3secondaryContainer: root.waterSoft,
            m3onSecondaryContainer: root.text,
            m3surfaceTint: root.waterDeep
        })

    Binding {
        when: root.active
        target: Appearance
        property: "autoBackgroundTransparency"
        value: 0.18
    }
}

pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common.functions

Singleton {
    id: root

    readonly property bool active: Config.options.appearance.visualStyleApplied === "sekaipop"
    readonly property bool dark: Appearance.m3colors.darkmode
    readonly property list<string> themes: ["mint", "indigo", "lime", "rose", "amber", "violet", "mono", "wallpaper"]
    readonly property string themeName: root.themes.includes(Config.options.appearance.sekaipop.theme) ? Config.options.appearance.sekaipop.theme : "mint"

    readonly property var palettes: ({
            "mint": { border: "#555473", a: "#04feee", b: "#00ffcb", deep: "#232235" },
            "indigo": { border: "#2d3775", a: "#8ea3ff", b: "#9fd8ff", deep: "#181e3f" },
            "lime": { border: "#39662d", a: "#a4ee55", b: "#7fe9a8", deep: "#223c1b" },
            "rose": { border: "#561938", a: "#ff5c9a", b: "#ff96c0", deep: "#43142c" },
            "amber": { border: "#6a3c11", a: "#ffa51f", b: "#ffd54a", deep: "#4b2a0c" },
            "violet": { border: "#43285f", a: "#c08cf2", b: "#e2b5ff", deep: "#2b1a3d" },
            "mono": { border: "#444444", a: "#f4f4f4", b: "#bdbdbd", deep: "#1a1a1a" }
        })
    readonly property var wallpaperPalette: ({
            border: ColorUtils.mix(Appearance.m3colors.m3primary, "#000000", 0.45),
            a: Appearance.m3colors.m3primary,
            b: Appearance.m3colors.m3tertiary,
            deep: ColorUtils.mix(Appearance.m3colors.m3primary, "#000000", 0.18)
        })
    readonly property var palette: root.themeName === "wallpaper" ? root.wallpaperPalette : root.palettes[root.themeName]

    readonly property color outline: root.palette.border
    readonly property color shadow: root.palette.border
    readonly property color accentA: root.palette.a
    readonly property color accentB: root.palette.b
    readonly property color deep: root.palette.deep
    readonly property color ring: root.dark ? Qt.tint("#ffffff", Qt.rgba(root.outline.r, root.outline.g, root.outline.b, 0.08)) : "#ffffff"
    readonly property color fill: root.dark ? Qt.lighter(root.deep, 1.18) : "#ffffff"
    readonly property color fillHover: root.dark ? Qt.lighter(root.fill, 1.35) : "#f2f2f2"
    readonly property color text: root.dark ? "#f4f4fa" : root.outline
    readonly property color textOnAccent: root.palette.border

    readonly property int borderWidth: 3
    readonly property int shadowOffset: 4
    readonly property int ringWidth: 4
    readonly property int pillHeight: 36
}

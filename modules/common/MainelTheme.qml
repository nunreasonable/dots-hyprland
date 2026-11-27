pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common.functions

Singleton {
    id: root

    readonly property bool active: StyleTheme.key === "mainel"
    readonly property bool dark: Appearance.m3colors.darkmode
    readonly property color matugenTint: Appearance.m3colors.m3primary

    readonly property color paneBase: root.dark ? "#1E202B" : "#F4F8F7"
    readonly property color paneElevatedBase: root.dark ? "#2A2D3C" : "#FFFFFF"
    readonly property color paneDeepBase: root.dark ? "#171922" : "#E3EBE8"
    readonly property color fill: ColorUtils.transparentize(ColorUtils.mix(root.paneBase, root.matugenTint, 0.94), 0.06)
    readonly property color fillElevated: ColorUtils.mix(root.paneElevatedBase, root.matugenTint, 0.96)
    readonly property color fillDeep: ColorUtils.mix(root.paneDeepBase, root.matugenTint, 0.96)

    readonly property color text: root.dark ? "#E9F2EF" : "#1E202B"
    readonly property color textWeak: root.dark ? "#98A3A9" : "#5C6B69"
    readonly property color jadeText: root.dark ? "#80E6BD" : "#12806A"
    readonly property color onJade: root.dark ? "#1E202B" : "#10201C"

    readonly property color jadeStart: "#38C3A7"
    readonly property color jadeMid: "#51DEBD"
    readonly property color jadeEnd: "#80E6BD"

    readonly property Gradient jadeGradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: root.jadeStart }
        GradientStop { position: 0.55; color: root.jadeMid }
        GradientStop { position: 1; color: root.jadeEnd }
    }
}

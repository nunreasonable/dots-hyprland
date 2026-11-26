pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common.styles

Singleton {
    id: root

    readonly property list<StyleValues> all: [
        IiStyle {},
        End4pcStyle {},
        NabyScapeStyle {},
        SekaiPopStyle {},
        MainelStyle {},
        TintaStyle {},
        CaractereStyle {},
        RisoStyle {},
        QuadrinhoStyle {},
        AquarioStyle {},
        AparelhoStyle {}
    ]

    readonly property StyleValues current: root.entry(Config.options.appearance.visualStyleApplied) ?? root.all[0]
    readonly property string key: root.current.key

    readonly property var surface: root.current.surface
    readonly property var elevation: root.current.elevation
    readonly property var type: root.current.type
    readonly property var motion: root.current.motion
    readonly property var texture: root.current.texture
    readonly property var palette: root.current.palette

    readonly property bool softShadow: root.elevation.kind === "soft"
    readonly property bool hardShadow: root.elevation.kind !== "soft" && root.elevation.kind !== "none"
    readonly property bool smoothMotion: root.motion.profile === "expressive" || root.motion.profile === "snappy"
    readonly property real motionScale: root.motion.profile === "snappy" ? 0.6 : 1

    function entry(key) {
        for (let i = 0; i < root.all.length; ++i) {
            if (root.all[i].key === key)
                return root.all[i];
        }
        return null;
    }
}

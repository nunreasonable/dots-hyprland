import QtQuick
import qs.modules.common
import qs.services

StyleValues {
    key: "quadrinho"
    displayName: "Quadrinho"
    icon: "comic_bubble"
    hint: Translation.tr("Quadrinho turns the desktop into a manga page: inked panels, screentone and notifications in speech balloons. In dark mode the pages turn black, like a flashback")
    layout: "end4pc"
    preset: ({
            "bar.cornerStyle": [2, 0],
            "bar.frameColor": ["layer0", "black"],
            "background.widgets.clock.style": ["digital", "cookie"],
            "dock.radius": [0, 23],
            "dock.borderWidth": [3, 1],
            "dock.borderColor": ["onLayer0", "layer0Border"]
        })

    surface.frame: true
    surface.borderWidth: QuadrinhoTheme.line
    surface.borderColor: QuadrinhoTheme.ink
    surface.fill: QuadrinhoTheme.paper
    surface.fillHover: QuadrinhoTheme.scheme.m3surfaceContainer
    surface.radiusOuter: 0
    surface.radiusInner: 0
    surface.gap: QuadrinhoTheme.gutterWide + 10

    elevation.kind: "none"

    type.ui: QuadrinhoTheme.uiFont
    type.display: QuadrinhoTheme.sfxFont
    type.numbers: QuadrinhoTheme.uiFont
    type.uiAxes: ({})
    type.displayAxes: ({})
    type.numbersAxes: ({})

    motion.profile: "snappy"

    palette.accent: QuadrinhoTheme.ink
    palette.onAccent: QuadrinhoTheme.paper
    palette.text: QuadrinhoTheme.ink
    palette.scheme: QuadrinhoTheme.scheme
}

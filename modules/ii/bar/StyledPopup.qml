import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

LazyLoader {
    id: root

    property Item hoverTarget
    default property Component contentComponent
    property real popupBackgroundMargin: 0

    readonly property bool shouldShow: !!root.hoverTarget && root.hoverTarget.containsMouse && Config.options.bar.tooltips.enable && !GlobalStates.barStyleEditorOpen
    readonly property bool morph: Config.options.bar.tooltips.style === "morph"
    property bool closing: false
    readonly property string barEdge: Config.options.bar.vertical ? (Config.options.bar.bottom ? "right" : "left") : (Config.options.bar.bottom ? "bottom" : "top")
    readonly property bool barVertical: Config.options.bar.vertical
    readonly property real bounceRoom: 24
    readonly property real filletRadius: 10
    readonly property var group: root.findGroup(root.hoverTarget)

    active: root.shouldShow || root.closing
    onShouldShowChanged: {
        if (!root.shouldShow && root.item && root.morph)
            root.closing = true;
    }

    function findGroup(item) {
        let p = item;
        while (p) {
            if (p.morphEdge !== undefined)
                return p;
            p = p.parent;
        }
        return null;
    }

    component Fillet: Shape {
        id: fillet
        property real r: 0
        property bool flipH: false
        property bool flipV: false
        property color fillColor: "transparent"
        width: r
        height: r
        visible: r > 0
        layer.enabled: true
        layer.samples: 4
        transform: Scale {
            origin.x: fillet.width / 2
            origin.y: fillet.height / 2
            xScale: fillet.flipH ? -1 : 1
            yScale: fillet.flipV ? -1 : 1
        }
        ShapePath {
            fillColor: fillet.fillColor
            strokeWidth: -1
            startX: fillet.r
            startY: fillet.r
            PathLine {
                x: 0
                y: fillet.r
            }
            PathArc {
                x: fillet.r
                y: 0
                radiusX: fillet.r
                radiusY: fillet.r
                direction: PathArc.Counterclockwise
            }
            PathLine {
                x: fillet.r
                y: fillet.r
            }
        }
    }

    component: PanelWindow {
        id: popupWindow
        color: "transparent"

        readonly property Item groupBox: root.group ? root.group.box : root.hoverTarget
        readonly property var barWin: root.hoverTarget?.QsWindow?.window ?? null
        readonly property rect boxRect: {
            const box = popupWindow.groupBox;
            if (!box)
                return Qt.rect(0, 0, 0, 0);
            if (Platform.isWindows) {
                const a = box.mapToGlobal(0, 0);
                const b = box.mapToGlobal(box.width, box.height);
                return Qt.rect(a.x - (popupWindow.screen?.x ?? 0), a.y - (popupWindow.screen?.y ?? 0), b.x - a.x, b.y - a.y);
            }
            const win = popupWindow.barWin;
            const originX = !win ? 0 : (win.anchors.left ? win.margins.left : popupWindow.screen.width - win.width - win.margins.right);
            const originY = !win ? 0 : (win.anchors.top ? win.margins.top : popupWindow.screen.height - win.height - win.margins.bottom);
            const a = box.mapToItem(null, 0, 0);
            const b = box.mapToItem(null, box.width, box.height);
            return Qt.rect(originX + a.x, originY + a.y, b.x - a.x, b.y - a.y);
        }
        readonly property real cardWidth: popupBackground.implicitWidth
        readonly property real cardHeight: popupBackground.implicitHeight
        readonly property real snapRange: 10 + root.filletRadius * 2

        function clampAlong(center, size, boxStartPos, boxLength, screenLength) {
            const low = boxStartPos < popupWindow.snapRange ? boxStartPos : 10;
            const high = screenLength - boxStartPos - boxLength < popupWindow.snapRange ? boxStartPos + boxLength - size : screenLength - size - 10;
            return Math.max(low, Math.min(center - size / 2, high));
        }

        readonly property real cardLeft: root.barVertical ? (root.barEdge === "left" ? boxRect.x + boxRect.width : boxRect.x - cardWidth) : clampAlong(boxRect.x + boxRect.width / 2, cardWidth, boxRect.x, boxRect.width, popupWindow.screen.width)
        readonly property real cardTop: !root.barVertical ? (root.barEdge === "top" ? boxRect.y + boxRect.height : boxRect.y - cardHeight) : clampAlong(boxRect.y + boxRect.height / 2, cardHeight, boxRect.y, boxRect.height, popupWindow.screen.height)
        readonly property real boxStart: root.barVertical ? boxRect.y - cardTop : boxRect.x - cardLeft
        readonly property real boxEnd: boxStart + (root.barVertical ? boxRect.height : boxRect.width)
        readonly property real cardExtent: root.barVertical ? cardHeight : cardWidth
        readonly property bool startCovered: boxStart >= 0
        readonly property bool endCovered: boxEnd <= cardExtent

        function filletSpec(isStart) {
            const d = isStart ? boxStart : boxEnd - cardExtent;
            const wide = isStart ? d > 0 : d < 0;
            const r = Math.min(root.filletRadius, Math.abs(d));
            const edge = root.barEdge;
            const sideDir = isStart ? -1 : 1;
            const alongCorner = isStart ? (wide ? d : 0) : (wide ? boxEnd : cardExtent);
            let cx, cy, sx, sy;
            if (!root.barVertical) {
                cx = alongCorner;
                cy = edge === "top" ? 0 : cardHeight;
                sx = sideDir;
                sy = edge === "top" ? (wide ? -1 : 1) : (wide ? 1 : -1);
            } else {
                cy = alongCorner;
                cx = edge === "left" ? 0 : cardWidth;
                sy = sideDir;
                sx = edge === "left" ? (wide ? -1 : 1) : (wide ? 1 : -1);
            }
            return {
                r: r,
                x: cx + (sx < 0 ? -r : 0),
                y: cy + (sy < 0 ? -r : 0),
                flipH: sx > 0,
                flipV: sy > 0
            };
        }

        function flat(corner) {
            if (!root.morph)
                return false;
            const e = root.barEdge;
            if (e === "top")
                return (corner === "tl" && boxStart <= 0) || (corner === "tr" && boxEnd >= cardExtent);
            if (e === "bottom")
                return (corner === "bl" && boxStart <= 0) || (corner === "br" && boxEnd >= cardExtent);
            if (e === "left")
                return (corner === "tl" && boxStart <= 0) || (corner === "bl" && boxEnd >= cardExtent);
            return (corner === "tr" && boxStart <= 0) || (corner === "br" && boxEnd >= cardExtent);
        }
        readonly property var startFillet: filletSpec(true)
        readonly property var endFillet: filletSpec(false)

        Binding {
            target: root.group
            property: "morphEdge"
            value: ({
                    top: "bottom",
                    bottom: "top",
                    left: "right",
                    right: "left"
                })[root.barEdge]
            when: root.morph && root.group !== null && root.shouldShow
        }
        Binding {
            target: root.group
            property: "morphStartFlat"
            value: popupWindow.startCovered
            when: root.morph && root.group !== null && root.shouldShow
        }
        Binding {
            target: root.group
            property: "morphEndFlat"
            value: popupWindow.endCovered
            when: root.morph && root.group !== null && root.shouldShow
        }

        anchors.left: root.morph || !Config.options.bar.vertical || (Config.options.bar.vertical && !Config.options.bar.bottom)
        anchors.right: !root.morph && Config.options.bar.vertical && Config.options.bar.bottom
        anchors.top: root.morph || Config.options.bar.vertical || (!Config.options.bar.vertical && !Config.options.bar.bottom)
        anchors.bottom: !root.morph && !Config.options.bar.vertical && Config.options.bar.bottom

        implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin + (root.morph && root.barVertical ? root.bounceRoom : 0)
        implicitHeight: popupBackground.implicitHeight + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin + (root.morph && !root.barVertical ? root.bounceRoom : 0)

        mask: Region {
            item: popupBackground
        }

        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        margins {
            left: {
                if (root.morph)
                    return popupWindow.cardLeft - Appearance.sizes.elevationMargin - (root.barEdge === "right" ? root.bounceRoom : 0);
                if (!Config.options.bar.vertical) {
                    const origin = root.QsWindow?.mapFromItem(root.hoverTarget, 0, 0);
                    const far = root.QsWindow?.mapFromItem(root.hoverTarget, root.hoverTarget.width, 0);
                    if (!origin || !far)
                        return 0;
                    return origin.x + (far.x - origin.x - popupBackground.implicitWidth) / 2;
                }
                return Appearance.sizes.verticalBarWidth;
            }
            top: {
                if (root.morph)
                    return popupWindow.cardTop - Appearance.sizes.elevationMargin - (root.barEdge === "bottom" ? root.bounceRoom : 0);
                if (!Config.options.bar.vertical)
                    return Appearance.sizes.barHeight;
                return root.QsWindow?.mapFromItem(root.hoverTarget, (root.hoverTarget.height - popupBackground.implicitHeight) / 2, 0).y;
            }
            right: root.morph ? 0 : Appearance.sizes.verticalBarWidth
            bottom: root.morph ? 0 : Appearance.sizes.barHeight
        }
        WlrLayershell.namespace: "quickshell:popup"
        WlrLayershell.layer: WlrLayer.Overlay

        Item {
            id: body
            anchors {
                fill: parent
                leftMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.left) + (root.morph && root.barEdge === "right" ? root.bounceRoom : 0)
                rightMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.right) + (root.morph && root.barEdge === "left" ? root.bounceRoom : 0)
                topMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.top) + (root.morph && root.barEdge === "bottom" ? root.bounceRoom : 0)
                bottomMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.bottom) + (root.morph && root.barEdge === "top" ? root.bounceRoom : 0)
            }
            transform: Scale {
                id: bodyScale
                origin.x: root.barEdge === "left" ? 0 : root.barEdge === "right" ? body.width : body.width / 2
                origin.y: root.barEdge === "top" ? 0 : root.barEdge === "bottom" ? body.height : body.height / 2
                xScale: (root.morph && root.barVertical) ? 0.01 : 1
                yScale: (root.morph && !root.barVertical) ? 0.01 : 1
            }

            StyledRectangularShadow {
                target: popupBackground
                visible: !root.morph
            }

            Rectangle {
                id: popupBackground
                readonly property real margin: 10
                anchors.fill: parent
                implicitWidth: contentLoader.implicitWidth + margin * 2
                implicitHeight: contentLoader.implicitHeight + margin * 2
                color: Appearance.m3colors.m3surfaceContainer
                radius: root.morph ? Appearance.rounding.large : Appearance.rounding.small
                topLeftRadius: popupWindow.flat("tl") ? 0 : radius
                topRightRadius: popupWindow.flat("tr") ? 0 : radius
                bottomLeftRadius: popupWindow.flat("bl") ? 0 : radius
                bottomRightRadius: popupWindow.flat("br") ? 0 : radius

                border.width: root.morph ? 0 : 1
                border.color: Appearance.colors.colLayer0Border

                Fillet {
                    visible: root.morph
                    r: popupWindow.startFillet.r
                    x: popupWindow.startFillet.x
                    y: popupWindow.startFillet.y
                    flipH: popupWindow.startFillet.flipH
                    flipV: popupWindow.startFillet.flipV
                    fillColor: popupBackground.color
                }
                Fillet {
                    visible: root.morph
                    r: popupWindow.endFillet.r
                    x: popupWindow.endFillet.x
                    y: popupWindow.endFillet.y
                    flipH: popupWindow.endFillet.flipH
                    flipV: popupWindow.endFillet.flipV
                    fillColor: popupBackground.color
                }

                Loader {
                    id: contentLoader
                    anchors.centerIn: parent
                    opacity: root.morph ? 0 : 1
                    sourceComponent: root.contentComponent
                }
            }
        }

        Connections {
            target: root
            function onShouldShowChanged() {
                if (!root.morph)
                    return;
                if (root.shouldShow) {
                    closeAnim.stop();
                    openAnim.restart();
                } else {
                    openAnim.stop();
                    closeAnim.restart();
                }
            }
        }

        ParallelAnimation {
            id: openAnim
            running: root.morph
            NumberAnimation {
                target: bodyScale
                property: root.barVertical ? "xScale" : "yScale"
                to: 1
                duration: 500
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
            }
            SequentialAnimation {
                PauseAnimation {
                    duration: 90
                }
                NumberAnimation {
                    target: contentLoader
                    property: "opacity"
                    to: 1
                    duration: Appearance.animationCurves.expressiveEffectsDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                }
            }
        }

        ParallelAnimation {
            id: closeAnim
            onFinished: root.closing = false
            NumberAnimation {
                target: bodyScale
                property: root.barVertical ? "xScale" : "yScale"
                to: 0.01
                duration: 220
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedAccel
            }
            NumberAnimation {
                target: contentLoader
                property: "opacity"
                to: 0
                duration: 120
            }
        }
    }
}

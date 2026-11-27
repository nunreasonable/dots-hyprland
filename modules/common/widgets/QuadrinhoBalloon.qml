import QtQuick
import QtQuick.Shapes
import qs.modules.common

Item {
    id: root

    property color fill: QuadrinhoTheme.paper
    property color ink: QuadrinhoTheme.ink
    property real line: QuadrinhoTheme.line
    property bool shout: false
    property string tailSide: "none"
    property real tailLength: 16
    property real tailWidth: 22
    property real tailBase: 0.78
    property real tailTip: 0.9
    property real maxRadius: 30
    property real spike: 7

    readonly property real bodyTop: root.tailSide === "top" ? root.tailLength : 0
    readonly property real bodyBottom: root.height - (root.tailSide === "bottom" ? root.tailLength : 0)
    readonly property var outline: root.buildOutline(root.width, root.height, root.shout, root.tailSide)

    function sampleEdge(points, ax, ay, bx, by, nx, ny, step) {
        const n = Math.max(1, Math.ceil(Math.hypot(bx - ax, by - ay) / step));
        for (let i = 0; i < n; ++i)
            points.push([ax + (bx - ax) * i / n, ay + (by - ay) * i / n, nx, ny]);
    }

    function sampleArc(points, cx, cy, r, from, to, step) {
        const n = Math.max(2, Math.ceil(r * Math.abs(to - from) / step));
        for (let i = 0; i < n; ++i) {
            const a = from + (to - from) * i / n;
            points.push([cx + r * Math.cos(a), cy + r * Math.sin(a), Math.cos(a), Math.sin(a)]);
        }
    }

    function buildOutline(width, height, shout, tailSide) {
        if (width <= 0 || height <= 0)
            return [];
        const h = root.line / 2;
        const inset = h + (shout ? root.spike : 0);
        const x0 = inset;
        const x1 = width - inset;
        const y0 = root.bodyTop + inset;
        const y1 = root.bodyBottom - inset;
        const r = Math.max(0, Math.min(root.maxRadius, (y1 - y0) / 2, (x1 - x0) / 2));
        const step = shout ? root.spike * 1.4 : 4;
        const half = root.tailWidth / 2;
        const baseX = Math.max(x0 + r + half, Math.min(x1 - r - half, width * root.tailBase));
        const tipX = Math.max(h, Math.min(width - h, width * root.tailTip));
        const pts = [];

        if (tailSide === "top") {
            root.sampleEdge(pts, x0 + r, y0, baseX - half, y0, 0, -1, step);
            pts.push([baseX - half, y0, 0, 0]);
            pts.push([tipX, h, 0, 0]);
            pts.push([baseX + half, y0, 0, 0]);
            root.sampleEdge(pts, baseX + half, y0, x1 - r, y0, 0, -1, step);
        } else {
            root.sampleEdge(pts, x0 + r, y0, x1 - r, y0, 0, -1, step);
        }
        root.sampleArc(pts, x1 - r, y0 + r, r, -Math.PI / 2, 0, step);
        root.sampleEdge(pts, x1, y0 + r, x1, y1 - r, 1, 0, step);
        root.sampleArc(pts, x1 - r, y1 - r, r, 0, Math.PI / 2, step);
        if (tailSide === "bottom") {
            root.sampleEdge(pts, x1 - r, y1, baseX + half, y1, 0, 1, step);
            pts.push([baseX + half, y1, 0, 0]);
            pts.push([tipX, height - h, 0, 0]);
            pts.push([baseX - half, y1, 0, 0]);
            root.sampleEdge(pts, baseX - half, y1, x0 + r, y1, 0, 1, step);
        } else {
            root.sampleEdge(pts, x1 - r, y1, x0 + r, y1, 0, 1, step);
        }
        root.sampleArc(pts, x0 + r, y1 - r, r, Math.PI / 2, Math.PI, step);
        root.sampleEdge(pts, x0, y1 - r, x0, y0 + r, -1, 0, step);
        root.sampleArc(pts, x0 + r, y0 + r, r, Math.PI, Math.PI * 1.5, step);

        const out = [];
        let flip = 0;
        for (const p of pts) {
            const reach = shout && (p[2] !== 0 || p[3] !== 0) && (flip++ % 2 === 1) ? root.spike : 0;
            out.push(Qt.point(p[0] + p[2] * reach, p[1] + p[3] * reach));
        }
        if (out.length > 0)
            out.push(out[0]);
        return out;
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.fill
            strokeColor: root.ink
            strokeWidth: root.line
            joinStyle: root.shout ? ShapePath.MiterJoin : ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap

            PathPolyline {
                path: root.outline
            }
        }
    }
}

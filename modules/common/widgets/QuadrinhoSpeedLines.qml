import QtQuick
import QtQuick.Shapes
import qs.modules.common

Item {
    id: root

    property color ink: QuadrinhoTheme.ink
    property real focusX: 0.5
    property real focusY: 0.5
    property real clearX: 0.3
    property real clearY: 0.3
    property int count: 72
    property int seed: 7
    property real thickness: 0.012

    readonly property var paths: root.build(root.width, root.height)

    function build(width, height) {
        if (width <= 0 || height <= 0)
            return [[], []];
        let state = root.seed * 2654435761 % 4294967296;
        const random = () => {
            state = (state * 1664525 + 1013904223) % 4294967296;
            return state / 4294967296;
        };
        const fx = width * root.focusX;
        const fy = height * root.focusY;
        const R = Math.hypot(Math.max(fx, width - fx), Math.max(fy, height - fy)) * 1.15 + 4;
        const cx = width * root.clearX;
        const cy = height * root.clearY;
        const star = [];
        for (let i = 0; i < root.count; ++i) {
            const a = (i + random() * 0.8) / root.count * Math.PI * 2;
            const w = root.thickness * (0.35 + random());
            const k = 1 + random() * 0.7;
            star.push(Qt.point(fx + R * Math.cos(a - w), fy + R * Math.sin(a - w)));
            star.push(Qt.point(fx + cx * k * Math.cos(a), fy + cy * k * Math.sin(a)));
            star.push(Qt.point(fx + R * Math.cos(a + w), fy + R * Math.sin(a + w)));
        }
        star.push(star[0]);
        const box = [Qt.point(fx - R - 2, fy - R - 2), Qt.point(fx + R + 2, fy - R - 2), Qt.point(fx + R + 2, fy + R + 2), Qt.point(fx - R - 2, fy + R + 2), Qt.point(fx - R - 2, fy - R - 2)];
        return [box, star];
    }

    clip: true

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.ink
            fillRule: ShapePath.OddEvenFill
            strokeColor: "transparent"
            strokeWidth: 0

            PathPolyline {
                path: root.paths[0]
            }
            PathPolyline {
                path: root.paths[1]
            }
        }
    }
}

import QtQuick
import QtQuick.Shapes
import qs.modules.common

Item {
    id: root

    property real level: 0
    property bool horizontal: false
    property real radius: Math.min(width, height) / 2
    property color topColor: AquarioTheme.waterTop
    property color bottomColor: AquarioTheme.waterBottom
    property color lineColor: AquarioTheme.dark ? "#8cffffff" : "#b3ffffff"
    property real meniscus: 1.5
    property real tilt: 0
    property bool smooth: true
    property bool splash: true
    property real amplitude: 0
    property real phase: 0

    readonly property real across: root.horizontal ? root.height : root.width
    readonly property real along: root.horizontal ? root.width : root.height
    readonly property real maxAmplitude: Math.min(AquarioTheme.waveAmplitude, root.along * 0.1)
    readonly property bool canMove: AquarioTheme.moving && root.visible && root.Window.visibility !== Window.Hidden
    property real shown: Math.max(0, Math.min(1, root.level))
    property bool ready: false
    readonly property real surface: root.along * (1 - root.shown)

    Behavior on shown {
        enabled: root.smooth && root.canMove
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutCubic
        }
    }

    onLevelChanged: {
        if (!root.ready || !root.splash || !root.canMove)
            return;
        if (!wave.running || root.amplitude < root.maxAmplitude * 0.4)
            wave.restart();
    }
    onCanMoveChanged: {
        if (!root.canMove && wave.running) {
            wave.stop();
            root.amplitude = 0;
        }
    }
    Component.onCompleted: root.ready = true

    ParallelAnimation {
        id: wave
        NumberAnimation {
            target: root
            property: "amplitude"
            from: root.maxAmplitude
            to: 0
            duration: AquarioTheme.waveDuration
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "phase"
            from: 0
            to: Math.PI * 3
            duration: AquarioTheme.waveDuration
        }
    }

    readonly property var outline: {
        const w = root.across;
        const h = root.along;
        const r = Math.max(0, Math.min(root.radius, w / 2, h / 2));
        if (w <= 0 || h <= 0 || root.shown <= 0.001)
            return { body: [], line: [] };
        const n = Math.max(12, Math.min(72, Math.ceil(w / 1.2)));
        const k = Math.PI * 2.5 / w;
        const amp = root.amplitude;
        const top = [];
        const bottom = [];
        const line = [];
        for (let i = 0; i <= n; ++i) {
            const a = w / 2 - w / 2 * Math.cos(Math.PI * i / n);
            let edge = 0;
            if (a < r)
                edge = r - Math.sqrt(Math.max(0, r * r - (r - a) * (r - a)));
            else if (a > w - r)
                edge = r - Math.sqrt(Math.max(0, r * r - (a - w + r) * (a - w + r)));
            const low = h - edge;
            const t = 2 * a / w - 1;
            const s = root.surface + amp * Math.sin(k * a + root.phase) - root.meniscus * Math.pow(t, 6) - root.tilt * t / 2;
            const y = Math.max(s, edge);
            if (y >= low - 0.05)
                continue;
            top.push(root.map(a, y));
            bottom.unshift(root.map(a, low));
            if (s > edge + 0.4)
                line.push(root.map(a, y));
        }
        if (top.length < 2)
            return { body: [], line: [] };
        const body = top.concat(bottom);
        body.push(top[0]);
        return { body: body, line: line.length > 1 ? line : [] };
    }

    function map(a, y) {
        return root.horizontal ? Qt.point(root.along - y, a) : Qt.point(a, y);
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        visible: root.outline.body.length > 0

        ShapePath {
            strokeWidth: -1
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0
                y1: root.horizontal ? 0 : Math.max(0, root.surface - root.maxAmplitude)
                x2: 0
                y2: root.height
                GradientStop {
                    position: 0
                    color: root.topColor
                }
                GradientStop {
                    position: 1
                    color: root.bottomColor
                }
            }
            PathPolyline {
                path: root.outline.body
            }
        }

        ShapePath {
            strokeWidth: 1.5
            strokeColor: root.lineColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline {
                path: root.outline.line
            }
        }
    }
}

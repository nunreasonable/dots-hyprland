import QtQuick
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property var lines: []
    property string date: ""
    property bool showDate: true
    property real pixelSize: 96
    property int horizontalAlignment: Text.AlignHCenter

    readonly property real slant: Math.tan(8 * Math.PI / 180)
    readonly property real outline: Math.max(3, Math.round(root.pixelSize * 0.045))
    readonly property real drop: Math.max(5, Math.round(root.pixelSize * 0.09))
    readonly property real pad: root.outline + 2
    readonly property real lineHeight: metrics.font.pixelSize > 0 && metrics.font.family !== "" ? metrics.tightBoundingRect("0").height : 0
    readonly property real lineGap: Math.round(root.pixelSize * 0.12)
    readonly property real textWidth: root.lineHeight > 0 ? Math.max(0, ...root.lines.map(line => metrics.tightBoundingRect(line).width)) : 0
    readonly property real textHeight: root.lines.length * root.lineHeight + Math.max(0, root.lines.length - 1) * root.lineGap
    readonly property var paintKey: [root.lines.join("\n"), root.pixelSize, QuadrinhoTheme.paper, QuadrinhoTheme.ink, canvas.width, canvas.height]

    implicitWidth: Math.max(canvas.width, root.showDate ? caption.implicitWidth : 0)
    implicitHeight: canvas.height + (root.showDate ? caption.height + 4 : 0)

    function alignedX(w) {
        if (root.horizontalAlignment === Text.AlignLeft)
            return 0;
        if (root.horizontalAlignment === Text.AlignRight)
            return root.width - w;
        return (root.width - w) / 2;
    }

    onPaintKeyChanged: canvas.requestPaint()

    FontMetrics {
        id: metrics
        font.family: QuadrinhoTheme.sfxFont
        font.pixelSize: root.pixelSize
    }

    Canvas {
        id: canvas
        x: root.alignedX(width)
        width: Math.ceil(root.textWidth + root.slant * root.lineHeight + root.pad * 2 + root.drop)
        height: Math.ceil(root.textHeight + root.pad * 2 + root.drop)
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            if (root.lines.length === 0)
                return;
            ctx.font = `${root.pixelSize}px "${QuadrinhoTheme.sfxFont}"`;
            const k = root.slant;
            const runs = root.lines.map((line, i) => {
                const box = metrics.tightBoundingRect(line);
                const baseline = root.pad + i * (root.lineHeight + root.lineGap) + root.lineHeight;
                const left = root.pad + (root.textWidth - box.width) / 2 - box.x;
                return { text: line, x: left, y: baseline };
            });
            const textPath = (dx, dy) => {
                ctx.beginPath();
                for (const run of runs) {
                    ctx.setTransform(1, 0, -k, 1, k * (run.y + dy), 0);
                    ctx.text(run.text, run.x + dx, run.y + dy);
                }
                ctx.setTransform(1, 0, 0, 1, 0, 0);
            };

            ctx.save();
            textPath(root.drop, root.drop);
            ctx.clip();
            ctx.fillStyle = QuadrinhoTheme.paper;
            ctx.fillRect(0, 0, width, height);
            ctx.fillStyle = QuadrinhoTheme.ink;
            ctx.beginPath();
            const step = 8;
            const r = Math.sqrt(0.6 * step * step / 2 / Math.PI);
            for (let y = 0; y < height + step; y += step) {
                for (let x = 0; x < width + step; x += step) {
                    ctx.moveTo(x + r, y);
                    ctx.arc(x, y, r, 0, Math.PI * 2);
                    ctx.moveTo(x + step / 2 + r, y + step / 2);
                    ctx.arc(x + step / 2, y + step / 2, r, 0, Math.PI * 2);
                }
            }
            ctx.fill();
            ctx.restore();

            ctx.strokeStyle = QuadrinhoTheme.ink;
            ctx.lineJoin = "round";
            ctx.lineWidth = 3;
            textPath(root.drop, root.drop);
            ctx.stroke();

            textPath(0, 0);
            ctx.lineWidth = root.outline * 2;
            ctx.stroke();
            ctx.fillStyle = QuadrinhoTheme.paper;
            ctx.fill();
        }
    }

    QuadrinhoCaption {
        id: caption
        visible: root.showDate && root.date !== ""
        x: root.alignedX(width) + (root.horizontalAlignment === Text.AlignLeft ? root.pad : 0)
        y: canvas.height + 4
        text: root.date
        horizontalPadding: Math.round(root.pixelSize * 0.16)
        verticalPadding: Math.round(root.pixelSize * 0.05)
        font.pixelSize: Math.max(Appearance.font.pixelSize.normal, Math.round(root.pixelSize * 0.19))
    }
}

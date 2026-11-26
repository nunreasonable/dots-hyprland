pragma Singleton
import QtQuick

QtObject {
    id: root

    readonly property list<string> partialBlocks: ["", "▏", "▎", "▍", "▌", "▋", "▊", "▉", "█"]
    readonly property string emptyBlock: "░"
    readonly property string fullBlock: "█"

    function meterText(value, cells) {
        const n = Math.max(0, Math.round(cells));
        if (n <= 0)
            return "";
        const clamped = Math.max(0, Math.min(1, value || 0));
        const total = clamped * n;
        let full = Math.floor(total);
        let partialIndex = Math.round((total - full) * 8);
        if (partialIndex >= 8) {
            partialIndex = 0;
            full = Math.min(n, full + 1);
        }
        const partial = (full < n && partialIndex > 0) ? root.partialBlocks[partialIndex] : "";
        const emptyCount = Math.max(0, n - full - (partial.length > 0 ? 1 : 0));
        return root.fullBlock.repeat(full) + partial + root.emptyBlock.repeat(emptyCount);
    }

    function _rowsFilledBits(filledRows, bitsByRow) {
        let bits = 0;
        for (let row = 4 - filledRows; row <= 3; row++) {
            if (row >= 0)
                bits |= bitsByRow[row];
        }
        return bits;
    }

    function brailleGraph(history, cells) {
        const n = Math.max(0, Math.round(cells));
        if (n <= 0)
            return "";
        const src = (history && history.length > 0) ? history : [0];
        const sampleCount = n * 2;
        const samples = [];
        for (let i = 0; i < sampleCount; i++) {
            const idx = Math.min(src.length - 1, Math.floor(i * src.length / sampleCount));
            samples.push(Math.max(0, Math.min(1, src[idx] || 0)));
        }

        const leftBitsByRow = [0x01, 0x02, 0x04, 0x40];
        const rightBitsByRow = [0x08, 0x10, 0x20, 0x80];

        let out = "";
        for (let c = 0; c < n; c++) {
            const left = samples[c * 2] ?? 0;
            const right = samples[c * 2 + 1] ?? 0;
            const leftRows = Math.round(left * 4);
            const rightRows = Math.round(right * 4);
            const code = 0x2800 | root._rowsFilledBits(leftRows, leftBitsByRow) | root._rowsFilledBits(
                      rightRows, rightBitsByRow);
            out += String.fromCharCode(code);
        }
        return out;
    }
}

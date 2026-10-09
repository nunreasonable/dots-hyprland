import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root
    configEntryName: "visualizer"
    pinnedBottom: true
    showSelectionBorder: false

    readonly property string style: configEntry.style ?? "bars"
    readonly property string colorSource: configEntry.colorSource ?? "theme"
    readonly property real sensitivity: configEntry.sensitivity ?? 1
    readonly property int bandHeight: configEntry.height ?? 260

    readonly property int bandCount: 32
    property var points: GlobalStates.visualizerPoints
    readonly property bool live: MprisController.activePlayer?.isPlaying ?? false

    implicitWidth: 360
    implicitHeight: Math.min(root.bandHeight, 160)

    readonly property var activePlayer: MprisController.activePlayer
    property var artUrl: root.colorSource === "cover" ? (activePlayer?.trackArtUrl ?? "") : ""
    readonly property bool artIsLocal: Platform.isWindows && String(root.artUrl).startsWith("file:")
    property string artFilePath: `${Directories.coverArt}/${Qt.md5(root.artUrl)}`
    property bool artDownloaded: false
    property string resolvedArtPath: root.artIsLocal ? root.artUrl : (root.artDownloaded ? (Platform.isWindows ? `file:///${artFilePath}` : Qt.resolvedUrl(artFilePath)) : "")

    onArtUrlChanged: {
        if (!root.artUrl) {
            root.artDownloaded = false;
            return;
        }
        if (root.artIsLocal) {
            root.artDownloaded = true;
            return;
        }
        coverDownloader.targetFile = root.artUrl;
        coverDownloader.artFilePath = root.artFilePath;
        root.artDownloaded = false;
        if (Platform.isWindows && WindowsNative.fsUtils?.classify(root.artFilePath) === "file") {
            root.artDownloaded = true;
            return;
        }
        coverDownloader.running = true;
    }

    Process {
        id: coverDownloader
        property string targetFile: root.artUrl
        property string artFilePath: root.artFilePath
        command: Platform.isWindows ? ["curl", "-4", "-sSL", targetFile, "-o", artFilePath] : ["bash", "-c", `[ -f ${artFilePath} ] || curl -4 -sSL '${targetFile}' -o '${artFilePath}'`]
        onExited: (exitCode, exitStatus) => {
            root.artDownloaded = !Platform.isWindows || exitCode === 0;
        }
    }

    ColorQuantizer {
        id: coverQuantizer
        source: root.colorSource === "cover" ? root.resolvedArtPath : ""
        depth: 0
        rescaleSize: 1
    }

    readonly property color barColor: (root.colorSource === "cover" && coverQuantizer.colors.length > 0) ? coverQuantizer.colors[0] : Appearance.colors.colPrimary

    property var levels: []

    function recompute() {
        const raw = root.points;
        const n = root.bandCount;
        let result = new Array(n).fill(0);
        if (raw && raw.length > 0 && root.live) {
            const bucket = raw.length / n;
            for (let i = 0; i < n; i++) {
                const start = Math.floor(i * bucket);
                const end = Math.max(start + 1, Math.floor((i + 1) * bucket));
                let sum = 0;
                let count = 0;
                for (let j = start; j < end && j < raw.length; j++) {
                    sum += raw[j] ?? 0;
                    count++;
                }
                result[i] = count > 0 ? (sum / count) : 0;
            }
        }
        const prev = root.levels.length === n ? root.levels : new Array(n).fill(0);
        const smoothed = new Array(n);
        for (let i = 0; i < n; i++) {
            const target = Math.max(0, Math.min(1, (result[i] / 1000) * root.sensitivity));
            // Fast attack, slower release so bars don't look too jittery.
            smoothed[i] = target > prev[i] ? target : prev[i] * 0.82 + target * 0.18;
        }
        root.levels = smoothed;
        canvas.requestPaint();
    }

    onPointsChanged: root.recompute()
    onLiveChanged: root.recompute()

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const levels = root.levels;
            const n = levels.length;
            if (n === 0)
                return;

            const gap = 3;
            const barWidth = Math.max(1, (width - gap * (n - 1)) / n);
            const col = root.barColor;
            ctx.fillStyle = Qt.rgba(col.r, col.g, col.b, 0.9);

            for (let i = 0; i < n; i++) {
                const h = Math.max(2, levels[i] * height);
                const x = i * (barWidth + gap);
                const y = height - h;
                const r = Math.min(barWidth / 2, 4);
                ctx.beginPath();
                ctx.moveTo(x, y + r);
                ctx.arcTo(x, y, x + r, y, r);
                ctx.lineTo(x + barWidth - r, y);
                ctx.arcTo(x + barWidth, y, x + barWidth, y + r, r);
                ctx.lineTo(x + barWidth, height);
                ctx.lineTo(x, height);
                ctx.closePath();
                ctx.fill();
            }
        }
    }
}

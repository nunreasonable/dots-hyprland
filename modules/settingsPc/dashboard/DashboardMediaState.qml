import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions

Item {
    id: root
    visible: false

    property var player: MprisController.activePlayer
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string artUrl: player?.trackArtUrl ?? ""
    readonly property bool artIsLocal: Platform.isWindows && artUrl.startsWith("file:")
    readonly property string artFilePath: `${Directories.coverArt}/${Qt.md5(artUrl)}`
    property bool downloaded: false
    readonly property string downloadedArtFilePath: artIsLocal ? artUrl : (downloaded ? FileUtils.folderUrl(artFilePath) : "")
    readonly property string trackKey: `${player?.uniqueId ?? ""}|${player?.trackTitle ?? ""}|${player?.trackArtist ?? ""}`

    property string displayedArtFilePath: ""
    property real displayedArtWidth: 0
    property string displayedTrackKey: ""

    function considerArt(path, width) {
        if (root.trackKey === root.displayedTrackKey && root.displayedArtFilePath !== "" && width < root.displayedArtWidth * 0.8)
            return;
        root.displayedArtFilePath = path;
        root.displayedArtWidth = width;
        root.displayedTrackKey = root.trackKey;
    }

    onTrackKeyChanged: {
        if (root.trackKey === root.displayedTrackKey)
            return;
        root.displayedArtFilePath = "";
        root.displayedArtWidth = 0;
        sameArtTimer.restart();
    }

    onDownloadedArtFilePathChanged: {
        if (root.downloadedArtFilePath === "")
            sameArtTimer.stop();
    }

    Timer {
        id: sameArtTimer
        interval: 500
        onTriggered: {
            if (root.displayedArtFilePath === "" && root.downloadedArtFilePath !== "" && artProbe.status === Image.Ready)
                root.considerArt(artProbe.source.toString(), 0);
        }
    }

    Image {
        id: artProbe
        visible: false
        asynchronous: true
        cache: false
        source: root.downloadedArtFilePath
        onStatusChanged: {
            if (status === Image.Ready && implicitWidth > 0)
                root.considerArt(source.toString(), implicitWidth);
        }
    }

    readonly property color artDominantColor: ColorUtils.mix(
        quantizer.colors[0] ?? Appearance.colors.colPrimary,
        Appearance.colors.colPrimaryContainer,
        0.8
    )
    property QtObject blendedColors: AdaptedMaterialScheme {
        color: root.artDominantColor
    }

    function refreshArt() {
        if (root.artUrl === "") {
            root.downloaded = false;
            return;
        }
        if (root.artIsLocal) {
            root.downloaded = true;
            return;
        }
        if (downloader.running) {
            downloader.rerun = true;
            return;
        }
        downloader.targetFile = root.artUrl;
        downloader.filePath = root.artFilePath;
        root.downloaded = false;
        if (Platform.isWindows && WindowsNative.fsUtils?.classify(root.artFilePath) === "file") {
            root.downloaded = true;
            return;
        }
        downloader.running = true;
    }

    onArtUrlChanged: refreshArt()
    Component.onCompleted: refreshArt()

    Timer {
        running: root.playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: root.player?.positionChanged()
    }

    Process {
        id: downloader
        property string targetFile: ""
        property string filePath: ""
        property bool rerun: false
        readonly property string partTag: Math.random().toString(36).slice(2, 10)
        workingDirectory: Platform.isWindows ? FileUtils.parentDirectory(filePath) : ""
        command: Platform.isWindows
            ? ["curl", "-4", "-sSL", "-o", WindowsNative.downloadName(filePath, partTag), "--url", targetFile]
            : ["bash", "-c", '[ -f "$2" ] || { curl -4 -sSL -o "$2.part" --url "$1" && mv "$2.part" "$2"; }', "art", targetFile, filePath]
        onExited: (exitCode, exitStatus) => {
            const ok = Platform.isWindows ? WindowsNative.finishDownload(downloader.filePath, downloader.partTag, exitCode === 0) : exitCode === 0;
            if (downloader.rerun || downloader.filePath !== root.artFilePath) {
                downloader.rerun = false;
                root.refreshArt();
                return;
            }
            root.downloaded = ok;
        }
    }

    ColorQuantizer {
        id: quantizer
        source: root.displayedArtFilePath
        depth: 0
        rescaleSize: 1
    }
}

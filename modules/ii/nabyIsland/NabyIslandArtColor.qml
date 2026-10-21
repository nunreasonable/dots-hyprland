import qs.services
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string artUrl: ""
    readonly property bool artIsLocal: root.artUrl.startsWith("file:")
    readonly property string artFilePath: `${Directories.coverArt}/${Qt.md5(root.artUrl)}`
    property bool downloaded: false
    readonly property string localArt: {
        if (root.artUrl.length === 0)
            return "";
        if (root.artIsLocal)
            return root.artUrl;
        if (!root.downloaded)
            return "";
        return Platform.isWindows ? `file:///${root.artFilePath}` : Qt.resolvedUrl(root.artFilePath);
    }
    readonly property bool ready: root.localArt.length > 0 && quantizer.colors.length > 0
    readonly property color dominant: root.ready ? quantizer.colors[0] : "transparent"
    readonly property color glow: {
        if (!root.ready)
            return "transparent";
        const c = root.dominant;
        const saturation = c.hslSaturation < 0.08 ? c.hslSaturation : Math.max(0.45, c.hslSaturation);
        const lightness = Math.max(0.42, Math.min(0.6, c.hslLightness));
        return Qt.hsla(Math.max(0, c.hslHue), saturation, lightness, 1);
    }

    onArtFilePathChanged: root.fetch()
    Component.onCompleted: root.fetch()

    function fetch() {
        root.downloaded = false;
        if (root.artUrl.length === 0 || root.artIsLocal)
            return;
        if (Platform.isWindows && WindowsNative.fsUtils?.classify(root.artFilePath) === "file") {
            root.downloaded = true;
            return;
        }
        if (downloader.running)
            return;
        downloader.targetFile = root.artUrl;
        downloader.outputFile = root.artFilePath;
        downloader.running = true;
    }

    Process {
        id: downloader
        property string targetFile: ""
        property string outputFile: ""
        command: Platform.isWindows
            ? ["curl", "-4", "-sSL", "--create-dirs", "-o", downloader.outputFile, "--url", downloader.targetFile]
            : ["bash", "-c", 'mkdir -p "$(dirname "$2")"; [ -f "$2" ] || curl -4 -sSL -o "$2" --url "$1"', "art", downloader.targetFile, downloader.outputFile]
        onExited: (exitCode, exitStatus) => {
            if (downloader.outputFile === root.artFilePath)
                root.downloaded = exitCode === 0;
            else
                root.fetch();
        }
    }

    ColorQuantizer {
        id: quantizer
        source: root.localArt
        depth: 0
        rescaleSize: 1
    }
}

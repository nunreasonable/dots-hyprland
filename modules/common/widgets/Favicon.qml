import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell.Io
import Quickshell.Widgets

IconImage {
    id: root
    property string url
    property string displayText

    property real size: 32
    property string downloadUserAgent: Config.options?.networking.userAgent ?? ""
    property string faviconDownloadPath: Directories.favicons
    property string domainName: url.includes("vertexaisearch") ? displayText : StringUtils.getDomain(url)
    property string faviconUrl: `https://www.google.com/s2/favicons?domain=${domainName}&sz=32`
    property string fileName: `${domainName}.ico`
    property string faviconFilePath: `${faviconDownloadPath}/${fileName}`
    property string urlToLoad

    Process {
        id: faviconDownloadProcess
        running: false
        // curl.exe ships with Windows itself; only the "[ -f ]" existence test needs bash,
        // and that's checked beforehand via WindowsNative.fsUtils instead (see startDownload).
        command: Platform.isWindows
            ? ["cmd", "/c", `curl -s "${root.faviconUrl}" -o "${root.faviconFilePath}" -L -H "User-Agent: ${downloadUserAgent}"`]
            : ["bash", "-c", `[ -f ${faviconFilePath} ] || curl -s '${root.faviconUrl}' -o '${faviconFilePath}' -L -H 'User-Agent: ${downloadUserAgent}'`]
        onExited: (exitCode, exitStatus) => {
            root.urlToLoad = root.faviconFilePath
        }
    }

    function startDownload() {
        if (Platform.isWindows) {
            if (!WindowsNative.fsUtils) {
                Qt.callLater(() => root.startDownload());
                return;
            }
            if (WindowsNative.fsUtils.classify(root.faviconFilePath) === "file") {
                root.urlToLoad = root.faviconFilePath;
                return;
            }
        }
        faviconDownloadProcess.running = true;
    }

    Component.onCompleted: {
        root.startDownload();
    }

    source: Qt.resolvedUrl(root.urlToLoad)
    implicitSize: root.size

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.implicitSize
            height: root.implicitSize
            radius: Appearance.rounding.full
        }
    }
}
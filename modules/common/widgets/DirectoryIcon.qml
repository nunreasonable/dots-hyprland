import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

// From https://github.com/caelestia-dots/shell with modifications.
// License: GPLv3

StyledImage {
    id: root
    required property var fileModelData
    asynchronous: true
    fillMode: Image.PreserveAspectFit

    source: {
        if (Platform.isWindows) return root.windowsSource();

        if (!fileModelData.fileIsDir)
            return Quickshell.iconPath("application-x-zerosize");

        if ([Directories.documents, Directories.downloads, Directories.music, Directories.pictures, Directories.videos].some(dir => FileUtils.trimFileProtocol(dir) === fileModelData.filePath))
            return Quickshell.iconPath(`folder-${fileModelData.fileName.toLowerCase()}`);

        return Quickshell.iconPath("inode-directory");
    }

    function windowsSource() {
        if (!fileModelData.fileIsDir) {
            return Images.isValidImageByName(fileModelData.fileName) ? fileModelData.fileUrl : Quickshell.iconPath("text-x-generic", "image-missing");
        }
        const special = [[Directories.documents, "folder-documents"], [Directories.downloads, "folder-download"],
            [Directories.music, "folder-music"], [Directories.pictures, "folder-pictures"], [Directories.videos, "folder-videos"]]
            .find(([dir, icon]) => FileUtils.trimFileProtocol(dir).toLowerCase() === fileModelData.filePath.toLowerCase());
        return Quickshell.iconPath(special ? special[1] : "inode-directory", "inode-directory");
    }

    onStatusChanged: {
        if (status === Image.Error)
            source = Quickshell.iconPath(Platform.isWindows ? "image-missing" : "error");
    }

    Process {
        running: !fileModelData.fileIsDir && !Platform.isWindows
        command: ["file", "--mime", "-b", fileModelData.filePath]
        stdout: StdioCollector {
            onStreamFinished: {
                const mime = text.split(";")[0].replace("/", "-");
                root.source = Images.validImageTypes.some(t => mime === `image-${t}`) ? fileModelData.fileUrl : Quickshell.iconPath(mime, "image-missing");
            }
        }
    }
}

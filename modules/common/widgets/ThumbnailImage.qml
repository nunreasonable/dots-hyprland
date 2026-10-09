import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

/**
 * Thumbnail image. It currently generates to the right place at the right size, but does not handle metadata/maintenance on modification.
 * See Freedesktop's spec: https://specifications.freedesktop.org/thumbnail-spec/thumbnail-spec-latest.html
 */
StyledImage {
    id: root

    property bool generateThumbnail: true
    required property string sourcePath
    property string thumbnailSizeName: {
        const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
        return Images.thumbnailSizeNameForDimensions(width * dpr, height * dpr);
    }
    property string thumbnailPath: Images.thumbnailPathFor(sourcePath, thumbnailSizeName)
    source: thumbnailPath

    asynchronous: true
    smooth: true
    mipmap: false

    opacity: status === Image.Ready ? 1 : 0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    Connections {
        target: Platform.isWindows ? WindowsNative : null
        function onReadyChanged() { if (WindowsNative.ready) root.sourceSizeChanged() }
    }
    onSourceSizeChanged: {
        if (!root.generateThumbnail) return;
        if (Platform.isWindows) {
            if (!WindowsNative.thumbnailer) return;
            const maxSize = Images.thumbnailSizes[root.thumbnailSizeName];
            WindowsNative.thumbnailer.generate(
                FileUtils.trimFileProtocol(root.sourcePath),
                FileUtils.trimFileProtocol(root.thumbnailPath),
                maxSize
            );
            return;
        }
        thumbnailGeneration.running = false;
        thumbnailGeneration.running = true;
    }
    Connections {
        target: WindowsNative.thumbnailer
        function onFinished(sourcePath, outputPath, ok) {
            if (!ok || outputPath !== FileUtils.trimFileProtocol(root.thumbnailPath)) return;
            root.source = "";
            root.source = root.thumbnailPath;
        }
    }
    Process {
        id: thumbnailGeneration
        command: {
            const maxSize = Images.thumbnailSizes[root.thumbnailSizeName];
            return ["bash", "-c",
                `[ -f '${FileUtils.trimFileProtocol(root.thumbnailPath)}' ] && exit 0 || { magick '${root.sourcePath}' -resize ${maxSize}x${maxSize} '${FileUtils.trimFileProtocol(root.thumbnailPath)}' && exit 1; }`
            ]
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 1) { // Force reload if thumbnail had to be generated
                root.source = "";
                root.source = root.thumbnailPath; // Force reload
            }
        }
    }
}

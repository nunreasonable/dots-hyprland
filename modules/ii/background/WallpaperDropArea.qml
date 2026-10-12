import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF

DropArea {
    id: root
    keys: ["text/uri-list"]

    required property var screen
    property var currentUrls: []
    readonly property var wallpaperPattern: Platform.isWindows
        ? /\.(png|jpe?g|webp|bmp|gif|mp4|webm|mkv|avi|mov)$/i
        : /\.(png|jpe?g|webp|bmp|gif)$/i

    function pathOf(url) {
        return CF.FileUtils.trimFileProtocol(decodeURIComponent(url.toString()));
    }

    function isWallpaper(url) {
        return root.wallpaperPattern.test(root.pathOf(url));
    }

    onEntered: drag => {
        drag.accepted = drag.hasUrls;
        root.currentUrls = drag.hasUrls ? drag.urls : [];
    }

    onExited: {
        root.currentUrls = [];
    }

    onDropped: drop => {
        if (!drop.hasUrls) {
            drop.accepted = false;
            root.currentUrls = [];
            return;
        }
        if (drop.urls.length === 1 && root.isWallpaper(drop.urls[0])) {
            Wallpapers.apply(root.pathOf(drop.urls[0]), Appearance.m3colors.darkmode);
        } else {
            DropShelf.show(drop.urls, root.screen, drop.x, drop.y);
        }
        drop.accept();
        root.currentUrls = [];
    }

    Rectangle {
        id: dropOverlay
        anchors.fill: parent
        visible: root.containsDrag
        color: CF.ColorUtils.transparentize(Appearance.colors.colPrimary, 0.6)

        readonly property bool isSingleWallpaper: root.currentUrls.length === 1 && root.isWallpaper(root.currentUrls[0])

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8
            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: dropOverlay.isSingleWallpaper ? "wallpaper" : "stacks"
                iconSize: 64
                color: Appearance.colors.colOnPrimary
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: dropOverlay.isSingleWallpaper
                    ? Translation.tr("Drop to set as wallpaper")
                    : Translation.tr("Drop to add to shelf")
                font.pixelSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnPrimary
            }
        }
    }
}

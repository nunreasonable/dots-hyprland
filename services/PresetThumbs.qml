pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    readonly property string thumbsDir: Directories.presetLocalThumbsPath

    property var queued: ({})
    property int attempts: 0
    property bool _winDirReady: false

    readonly property var thumbSet: {
        const names = new Set();
        for (let i = 0; i < thumbsModel.count; i++)
            names.add(thumbsModel.get(i, "fileName"));
        return names;
    }

    function shQuote(str) {
        return "'" + String(str).replace(/'/g, "'\"'\"'") + "'";
    }

    function cleanPath(source) {
        return FileUtils.trimFileProtocol(String(source ?? ""));
    }

    function keyFor(source) {
        return Qt.md5(root.cleanPath(source));
    }

    function thumbFor(source) {
        const clean = root.cleanPath(source);
        if (clean === "") return "";
        const name = `${root.keyFor(clean)}.jpg`;
        return root.thumbSet.has(name) ? `${root.thumbsDir}/${name}` : "";
    }

    function request(source) {
        const clean = root.cleanPath(source);
        if (clean === "" || clean.startsWith("http")) return;
        if (root.thumbSet.has(`${root.keyFor(clean)}.jpg`)) return;
        if (root.queued[clean]) return;
        root.queued[clean] = true;
        if (Platform.isWindows) {
            Qt.callLater(root.generate);
            return;
        }
        batchTimer.restart();
    }

    function refreshThumbs() {
        const current = thumbsModel.folder;
        thumbsModel.folder = "";
        thumbsModel.folder = current;
    }

    function _ensureWindowsDir() {
        if (root._winDirReady) return;
        if (!WindowsNative.fsUtils) return;
        WindowsNative.fsUtils.makePath(root.thumbsDir);
        root._winDirReady = true;
        thumbsModel.folder = FileUtils.folderUrl(root.thumbsDir);
    }

    function generate() {
        const paths = Object.keys(root.queued);
        if (paths.length === 0) {
            root.attempts = 0;
            return;
        }

        if (Platform.isWindows) {
            if (!WindowsNative.thumbnailer) return;
            root._ensureWindowsDir();
            root.queued = ({});
            for (const path of paths) {
                const outputPath = `${root.thumbsDir}/${root.keyFor(path)}.jpg`;
                WindowsNative.thumbnailer.generate(path, outputPath, 720);
            }
            return;
        }

        if (thumbProc.running) return;
        root.queued = ({});
        const dir = root.thumbsDir;
        let script = `D=${root.shQuote(dir)}; gen() { out="$D/$1.jpg"; [ -s "$out" ] && [ "$out" -nt "$2" ] && return; if magick "$2[0]" -auto-orient -resize 720x -quality 82 "jpg:$D/.$1.part" && mv -f "$D/.$1.part" "$out"; then echo "THUMB ok $1"; else echo "THUMB fail $1"; fi; rm -f "$D/.$1.part"; }; `;
        paths.forEach((path, i) => {
            script += `gen ${root.keyFor(path)} ${root.shQuote(path)} & `;
            if (i % 4 === 3) script += "wait; ";
        });
        script += "wait";
        thumbProc.command = ["bash", "-c", script];
        thumbProc.running = true;
    }

    Component.onCompleted: {
        if (Platform.isWindows)
            root._ensureWindowsDir();
    }

    Connections {
        target: Platform.isWindows ? WindowsNative : null
        function onReadyChanged() {
            root._ensureWindowsDir();
            root.generate();
        }
    }

    Connections {
        target: Platform.isWindows ? WindowsNative.thumbnailer : null
        function onFinished(sourcePath, outputPath, ok) {
            if (ok) root.refreshThumbs();
        }
    }

    Timer {
        id: batchTimer
        interval: 120
        onTriggered: root.generate()
    }

    FolderListModel {
        id: thumbsModel
        folder: ""
        showDirs: false
        nameFilters: ["*.jpg"]
    }

    Process {
        id: prepareProc
        running: !Platform.isWindows
        command: ["bash", "-c", `mkdir -p ${root.shQuote(root.thumbsDir)} && for f in ${root.shQuote(root.thumbsDir)}/*.jpg; do [ -e "$f" ] || continue; magick identify -quiet "$f" >/dev/null 2>&1 || rm -f "$f"; done; rm -f ${root.shQuote(root.thumbsDir)}/.*.part`]
        onExited: thumbsModel.folder = Qt.resolvedUrl(root.thumbsDir)
    }

    Process {
        id: thumbProc
        onExited: Qt.callLater(root.generate)
    }
}

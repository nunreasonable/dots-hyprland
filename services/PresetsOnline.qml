pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common

Singleton {
    id: root

    readonly property string curlBin: Platform.isWindows ? "curl.exe" : "curl"

    readonly property var sources: [
        { repo: "Blapples/wallpapers", branch: "main", prefix: "" },
        { repo: "pctrade/end4-pCpresets", branch: "main", prefix: "pctrade--" }
    ]

    property var entries: []
    property bool loading: false
    property string error: ""
    property string downloadingName: ""

    property var _collected: []
    property int _sourceIndex: 0
    property int _failedSources: 0

    readonly property var pending: {
        const downloaded = new Set();
        for (let i = 0; i < Presets.onlineFolderModel.count; i++)
            downloaded.add(Presets.onlineFolderModel.get(i, "fileName").replace(".json", ""));
        return root.entries.filter(entry => !downloaded.has(entry.name));
    }

    function rawUrl(path, repo, branch) {
        return `https://raw.githubusercontent.com/${repo}/${branch}/${path.split("/").map(encodeURIComponent).join("/")}`;
    }

    function refresh() {
        if (root.loading)
            return;
        root.loading = true;
        root.error = "";
        root._collected = [];
        root._failedSources = 0;
        root._sourceIndex = 0;
        root._listNext();
    }

    function _listNext() {
        const src = root.sources[root._sourceIndex];
        listProc.source = src;
        listProc.command = [root.curlBin, "-sSL",
            "-H", "Accept: application/vnd.github+json",
            "-H", "User-Agent: ii-windows-quickshell",
            `https://api.github.com/repos/${src.repo}/git/trees/${src.branch}?recursive=1`];
        listProc.running = true;
    }

    Process {
        id: listProc
        property var source: null
        stdout: StdioCollector { id: listCollector }
        onExited: code => {
            const src = listProc.source;
            try {
                const data = JSON.parse(listCollector.text);
                if (!Array.isArray(data.tree))
                    throw new Error("unexpected response");

                const prefix = "presets/";
                const imageExt = /\.(png|jpe?g|webp)$/i;
                const groups = {};

                for (const entry of data.tree) {
                    if (entry.type !== "blob" || !entry.path.startsWith(prefix))
                        continue;
                    const rel = entry.path.slice(prefix.length);
                    const slashIdx = rel.indexOf("/");
                    if (slashIdx === -1)
                        continue;
                    const folder = rel.slice(0, slashIdx);
                    const filename = rel.slice(slashIdx + 1);
                    if (filename.includes("/"))
                        continue;
                    if (!groups[folder])
                        groups[folder] = { images: [], jsonPath: "" };
                    if (/\.json$/i.test(filename) && filename.toLowerCase() !== "meta.json")
                        groups[folder].jsonPath = entry.path;
                    else if (imageExt.test(filename))
                        groups[folder].images.push(entry.path);
                }

                const presets = [];
                for (const folder in groups) {
                    const g = groups[folder];
                    if (!g.jsonPath || g.images.length === 0)
                        continue;
                    const main = g.images.find(path => /preview\.png$/i.test(path))
                        || g.images.find(path => !/pfp|avatar|banner/i.test(path))
                        || g.images[0];
                    presets.push({
                        name: src.prefix + folder,
                        title: folder.replace(/[-_]+/g, " ").replace(/\b\w/g, c => c.toUpperCase()),
                        author: src.repo.split("/")[0],
                        repo: src.repo,
                        jsonUrl: root.rawUrl(g.jsonPath, src.repo, src.branch),
                        screenshot: root.rawUrl(main, src.repo, src.branch)
                    });
                }
                root._collected = root._collected.concat(presets);
            } catch (e) {
                root._failedSources++;
            }
            root._sourceIndex++;
            if (root._sourceIndex < root.sources.length)
                Qt.callLater(root._listNext);
            else
                root._finishListing();
        }
    }

    function _finishListing() {
        root.loading = false;
        if (root._collected.length === 0 && root._failedSources > 0) {
            root.entries = [];
            root.error = Translation.tr("Failed to load online presets");
            return;
        }
        const presets = root._collected.slice();
        presets.sort((a, b) => a.title.localeCompare(b.title));
        root.entries = presets;
    }

    function download(entry) {
        if (root.downloadingName !== "")
            return;
        root.error = "";
        root.downloadingName = entry.name;
        downloadProc.entryName = entry.name;
        downloadProc.command = [root.curlBin, "-sSL", entry.jsonUrl];
        downloadProc.running = true;
    }

    Process {
        id: downloadProc
        property string entryName: ""
        stdout: StdioCollector { id: downloadCollector }
        onExited: code => {
            root.downloadingName = "";
            if (code !== 0 || downloadCollector.text.trim().length === 0) {
                root.error = Translation.tr("Failed to download preset");
                return;
            }
            try {
                JSON.parse(downloadCollector.text);
            } catch (e) {
                root.error = Translation.tr("Failed to download preset");
                return;
            }
            onlineWriteFile.presetName = downloadProc.entryName;
            onlineWriteFile.setText(downloadCollector.text);
            Presets.refreshOnline();
        }
    }

    FileView {
        id: onlineWriteFile
        property string presetName: ""
        path: presetName.length > 0 ? `${Directories.onlinePresetsPath}/${presetName}.json` : ""
        blockLoading: true
        printErrors: false
    }
}

pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    readonly property string curlBin: Platform.isWindows ? "curl.exe" : "curl"

    readonly property string thumbsDir: Directories.presetOnlineThumbsPath
    readonly property string indexPath: Directories.presetsOnlineIndexPath
    readonly property real staleAfterMs: 6 * 60 * 60 * 1000

    property var entries: []
    property real lastFetched: 0
    readonly property bool stale: Date.now() - lastFetched > staleAfterMs
    property string error: ""
    property bool loading: false
    property string downloadingName: ""
    property int previewLimit: 3
    property var activeEntry: null
    property var collected: []
    property var listed: []
    property int sourceIndex: 0
    property int failedSources: 0
    property bool _winDirReady: false

    readonly property int indexVersion: 4

    readonly property var sources: [
        { repo: "pctrade/end4-pCpresets", branch: "main", prefix: "pctrade--", sanitize: true, rootWallpapers: false, authorsBranch: "gallery-data" },
        { repo: "Blapples/wallpapers", branch: "main", prefix: "", sanitize: false, rootWallpapers: true }
    ]

    readonly property var shareAllowedRoots: ["appearance", "background", "bar", "calendar", "crosshair", "dock", "interactions", "launcher", "light", "lock", "media", "notifications", "osd", "osk", "overlay", "overview", "panelFamily", "profile", "regionSelector", "resources", "settings", "sidebar", "tray", "wallpaperSelector", "windows", "hyprland"]
    readonly property var hyprlandAllowedKeys: ["decoration", "gaps", "animations", "general"]

    readonly property var thumbSet: {
        const names = new Set();
        for (let i = 0; i < thumbsModel.count; i++)
            names.add(thumbsModel.get(i, "fileName"));
        return names;
    }

    function thumbFor(entry) {
        return root.thumbSet.has(entry.name + ".jpg") ? `${root.thumbsDir}/${entry.name}.jpg` : "";
    }

    property int thumbAttempts: 0

    function refreshThumbs() {
        const current = thumbsModel.folder;
        thumbsModel.folder = "";
        thumbsModel.folder = current;
    }

    function generateThumbs() {
        const missing = root.entries.filter(e => !root.thumbSet.has(e.name + ".jpg"));
        if (missing.length === 0) {
            root.thumbAttempts = 0;
            return;
        }

        if (Platform.isWindows) {
            if (!WindowsNative.thumbnailer) return;
            root._ensureWindowsDirs();
            root._winThumbQueue = missing.slice();
            root._downloadNextThumbWindows();
            return;
        }

        if (thumbProc.running) return;
        const dir = root.thumbsDir;
        let script = `D=${root.shQuote(dir)}; gen() { out="$D/$1.jpg"; [ -s "$out" ] && return; if curl -sSL -m 40 -o "$D/.$1.src" "$2" && magick "$D/.$1.src" -auto-orient -resize 720x -quality 82 "jpg:$D/.$1.part" && mv -f "$D/.$1.part" "$out"; then echo "THUMB ok $1"; else echo "THUMB fail $1"; fi; rm -f "$D/.$1.src" "$D/.$1.part"; }; `;
        missing.forEach((e, i) => {
            script += `gen ${root.shQuote(e.name)} ${root.shQuote(e.screenshot)} & `;
            if (i % 4 === 3) script += "wait; ";
        });
        script += "wait";
        thumbProc.command = ["bash", "-c", script];
        thumbProc.running = true;
    }

    property var _winThumbQueue: []

    function _downloadNextThumbWindows() {
        if (root._winThumbQueue.length === 0) return;
        const entry = root._winThumbQueue.shift();
        winThumbSrcProc.entryName = entry.name;
        winThumbSrcProc.srcPath = `${root.thumbsDir}/.${entry.name}.src`;
        winThumbSrcProc.command = [root.curlBin, "-sSL", "-m", "40", "-o", winThumbSrcProc.srcPath, entry.screenshot];
        winThumbSrcProc.running = true;
    }

    Process {
        id: winThumbSrcProc
        property string entryName: ""
        property string srcPath: ""
        onExited: code => {
            if (code === 0 && WindowsNative.thumbnailer) {
                WindowsNative.thumbnailer.generate(winThumbSrcProc.srcPath, `${root.thumbsDir}/${winThumbSrcProc.entryName}.jpg`, 720);
            }
            Qt.callLater(root._downloadNextThumbWindows);
        }
    }

    Connections {
        target: Platform.isWindows ? WindowsNative.thumbnailer : null
        function onFinished(sourcePath, outputPath, ok) {
            if (!sourcePath.endsWith(".src")) return;
            if (ok) root.refreshThumbs();
            WindowsNative.fsUtils?.removeFile(sourcePath);
        }
    }

    function ensureFresh() {
        if (root.loading) return;
        if (root.entries.length === 0 || root.stale) root.refresh();
        else root.generateThumbs();
    }

    FolderListModel {
        id: thumbsModel
        folder: ""
        showDirs: false
        nameFilters: ["*.jpg"]
    }

    FileView {
        id: indexFile
        path: root.indexPath
        printErrors: false
        onLoaded: {
            try {
                const saved = JSON.parse(indexFile.text());
                if (saved.version === root.indexVersion && Array.isArray(saved.entries)) {
                    root.entries = saved.entries;
                    root.lastFetched = saved.time ?? 0;
                }
            } catch (e) {}
        }
    }

    function _ensureWindowsDirs() {
        if (root._winDirReady) return;
        if (!WindowsNative.fsUtils) return;
        WindowsNative.fsUtils.makePath(root.thumbsDir);
        root._winDirReady = true;
        thumbsModel.folder = FileUtils.folderUrl(root.thumbsDir);
    }

    Component.onCompleted: {
        if (Platform.isWindows) {
            root._ensureWindowsDirs();
        }
    }

    Connections {
        target: Platform.isWindows ? WindowsNative : null
        function onReadyChanged() {
            root._ensureWindowsDirs();
        }
    }

    Process {
        id: prepareProc
        running: !Platform.isWindows
        command: ["bash", "-c", `mkdir -p ${root.shQuote(root.thumbsDir)} && for f in ${root.shQuote(root.thumbsDir)}/*.jpg; do [ -e "$f" ] || continue; magick identify -quiet "$f" >/dev/null 2>&1 || rm -f "$f"; done; rm -f ${root.shQuote(root.thumbsDir)}/.*.part ${root.shQuote(root.thumbsDir)}/.*.src ${root.shQuote(root.thumbsDir)}/.*.tmp`]
        onExited: {
            thumbsModel.folder = Qt.resolvedUrl(root.thumbsDir);
            root.generateThumbs();
        }
    }

    Process {
        id: thumbProc
        onExited: code => {
            root.thumbAttempts++;
            if (root.thumbAttempts < 3) Qt.callLater(root.generateThumbs);
        }
    }

    readonly property var pending: {
        const downloaded = new Set();
        for (let i = 0; i < Presets.onlineFolderModel.count; i++)
            downloaded.add(Presets.onlineFolderModel.get(i, "fileName").replace(".json", ""));
        return root.entries.filter(p => !downloaded.has(p.name));
    }

    function refresh() {
        root.loading = true;
        root.error = "";
        root.collected = [];
        root.failedSources = 0;
        root.sourceIndex = 0;
        listProc.running = false;
        root.listNext();
    }

    function listNext() {
        const src = root.sources[root.sourceIndex];
        listProc.source = src;
        listProc.command = [root.curlBin, "-sSL", "-w", "\nHTTP_STATUS:%{http_code}",
            "-H", "Accept: application/vnd.github+json",
            "-H", "User-Agent: ii-windows-quickshell",
            `https://api.github.com/repos/${src.repo}/git/trees/${src.branch}?recursive=1`];
        listProc.running = true;
    }

    function finishListing() {
        root.loading = false;
        if (root.collected.length === 0 && root.failedSources > 0) {
            root.entries = [];
            root.error = Translation.tr("Failed to load online presets");
            return;
        }
        const presets = root.collected.slice();
        presets.sort((a, b) => a.title.localeCompare(b.title));
        root.listed = presets;
        const src = root.sources.find(item => item.authorsBranch);
        if (!src) {
            root.publishListing({});
            return;
        }
        authorsProc.source = src;
        authorsProc.command = [root.curlBin, "-sSL", "-m", "15", "-w", "\nHTTP_STATUS:%{http_code}",
            `https://raw.githubusercontent.com/${src.repo}/${src.authorsBranch}/index.json`];
        authorsProc.running = true;
    }

    function publishListing(authors) {
        const presets = root.listed.map(entry => {
            const known = authors[entry.name];
            if (known) return Object.assign({}, entry, { author: known });
            const hasIndex = root.sources.some(src => src.authorsBranch && src.repo === entry.repo);
            return hasIndex ? Object.assign({}, entry, { author: "" }) : entry;
        });
        root.previewLimit = 3;
        root.entries = presets;
        root.lastFetched = Date.now();
        indexFile.setText(JSON.stringify({ version: root.indexVersion, time: root.lastFetched, entries: presets }));
        root.generateThumbs();
    }

    Process {
        id: authorsProc
        property var source: root.sources[0]
        stdout: StdioCollector { id: authorsCollector }
        onExited: code => {
            const raw = authorsCollector.text;
            const statusMatch = raw.match(/HTTP_STATUS:(\d+)\s*$/);
            const body = statusMatch ? raw.slice(0, statusMatch.index) : raw;
            const authors = {};
            try {
                if (statusMatch && statusMatch[1] === "200") {
                    const data = JSON.parse(body);
                    for (const folder in (data.presets ?? ({})))
                        if (data.presets[folder].author) authors[authorsProc.source.prefix + folder] = data.presets[folder].author;
                }
            } catch (e) {}
            root.publishListing(authors);
        }
    }

    function originOf(name) {
        for (const src of root.sources)
            if (src.prefix !== "" && name.startsWith(src.prefix)) return src.repo;
        const plain = root.sources.find(src => src.prefix === "");
        return plain ? plain.repo : "gallery";
    }

    function displayName(name) {
        for (const src of root.sources)
            if (src.prefix !== "" && name.startsWith(src.prefix)) return name.slice(src.prefix.length);
        return name;
    }

    function rawUrl(path, base) {
        return `${base}${path.split("/").map(encodeURIComponent).join("/")}`;
    }

    function cacheDir() {
        return Directories.onlinePresetsPath;
    }

    function assetDir(name) {
        return `${root.cacheDir()}/assets/${name}`;
    }

    function shQuote(str) {
        return "'" + String(str).replace(/'/g, "'\"'\"'") + "'";
    }

    function fail(message) {
        root.error = message;
        root.downloadingName = "";
    }

    // ─── Reference rewriting, used on Windows in place of jq ───
    function _applyShareFilter(obj) {
        const out = {};
        for (const key of root.shareAllowedRoots) {
            if (!(key in obj)) continue;
            if (key === "hyprland" && obj.hyprland && typeof obj.hyprland === "object" && !Array.isArray(obj.hyprland)) {
                const h = {};
                for (const hk of root.hyprlandAllowedKeys)
                    if (hk in obj.hyprland) h[hk] = obj.hyprland[hk];
                out.hyprland = h;
            } else {
                out[key] = obj[key];
            }
        }
        return out;
    }

    function _walkFix(node, dir, fileSet) {
        if (typeof node === "string") {
            const base = node.split("/").pop();
            return fileSet.has(base) ? `${dir}/${base}` : node;
        }
        if (Array.isArray(node))
            return node.map(item => root._walkFix(item, dir, fileSet));
        if (node !== null && typeof node === "object") {
            const out = {};
            for (const key in node)
                out[key] = root._walkFix(node[key], dir, fileSet);
            return out;
        }
        return node;
    }

    function _fixReferences(obj, dir, filenames) {
        const fileSet = new Set(filenames);
        let result = root._walkFix(obj, dir, fileSet);
        const tree = result?.background?.collage?.tree;
        if (tree != null) {
            try {
                const fixedTree = root._walkFix(JSON.parse(tree), dir, fileSet);
                result.background = Object.assign({}, result.background, {
                    collage: Object.assign({}, result.background.collage, { tree: JSON.stringify(fixedTree) })
                });
            } catch (e) {}
        }
        if (result && typeof result === "object" && "profile" in result)
            result.profile = Object.assign({}, result.profile, { avatarPath: dir });
        result._presetMeta = Object.assign({}, result._presetMeta, { source: "online" });
        return result;
    }

    function startAssets(name, stagingJsonPath, folderAssets, wallpaperFiles) {
        const dir = root.assetDir(name);
        assetsProc.entryName = name;
        assetsProc.stagingJsonPath = stagingJsonPath;
        assetsProc.assetCacheDirPath = dir;

        const rootBase = root.activeEntry?.rootWallpapers ? root.activeEntry.rawBase : "";
        const wallpaperAssets = rootBase === "" ? [] : wallpaperFiles.map(f => ({ filename: f.split("/").pop(), url: root.rawUrl(f, rootBase) }));
        const seen = new Set();
        const toDownload = [...wallpaperAssets, ...folderAssets].filter(a => {
            if (seen.has(a.filename)) return false;
            seen.add(a.filename);
            return true;
        });
        assetsProc.assetFilenames = toDownload.map(a => a.filename);

        let cmd = `mkdir -p ${root.shQuote(dir)}`;
        for (const asset of toDownload)
            cmd += ` && curl -sSL ${root.shQuote(asset.url)} -o ${root.shQuote(dir + "/" + asset.filename)}`;
        assetsProc.command = ["bash", "-c", cmd];
        assetsProc.running = true;
    }

    function download(entry) {
        if (root.downloadingName !== "") return;
        root.error = "";
        root.activeEntry = entry;
        root.downloadingName = entry.name;

        if (Platform.isWindows) {
            root._winDownload(entry);
            return;
        }

        const staging = `${root.cacheDir()}/.${entry.name}.online.json.tmp`;
        jsonProc.entryName = entry.name;
        jsonProc.entryAssets = entry.assets;
        jsonProc.metaUrl = entry.metaUrl;
        jsonProc.stagingJsonPath = staging;
        jsonProc.command = ["bash", "-c",
            `mkdir -p ${root.shQuote(root.cacheDir())} && curl -sSL ${root.shQuote(entry.jsonUrl)} -o ${root.shQuote(staging)}`];
        jsonProc.running = true;
    }

    Process {
        id: listProc
        property var source: root.sources[0]
        stdout: StdioCollector { id: listCollector }
        onExited: code => {
            const src = listProc.source;
            const raw = listCollector.text;
            const statusMatch = raw.match(/HTTP_STATUS:(\d+)\s*$/);
            const body = statusMatch ? raw.slice(0, statusMatch.index) : raw;
            const rawBase = `https://raw.githubusercontent.com/${src.repo}/${src.branch}/`;
            try {
                const data = JSON.parse(body);
                if (!Array.isArray(data.tree)) throw new Error("unexpected response");

                const prefix = "presets/";
                const imageExt = /\.(png|jpe?g|webp)$/i;
                const groups = {};

                for (const entry of data.tree) {
                    if (entry.type !== "blob" || !entry.path.startsWith(prefix)) continue;
                    const rel = entry.path.slice(prefix.length);
                    const slashIdx = rel.indexOf("/");
                    if (slashIdx === -1) continue;
                    const folder = rel.slice(0, slashIdx);
                    const filename = rel.slice(slashIdx + 1);
                    if (filename.includes("/")) continue;

                    if (!groups[folder]) groups[folder] = { images: [], assets: [], jsonPath: "", metaPath: "" };
                    if (filename.toLowerCase() === "meta.json") {
                        groups[folder].metaPath = entry.path;
                    } else if (/\.json$/i.test(filename)) {
                        groups[folder].jsonPath = entry.path;
                    } else {
                        groups[folder].assets.push({ path: entry.path, filename });
                        if (imageExt.test(filename)) groups[folder].images.push({ path: entry.path, filename });
                    }
                }

                const presets = [];
                for (const folder in groups) {
                    const g = groups[folder];
                    if (!g.jsonPath || g.images.length === 0) continue;

                    const exactPreview = /^preview\.png$/i;
                    const nonGeneric = g.images.filter(img => !exactPreview.test(img.filename));
                    const mainCandidates = nonGeneric.length > 0 ? nonGeneric : g.images;
                    const exactMatch = g.images.find(img => exactPreview.test(img.filename));
                    const deskMatch = mainCandidates.find(img => /desktop/i.test(img.filename));
                    const plainMatch = mainCandidates.find(img => !/pfp|avatar|banner/i.test(img.filename));
                    const main = exactMatch ?? deskMatch ?? plainMatch ?? mainCandidates[0];

                    presets.push({
                        name: src.prefix + folder,
                        title: folder.replace(/[-_]+/g, " ").replace(/\b\w/g, c => c.toUpperCase()),
                        author: src.repo.split("/")[0],
                        repo: src.repo,
                        sanitize: src.sanitize,
                        rootWallpapers: src.rootWallpapers,
                        rawBase: rawBase,
                        jsonUrl: root.rawUrl(g.jsonPath, rawBase),
                        metaUrl: g.metaPath ? root.rawUrl(g.metaPath, rawBase) : "",
                        screenshot: root.rawUrl(main.path, rawBase),
                        assets: g.assets.map(a => ({ filename: a.filename, url: root.rawUrl(a.path, rawBase) }))
                    });
                }
                root.collected = root.collected.concat(presets);
            } catch (e) {
                root.failedSources++;
            }
            root.sourceIndex++;
            if (root.sourceIndex < root.sources.length) Qt.callLater(root.listNext);
            else root.finishListing();
        }
    }

    Process {
        id: jsonProc
        property string entryName: ""
        property var entryAssets: []
        property string metaUrl: ""
        property string stagingJsonPath: ""
        onExited: code => {
            if (code !== 0) {
                root.fail(Translation.tr("Failed to download preset"));
                return;
            }
            if (jsonProc.metaUrl !== "") {
                metaProc.entryName = jsonProc.entryName;
                metaProc.entryAssets = jsonProc.entryAssets;
                metaProc.stagingJsonPath = jsonProc.stagingJsonPath;
                metaProc.command = [root.curlBin, "-sSL", jsonProc.metaUrl];
                metaProc.running = true;
            } else {
                root.startAssets(jsonProc.entryName, jsonProc.stagingJsonPath, jsonProc.entryAssets, []);
            }
        }
    }

    Process {
        id: metaProc
        property string entryName: ""
        property var entryAssets: []
        property string stagingJsonPath: ""
        stdout: StdioCollector { id: metaCollector }
        onExited: code => {
            let wallpaperFiles = [];
            if (code === 0) {
                try {
                    const meta = JSON.parse(metaCollector.text);
                    if (Array.isArray(meta.wallpapers)) wallpaperFiles = meta.wallpapers;
                } catch (e) {}
            }
            root.startAssets(metaProc.entryName, metaProc.stagingJsonPath, metaProc.entryAssets, wallpaperFiles);
        }
    }

    Process {
        id: assetsProc
        property string entryName: ""
        property string stagingJsonPath: ""
        property string assetCacheDirPath: ""
        property var assetFilenames: []
        onExited: code => {
            if (code !== 0) {
                root.fail(Translation.tr("Failed to download preset assets"));
                return;
            }
            const finalJsonPath = `${root.cacheDir()}/${assetsProc.entryName}.json`;
            const sanitize = root.activeEntry?.sanitize ?? false;
            const fixFilter = '$files as $files | def fix: walk(if type == "string" then '
                + '((split("/") | last) as $base | if ($files | index($base)) then ($dir + "/" + $base) else . end) else . end); '
                + 'fix | if (.background.collage.tree? // null) != null then .background.collage.tree |= (try (fromjson | fix | tojson) catch .) else . end '
                + '| if has("profile") then .profile.avatarPath = $dir else . end | ._presetMeta.source = "online"';
            const jqFilter = (sanitize ? root.shareFilter() : "") + fixFilter;
            const filesJson = JSON.stringify(assetsProc.assetFilenames);
            const cmd = `jq --arg dir ${root.shQuote(assetsProc.assetCacheDirPath)} --argjson files ${root.shQuote(filesJson)} ${root.shQuote(jqFilter)} ${root.shQuote(assetsProc.stagingJsonPath)} > ${root.shQuote(finalJsonPath)} && rm -f ${root.shQuote(assetsProc.stagingJsonPath)}`;
            rewriteProc.command = ["bash", "-c", cmd];
            rewriteProc.running = true;
        }
    }

    function shareFilter() {
        return "with_entries(select(.key as $k | " + JSON.stringify(root.shareAllowedRoots)
            + " | index($k))) | if (.hyprland | type) == \"object\" then .hyprland |= with_entries(select(.key as $k | "
            + JSON.stringify(root.hyprlandAllowedKeys) + " | index($k))) else . end | ";
    }

    Process {
        id: rewriteProc
        onExited: code => {
            if (code === 0) {
                Presets.refreshOnline();
                root.downloadingName = "";
            } else {
                root.fail(Translation.tr("Failed to finalize preset"));
            }
        }
    }

    // ─── Windows download pipeline (no bash/jq) ───
    property string _winStagingText: ""
    property string _winEntryName: ""
    property var _winAssetQueue: []
    property string _winAssetDir: ""
    property var _winAssetFilenames: []

    function _winDownload(entry) {
        winJsonProc.entryName = entry.name;
        winJsonProc.entryAssets = entry.assets;
        winJsonProc.metaUrl = entry.metaUrl;
        winJsonProc.command = [root.curlBin, "-sSL", "--max-time", "30", "--max-filesize", "2000000", entry.jsonUrl];
        winJsonProc.running = true;
    }

    Process {
        id: winJsonProc
        property string entryName: ""
        property var entryAssets: []
        property string metaUrl: ""
        stdout: StdioCollector { id: winJsonCollector }
        onExited: code => {
            if (code !== 0 || winJsonCollector.text.trim().length === 0) {
                root.fail(Translation.tr("Failed to download preset"));
                return;
            }
            if (winJsonProc.metaUrl !== "") {
                winMetaProc.entryName = winJsonProc.entryName;
                winMetaProc.entryAssets = winJsonProc.entryAssets;
                winMetaProc.stagingText = winJsonCollector.text;
                winMetaProc.command = [root.curlBin, "-sSL", "--max-time", "15", winJsonProc.metaUrl];
                winMetaProc.running = true;
            } else {
                root._winStartAssets(winJsonProc.entryName, winJsonCollector.text, winJsonProc.entryAssets, []);
            }
        }
    }

    Process {
        id: winMetaProc
        property string entryName: ""
        property var entryAssets: []
        property string stagingText: ""
        stdout: StdioCollector { id: winMetaCollector }
        onExited: code => {
            let wallpaperFiles = [];
            if (code === 0) {
                try {
                    const meta = JSON.parse(winMetaCollector.text);
                    if (Array.isArray(meta.wallpapers)) wallpaperFiles = meta.wallpapers;
                } catch (e) {}
            }
            root._winStartAssets(winMetaProc.entryName, winMetaProc.stagingText, winMetaProc.entryAssets, wallpaperFiles);
        }
    }

    function _winStartAssets(name, stagingText, folderAssets, wallpaperFiles) {
        const dir = root.assetDir(name);
        const rootBase = root.activeEntry?.rootWallpapers ? root.activeEntry.rawBase : "";
        const wallpaperAssets = rootBase === "" ? [] : wallpaperFiles.map(f => ({ filename: f.split("/").pop(), url: root.rawUrl(f, rootBase) }));
        const seen = new Set();
        const toDownload = [...wallpaperAssets, ...folderAssets].filter(a => {
            if (seen.has(a.filename)) return false;
            seen.add(a.filename);
            return true;
        });

        root._winEntryName = name;
        root._winStagingText = stagingText;
        root._winAssetDir = dir;
        root._winAssetFilenames = toDownload.map(a => a.filename);

        WindowsNative.fsUtils?.makePath(dir);
        root._winAssetQueue = toDownload.slice();
        root._winDownloadNextAsset();
    }

    function _winDownloadNextAsset() {
        if (root._winAssetQueue.length === 0) {
            root._winFinalize();
            return;
        }
        const asset = root._winAssetQueue.shift();
        winAssetProc.command = [root.curlBin, "-sSL", asset.url, "-o", `${root._winAssetDir}/${asset.filename}`];
        winAssetProc.running = true;
    }

    Process {
        id: winAssetProc
        onExited: code => {
            if (code !== 0) {
                root.fail(Translation.tr("Failed to download preset assets"));
                return;
            }
            root._winDownloadNextAsset();
        }
    }

    function _winFinalize() {
        try {
            let parsed = JSON.parse(root._winStagingText);
            if (root.activeEntry?.sanitize)
                parsed = root._applyShareFilter(parsed);
            parsed = root._fixReferences(parsed, root._winAssetDir, root._winAssetFilenames);
            winFinalWriteFile.targetPath = `${root.cacheDir()}/${root._winEntryName}.json`;
            WindowsNative.fsUtils?.makePath(root.cacheDir());
            winFinalWriteFile.setText(JSON.stringify(parsed, null, 2));
            Presets.refreshOnline();
            root.downloadingName = "";
        } catch (e) {
            root.fail(Translation.tr("Failed to finalize preset"));
        }
    }

    FileView {
        id: winFinalWriteFile
        property string targetPath: ""
        path: targetPath
        blockLoading: true
        printErrors: false
    }
}

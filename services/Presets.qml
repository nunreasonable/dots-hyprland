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

    property alias folderModel: presetsFolderModel
    property alias onlineFolderModel: onlinePresetsFolderModel
    property alias importedFolderModel: importedPresetsFolderModel

    signal renamed(string oldName, string newName)
    signal exported(string name, bool ok, string message)
    signal imported(string name)
    signal importFailed(string message)
    signal installed(string name, bool ok, string message)
    signal published(string name, string prUrl)
    signal unpublished(string name, string prUrl)
    signal pickPreviewRequested(string name)

    property list<string> lastSkippedKeys: []

    readonly property var allowedRoots: ["appearance", "background", "bar", "calendar", "cheatsheet", "crosshair", "custom", "dock", "interactions", "lock", "notifications", "osd", "overview", "settings", "sidebar", "time", "waffles", "wallpaperSelector"]
    readonly property var forbiddenParts: ["__proto__", "prototype", "constructor"]
    readonly property var spicyKeys: [
        "background.konachanSpicy",
        "background.konachanExtraTags",
        "wallpaperSelector.wallhavenPurity",
        "wallpaperSelector.wallhavenApiKey",
        "wallpaperSelector.wppFolder",
        "wallpaperSelector.wppSpicyFolder",
        "dock.pinnedApps",
        "bar.screenList",
        "notifications.forceMonitor"
    ]
    readonly property var sensitiveNamePattern: /(api[-_]?key|token|secret|credential|password|useragent)/i
    readonly property var pathLikeLeafPattern: /(path|url|uri|folder|dir|file|picture|image|icon|city|username|prompt|location|pins)$/i
    readonly property var imageExtPattern: /\.(png|jpe?g|webp|bmp)$/i

    readonly property string curlBin: Platform.isWindows ? "curl.exe" : "curl"
    readonly property string tarBin: "tar.exe"

    readonly property string githubRepo: "pctrade/end4-pCpresets"
    readonly property string githubClientId: ""
    readonly property string githubOAuthScope: "public_repo"

    property string githubLogin: ""
    property bool githubBusy: false
    property string githubError: ""

    property bool deviceFlowOpen: false
    property string deviceFlowUserCode: ""
    property string deviceFlowVerificationUri: ""

    property var sharedNames: []
    property var ownedCache: ({})

    property bool dirsReady: false

    function ensureDirs() {
        if (root.dirsReady)
            return;
        if (Platform.isWindows) {
            if (!WindowsNative.fsUtils)
                return;
            WindowsNative.fsUtils.makePath(Directories.userPresetsPath);
            WindowsNative.fsUtils.makePath(Directories.onlinePresetsPath);
            WindowsNative.fsUtils.makePath(Directories.importedPresetsPath);
            WindowsNative.fsUtils.makePath(Directories.presetsStagingPath);
        } else {
            presetsDirMarker.setText("");
            onlineDirMarker.setText("");
            importedDirMarker.setText("");
        }
        root.dirsReady = true;
        root.refresh();
        root.refreshOnline();
        root.refreshImported();
    }

    Component.onCompleted: {
        root.ensureDirs();
        sharedFile.reload();
    }

    Connections {
        target: WindowsNative
        function onReadyChanged() {
            root.ensureDirs();
        }
    }

    FileView {
        id: presetsDirMarker
        path: `${Directories.userPresetsPath}/.keep`
        printErrors: false
    }

    FileView {
        id: onlineDirMarker
        path: `${Directories.onlinePresetsPath}/.keep`
        printErrors: false
    }

    FileView {
        id: importedDirMarker
        path: `${Directories.importedPresetsPath}/.keep`
        printErrors: false
    }

    FolderListModel {
        id: presetsFolderModel
        folder: FileUtils.folderUrl(Directories.userPresetsPath)
        showDirs: false
        nameFilters: root.dirsReady ? ["*.json"] : ["*.not-ready"]
    }

    FolderListModel {
        id: onlinePresetsFolderModel
        folder: FileUtils.folderUrl(Directories.onlinePresetsPath)
        showDirs: false
        nameFilters: root.dirsReady ? ["*.json"] : ["*.not-ready"]
    }

    FolderListModel {
        id: importedPresetsFolderModel
        folder: FileUtils.folderUrl(Directories.importedPresetsPath)
        showDirs: false
        nameFilters: root.dirsReady ? ["*.json"] : ["*.not-ready"]
    }

    function refresh() {
        const current = presetsFolderModel.folder;
        presetsFolderModel.folder = "";
        presetsFolderModel.folder = current;
    }

    function refreshOnline() {
        const current = onlinePresetsFolderModel.folder;
        onlinePresetsFolderModel.folder = "";
        onlinePresetsFolderModel.folder = current;
    }

    function refreshImported() {
        const current = importedPresetsFolderModel.folder;
        importedPresetsFolderModel.folder = "";
        importedPresetsFolderModel.folder = current;
    }

    function previewImage(data) {
        const path = String(data?._presetMeta?.preview ?? data?.background?.wallpaperPath ?? "");
        if (/^https:\/\//i.test(path) || /^[A-Za-z]:[\\/]/.test(path) || (!Platform.isWindows && path.startsWith("/")))
            return path;
        return "";
    }

    function isSkippedKey(dottedKey) {
        const parts = dottedKey.split(".");
        if (parts.some(part => root.forbiddenParts.includes(part)))
            return true;
        if (!root.allowedRoots.includes(parts[0]))
            return true;
        const lower = dottedKey.toLowerCase();
        for (const spicy of root.spicyKeys) {
            if (lower === spicy.toLowerCase())
                return true;
        }
        if (root.sensitiveNamePattern.test(dottedKey.replace(/[._-]/g, "")))
            return true;
        if (root.pathLikeLeafPattern.test(parts[parts.length - 1]))
            return true;
        return false;
    }

    function existsInConfig(dottedKey) {
        const parts = dottedKey.split(".");
        let node = Config.options;
        for (const part of parts) {
            if (node === null || typeof node !== "object" || root.forbiddenParts.includes(part) || !(part in node) || typeof node[part] === "function")
                return false;
            node = node[part];
        }
        return true;
    }

    function isPlainObject(value) {
        return value !== null && typeof value === "object" && !Array.isArray(value);
    }

    function filterForSave(obj, prefix) {
        const out = {};
        for (const key in obj) {
            if (key === "_presetMeta")
                continue;
            const dotted = prefix ? `${prefix}.${key}` : key;
            if (root.isSkippedKey(dotted))
                continue;
            const value = obj[key];
            out[key] = root.isPlainObject(value) ? root.filterForSave(value, dotted) : value;
        }
        return out;
    }

    function applyFiltered(preset, prefix, skipped) {
        for (const key in preset) {
            if (key === "_presetMeta")
                continue;
            const dotted = prefix ? `${prefix}.${key}` : key;
            if (root.isSkippedKey(dotted)) {
                skipped.push(dotted);
                continue;
            }
            const value = preset[key];
            if (root.isPlainObject(value)) {
                root.applyFiltered(value, dotted, skipped);
                continue;
            }
            if (!root.existsInConfig(dotted))
                continue;
            Config.setNestedValue(dotted, value);
        }
    }

    function sanitizeName(rawName) {
        let name = String(rawName).trim().replace(/[\\/:*?"<>|\x00-\x1f]/g, "_").replace(/\s+/g, "_").replace(/^\.+/, "").slice(0, 80);
        if (/^(con|prn|aux|nul|com\d|lpt\d)$/i.test(name))
            name = "_" + name;
        return name.length > 0 ? name : "preset";
    }

    function shQuoteLinux(str) {
        return "'" + String(str).replace(/'/g, "'\"'\"'") + "'";
    }

    function isAbsolutePath(value) {
        return typeof value === "string" && (/^[A-Za-z]:[\\/]/.test(value) || value.startsWith("/") || value.startsWith("~/"));
    }

    function mapStrings(node, mapFn) {
        if (typeof node === "string")
            return mapFn(node);
        if (Array.isArray(node))
            return node.map(item => root.mapStrings(item, mapFn));
        if (node !== null && typeof node === "object") {
            const out = {};
            for (const key in node)
                out[key] = root.mapStrings(node[key], mapFn);
            return out;
        }
        return node;
    }

    function collectImageAssets(node, found) {
        found = found || [];
        if (typeof node === "string") {
            if (root.imageExtPattern.test(node) && root.isAbsolutePath(node) && found.indexOf(node) === -1)
                found.push(node);
        } else if (Array.isArray(node)) {
            for (const item of node)
                root.collectImageAssets(item, found);
        } else if (node !== null && typeof node === "object") {
            for (const key in node)
                root.collectImageAssets(node[key], found);
        }
        return found;
    }

    FileView {
        id: liveConfigFile
        path: Directories.shellConfigPath
        printErrors: false
    }

    FileView {
        id: presetWriteFile
        property string targetPath: ""
        path: targetPath
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: wallpaperSniffFile
        property string targetPath: ""
        path: targetPath
        blockAllReads: true
        printErrors: false
    }

    FileView {
        id: wallpaperCopyFile
        property string targetPath: ""
        path: targetPath
        blockWrites: true
        printErrors: false
    }

    function _sniffImageFormat(bytes) {
        if (bytes.length >= 8 && bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4E && bytes[3] === 0x47
                && bytes[4] === 0x0D && bytes[5] === 0x0A && bytes[6] === 0x1A && bytes[7] === 0x0A)
            return "png";
        if (bytes.length >= 3 && bytes[0] === 0xFF && bytes[1] === 0xD8 && bytes[2] === 0xFF)
            return "jpg";
        if (bytes.length >= 12 && bytes[0] === 0x52 && bytes[1] === 0x49 && bytes[2] === 0x46 && bytes[3] === 0x46
                && bytes[8] === 0x57 && bytes[9] === 0x45 && bytes[10] === 0x42 && bytes[11] === 0x50)
            return "webp";
        return "";
    }

    function _copyWallpaperForPreset(sourcePath, presetName) {
        const clean = FileUtils.trimFileProtocol(String(sourcePath ?? ""));
        if (clean === "" || /^https?:\/\//i.test(clean) || Wallpapers.isVideoPath(clean))
            return sourcePath ?? "";

        let buffer;
        try {
            wallpaperSniffFile.targetPath = clean;
            buffer = wallpaperSniffFile.data();
        } catch (e) {
            return sourcePath;
        }
        const bytes = new Uint8Array(buffer);
        if (bytes.length === 0)
            return sourcePath;

        const format = root._sniffImageFormat(bytes);
        const base = clean.split("/").pop();
        const dotIndex = base.lastIndexOf(".");
        const stem = dotIndex > 0 ? base.slice(0, dotIndex) : base;
        const currentExt = (dotIndex > 0 ? base.slice(dotIndex + 1) : "").toLowerCase().replace(/^jpeg$/, "jpg");
        const destName = (format !== "" && format !== currentExt) ? `${stem}.${format}` : base;
        const destPath = `${Directories.userPresetsPath}/assets/${presetName}/${destName}`;

        try {
            wallpaperCopyFile.targetPath = destPath;
            wallpaperCopyFile.setData(buffer);
        } catch (e) {
            return sourcePath;
        }
        return destPath;
    }

    FileView {
        id: presetReadFile
        property string targetPath: ""
        path: targetPath
        printErrors: false
        onLoaded: {
            const name = presetReadFile.targetPath.split("/").pop().replace(".json", "");
            root._finishApply(name, presetReadFile.text());
        }
    }

    property string _pendingSaveName: ""
    property string _pendingSaveDescription: ""

    function save(rawInput) {
        root.ensureDirs();
        const raw = String(rawInput).trim();
        if (raw.length === 0)
            return;
        const commaIndex = raw.indexOf(",");
        let name = raw;
        let description = "";
        if (commaIndex !== -1) {
            name = raw.substring(0, commaIndex).trim();
            description = raw.substring(commaIndex + 1).trim();
        }
        name = root.sanitizeName(name);
        if (name.length === 0)
            return;
        root._pendingSaveName = name;
        root._pendingSaveDescription = description;
        liveConfigFile.reload();
        Qt.callLater(root._finishSave);
    }

    function overwrite(name) {
        root.save(name);
    }

    function _finishSave() {
        let parsed;
        try {
            parsed = JSON.parse(liveConfigFile.text());
        } catch (e) {
            console.log("[Presets] could not read current config:", e);
            return;
        }
        const filtered = root.filterForSave(parsed, "");
        const livePreview = String(parsed?.background?.wallpaperPath ?? "");
        const preview = livePreview !== "" ? root._copyWallpaperForPreset(livePreview, root._pendingSaveName) : "";
        filtered._presetMeta = { preview: preview };
        if (root._pendingSaveDescription !== "")
            filtered._presetMeta.description = root._pendingSaveDescription;
        presetWriteFile.targetPath = `${Directories.userPresetsPath}/${root._pendingSaveName}.json`;
        presetWriteFile.setText(JSON.stringify(filtered, null, 2));
        root.refresh();
    }

    function apply(name) {
        presetReadFile.targetPath = `${Directories.userPresetsPath}/${name}.json`;
        presetReadFile.reload();
    }

    function applyOnline(name) {
        presetReadFile.targetPath = `${Directories.onlinePresetsPath}/${name}.json`;
        presetReadFile.reload();
    }

    function applyImported(name) {
        presetReadFile.targetPath = `${Directories.importedPresetsPath}/${name}.json`;
        presetReadFile.reload();
    }

    function _finishApply(name, text) {
        let parsed;
        try {
            parsed = JSON.parse(text);
        } catch (e) {
            console.log("[Presets] could not read preset:", name, e);
            return;
        }
        const skipped = [];
        root.applyFiltered(parsed, "", skipped);
        root.lastSkippedKeys = skipped;
        Qt.callLater(() => Wallpapers.reapplyPalette());
    }

    function remove(name) {
        root._deletePath(`${Directories.userPresetsPath}/${name}.json`, root.refresh);
    }

    function removeOnline(name) {
        root._deletePath(`${Directories.onlinePresetsPath}/${name}.json`, root.refreshOnline);
    }

    function removeImported(name) {
        root._deletePath(`${Directories.importedPresetsPath}/${name}.json`, root.refreshImported);
    }

    function _deletePath(path, onDone) {
        if (Platform.isWindows) {
            WindowsNative.fsUtils?.removeFile(path);
            if (onDone)
                onDone();
            return;
        }
        deleteProc.onDone = onDone;
        deleteProc.command = ["rm", "-f", "--", path];
        deleteProc.running = true;
    }

    Process {
        id: deleteProc
        property var onDone: null
        onExited: {
            if (deleteProc.onDone)
                deleteProc.onDone();
        }
    }

    function _removeStagingDir(dir) {
        if (dir === "")
            return;
        if (Platform.isWindows) {
            Quickshell.execDetached(["powershell.exe", "-NoProfile", "-Command", `Remove-Item -LiteralPath '${dir.replace(/'/g, "''")}' -Recurse -Force -ErrorAction SilentlyContinue`]);
        } else {
            Quickshell.execDetached(["bash", "-c", `rm -rf -- ${root.shQuoteLinux(dir)}`]);
        }
    }

    function _clearStagingDir(dir, callback) {
        clearStageProc.onDoneCb = callback;
        if (Platform.isWindows) {
            const escaped = dir.replace(/'/g, "''");
            clearStageProc.command = ["powershell.exe", "-NoProfile", "-Command", `if (Test-Path -LiteralPath '${escaped}') { Remove-Item -LiteralPath '${escaped}' -Recurse -Force }; New-Item -ItemType Directory -Force -Path '${escaped}' | Out-Null`];
        } else {
            clearStageProc.command = ["bash", "-c", `rm -rf -- ${root.shQuoteLinux(dir)} && mkdir -p ${root.shQuoteLinux(dir)}`];
        }
        clearStageProc.running = true;
    }

    Process {
        id: clearStageProc
        property var onDoneCb: null
        onExited: {
            const cb = clearStageProc.onDoneCb;
            clearStageProc.onDoneCb = null;
            if (cb)
                cb();
        }
    }

    function openPresetsFolder() {
        if (Platform.isWindows)
            WindowsNative.fsUtils?.makePath(Directories.userPresetsPath);
        Qt.openUrlExternally(FileUtils.folderUrl(Directories.userPresetsPath));
    }

    function importJsonText(text, suggestedName) {
        let parsed;
        try {
            parsed = JSON.parse(text);
        } catch (e) {
            console.log("[Presets] dropped file is not valid JSON:", e);
            return false;
        }
        if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed))
            return false;
        let name = root.sanitizeName(suggestedName || "imported");
        if (name.length === 0)
            name = "imported";
        presetWriteFile.targetPath = `${Directories.userPresetsPath}/${name}.json`;
        presetWriteFile.setText(JSON.stringify(parsed, null, 2));
        root.refresh();
        return true;
    }

    property string _renameOldName: ""
    property string _renameNewName: ""

    function rename(name, newName) {
        const sanitized = root.sanitizeName(String(newName).trim());
        if (sanitized === "" || sanitized === name) {
            root.renamed(name, "");
            return;
        }
        root._renameOldName = name;
        root._renameNewName = sanitized;
        renameCheckFile.path = `${Directories.userPresetsPath}/${sanitized}.json`;
        renameCheckFile.reload();
    }

    FileView {
        id: renameCheckFile
        printErrors: false
        onLoaded: root.renamed(root._renameOldName, "")
        onLoadFailed: error => {
            renameReadFile.path = `${Directories.userPresetsPath}/${root._renameOldName}.json`;
            renameReadFile.reload();
        }
    }

    FileView {
        id: renameReadFile
        printErrors: false
        onLoaded: {
            const text = renameReadFile.text();
            presetWriteFile.targetPath = `${Directories.userPresetsPath}/${root._renameNewName}.json`;
            presetWriteFile.setText(text);
            root._deletePath(`${Directories.userPresetsPath}/${root._renameOldName}.json`, () => {
                root.refresh();
                root.renamed(root._renameOldName, root._renameNewName);
            });
        }
        onLoadFailed: error => root.renamed(root._renameOldName, "")
    }

    property string _stageDir: ""
    property var _stageParsed: null
    property string _stageName: ""
    property string _stagePreview: ""
    property var _stageOnReady: null
    property var _stageOnError: null
    property var _stageQueue: []
    property var _stageRenameMap: ({})
    property var _stageUsedNames: ({})

    function _prepareExportFolder(name, previewPath, onReady, onError) {
        exportSourceFile.presetName = name;
        exportSourceFile.previewPath = previewPath;
        exportSourceFile.onReady = onReady;
        exportSourceFile.onError = onError;
        exportSourceFile.path = `${Directories.userPresetsPath}/${name}.json`;
        exportSourceFile.reload();
    }

    FileView {
        id: exportSourceFile
        property string presetName: ""
        property string previewPath: ""
        property var onReady: null
        property var onError: null
        printErrors: false
        onLoaded: root._exportGotJson(exportSourceFile.text())
        onLoadFailed: error => {
            const cb = exportSourceFile.onError;
            exportSourceFile.onError = null;
            if (cb)
                cb(Translation.tr("Preset not found"));
        }
    }

    function _exportGotJson(text) {
        let parsed;
        try {
            parsed = JSON.parse(text);
        } catch (e) {
            const cb = exportSourceFile.onError;
            exportSourceFile.onError = null;
            if (cb)
                cb(Translation.tr("Could not read the preset"));
            return;
        }
        if (parsed?._presetMeta?.origin) {
            const cb = exportSourceFile.onError;
            exportSourceFile.onError = null;
            if (cb)
                cb(Translation.tr("This preset came from the gallery and can't be exported"));
            return;
        }
        const assets = root.collectImageAssets(parsed);
        const stagingDir = `${Directories.presetsStagingPath}/${exportSourceFile.presetName}`;
        root._stageOnReady = exportSourceFile.onReady;
        root._stageOnError = exportSourceFile.onError;
        root._clearStagingDir(stagingDir, () => {
            root._stageAssets(stagingDir, parsed, assets, exportSourceFile.presetName, exportSourceFile.previewPath);
        });
    }

    function _stageAssets(stagingDir, parsed, assetPaths, name, previewPath) {
        root._stageDir = stagingDir;
        root._stageParsed = parsed;
        root._stageName = name;
        root._stagePreview = previewPath;
        root._stageRenameMap = {};
        root._stageUsedNames = {};
        root._stageQueue = assetPaths.slice();
        if (Platform.isWindows)
            WindowsNative.fsUtils?.makePath(stagingDir);
        root._stageNext();
    }

    function _stageNext() {
        if (root._stageQueue.length === 0) {
            root._stageFinish();
            return;
        }
        const src = root._stageQueue.shift();
        stageSniffFile.sourcePath = src;
        stageSniffFile.path = src;
        stageSniffFile.reload();
    }

    FileView {
        id: stageSniffFile
        property string sourcePath: ""
        blockAllReads: true
        printErrors: false
        onLoaded: {
            try {
                const buf = stageSniffFile.data();
                root._stageGotBytes(stageSniffFile.sourcePath, buf);
            } catch (e) {
                root._stageNext();
            }
        }
        onLoadFailed: error => root._stageNext()
    }

    function _stageGotBytes(sourcePath, buffer) {
        const bytes = new Uint8Array(buffer);
        const format = root._sniffImageFormat(bytes);
        const base = sourcePath.split(/[\\/]/).pop();
        const dot = base.lastIndexOf(".");
        const stem = dot > 0 ? base.slice(0, dot) : base;
        const currentExt = (dot > 0 ? base.slice(dot + 1) : "").toLowerCase().replace(/^jpeg$/, "jpg");
        let destName = (format !== "" && format !== currentExt) ? `${stem}.${format}` : base;
        if (root._stageUsedNames[destName] !== undefined && root._stageUsedNames[destName] !== sourcePath)
            destName = `${stem}-fixed.${format || currentExt || "png"}`;
        root._stageUsedNames[destName] = sourcePath;
        root._stageRenameMap[sourcePath] = destName;
        try {
            stageWriteFile.targetPath = `${root._stageDir}/${destName}`;
            stageWriteFile.setData(buffer);
        } catch (e) {}
        root._stageNext();
    }

    FileView {
        id: stageWriteFile
        property string targetPath: ""
        path: targetPath
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: previewReadFile
        blockAllReads: true
        printErrors: false
    }

    FileView {
        id: previewStageWriteFile
        property string targetPath: ""
        path: targetPath
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: metaStageWriteFile
        property string targetPath: ""
        path: targetPath
        blockLoading: true
        printErrors: false
    }

    function _stageFinish() {
        let finalObj = root.mapStrings(root._stageParsed, s => root._stageRenameMap[s] !== undefined ? root._stageRenameMap[s] : s);
        finalObj = root.mapStrings(finalObj, s => root.isAbsolutePath(s) ? s.split(/[\\/]/).pop() : s);

        const wallpapers = Object.values(root._stageRenameMap);
        const meta = { preview: "", screenshots: [], wallpapers: wallpapers };

        if (root._stagePreview !== "") {
            try {
                previewReadFile.path = root._stagePreview;
                previewReadFile.reload();
                const buf = previewReadFile.data();
                const ext = (root._stagePreview.match(/\.[^.\\/]+$/) ?? [".png"])[0].toLowerCase();
                const previewName = `preview${ext === ".jpeg" ? ".jpg" : ext}`;
                previewStageWriteFile.targetPath = `${root._stageDir}/${previewName}`;
                previewStageWriteFile.setData(buf);
                meta.preview = previewName;
            } catch (e) {}
        }

        presetWriteFile.targetPath = `${root._stageDir}/${root._stageName}.json`;
        presetWriteFile.setText(JSON.stringify(finalObj, null, 2));
        metaStageWriteFile.targetPath = `${root._stageDir}/meta.json`;
        metaStageWriteFile.setText(JSON.stringify(meta, null, 2));

        const names = [`${root._stageName}.json`, "meta.json"].concat(Object.values(root._stageRenameMap));
        if (meta.preview !== "")
            names.push(meta.preview);

        const onReady = root._stageOnReady;
        root._stageOnReady = null;
        root._stageOnError = null;
        if (onReady)
            onReady(root._stageDir, names);
    }

    function _zipStagingDir(stagingDir, names, destZipPath, callback) {
        zipProc.onDoneCb = callback;
        if (Platform.isWindows) {
            WindowsNative.fsUtils?.removeFile(destZipPath);
            zipProc.command = [root.tarBin, "-a", "-c", "-f", destZipPath, "-C", stagingDir].concat(names);
        } else {
            const nameList = names.map(root.shQuoteLinux).join(" ");
            zipProc.command = ["bash", "-c", `cd ${root.shQuoteLinux(stagingDir)} && rm -f ${root.shQuoteLinux(destZipPath)} && (command -v zip >/dev/null 2>&1 && zip -q -r ${root.shQuoteLinux(destZipPath)} ${nameList} || python3 -c "import zipfile,sys; z=zipfile.ZipFile(sys.argv[1],'w',zipfile.ZIP_DEFLATED); [z.write(n) for n in sys.argv[2:]]; z.close()" ${root.shQuoteLinux(destZipPath)} ${nameList})`];
        }
        zipProc.running = true;
    }

    Process {
        id: zipProc
        property var onDoneCb: null
        onExited: code => {
            const cb = zipProc.onDoneCb;
            zipProc.onDoneCb = null;
            if (cb)
                cb(code === 0);
        }
    }

    function exportZip(name) {
        root._prepareExportFolder(name, "", (stagingDir, names) => {
            root._zipStagingDir(stagingDir, names, `${Directories.userPresetsPath}/${name}.zip`, ok => {
                root._removeStagingDir(stagingDir);
                root.refresh();
                root.exported(name, ok, ok ? "" : Translation.tr("Could not create the ZIP file"));
            });
        }, message => root.exported(name, false, message));
    }

    property string _importStagingDir: ""
    property string _importJsonEntry: ""
    property string _importBaseDir: ""
    property var _importParsed: null
    property string _importBaseName: ""
    property var _importFileSet: null
    property var _importCopyQueue: []
    property string _importSrcDir: ""
    property string _importDestDir: ""

    function importZip(zipPath) {
        const clean = FileUtils.trimFileProtocol(String(zipPath));
        const stagingDir = `${Directories.presetsStagingPath}/_import`;
        root._clearStagingDir(stagingDir, () => root._importExtract(stagingDir, clean));
    }

    function _importExtract(stagingDir, zipPath) {
        root._importStagingDir = stagingDir;
        if (Platform.isWindows) {
            importListProc.command = [root.tarBin, "-tf", zipPath];
        } else {
            importListProc.command = ["bash", "-c", `unzip -Z1 ${root.shQuoteLinux(zipPath)} 2>/dev/null || unzip -l ${root.shQuoteLinux(zipPath)} | awk 'NR>3 {print $4}'`];
        }
        importListProc.zipPath = zipPath;
        importListProc.running = true;
    }

    Process {
        id: importListProc
        property string zipPath: ""
        stdout: StdioCollector { id: importListOut }
        onExited: code => {
            if (code !== 0) {
                root.importFailed(Translation.tr("Could not read the ZIP file"));
                return;
            }
            const entries = importListOut.text.split("\n").map(l => l.trim()).filter(l => l.length > 0 && !l.endsWith("/"));
            const jsonEntry = entries.find(e => /\.json$/i.test(e) && e.split("/").pop().toLowerCase() !== "meta.json" && (e.split("/").length - 1) <= 3);
            if (!jsonEntry) {
                root.importFailed(Translation.tr("No preset file found in the ZIP"));
                return;
            }
            root._importJsonEntry = jsonEntry;
            const slash = jsonEntry.lastIndexOf("/");
            root._importBaseDir = slash === -1 ? "" : jsonEntry.slice(0, slash);
            if (Platform.isWindows) {
                importExtractProc.command = [root.tarBin, "-xf", importListProc.zipPath, "-C", root._importStagingDir];
            } else {
                importExtractProc.command = ["bash", "-c", `cd ${root.shQuoteLinux(root._importStagingDir)} && (unzip -q ${root.shQuoteLinux(importListProc.zipPath)} || python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall('.')" ${root.shQuoteLinux(importListProc.zipPath)})`];
            }
            importExtractProc.running = true;
        }
    }

    Process {
        id: importExtractProc
        onExited: code => {
            if (code !== 0) {
                root.importFailed(Translation.tr("Could not extract the ZIP file"));
                return;
            }
            importJsonReadFile.path = `${root._importStagingDir}/${root._importJsonEntry}`;
            importJsonReadFile.reload();
        }
    }

    FileView {
        id: importJsonReadFile
        printErrors: false
        onLoaded: root._importGotJson(importJsonReadFile.text())
        onLoadFailed: error => root.importFailed(Translation.tr("No preset file found in the ZIP"))
    }

    function _importGotJson(text) {
        let parsed;
        try {
            parsed = JSON.parse(text);
        } catch (e) {
            root.importFailed(Translation.tr("The preset file in the ZIP is invalid"));
            return;
        }
        const assetDir = root._importBaseDir === "" ? root._importStagingDir : `${root._importStagingDir}/${root._importBaseDir}`;
        const baseName = root.sanitizeName(FileUtils.fileNameForPath(root._importJsonEntry).replace(/\.json$/i, ""));
        root._importParsed = parsed;
        root._importBaseName = baseName;
        if (Platform.isWindows) {
            const files = (WindowsNative.fsUtils?.listDir(assetDir) ?? []).filter(f => !/\.json$/i.test(f));
            root._importCopyAssets(assetDir, `${Directories.importedPresetsPath}/assets/${baseName}`, files);
        } else {
            importFindProc.assetDir = assetDir;
            importFindProc.destAssetDir = `${Directories.importedPresetsPath}/assets/${baseName}`;
            importFindProc.command = ["bash", "-c", `cd ${root.shQuoteLinux(assetDir)} && find . -maxdepth 1 -type f ! -iname "*.json" -printf '%f\\n' 2>/dev/null`];
            importFindProc.running = true;
        }
    }

    Process {
        id: importFindProc
        property string assetDir: ""
        property string destAssetDir: ""
        stdout: StdioCollector { id: importFindOut }
        onExited: code => {
            const files = importFindOut.text.split("\n").map(l => l.trim()).filter(l => l.length > 0);
            root._importCopyAssets(importFindProc.assetDir, importFindProc.destAssetDir, files);
        }
    }

    function _importCopyAssets(assetDir, destAssetDir, files) {
        if (Platform.isWindows)
            WindowsNative.fsUtils?.makePath(destAssetDir);
        root._importSrcDir = assetDir;
        root._importDestDir = destAssetDir;
        root._importFileSet = new Set(files);
        root._importCopyQueue = files.slice();
        root._importCopyNext();
    }

    function _importCopyNext() {
        if (root._importCopyQueue.length === 0) {
            root._importFinish();
            return;
        }
        const file = root._importCopyQueue.shift();
        importCopyReadFile.destName = file;
        importCopyReadFile.path = `${root._importSrcDir}/${file}`;
        importCopyReadFile.reload();
    }

    FileView {
        id: importCopyReadFile
        property string destName: ""
        blockAllReads: true
        printErrors: false
        onLoaded: {
            try {
                const buf = importCopyReadFile.data();
                importCopyWriteFile.targetPath = `${root._importDestDir}/${importCopyReadFile.destName}`;
                importCopyWriteFile.setData(buf);
            } catch (e) {}
            root._importCopyNext();
        }
        onLoadFailed: error => root._importCopyNext()
    }

    FileView {
        id: importCopyWriteFile
        property string targetPath: ""
        path: targetPath
        blockLoading: true
        printErrors: false
    }

    function _importedNameExists(name) {
        const path = `${Directories.importedPresetsPath}/${name}.json`;
        if (Platform.isWindows)
            return WindowsNative.fsUtils ? WindowsNative.fsUtils.classify(path) !== "invalid" : false;
        return false;
    }

    function _importFinish() {
        const dir = root._importDestDir;
        const fileSet = root._importFileSet;
        let fixed = root.mapStrings(root._importParsed, s => {
            const base = s.split(/[\\/]/).pop();
            return fileSet.has(base) ? `${dir}/${base}` : s;
        });
        const filtered = root.filterForSave(fixed, "");
        filtered._presetMeta = Object.assign({}, fixed?._presetMeta, { source: "imported" });
        delete filtered._presetMeta.origin;

        let name = root._importBaseName;
        let n = 2;
        while (root._importedNameExists(name)) {
            name = `${root._importBaseName}_${n}`;
            n++;
        }
        presetWriteFile.targetPath = `${Directories.importedPresetsPath}/${name}.json`;
        presetWriteFile.setText(JSON.stringify(filtered, null, 2));
        root.refreshImported();
        root._removeStagingDir(root._importStagingDir);
        root.imported(name);
    }

    property var _installParsed: null
    property string _installName: ""
    property string _installSource: ""
    property var _installQueue: []
    property var _installRenameMap: ({})

    function install(name, source) {
        const dir = source === "imported" ? Directories.importedPresetsPath : Directories.onlinePresetsPath;
        installReadFile.name = name;
        installReadFile.source = source;
        installReadFile.path = `${dir}/${name}.json`;
        installReadFile.reload();
    }

    FileView {
        id: installReadFile
        property string name: ""
        property string source: ""
        printErrors: false
        onLoaded: root._installGotJson(installReadFile.name, installReadFile.source, installReadFile.text())
        onLoadFailed: error => root.installed("", false, Translation.tr("Preset not found"))
    }

    function _installGotJson(name, source, text) {
        let parsed;
        try {
            parsed = JSON.parse(text);
        } catch (e) {
            root.installed(name, false, Translation.tr("Could not read the preset"));
            return;
        }
        root._installParsed = parsed;
        root._installName = name;
        root._installSource = source;
        root._installRenameMap = {};
        root._installQueue = root.collectImageAssets(parsed);
        root._installNext();
    }

    function _installNext() {
        if (root._installQueue.length === 0) {
            root._installFinish();
            return;
        }
        const src = root._installQueue.shift();
        installAssetReadFile.sourcePath = src;
        installAssetReadFile.path = src;
        installAssetReadFile.reload();
    }

    FileView {
        id: installAssetReadFile
        property string sourcePath: ""
        blockAllReads: true
        printErrors: false
        onLoaded: {
            try {
                const buf = installAssetReadFile.data();
                root._installPlaceAsset(installAssetReadFile.sourcePath, buf);
            } catch (e) {}
            root._installNext();
        }
        onLoadFailed: error => root._installNext()
    }

    FileView {
        id: installAssetWriteFile
        property string targetPath: ""
        path: targetPath
        blockLoading: true
        printErrors: false
    }

    function _installRoleFor(path) {
        if (/wallpaper|lockwall/i.test(path))
            return "wallpaper";
        if (/avatar/i.test(path))
            return "avatar";
        return "asset";
    }

    function _installPlaceAsset(sourcePath, buffer) {
        const role = root._installRoleFor(sourcePath);
        const picturesDir = FileUtils.trimFileProtocol(Directories.pictures);
        const destDir = role === "wallpaper" ? `${picturesDir}/Wallpapers`
            : role === "avatar" ? `${picturesDir}/avatar`
            : `${picturesDir}/preset-assets`;
        if (Platform.isWindows)
            WindowsNative.fsUtils?.makePath(destDir);
        const base = sourcePath.split(/[\\/]/).pop();
        let destPath = `${destDir}/${base}`;
        if (Platform.isWindows && WindowsNative.fsUtils && WindowsNative.fsUtils.classify(destPath) !== "invalid") {
            const dot = base.lastIndexOf(".");
            const stem = dot > 0 ? base.slice(0, dot) : base;
            const ext = dot > 0 ? base.slice(dot) : "";
            destPath = `${destDir}/${stem}-${Date.now().toString(36)}${ext}`;
        }
        try {
            installAssetWriteFile.targetPath = destPath;
            installAssetWriteFile.setData(buffer);
            root._installRenameMap[sourcePath] = destPath;
        } catch (e) {}
    }

    function _mineNameExists(name) {
        const path = `${Directories.userPresetsPath}/${name}.json`;
        if (Platform.isWindows)
            return WindowsNative.fsUtils ? WindowsNative.fsUtils.classify(path) !== "invalid" : false;
        return false;
    }

    function _installFinish() {
        const map = root._installRenameMap;
        let fixed = root.mapStrings(root._installParsed, s => map[s] !== undefined ? map[s] : s);
        const filtered = root.filterForSave(fixed, "");
        filtered._presetMeta = { origin: root._installSource === "imported" ? "imported" : PresetsOnline.originOf(root._installName) };

        let name = root.sanitizeName(PresetsOnline.displayName(root._installName));
        if (name === "")
            name = "preset";
        let finalName = name;
        let n = 2;
        while (root._mineNameExists(finalName)) {
            finalName = `${name}_${n}`;
            n++;
        }
        presetWriteFile.targetPath = `${Directories.userPresetsPath}/${finalName}.json`;
        presetWriteFile.setText(JSON.stringify(filtered, null, 2));
        root.refresh();
        root.installed(finalName, true, "");
    }

    readonly property string sharedFilePath: Directories.sharedPresetsPath

    function isPublished(name) {
        return root.sharedNames.includes(name) || root.ownedCache[name] === true;
    }

    function rememberShared(name) {
        const cache = Object.assign({}, root.ownedCache);
        cache[name] = true;
        root.ownedCache = cache;
        if (root.sharedNames.includes(name))
            return;
        root.sharedNames = root.sharedNames.concat([name]);
        sharedFile.setText(JSON.stringify(root.sharedNames));
    }

    function forgetShared(name) {
        const cache = Object.assign({}, root.ownedCache);
        cache[name] = false;
        root.ownedCache = cache;
        if (!root.sharedNames.includes(name))
            return;
        root.sharedNames = root.sharedNames.filter(entry => entry !== name);
        sharedFile.setText(JSON.stringify(root.sharedNames));
    }

    FileView {
        id: sharedFile
        path: root.sharedFilePath
        printErrors: false
        onLoaded: {
            try {
                const saved = JSON.parse(sharedFile.text());
                if (Array.isArray(saved))
                    root.sharedNames = saved;
            } catch (e) {}
        }
    }

    property var _ghTokenCallback: null
    property string _ghToken: ""

    function _withGithubToken(callback) {
        root._ghTokenCallback = callback;
        root._ghCliTried = false;
        root._resolveGithubToken();
    }

    function _resolveGithubToken() {
        if (!KeyringStorage.loaded) {
            KeyringStorage.fetchKeyringData();
            return;
        }
        const token = KeyringStorage.keyringData?.presets?.github?.token ?? "";
        if (token === "") {
            root._tryGhCli();
            return;
        }
        root._verifyToken(token);
    }

    property bool _ghCliTried: false

    function _tryGhCli() {
        if (root._ghCliTried) {
            root._startDeviceFlow();
            return;
        }
        root._ghCliTried = true;
        const gh = Platform.isWindows ? (WindowsNative.fsUtils?.findExecutable("gh") ?? "") : "gh";
        if (gh === "") {
            root._startDeviceFlow();
            return;
        }
        ghCliTokenProc.command = [gh, "auth", "token"];
        ghCliTokenProc.running = true;
    }

    Process {
        id: ghCliTokenProc
        stdout: StdioCollector { id: ghCliTokenOut }
        onExited: code => {
            const token = ghCliTokenOut.text.trim();
            if (code === 0 && token !== "")
                root._verifyToken(token);
            else
                root._startDeviceFlow();
        }
    }

    Connections {
        target: KeyringStorage
        function onLoadedChanged() {
            if (root._ghTokenCallback)
                root._resolveGithubToken();
        }
        function onDataChanged() {
            if (root._ghTokenCallback)
                root._resolveGithubToken();
        }
    }

    function _verifyToken(token) {
        verifyTokenProc.command = [root.curlBin, "-sS", "-w", "\nHTTP_STATUS:%{http_code}",
            "-H", `Authorization: Bearer ${token}`,
            "-H", "Accept: application/vnd.github+json",
            "-H", "X-GitHub-Api-Version: 2022-11-28",
            "-H", "User-Agent: ii-windows-presets",
            "https://api.github.com/user"];
        verifyTokenProc.token = token;
        verifyTokenProc.running = true;
    }

    Process {
        id: verifyTokenProc
        property string token: ""
        stdout: StdioCollector { id: verifyTokenOut }
        onExited: code => {
            const parsed = root._parseGhResponse(verifyTokenOut.text);
            if (parsed.status === 200 && parsed.body?.login) {
                root.githubLogin = parsed.body.login;
                root._ghToken = verifyTokenProc.token;
                const cb = root._ghTokenCallback;
                root._ghTokenCallback = null;
                if (cb)
                    cb(verifyTokenProc.token);
            } else {
                root._tryGhCli();
            }
        }
    }

    function _parseGhResponse(raw) {
        const m = raw.match(/HTTP_STATUS:(\d+)\s*$/);
        const status = m ? parseInt(m[1]) : -1;
        const bodyText = m ? raw.slice(0, m.index) : raw;
        let body = null;
        try {
            body = JSON.parse(bodyText);
        } catch (e) {}
        return { status: status, body: body };
    }

    function _b64Decode(base64WithNewlines) {
        return Qt.atob(String(base64WithNewlines).replace(/\s+/g, ""));
    }

    function _startDeviceFlow() {
        if (root.githubClientId === "") {
            root.githubError = Translation.tr("Sign in with the GitHub CLI first: install it (winget install GitHub.cli), then run gh auth login");
            root.githubBusy = false;
            root._ghTokenCallback = null;
            return;
        }
        deviceCodeProc.command = [root.curlBin, "-sS", "-X", "POST",
            "-H", "Accept: application/json",
            "-d", `client_id=${root.githubClientId}&scope=${root.githubOAuthScope}`,
            "https://github.com/login/device/code"];
        deviceCodeProc.running = true;
    }

    Process {
        id: deviceCodeProc
        stdout: StdioCollector { id: deviceCodeOut }
        onExited: code => {
            let data = null;
            try {
                data = JSON.parse(deviceCodeOut.text);
            } catch (e) {}
            if (!data || !data.device_code) {
                root.githubBusy = false;
                root.githubError = Translation.tr("Could not start GitHub sign-in");
                root._ghTokenCallback = null;
                return;
            }
            root._deviceCode = data.device_code;
            root.deviceFlowUserCode = data.user_code;
            root.deviceFlowVerificationUri = data.verification_uri_complete || data.verification_uri;
            root.deviceFlowOpen = true;
            root.githubBusy = true;
            devicePollTimer.interval = Math.max(5, data.interval || 5) * 1000;
            devicePollTimer.restart();
            Qt.openUrlExternally(root.deviceFlowVerificationUri);
        }
    }

    property string _deviceCode: ""

    Timer {
        id: devicePollTimer
        repeat: true
        onTriggered: devicePollProc.running = true
    }

    Process {
        id: devicePollProc
        command: [root.curlBin, "-sS", "-X", "POST",
            "-H", "Accept: application/json",
            "-d", `client_id=${root.githubClientId}&device_code=${root._deviceCode}&grant_type=urn:ietf:params:oauth:grant-type:device_code`,
            "https://github.com/login/oauth/access_token"]
        stdout: StdioCollector { id: devicePollOut }
        onExited: code => {
            let data = null;
            try {
                data = JSON.parse(devicePollOut.text);
            } catch (e) {}
            if (data && data.access_token) {
                devicePollTimer.stop();
                root.deviceFlowOpen = false;
                KeyringStorage.setNestedField(["presets", "github", "token"], data.access_token);
                root._verifyToken(data.access_token);
                return;
            }
            const err = data?.error ?? "";
            if (err === "authorization_pending")
                return;
            if (err === "slow_down") {
                devicePollTimer.interval += 5000;
                return;
            }
            devicePollTimer.stop();
            root.deviceFlowOpen = false;
            root.githubBusy = false;
            root._ghTokenCallback = null;
            root.githubError = err === "expired_token" ? Translation.tr("The sign-in code expired, try again")
                : err === "access_denied" ? Translation.tr("Sign-in was cancelled")
                : Translation.tr("GitHub sign-in failed");
        }
    }

    function cancelDeviceFlow() {
        devicePollTimer.stop();
        root.deviceFlowOpen = false;
        root.githubBusy = false;
        root._ghTokenCallback = null;
    }

    property var _ghApiCallback: null

    function _ghApi(method, path, bodyObj, callback) {
        root._ghApiCallback = callback;
        const url = path.startsWith("http") ? path : `https://api.github.com${path}`;
        const args = [root.curlBin, "-sS", "-X", method,
            "-w", "\nHTTP_STATUS:%{http_code}",
            "-H", `Authorization: Bearer ${root._ghToken}`,
            "-H", "Accept: application/vnd.github+json",
            "-H", "X-GitHub-Api-Version: 2022-11-28",
            "-H", "User-Agent: ii-windows-presets"];
        if (bodyObj !== null)
            args.push("-H", "Content-Type: application/json", "--data-binary", "@-");
        args.push(url);
        ghApiProc.hasBody = bodyObj !== null;
        ghApiProc.bodyText = bodyObj !== null ? JSON.stringify(bodyObj) : "";
        ghApiProc.command = args;
        ghApiProc.running = true;
    }

    Process {
        id: ghApiProc
        property bool hasBody: false
        property string bodyText: ""
        stdout: StdioCollector { id: ghApiOut }
        onRunningChanged: {
            if (ghApiProc.running && ghApiProc.hasBody) {
                ghApiProc.stdinEnabled = true;
                ghApiProc.write(ghApiProc.bodyText);
                ghApiProc.stdinEnabled = false;
            }
        }
        onExited: code => {
            const parsed = root._parseGhResponse(ghApiOut.text);
            const cb = root._ghApiCallback;
            root._ghApiCallback = null;
            if (cb)
                cb(parsed.status, parsed.body);
        }
    }

    function _base64File(path, callback) {
        b64Proc.onDoneCb = callback;
        if (Platform.isWindows) {
            b64Proc.command = ["powershell.exe", "-NoProfile", "-Command", `[Convert]::ToBase64String([IO.File]::ReadAllBytes('${path.replace(/'/g, "''")}'))`];
        } else {
            b64Proc.command = ["bash", "-c", `base64 -w0 ${root.shQuoteLinux(path)}`];
        }
        b64Proc.running = true;
    }

    Process {
        id: b64Proc
        property var onDoneCb: null
        stdout: StdioCollector { id: b64Out }
        onExited: code => {
            const cb = b64Proc.onDoneCb;
            b64Proc.onDoneCb = null;
            if (cb)
                cb(code === 0 ? b64Out.text.trim() : null);
        }
    }

    property string _branchForkRepo: ""
    property int _branchWaitTicks: 0

    function _ghEnsureBranch(prefix, onReady, onError) {
        const owner = root.githubRepo.split("/")[0];
        const repoName = root.githubRepo.split("/")[1];
        root._branchForkRepo = root.githubLogin.toLowerCase() === owner.toLowerCase() ? root.githubRepo : `${root.githubLogin}/${repoName}`;
        const afterForkReady = () => {
            root._ghApi("GET", `/repos/${root._branchForkRepo}/git/ref/heads/main`, null, (status, body) => {
                if (status !== 200 || !body?.object?.sha) {
                    onError(Translation.tr("Could not read the gallery repository"));
                    return;
                }
                const branch = `${prefix}-${Date.now()}`;
                root._ghApi("POST", `/repos/${root._branchForkRepo}/git/refs`, { ref: `refs/heads/${branch}`, sha: body.object.sha }, status2 => {
                    if (status2 !== 201) {
                        onError(Translation.tr("Could not create a branch"));
                        return;
                    }
                    onReady(root._branchForkRepo, branch);
                });
            });
        };
        if (root._branchForkRepo === root.githubRepo) {
            afterForkReady();
            return;
        }
        root._ghApi("POST", `/repos/${root.githubRepo}/forks`, null, () => {
            root._branchWaitTicks = 0;
            root._branchWaitForkReady(afterForkReady, onError);
        });
    }

    function _branchWaitForkReady(afterForkReady, onError) {
        root._ghApi("GET", `/repos/${root._branchForkRepo}`, null, status => {
            if (status === 200) {
                root._ghApi("POST", `/repos/${root._branchForkRepo}/merge-upstream`, { branch: "main" }, () => afterForkReady());
                return;
            }
            root._branchWaitTicks++;
            if (root._branchWaitTicks > 10) {
                onError(Translation.tr("Could not prepare your fork"));
                return;
            }
            branchForkWaitTimer.onReadyCb = afterForkReady;
            branchForkWaitTimer.onErrorCb = onError;
            branchForkWaitTimer.restart();
        });
    }

    Timer {
        id: branchForkWaitTimer
        interval: 2000
        property var onReadyCb: null
        property var onErrorCb: null
        onTriggered: root._branchWaitForkReady(branchForkWaitTimer.onReadyCb, branchForkWaitTimer.onErrorCb)
    }

    property bool uploadGuideOpen: false
    property string uploadGuideName: ""
    property string _pubPreviewPath: ""
    property string _pubName: ""
    property string _pubForkRepo: ""
    property string _pubBranch: ""
    property string _pubStagingDir: ""
    property var _pubFileNames: []
    property int _pubUploadIndex: 0

    function publish(name) {
        if (!Config.options.profile.uploadGuideSeen) {
            root.uploadGuideName = name;
            root.uploadGuideOpen = true;
            return;
        }
        root.pickPreviewRequested(name);
    }

    function confirmUploadGuide() {
        Config.options.profile.uploadGuideSeen = true;
        root.uploadGuideOpen = false;
        root.pickPreviewRequested(root.uploadGuideName);
    }

    function cancelUploadGuide() {
        root.uploadGuideOpen = false;
    }

    function publishWithPreview(name, previewPath) {
        root.githubBusy = true;
        root.githubError = "";
        root._pubPreviewPath = previewPath || "";
        root._withGithubToken(() => root._beginPublish(name));
    }

    function _beginPublish(name) {
        root._prepareExportFolder(name, root._pubPreviewPath, (stagingDir, names) => {
            root._ghEnsureBranch(`preset/${name}`, (repo, branch) => {
                root._pubForkRepo = repo;
                root._pubBranch = branch;
                root._pubStagingDir = stagingDir;
                root._pubFileNames = names;
                root._pubName = name;
                root._pubUploadIndex = 0;
                root._pubUploadNext();
            }, message => {
                root.githubBusy = false;
                root.githubError = message;
                root._removeStagingDir(stagingDir);
            });
        }, message => {
            root.githubBusy = false;
            root.githubError = message;
        });
    }

    function _pubUploadNext() {
        if (root._pubUploadIndex >= root._pubFileNames.length) {
            root._pubCreatePr();
            return;
        }
        const fileName = root._pubFileNames[root._pubUploadIndex];
        root._pubUploadIndex++;
        root._pubUploadFile(fileName, () => root._pubUploadNext());
    }

    function _pubUploadFile(fileName, onDone) {
        const localPath = `${root._pubStagingDir}/${fileName}`;
        const repoPath = `presets/${root._pubName}/${fileName}`;
        root._ghApi("GET", `/repos/${root._pubForkRepo}/contents/${repoPath}?ref=${root._pubBranch}`, null, (status, body) => {
            const sha = status === 200 ? body?.sha : undefined;
            root._base64File(localPath, content => {
                if (content === null) {
                    onDone();
                    return;
                }
                const payload = { message: `Add preset ${root._pubName}`, content: content, branch: root._pubBranch };
                if (sha)
                    payload.sha = sha;
                root._ghApi("PUT", `/repos/${root._pubForkRepo}/contents/${repoPath}`, payload, () => onDone());
            });
        });
    }

    function _pubCreatePr() {
        root._ghApi("POST", `/repos/${root.githubRepo}/pulls`, {
            title: `Preset: ${root._pubName}`,
            head: `${root.githubLogin}:${root._pubBranch}`,
            base: "main",
            body: `Shared from the shell by @${root.githubLogin}.`
        }, (status, body) => {
            root.githubBusy = false;
            root._removeStagingDir(root._pubStagingDir);
            if (status === 201 && body?.html_url) {
                root.rememberShared(root._pubName);
                root.githubError = "";
                Qt.openUrlExternally(body.html_url);
                root.published(root._pubName, body.html_url);
            } else {
                root.githubError = Translation.tr("Could not open the pull request");
            }
        });
    }

    property string _unshareName: ""
    property string _unshareRepo: ""
    property string _unshareBranch: ""
    property var _unshareDeleteQueue: []

    function unpublish(name) {
        root.githubBusy = true;
        root.githubError = "";
        root._withGithubToken(() => {
            root._ghApi("GET", `/repos/${root.githubRepo}/contents/presets/${name}?ref=main`, null, status => {
                if (status === 404) {
                    root.githubBusy = false;
                    root.forgetShared(name);
                    root.githubError = Translation.tr("\"%1\" is not in the gallery").arg(name);
                    return;
                }
                root._unshareCheckOwner(name);
            });
        });
    }

    function _unshareCheckOwner(name) {
        root._ghApi("GET", `/repos/${root.githubRepo}/contents/presets/${name}/meta.json?ref=main`, null, (status, body) => {
            let author = "";
            if (status === 200 && body?.content) {
                try {
                    author = JSON.parse(root._b64Decode(body.content))?.author ?? "";
                } catch (e) {}
            }
            if (author !== "") {
                root._unshareVerifyAndRemove(name, author);
                return;
            }
            root._ghApi("GET", `/repos/${root.githubRepo}/commits?path=presets/${name}&per_page=100`, null, (status2, list) => {
                let first = "";
                if (Array.isArray(list)) {
                    for (let i = list.length - 1; i >= 0; i--) {
                        const login = list[i]?.author?.login;
                        if (login) {
                            first = login;
                            break;
                        }
                    }
                }
                root._unshareVerifyAndRemove(name, first);
            });
        });
    }

    function _unshareVerifyAndRemove(name, author) {
        if (author === "" || author.toLowerCase() !== root.githubLogin.toLowerCase()) {
            root.githubBusy = false;
            root.githubError = Translation.tr("\"%1\" belongs to someone else").arg(name);
            return;
        }
        root._ghEnsureBranch(`preset/remove-${name}`, (repo, branch) => {
            root._ghApi("GET", `/repos/${repo}/contents/presets/${name}?ref=${branch}`, null, (status, list) => {
                if (!Array.isArray(list)) {
                    root.githubBusy = false;
                    root.githubError = Translation.tr("Could not read the preset folder");
                    return;
                }
                root._unshareRepo = repo;
                root._unshareBranch = branch;
                root._unshareName = name;
                root._unshareDeleteQueue = list.slice();
                root._unshareDeleteNext();
            });
        }, message => {
            root.githubBusy = false;
            root.githubError = message;
        });
    }

    function _unshareDeleteNext() {
        if (root._unshareDeleteQueue.length === 0) {
            root._unshareCreatePr();
            return;
        }
        const entry = root._unshareDeleteQueue.shift();
        root._ghApi("DELETE", `/repos/${root._unshareRepo}/contents/${entry.path}`, { message: `Remove preset ${root._unshareName}`, sha: entry.sha, branch: root._unshareBranch }, () => root._unshareDeleteNext());
    }

    function _unshareCreatePr() {
        root._ghApi("POST", `/repos/${root.githubRepo}/pulls`, {
            title: `Remove preset: ${root._unshareName}`,
            head: `${root.githubLogin}:${root._unshareBranch}`,
            base: "main",
            body: `Removed from the gallery by its author, @${root.githubLogin}.`
        }, (status, body) => {
            root.githubBusy = false;
            if (status === 201 && body?.html_url) {
                root.forgetShared(root._unshareName);
                Qt.openUrlExternally(body.html_url);
                root.unpublished(root._unshareName, body.html_url);
            } else {
                root.githubError = Translation.tr("Could not open the pull request");
            }
        });
    }
}

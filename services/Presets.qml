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

    property list<string> lastSkippedKeys: []

    readonly property var skippedRoots: ["windowsPort", "policies"]
    readonly property var spicyKeys: [
        "background.konachanSpicy",
        "background.konachanExtraTags",
        "wallpaperSelector.wallhavenPurity",
        "wallpaperSelector.wallhavenApiKey"
    ]
    readonly property var sensitiveNamePattern: /(api[-_]?key|token|secret|credential|password|useragent)/i

    Component.onCompleted: presetsDirMarker.setText("")

    FileView {
        id: presetsDirMarker
        path: `${Directories.userPresetsPath}/.keep`
        printErrors: false
    }

    FolderListModel {
        id: presetsFolderModel
        folder: Qt.resolvedUrl(Directories.userPresetsPath)
        showDirs: false
        nameFilters: ["*.json"]
    }

    FolderListModel {
        id: onlinePresetsFolderModel
        folder: Qt.resolvedUrl(Directories.onlinePresetsPath)
        showDirs: false
        nameFilters: ["*.json"]
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

    function previewImage(data) {
        return data?.background?.wallpaperPath ?? "";
    }

    function isSkippedKey(dottedKey) {
        const lower = dottedKey.toLowerCase();
        for (const rootKey of root.skippedRoots) {
            if (lower === rootKey.toLowerCase() || lower.startsWith(rootKey.toLowerCase() + "."))
                return true;
        }
        for (const spicy of root.spicyKeys) {
            if (lower === spicy.toLowerCase())
                return true;
        }
        if (root.sensitiveNamePattern.test(dottedKey.replace(/[._-]/g, "")))
            return true;
        return false;
    }

    function existsInConfig(dottedKey) {
        const parts = dottedKey.split(".");
        let node = Config.options;
        for (const part of parts) {
            if (node === null || typeof node !== "object" || !(part in node))
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
        return String(rawName).trim().replace(/[\\/:*?"<>|]/g, "_").replace(/\s+/g, "_");
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
        if (root._pendingSaveDescription !== "")
            filtered._presetMeta = { description: root._pendingSaveDescription };
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
    }

    function remove(name) {
        root._deletePath(`${Directories.userPresetsPath}/${name}.json`, root.refresh);
    }

    function removeOnline(name) {
        root._deletePath(`${Directories.onlinePresetsPath}/${name}.json`, root.refreshOnline);
    }

    function _deletePath(path, onDone) {
        deleteProc.onDone = onDone;
        const escaped = path.replace(/'/g, "''");
        deleteProc.command = ["powershell", "-NoProfile", "-WindowStyle", "Hidden", "-Command",
            `Remove-Item -LiteralPath '${escaped}' -Force -ErrorAction SilentlyContinue`];
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

    function openPresetsFolder() {
        Qt.openUrlExternally(Directories.userPresetsPath);
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
}

pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string curlBin: Platform.isWindows ? "curl.exe" : "curl"
    readonly property string repo: "nunreasonable/ii-windows"
    readonly property string setupAssetName: "ii-windows-setup.exe"
    readonly property string apiUrl: Quickshell.env("IIW_SELF_UPDATE_RELEASE_JSON") || `https://api.github.com/repos/${root.repo}/releases/latest`
    readonly property string installedVersionOverride: Quickshell.env("IIW_SELF_UPDATE_INSTALLED_VERSION") || ""
    readonly property int checkIntervalMs: 24 * 60 * 60 * 1000

    property string installedVersion: root.installedVersionOverride
    property bool checking: false
    property bool downloading: false
    property string lastError: ""
    property string downloadDest: ""

    property string latestVersion: ""
    property string releaseName: ""
    property string htmlUrl: ""
    property string setupUrl: ""
    property int setupSize: 0
    property double lastCheckedAt: 0
    property string notifiedVersion: ""

    readonly property bool updateAvailable: Platform.isWindows
        && root.installedVersion !== ""
        && root.latestVersion !== ""
        && root._isNewer(root.latestVersion, root.installedVersion)

    function _parseVersion(text) {
        if (!text) return null;
        let t = text.toString().trim();
        if (t.length > 0 && (t[0] === "v" || t[0] === "V")) t = t.slice(1);
        let core = t;
        let pre = null;
        const dashIdx = t.indexOf("-");
        if (dashIdx !== -1) {
            core = t.slice(0, dashIdx);
            pre = t.slice(dashIdx + 1);
        }
        const plusIdx = core.indexOf("+");
        if (plusIdx !== -1) core = core.slice(0, plusIdx);
        if (core.length === 0) return null;
        const parts = [];
        for (const piece of core.split(".")) {
            if (!/^\d+$/.test(piece)) return null;
            parts.push(parseInt(piece, 10));
        }
        return { parts: parts, pre: pre };
    }

    function _compareVersions(a, b) {
        const len = Math.max(a.parts.length, b.parts.length);
        for (let i = 0; i < len; i++) {
            const pa = a.parts[i] ?? 0;
            const pb = b.parts[i] ?? 0;
            if (pa !== pb) return pa < pb ? -1 : 1;
        }
        if (a.pre === null && b.pre === null) return 0;
        if (a.pre === null) return 1;
        if (b.pre === null) return -1;
        return a.pre < b.pre ? -1 : (a.pre > b.pre ? 1 : 0);
    }

    function _isNewer(candidate, installed) {
        const c = root._parseVersion(candidate);
        const i = root._parseVersion(installed);
        if (!c || !i) return false;
        return root._compareVersions(c, i) > 0;
    }

    function _parseReleaseName(name, tag) {
        const trimmedName = (name || "").trim();
        if (trimmedName.length > 0) {
            const idx = trimmedName.indexOf("—");
            if (idx !== -1) {
                const after = trimmedName.slice(idx + 1).trim();
                if (after.length > 0) return after;
            }
            return trimmedName;
        }
        return (tag || "").replace(/^v/i, "");
    }

    function refresh() {
        if (!Platform.isWindows || root.checking) return;
        root.checking = true;
        root.lastError = "";
        checkProc.command = [root.curlBin, "-sS", "--max-time", "10", "-w", "\nHTTP_STATUS:%{http_code}",
            "-H", "Accept: application/vnd.github+json",
            "-H", "User-Agent: ii-windows-quickshell",
            root.apiUrl];
        checkProc.running = true;
    }

    function maybeAutoCheck() {
        if (!Platform.isWindows || root.checking) return;
        if (Date.now() - root.lastCheckedAt >= root.checkIntervalMs) root.refresh();
    }

    function startUpdate() {
        if (!Platform.isWindows || root.setupUrl === "" || root.downloading) return;
        root.downloading = true;
        root.lastError = "";
        root.downloadDest = `${Directories.selfUpdateDownloadDir}/${root.setupAssetName}`;
        downloadProc.command = [root.curlBin, "--create-dirs", "-fsSL", "--max-time", "180", "-o", root.downloadDest,
            "-w", "SIZE:%{size_download}", root.setupUrl];
        downloadProc.running = true;
    }

    function _maybeNotify() {
        if (!Config.ready || !Config.options.windowsPort.selfUpdate.notify) return;
        if (!root.updateAvailable || root.notifiedVersion === root.latestVersion) return;
        Notifications.sendDesktop(
            Translation.tr("ii-windows update available"),
            Translation.tr("%1 \"%2\" is ready to install.").arg(root.latestVersion).arg(root.releaseName),
            []
        );
        root.notifiedVersion = root.latestVersion;
    }

    function _saveCache() {
        if (!Platform.isWindows) return;
        cacheFileView.setText(JSON.stringify({
            lastCheckedAt: root.lastCheckedAt,
            latestVersion: root.latestVersion,
            releaseName: root.releaseName,
            htmlUrl: root.htmlUrl,
            setupUrl: root.setupUrl,
            setupSize: root.setupSize,
            notifiedVersion: root.notifiedVersion
        }));
    }

    Component.onCompleted: {
        if (!Platform.isWindows) return;
        manifestFileView.reload();
        cacheFileView.reload();
    }

    FileView {
        id: cacheFileView
        path: Platform.isWindows ? Directories.selfUpdateCachePath : ""
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(cacheFileView.text());
                root.latestVersion = data.latestVersion ?? "";
                root.releaseName = data.releaseName ?? "";
                root.htmlUrl = data.htmlUrl ?? "";
                root.setupUrl = data.setupUrl ?? "";
                root.setupSize = data.setupSize ?? 0;
                root.lastCheckedAt = data.lastCheckedAt ?? 0;
                root.notifiedVersion = data.notifiedVersion ?? "";
            } catch (e) {}
            root.maybeAutoCheck();
        }
        onLoadFailed: root.maybeAutoCheck()
    }

    FileView {
        id: manifestFileView
        path: (Platform.isWindows && root.installedVersionOverride === "") ? Directories.installManifestPath : ""
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(manifestFileView.text());
                if (data.version) {
                    root.installedVersion = data.version;
                    return;
                }
            } catch (e) {}
            versionFileView.reload();
        }
        onLoadFailed: versionFileView.reload()
    }

    FileView {
        id: versionFileView
        path: (Platform.isWindows && root.installedVersionOverride === "") ? Directories.installVersionPath : ""
        printErrors: false
        onLoaded: {
            const text = versionFileView.text().trim();
            if (text.length > 0) root.installedVersion = text.replace(/^v/i, "");
        }
    }

    Process {
        id: checkProc
        stdout: StdioCollector { id: checkCollector }
        onExited: (exitCode, exitStatus) => {
            root.checking = false;
            root.lastCheckedAt = Date.now();
            const raw = checkCollector.text;
            const statusMatch = raw.match(/HTTP_STATUS:(\d+)\s*$/);
            const body = statusMatch ? raw.slice(0, statusMatch.index) : raw;
            const status = statusMatch ? statusMatch[1] : "";
            if (exitCode !== 0 || status !== "200") {
                root.lastError = status
                    ? Translation.tr("GitHub answered HTTP %1.").arg(status)
                    : Translation.tr("Could not reach GitHub.");
                root._saveCache();
                return;
            }
            try {
                const json = JSON.parse(body);
                if (json.prerelease) {
                    root._saveCache();
                    return;
                }
                const tag = json.tag_name ?? "";
                root.latestVersion = tag.replace(/^v/i, "");
                root.releaseName = root._parseReleaseName(json.name ?? "", tag);
                root.htmlUrl = json.html_url ?? "";
                const assets = json.assets ?? [];
                const setupAsset = assets.find(a => (a.name ?? "").toLowerCase() === root.setupAssetName);
                root.setupUrl = setupAsset ? (setupAsset.browser_download_url ?? "") : "";
                root.setupSize = setupAsset ? (setupAsset.size ?? 0) : 0;
                root.lastError = "";
                root._maybeNotify();
                root._saveCache();
            } catch (e) {
                root.lastError = Translation.tr("Could not parse GitHub's response.");
                root._saveCache();
            }
        }
    }

    Process {
        id: downloadProc
        stdout: StdioCollector { id: downloadCollector }
        onExited: (exitCode, exitStatus) => {
            root.downloading = false;
            if (exitCode !== 0) {
                root.lastError = Translation.tr("Couldn't download the update.");
                return;
            }
            const sizeMatch = downloadCollector.text.match(/SIZE:(\d+)/);
            const downloadedSize = sizeMatch ? parseInt(sizeMatch[1], 10) : -1;
            if (root.setupSize > 0 && downloadedSize !== root.setupSize) {
                root.lastError = Translation.tr("The downloaded file doesn't match the size GitHub reported.");
                return;
            }
            Quickshell.execDetached([root.downloadDest, "--update"]);
        }
    }
}

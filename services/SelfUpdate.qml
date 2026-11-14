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
    readonly property string apiOverride: Quickshell.env("IIW_SELF_UPDATE_RELEASE_JSON") || ""
    readonly property string apiUrl: root.apiOverride !== "" ? root.apiOverride
        : root.installedIsPrerelease ? `https://api.github.com/repos/${root.repo}/releases?per_page=20`
        : `https://api.github.com/repos/${root.repo}/releases/latest`
    readonly property string installedVersionOverride: Quickshell.env("IIW_SELF_UPDATE_INSTALLED_VERSION") || ""
    readonly property int recheckIntervalMs: 24 * 60 * 60 * 1000
    readonly property var notifyIdentity: ["-a", "ii-windows", "-i", "illogical-impulse"]

    property string installedVersion: root.installedVersionOverride
    readonly property bool installedIsPrerelease: root._preRank(root._parseVersion(root.installedVersion)?.pre ?? null) < 0
    property bool checking: false
    property bool downloading: false
    property string lastError: ""
    property string downloadDest: ""

    property string latestVersion: ""
    property string releaseName: ""
    property string htmlUrl: ""
    property string setupUrl: ""
    property int setupSize: 0
    property string setupDigest: ""
    readonly property string setupUrlPrefix: `https://github.com/${root.repo}/releases/download/`
    property double lastCheckedAt: 0
    property string stableVersion: ""
    readonly property bool canGoBackToStable: Platform.isWindows && root.installedIsPrerelease

    property bool _cacheDone: false
    property bool _versionDone: root.installedVersionOverride !== ""
    property bool _startupChecked: false
    property string _sessionNotifiedVersion: ""
    property int _notificationId: -1
    property bool _updateFromNotification: false

    property string installedPatch: ""
    property string failedPatch: ""
    property int patchNumber: 0
    property string patchUrl: ""
    property string patchDigest: ""
    property int patchSize: 0
    property bool patching: false
    property string _patchNotified: ""
    property int _patchNotificationId: -1
    readonly property int installedPatchNumber: {
        const m = root.installedPatch.match(/^(.+)-p(\d+)$/);
        return m && m[1] === root.installedVersion ? parseInt(m[2], 10) : 0;
    }
    readonly property string patchLabel: root.patchNumber > 0 ? `${root.installedVersion}-p${root.patchNumber}` : ""
    readonly property bool patchAvailable: Platform.isWindows
        && !root.updateAvailable
        && root.patchNumber > root.installedPatchNumber
        && root.patchLabel !== root.failedPatch
        && root.patchDigest !== ""
        && (root.patchUrl.startsWith(root.setupUrlPrefix) || root.apiOverride !== "")
    readonly property string displayVersion: root.installedPatchNumber > 0 ? `${root.installedVersion}-p${root.installedPatchNumber}` : root.installedVersion

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

    function _comparePre(a, b) {
        const xs = a.split(".");
        const ys = b.split(".");
        for (let i = 0; i < Math.min(xs.length, ys.length); i++) {
            const xNum = /^\d+$/.test(xs[i]);
            const yNum = /^\d+$/.test(ys[i]);
            if (xNum && yNum) {
                const d = parseInt(xs[i], 10) - parseInt(ys[i], 10);
                if (d !== 0) return d < 0 ? -1 : 1;
            } else if (xNum !== yNum) {
                return xNum ? -1 : 1;
            } else if (xs[i] !== ys[i]) {
                return xs[i] < ys[i] ? -1 : 1;
            }
        }
        return xs.length === ys.length ? 0 : (xs.length < ys.length ? -1 : 1);
    }

    function _preRank(pre) {
        if (pre === null) return 0;
        return /^fix\d+$/i.test(pre) ? 1 : -1;
    }

    function _compareVersions(a, b) {
        const len = Math.max(a.parts.length, b.parts.length);
        for (let i = 0; i < len; i++) {
            const pa = a.parts[i] ?? 0;
            const pb = b.parts[i] ?? 0;
            if (pa !== pb) return pa < pb ? -1 : 1;
        }
        const ra = root._preRank(a.pre);
        const rb = root._preRank(b.pre);
        if (ra !== rb) return ra < rb ? -1 : 1;
        if (ra === 0) return 0;
        if (ra === 1) {
            const d = parseInt(a.pre.slice(3), 10) - parseInt(b.pre.slice(3), 10);
            return d === 0 ? 0 : (d < 0 ? -1 : 1);
        }
        return root._comparePre(a.pre, b.pre);
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

    function _pickStable(json) {
        if (!Array.isArray(json)) return "";
        let best = null;
        for (const release of json) {
            if (release.draft || release.prerelease) continue;
            const version = root._parseVersion(release.tag_name ?? "");
            if (!version || root._preRank(version.pre) < 0) continue;
            if (best === null || root._compareVersions(version, best.version) > 0)
                best = { version: version, tag: release.tag_name };
        }
        return best ? best.tag.replace(/^v/i, "") : "";
    }

    function goBackToStable() {
        if (!root.canGoBackToStable) return;
        const setup = `${Directories.installDir}/ii-windows-setup.exe`.replace(/\//g, "\\");
        Quickshell.execDetached([setup, "--update", "--stable"]);
    }

    function _pickRelease(json) {
        if (!Array.isArray(json)) {
            if (json.draft || (json.prerelease && !root.installedIsPrerelease)) return null;
            return json;
        }
        let best = null;
        let bestVersion = null;
        for (const release of json) {
            if (release.draft || (release.prerelease && !root.installedIsPrerelease)) continue;
            const version = root._parseVersion(release.tag_name ?? "");
            if (!version) continue;
            if (best === null || root._compareVersions(version, bestVersion) > 0) {
                best = release;
                bestVersion = version;
            }
        }
        return best;
    }

    function load() {}

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

    function _startupCheck() {
        if (!Platform.isWindows || root._startupChecked || !root._cacheDone || !root._versionDone || !Config.ready) return;
        root._startupChecked = true;
        if (Config.options.windowsPort.selfUpdate.enableCheck) root.refresh();
    }

    function startUpdate() {
        if (!Platform.isWindows || root.setupUrl === "" || root.downloading) return;
        if (!root.setupUrl.startsWith(root.setupUrlPrefix)) {
            root.lastError = Translation.tr("Couldn't download the update.");
            return;
        }
        root.downloading = true;
        root.lastError = "";
        root.downloadDest = `${Directories.selfUpdateDownloadDir}/${root.setupAssetName}`;
        downloadProc.command = [root.curlBin, "--create-dirs", "-fsSL", "--max-time", "180", "-o", root.downloadDest,
            "-w", "SIZE:%{size_download}", root.setupUrl];
        downloadProc.running = true;
    }

    function _updateFromNotificationAction() {
        if (root.downloading) return;
        root._updateFromNotification = true;
        Notifications.sendDesktop(Translation.tr("ii-windows update"), Translation.tr("Downloading the update…"), [...root.notifyIdentity, "-e"]);
        root.startUpdate();
    }

    function _maybeNotify() {
        if (!Config.ready || !Config.options.windowsPort.selfUpdate.notify) return;
        if (!root.updateAvailable || root._sessionNotifiedVersion === root.latestVersion) return;
        root._sessionNotifiedVersion = root.latestVersion;
        const actions = [...root.notifyIdentity];
        if (root.setupUrl !== "") actions.push("-A", `update=${Translation.tr("Update")}`);
        if (root.htmlUrl !== "") actions.push("-A", `notes=${Translation.tr("What's new")}`);
        root._notificationId = Notifications.sendDesktop(
            Translation.tr("ii-windows update available"),
            Translation.tr("%1 \"%2\" is ready to install. Nothing changes until you confirm it in the setup.").arg(root.latestVersion).arg(root.releaseName),
            actions
        ) ?? -1;
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
            setupDigest: root.setupDigest
        }));
    }

    function _pickPatch(assets) {
        const prefix = `ii-qml-${root.installedVersion}-p`;
        let best = null;
        let bestNumber = 0;
        for (const asset of assets) {
            const name = String(asset.name ?? "");
            if (!name.startsWith(prefix) || !name.endsWith(".zip")) continue;
            const number = parseInt(name.slice(prefix.length, -4), 10);
            if (!(number > bestNumber) || String(number) !== name.slice(prefix.length, -4)) continue;
            best = asset;
            bestNumber = number;
        }
        root.patchNumber = best ? bestNumber : 0;
        root.patchUrl = best ? String(best.browser_download_url ?? "") : "";
        root.patchSize = best ? (best.size ?? 0) : 0;
        root.patchDigest = best ? String(best.digest ?? "").replace(/^sha256:/i, "").toLowerCase() : "";
    }

    function _maybeNotifyPatch() {
        if (!Config.ready || !Config.options.windowsPort.selfUpdate.notify) return;
        if (!root.patchAvailable || root._patchNotified === root.patchLabel) return;
        root._patchNotified = root.patchLabel;
        root._patchNotificationId = Notifications.sendDesktop(
            Translation.tr("ii-windows fix available"),
            Translation.tr("A small fix for %1 is ready. Applying it restarts the shell for a moment; nothing else is reinstalled.").arg(root.installedVersion),
            [...root.notifyIdentity, "-A", `patch=${Translation.tr("Apply fix")}`]
        ) ?? -1;
    }

    function applyPatch() {
        if (!root.patchAvailable || root.patching || root.downloading) return;
        root.patching = true;
        root.lastError = "";
        root.downloadDest = `${Directories.selfUpdateDownloadDir}/ii-qml-${root.patchLabel}.zip`;
        patchDownloadProc.label = root.patchLabel;
        patchDownloadProc.digest = root.patchDigest;
        patchDownloadProc.command = [root.curlBin, "--create-dirs", "-fsSL", "--max-time", "120", "-o", root.downloadDest, root.patchUrl];
        patchDownloadProc.running = true;
    }

    function _patchFailed(message) {
        root.patching = false;
        root.lastError = message;
        Notifications.sendDesktop(Translation.tr("ii-windows fix"), message, root.notifyIdentity);
    }

    Process {
        id: patchDownloadProc
        property string label: ""
        property string digest: ""
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root._patchFailed(Translation.tr("Couldn't download the fix."));
                return;
            }
            patchHashProc.label = patchDownloadProc.label;
            patchHashProc.digest = patchDownloadProc.digest;
            patchHashProc.zip = root.downloadDest;
            patchHashProc.command = ["certutil.exe", "-hashfile", root.downloadDest.replace(/\//g, "\\"), "SHA256"];
            patchHashProc.running = true;
        }
    }

    Process {
        id: patchHashProc
        property string label: ""
        property string digest: ""
        property string zip: ""
        stdout: StdioCollector { id: patchHashCollector }
        onExited: (exitCode, exitStatus) => {
            const found = (patchHashCollector.text.match(/^[0-9a-f ]{64,95}$/im) ?? [""])[0].replace(/\s+/g, "").toLowerCase();
            if (exitCode !== 0 || found !== patchHashProc.digest) {
                root._patchFailed(Translation.tr("The downloaded fix doesn't match the checksum GitHub reported."));
                return;
            }
            root._runPatch(patchHashProc.zip, patchHashProc.label);
        }
    }

    function _runPatch(zip, label) {
        const win = path => FileUtils.trimFileProtocol(String(path)).replace(/\//g, "\\").replace(/\\+$/, "");
        const live = win(Quickshell.shellPath(""));
        Quickshell.execDetached(["powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden",
            "-File", win(`${Directories.scriptPath}/update/apply-qml-patch.ps1`),
            "-Zip", win(zip), "-Label", label, "-InstallDir", win(Directories.installDir), "-LiveDir", live]);
    }

    FileView {
        id: patchFileView
        path: Platform.isWindows ? `${Directories.installDir}/PATCH` : ""
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.installedPatch = patchFileView.text().trim()
        onLoadFailed: root.installedPatch = ""
    }

    FileView {
        id: failedPatchFileView
        path: Platform.isWindows ? `${Directories.installDir}/PATCH-FAILED` : ""
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.failedPatch = failedPatchFileView.text().trim()
        onLoadFailed: root.failedPatch = ""
    }

    Component.onCompleted: {
        if (!Platform.isWindows) return;
        patchFileView.reload();
        failedPatchFileView.reload();
        manifestFileView.reload();
        cacheFileView.reload();
    }

    Connections {
        target: Platform.isWindows ? Notifications : null
        function onDesktopActionInvoked(id, action) {
            if (id === root._patchNotificationId && action === "patch") {
                root.applyPatch();
                return;
            }
            if (id !== root._notificationId) return;
            if (action === "update") root._updateFromNotificationAction();
            else if (action === "notes" && root.htmlUrl !== "") Qt.openUrlExternally(root.htmlUrl);
        }
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (!Config.ready) return;
            root._startupCheck();
            if (!root.checking) root._maybeNotify();
        }
    }

    Timer {
        running: Platform.isWindows && root._startupChecked && Config.ready && Config.options.windowsPort.selfUpdate.enableCheck
        interval: root.recheckIntervalMs
        repeat: true
        onTriggered: root.refresh()
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
                root.setupDigest = data.setupDigest ?? "";
                root.lastCheckedAt = data.lastCheckedAt ?? 0;
            } catch (e) {}
            root._cacheDone = true;
            root._startupCheck();
        }
        onLoadFailed: {
            root._cacheDone = true;
            root._startupCheck();
        }
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
                    root._versionDone = true;
                    root._startupCheck();
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
            root._versionDone = true;
            root._startupCheck();
        }
        onLoadFailed: {
            root._versionDone = true;
            root._startupCheck();
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
            const localTest = root.apiOverride.startsWith("file:") && status === "000";
            if (exitCode !== 0 || (status !== "200" && !localTest)) {
                root.lastError = status
                    ? Translation.tr("GitHub answered HTTP %1.").arg(status)
                    : Translation.tr("Could not reach GitHub.");
                root._maybeNotify();
                root._saveCache();
                return;
            }
            try {
                const parsed = JSON.parse(body);
                const stable = root._pickStable(parsed);
                if (stable !== "") root.stableVersion = stable;
                const release = root._pickRelease(parsed);
                if (release) {
                    const tag = release.tag_name ?? "";
                    root.latestVersion = tag.replace(/^v/i, "");
                    root.releaseName = root._parseReleaseName(release.name ?? "", tag);
                    root.htmlUrl = release.html_url ?? "";
                    const assets = release.assets ?? [];
                    const setupAsset = assets.find(a => (a.name ?? "").toLowerCase() === root.setupAssetName);
                    root.setupUrl = setupAsset ? (setupAsset.browser_download_url ?? "") : "";
                    root.setupSize = setupAsset ? (setupAsset.size ?? 0) : 0;
                    root.setupDigest = setupAsset ? String(setupAsset.digest ?? "").replace(/^sha256:/i, "").toLowerCase() : "";
                    root._pickPatch(tag.replace(/^v/i, "") === root.installedVersion ? assets : []);
                }
                root.lastError = "";
                root._maybeNotify();
                root._maybeNotifyPatch();
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
            const fromNotification = root._updateFromNotification;
            root._updateFromNotification = false;
            if (exitCode !== 0) {
                root.lastError = Translation.tr("Couldn't download the update.");
                if (fromNotification) Notifications.sendDesktop(Translation.tr("ii-windows update"), root.lastError, root.notifyIdentity);
                return;
            }
            const sizeMatch = downloadCollector.text.match(/SIZE:(\d+)/);
            const downloadedSize = sizeMatch ? parseInt(sizeMatch[1], 10) : -1;
            if (root.setupSize > 0 && downloadedSize !== root.setupSize) {
                root.lastError = Translation.tr("The downloaded file doesn't match the size GitHub reported.");
                if (fromNotification) Notifications.sendDesktop(Translation.tr("ii-windows update"), root.lastError, root.notifyIdentity);
                return;
            }
            if (!/^[0-9a-f]{64}$/.test(root.setupDigest)) {
                Quickshell.execDetached([root.downloadDest, "--update"]);
                return;
            }
            hashProc.command = ["certutil.exe", "-hashfile", root.downloadDest.replace(/\//g, "\\"), "SHA256"];
            hashProc.notify = fromNotification;
            hashProc.running = true;
        }
    }

    Process {
        id: hashProc
        property bool notify: false
        stdout: StdioCollector { id: hashCollector }
        onExited: (exitCode, exitStatus) => {
            const found = (hashCollector.text.match(/^[0-9a-f ]{64,95}$/im) ?? [""])[0].replace(/\s+/g, "").toLowerCase();
            if (exitCode !== 0 || found !== root.setupDigest) {
                root.lastError = Translation.tr("The downloaded file doesn't match the checksum GitHub reported.");
                if (hashProc.notify) Notifications.sendDesktop(Translation.tr("ii-windows update"), root.lastError, root.notifyIdentity);
                return;
            }
            Quickshell.execDetached([root.downloadDest, "--update"]);
        }
    }
}

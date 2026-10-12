pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string provider:   "unsplash" // "unsplash" | "pexels" | "blapples" | "naive"
    property string resolution: "1080p"    // "1080p" | "2K" | "4K"
    property string query:      ""         // empty keyword = random
    property string colorGroup: ""         // naive/blapples: "" = all | "red"|"orange"|"yellow"|"green"|"blue"|"purple"
    property string category:   "general"  // unsplash: "nature"|"city"|...
    property bool   loading:    false
    property bool   appending:  false
    property int    page:       1
    property var    results:    []         // list [ {thumb, full, id, provider} ]
    property int totalPages: 0

    property var _naiveFullResults: []
    property var _blapplesFullResults: []
    property int localPageSize: 24

    signal fetched()
    signal fetchError(string message)

    readonly property string unsplashClientId: KeyringStorage.keyringData?.apiKeys?.unsplash ?? ""
    readonly property string pexelsApiKey: KeyringStorage.keyringData?.apiKeys?.pexels ?? ""

    readonly property string blapplesJsonUrl: "https://raw.githubusercontent.com/Blapples/wallpapers/main/wallpapers.json"
    readonly property string blapplesPagesBase: "https://raw.githubusercontent.com/Blapples/wallpapers/main/"
    readonly property string blapplesFullBase: "https://raw.githubusercontent.com/Blapples/wallpapers/main/"

    readonly property string naiveJsonUrl: "https://raw.githubusercontent.com/na-ive/wallpapers/gh-pages/wallpapers.json"
    readonly property string naivePagesBase: "https://raw.githubusercontent.com/na-ive/wallpapers/gh-pages/"
    readonly property string naiveFullBase: "https://raw.githubusercontent.com/na-ive/wallpapers/main/"

    readonly property var resolutionMap: ({
        "unsplash": {
            "1080p": "&w=1920&h=1080&fit=crop",
            "2K":    "&w=2560&h=1440&fit=crop",
            "4K":    "&w=3840&h=2160&fit=crop",
        },
        "pexels": {
            "1080p": "&w=1920&h=1080&fit=crop",
            "2K":    "&w=2560&h=1440&fit=crop",
            "4K":    "&w=3840&h=2160&fit=crop",
        }
    })

    function fetch() {
        if (root.loading) return;
        root.page = 1;
        root.appending = false;
        root.results = [];
        _doFetch();
    }

    function nextPage() {
        if (root.loading) return;

        if (root.provider === "naive" || root.provider === "blapples") {
            const full = root.provider === "naive" ? root._naiveFullResults : root._blapplesFullResults;
            if (root.page * root.localPageSize >= full.length) return;
            root.page += 1;
            root.appending = true;
            root.results = full.slice(0, root.page * root.localPageSize);
            root.fetched();
            return;
        }

        if (root.provider !== "unsplash" && root.totalPages > 0 && root.page >= root.totalPages) return;
        root.appending = true;
        root.page += 1;
        _doFetch();
    }

    function prevPage() {
        if (root.loading || root.page <= 1) return;

        if (root.provider === "naive" || root.provider === "blapples") {
            const full = root.provider === "naive" ? root._naiveFullResults : root._blapplesFullResults;
            root.page -= 1;
            root.appending = false;
            root.results = full.slice(0, root.page * root.localPageSize);
            return;
        }

        root.page -= 1;
        _doFetch();
    }

    function _doFetch() {
        root.loading = true;
        if (root.provider === "unsplash") {
            _fetchUnsplash();
        } else if (root.provider === "pexels") {
            _fetchPexels();
        } else if (root.provider === "blapples") {
            _fetchBlapples();
        } else if (root.provider === "naive") {
            _fetchNaive();
        }
    }

    function goToPage(n) {
        root.page = n;

        if (root.provider === "naive" || root.provider === "blapples") {
            const full = root.provider === "naive" ? root._naiveFullResults : root._blapplesFullResults;
            root.appending = false;
            root.results = full.slice(0, root.page * root.localPageSize);
            return;
        }

        _doFetch();
    }

    function _fetchUnsplash() {
        const orientation = "landscape";
        const count       = 24;
        const q           = root.query.length > 0 ? `&query=${encodeURIComponent(root.query)}` : `&query=${encodeURIComponent(root.category)}`;
        const clientId    = root.unsplashClientId;

        const url = `https://api.unsplash.com/photos/random?orientation=${orientation}&count=${count}${q}&client_id=${clientId}`;

        fetchProc.provider = "unsplash";
        fetchProc.command = ["curl", "-s", url];
        fetchProc.running = true;
    }

    function _fetchPexels() {
        const q = root.query.length > 0 ? root.query : "wallpaper landscape";
        const url = `https://api.pexels.com/v1/search?query=${encodeURIComponent(q)}&per_page=24&page=${root.page}`;
        fetchProc.provider = "pexels";
        fetchProc.command  = ["curl", "-s", "-H", `Authorization: ${root.pexelsApiKey}`, url];
        fetchProc.running  = true;
    }

    function _fetchBlapples() {
        _startLocalStream("blapples", root.blapplesJsonUrl);
    }

    function _fetchNaive() {
        _startLocalStream("naive", root.naiveJsonUrl);
    }

    function _startLocalStream(provider, url) {
        if (Platform.isWindows) {
            fullFetchProc.provider = provider;
            fullFetchProc.command = ["curl", "-sSL", "--max-time", "30", url];
            fullFetchProc.running = true;
            return;
        }
        streamProc.provider = provider;
        streamProc.items = [];
        if (provider === "naive") root._naiveFullResults = streamProc.items;
        else root._blapplesFullResults = streamProc.items;
        streamProc.command = ["python3", Quickshell.shellPath("scripts/wallpapers/stream-wallpapers.py"), url];
        streamProc.running = true;
    }

    function _matchesLocalFilters(item) {
        if (!item || !item.filename) return false;
        const q = root.query.trim().toLowerCase();
        const cg = root.colorGroup.trim().toLowerCase();
        if (q.length > 0 && !String(item.filename).toLowerCase().includes(q)) return false;
        if (cg.length > 0 && !(item.color_groups ?? []).map(g => String(g).toLowerCase()).includes(cg)) return false;
        return true;
    }

    function _pushLocalItem(item) {
        const items = streamProc.items;
        items.push(item);
        if (items.length > root.localPageSize) return;
        root.appending = items.length > 1;
        root.results = items.slice(0, root.localPageSize);
        root.fetched();
    }

    function _finishLocalList(provider, items) {
        if (provider === "naive") root._naiveFullResults = items;
        else root._blapplesFullResults = items;
        root.totalPages = Math.max(1, Math.ceil(items.length / root.localPageSize));
        root.appending = false;
        root.results = items.slice(0, root.localPageSize);
        root.fetched();
    }

    function _parseUnsplash(jsonStr) {
        try {
            const data = JSON.parse(jsonStr);

            const newItems = data.map(item => ({
                id:               item.id,
                thumb:            item.urls.small,
                full: item.urls.raw + (root.resolution === "4K" ? "&w=3840&h=2160&fit=crop&fm=jpg&q=85"
                    : root.resolution === "2K" ? "&w=2560&h=1440&fit=crop&fm=jpg&q=85"
                    : "&w=1920&h=1080&fit=crop&fm=jpg&q=85"),
                provider:         "unsplash",
                title:            item.alt_description ?? item.description ?? "",
                author:           item.user?.name ?? "",
                authorUrl:        item.user?.links?.html ?? "",
                likes:            item.likes ?? 0,
                width:            item.width ?? 0,
                height:           item.height ?? 0,
                downloadLocation: item.links?.download_location ?? "",
            }));

            root.results = root.appending ? root.results.concat(newItems) : newItems;
            root.fetched();
        } catch (e) {
            root.fetchError("Unsplash parse error: " + e);
        }
    }

    function _parsePexels(jsonStr) {
        try {
            const data = JSON.parse(jsonStr);

            root.totalPages = Math.ceil((data.total_results ?? 0) / 24);
            const newItems = data.photos.map(item => ({
                id:               String(item.id),
                thumb:            item.src.large,
                full: root.resolution === "4K" ? item.src.original + "?auto=compress&cs=tinysrgb&w=3840&h=2160&fit=crop"
                    : root.resolution === "2K" ? item.src.original + "?auto=compress&cs=tinysrgb&w=2560&h=1440&fit=crop"
                    :                            item.src.original + "?auto=compress&cs=tinysrgb&w=1920&h=1080&fit=crop",
                provider:         "pexels",
                title:            item.alt ?? "",
                author:           item.photographer ?? "",
                authorUrl:        item.photographer_url ?? "",
                likes:            0,
                width:            item.width ?? 0,
                height:           item.height ?? 0,
                avgColor:         item.avg_color ?? "",
                downloadLocation: "",
            }));

            root.results = root.appending ? root.results.concat(newItems) : newItems;
            root.fetched();
        } catch (e) {
            root.fetchError("Pexels parse error: " + e);
        }
    }

    function _mapBlapples(item) {
        const filename = String(item.filename);
        const baseName = filename.replace(/\.[^.]+$/, "");
        const dims = String(item.resolution ?? "").split("x");
        const w = parseInt(dims[0], 10) || 0;
        const h = parseInt(dims[1], 10) || 0;
        return {
            id:               baseName,
            thumb:            root.blapplesPagesBase + String(item.thumbnail ?? item.preview ?? filename).split("/").map(encodeURIComponent).join("/"),
            full:             root.blapplesFullBase + filename.split("/").map(encodeURIComponent).join("/"),
            provider:         "blapples",
            title:            baseName.replace(/[-_]+/g, " ").replace(/\b\w/g, c => c.toUpperCase()),
            author:           "",
            authorUrl:        "",
            likes:            0,
            width:            w,
            height:           h,
            avgColor:         item.color ?? "",
            colorGroups:      (item.color_groups ?? []).map(g => String(g).toLowerCase()),
            downloadLocation: "",
        };
    }

    function _mapNaive(item) {
        const filename = String(item.filename);
        const baseName = filename.replace(/\.[^.]+$/, "");
        const dims = String(item.resolution ?? "").split("x");
        const w = parseInt(dims[0], 10) || 0;
        const h = parseInt(dims[1], 10) || 0;
        return {
            id:               baseName,
            thumb:            root.naivePagesBase + String(item.thumbnail ?? item.preview ?? filename),
            full:             root.naiveFullBase + encodeURIComponent(filename),
            provider:         "naive",
            title:            baseName.replace(/[-_]+/g, " ").replace(/\b\w/g, c => c.toUpperCase()),
            author:           "",
            authorUrl:        "",
            likes:            0,
            width:            w,
            height:           h,
            avgColor:         item.color ?? "",
            colorGroups:      item.color_groups ?? [],
            downloadLocation: "",
        };
    }

    // ─── Process: Linux streaming (python3) ───
    Process {
        id: streamProc
        property string provider: ""
        property var items: []

        stdout: SplitParser {
            onRead: line => {
                try {
                    const raw = JSON.parse(line);
                    if (!root._matchesLocalFilters(raw)) return;
                    root._pushLocalItem(streamProc.provider === "naive" ? root._mapNaive(raw) : root._mapBlapples(raw));
                } catch (e) {}
            }
        }

        onExited: (exitCode) => {
            root.loading = false;
            const count = streamProc.items.length;
            root.totalPages = Math.max(1, Math.ceil(count / root.localPageSize));
            if (count === 0) {
                if (exitCode !== 0) {
                    root.fetchError(`${streamProc.provider} stream exited with code ${exitCode}`);
                    return;
                }
                root.appending = false;
                root.results = [];
                root.fetched();
            }
        }
    }

    // ─── Process: Windows (no python3) — fetch the whole index at once, filter/map in JS ───
    Process {
        id: fullFetchProc
        property string provider: ""
        stdout: StdioCollector { id: fullFetchCollector }
        onExited: (exitCode) => {
            root.loading = false;
            if (exitCode !== 0) {
                root.fetchError(`${fullFetchProc.provider} fetch exited with code ${exitCode}`);
                return;
            }
            try {
                const data = JSON.parse(fullFetchCollector.text);
                const items = [];
                for (const raw of data) {
                    if (!root._matchesLocalFilters(raw)) continue;
                    items.push(fullFetchProc.provider === "naive" ? root._mapNaive(raw) : root._mapBlapples(raw));
                }
                root._finishLocalList(fullFetchProc.provider, items);
            } catch (e) {
                root.fetchError(`${fullFetchProc.provider} parse error: ` + e);
            }
        }
    }

    Process {
        id: fetchProc
        property string provider: ""
        property string buffer:   ""

        onRunningChanged: {
            if (running) buffer = "";
        }

        stdout: SplitParser {
            onRead: data => {
                fetchProc.buffer += data;
            }
        }

        onExited: (exitCode) => {
            root.loading = false;
            if (exitCode !== 0) {
                root.fetchError("curl exited with code " + exitCode);
                return;
            }
            if (fetchProc.provider === "unsplash") {
                root._parseUnsplash(fetchProc.buffer);
            } else if (fetchProc.provider === "pexels") {
                root._parsePexels(fetchProc.buffer);
            }
        }
    }
}

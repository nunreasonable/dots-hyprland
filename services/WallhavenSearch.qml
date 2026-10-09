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

    property bool fetching: false
    property var currentResults: []
    property var currentMeta: ({})
    property string lastError: ""
    property string currentQuery: ""
    property int currentPage: 1
    property int lastPage: 1

    property string categories: "111"
    property string purity: "100"
    property string sorting: "relevance"
    property string order: "desc"
    property string topRange: "1y"
    property string seed: ""
    property string minResolution: ""
    property string ratios: ""
    property string apiKey: ""
    property string colors: ""

    readonly property string downloadDirectory: `${FileUtils.trimFileProtocol(Directories.pictures)
                                                }/Wallpapers`

    signal searchCompleted(var results, var meta)
    signal searchFailed(string error)
    signal wallpaperDownloaded(string wallpaperId, string localPath)
    readonly property string apiBaseUrl: "https://wallhaven.cc/api/v1"

    Component.onCompleted: {
        loadFromConfig();
    }

    function loadFromConfig() {
        const cfg = Config.options?.wallpaperSelector;
        if (!cfg)
            return;
        apiKey = KeyringStorage.keyringData?.apiKeys?.wallhaven ?? cfg.wallhavenApiKey ?? "";
        categories = cfg.wallhavenCategories || "111";
        purity = cfg.wallhavenPurity || "100";
        sorting = cfg.wallhavenSorting || "relevance";
        order = cfg.wallhavenOrder || "desc";
        ratios = cfg.wallhavenRatios || "";
        colors = cfg.wallhavenColors || "";
        topRange = cfg.wallhavenTopRange || "1y";
        currentQuery = cfg.wallhavenQuery || "";
    }

    function saveToConfig() {
        const cfg = Config.options?.wallpaperSelector;
        if (!cfg)
            return;
        cfg.wallhavenCategories = categories;
        cfg.wallhavenPurity = purity;
        cfg.wallhavenSorting = sorting;
        cfg.wallhavenOrder = order;
        cfg.wallhavenRatios = ratios;
        cfg.wallhavenColors = colors;
        cfg.wallhavenTopRange = topRange;
        cfg.wallhavenQuery = currentQuery;
        cfg.wallhavenApiKey = apiKey;
        if (Platform.isWindows)
            return;
        if (apiKey.length > 0)
            KeyringStorage.setNestedField(["apiKeys", "wallhaven"], apiKey);
    }

    function clearQuery() {
        if (currentQuery === "" && currentResults.length === 0)
            return;
        currentQuery = "";
        currentResults = [];
        currentPage = 1;
        lastPage = 1;
        currentMeta = ({});
        lastError = "";
        saveToConfig();
    }

    function search(query, page) {
        if (fetching)
            return;
        fetching = true;
        lastError = "";
        currentQuery = query || "";
        currentPage = page || 1;

        var url = apiBaseUrl + "/search";
        var params = [];

        if (currentQuery) {
            params.push("q=" + encodeURIComponent(currentQuery));
        }

        const valid = (value, pattern, fallback) => pattern.test(String(value ?? "")) ? String(value) : fallback;
        params.push("categories=" + valid(categories, /^[01]{3}$/, "111"));
        var safePurity = valid(purity, /^[01]{3}$/, "100");
        if (!SpicyStuff.allowed)
            safePurity = safePurity.charAt(0) + "00";
        if (safePurity === "000")
            safePurity = "100";
        params.push("purity=" + safePurity);
        const safeSorting = valid(sorting, /^(date_added|relevance|random|views|favorites|toplist|hot)$/, "date_added");
        params.push("sorting=" + safeSorting);
        params.push("order=" + valid(order, /^(desc|asc)$/, "desc"));

        if (safeSorting === "toplist")
            params.push("topRange=" + valid(topRange, /^(1d|3d|1w|1M|3M|6M|1y)$/, "1M"));

        if (safeSorting === "random" && /^[A-Za-z0-9]{1,16}$/.test(seed ?? ""))
            params.push("seed=" + seed);

        if (/^\d{2,5}x\d{2,5}$/.test(minResolution ?? ""))
            params.push("atleast=" + minResolution);

        const safeRatios = String(ratios ?? "").split(",").filter(r => /^(\d{1,2}x\d{1,2}|landscape|portrait)$/.test(r)).join(",");
        if (safeRatios)
            params.push("ratios=" + encodeURIComponent(safeRatios));

        if (/^[0-9a-fA-F]{6}$/.test(colors ?? ""))
            params.push("colors=" + colors);

        params.push("page=" + currentPage);

        url += "?" + params.join("&");

        console.log("[WallhavenSearch] Searching:", url);

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                fetching = false;
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        if (response.data && Array.isArray(response.data)) {
                            currentResults = SpicyStuff.allowed ? response.data : response.data.filter(item => item?.purity === "sfw");
                            currentMeta = response.meta || {};
                            lastPage = currentMeta.last_page || 1;
                            if (currentMeta.seed) {
                                seed = currentMeta.seed;
                            }
                            console.log("[WallhavenSearch] Search completed:", currentResults.length,
                                        "results, page", currentPage, "of", lastPage);
                            searchCompleted(currentResults, currentMeta);
                        } else {
                            lastError = "Invalid API response";
                            console.warn("[WallhavenSearch]", lastError);
                            searchFailed(lastError);
                        }
                    } catch (e) {
                        lastError = "Failed to parse API response: " + e.toString();
                        console.warn("[WallhavenSearch]", lastError);
                        searchFailed(lastError);
                    }
                } else if (xhr.status === 429) {
                    lastError = Translation.tr("Rate limit exceeded (45 requests/minute)");
                    console.warn("[WallhavenSearch]", lastError);
                    searchFailed(lastError);
                } else if (xhr.status === 401) {
                    lastError = Translation.tr("Invalid API Key");
                    console.warn("[WallhavenSearch]", lastError);
                    searchFailed(lastError);
                } else {
                    lastError = "API error: " + xhr.status;
                    console.warn("[WallhavenSearch]", lastError);
                    searchFailed(lastError);
                }
            }
        };

        xhr.open("GET", url);
        if (/^[A-Za-z0-9]{32}$/.test(apiKey ?? ""))
            xhr.setRequestHeader("X-API-Key", apiKey);
        xhr.send();
    }

    function getWallpaperUrl(wallpaper) {
        if (wallpaper.path) {
            return wallpaper.path;
        }
        if (wallpaper.id) {
            var idPrefix = wallpaper.id.substring(0, 2);
            return "https://w.wallhaven.cc/full/" + idPrefix + "/wallhaven-" + wallpaper.id + ".jpg";
        }
        return "";
    }

    function getThumbnailUrl(wallpaper, size) {
        if (wallpaper.thumbs && wallpaper.thumbs[size]) {
            return wallpaper.thumbs[size];
        }
        if (wallpaper.id) {
            var idPrefix = wallpaper.id.substring(0, 2);
            var sizeMap = {
                "small": "small",
                "large": "lg",
                "original": "orig"
            };
            var sizePath = sizeMap[size] || "lg";
            return "https://th.wallhaven.cc/" + sizePath + "/" + idPrefix + "/" + wallpaper.id + ".jpg";
        }
        return "";
    }

    Process {
        id: downloadProc
        property string localPath: ""
        property var callback: null
        property string wallpaperId: ""
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                console.log("[WallhavenSearch] Wallpaper downloaded:", downloadProc.localPath);
                root.wallpaperDownloaded(downloadProc.wallpaperId, downloadProc.localPath);
                if (downloadProc.callback) {
                    downloadProc.callback(true, downloadProc.localPath);
                }
            } else {
                console.warn("[WallhavenSearch] Failed to download wallpaper, exit code:", exitCode);
                if (downloadProc.callback) {
                    downloadProc.callback(false, "");
                }
            }
        }
    }

    function downloadWallpaper(wallpaper, callback) {
        var url = getWallpaperUrl(wallpaper);
        if (!url) {
            console.warn("[WallhavenSearch] No URL available for wallpaper", wallpaper.id);
            if (callback)
                callback(false, "");
            return;
        }

        var wallpaperId = String(wallpaper.id ?? "");
        var extension = (url.split('.').pop() || "").toLowerCase();
        if (!/^[a-z0-9]{1,16}$/.test(wallpaperId) || !["jpg", "jpeg", "png", "webp"].includes(extension)
                || !/^https:\/\/w\.wallhaven\.cc\//.test(url)) {
            console.warn("[WallhavenSearch] Refusing unexpected wallpaper data", wallpaperId);
            if (callback)
                callback(false, "");
            return;
        }
        var localPath = downloadDirectory + "/wallhaven_" + wallpaperId + "." + extension;

        console.log("[WallhavenSearch] Downloading wallpaper", wallpaperId, "to", localPath);

        downloadProc.localPath = localPath;
        downloadProc.callback = callback;
        downloadProc.wallpaperId = wallpaperId;
        downloadProc.command = ["curl", "--create-dirs", "-sSL", "--max-filesize", "60000000", "-o", localPath, "--url", url];
        downloadProc.running = true;
    }

    function browse(sortMode) {
        currentQuery = "";
        sorting = sortMode || "toplist";
        if (sortMode === "random")
            seed = "";
        saveToConfig();
        search("", 1);
    }

    function setColor(hex) {
        colors = (colors === hex) ? "" : (hex || "");
        saveToConfig();
        search(currentQuery, 1);
    }

    function reset() {
        currentResults = [];
        currentMeta = {};
        currentQuery = "";
        currentPage = 1;
        lastPage = 1;
        seed = "";
        lastError = "";
    }

    function nextPage() {
        if (currentPage < lastPage && !fetching) {
            search(currentQuery, currentPage + 1);
        }
    }

    function previousPage() {
        if (currentPage > 1 && !fetching) {
            search(currentQuery, currentPage - 1);
        }
    }

    function goToPage(page) {
        page = parseInt(page, 10);
        if (isNaN(page) || page < 1)
            page = 1;
        if (page > lastPage)
            page = lastPage;
        if (page !== currentPage && !fetching)
            search(currentQuery, page);
    }
}

pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.modules.common

Singleton {
    id: root

    property int consumers: 0
    readonly property bool wanted: root.consumers > 0
    readonly property MprisPlayer activePlayer: MprisController.activePlayer

    property var lyricsLines: []
    property int activeIndex: -1
    property string status: "loading"
    property var slots: ["", "", "", "", "", "", ""]
    property string loadedKey: ""
    property int requestToken: 0
    property var request: null
    property var pendingUrls: []

    readonly property int before: 3
    readonly property int after: 3
    readonly property int total: 7

    readonly property bool playing: root.activePlayer?.isPlaying ?? false
    readonly property bool synced: root.status === "ok" && root.lyricsLines.length > 0
    readonly property real leadSeconds: 0.15

    property real basePosition: 0
    property real baseTime: Date.now()

    function buildSlots(idx) {
        const result = [];
        for (let i = 0; i < root.total; i++) {
            const lineIdx = idx - root.before + i;
            if (lineIdx >= 0 && lineIdx < root.lyricsLines.length)
                result.push(root.lyricsLines[lineIdx].text || "♪");
            else
                result.push("");
        }
        return result;
    }

    function currentPosition() {
        return root.playing ? root.basePosition + (Date.now() - root.baseTime) / 1000 : root.basePosition;
    }

    function resync() {
        if (!root.activePlayer || !root.wanted)
            return;
        root.activePlayer.positionChanged();
        readPositionTimer.restart();
    }

    function indexAt(pos) {
        const lines = root.lyricsLines;
        let low = 0;
        let high = lines.length - 1;
        let result = -1;
        while (low <= high) {
            const mid = (low + high) >> 1;
            if (lines[mid].time <= pos) {
                result = mid;
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }
        return result;
    }

    function update() {
        boundaryTimer.stop();
        if (!root.synced || !root.wanted)
            return;
        const idx = root.indexAt(root.currentPosition() + root.leadSeconds);
        if (idx !== root.activeIndex) {
            root.activeIndex = idx;
            root.slots = root.buildSlots(idx);
        }
        const next = root.lyricsLines[idx + 1];
        if (!root.playing || !next)
            return;
        const delay = (next.time - root.leadSeconds - root.currentPosition()) * 1000;
        boundaryTimer.interval = Math.max(1, Math.ceil(delay));
        boundaryTimer.start();
    }

    function parseLrc(text) {
        const lines = [];
        for (const rawLine of (text ?? "").split(/\r?\n/)) {
            const raw = rawLine.trim();
            const tagEnd = raw.indexOf("]");
            if (!raw.startsWith("[") || tagEnd < 0)
                continue;
            const parts = raw.slice(1, tagEnd).split(":");
            if (parts.length !== 2)
                continue;
            const time = parseInt(parts[0]) * 60 + parseFloat(parts[1]);
            if (isNaN(time))
                continue;
            lines.push({
                time: time,
                text: raw.slice(tagEnd + 1).trim()
            });
        }
        return lines.sort((a, b) => a.time - b.time);
    }

    function isMatch(entry, title, artist) {
        if (!entry?.syncedLyrics)
            return false;
        const resultTitle = (entry.trackName ?? "").toLowerCase();
        const resultArtist = (entry.artistName ?? "").toLowerCase();
        const t = title.toLowerCase();
        const a = artist.toLowerCase();
        const titleMatch = t.includes(resultTitle) || resultTitle.includes(t) || t.split(/\s+/).some(word => word.length > 3 && resultTitle.includes(word));
        const artistMatch = a.includes(resultArtist) || resultArtist.includes(a) || a.split(/\s+/).some(word => word.length > 3 && resultArtist.includes(word));
        return titleMatch && artistMatch;
    }

    function trackKey() {
        return `${root.activePlayer?.trackTitle ?? ""}\n${root.activePlayer?.trackArtist ?? ""}`;
    }

    function finish(lines) {
        timeoutTimer.stop();
        root.request = null;
        if (lines.length === 0) {
            root.status = "not_found";
            return;
        }
        root.lyricsLines = lines;
        root.activeIndex = -1;
        root.slots = root.buildSlots(-1);
        root.status = "ok";
        root.resync();
    }

    function fetchNext(token, title, artist) {
        if (token !== root.requestToken)
            return;
        if (root.pendingUrls.length === 0) {
            root.finish([]);
            return;
        }
        const url = root.pendingUrls[0];
        root.pendingUrls = root.pendingUrls.slice(1);
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE || token !== root.requestToken)
                return;
            let lines = [];
            if (xhr.status === 200) {
                try {
                    let data = JSON.parse(xhr.responseText);
                    if (Array.isArray(data))
                        data = data.find(entry => root.isMatch(entry, title, artist)) ?? null;
                    if (data && root.isMatch(data, title, artist))
                        lines = root.parseLrc(data.syncedLyrics);
                } catch (e) {}
            }
            if (lines.length > 0)
                root.finish(lines);
            else
                root.fetchNext(token, title, artist);
        };
        xhr.open("GET", url);
        xhr.send();
        root.request = xhr;
        timeoutTimer.restart();
    }

    function restartLyrics() {
        root.requestToken++;
        root.request?.abort();
        root.request = null;
        timeoutTimer.stop();
        boundaryTimer.stop();
        root.lyricsLines = [];
        root.activeIndex = -1;
        root.slots = ["", "", "", "", "", "", ""];
        root.status = "loading";
        root.loadedKey = root.wanted ? root.trackKey() : "";
        if (!root.wanted)
            return;

        const title = root.activePlayer?.trackTitle ?? "";
        const artist = root.activePlayer?.trackArtist ?? "";
        const duration = Math.floor(root.activePlayer?.length ?? 0);
        if (!title || !artist) {
            root.status = "no_info";
            return;
        }

        const t = encodeURIComponent(title);
        const a = encodeURIComponent(artist);
        root.pendingUrls = [`https://lrclib.net/api/get?track_name=${t}&artist_name=${a}&duration=${duration}`, `https://lrclib.net/api/search?track_name=${t}&artist_name=${a}`, `https://lrclib.net/api/search?q=${encodeURIComponent(title + " " + artist)}`];
        root.fetchNext(root.requestToken, title, artist);
    }

    onWantedChanged: {
        if (root.wanted && root.loadedKey !== root.trackKey())
            root.restartLyrics();
        else if (root.wanted)
            root.resync();
    }

    onActivePlayerChanged: restartDebounce.restart()

    Timer {
        id: timeoutTimer
        interval: 15000
        onTriggered: {
            const token = root.requestToken;
            root.request?.abort();
            root.request = null;
            root.fetchNext(token, root.activePlayer?.trackTitle ?? "", root.activePlayer?.trackArtist ?? "");
        }
    }

    Timer {
        id: readPositionTimer
        interval: 80
        onTriggered: {
            root.basePosition = root.activePlayer?.position ?? 0;
            root.baseTime = Date.now();
            root.update();
        }
    }

    Timer {
        id: boundaryTimer
        onTriggered: root.update()
    }

    Timer {
        interval: 4000
        repeat: true
        running: root.synced && root.playing && root.wanted
        onTriggered: root.resync()
    }

    Timer {
        id: restartDebounce
        interval: 150
        onTriggered: {
            if (root.wanted)
                root.restartLyrics();
        }
    }

    Connections {
        target: root.activePlayer
        function onTrackTitleChanged() {
            restartDebounce.restart();
        }
        function onTrackArtistChanged() {
            restartDebounce.restart();
        }
        function onPlaybackStateChanged() {
            root.resync();
        }
    }
}

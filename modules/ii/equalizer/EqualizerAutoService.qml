pragma Singleton
import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property MprisPlayer player: MprisController.activePlayer

    readonly property var allowedPlayerIdentities: ["spotify", "firefox"]
    readonly property var domainRestrictedIdentities: ({
        "firefox": ["youtube.com"]
    })

    function isEligiblePlayer(p) {
        if (!p) return false
        const identity = (p.identity ?? "").toLowerCase()
        if (root.allowedPlayerIdentities.length > 0 &&
            !root.allowedPlayerIdentities.some(id => identity.includes(id))) {
            return false
        }
        for (const key in root.domainRestrictedIdentities) {
            if (!identity.includes(key)) continue
            const hosts = root.domainRestrictedIdentities[key]
            const pageUrl = String(p.metadata?.["xesam:url"] ?? "").toLowerCase()
            return hosts.some(host => pageUrl.includes(host))
        }
        return true
    }

    property bool autoEnabled: false
    property string lastLookupKey: ""
    property var lastArtistTags: []
    property var lastTrackTags: []
    property string currentPresetName: "Flat"

    readonly property var genreTagPresetMap: ({
        "metal": "Rock", "punk": "Rock", "grunge": "Rock",
        "emo": "Rock", "screamo": "Rock", "ska": "Rock", "rock": "Rock",
        "classical": "Classic", "orchestra": "Classic", "orchestral": "Classic",
        "opera": "Classic", "baroque": "Classic", "symphony": "Classic", "soundtrack": "Classic",
        "jazz": "Jazz", "blues": "Jazz", "swing": "Jazz", "bossa nova": "Jazz",
        "lounge": "Jazz", "trip hop": "Jazz", "ambient": "Jazz", "chillout": "Jazz",
        "downtempo": "Jazz", "lo-fi": "Jazz", "lofi": "Jazz",
        "hip hop": "Bass", "hip-hop": "Bass", "rap": "Bass", "trap": "Bass",
        "edm": "Bass", "electronic": "Bass", "house": "Bass", "techno": "Bass",
        "dubstep": "Bass", "dnb": "Bass", "d&b": "Bass", "reggae": "Bass", "dub": "Bass",
        "grime": "Bass", "funk": "Bass", "disco": "Bass", "afrobeat": "Bass",
        "synthwave": "Bass", "bass": "Bass",
        "acoustic": "Vocal", "folk": "Vocal", "singer-songwriter": "Vocal",
        "a cappella": "Vocal", "country": "Vocal", "gospel": "Vocal", "choir": "Vocal",
        "soul": "Vocal", "r&b": "Vocal", "rnb": "Vocal", "vocal": "Vocal",
        "pop": "Pop"
    })

    readonly property var falsePositiveSubstrings: ({
        "vocal": ["vocalist"],
        "bass": ["double bass", "upright bass", "bass guitar", "bassist", "bass player"]
    })

    function refresh() {
        if (Platform.isWindows) {
            root.currentPresetName = EqualizerApoBackend.presetName;
            return;
        }
        eqGetProc.running = false
        eqGetProc.running = true
    }

    function refreshAuto() {
        if (Platform.isWindows) {
            root.autoEnabled = EqualizerApoBackend.autoEnabled;
            if (root.autoEnabled) root.maybeLookupGenre();
            return;
        }
        eqGetAutoProc.running = false
        eqGetAutoProc.running = true
    }

    function toggleAuto() {
        const next = !root.autoEnabled
        root.autoEnabled = next
        if (Platform.isWindows) {
            EqualizerApoBackend.toggleAuto();
        } else {
            Quickshell.execDetached(["bash", Directories.eqScriptPath, Directories.eqStateDir, "set_auto", next ? "true" : "false"])
        }
        if (next) {
            root.lastLookupKey = ""
            root.maybeLookupGenre()
        }
    }

    function deriveYouTubeArtistTrack(rawTitle) {
        let t = String(rawTitle ?? "")
        t = t.replace(/^\(\d+\)\s*/, "").replace(/\s*-\s*YouTube$/i, "").trim()
        if (!t) return null
        const parts = t.split(" - ")
        if (parts.length < 2) return null
        const artist = parts[0].trim()
        let track = parts.slice(1).join(" - ").trim()
        track = track.replace(/[\[(](official\s*)?(music\s*)?(video|audio|lyrics?|visualizer|hd|4k)[\])]/gi, "").trim()
        if (!artist || !track) return null
        return { artist, track }
    }

    function maybeLookupGenre() {
        if (!root.autoEnabled) return
        if (!root.isEligiblePlayer(root.player)) return
        let artist = root.player?.trackArtist ?? ""
        let title = root.player?.trackTitle ?? ""
        if (!artist && title) {
            const parsed = root.deriveYouTubeArtistTrack(title)
            if (!parsed) return
            artist = parsed.artist
            title = parsed.track
        }
        if (!artist) return
        const key = artist + "␟" + title
        if (key === root.lastLookupKey) return
        root.lastLookupKey = key
        root.lastArtistTags = []
        root.lastTrackTags = []

        if (Platform.isWindows) {
            EqualizerApoBackend.genreTags(artist, (tags) => {
                root.lastArtistTags = tags;
                root.recomputePreset();
            });
            if (title) {
                EqualizerApoBackend.trackGenreTags(artist, title, (tags) => {
                    root.lastTrackTags = tags;
                    root.recomputePreset();
                });
            }
            return
        }

        genreTagsProc.artist = artist
        genreTagsProc.running = false
        genreTagsProc.running = true
        if (title) {
            trackGenreTagsProc.artist = artist
            trackGenreTagsProc.title = title
            trackGenreTagsProc.running = false
            trackGenreTagsProc.running = true
        }
    }

    function scoreTagGroup(tags, multiplier, scores) {
        if (!Array.isArray(tags)) return
        tags.forEach((tag, i) => {
            const lower = String(tag).toLowerCase()
            if (!lower) return
            const rankWeight = tags.length - i
            for (const key in root.genreTagPresetMap) {
                if (!lower.includes(key)) continue
                const exclusions = root.falsePositiveSubstrings[key]
                if (exclusions && exclusions.some(bad => lower.includes(bad))) continue
                const preset = root.genreTagPresetMap[key]
                scores[preset] = (scores[preset] || 0) + rankWeight * multiplier
                break
            }
        })
    }

    function presetForTags(artistTags, trackTags) {
        const scores = {}
        root.scoreTagGroup(trackTags, 3, scores)
        root.scoreTagGroup(artistTags, 1, scores)
        let best = null
        let bestScore = 0
        for (const preset in scores) {
            if (scores[preset] > bestScore) {
                best = preset
                bestScore = scores[preset]
            }
        }
        return bestScore > 0 ? best : null
    }

    function recomputePreset() {
        if (!root.autoEnabled) return
        const preset = root.presetForTags(root.lastArtistTags, root.lastTrackTags)
        if (preset && preset !== root.currentPresetName) {
            root.applyAutoPreset(preset)
        }
    }

    function applyAutoPreset(name) {
        root.currentPresetName = name
        if (Platform.isWindows) {
            EqualizerApoBackend.applyPreset(name);
        } else {
            Quickshell.execDetached(["bash", Directories.eqScriptPath, Directories.eqStateDir, "preset", name])
        }
    }

    Component.onCompleted: {
        root.refresh()
        root.refreshAuto()
    }

    onPlayerChanged: root.maybeLookupGenre()

    Connections {
        target: root.player
        function onTrackArtistChanged() { root.maybeLookupGenre() }
        function onTrackTitleChanged() { root.maybeLookupGenre() }
    }

    Process {
        id: eqGetProc
        running: false
        command: ["bash", Directories.eqScriptPath, Directories.eqStateDir, "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    root.currentPresetName = data.preset ?? "Custom"
                } catch (e) {
                }
            }
        }
    }

    Process {
        id: eqGetAutoProc
        running: false
        command: ["bash", Directories.eqScriptPath, Directories.eqStateDir, "get_auto"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                root.autoEnabled = (t === "true" || t === "1")
                if (root.autoEnabled) root.maybeLookupGenre()
            }
        }
    }

    Process {
        id: genreTagsProc
        running: false
        property string artist: ""
        command: artist.length > 0
            ? ["bash", Directories.eqScriptPath, Directories.eqStateDir, "genre_tags", artist]
            : ["true"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.lastArtistTags = JSON.parse(text)
                } catch (e) {
                    root.lastArtistTags = []
                }
                root.recomputePreset()
            }
        }
    }

    Process {
        id: trackGenreTagsProc
        running: false
        property string artist: ""
        property string title: ""
        command: (artist.length > 0 && title.length > 0)
            ? ["bash", Directories.eqScriptPath, Directories.eqStateDir, "track_genre_tags", artist, title]
            : ["true"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.lastTrackTags = JSON.parse(text)
                } catch (e) {
                    root.lastTrackTags = []
                }
                root.recomputePreset()
            }
        }
    }
}

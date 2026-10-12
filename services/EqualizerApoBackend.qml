pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

// Windows counterpart to equalizer.sh/EasyEffects.qml - same 10-band +
// preamp + presets + Auto genre-follow model EqualizerView.qml already
// knows how to drive, just backed by Equalizer APO (WindowsNative.equalizer,
// see src/windows/system/equalizer_apo.{hpp,cpp}) and a plain JSON state
// file instead of EasyEffects preset JSON. Only ever touched behind
// Platform.isWindows checks from the equalizer view and its auto genre-follow
// service - loads harmlessly on Linux (the FileView just sits on an unused file).
Singleton {
    id: root

    readonly property var bandFreqs: [32, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    readonly property var presetValues: ({
        "Flat":    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        "Bass":    [5, 7, 5, 2, 1, 0, 0, 0, 1, 2],
        "Treble":  [-2, -1, 0, 1, 2, 3, 4, 5, 6, 6],
        "Vocal":   [-2, -1, 1, 3, 5, 5, 4, 2, 1, 0],
        "Pop":     [2, 4, 2, 0, 1, 2, 4, 2, 1, 2],
        "Rock":    [5, 4, 2, -1, -2, -1, 2, 4, 5, 6],
        "Jazz":    [3, 3, 1, 1, 1, 1, 2, 1, 2, 3],
        "Classic": [0, 1, 2, 2, 2, 2, 1, 2, 3, 4]
    })

    readonly property bool apoReady: Platform.isWindows && !!WindowsNative.equalizer && WindowsNative.equalizer.ready
    readonly property bool needsHookStep: Platform.isWindows && !!WindowsNative.equalizer
        && WindowsNative.equalizer.installed && !WindowsNative.equalizer.hooked
    property bool pending: false

    // customPresets/genreCache/trackGenreCache have caller-chosen keys
    // (preset names, artist names, "artist\x1ftrack" pairs) - JsonObject
    // needs a fixed schema, so those three live as plain JSON-text fields
    // in the adapter (customPresetsJson etc.) and get mirrored into these
    // ordinary parsed properties on load/every write.
    property var customPresets: ({})
    property var genreCache: ({})
    property var trackGenreCache: ({})

    function fmtGain(value) {
        let rounded = Math.round(Number(value) * 100) / 100;
        if (!isFinite(rounded)) rounded = 0;
        let text = rounded.toFixed(2);
        if (text.indexOf(".") !== -1) text = text.replace(/0+$/, "").replace(/\.$/, "");
        return text;
    }

    // Mirrors equalizer.sh's apply_eq() mapping, just emitted as Equalizer
    // APO "Filter N: ON PK Fc <freq> Hz Gain <gain> dB Q 1.00" lines instead
    // of an EasyEffects 32-band JSON blob - see
    // $IIW/build/inventory (equalizer port report) for the host-side parity
    // check of this exact function.
    function buildApoConfig(bands, preamp, bypassed) {
        if (bypassed || !bands || bands.length !== 10) return "Preamp: 0 dB\n";
        const lines = [`Preamp: ${root.fmtGain(preamp)} dB`];
        for (let i = 0; i < 10; i++) {
            lines.push(`Filter ${i + 1}: ON PK Fc ${root.bandFreqs[i]} Hz Gain ${root.fmtGain(bands[i])} dB Q 1.00`);
        }
        return lines.join("\n") + "\n";
    }

    function writeCurrentCurve() {
        if (!Platform.isWindows || !WindowsNative.equalizer) return;
        const text = root.buildApoConfig(adapter.bands, adapter.preamp, adapter.bypassed);
        WindowsNative.equalizer.writeCurve(text);
    }

    function ensureHooked() {
        if (!Platform.isWindows || !WindowsNative.equalizer) return;
        if (WindowsNative.equalizer.hooked) return;
        if (WindowsNative.equalizer.configWritable) WindowsNative.equalizer.hookDirectly();
    }

    function requestElevatedHook() {
        if (!Platform.isWindows || !WindowsNative.equalizer) return;
        WindowsNative.equalizer.hookElevated();
        hookPollTimer.attemptsLeft = 20;
        hookPollTimer.start();
    }

    Timer {
        id: hookPollTimer
        interval: 1000
        repeat: true
        property int attemptsLeft: 0
        onTriggered: {
            if (!WindowsNative.equalizer) { hookPollTimer.stop(); return; }
            WindowsNative.equalizer.refresh();
            hookPollTimer.attemptsLeft -= 1;
            if (WindowsNative.equalizer.hooked || hookPollTimer.attemptsLeft <= 0) hookPollTimer.stop();
        }
    }

    Timer {
        id: liveApplyTimer
        interval: 120
        repeat: false
        onTriggered: {
            root.writeCurrentCurve();
            root.pending = false;
        }
    }

    function setBand(index, value) {
        const bands = adapter.bands.slice();
        bands[index] = value;
        adapter.bands = bands;
        adapter.presetName = "Custom";
        root.pending = true;
        liveApplyTimer.restart();
    }

    function setPreamp(value) {
        adapter.preamp = value;
        root.pending = true;
        liveApplyTimer.restart();
    }

    function setDim(value) {
        adapter.dim = value;
    }

    function saveChanges() {
        root.writeCurrentCurve();
        root.pending = false;
    }

    function applyPreset(name) {
        const vals = root.presetValues[name];
        if (vals) adapter.bands = vals.slice();
        adapter.presetName = name;
        root.pending = false;
        root.writeCurrentCurve();
    }

    function applyCustomPreset(name) {
        const vals = root.customPresets[name];
        if (vals) adapter.bands = vals.slice();
        adapter.presetName = name;
        root.pending = false;
        root.writeCurrentCurve();
    }

    function saveCustomPreset(name) {
        const trimmed = String(name).trim();
        if (!trimmed) return;
        const updated = Object.assign({}, root.customPresets);
        updated[trimmed] = adapter.bands.slice();
        root.customPresets = updated;
        adapter.customPresetsJson = JSON.stringify(updated);
        adapter.presetName = trimmed;
        root.pending = false;
        root.writeCurrentCurve();
    }

    function deleteCustomPreset(name) {
        const updated = Object.assign({}, root.customPresets);
        delete updated[name];
        root.customPresets = updated;
        adapter.customPresetsJson = JSON.stringify(updated);
        if (adapter.presetName === name) {
            adapter.presetName = "Custom";
        }
    }

    function toggleBypass() {
        adapter.bypassed = !adapter.bypassed;
        root.writeCurrentCurve();
    }

    function setLastfmKey(key) {
        adapter.lastfmKey = String(key).trim();
    }

    function toggleAuto() {
        adapter.autoEnabled = !adapter.autoEnabled;
    }

    // Collab-string fallback, same reasoning/order as equalizer.sh's
    // strip_featured_artists(): try the full MPRIS artist string first, and
    // only fall back to this (the first-listed name) when that lookup comes
    // back with nothing.
    function primaryArtist(artist) {
        return String(artist)
            .replace(/\s*,.*/, "")
            .replace(/\s+&\s.*/, "")
            .replace(/\s+(feat(uring)?|ft)\.?\s.*/i, "")
            .replace(/\s+x\s.*/i, "")
            .replace(/\s+vs\.?\s.*/i, "");
    }

    function lastfmLookup(method, params, onTags) {
        if (!adapter.lastfmKey) { onTags([]); return; }
        let qs = `method=${method}&api_key=${encodeURIComponent(adapter.lastfmKey)}&format=json`;
        for (const k in params) qs += `&${k}=${encodeURIComponent(params[k])}`;
        const url = `https://ws.audioscrobbler.com/2.0/?${qs}`;
        const proc = lastfmProcComponent.createObject(root, { url: url, onTags: onTags });
        proc.running = true;
    }

    Component {
        id: lastfmProcComponent
        Process {
            id: proc
            property string url: ""
            property var onTags: null
            command: ["curl.exe", "-fsS", "--max-time", "5", proc.url]
            stdout: StdioCollector {
                onStreamFinished: {
                    let tags = [];
                    try {
                        const data = JSON.parse(text);
                        const raw = data?.toptags?.tag ?? [];
                        tags = raw.map(t => t.name).filter(n => !!n);
                    } catch (e) { tags = []; }
                    if (proc.onTags) proc.onTags(tags);
                    proc.destroy();
                }
            }
            onExited: (exitCode, exitStatus) => {
                if (exitCode !== 0 && proc.onTags) { proc.onTags([]); proc.destroy(); }
            }
        }
    }

    function genreTags(artist, callback) {
        const key = String(artist).toLowerCase();
        if (Object.prototype.hasOwnProperty.call(root.genreCache, key)) { callback(root.genreCache[key]); return; }
        root.lastfmLookup("artist.gettoptags", { artist: artist }, (tags) => {
            if (tags.length === 0) {
                const primary = root.primaryArtist(artist);
                if (primary && primary.toLowerCase() !== key) {
                    root.lastfmLookup("artist.gettoptags", { artist: primary }, (tags2) => {
                        root.cacheGenreTags(key, tags2);
                        callback(tags2);
                    });
                    return;
                }
            }
            root.cacheGenreTags(key, tags);
            callback(tags);
        });
    }

    function cacheGenreTags(key, tags) {
        const updated = Object.assign({}, root.genreCache);
        updated[key] = tags;
        root.genreCache = updated;
        adapter.genreCacheJson = JSON.stringify(updated);
    }

    function trackGenreTags(artist, title, callback) {
        const key = `${String(artist).toLowerCase()}\u001f${String(title).toLowerCase()}`;
        if (Object.prototype.hasOwnProperty.call(root.trackGenreCache, key)) { callback(root.trackGenreCache[key]); return; }
        root.lastfmLookup("track.gettoptags", { artist: artist, track: title }, (tags) => {
            const updated = Object.assign({}, root.trackGenreCache);
            updated[key] = tags;
            root.trackGenreCache = updated;
            adapter.trackGenreCacheJson = JSON.stringify(updated);
            callback(tags);
        });
    }

    Timer {
        id: fileWriteTimer
        interval: 150
        repeat: false
        onTriggered: stateFile.writeAdapter()
    }

    FileView {
        id: stateFile
        path: FileUtils.trimFileProtocol(`${Directories.eqStateDir}/eq_state_windows.json`)
        watchChanges: false
        onAdapterUpdated: fileWriteTimer.restart()
        onLoaded: {
            try { root.customPresets = JSON.parse(adapter.customPresetsJson || "{}"); } catch (e) { root.customPresets = {}; }
            try { root.genreCache = JSON.parse(adapter.genreCacheJson || "{}"); } catch (e) { root.genreCache = {}; }
            try { root.trackGenreCache = JSON.parse(adapter.trackGenreCacheJson || "{}"); } catch (e) { root.trackGenreCache = {}; }
            if (Platform.isWindows && WindowsNative.equalizer) {
                WindowsNative.equalizer.setDefaultDeviceId(Audio.sink?.name ?? "");
                root.ensureHooked();
                root.writeCurrentCurve();
            }
        }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) fileWriteTimer.restart();
        }

        adapter: JsonAdapter {
            id: adapter
            property list<real> bands: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            property real preamp: 0
            property real dim: 0.3
            property string presetName: "Flat"
            property bool bypassed: false
            property bool autoEnabled: false
            property string lastfmKey: ""
            property string customPresetsJson: "{}"
            property string genreCacheJson: "{}"
            property string trackGenreCacheJson: "{}"
        }
    }

    readonly property alias bands: adapter.bands
    readonly property alias preamp: adapter.preamp
    readonly property alias dim: adapter.dim
    readonly property alias presetName: adapter.presetName
    readonly property alias bypassed: adapter.bypassed
    readonly property alias autoEnabled: adapter.autoEnabled
    readonly property alias lastfmKey: adapter.lastfmKey

    Connections {
        target: Audio
        function onSinkChanged() {
            if (Platform.isWindows && WindowsNative.equalizer) WindowsNative.equalizer.setDefaultDeviceId(Audio.sink?.name ?? "");
        }
    }
}

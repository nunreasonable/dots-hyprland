pragma Singleton
import qs.modules.common
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var table: [
        { label: "Realtek Audio Console", ids: ["realtek"], names: ["realtek audio console", "realtek hd audio manager"] },
        { label: "Waves MaxxAudio", ids: ["waves", "maxxaudio"], names: ["maxxaudio", "waves maxxaudio"] },
        { label: "Dolby Access", ids: ["dolbylaboratories", "dolby"], names: ["dolby access", "dolby atmos"] },
        { label: "DTS Audio", ids: ["dts", "xperi"], names: ["dts sound unbound", "dts audio processing", "dts:x ultra", "dtsx ultra"] },
        { label: "Nahimic", ids: ["nahimic", "a-volute", "avolute"], names: ["nahimic"] },
        { label: "ASUS Sonic Studio", ids: ["asus"], names: ["sonic studio", "sonic studio 3"] },
        { label: "Bang & Olufsen Audio Control", ids: ["bang", "bangolufsen", "bang-olufsen"], names: ["bang & olufsen", "b&o audio control"] },
        { label: "Dell/Alienware Audio", ids: ["dell", "alienware"], names: ["dell audio", "alienware audio", "alienware command center"] },
        { label: "HP Audio Control", ids: ["hp.audiocontrol", "hpaudiocontrol"], names: ["hp audio control", "hp audio switch"] },
        { label: "SteelSeries GG", ids: ["steelseries"], names: ["steelseries gg", "steelseries sonar", "sonar"] },
        { label: "Voicemeeter", ids: ["vb-audio", "voicemeeter"], names: ["voicemeeter"] },
        { label: "FxSound", ids: ["fxsound"], names: ["fxsound"] },
        { label: "Boom 3D", ids: ["globaldelight", "boom3d"], names: ["boom 3d", "boom3d"] },
        { label: "Peace (Equalizer APO GUI)", ids: ["peace"], names: ["peace"] }
    ]

    function containsAny(haystack, needles) {
        if (!haystack) return false;
        const lower = haystack.toLowerCase();
        return needles.some(n => lower.includes(n));
    }

    function matchesEntry(row, entry) {
        const id = String(entry.id ?? "");
        const name = String(entry.name ?? "");
        return root.containsAny(id, row.ids) || root.containsAny(name, row.names);
    }

    function installed() {
        if (!Platform.isWindows) return [];
        const all = Array.from(DesktopEntries.applications.values ?? []);
        const found = [];
        for (const row of root.table) {
            const entry = all.find(e => root.matchesEntry(row, e));
            if (entry) found.push({ label: row.label, entry: entry });
        }
        return found;
    }
}

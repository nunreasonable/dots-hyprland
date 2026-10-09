pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var schemes: ({})

    FileView {
        id: schemesFile
        path: `${Directories.assetsPath}/color_schemes.json`
        watchChanges: false
        onLoaded: {
            try {
                root.schemes = JSON.parse(schemesFile.text());
            } catch (e) {
                console.warn("ColorSchemes: failed to parse JSON -", e);
                root.schemes = {};
            }
        }
    }

    readonly property var currentScheme: root.schemes[Config.options.appearance.palette.namedScheme] ?? null

    function schemeOptions() {
        const options = [
            {
                displayName: Translation.tr("From wallpaper"),
                value: ""
            }
        ];
        const ids = Object.keys(root.schemes).sort();
        for (const id of ids) {
            options.push({
                displayName: root.schemes[id].name ?? id,
                value: id
            });
        }
        return options;
    }

    function accentsFor(dark) {
        const scheme = root.currentScheme;
        if (!scheme)
            return {};
        return (scheme.accents ?? {})[dark ? "dark" : "light"] ?? {};
    }

    function accentOptions(dark) {
        const accents = root.accentsFor(dark);
        return Object.keys(accents).map(role => ({
                    displayName: role,
                    value: role,
                    color: accents[role]
                }));
    }

    function currentAccent(slot, dark) {
        const scheme = root.currentScheme;
        if (!scheme)
            return "";
        const accents = root.accentsFor(dark);
        const requested = slot === "secondary" ? Config.options.appearance.palette.namedSchemeSecondary : Config.options.appearance.palette.namedSchemePrimary;
        if (requested && accents[requested])
            return accents[requested];
        const fallback = (scheme.defaults ?? {})[slot];
        if (fallback && accents[fallback])
            return accents[fallback];
        const values = Object.values(accents);
        return values.length > 0 ? values[0] : "";
    }

    function applySecondaryOverride() {
        if (!Config.options.appearance.palette.namedScheme)
            return;
        const secondaryHex = root.currentAccent("secondary", Appearance.m3colors.darkmode);
        if (!/^#[0-9a-fA-F]{6}$/.test(secondaryHex ?? ""))
            return;
        const m3 = Appearance.m3colors;
        m3.m3secondary = ColorUtils.adaptToAccent(m3.m3secondary, secondaryHex);
        m3.m3onSecondary = ColorUtils.adaptToAccent(m3.m3onSecondary, secondaryHex);
        m3.m3secondaryContainer = ColorUtils.adaptToAccent(m3.m3secondaryContainer, secondaryHex);
        m3.m3onSecondaryContainer = ColorUtils.adaptToAccent(m3.m3onSecondaryContainer, secondaryHex);
    }
}

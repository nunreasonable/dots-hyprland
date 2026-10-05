pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Windows equivalent of switchwall.sh's terminal theming (applycolor.sh's apply_anyterm() -
 * apply_kitty() has no Windows Terminal equivalent, so it's skipped here): regenerates
 * sequences.txt and a Windows Terminal color-scheme/profile fragment whenever ii's Material
 * colors change, gated the same way applycolor.sh gates it on
 * appearance.wallpaperTheming.enableTerminal (and enableAppsAndShell, same as Wallpapers.qml's
 * _retheme()). When either is off, the fragment and sequences.txt are removed instead, so
 * Windows Terminal falls back to whatever the user had configured themselves.
 *
 * Also writes two Oh My Posh prompt themes (_writeOhMyPosh()/_writeOhMyPoshPlain()): ii.omp.json
 * with Nerd Font glyphs for Windows Terminal, and ii.plain.omp.json with plain Unicode/ASCII
 * stand-ins for a classic console (conhost) whose current font can't show them. profile.ps1
 * picks between the two at shell start; this file just keeps both current.
 *
 * term0..15 come from the native Quickshell.Windows.TerminalColors.generate() - a C++ port of
 * generate_colors_material.py's terminal-harmonization pass, since there's no bundled Python/
 * materialyoucolor on Windows to run the script itself. It takes scheme-base.json's dark/light
 * object plus three Material colors as inputs; see _materialFromJson() for where those come
 * from, and WindowsNativeImpl.qml for why this is read through WindowsNative instead of
 * `import Quickshell.Windows` directly.
 *
 * terminalGenerationProps.forceDarkMode mirrors switchwall.sh forcing
 * generate_colors_material.py's --mode to "dark" regardless of ii's real theme: the script
 * recomputes its *own* full Material scheme at that forced mode, independently of the matugen
 * colors.json ii's UI uses. So when ii is light but forceDarkMode is on, the Material colors
 * feeding the terminal (both the palette 232-255 colors in sequences.txt and the
 * harmonization inputs below) need to come from a dark-mode run too - _ensureDarkMaterial()
 * runs matugen.exe a second time into material-dark.json for exactly that case, reusing
 * Wallpapers.qml's own write-config-then-run ordering (FileView skips writes of unchanged
 * text, so this only waits for matugen when the config actually changed). Otherwise
 * (forceDarkMode off, or ii already dark) colors.json alone already has everything, since the
 * script would just recompute the same scheme matugen did.
 *
 * primary_paletteKeyColor (the harmonization hue source TerminalColors.generate()'s doc
 * comment asks for) isn't a key matugen's own templates can produce - checked against the
 * installed matugen 4.1.0's `-j hex` dump: there's no paletteKeyColor key at all, since it's a
 * materialyoucolor/MaterialDynamicColors attribute the script computes separately, not
 * something matugen's Rust implementation exposes. `primary` is used instead.
 */
Singleton {
    id: root

    function load() {} // For forcing initialization (shell.qml), same as Wallpapers.load()

    readonly property bool _enabled: Platform.isWindows && Config.ready
        && Config.options.appearance.wallpaperTheming.enableTerminal
        && Config.options.appearance.wallpaperTheming.enableAppsAndShell
    readonly property bool _forceDark: Config.ready
        && Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode
    readonly property bool _needsDarkMaterial: root._forceDark && !Appearance.m3colors.darkmode

    function regenerate() {
        if (!Platform.isWindows || !Config.ready) return;
        if (!root._enabled) {
            root._removeOutputs();
            return;
        }
        if (root._needsDarkMaterial) {
            root._ensureDarkMaterial();
        } else {
            root._applyFromJsonText(colorsFileView.text());
        }
    }

    // --- triggers: anything applycolor.sh's callers would also react to ---------------------

    Connections {
        target: Platform.isWindows ? Config : null
        function onReadyChanged() { root.regenerate(); }
    }
    Connections {
        target: Platform.isWindows ? WindowsNative : null
        function onReadyChanged() { root.regenerate(); }
    }
    Connections {
        target: Platform.isWindows ? (Config.options?.appearance?.wallpaperTheming ?? null) : null
        function onEnableTerminalChanged() { root.regenerate(); }
        function onEnableAppsAndShellChanged() { root.regenerate(); }
    }
    Connections {
        target: Platform.isWindows ? (Config.options?.appearance?.wallpaperTheming?.terminalGenerationProps ?? null) : null
        function onForceDarkModeChanged() { root.regenerate(); }
        function onHarmonyChanged() { root.regenerate(); }
        function onHarmonizeThresholdChanged() { root.regenerate(); }
        function onTermFgBoostChanged() { root.regenerate(); }
    }
    Connections {
        target: Platform.isWindows ? (Config.options?.appearance?.transparency ?? null) : null
        function onEnableChanged() { root.regenerate(); }
    }

    // colors.json: the same file MaterialThemeLoader watches, read independently here (raw
    // JSON, not Appearance.m3colors) so the exact matugen hex strings survive without a QML
    // `color` round-trip, and so this keeps working unchanged if primary_paletteKeyColor is
    // ever added to the template.
    FileView {
        id: colorsFileView
        path: Platform.isWindows ? Qt.resolvedUrl(Directories.generatedMaterialThemePath) : ""
        watchChanges: true
        printErrors: false
        onFileChanged: { reload(); colorsReloadDelay.restart(); }
        onLoadedChanged: root.regenerate()
    }
    Timer {
        id: colorsReloadDelay
        interval: Config.options?.hacks?.arbitraryRaceConditionDelay ?? 100
        onTriggered: root.regenerate()
    }

    function _applyFromJsonText(text) {
        if (!text) return;
        let json;
        try {
            json = JSON.parse(text);
        } catch (e) {
            return;
        }
        root._writeOutputs(root._materialFromJson(json));
    }

    function _materialFromJson(json) {
        return {
            primary: json.primary, primaryContainer: json.primary_container,
            secondary: json.secondary, secondaryContainer: json.secondary_container,
            tertiary: json.tertiary, tertiaryContainer: json.tertiary_container,
            error: json.error, errorContainer: json.error_container,
            onPrimary: json.on_primary, onPrimaryContainer: json.on_primary_container,
            onSecondary: json.on_secondary, onSecondaryContainer: json.on_secondary_container,
            onTertiary: json.on_tertiary, onTertiaryContainer: json.on_tertiary_container,
            onError: json.on_error, onErrorContainer: json.on_error_container,
            outlineVariant: json.outline_variant,
            surfaceContainerLow: json.surface_container_low, onSurface: json.on_surface,
            // See the file-level doc comment: matugen has no paletteKeyColor output.
            primaryKeyColor: json.primary_paletteKeyColor || json.primary,
            background: json.background,
        };
    }

    // --- forceDarkMode's second matugen.exe pass ---------------------------------------------

    // Same auto-detection Wallpapers.qml's _retheme() does for the main theme; duplicated
    // (rather than calling into Wallpapers.qml) since it's three lines and this needs it for
    // both the dark-mode matugen args below and the monochrome flag in _writeOutputs().
    function _resolveSchemeType(path) {
        let t = Config.options.appearance.palette.type || "auto";
        if (t === "auto") {
            t = (path && WindowsNative.imageTools) ? WindowsNative.imageTools.schemeForImage(path) : "scheme-tonal-spot";
        }
        return t;
    }

    function _ensureDarkMaterial() {
        const wn = WindowsNative.wallpaper;
        if (!wn) return; // native backend not ready yet; WindowsNative.onReadyChanged retries

        const matugenExe = wn.matugenPath();
        if (!matugenExe) return; // same silent bail Wallpapers.qml does when matugen is missing

        const accentColor = Config.options.appearance.palette.accentColor;
        const hasAccentColor = /^#[0-9a-fA-F]{6}$/.test(accentColor ?? "");
        const path = Config.options.background.wallpaperPath;
        if (!hasAccentColor && !path) return; // nothing to theme from yet

        const schemeType = root._resolveSchemeType(path);
        const args = [matugenExe, "--source-color-index", "0", "-c", darkMatugenConfig.path, "-m", "dark", "-t", schemeType];
        if (hasAccentColor) {
            args.push("color", "hex", accentColor);
        } else {
            args.push("image", path);
        }

        const config = root._darkMatugenConfigText();
        if (config === root._writtenDarkConfig) {
            root._runDarkMatugen(args);
            return;
        }
        root._pendingDarkMatugen = args;
        if (config !== root._writingDarkConfig) {
            root._writingDarkConfig = config;
            darkMatugenConfig.setText(config);
        }
    }

    property var _pendingDarkMatugen: null
    property string _writtenDarkConfig: "" // on disk
    property string _writingDarkConfig: "" // write in flight

    function _runDarkMatugen(args) {
        darkMatugenProc.command = args;
        darkMatugenProc.running = false;
        darkMatugenProc.running = true;
    }

    function _darkMatugenConfigText() {
        const toml = s => s.indexOf("'") === -1 ? `'${s}'` : JSON.stringify(s);
        const template = FileUtils.trimFileProtocol(Directories.windowsMatugenTemplatePath);
        return `[config]\nversion_check = false\n\n[templates.m3colors]\n`
            + `input_path = ${toml(template)}\n`
            + `output_path = ${toml(Directories.windowsTerminalMaterialDarkPath)}\n`;
    }

    FileView {
        id: darkMatugenConfig
        path: Platform.isWindows ? Directories.windowsTerminalMaterialDarkConfigPath : ""
        preload: false
        onSaved: {
            root._writtenDarkConfig = root._writingDarkConfig;
            root._writingDarkConfig = "";
            if (!root._pendingDarkMatugen) return;
            const args = root._pendingDarkMatugen;
            root._pendingDarkMatugen = null;
            root._runDarkMatugen(args);
        }
        onSaveFailed: error => {
            root._pendingDarkMatugen = null;
            root._writingDarkConfig = "";
            console.warn("[WindowsTerminalTheme] Could not write the dark-mode matugen config:", error);
        }
    }

    Process {
        id: darkMatugenProc
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) console.warn("[WindowsTerminalTheme] matugen.exe (dark):", text);
            }
        }
    }

    FileView {
        id: darkMaterialFileView
        path: Platform.isWindows ? Qt.resolvedUrl(Directories.windowsTerminalMaterialDarkPath) : ""
        watchChanges: true
        printErrors: false
        onFileChanged: { reload(); darkMaterialReloadDelay.restart(); }
        onLoadedChanged: root._onDarkMaterialLoaded()
    }
    Timer {
        id: darkMaterialReloadDelay
        interval: Config.options?.hacks?.arbitraryRaceConditionDelay ?? 100
        onTriggered: root._onDarkMaterialLoaded()
    }

    function _onDarkMaterialLoaded() {
        if (!root._needsDarkMaterial) return; // stale: mode flipped back while matugen ran
        root._applyFromJsonText(darkMaterialFileView.text());
    }

    // --- rendering: term0-15 + sequences.txt + the Windows Terminal fragment -----------------

    FileView {
        id: schemeBaseFileView
        path: Platform.isWindows ? Qt.resolvedUrl(Directories.terminalSchemeBasePath) : ""
        preload: Platform.isWindows
        onLoadedChanged: root.regenerate()
    }
    FileView {
        id: sequencesTemplateFileView
        path: Platform.isWindows ? Qt.resolvedUrl(Directories.terminalSequencesTemplatePath) : ""
        preload: Platform.isWindows
        onLoadedChanged: root.regenerate()
    }

    function _writeOutputs(material) {
        if (!WindowsNative.terminalColors) {
            console.warn("[WindowsTerminalTheme] Quickshell.Windows.TerminalColors isn't available in this build yet, skipping terminal theming");
            return;
        }

        // Both templates regenerate once loaded (onLoadedChanged below).
        if (!schemeBaseFileView.loaded || !sequencesTemplateFileView.loaded) return;

        let schemeBase;
        try {
            schemeBase = JSON.parse(schemeBaseFileView.text());
        } catch (e) {
            console.warn("[WindowsTerminalTheme] Could not read scheme-base.json:", e);
            return;
        }
        const darkMode = root._needsDarkMaterial
            || (material.background ? Qt.color(material.background).hslLightness < 0.5 : Appearance.m3colors.darkmode);
        const baseScheme = schemeBase[darkMode ? "dark" : "light"];
        if (!baseScheme) return;

        const props = Config.options.appearance.wallpaperTheming.terminalGenerationProps;
        // Always false: generate_colors_material.py's monochrome branch checks
        // `args.scheme == 'monochrome'`, but switchwall.sh always passes `scheme-monochrome`
        // (with the "scheme-" prefix), so that branch never actually runs on Linux either -
        // monochrome wallpapers get harmonized terminal colors there too. Matching that (not
        // the apparent intent) is what makes this byte-for-byte what ii actually shows.
        const monochrome = false;

        const termColors = WindowsNative.terminalColors.generate(
            baseScheme, material.primaryKeyColor, material.surfaceContainerLow, material.onSurface,
            darkMode, props.harmony, props.harmonizeThreshold, props.termFgBoost, monochrome);

        const colorMap = Object.assign({}, termColors, {
            primary: material.primary, primaryContainer: material.primaryContainer,
            secondary: material.secondary, secondaryContainer: material.secondaryContainer,
            tertiary: material.tertiary, tertiaryContainer: material.tertiaryContainer,
            error: material.error, errorContainer: material.errorContainer,
            onPrimary: material.onPrimary, onPrimaryContainer: material.onPrimaryContainer,
            onSecondary: material.onSecondary, onSecondaryContainer: material.onSecondaryContainer,
            onTertiary: material.onTertiary, onTertiaryContainer: material.onTertiaryContainer,
            onError: material.onError, onErrorContainer: material.onErrorContainer,
            outlineVariant: material.outlineVariant,
        });

        root._writeSequences(colorMap);
        root._writeFragment(colorMap, material);
        root._writeOhMyPosh(colorMap);
        root._writeOhMyPoshPlain(colorMap);
        root._nudgeWindowsTerminal();
    }

    // Same two-pass substitution as applycolor.sh's apply_anyterm(): "$name #" (the name plus
    // the space and "#" that follow it in the template) becomes the plain hex digits, so the
    // "#" written just before "$name" in the template is what's left to prefix them; then
    // "$alpha" (not in the current template, but applycolor.sh always does this pass too).
    function _writeSequences(colorMap) {
        let text = sequencesTemplateFileView.text();
        if (!text) return;
        for (const name in colorMap) {
            const hex = String(colorMap[name] || "").replace(/^#/, "");
            if (!hex) continue;
            text = text.split(`$${name} #`).join(hex);
        }
        text = text.split("$alpha").join("100"); // term_alpha in applycolor.sh; always opaque here
        // The template's OSC 1 (icon name) is ignored by kitty and foot but is the tab title in
        // Windows Terminal, which would read "0;#RRGGBB".
        text = text.replace(/\x1b\]1;[^\x1b]*\x1b\\/g, "");
        sequencesOutput.setText(text);
    }

    FileView {
        id: sequencesOutput
        path: Platform.isWindows ? Directories.windowsTerminalSequencesPath : ""
        onSaveFailed: error => console.warn("[WindowsTerminalTheme] Could not write sequences.txt:", error);
    }

    function _writeFragment(colorMap, material) {
        const ansiTerms = ["term0", "term1", "term2", "term3", "term4", "term5", "term6", "term7",
            "term8", "term9", "term10", "term11", "term12", "term13", "term14", "term15"];
        const ansiNames = ["black", "red", "green", "yellow", "blue", "purple", "cyan", "white",
            "brightBlack", "brightRed", "brightGreen", "brightYellow", "brightBlue", "brightPurple", "brightCyan", "brightWhite"];
        const scheme = { name: "illogical-impulse" };
        for (let i = 0; i < ansiTerms.length; i++) scheme[ansiNames[i]] = colorMap[ansiTerms[i]];
        scheme.background = colorMap.term0;
        scheme.foreground = colorMap.term7;
        scheme.cursorColor = colorMap.term7;
        scheme.selectionBackground = material.onSecondaryContainer;

        // Subtle when on, matching Linux's own panel/bar transparency rather than something
        // that would make a terminal hard to read.
        const transparencyOn = Config.options.appearance.transparency.enable === true;
        const profileUpdate = guid => ({
            updates: guid,
            colorScheme: "illogical-impulse",
            font: { face: "JetBrainsMono Nerd Font", size: 11 },
            cursorShape: "bar",
            padding: "22",
            opacity: transparencyOn ? 85 : 100,
            useAcrylic: transparencyOn,
        });

        const fragment = {
            profiles: [
                profileUpdate("{61c54bbd-c2c6-5271-96e7-009a87ff44bf}"), // Windows PowerShell
                profileUpdate("{0caa0dad-35be-5f56-a8ff-afceeeaa6101}"), // Command Prompt
                profileUpdate("{574e775e-4f2a-5b96-ac1e-a2962a402336}"), // PowerShell 7 (pwsh)
            ],
            schemes: [scheme],
        };
        fragmentOutput.setText(JSON.stringify(fragment, null, 2));
    }

    FileView {
        id: fragmentOutput
        path: Platform.isWindows ? Directories.windowsTerminalFragmentPath : ""
        onSaveFailed: error => console.warn("[WindowsTerminalTheme] Could not write the Windows Terminal fragment:", error);
    }

    // Oh My Posh prompt (profile.ps1 prefers it over Starship): the layout of ii's starship.toml
    // - a duration pill, the path pill and a git pill, then the prompt character on its own
    // line - in the same Material roles its 256-color slots map to (sequences.txt: 255 primary,
    // 252 secondaryContainer, 235 onSecondaryContainer, 240 onPrimary, 243 primary, 244 error).
    function _writeOhMyPosh(c) {
        const pillStart = "\uE0B6", pillEnd = "\uE0B4";
        const character = "{{ if gt .Code 0 }}\uF00D \uF04B{{ else }}\uEA71 \uF04B{{ end }}";
        const characterColor = ["{{ if gt .Code 0 }}p:error{{ end }}"];
        const theme = {
            "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
            "version": 3,
            "final_space": true,
            "palette": {
                "primary": c.primary,
                "onPrimary": c.onPrimary,
                "secondaryContainer": c.secondaryContainer,
                "onSecondaryContainer": c.onSecondaryContainer,
                "error": c.error,
            },
            "blocks": [
                {
                    "type": "prompt",
                    "alignment": "left",
                    "segments": [
                        {
                            "type": "executiontime", "style": "diamond",
                            "leading_diamond": pillStart, "trailing_diamond": pillEnd,
                            "foreground": "p:onSecondaryContainer", "background": "p:secondaryContainer",
                            "template": "\uF017 {{ .FormattedMs }}",
                            "options": { "threshold": 0, "style": "austin" },
                        },
                        {
                            "type": "path", "style": "diamond",
                            "leading_diamond": ` ${pillStart}`, "trailing_diamond": pillEnd,
                            "foreground": "p:onPrimary", "background": "p:primary",
                            "template": "\uF07B \u2192 {{ .Path }}",
                            // DOS separators, as Windows paths are shown elsewhere in ii.
                            // The Nerd Font house is wider than its cell and would cover the "\".
                            "options": { "style": "agnoster_short", "max_depth": 2, "home_icon": "\uF46D ", "folder_separator_icon": "\\" },
                        },
                        {
                            "type": "git", "style": "diamond",
                            "leading_diamond": ` \uE702 ${pillStart}`, "trailing_diamond": pillEnd,
                            "foreground": "p:onSecondaryContainer", "background": "p:secondaryContainer",
                            "template": "\uE725 {{ .HEAD }}",
                            "options": { "branch_icon": "" },
                        },
                    ],
                },
                {
                    "type": "prompt",
                    "alignment": "left",
                    "newline": true,
                    "segments": [
                        {
                            "type": "text", "style": "plain",
                            "foreground": "p:primary", "foreground_templates": characterColor,
                            "template": `  ${character}`,
                        },
                    ],
                },
            ],
            // Indented like the character line, so collapsed prompts line up with the live one.
            "transient_prompt": {
                "foreground": "p:primary",
                "foreground_templates": characterColor,
                "template": `  ${character} `,
            },
        };
        ohMyPoshOutput.setText(JSON.stringify(theme, null, 2));
    }

    FileView {
        id: ohMyPoshOutput
        path: Platform.isWindows ? Directories.windowsTerminalOhMyPoshPath : ""
        onSaveFailed: error => console.warn("[WindowsTerminalTheme] Could not write the Oh My Posh theme:", error);
    }

    // Same layout and colors as _writeOhMyPosh(), but every segment's glyph is a plain
    // Unicode/ASCII stand-in instead of a Nerd Font private-use-area codepoint - for a classic
    // console (conhost) whose current font isn't a Nerd Font (profile.ps1 decides which of the
    // two files to load; Windows Terminal always gets the glyph one above, untouched). The
    // powerline pill separators (/) are themselves Nerd/PowerLine PUA glyphs, so
    // this drops the diamond styling and falls back to "plain" segments with ASCII brackets,
    // which every console font (raster or TrueType) already has.
    function _writeOhMyPoshPlain(c) {
        const character = "{{ if gt .Code 0 }}x{{ else }}>{{ end }}";
        const characterColor = ["{{ if gt .Code 0 }}p:error{{ end }}"];
        const theme = {
            "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
            "version": 3,
            "final_space": true,
            "palette": {
                "primary": c.primary,
                "onPrimary": c.onPrimary,
                "secondaryContainer": c.secondaryContainer,
                "onSecondaryContainer": c.onSecondaryContainer,
                "error": c.error,
            },
            "blocks": [
                {
                    "type": "prompt",
                    "alignment": "left",
                    "segments": [
                        {
                            "type": "executiontime", "style": "plain",
                            "foreground": "p:onSecondaryContainer", "background": "p:secondaryContainer",
                            "template": "[{{ .FormattedMs }}]",
                            "options": { "threshold": 0, "style": "austin" },
                        },
                        {
                            "type": "path", "style": "plain",
                            "foreground": "p:onPrimary", "background": "p:primary",
                            "template": " {{ .Path }}",
                            "options": { "style": "agnoster_short", "max_depth": 2, "home_icon": "~", "folder_separator_icon": "\\" },
                        },
                        {
                            "type": "git", "style": "plain",
                            "foreground": "p:onSecondaryContainer", "background": "p:secondaryContainer",
                            "template": " [{{ .HEAD }}]",
                            "options": { "branch_icon": "" },
                        },
                    ],
                },
                {
                    "type": "prompt",
                    "alignment": "left",
                    "newline": true,
                    "segments": [
                        {
                            "type": "text", "style": "plain",
                            "foreground": "p:primary", "foreground_templates": characterColor,
                            "template": `${character} `,
                        },
                    ],
                },
            ],
            "transient_prompt": {
                "foreground": "p:primary",
                "foreground_templates": characterColor,
                "template": `${character} `,
            },
        };
        ohMyPoshPlainOutput.setText(JSON.stringify(theme, null, 2));
    }

    FileView {
        id: ohMyPoshPlainOutput
        path: Platform.isWindows ? Directories.windowsTerminalOhMyPoshPlainPath : ""
        onSaveFailed: error => console.warn("[WindowsTerminalTheme] Could not write the plain Oh My Posh theme:", error);
    }

    // --- removal (enableTerminal/enableAppsAndShell off) & nudging an open Windows Terminal --

    function _removeOutputs() {
        if (!Platform.isWindows) return;
        removeOutputsProc.command = ["powershell", "-NoProfile", "-NonInteractive", "-Command",
            `Remove-Item -LiteralPath '${Directories.windowsTerminalSequencesPath}' -Force -ErrorAction SilentlyContinue; `
            + `Remove-Item -LiteralPath '${Directories.windowsTerminalFragmentPath}' -Force -ErrorAction SilentlyContinue; `
            + `Remove-Item -LiteralPath '${Directories.windowsTerminalOhMyPoshPath}' -Force -ErrorAction SilentlyContinue; `
            + `Remove-Item -LiteralPath '${Directories.windowsTerminalOhMyPoshPlainPath}' -Force -ErrorAction SilentlyContinue`];
        removeOutputsProc.running = false;
        removeOutputsProc.running = true;
        root._nudgeWindowsTerminal();
    }
    Process { id: removeOutputsProc }

    // Windows Terminal doesn't hot-reload *fragment* files the way it hot-reloads settings.json
    // as of the versions in general use; bumping settings.json's own mtime without touching its
    // content makes already-open windows re-read everything, fragments included. The integrator
    // tests this on the real VM - drop this function (and its two call sites above) if it turns
    // out Windows Terminal reloads fragments on its own.
    function _nudgeWindowsTerminal() {
        if (!Platform.isWindows) return;
        const path = Directories.windowsTerminalSettingsJsonPath;
        const script = `if (Test-Path -LiteralPath '${path}') { (Get-Item -LiteralPath '${path}').LastWriteTime = Get-Date }`;
        nudgeProc.command = ["powershell", "-NoProfile", "-NonInteractive", "-Command", script];
        nudgeProc.running = false;
        nudgeProc.running = true;
    }
    Process { id: nudgeProc }
}

pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    function load() {}

    readonly property bool _enabled: Platform.isWindows && Config.ready
        && Config.options.appearance.wallpaperTheming.enableTerminal
        && Config.options.appearance.wallpaperTheming.enableAppsAndShell
    readonly property bool _forceDark: Config.ready
        && Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode
    readonly property bool _needsDarkMaterial: root._forceDark && !Appearance.m3colors.darkmode

    property bool _armed: false
    readonly property bool _reading: root._armed && root._enabled
    readonly property bool _inputsSettled: colorsFileView.settled && schemeBaseFileView.settled
        && sequencesTemplateFileView.settled && sequencesOutput.settled && fragmentOutput.settled
        && ohMyPoshOutput.settled && ohMyPoshPlainOutput.settled

    on_ArmedChanged: root.regenerate()
    on_InputsSettledChanged: root.regenerate()

    Timer {
        interval: 10000
        running: Platform.isWindows && Config.ready && !root._armed
        onTriggered: root._armed = true
    }

    component SettledFileView: FileView {
        id: settledFileView
        property bool settled: false
        onPathChanged: settledFileView.settled = false
        onLoaded: settledFileView.settled = true
        onLoadFailed: settledFileView.settled = true
    }

    function regenerate() {
        if (!root._armed) return;
        if (!root._enabled) {
            root._removeOutputs();
            return;
        }
        if (!root._inputsSettled) return;
        if (root._needsDarkMaterial) {
            root._ensureDarkMaterial();
        } else {
            root._applyFromJsonText(colorsFileView.text());
        }
    }

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

    SettledFileView {
        id: colorsFileView
        path: root._reading ? Qt.resolvedUrl(Directories.generatedMaterialThemePath) : ""
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
            primaryKeyColor: json.primary_paletteKeyColor || json.primary,
            background: json.background,
        };
    }

    function _resolveSchemeType(path) {
        let t = Config.options.appearance.palette.type || "auto";
        if (t === "auto") {
            t = (path && WindowsNative.imageTools) ? WindowsNative.imageTools.schemeForImage(path) : "scheme-tonal-spot";
        }
        return t;
    }

    function _ensureDarkMaterial() {
        const wn = WindowsNative.wallpaper;
        if (!wn) return;

        const matugenExe = wn.matugenPath();
        if (!matugenExe) return;

        const accentColor = Config.options.appearance.palette.accentColor;
        const hasAccentColor = /^#[0-9a-fA-F]{6}$/.test(accentColor ?? "");
        const path = Config.options.background.wallpaperPath;
        if (!hasAccentColor && !path) return;

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
    property string _writtenDarkConfig: ""
    property string _writingDarkConfig: ""

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
        path: root._reading ? Directories.windowsTerminalMaterialDarkConfigPath : ""
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
        path: root._reading ? Qt.resolvedUrl(Directories.windowsTerminalMaterialDarkPath) : ""
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
        if (!root._needsDarkMaterial) return;
        root._applyFromJsonText(darkMaterialFileView.text());
    }

    SettledFileView {
        id: schemeBaseFileView
        path: root._reading ? Qt.resolvedUrl(Directories.terminalSchemeBasePath) : ""
    }
    SettledFileView {
        id: sequencesTemplateFileView
        path: root._reading ? Qt.resolvedUrl(Directories.terminalSequencesTemplatePath) : ""
    }

    function _writeOutputs(material) {
        if (!WindowsNative.terminalColors) {
            console.warn("[WindowsTerminalTheme] Quickshell.Windows.TerminalColors isn't available in this build yet, skipping terminal theming");
            return;
        }

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
    }

    function _writeSequences(colorMap) {
        let text = sequencesTemplateFileView.text();
        if (!text) return;
        for (const name in colorMap) {
            const hex = String(colorMap[name] || "").replace(/^#/, "");
            if (!hex) continue;
            text = text.split(`$${name} #`).join(hex);
        }
        text = text.split("$alpha").join("100");
        text = text.replace(/\x1b\]1;[^\x1b]*\x1b\\/g, "");
        sequencesOutput.setText(text);
    }

    SettledFileView {
        id: sequencesOutput
        path: root._reading ? Directories.windowsTerminalSequencesPath : ""
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
                profileUpdate("{61c54bbd-c2c6-5271-96e7-009a87ff44bf}"),
                profileUpdate("{0caa0dad-35be-5f56-a8ff-afceeeaa6101}"),
                profileUpdate("{574e775e-4f2a-5b96-ac1e-a2962a402336}"),
            ],
            schemes: [scheme],
        };
        fragmentOutput.setText(JSON.stringify(fragment, null, 2));
    }

    SettledFileView {
        id: fragmentOutput
        path: root._reading ? Directories.windowsTerminalFragmentPath : ""
        onSaved: root._nudgeWindowsTerminal()
        onSaveFailed: error => console.warn("[WindowsTerminalTheme] Could not write the Windows Terminal fragment:", error);
    }

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
            "transient_prompt": {
                "foreground": "p:primary",
                "foreground_templates": characterColor,
                "template": `  ${character} `,
            },
        };
        ohMyPoshOutput.setText(JSON.stringify(theme, null, 2));
    }

    SettledFileView {
        id: ohMyPoshOutput
        path: root._reading ? Directories.windowsTerminalOhMyPoshPath : ""
        onSaveFailed: error => console.warn("[WindowsTerminalTheme] Could not write the Oh My Posh theme:", error);
    }

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

    SettledFileView {
        id: ohMyPoshPlainOutput
        path: root._reading ? Directories.windowsTerminalOhMyPoshPlainPath : ""
        onSaveFailed: error => console.warn("[WindowsTerminalTheme] Could not write the plain Oh My Posh theme:", error);
    }

    function _removeOutputs() {
        if (!Platform.isWindows) return;
        const fs = WindowsNative.fsUtils;
        const outputs = [Directories.windowsTerminalSequencesPath, Directories.windowsTerminalFragmentPath,
            Directories.windowsTerminalOhMyPoshPath, Directories.windowsTerminalOhMyPoshPlainPath];
        if (fs && !outputs.some(path => fs.classify(path) !== "invalid")) return;
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

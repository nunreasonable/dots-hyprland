pragma Singleton

import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import qs.modules.settings
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    property string query: ""

    function ensurePrefix(prefix) {
        if ([Config.options.search.prefix.action, Config.options.search.prefix.app, Config.options.search.prefix.clipboard, Config.options.search.prefix.emojis, Config.options.search.prefix.math, Config.options.search.prefix.shellCommand, Config.options.search.prefix.webSearch,].some(i => root.query.startsWith(i))) {
            root.query = prefix + root.query.slice(1);
        } else {
            root.query = prefix + root.query;
        }
    }

    // Load user action scripts from ~/.config/illogical-impulse/actions/
    // Uses FolderListModel to auto-reload when scripts are added/removed
    property var userActionsFolder: null
    onQueryChanged: {
        if (root.query !== "" && !root.userActionsFolder)
            root.loadUserActionsFolder();
    }
    function loadUserActionsFolder() {
        if (Platform.isWindows && WindowsNative.fsUtils?.classify(Directories.userActions) !== "dir")
            return;
        root.userActionsFolder = userActionsFolderComponent.createObject(root);
    }
    property var userActionScripts: {
        const userActionsFolder = root.userActionsFolder;
        if (!userActionsFolder)
            return [];
        const actions = [];
        for (let i = 0; i < userActionsFolder.count; i++) {
            const fileName = userActionsFolder.get(i, "fileName");
            const filePath = userActionsFolder.get(i, "filePath");
            if (fileName && filePath) {
                const actionName = fileName.replace(/\.[^/.]+$/, ""); // strip extension
                actions.push({
                    action: actionName,
                    execute: ((path) => (args) => {
                        Quickshell.execDetached([path, ...(args ? args.split(" ") : [])]);
                    })(FileUtils.trimFileProtocol(filePath.toString()))
                });
            }
        }
        return actions;
    }

    Component {
        id: userActionsFolderComponent
        FolderListModel {
            folder: Qt.resolvedUrl(Directories.userActions)
            showDirs: false
            showHidden: false
            sortField: FolderListModel.Name
        }
    }

    property var searchActions: [
        {
            action: "accentcolor",
            execute: args => {
                Wallpapers.setAccentColor(args != '' ? args : undefined);
            }
        },
        {
            action: "dark",
            execute: () => {
                Wallpapers.setMode(true);
            }
        },
        {
            action: "konachanwallpaper",
            execute: () => {
                RandomWallpaper.fetch("konachan");
            }
        },
        {
            action: "light",
            execute: () => {
                Wallpapers.setMode(false);
            }
        },
        {
            action: "superpaste",
            execute: args => {
                if (!/^(\d+)/.test(args.trim())) {
                    // Invalid if doesn't start with numbers
                    Notifications.sendDesktop(Translation.tr("Superpaste"), Translation.tr("Usage: <tt>%1superpaste NUM_OF_ENTRIES[i]</tt>\nSupply <tt>i</tt> when you want images\nExamples:\n<tt>%1superpaste 4i</tt> for the last 4 images\n<tt>%1superpaste 7</tt> for the last 7 entries").arg(Config.options.search.prefix.action), ["-a", "Shell"]);
                    return;
                }
                const syntaxMatch = /^(?:(\d+)(i)?)/.exec(args.trim());
                const count = syntaxMatch[1] ? parseInt(syntaxMatch[1]) : 1;
                const isImage = !!syntaxMatch[2];
                Cliphist.superpaste(count, isImage);
            }
        },
        {
            action: "todo",
            execute: args => {
                Todo.addTask(args);
            }
        },
        {
            action: "wallpaper",
            execute: () => {
                Hyprland.dispatch(`hl.dsp.global("quickshell:wallpaperSelectorToggle")`)
            }
        },
        {
            action: "wipeclipboard",
            execute: () => {
                Cliphist.wipe();
            }
        },
    ]

    // Combined built-in and user actions
    property var allActions: searchActions.concat(userActionScripts)

    property string mathResult: ""
    property bool clipboardWorkSafetyActive: {
        const enabled = Config.options.workSafety.enable.clipboard;
        const sensitiveNetwork = (StringUtils.stringListContainsSubstring(Network.networkName.toLowerCase(), Config.options.workSafety.triggerCondition.networkNameKeywords));
        return enabled && sensitiveNetwork;
    }

    function keybindToString(bind) {
        const modmask = bind.modmask ?? 0;
        const mods = [];
        if (modmask & (1 << 2))
            mods.push("Ctrl");
        if (modmask & (1 << 6))
            mods.push("Super");
        if (modmask & (1 << 0))
            mods.push("Shift");
        if (modmask & (1 << 3))
            mods.push("Alt");
        return [...mods, bind.key].filter(part => part).join(" + ");
    }

    function containsUnsafeLink(entry) {
        if (entry == undefined)
            return false;
        const unsafeKeywords = Config.options.workSafety.triggerCondition.linkKeywords;
        return StringUtils.stringListContainsSubstring(entry.toLowerCase(), unsafeKeywords);
    }

    Timer {
        id: nonAppResultsTimer
        interval: Config.options.search.nonAppResultDelay
        onTriggered: {
            let expr = root.query;
            if (expr.startsWith(Config.options.search.prefix.math)) {
                expr = expr.slice(Config.options.search.prefix.math.length);
            }
            mathProc.calculateExpression(expr);
        }
    }

    property bool windowsHasQalc: false
    property bool windowsQalcChecked: false
    function checkWindowsQalc() {
        const fs = WindowsNative.fsUtils;
        if (root.windowsQalcChecked || !fs) return;
        root.windowsQalcChecked = true;
        root.windowsHasQalc = !!fs.findExecutable("qalc.exe");
    }
    function evalArithmetic(expression) {
        const expr = expression.replace(/\s+/g, "").replace(/,/g, ".").replace(/×/g, "*").replace(/÷/g, "/").replace(/\^/g, "**");
        if (!/^[0-9.+\-*\/%()]+$/.test(expr) || !/[0-9]/.test(expr)) return "";
        try {
            const value = Function(`"use strict"; return (${expr});`)();
            return Number.isFinite(value) ? String(Number(value.toPrecision(12))) : "";
        } catch (e) {
            return "";
        }
    }

    Process {
        id: mathProc
        property list<string> baseCommand: ["qalc", "-t"]
        function calculateExpression(expression) {
            if (Platform.isWindows) root.checkWindowsQalc();
            if (Platform.isWindows && !root.windowsHasQalc) {
                root.mathResult = root.evalArithmetic(expression);
                return;
            }
            mathProc.running = false;
            mathProc.command = baseCommand.concat(expression);
            mathProc.running = true;
        }
        stdout: SplitParser {
            onRead: data => {
                root.mathResult = data;
            }
        }
    }

    property list<var> results: {
        // Search results are handled here
        ////////////////// Skip? //////////////////
        if (root.query == "")
            return [];

        ///////////// Special cases ///////////////
        if (root.query.startsWith(Config.options.search.prefix.clipboard)) {
            // Clipboard
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.clipboard);
            const clipboardResults = Cliphist.fuzzyQuery(searchString).map((entry, index, array) => {
                const mightBlurImage = Cliphist.entryIsImage(entry) && root.clipboardWorkSafetyActive;
                let shouldBlurImage = mightBlurImage;
                if (mightBlurImage) {
                    shouldBlurImage = shouldBlurImage && (root.containsUnsafeLink(array[index - 1]) || root.containsUnsafeLink(array[index + 1]));
                }
                const type = `#${entry.match(/^\s*(\S+)/)?.[1] || ""}`;
                const pinned = Cliphist.isPinned(entry);
                return resultComp.createObject(null, {
                    rawValue: entry,
                    name: StringUtils.cleanCliphistEntry(entry),
                    verb: "",
                    type: type,
                    pinned: pinned,
                    execute: () => {
                        Cliphist.copy(entry);
                    },
                    actions: [resultComp.createObject(null, {
                            name: pinned ? Translation.tr("Unpin") : Translation.tr("Pin"),
                            iconName: pinned ? "keep_off" : "keep",
                            iconType: LauncherSearchResult.IconType.Material,
                            execute: () => {
                                Cliphist.togglePin(entry);
                            }
                        }), resultComp.createObject(null, {
                            name: Translation.tr("Copy"),
                            iconName: "content_copy",
                            iconType: LauncherSearchResult.IconType.Material,
                            execute: () => {
                                Cliphist.copy(entry);
                            }
                        }), resultComp.createObject(null, {
                            name: Translation.tr("Delete"),
                            iconName: "delete",
                            iconType: LauncherSearchResult.IconType.Material,
                            execute: () => {
                                Cliphist.deleteEntry(entry);
                            }
                        })],
                    blurImage: shouldBlurImage
                });
            }).filter(Boolean);
            return [...clipboardResults.filter(r => r.pinned), ...clipboardResults.filter(r => !r.pinned)];
        } else if (root.query.startsWith(Config.options.search.prefix.emojis)) {
            // Clipboard
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.emojis);
            return Emojis.fuzzyQuery(searchString).map(entry => {
                const emoji = entry.match(/^\s*(\S+)/)?.[1] || "";
                return resultComp.createObject(null, {
                    rawValue: entry,
                    name: entry.replace(/^\s*\S+\s+/, ""),
                    iconName: emoji,
                    iconType: LauncherSearchResult.IconType.Text,
                    verb: Translation.tr("Copy"),
                    type: Translation.tr("Emoji"),
                    execute: () => {
                        Quickshell.clipboardText = entry.match(/^\s*(\S+)/)?.[1];
                    }
                });
            }).filter(Boolean);
        } else if (root.query.startsWith(Config.options.search.prefix.keybinds)) {
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.keybinds).toLowerCase();
            return HyprlandKeybinds.keybinds.filter(bind => {
                if (!bind.description && !bind.key)
                    return false;
                if (searchString === "")
                    return true;
                return (bind.description ?? "").toLowerCase().includes(searchString) || (bind.key ?? "").toLowerCase().includes(searchString);
            }).slice(0, 50).map(bind => {
                const keyStr = root.keybindToString(bind);
                return resultComp.createObject(null, {
                    id: `${bind.key}:${bind.modmask}:${bind.dispatcher}:${bind.arg}`,
                    name: bind.description ? `${bind.description}  ·  ${keyStr}` : keyStr,
                    verb: Translation.tr("Copy"),
                    type: Translation.tr("Keybind"),
                    fontType: LauncherSearchResult.FontType.Monospace,
                    iconName: 'keyboard_command_key',
                    iconType: LauncherSearchResult.IconType.Material,
                    execute: () => {
                        Quickshell.clipboardText = keyStr;
                    }
                });
            });
        } else if (root.query.startsWith(Config.options.search.prefix.symbols)) {
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.symbols);
            return MaterialSymbolsSearch.fuzzyQuery(searchString).map(entry => {
                const symbolName = entry.split("\t")[0] ?? "";
                return resultComp.createObject(null, {
                    rawValue: entry,
                    name: symbolName,
                    iconName: symbolName,
                    iconType: LauncherSearchResult.IconType.Material,
                    verb: Translation.tr("Copy"),
                    type: Translation.tr("Symbol"),
                    execute: () => {
                        Quickshell.clipboardText = symbolName;
                    }
                });
            }).filter(Boolean);
        }

        ////////////////// Init ///////////////////
        nonAppResultsTimer.restart();
        const mathResultObject = resultComp.createObject(null, {
            name: root.mathResult,
            verb: Translation.tr("Copy"),
            type: Translation.tr("Math result"),
            fontType: LauncherSearchResult.FontType.Monospace,
            iconName: 'calculate',
            iconType: LauncherSearchResult.IconType.Material,
            execute: () => {
                Quickshell.clipboardText = root.mathResult;
            }
        });
        const appResultObjects = AppSearch.fuzzyQuery(StringUtils.cleanPrefix(root.query, Config.options.search.prefix.app)).map(entry => {
            return resultComp.createObject(null, {
                type: Translation.tr("App"),
                id: entry.id,
                name: entry.name,
                iconName: entry.icon,
                iconType: LauncherSearchResult.IconType.System,
                verb: Translation.tr("Open"),
                execute: () => {
                    if (!entry.runInTerminal || Platform.isWindows)
                        entry.execute();
                    else {
                        // Probably needs more proper escaping, but this will do for now
                        Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(entry.command.join(' '))}'`]);
                    }
                },
                comment: entry.comment,
                runInTerminal: entry.runInTerminal,
                genericName: entry.genericName,
                keywords: entry.keywords,
                actions: entry.actions.map(action => {
                    return resultComp.createObject(null, {
                        name: action.name,
                        iconName: action.icon,
                        iconType: LauncherSearchResult.IconType.System,
                        execute: () => {
                            if (!action.runInTerminal || Platform.isWindows)
                                action.execute();
                            else {
                                Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(action.command.join(' '))}'`]);
                            }
                        }
                    });
                })
            });
        });
        const commandResultObject = resultComp.createObject(null, {
            name: StringUtils.cleanPrefix(root.query, Config.options.search.prefix.shellCommand).replace("file://", ""),
            verb: Translation.tr("Run"),
            type: Translation.tr("Command"),
            fontType: LauncherSearchResult.FontType.Monospace,
            iconName: 'terminal',
            iconType: LauncherSearchResult.IconType.Material,
            execute: () => {
                let cleanedCommand = root.query.replace("file://", "");
                cleanedCommand = StringUtils.cleanPrefix(cleanedCommand, Config.options.search.prefix.shellCommand);
                if (cleanedCommand.startsWith(Config.options.search.prefix.shellCommand)) {
                    cleanedCommand = cleanedCommand.slice(Config.options.search.prefix.shellCommand.length);
                }
                if (Platform.isWindows) {
                    Quickshell.execDetached(["powershell", "-NoProfile", "-Command", cleanedCommand]);
                    return;
                }
                Quickshell.execDetached(["bash", "-c", root.query.startsWith('sudo') ? `${Config.options.apps.terminal} fish -C '${cleanedCommand}'` : cleanedCommand]);
            }
        });
        const webSearchResultObject = resultComp.createObject(null, {
            name: StringUtils.cleanPrefix(root.query, Config.options.search.prefix.webSearch),
            verb: Translation.tr("Search"),
            type: Translation.tr("Web search"),
            iconName: 'travel_explore',
            iconType: LauncherSearchResult.IconType.Material,
            execute: () => {
                let query = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.webSearch);
                let url = Config.options.search.engineBaseUrl + query;
                for (let site of Config.options.search.excludedSites) {
                    url += ` -site:${site}`;
                }
                Qt.openUrlExternally(url);
            }
        });
        const settingsEntries = Config.options.appearance.settingsLayout === "end4pc" ? SettingsSearchIndex.search(root.query, 8) : [];
        const settingsResults = settingsEntries.map(entry => {
            const breadcrumb = entry.kind === "page" ? Translation.tr("Settings") : [entry.pageName, entry.kind === "option" ? entry.section : "", entry.kind === "option" ? entry.subsection : ""].filter(part => part).join(" › ");
            return resultComp.createObject(null, {
                name: entry.label,
                comment: breadcrumb,
                verb: Translation.tr("Go"),
                type: [Translation.tr("Settings"), entry.pageName, entry.kind === "option" ? entry.section : "", entry.kind === "option" ? entry.subsection : ""].filter(part => part).join(" • "),
                iconName: entry.icon,
                iconType: LauncherSearchResult.IconType.Material,
                execute: () => {
                    root.query = "";
                    SettingsApp.openAt(entry.pageId, entry.kind === "page" ? "" : entry.label, entry.section, entry.subsection);
                }
            });
        });
        const launcherActionObjects = root.allActions.map(action => {
            const actionString = `${Config.options.search.prefix.action}${action.action}`;
            if (actionString.startsWith(root.query) || root.query.startsWith(actionString)) {
                return resultComp.createObject(null, {
                    name: root.query.startsWith(actionString) ? root.query : actionString,
                    verb: Translation.tr("Run"),
                    type: Translation.tr("Action"),
                    iconName: 'settings_suggest',
                    iconType: LauncherSearchResult.IconType.Material,
                    execute: () => {
                        action.execute(root.query.split(" ").slice(1).join(" "));
                    }
                });
            }
            return null;
        }).filter(Boolean);

        //////// Prioritized by prefix /////////
        let result = [];
        const startsWithNumber = /^\d/.test(root.query);
        const startsWithMathPrefix = root.query.startsWith(Config.options.search.prefix.math);
        const startsWithShellCommandPrefix = root.query.startsWith(Config.options.search.prefix.shellCommand);
        const startsWithWebSearchPrefix = root.query.startsWith(Config.options.search.prefix.webSearch);
        if (startsWithNumber || startsWithMathPrefix) {
            result.push(mathResultObject);
        } else if (startsWithShellCommandPrefix) {
            result.push(commandResultObject);
        } else if (startsWithWebSearchPrefix) {
            result.push(webSearchResultObject);
        }

        //////////////// Apps //////////////////
        result = result.concat(appResultObjects);

        ////////////// Settings ////////////////
        result = result.concat(settingsResults);

        ////////// Launcher actions ////////////
        result = result.concat(launcherActionObjects);

        /// Math result, command, web search ///
        if (Config.options.search.prefix.showDefaultActionsWithoutPrefix) {
            if (!startsWithShellCommandPrefix)
                result.push(commandResultObject);
            if (!startsWithNumber && !startsWithMathPrefix)
                result.push(mathResultObject);
            if (!startsWithWebSearchPrefix)
                result.push(webSearchResultObject);
        }

        return result;
    }

    Component {
        id: resultComp
        LauncherSearchResult {}
    }
}

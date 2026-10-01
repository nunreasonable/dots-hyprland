pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * A service that provides access to Hyprland keybinds.
 * Uses the `get_keybinds.py` script to parse comments in config files in a certain format and convert to JSON.
 * On Windows, reads the keybinds.json that Quickshell's native hotkeys load
 * (%LOCALAPPDATA%\illogical-impulse\keybinds.json, else defaults/windows/keybinds.json)
 * and converts it to the shape of `hyprctl binds -j`.
 */
Singleton {
    id: root
    property var keybinds: []
    property var keybindCategories: []

    function updateCategories() {
        var groups = []
        for (var i = 0; i < root.keybinds.length; i++) {
            var bind = root.keybinds[i].description
            var group = bind.substring(0, bind.indexOf(":"))
            if (!groups.includes(group) && group.length > 0) {
                groups.push(group)
            }
        }
        root.keybindCategories = groups
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded" && !Platform.isWindows) {
                getKeybinds.running = true
            }
        }
    }

    Process {
        id: getKeybinds
        running: !Platform.isWindows
        command: ["hyprctl", "binds", "-j"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.keybinds = JSON.parse(text)
                    root.updateCategories()
                } catch (e) {
                    console.error("[CheatsheetKeybinds] Error parsing keybinds:", e)
                }
            }
        }
    }

    // Windows

    // Hyprland modmask bits, as used by the cheatsheet
    readonly property var windowsModBits: ({
        "shift": 1, "ctrl": 4, "control": 4, "ctl": 4, "alt": 8,
        "super": 64, "win": 64, "windows": 64, "meta": 64, "mod4": 64, "logo": 64,
        "super_l": 64, "super_r": 64, "lwin": 64, "rwin": 64,
    })
    // Hyprland's key name for a lone modifier ("SUPER + SUPER_L")
    readonly property var windowsLoneKeys: ({ 1: "Shift_L", 4: "Control_L", 8: "Alt_L", 64: "SUPER_L" })
    // Windows key names that differ from Hyprland's (xkb) ones
    readonly property var windowsKeyNames: ({
        "pageup": "Page_Up", "prior": "Page_Up", "pagedown": "Page_Down", "next": "Page_Down",
        "enter": "Return", "esc": "Escape", "backspace": "BackSpace", "del": "Delete", "ins": "Insert",
    })

    property string windowsUserText: ""
    property string windowsDefaultText: ""

    function windowsBindToHyprland(bind) {
        var modmask = 0
        var key = ""
        var parts = (bind.keys ?? "").split("+")
        for (var i = 0; i < parts.length; i++) {
            var token = parts[i].trim()
            var bit = root.windowsModBits[token.toLowerCase()]
            if (bit !== undefined) modmask |= bit
            else key = root.windowsKeyNames[token.toLowerCase()] ?? token
        }
        if (key.length === 0) key = root.windowsLoneKeys[modmask] ?? ""

        var dispatcher = bind.action ?? ""
        var arg = ""
        if (bind.action === "global") {
            dispatcher = "global"
            arg = (bind.name ?? "").includes(":") ? bind.name : `quickshell:${bind.name}`
        } else if (bind.action === "dispatch") {
            var request = bind.dispatch ?? ""
            var space = request.indexOf(" ")
            dispatcher = space === -1 ? request : request.substring(0, space)
            arg = space === -1 ? "" : request.substring(space + 1)
        } else if (bind.action === "exec") {
            dispatcher = "exec"
            arg = bind.command ?? ""
        } else if (bind.action === "ipc") {
            dispatcher = "exec"
            arg = ["qs", "ipc", "call", bind.target, bind["function"], ...(bind.args ?? [])].join(" ")
        }

        return {
            "locked": false,
            "mouse": false,
            "release": bind.onRelease ?? false,
            "repeat": bind.repeat ?? false,
            "longPress": false,
            "non_consuming": bind.action === "native",
            "has_description": (bind.description ?? "").length > 0,
            "modmask": modmask,
            "submap": "",
            "key": key,
            "keycode": 0,
            "catch_all": false,
            "description": bind.description ?? "",
            "dispatcher": dispatcher,
            "arg": arg,
        }
    }

    function updateWindowsKeybinds() {
        var text = root.windowsUserText.length > 0 ? root.windowsUserText : root.windowsDefaultText
        if (text.length === 0) return
        try {
            root.keybinds = (JSON.parse(text).binds ?? []).map(bind => root.windowsBindToHyprland(bind))
            root.updateCategories()
        } catch (e) {
            console.error("[CheatsheetKeybinds] Error parsing keybinds.json:", e)
        }
    }

    // Same lookup order as the native side: the user's file wins and is reloaded on change.
    FileView {
        id: windowsUserFile
        path: Platform.isWindows ? `${String(Quickshell.env("LOCALAPPDATA") ?? "").replace(/\\/g, "/")}/illogical-impulse/keybinds.json` : ""
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            root.windowsUserText = windowsUserFile.text()
            root.updateWindowsKeybinds()
        }
        onLoadFailed: {
            root.windowsUserText = ""
            root.updateWindowsKeybinds()
        }
    }

    FileView {
        id: windowsDefaultFile
        path: Platform.isWindows ? Quickshell.shellPath("defaults/windows/keybinds.json") : ""
        onLoaded: {
            root.windowsDefaultText = windowsDefaultFile.text()
            root.updateWindowsKeybinds()
        }
    }
}

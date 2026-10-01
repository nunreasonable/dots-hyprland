pragma Singleton

import qs.modules.common
import Quickshell

Singleton {
    id: root
    property int shiftMode: 0 // 0: off, 1: on, 2: lock
    property list<int> shiftKeys: [42, 54] // Keycodes for Shift keys (left and right)
    property list<int> altKeys: [56, 100] // Keycodes for Alt keys (left and right)
    property list<int> ctrlKeys: [29, 97] // Keycodes for Ctrl keys (left and right)

    // Windows: keycodes this service pressed and hasn't released yet. releaseAllKeys() only
    // releases these, since injecting a key-up for every key (what ydotool does on Linux) also
    // runs at startup and would reach every app and the hotkey hook.
    property var windowsPressed: ({})

    function releaseAllKeys() {
        const keycodes = Array.from(Array(249).keys());
        if (Platform.isWindows) {
            Object.keys(root.windowsPressed).forEach(keycode => WindowsNative.input.sendKey(parseInt(keycode), false));
            root.windowsPressed = {};
        } else {
            Quickshell.execDetached([
                "ydotool",
                "key", "--key-delay", "0",
                ...keycodes.map(keycode => `${keycode}:0`)
            ])
        }
        root.shiftMode = 0; // Reset shift mode
    }

    function releaseShiftKeys() {
        if (Platform.isWindows) {
            root.shiftKeys.filter(keycode => root.windowsPressed[keycode]).forEach(keycode => {
                WindowsNative.input.sendKey(keycode, false);
                delete root.windowsPressed[keycode];
            });
        } else {
            Quickshell.execDetached([
                "ydotool",
                "key", "--key-delay", "0",
                ...root.shiftKeys.map(keycode => `${keycode}:0`)
            ])
        }
        root.shiftMode = 0; // Reset shift mode
    }

    function press(keycode) {
        if (Platform.isWindows) {
            WindowsNative.input.sendKey(keycode, true);
            root.windowsPressed[keycode] = true;
            return;
        }
        Quickshell.execDetached([
            "ydotool",
            "key", "--key-delay", "0",
            `${keycode}:1`
        ]);
    }

    function release(keycode) {
        if (Platform.isWindows) {
            WindowsNative.input.sendKey(keycode, false);
            delete root.windowsPressed[keycode];
            return;
        }
        Quickshell.execDetached([
            "ydotool",
            "key", "--key-delay", "0",
            `${keycode}:0`
        ]);
    }
}

pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    function isPinned(appId) {
        const key = appId.toLowerCase();
        return Config.options.dock.pinnedApps.some(id => id.toLowerCase() === key);
    }

    function togglePin(appId) {
        if (root.isPinned(appId)) {
            const key = appId.toLowerCase();
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.filter(id => id.toLowerCase() !== key)
        } else {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.concat([appId])
        }
    }

    function movePin(from, to) {
        const order = [];
        const seen = new Set();
        for (const id of Config.options.dock.pinnedApps) {
            if (seen.has(id.toLowerCase()))
                continue;
            seen.add(id.toLowerCase());
            order.push(id);
        }
        if (from === to || from < 0 || to < 0 || from >= order.length || to >= order.length)
            return;
        const moved = order.splice(from, 1)[0];
        order.splice(to, 0, moved);
        Config.options.dock.pinnedApps = order;
    }

    property list<var> apps: []

    readonly property var _layout: {
        var map = new Map();

        // Pinned apps
        const pinnedApps = Config.options?.dock.pinnedApps ?? [];
        for (const appId of pinnedApps) {
            if (!map.has(appId.toLowerCase())) map.set(appId.toLowerCase(), ({
                pinned: true,
                toplevels: []
            }));
        }

        // Separator
        if (pinnedApps.length > 0) {
            map.set("SEPARATOR", { pinned: false, toplevels: [] });
        }

        // Ignored apps
        const ignoredRegexStrings = Config.options?.dock.ignoredAppRegexes ?? [];
        const ignoredRegexes = ignoredRegexStrings.map(pattern => new RegExp(pattern, "i"));
        // Open windows
        for (const toplevel of ToplevelManager.toplevels.values) {
            if (ignoredRegexes.some(re => re.test(toplevel.appId))) continue;
            if (!map.has(toplevel.appId.toLowerCase())) map.set(toplevel.appId.toLowerCase(), ({
                pinned: false,
                toplevels: []
            }));
            map.get(toplevel.appId.toLowerCase()).toplevels.push(toplevel);
        }

        return map;
    }

    readonly property var _entries: new Map()
    property bool _completed: false

    on_LayoutChanged: {
        if (root._completed)
            root._syncApps();
    }

    Component.onCompleted: {
        root._completed = true;
        root._syncApps();
    }

    function _sameItems(a, b) {
        if (a.length !== b.length)
            return false;
        for (let i = 0; i < a.length; i++) {
            if (a[i] !== b[i])
                return false;
        }
        return true;
    }

    function _syncApps() {
        const entries = root._entries;
        const values = [];
        const seen = new Set();
        for (const [key, value] of root._layout) {
            let entry = entries.get(key);
            if (!entry) {
                entry = appEntryComp.createObject(null, { appId: key, toplevels: value.toplevels, pinned: value.pinned });
                entries.set(key, entry);
            } else {
                if (entry.pinned !== value.pinned)
                    entry.pinned = value.pinned;
                if (!root._sameItems(entry.toplevels, value.toplevels))
                    entry.toplevels = value.toplevels;
            }
            seen.add(key);
            values.push(entry);
        }
        for (const key of Array.from(entries.keys())) {
            if (!seen.has(key))
                entries.delete(key);
        }
        if (!root._sameItems(root.apps, values))
            root.apps = values;
    }

    component TaskbarAppEntry: QtObject {
        id: wrapper
        required property string appId
        required property list<var> toplevels
        required property bool pinned
    }
    Component {
        id: appEntryComp
        TaskbarAppEntry {}
    }
}

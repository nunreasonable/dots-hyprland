pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    function isPinned(appId) {
        return Config.options.dock.pinnedApps.indexOf(appId) !== -1;
    }

    function togglePin(appId) {
        if (root.isPinned(appId)) {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.filter(id => id !== appId)
        } else {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.concat([appId])
        }
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

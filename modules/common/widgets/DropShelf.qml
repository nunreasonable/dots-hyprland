pragma Singleton
pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell

Singleton {
    id: root

    property list<string> items: []

    function show(urls, screen, x, y) {
        root.addItems(urls);
        GlobalStates.dropoverScreen = screen;
        GlobalStates.dropoverX = x;
        GlobalStates.dropoverY = y;
        GlobalStates.dropoverOpen = true;
    }

    function addItems(urls) {
        const incoming = urls.map(u => FileUtils.trimFileProtocol(u.toString()));
        const merged = [...root.items];
        for (const path of incoming) {
            if (path.length > 0 && !merged.includes(path))
                merged.push(path);
        }
        root.items = merged;
    }

    function removeItem(path) {
        root.items = root.items.filter(p => p !== path);
    }

    function clear() {
        root.items = [];
    }

    function copyAll() {
        if (root.items.length === 0)
            return;
        const urls = root.items.map(p => Qt.resolvedUrl(p).toString()).join("\n");
        Quickshell.clipboardText = urls;
    }

    function hide() {
        GlobalStates.dropoverOpen = false;
    }
}

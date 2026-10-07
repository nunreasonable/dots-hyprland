pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property int gateHops: 3
    property int hops: 0
    property var pending: []

    function add(loader) {
        root.pending.push(loader);
        root.pending.sort((a, b) => b.deferPriority - a.deferPriority);
        root.hops = 0;
        if (!releaseTimer.running)
            releaseTimer.start();
    }

    function remove(loader) {
        const index = root.pending.indexOf(loader);
        if (index !== -1)
            root.pending.splice(index, 1);
    }

    Timer {
        id: releaseTimer
        interval: 0
        onTriggered: {
            if (root.hops < root.gateHops) {
                root.hops++;
            } else {
                while (root.pending.length > 0) {
                    const loader = root.pending.shift();
                    loader.released = true;
                    if (loader.active)
                        break;
                }
            }
            if (root.pending.length > 0)
                releaseTimer.restart();
        }
    }
}

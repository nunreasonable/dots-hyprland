pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property int gateHops: 2
    property int hops: 0
    property var pending: []
    property bool drained: false

    function add(loader) {
        root.pending.push(loader);
        root.pending.sort((a, b) => b.deferPriority - a.deferPriority);
        root.hops = 0;
        root.drained = false;
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
            else
                root.drained = true;
        }
    }
}

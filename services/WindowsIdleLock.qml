pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell

Singleton {
    id: root

    function load() {}

    readonly property int lockSeconds: Config.options.windowsPort.idle.lock
    readonly property bool paused: Idle.inhibit || WindowsGameMode.enabled
    readonly property bool active: Platform.isWindows && WindowsNative.ready
        && root.lockSeconds > 0 && !root.paused

    property bool _armed: false

    onPausedChanged: root._armed = false
    onActiveChanged: root._armed = false

    Timer {
        interval: 5000
        repeat: true
        triggeredOnStart: true
        running: root.active

        onTriggered: {
            const idlePower = WindowsNative.idlePower;
            if (!idlePower) return;

            const idle = idlePower.idleSeconds();
            if (idle < 0) return;

            if (idle < root.lockSeconds) {
                root._armed = true;
                return;
            }

            if (root._armed) {
                root._armed = false;
                WindowsNative.session?.lock();
            }
        }
    }
}

pragma Singleton

import QtQml
import QtQuick
import Quickshell
import qs.modules.common

/**
 * Safe-to-import-everywhere gateway to the native Quickshell.Windows singletons
 * (Session, SystemStats, Brightness, Keyboard, Clipboard, Credentials, Input, NightLight, Hotkeys).
 *
 * Services that need one of those read it from here (e.g. `WindowsNative.stats.cpuUsage`)
 * instead of importing Quickshell.Windows directly, since that module only exists on
 * Windows - see WindowsNativeImpl.qml for why a direct import would break Linux.
 *
 * Every property below is null until `ready` (false on Linux, and briefly during Windows
 * startup while the component loads).
 */
Singleton {
    id: root

    readonly property bool ready: _impl !== null
    property QtObject _impl: null

    readonly property QtObject session: _impl ? _impl.session : null
    readonly property QtObject stats: _impl ? _impl.stats : null
    readonly property QtObject brightness: _impl ? _impl.brightness : null
    readonly property QtObject keyboard: _impl ? _impl.keyboard : null
    readonly property QtObject clipboard: _impl ? _impl.clipboard : null
    readonly property QtObject credentials: _impl ? _impl.credentials : null
    readonly property QtObject input: _impl ? _impl.input : null
    readonly property QtObject nightLight: _impl ? _impl.nightLight : null
    readonly property QtObject hotkeys: _impl ? _impl.hotkeys : null
    readonly property QtObject wallpaper: _impl ? _impl.wallpaper : null
    readonly property QtObject imageTools: _impl ? _impl.imageTools : null
    readonly property QtObject thumbnailer: _impl ? _impl.thumbnailer : null
    readonly property QtObject fsUtils: _impl ? _impl.fsUtils : null

    Component.onCompleted: {
        if (!Platform.isWindows) return;

        const comp = Qt.createComponent(Qt.resolvedUrl("WindowsNativeImpl.qml"));

        const finish = () => {
            if (comp.status === Component.Ready) {
                root._impl = comp.createObject(root);
            } else if (comp.status === Component.Error) {
                console.error("[WindowsNative] Failed to load backend:", comp.errorString());
            }
        };

        if (comp.status === Component.Ready || comp.status === Component.Error) {
            finish();
        } else {
            comp.statusChanged.connect(finish);
        }
    }
}

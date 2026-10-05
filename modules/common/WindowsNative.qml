pragma Singleton

import QtQml
import QtQuick
import Quickshell
import qs.modules.common

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
    readonly property QtObject notificationSettings: _impl ? _impl.notificationSettings : null
    readonly property QtObject network: _impl ? _impl.network : null
    readonly property QtObject wallpaper: _impl ? _impl.wallpaper : null
    readonly property QtObject imageTools: _impl ? _impl.imageTools : null
    readonly property QtObject thumbnailer: _impl ? _impl.thumbnailer : null
    readonly property QtObject fsUtils: _impl ? _impl.fsUtils : null
    readonly property QtObject taskbar: _impl ? _impl.taskbar : null
    readonly property QtObject desktopLayer: _impl ? _impl.desktopLayer : null
    readonly property QtObject screenshot: _impl ? _impl.screenshot : null
    readonly property QtObject ocr: _impl ? _impl.ocr : null
    readonly property QtObject screenRecorder: _impl ? _impl.screenRecorder : null
    readonly property QtObject terminalColors: _impl ? _impl.terminalColors : null
    readonly property QtObject tiling: _impl ? _impl.tiling : null

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

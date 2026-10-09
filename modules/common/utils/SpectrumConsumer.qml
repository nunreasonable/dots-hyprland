import QtQuick
import qs.services

QtObject {
    id: root

    property bool active: false
    property bool registered: false

    function sync(alive) {
        const want = alive && root.active;
        if (want === root.registered)
            return;
        AudioSpectrum.consumers += want ? 1 : -1;
        root.registered = want;
    }

    onActiveChanged: root.sync(true)
    Component.onCompleted: root.sync(true)
    Component.onDestruction: root.sync(false)
}

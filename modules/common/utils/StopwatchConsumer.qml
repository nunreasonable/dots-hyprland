import QtQuick
import qs.services

QtObject {
    id: root

    property bool active: false
    property bool centiseconds: false
    property int registeredMode: -1

    function sync(alive) {
        const mode = alive && root.active ? (root.centiseconds ? 1 : 0) : -1;
        if (mode === root.registeredMode)
            return;
        if (root.registeredMode === 1)
            TimerService.stopwatchCentisecondConsumers--;
        else if (root.registeredMode === 0)
            TimerService.stopwatchSecondConsumers--;
        root.registeredMode = mode;
        if (mode === 1)
            TimerService.stopwatchCentisecondConsumers++;
        else if (mode === 0)
            TimerService.stopwatchSecondConsumers++;
    }

    onActiveChanged: root.sync(true)
    onCentisecondsChanged: root.sync(true)
    Component.onCompleted: root.sync(true)
    Component.onDestruction: root.sync(false)
}

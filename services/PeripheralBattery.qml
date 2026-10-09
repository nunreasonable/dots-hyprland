pragma Singleton

import qs.services
import qs.modules.common
import Quickshell
import Quickshell.Bluetooth
import QtQuick

Singleton {
    id: root

    function load() {}

    readonly property var devices: Bluetooth.devices.values.filter(dev => dev.batteryAvailable)

    function isLow(dev) {
        return dev.battery > 0 && dev.battery <= Config.options.battery.peripheralLow / 100;
    }
    function isCritical(dev) {
        return dev.battery > 0 && dev.battery <= Config.options.battery.peripheralCritical / 100;
    }

    readonly property var lowDevices: root.devices.filter(dev => root.isLow(dev))

    Instantiator {
        model: ScriptModel {
            values: root.devices
            objectProp: "address"
        }
        delegate: QtObject {
            id: tracker
            required property var modelData
            readonly property string name: modelData.name || Translation.tr("Device")
            readonly property bool low: root.isLow(modelData)
            readonly property bool critical: root.isCritical(modelData)

            onLowChanged: {
                if (!tracker.low || tracker.critical || !Config.options.battery.peripheralNotify)
                    return;
                Notifications.sendDesktop(Translation.tr("%1 battery low").arg(tracker.name), Translation.tr("%1% remaining").arg(Math.round(tracker.modelData.battery * 100)), ["-a", "Shell", "--hint=int:transient:1"]);
            }
            onCriticalChanged: {
                if (!tracker.critical || !Config.options.battery.peripheralNotify)
                    return;
                Notifications.sendDesktop(Translation.tr("%1 battery critically low").arg(tracker.name), Translation.tr("%1% remaining, please charge it").arg(Math.round(tracker.modelData.battery * 100)), ["-u", "critical", "-a", "Shell", "--hint=int:transient:1"]);
            }
        }
    }
}

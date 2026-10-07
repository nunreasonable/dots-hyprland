import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets
import QtQuick
import Quickshell

AbstractBackgroundWidget {
    id: root

    configEntryName: "resources"

    implicitWidth: contentRow.implicitWidth
    implicitHeight: contentRow.implicitHeight

    property var diskUsage: ({})
    readonly property real diskRatio: {
        const used = root.diskUsage.usedBytes;
        const total = root.diskUsage.totalBytes;
        if (typeof used !== "number" || typeof total !== "number" || total <= 0) return 0;
        return Math.max(0, Math.min(1, used / total));
    }

    function refreshDisk() {
        if (!Platform.isWindows || !WindowsNative.systemMonitor) return;
        const drive = (Quickshell.env("SystemDrive") || "C:") + "\\";
        root.diskUsage = WindowsNative.systemMonitor.volumeUsage(drive) ?? {};
    }

    Connections {
        target: Platform.isWindows ? WindowsNative : null
        function onReadyChanged() {
            if (WindowsNative.ready) root.refreshDisk();
        }
    }

    Timer {
        interval: 30000
        triggeredOnStart: true
        repeat: true
        running: Platform.isWindows && WindowsNative.ready && WindowsNative.systemMonitor !== null
        onTriggered: root.refreshDisk()
    }

    Row {
        id: contentRow
        spacing: 10

        ResourcesStatCard {
            icon: "settings"
            percentValue: ResourceUsage.cpuUsage
            label: Translation.tr("CPU")
        }
        ResourcesStatCard {
            icon: "memory_alt"
            percentValue: ResourceUsage.memoryUsedPercentage
            label: Translation.tr("RAM")
        }
        ResourcesStatCard {
            visible: Platform.isWindows
            icon: "storage"
            percentValue: root.diskRatio
            label: Translation.tr("Disk")
        }
    }
}

pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple polled resource usage service with RAM, Swap, and CPU usage.
 */
Singleton {
    id: root
	property real memoryTotal: Platform.isWindows ? (WindowsNative.stats ? WindowsNative.stats.memoryTotalKb : 1) : 1
	property real memoryFree: Platform.isWindows ? (WindowsNative.stats ? WindowsNative.stats.memoryAvailableKb : 0) : 0
	property real memoryUsed: memoryTotal - memoryFree
    property real memoryUsedPercentage: memoryUsed / memoryTotal
    property real swapTotal: Platform.isWindows ? (WindowsNative.stats ? WindowsNative.stats.swapTotalKb : 1) : 1
	property real swapFree: Platform.isWindows ? (WindowsNative.stats ? WindowsNative.stats.swapAvailableKb : 0) : 0
	property real swapUsed: swapTotal - swapFree
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
    property real cpuUsage: Platform.isWindows ? (WindowsNative.stats ? WindowsNative.stats.cpuUsage : 0) : 0
    property var previousCpuStats

    property string maxAvailableMemoryString: kbToGbString(ResourceUsage.memoryTotal)
    property string maxAvailableSwapString: kbToGbString(ResourceUsage.swapTotal)
    property string maxAvailableCpuString: Platform.isWindows ? (WindowsNative.stats ? WindowsNative.stats.cpuName : "--") : "--"

    readonly property bool cpuTempAvailable: !Platform.isWindows
    property real cpuTemp: 0
    property int cpuTempConsumers: 0
    property string thermalPath: ""
    property bool thermalSearched: false
    property int diskConsumers: 0
    property real diskTotal: 1
    property real diskUsed: 0
    property real diskFree: 0
    property real diskUsedPercentage: diskTotal > 0 ? diskUsed / diskTotal : 0
    property string maxAvailableDiskString: kbToGbString(diskTotal)

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    function updateMemoryUsageHistory() {
        memoryUsageHistory = [...memoryUsageHistory, memoryUsedPercentage]
        if (memoryUsageHistory.length > historyLength) {
            memoryUsageHistory.shift()
        }
    }
    function updateSwapUsageHistory() {
        swapUsageHistory = [...swapUsageHistory, swapUsedPercentage]
        if (swapUsageHistory.length > historyLength) {
            swapUsageHistory.shift()
        }
    }
    function updateCpuUsageHistory() {
        cpuUsageHistory = [...cpuUsageHistory, cpuUsage]
        if (cpuUsageHistory.length > historyLength) {
            cpuUsageHistory.shift()
        }
    }
    function updateHistories() {
        updateMemoryUsageHistory()
        updateSwapUsageHistory()
        updateCpuUsageHistory()
    }

	Timer {
		interval: Config.options?.resources?.updateInterval ?? 3000
		running: Platform.isWindows
		repeat: true
		onTriggered: root.updateHistories()
	}

	Timer {
		interval: 1
        running: !Platform.isWindows
        repeat: true
		onTriggered: {
            // Reload files
            fileMeminfo.reload()
            fileStat.reload()

            // Parse memory and swap usage
            const textMeminfo = fileMeminfo.text()
            memoryTotal = Number(textMeminfo.match(/MemTotal: *(\d+)/)?.[1] ?? 1)
            memoryFree = Number(textMeminfo.match(/MemAvailable: *(\d+)/)?.[1] ?? 0)
            swapTotal = Number(textMeminfo.match(/SwapTotal: *(\d+)/)?.[1] ?? 1)
            swapFree = Number(textMeminfo.match(/SwapFree: *(\d+)/)?.[1] ?? 0)

            // Parse CPU usage
            const textStat = fileStat.text()
            const cpuLine = textStat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
            if (cpuLine) {
                const stats = cpuLine.slice(1).map(Number)
                const total = stats.reduce((a, b) => a + b, 0)
                const idle = stats[3]

                if (previousCpuStats) {
                    const totalDiff = total - previousCpuStats.total
                    const idleDiff = idle - previousCpuStats.idle
                    cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0
                }

                previousCpuStats = { total, idle }
            }

            root.updateHistories()
            interval = Config.options?.resources?.updateInterval ?? 3000
        }
	}

    function refreshDisk() {
        if (!Platform.isWindows) {
            diskProc.running = false;
            diskProc.running = true;
            return;
        }
        const monitor = WindowsNative.systemMonitor;
        if (!monitor)
            return;
        const usage = monitor.volumeUsage((Quickshell.env("SystemDrive") || "C:") + "\\") ?? {};
        if (typeof usage.totalBytes !== "number" || usage.totalBytes <= 0)
            return;
        root.diskTotal = usage.totalBytes / 1024;
        root.diskUsed = usage.usedBytes / 1024;
        root.diskFree = root.diskTotal - root.diskUsed;
    }

    function readCpuTemp() {
        const raw = parseFloat(fileTemp.text().trim());
        if (!isNaN(raw) && raw > 0)
            root.cpuTemp = raw > 200 ? Math.round(raw / 100) / 10 : raw;
    }

    onCpuTempConsumersChanged: {
        if (root.cpuTempConsumers > 0 && root.cpuTempAvailable && !root.thermalSearched && !findThermalPathProc.running) {
            root.thermalSearched = true;
            findThermalPathProc.running = true;
        }
    }

    Timer {
        interval: 30000
        triggeredOnStart: true
        repeat: true
        running: root.diskConsumers > 0 && (!Platform.isWindows || WindowsNative.ready)
        onTriggered: root.refreshDisk()
    }

    Timer {
        interval: Config.options?.resources?.updateInterval ?? 3000
        triggeredOnStart: true
        repeat: true
        running: root.cpuTempAvailable && root.cpuTempConsumers > 0 && root.thermalPath.length > 0
        onTriggered: {
            fileTemp.reload();
            root.readCpuTemp();
        }
    }

    Process {
        id: diskProc
        command: ["df", "-k", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                if (lines.length < 2)
                    return;
                const parts = lines[1].trim().split(/\s+/).map(Number);
                if (parts.length < 4)
                    return;
                root.diskTotal = parts[1];
                root.diskUsed = parts[2];
                root.diskFree = parts[3];
            }
        }
    }

    Process {
        id: findThermalPathProc
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do [ -d \"$h\" ] || continue; for l in \"$h\"/temp*_label; do [ -f \"$l\" ] || continue; if grep -qE 'Package id 0|Tctl|Tdie' \"$l\" 2>/dev/null; then inp=\"${l%_label}_input\"; [ -f \"$inp\" ] && echo \"$inp\" && exit 0; fi; done; done; for z in /sys/class/thermal/thermal_zone*; do [ -d \"$z\" ] || continue; type=$(cat \"$z/type\" 2>/dev/null); case \"$type\" in x86_pkg_temp|cpu*|TCPU) [ -f \"$z/temp\" ] && echo \"$z/temp\" && exit 0;; esac; done; for t in /sys/class/hwmon/hwmon*/temp1_input /sys/class/thermal/thermal_zone0/temp; do [ -f \"$t\" ] && echo \"$t\" && exit 0; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = text.trim();
                if (found.length > 0)
                    root.thermalPath = found;
            }
        }
    }

    FileView {
        id: fileTemp
        path: root.thermalPath
        printErrors: false
        onLoaded: root.readCpuTemp()
    }

	FileView { id: fileMeminfo; path: Platform.isWindows ? "" : "/proc/meminfo" }
    FileView { id: fileStat; path: Platform.isWindows ? "" : "/proc/stat" }

    Process {
        id: findCpuMaxFreqProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-c", "lscpu | grep 'CPU max MHz' | awk '{print $4}'"]
        running: !Platform.isWindows
        stdout: StdioCollector {
            id: outputCollector
            onStreamFinished: {
                root.maxAvailableCpuString = (parseFloat(outputCollector.text) / 1000).toFixed(0) + " GHz"
            }
        }
    }
}

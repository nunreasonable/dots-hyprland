pragma Singleton
pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property list<real> points: []
    readonly property bool playing: MprisController.activePlayer?.isPlaying ?? false
    readonly property bool barShown: GlobalStates.barOpen && !GlobalStates.screenLocked && !(Platform.isWindows && Config.options.windowsPort.nativeTaskbar)
    readonly property bool barVisualizer: !BarLayouts.classic && (BarLayouts.leftLayout.includes("visualizer") || BarLayouts.middleLayout.includes("visualizer") || BarLayouts.rightLayout.includes("visualizer"))
    readonly property bool islandVisualizer: BarLayouts.middleLayout.includes("dynamicIsland") && (Config.options.bar.dynamicIsland.visualizerStyle === "wave" || (Config.options.bar.dynamicIsland.visualizerStyle === "dots" && !Config.options.bar.dynamicIsland.showMediaControls))
    readonly property bool desktopVisualizer: Config.options.background.widgets.visualizer.enable
    readonly property bool wanted: GlobalStates.mediaControlsOpen || root.desktopVisualizer || (root.barShown && root.playing && (root.barVisualizer || root.islandVisualizer))

    onWantedChanged: {
        if (!root.wanted)
            root.points = [];
    }

    Process {
        id: cavaProc
        running: root.wanted && !Platform.isWindows
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                root.points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
            }
        }
    }

    Binding {
        when: Platform.isWindows && WindowsNative.ready
        target: WindowsNative.audioVisualizer
        property: "running"
        value: root.wanted
    }

    Binding {
        when: Platform.isWindows && WindowsNative.ready
        target: WindowsNative.audioVisualizer
        property: "framerate"
        value: 30
    }

    Connections {
        target: Platform.isWindows ? WindowsNative.audioVisualizer : null
        function onValuesChanged() {
            root.points = WindowsNative.audioVisualizer.values;
        }
    }
}

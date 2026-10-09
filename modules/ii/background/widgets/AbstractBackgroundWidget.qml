import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets.widgetCanvas

AbstractWidget {
    id: root

    required property string configEntryName
    required property int screenWidth
    required property int screenHeight
    required property int scaledScreenWidth
    required property int scaledScreenHeight
    required property real wallpaperScale
    property Item wallpaperItem: null
    property bool visibleWhenLocked: Config.options.lock.showWidgets
    property var configEntry: Config.options.background.widgets[configEntryName]
    property string placementStrategy: configEntry.placementStrategy
    property real targetX: Math.max(0, Math.min(configEntry.x, scaledScreenWidth - width))
    property real targetY : Math.max(0, Math.min(configEntry.y, scaledScreenHeight - height))
    property real targetZ: configEntry.z ?? 0
    x: targetX
    y: targetY
    z: targetZ
    visible: opacity > 0
    opacity: (GlobalStates.screenLocked && !visibleWhenLocked) ? 0 : 1
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    scale: (draggable && containsPress) ? 1.05 : 1
    Behavior on scale {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    draggable: placementStrategy === "free" && !Config.options.background.widgetsLocked

    function requestDelete() {
        Config.options.background.widgets[root.configEntryName].enable = false;
    }

    function restoreXYBinding() {
        root.x = Qt.binding(() => root.targetX);
        root.y = Qt.binding(() => root.targetY);
        root.z = Qt.binding(() => root.targetZ);
    }

    function commitPosition() {
        configEntry.x = root.x;
        configEntry.y = root.y;
        configEntry.z = root.z;
        root.targetX = Qt.binding(() => Math.max(0, Math.min(configEntry.x, scaledScreenWidth - width)));
        root.targetY = Qt.binding(() => Math.max(0, Math.min(configEntry.y, scaledScreenHeight - height)));
        root.targetZ = Qt.binding(() => configEntry.z ?? 0);
        root.restoreXYBinding();
    }

    onReleased: root.commitPosition()

    property bool needsColText: false
    property color dominantColor: Appearance.colors.colPrimary
    property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
    property color colText: {
        const onNormalBackground = (GlobalStates.screenLocked && Config.options.lock.blur.enable)
        const adaptiveColor = ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (dominantColorIsDark ? 0.8 : 0.12))
        return onNormalBackground ? Appearance.colors.colOnLayer0 : adaptiveColor;
    }

    property bool wallpaperIsVideo: Config.options.background.wallpaperPath.endsWith(".mp4") || Config.options.background.wallpaperPath.endsWith(".webm") || Config.options.background.wallpaperPath.endsWith(".mkv") || Config.options.background.wallpaperPath.endsWith(".avi") || Config.options.background.wallpaperPath.endsWith(".mov")
    property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath
    
    onWallpaperPathChanged: refreshPlacementIfNeeded()
    onPlacementStrategyChanged: refreshPlacementIfNeeded()
    Connections {
        target: Platform.isWindows ? WindowsNative : null
        function onReadyChanged() { if (WindowsNative.ready) root.refreshPlacementIfNeeded() }
    }
    Connections {
        target: Config
        function onReadyChanged() { refreshPlacementIfNeeded() }
    }
    // TODO: make these less arbitrary
    readonly property int leastBusyContentWidth: 300
    readonly property int leastBusyContentHeight: 300
    readonly property int leastBusyHorizontalPadding: 200
    readonly property int leastBusyVerticalPadding: 200

    property int _windowsRequestId: -1

    function refreshPlacementIfNeeded() {
        if (!Config.ready) return;
        if (root.placementStrategy === "free" && !root.needsColText) return;

        if (Platform.isWindows) {
            if (!WindowsNative.imageTools) return;
            if (!root.wallpaperPath) return;
            windowsRefreshDebounce.restart();
            return;
        }

        leastBusyRegionProc.wallpaperPath = root.wallpaperPath;
        leastBusyRegionProc.running = false;
        leastBusyRegionProc.running = true;
    }

    function windowsRequestPlacement() {
        if (!Config.ready) return;
        if (root.placementStrategy === "free" && !root.needsColText) return;
        if (!WindowsNative.imageTools) return;
        if (!root.wallpaperPath) return;

        root._windowsRequestId = WindowsNative.imageTools.requestLeastBusyRegion(
            root.wallpaperPath,
            root.leastBusyContentWidth,
            root.leastBusyContentHeight,
            Math.round(root.scaledScreenWidth),
            Math.round(root.scaledScreenHeight),
            root.leastBusyHorizontalPadding,
            root.leastBusyVerticalPadding,
            root.placementStrategy === "mostBusy"
        );
    }

    Timer {
        id: windowsRefreshDebounce
        interval: 0
        repeat: false
        onTriggered: root.windowsRequestPlacement()
    }

    Connections {
        target: Platform.isWindows ? WindowsNative.imageTools : null
        function onLeastBusyRegionReady(requestId, result) {
            if (requestId !== root._windowsRequestId) return;
            root.applyPlacement(result);
        }
    }

    function applyPlacement(parsedContent) {
        if (!parsedContent || parsedContent.error) return;
        root.dominantColor = parsedContent.dominant_color || Appearance.colors.colPrimary;
        if (root.placementStrategy === "free") return;
        root.targetX = parsedContent.center_x * root.wallpaperScale - root.width / 2;
        root.targetY  = parsedContent.center_y * root.wallpaperScale - root.height / 2;
    }

    Process {
        id: leastBusyRegionProc
        property string wallpaperPath: root.wallpaperPath
        command: [Quickshell.shellPath("scripts/images/least-busy-region-venv.sh") // Comments to force the formatter to break lines
            , "--screen-width", Math.round(root.scaledScreenWidth) //
            , "--screen-height", Math.round(root.scaledScreenHeight) //
            , "--width", root.leastBusyContentWidth //
            , "--height", root.leastBusyContentHeight //
            , "--horizontal-padding", root.leastBusyHorizontalPadding //
            , "--vertical-padding", root.leastBusyVerticalPadding //
            , wallpaperPath //
            , ...(root.placementStrategy === "mostBusy" ? ["--busiest"] : [])
            // "--visual-output",
        ]
        stdout: StdioCollector {
            id: leastBusyRegionOutputCollector
            onStreamFinished: {
                const output = leastBusyRegionOutputCollector.text;
                // console.log("[Background] Least busy region output:", output)
                if (output.length === 0) return;
                root.applyPlacement(JSON.parse(output));
            }
        }
    }
}


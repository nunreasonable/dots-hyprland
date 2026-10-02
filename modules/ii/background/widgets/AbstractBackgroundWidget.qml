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
    property bool visibleWhenLocked: false
    property var configEntry: Config.options.background.widgets[configEntryName]
    property string placementStrategy: configEntry.placementStrategy
    property real targetX: Math.max(0, Math.min(configEntry.x, scaledScreenWidth - width))
    property real targetY : Math.max(0, Math.min(configEntry.y, scaledScreenHeight - height))
    x: targetX
    y: targetY
    visible: opacity > 0
    opacity: (GlobalStates.screenLocked && !visibleWhenLocked) ? 0 : 1
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    scale: (draggable && containsPress) ? 1.05 : 1
    Behavior on scale {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    draggable: placementStrategy === "free"
    onReleased: {
        root.targetX = root.x;
        root.targetY = root.y;
        configEntry.x = root.targetX;
        configEntry.y = root.targetY;
    }

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
        target: Config
        function onReadyChanged() { refreshPlacementIfNeeded() }
    }
    // TODO: make these less arbitrary
    readonly property int leastBusyContentWidth: 300
    readonly property int leastBusyContentHeight: 300
    readonly property int leastBusyHorizontalPadding: 200
    readonly property int leastBusyVerticalPadding: 200

    function refreshPlacementIfNeeded() {
        if (!Config.ready) return;
        if (root.placementStrategy === "free" && !root.needsColText) return;

        if (Platform.isWindows) {
            if (!WindowsNative.imageTools) return; // native backend not ready yet
            if (!root.wallpaperPath) return; // nothing to place against (the script finds nothing either)
            const result = WindowsNative.imageTools.leastBusyRegion(
                root.wallpaperPath,
                root.leastBusyContentWidth,
                root.leastBusyContentHeight,
                Math.round(root.scaledScreenWidth),
                Math.round(root.scaledScreenHeight),
                root.leastBusyHorizontalPadding,
                root.leastBusyVerticalPadding,
                root.placementStrategy === "mostBusy"
            );
            root.applyPlacement(result);
            return;
        }

        leastBusyRegionProc.wallpaperPath = root.wallpaperPath;
        leastBusyRegionProc.running = false;
        leastBusyRegionProc.running = true;
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


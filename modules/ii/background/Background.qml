pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.common.functions as CF
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.modules.ii.background.widgets
import qs.modules.ii.background.widgets.clock
import qs.modules.ii.background.widgets.weather
import qs.modules.ii.background.widgets.resources
import qs.modules.ii.background.widgets.calendar
import qs.modules.ii.background.widgets.customtext
import qs.modules.ii.background.widgets.images
import qs.modules.ii.background.widgets.media
import qs.modules.ii.background.widgets.notes
import qs.modules.ii.background.widgets.timers
import qs.modules.ii.background.widgets.todo
import qs.modules.ii.background.widgets.usercard
import qs.modules.ii.background.widgets.visualizer
import qs.modules.ii.background.widgets.worldclock

Variants {
    id: root
    model: Quickshell.screens

    component WidgetMaskRegion: Region {
        required property Loader loader
        required property Item canvas
        readonly property Item widget: loader.item
        readonly property bool shown: widget !== null && loader.visible && widget.visible
        readonly property int padding: 16
        x: shown ? Math.floor(canvas.x + loader.x + widget.x) - padding : 0
        y: shown ? Math.floor(canvas.y + loader.y + widget.y) - padding : 0
        width: shown ? Math.ceil(widget.width) + padding * 2 : 0
        height: shown ? Math.ceil(widget.height) + padding * 2 : 0
    }

    PanelWindow {
        id: bgRoot

        required property var modelData

        // Hide when fullscreen
        property list<HyprlandWorkspace> workspacesForMonitor: Hyprland.workspaces.values.filter(workspace => workspace.monitor && workspace.monitor.name == monitor.name)
        property var activeWorkspaceWithFullscreen: workspacesForMonitor.filter(workspace => ((workspace.toplevels.values.filter(window => window.wayland?.fullscreen)[0] != undefined) && workspace.active))[0]
        visible: (GlobalStates.screenLocked || (!(activeWorkspaceWithFullscreen != undefined)) || !Config?.options.background.hideWhenFullscreen) && !(nativeWallpaper && widgetsAboveIcons && !videoLayerActive && !nativePreviewShown)

        // Workspaces
        property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
        property list<var> relevantWindows: HyprlandData.windowList.filter(win => win.monitor == monitor?.id && win.workspace.id >= 0).sort((a, b) => a.workspace.id - b.workspace.id)
        property int firstWorkspaceId: relevantWindows[0]?.workspace.id || 1
        property int lastWorkspaceId: relevantWindows[relevantWindows.length - 1]?.workspace.id || 10
        property int workspaceChunkSize: Config?.options.bar.workspaces.shown ?? 10
        property int totalWorkspaces: Math.ceil(lastWorkspaceId / workspaceChunkSize) * workspaceChunkSize
        // Wallpaper
        readonly property string effectiveWallpaperPath: bgRoot.currentEffectivePath()
        property bool wallpaperIsVideo: Wallpapers.isVideoPath(bgRoot.effectiveWallpaperPath)
        readonly property string targetWallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : effectiveWallpaperPath
        property string wallpaperPath: ""
        readonly property bool videoLayerActive: Platform.isWindows && wallpaperIsVideo && !wallpaperSafetyTriggered
        readonly property bool showVideoFrame: videoLayerActive && !(videoWallpaperLoader.item?.ready ?? false)
        readonly property bool desktopCovered: HyprlandData.windowList.some(win => win.monitor == monitor?.id
            && win.workspace?.id === monitor?.activeWorkspace?.id && (win.fullscreen ?? 0) > 0 && !win.minimized)
        property bool wallpaperSafetyTriggered: {
            const enabled = Config.options.workSafety.enable.wallpaper;
            const sensitiveWallpaper = (CF.StringUtils.stringListContainsSubstring(wallpaperPath.toLowerCase(), Config.options.workSafety.triggerCondition.fileKeywords));
            const sensitiveNetwork = (CF.StringUtils.stringListContainsSubstring(Network.networkName.toLowerCase(), Config.options.workSafety.triggerCondition.networkNameKeywords));
            return enabled && sensitiveWallpaper && sensitiveNetwork;
        }
        readonly property real parallaxRation: bgRoot.nativeWallpaper ? 1 : Config.options.background.parallax.workspaceZoom
        property real minSuitableScale: 1 // Some reasonable init, to be updated
        property real effectiveWallpaperScale: minSuitableScale * parallaxRation
        property int wallpaperWidth: modelData.width // Some reasonable init value, to be updated
        property int wallpaperHeight: modelData.height // Some reasonable init value, to be updated
        property real scaledWallpaperWidth: wallpaperWidth * effectiveWallpaperScale
        property real scaledWallpaperHeight: wallpaperHeight * effectiveWallpaperScale
        property real parallaxTotalPixelsX: Math.max(0, scaledWallpaperWidth - screen.width)
        property real parallaxTotalPixelsY: Math.max(0, scaledWallpaperHeight - screen.height)
        readonly property bool verticalParallax: (Config.options.background.parallax.autoVertical && wallpaperHeight > wallpaperWidth) || Config.options.background.parallax.vertical
        // Colors
        property bool shouldBlur: (GlobalStates.screenLocked && Config.options.lock.blur.enable)
        property color dominantColor: Appearance.colors.colPrimary // Default, to be changed
        property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
        property color colText: {
            if (wallpaperSafetyTriggered)
                return CF.ColorUtils.mix(Appearance.colors.colOnLayer0, Appearance.colors.colPrimary, 0.75);
            return (GlobalStates.screenLocked && shouldBlur) ? Appearance.colors.colOnLayer0 : CF.ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (dominantColorIsDark ? 0.8 : 0.12));
        }
        Behavior on colText {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        readonly property bool widgetsAboveIcons: Platform.isWindows && (WindowsNative.desktopLayer?.active ?? false) && !GlobalStates.screenLocked
        readonly property bool nativeWallpaper: Platform.isWindows && Config.options.windowsPort.backgroundBehindIcons && !Config.options.windowsPort.ownWallpaper
        readonly property Item widgetsSlot: widgetsWindowLoader.active ? (widgetsWindowLoader.item?.slot ?? null) : null
        readonly property bool widgetsOnThisScreen: Config.options.background.screenList.length === 0
            || Config.options.background.screenList.includes(bgRoot.modelData.name)

        readonly property bool previewActive: Wallpapers.previewPath !== ""
        property bool nativePreviewHold: false
        readonly property bool nativePreviewShown: nativeWallpaper && (previewActive || nativePreviewHold)
        readonly property bool drawsWallpaper: !nativeWallpaper || nativePreviewShown

        readonly property real splitFraction: {
            switch (Config.options.background.splitRatio) {
            case "25":
                return 0.28;
            case "50":
                return 0.54;
            default:
                return 1.0;
            }
        }
        readonly property bool overviewBlurActive: Config.options.overview.style === "niri" && GlobalStates.overviewOpen && Config.options.overview.enable
        readonly property bool userBlurActive: Config.options.background.showBlur && !bgRoot.wallpaperIsVideo
        readonly property bool blurFullScreen: bgRoot.overviewBlurActive || bgRoot.splitFraction >= 1.0
        readonly property bool wallpaperBlurActive: (bgRoot.userBlurActive || bgRoot.overviewBlurActive)
            && !bgRoot.nativeWallpaper && !bgRoot.wallpaperSafetyTriggered
            && (!GlobalStates.screenLocked || !centeredWallpaper.centeredWallpaperEnabled || bgRoot.blurFullScreen)

        readonly property var transitionShaders: ["circlePit", "circleSelect", "magic", "Doom", "Peel", "transition", "pixelate", "stripes", "crt", "dissolve", "glitch", "ripple", "shatter"]
        readonly property string wallpaperAnimation: Config.options.background.wallpaperAnimation ?? "random"
        property string transitionShader: "transition"
        property bool transitionLive: false
        property bool transitionPending: false
        property real transitionProgress: 1
        property bool shownWallpaperIsVideo: false
        readonly property bool transitionFailed: transitionLoader.item?.failed ?? false

        // Layer props
        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: (GlobalStates.screenLocked && !scaleAnim.running) ? WlrLayer.Overlay : (Platform.isWindows ? WlrLayer.Background : WlrLayer.Bottom)
        // WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell:background"
        WlrLayershell.keyboardFocus: GlobalStates.desktopWidgetKeyboardFocus ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: {
            if (!bgRoot.wallpaperSafetyTriggered || bgRoot.wallpaperIsVideo)
                return "transparent";
            return CF.ColorUtils.mix(Appearance.colors.colLayer0, Appearance.colors.colPrimary, 0.75);
        }
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        Component.onCompleted: bgRoot.syncWallpaperPath()

        onTargetWallpaperPathChanged: Qt.callLater(bgRoot.syncWallpaperPath)

        onWallpaperPathChanged: {
            bgRoot.updateZoomScale();
            // Clock position gets updated after zoom scale is updated
        }

        onPreviewActiveChanged: {
            if (bgRoot.previewActive) {
                bgRoot.syncWallpaperPath();
                return;
            }
            if (!bgRoot.nativeWallpaper)
                return;
            bgRoot.nativePreviewHold = true;
            nativePreviewHoldTimer.restart();
        }

        onVisibleChanged: {
            if (!bgRoot.visible)
                bgRoot.finishTransition();
        }

        onTransitionFailedChanged: {
            if (bgRoot.transitionFailed)
                Qt.callLater(bgRoot.finishTransition);
        }

        Timer {
            id: nativePreviewHoldTimer
            interval: 1500
            onTriggered: bgRoot.nativePreviewHold = false
        }

        function canAnimateWallpaperChange() {
            return bgRoot.wallpaperAnimation !== "" && bgRoot.visible && bgRoot.drawsWallpaper
                && !bgRoot.wallpaperSafetyTriggered && !bgRoot.shownWallpaperIsVideo
                && wallpaper.status === Image.Ready && wallpaper.visible
                && !blurLoader.active && !centeredWallpaper.centeredShapeActive;
        }

        function currentEffectivePath() {
            if (GlobalStates.screenLocked && Config.options.background.lockWall !== "")
                return Config.options.background.lockWall;
            return Wallpapers.previewPath || Wallpapers.confirmedPath || Config.options.background.wallpaperPath;
        }

        function pickTransitionShader(toVideo) {
            if (toVideo)
                return "transition";
            if (bgRoot.wallpaperAnimation === "random")
                return bgRoot.transitionShaders[Math.floor(Math.random() * bgRoot.transitionShaders.length)];
            return bgRoot.wallpaperAnimation;
        }

        function syncWallpaperPath() {
            const effective = bgRoot.currentEffectivePath();
            const toVideo = Wallpapers.isVideoPath(effective);
            const next = toVideo ? Config.options.background.thumbnailPath : effective;
            if (next === bgRoot.wallpaperPath)
                return;
            bgRoot.finishTransition();
            if (bgRoot.canAnimateWallpaperChange()) {
                bgRoot.transitionShader = bgRoot.pickTransitionShader(toVideo);
                bgRoot.transitionProgress = 0;
                bgRoot.transitionPending = true;
                bgRoot.transitionLive = true;
            }
            bgRoot.shownWallpaperIsVideo = toVideo;
            bgRoot.wallpaperPath = next;
        }

        function finishTransition() {
            transitionAnim.stop();
            bgRoot.transitionPending = false;
            bgRoot.transitionLive = false;
            bgRoot.transitionProgress = 1;
        }

        NumberAnimation {
            id: transitionAnim
            target: bgRoot
            property: "transitionProgress"
            from: 0
            to: 1
            duration: 1000
            easing.type: Easing.InOutQuad
            onFinished: bgRoot.finishTransition()
        }

        Timer {
            interval: 5000
            running: bgRoot.transitionPending
            onTriggered: bgRoot.finishTransition()
        }

        // Wallpaper zoom scale
        function updateZoomScale() {
            if (Platform.isWindows) {
                const size = WindowsNative.imageTools?.imageSize(bgRoot.wallpaperPath);
                if (size && size.width > 0 && size.height > 0) bgRoot.applyWallpaperSize(size.width, size.height);
                return;
            }
            getWallpaperSizeProc.path = bgRoot.wallpaperPath;
            getWallpaperSizeProc.running = true;
        }
        Connections {
            target: Platform.isWindows ? WindowsNative : null
            function onReadyChanged() {
                if (WindowsNative.ready) bgRoot.updateZoomScale();
            }
        }
        Connections {
            target: Platform.isWindows ? bgRoot.modelData : null
            function onGeometryChanged() {
                bgRoot.updateZoomScale();
            }
        }
        function applyWallpaperSize(width, height) {
            const [screenWidth, screenHeight] = [bgRoot.screen.width, bgRoot.screen.height];
            bgRoot.wallpaperWidth = width;
            bgRoot.wallpaperHeight = height;

            // Perfect image; scale = 1
            // Small picture; scale > 1; will zoom in the picture
            // Big picture; scale < 1; will zoom out the picture
            // Choose max number so every side will fit
            bgRoot.minSuitableScale = Math.max(screenWidth / width, screenHeight / height);
        }
        Process {
            id: getWallpaperSizeProc
            property string path: bgRoot.wallpaperPath
            command: ["magick", "identify", "-format", "%w %h", path]
            stdout: StdioCollector {
                id: wallpaperSizeOutputCollector
                onStreamFinished: {
                    const output = wallpaperSizeOutputCollector.text;
                    const [width, height] = output.split(" ").map(Number);
                    bgRoot.applyWallpaperSize(width, height);
                }
            }
        }

        LazyLoader {
            id: widgetsWindowLoader
            activeAsync: Platform.isWindows

            PanelWindow {
                id: widgetsWindow
                readonly property Item slot: widgetsSlotItem

                screen: bgRoot.modelData
                visible: bgRoot.widgetsAboveIcons
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.namespace: "quickshell:backgroundWidgets"
                WlrLayershell.keyboardFocus: GlobalStates.desktopWidgetKeyboardFocus ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }
                color: "transparent"

                mask: Region {
                    WidgetMaskRegion {
                        loader: weatherLoader
                        canvas: widgetCanvas
                    }
                    WidgetMaskRegion {
                        loader: clockLoader
                        canvas: widgetCanvas
                    }
                    WidgetMaskRegion {
                        loader: resourcesLoader
                        canvas: widgetCanvas
                    }
                    WidgetMaskRegion {
                        loader: calendarLoader
                        canvas: widgetCanvas
                    }
                    WidgetMaskRegion {
                        loader: customTextLoader
                        canvas: widgetCanvas
                    }
                    WidgetMaskRegion {
                        loader: customImageLoader
                        canvas: widgetCanvas
                    }
                    WidgetMaskRegion {
                        loader: imageCardLoader
                        canvas: widgetCanvas
                    }
                    WidgetMaskRegion {
                        loader: stickerLoader
                        canvas: widgetCanvas
                    }
                    WidgetMaskRegion {
                        loader: imageConverterLoader
                        canvas: widgetCanvas
                    }
                    WidgetMaskRegion {
                        loader: mediaWidgetLoader
                        canvas: widgetCanvas
                    }
                    WidgetMaskRegion {
                        loader: notesLoader
                        canvas: widgetCanvas
                    }
                    WidgetMaskRegion {
                        loader: timersLoader
                        canvas: widgetCanvas
                    }
                    WidgetMaskRegion {
                        loader: todoLoader
                        canvas: widgetCanvas
                    }
                    WidgetMaskRegion {
                        loader: userCardLoader
                        canvas: widgetCanvas
                    }
                    WidgetMaskRegion {
                        loader: visualizerLoader
                        canvas: widgetCanvas
                    }
                    WidgetMaskRegion {
                        loader: worldClockLoader
                        canvas: widgetCanvas
                    }
                }

                Item {
                    id: widgetsSlotItem
                    anchors.fill: parent
                }
            }
        }

        Item {
            id: wallpaperLayer
            anchors.fill: parent

            Item {
                id: wallpaperFrame
                anchors.fill: parent

                // Wallpaper
                StyledImage {
                    id: wallpaper
                    visible: opacity > 0 && !blurLoader.active && !centeredWallpaper.centeredHidesFullWallpaper
                    opacity: ((status === Image.Ready || bgRoot.transitionLive) && (!bgRoot.wallpaperIsVideo || bgRoot.showVideoFrame))
                        ? centeredWallpaper.centeredFullWallpaperOpacity() : 0
                    cache: false
                    smooth: false

                    property int workspaceIndex: (bgRoot.monitor.activeWorkspace?.id ?? 1) - 1
                    property real middleFraction: 0.5
                    property real fraction: {
                        // 0 - start of the picture
                        // 1 - end of the picture
                        if (bgRoot.totalWorkspaces <= 1) {
                            return middleFraction;
                        }
                        return Math.max(0, Math.min(1, workspaceIndex / (bgRoot.totalWorkspaces - 1)));
                    }

                    property real usedFractionX: {
                        let usedFraction = middleFraction;
                        if (bgRoot.nativeWallpaper) {
                            return usedFraction;
                        }
                        if (Config.options.background.parallax.enableWorkspace && !bgRoot.verticalParallax) {
                            usedFraction = fraction;
                        }
                        if (Config.options.background.parallax.enableSidebar) {
                            let sidebarFraction = bgRoot.parallaxRation / bgRoot.workspaceChunkSize / 2;
                            usedFraction += (sidebarFraction * GlobalStates.sidebarRightOpen - sidebarFraction * GlobalStates.sidebarLeftOpen);
                        }
                        return Math.max(0, Math.min(1, usedFraction));
                    }
                    property real usedFractionY: {
                        let usedFraction = middleFraction;
                        if (Config.options.background.parallax.enableWorkspace && bgRoot.verticalParallax && !bgRoot.nativeWallpaper) {
                            usedFraction = fraction;
                        }
                        return Math.max(0, Math.min(1, usedFraction));
                    }

                    x: {
                        if (bgRoot.screen.width > width) {
                            // Center the picture
                            return (bgRoot.screen.width - width) / 2;
                        }
                        return - bgRoot.parallaxTotalPixelsX * usedFractionX;
                    }
                    y: {
                        if (bgRoot.screen.height > height) {
                            // Center the picture
                            return (bgRoot.screen.height - height) / 2;
                        }
                        return - bgRoot.parallaxTotalPixelsY * usedFractionY;
                    }

                    source: (bgRoot.wallpaperSafetyTriggered || !bgRoot.drawsWallpaper) ? "" : bgRoot.wallpaperPath
                    fillMode: Image.PreserveAspectCrop
                    Behavior on x {
                        NumberAnimation {
                            duration: 600
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on y {
                        NumberAnimation {
                            duration: 600
                            easing.type: Easing.OutCubic
                        }
                    }
                    width: bgRoot.scaledWallpaperWidth
                    height: bgRoot.scaledWallpaperHeight

                    onStatusChanged: {
                        if (!bgRoot.transitionPending)
                            return;
                        if (status === Image.Ready) {
                            transitionAnim.restart();
                            bgRoot.transitionPending = false;
                        } else if (status === Image.Error || status === Image.Null) {
                            bgRoot.finishTransition();
                        }
                    }
                }

                Loader {
                    id: wallpaperBlurLoader
                    anchors.fill: parent
                    active: bgRoot.wallpaperBlurActive
                    sourceComponent: Item {
                        id: blurRoot

                        readonly property real fadeWidth: 140
                        readonly property bool alignRight: Config.options.background.splitSide === "right"
                        property real coreWidth: bgRoot.blurFullScreen ? blurRoot.width : blurRoot.width * bgRoot.splitFraction

                        Behavior on coreWidth {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }

                        layer.enabled: !bgRoot.blurFullScreen
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: blurRoot.width
                                height: blurRoot.height
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop {
                                        position: blurRoot.alignRight ? 1 - (blurRoot.coreWidth / blurRoot.width) : Math.max(0, (blurRoot.coreWidth - blurRoot.fadeWidth) / blurRoot.width)
                                        color: blurRoot.alignRight ? "transparent" : "white"
                                    }
                                    GradientStop {
                                        position: blurRoot.alignRight ? Math.min(1, 1 - (blurRoot.coreWidth - blurRoot.fadeWidth) / blurRoot.width) : Math.min(1, blurRoot.coreWidth / blurRoot.width)
                                        color: blurRoot.alignRight ? "white" : "transparent"
                                    }
                                }
                            }
                        }

                        FastBlur {
                            x: wallpaper.x
                            y: wallpaper.y
                            width: wallpaper.width
                            height: wallpaper.height
                            source: wallpaper
                            radius: Config.options.background.blurRadius
                        }
                    }
                }

                Loader {
                    id: videoWallpaperLoader
                    anchors.fill: parent
                    active: bgRoot.videoLayerActive
                    source: "VideoWallpaperLayer.qml"
                }

                Loader {
                    id: collageLoader
                    anchors.fill: parent
                    active: Collage.enabled && !bgRoot.nativeWallpaper
                    sourceComponent: MultipleWalls {
                        screen: bgRoot.modelData
                        transitionDone: !bgRoot.transitionPending && bgRoot.transitionProgress >= 1.0
                    }
                }
            }

            Binding {
                target: videoWallpaperLoader.item
                property: "shown"
                value: bgRoot.visible
                when: videoWallpaperLoader.item !== null
            }

            Binding {
                target: videoWallpaperLoader.item
                property: "covered"
                value: bgRoot.desktopCovered
                when: videoWallpaperLoader.item !== null
            }

            Loader {
                id: transitionLoader
                anchors.fill: parent
                active: bgRoot.transitionLive
                sourceComponent: WallpaperTransition {
                    source: wallpaperFrame
                    shader: bgRoot.transitionShader
                    progress: bgRoot.transitionProgress
                    duration: transitionAnim.duration
                }
            }

            Loader {
                id: blurLoader
                active: Config.options.lock.blur.enable && (GlobalStates.screenLocked || scaleAnim.running)
                    && !centeredWallpaper.centeredWallpaperEnabled && !bgRoot.wallpaperBlurActive
                x: wallpaper.x
                y: wallpaper.y
                width: wallpaper.width
                height: wallpaper.height
                scale: GlobalStates.screenLocked ? Config.options.lock.blur.extraZoom : 1
                Behavior on scale {
                    NumberAnimation {
                        id: scaleAnim
                        duration: 400
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                    }
                }
                sourceComponent: GaussianBlur {
                    source: wallpaper
                    radius: GlobalStates.screenLocked ? Config.options.lock.blur.radius : 0
                    samples: radius * 2 + 1

                    Rectangle {
                        opacity: GlobalStates.screenLocked ? 1 : 0
                        anchors.fill: parent
                        color: CF.ColorUtils.transparentize(Appearance.colors.colLayer0, 0.7)
                    }
                }
            }

            CenteredWallpaper {
                id: centeredWallpaper
                anchors.fill: parent
                screen: bgRoot.modelData
                wallpaperPath: bgRoot.wallpaperSafetyTriggered ? "" : bgRoot.wallpaperPath
                wallpaperIsVideo: bgRoot.wallpaperIsVideo
                allowed: !bgRoot.nativeWallpaper && !bgRoot.videoLayerActive
                collageMode: Collage.enabled && !bgRoot.nativeWallpaper
            }

            WallpaperDropArea {
                anchors.fill: parent
                screen: bgRoot.modelData
            }

            Loader {
                anchors.fill: parent
                active: Collage.enabled && !bgRoot.nativeWallpaper && !Config.options.background.widgetsLocked
                    && !GlobalStates.screenLocked && !!collageLoader.item
                sourceComponent: MultipleWallsDrop {
                    collage: collageLoader.item
                }
            }

            WidgetCanvas {
                id: widgetCanvas
                parent: bgRoot.widgetsAboveIcons && bgRoot.widgetsSlot ? bgRoot.widgetsSlot : wallpaperLayer
                width: parent.width
                height: parent.height
                readonly property real parallaxFactor: {
                    var f = Config.options.background.parallax.widgetsFactor;
                    return f / bgRoot.parallaxRation;
                }
                readonly property real baseWallpaperOffsetX: (bgRoot.screen.width - wallpaper.width) / 2
                readonly property real baseWallpaperOffsetY: (bgRoot.screen.height - wallpaper.height) / 2
                readonly property real wallpaperTotalOffsetX: wallpaper.x - baseWallpaperOffsetX
                readonly property real wallpaperTotalOffsetY: wallpaper.y - baseWallpaperOffsetY
                readonly property bool locked: GlobalStates.screenLocked
                x: wallpaperTotalOffsetX * parallaxFactor * !locked * !bgRoot.nativeWallpaper
                y: wallpaperTotalOffsetY * parallaxFactor * !locked * !bgRoot.nativeWallpaper

                transitions: Transition {
                    PropertyAnimation {
                        properties: "width,height"
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                    AnchorAnimation {
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                }

                MouseArea {
                    id: centeredDesktopThumpArea
                    width: Math.max(1, centeredWallpaper.centeredShapeSize())
                    height: width
                    anchors.centerIn: parent
                    visible: centeredWallpaper.centeredShapeActive && !GlobalStates.screenLocked
                    acceptedButtons: Qt.LeftButton
                    onClicked: GlobalStates.centeredWallpaperThumpRequested()
                }

                FadeLoader {
                    id: weatherLoader
                    asynchronous: Platform.isWindows
                    shown: Config.options.background.widgets.weather.enable && bgRoot.widgetsOnThisScreen
                    sourceComponent: WeatherWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                        wallpaperItem: wallpaper
                    }
                }

                FadeLoader {
                    id: clockLoader
                    asynchronous: Platform.isWindows
                    shown: Config.options.background.widgets.clock.enable && (GlobalStates.screenLocked || bgRoot.widgetsOnThisScreen)
                    sourceComponent: ClockWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                        wallpaperSafetyTriggered: bgRoot.wallpaperSafetyTriggered
                        wallpaperItem: wallpaper
                    }
                }

                FadeLoader {
                    id: resourcesLoader
                    asynchronous: Platform.isWindows
                    shown: Config.options.background.widgets.resources.enable && bgRoot.widgetsOnThisScreen
                    sourceComponent: ResourcesWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                        wallpaperItem: wallpaper
                    }
                }

                FadeLoader {
                    id: calendarLoader
                    asynchronous: Platform.isWindows
                    shown: Config.options.background.widgets.calendar.enable && bgRoot.widgetsOnThisScreen
                    sourceComponent: CalendarWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                        wallpaperItem: wallpaper
                    }
                }

                FadeLoader {
                    id: customTextLoader
                    asynchronous: Platform.isWindows
                    shown: Config.options.background.widgets.customText.enable && bgRoot.widgetsOnThisScreen
                    sourceComponent: CustomTextWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                        wallpaperItem: wallpaper
                    }
                }

                FadeLoader {
                    id: customImageLoader
                    asynchronous: Platform.isWindows
                    shown: Config.options.background.widgets.customImage.enable && bgRoot.widgetsOnThisScreen
                    sourceComponent: CustomImage {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                        wallpaperItem: wallpaper
                    }
                }

                FadeLoader {
                    id: imageCardLoader
                    asynchronous: Platform.isWindows
                    shown: Config.options.background.widgets.imageCard.enable && bgRoot.widgetsOnThisScreen
                    sourceComponent: ImageCardWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                        wallpaperItem: wallpaper
                    }
                }

                FadeLoader {
                    id: stickerLoader
                    asynchronous: Platform.isWindows
                    shown: Config.options.background.widgets.sticker.enable && bgRoot.widgetsOnThisScreen
                    sourceComponent: StickerWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                        wallpaperItem: wallpaper
                    }
                }

                FadeLoader {
                    id: imageConverterLoader
                    asynchronous: Platform.isWindows
                    shown: Config.options.background.widgets.images.enable && bgRoot.widgetsOnThisScreen
                    sourceComponent: ImageConverterWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                        wallpaperItem: wallpaper
                    }
                }

                FadeLoader {
                    id: mediaWidgetLoader
                    asynchronous: Platform.isWindows
                    shown: Config.options.background.widgets.media.enable && bgRoot.widgetsOnThisScreen
                    sourceComponent: MediaWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                        wallpaperItem: wallpaper
                    }
                }

                FadeLoader {
                    id: notesLoader
                    asynchronous: Platform.isWindows
                    shown: Config.options.background.widgets.notes.enable && bgRoot.widgetsOnThisScreen
                    sourceComponent: NotesWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                        wallpaperItem: wallpaper
                    }
                }

                FadeLoader {
                    id: timersLoader
                    asynchronous: Platform.isWindows
                    shown: Config.options.background.widgets.timers.enable && bgRoot.widgetsOnThisScreen
                    sourceComponent: TimerWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                        wallpaperItem: wallpaper
                    }
                }

                FadeLoader {
                    id: todoLoader
                    asynchronous: Platform.isWindows
                    shown: Config.options.background.widgets.todo.enable && bgRoot.widgetsOnThisScreen
                    sourceComponent: TodoWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                        wallpaperItem: wallpaper
                    }
                }

                FadeLoader {
                    id: userCardLoader
                    asynchronous: Platform.isWindows
                    shown: Config.options.background.widgets.userCard.enable && bgRoot.widgetsOnThisScreen
                    sourceComponent: UserCardWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                        wallpaperItem: wallpaper
                    }
                }

                FadeLoader {
                    id: visualizerLoader
                    asynchronous: Platform.isWindows
                    shown: Config.options.background.widgets.visualizer.enable && bgRoot.widgetsOnThisScreen
                    sourceComponent: VisualizerWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                        wallpaperItem: wallpaper
                    }
                }

                FadeLoader {
                    id: worldClockLoader
                    asynchronous: Platform.isWindows
                    shown: Config.options.background.widgets.worldClock.enable && bgRoot.widgetsOnThisScreen
                    sourceComponent: WorldClockWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                        wallpaperItem: wallpaper
                    }
                }
            }

            Loader {
                anchors.fill: parent
                active: Collage.enabled && !bgRoot.nativeWallpaper && !Config.options.background.widgetsLocked
                    && !GlobalStates.screenLocked && !!collageLoader.item
                sourceComponent: MultipleWallsEditor {
                    collage: collageLoader.item
                }
            }
        }
    }
}

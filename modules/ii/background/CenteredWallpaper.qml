import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF
import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    required property var screen
    required property string wallpaperPath
    required property bool wallpaperIsVideo
    property bool allowed: true
    property bool collageMode: false

    readonly property bool centeredWallpaperConfigEnabled: Config.options.background.centeredWallpaper && root.allowed
    property bool centeredWallpaperEnabled: false
    property bool centeredWallpaperPendingDisable: false
    property bool centeredOnlyWhenLocked: Config.options.background.centeredWallpaperOnlyWhenLocked
    property int centeredWallpaperShape: CF.ShapeUtils.getShape(Config.options.background.centeredWallpaperShape)
    property int centeredWallpaperSize: Config.options.background.centeredWallpaperSize
    readonly property string shapeImagePath: root.collageMode && Config.options.background.centeredWallpaperImage !== ""
        ? Config.options.background.centeredWallpaperImage
        : root.wallpaperPath
    property color centeredWallpaperColor: Appearance.getColorFromName(Config.options.background.centeredWallpaperColor)

    onCenteredOnlyWhenLockedChanged: root.syncProgress()

    onCenteredWallpaperConfigEnabledChanged: {
        if (root.centeredWallpaperConfigEnabled) {
            centeredAnim.stop();
            root.centeredWallpaperPendingDisable = false;
            root.centeredWallpaperEnabled = true;
            root.centeredProgress = 1;
        } else if (root.centeredProgress === 1 && !centeredAnim.running) {
            root.centeredWallpaperEnabled = false;
        } else {
            root.centeredWallpaperPendingDisable = true;
        }
        root.syncProgress();
    }

    property real centeredShapeMax: Math.max(1, Math.ceil(
        Math.hypot(root.screen.width / 2, root.screen.height / 2)
        / CF.ShapeUtils.centeredShapeMinBoundaryRadius(root.centeredWallpaperShape) * 1.02))
    property real centeredShapeRenderSize: Math.max(1, Math.ceil(
        Math.hypot(root.screen.width, root.screen.height)))

    property bool centeredAnimationReady: false
    property bool centeredAnimating: false
    property real centeredProgress: 0

    function targetProgress() {
        if (!root.centeredWallpaperConfigEnabled) return 1;
        return GlobalStates.screenLocked ? 0 : (root.centeredOnlyWhenLocked ? 1 : 0);
    }

    function syncProgress() {
        root.setCenteredProgress(root.targetProgress());
    }

    function setCenteredProgress(value) {
        if (!root.centeredWallpaperEnabled || !Config.ready || !root.centeredAnimationReady) {
            centeredAnim.stop();
            root.centeredProgress = value;
            if (Config.ready) root.centeredAnimationReady = true;
            root.finishPendingDisable();
            return;
        }
        if (centeredAnim.running && centeredAnim.to === value) return;
        centeredAnim.stop();
        if (value === root.centeredProgress) {
            root.finishPendingDisable();
            return;
        }
        centeredAnim.duration = value > root.centeredProgress ? 800 : 650;
        centeredAnim.to = value;
        centeredAnim.start();
    }

    function finishPendingDisable() {
        if (root.centeredWallpaperPendingDisable && root.centeredProgress === 1) {
            root.centeredWallpaperPendingDisable = false;
            root.centeredWallpaperEnabled = false;
        }
    }

    NumberAnimation {
        id: centeredAnim
        target: root
        property: "centeredProgress"
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
        onRunningChanged: {
            root.centeredAnimating = running;
            if (!running) root.finishPendingDisable();
        }
    }

    readonly property bool centeredShapeActive: root.centeredWallpaperEnabled
        && (root.centeredProgress < 1 || root.centeredAnimating)

    readonly property bool centeredHidesFullWallpaper: root.centeredWallpaperEnabled
        && root.centeredFullWallpaperOpacity() <= 0

    property real centeredFade: 0.05

    function centeredShapeSize() {
        if (!root.centeredWallpaperEnabled) return 1;
        return root.centeredWallpaperSize
            + root.centeredProgress * (root.centeredShapeMax - root.centeredWallpaperSize);
    }
    function centeredImageScale() {
        if (!root.centeredWallpaperEnabled) return 1;
        const minDim = Math.min(root.screen.width, root.screen.height);
        const size = root.centeredShapeSize();
        const overscan = size >= minDim ? 1
            : 1.08 - 0.08 * (size - root.centeredWallpaperSize) / (minDim - root.centeredWallpaperSize);
        return overscan * root.centeredShapeRenderSize / Math.max(size, minDim);
    }
    function centeredFullWallpaperOpacity() {
        if (!root.centeredWallpaperEnabled) return 1;
        return Math.max(0, Math.min(1, (root.centeredProgress - (1 - root.centeredFade)) / root.centeredFade));
    }
    function centeredBgOpacity() {
        if (!root.centeredWallpaperEnabled) return 0;
        if (root.wallpaperIsVideo || root.collageMode) return 0;
        return Math.max(0, Math.min(1, (1 - root.centeredProgress) / root.centeredFade));
    }

    Component.onCompleted: {
        root.centeredWallpaperEnabled = root.centeredWallpaperConfigEnabled;
        root.syncProgress();
        if (Config.ready)
            root.centeredAnimationReady = true;
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (!Config.ready) return;
            root.syncProgress();
            root.centeredAnimationReady = true;
        }
    }

    Connections {
        target: GlobalStates
        function onScreenLockedChanged() {
            root.syncProgress();
        }
    }

    Loader {
        anchors.fill: parent
        active: root.centeredWallpaperEnabled
        sourceComponent: Item {
            Rectangle {
                anchors.fill: parent
                color: root.centeredWallpaperColor
                opacity: root.centeredBgOpacity()
                visible: opacity > 0
            }

            MaterialShape {
                id: centeredWallpaperShapeItem
                anchors.centerIn: parent
                width: root.centeredShapeRenderSize
                height: root.centeredShapeRenderSize
                color: root.wallpaperIsVideo || root.collageMode ? "transparent" : root.centeredWallpaperColor
                shape: root.centeredWallpaperShape
                transformOrigin: Item.Center
                property real shapeZoom: 1
                scale: (root.centeredShapeSize() / root.centeredShapeRenderSize) * shapeZoom
                visible: root.centeredShapeActive

                SequentialAnimation {
                    id: shapeZoomAnim
                    NumberAnimation { target: centeredWallpaperShapeItem; property: "shapeZoom"; to: 1.06; duration: 300; easing.type: Easing.OutQuad }
                    NumberAnimation { target: centeredWallpaperShapeItem; property: "shapeZoom"; to: 1.0; duration: 500; easing.type: Easing.InOutQuad }
                }
                SequentialAnimation {
                    id: imageFollowAnim
                    PauseAnimation { duration: 200 }
                    NumberAnimation { target: centeredWallpaperImage; property: "imageZoom"; to: 1.08; duration: 250; easing.type: Easing.OutQuad }
                    NumberAnimation { target: centeredWallpaperImage; property: "imageZoom"; to: 1.0; duration: 350; easing.type: Easing.InOutQuad }
                }
                function thump() {
                    if (shapeZoomAnim.running || imageFollowAnim.running) return;
                    shapeZoomAnim.restart();
                    imageFollowAnim.restart();
                }

                Connections {
                    target: GlobalStates
                    function onCenteredWallpaperThumpRequested() {
                        centeredWallpaperShapeItem.thump();
                    }
                }

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: MaterialShape {
                        width: centeredWallpaperShapeItem.width
                        height: centeredWallpaperShapeItem.height
                        shape: root.centeredWallpaperShape
                    }
                }

                StyledImage {
                    id: centeredWallpaperImage
                    width: root.width
                    height: root.height
                    anchors.centerIn: parent
                    source: root.shapeImagePath
                    fillMode: Image.PreserveAspectCrop
                    mipmap: true
                    antialiasing: true
                    sourceSize: Qt.size(Math.ceil(root.screen.width * root.screen.devicePixelRatio),
                        Math.ceil(root.screen.height * root.screen.devicePixelRatio))
                    property real imageZoom: 1
                    scale: root.centeredImageScale() * (1 / centeredWallpaperShapeItem.shapeZoom) * imageZoom
                }

                MouseArea {
                    anchors.fill: parent
                    z: 1
                    acceptedButtons: Qt.LeftButton
                    onClicked: centeredWallpaperShapeItem.thump()
                }
            }
        }
    }
}

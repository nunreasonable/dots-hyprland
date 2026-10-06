pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.utils
import qs.modules.common.widgets
import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    signal dismiss
    signal picked(string hex)

    property real pointerX: -1
    property real pointerY: -1

    visible: false
    color: "transparent"
    WlrLayershell.namespace: "quickshell:colorPicker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    readonly property string screenshotDir: Directories.screenshotTemp
    readonly property string screenFileName: FileUtils.sanitizeFilename(root.screen?.name ?? "")
    readonly property string screenshotPath: `${root.screenshotDir}/colorpicker-${root.screenFileName}`
    property bool screenshotReady: false

    readonly property real dpr: root.screen?.devicePixelRatio ?? 1
    readonly property int imageWidth: frozenShot.sourceSize.width
    readonly property int imageHeight: frozenShot.sourceSize.height
    readonly property bool pointerKnown: root.pointerX >= 0 && root.pointerY >= 0
    readonly property int pixelX: root.toPixel(root.pointerX, root.imageWidth)
    readonly property int pixelY: root.toPixel(root.pointerY, root.imageHeight)
    readonly property bool canSample: root.screenshotReady && root.pointerKnown && root.imageWidth > 0
    readonly property string hoveredColor: root.canSample ? root.sample(root.pixelX, root.pixelY) : ""
    readonly property bool hoveredIsDark: ColorUtils.isDark(root.hoveredColor || "black")

    property real zoom: 10
    readonly property real minZoom: 4
    readonly property real maxZoom: 24
    readonly property real loupeTargetSize: 150
    readonly property real cellSize: Math.max(1, Math.round(root.zoom * root.dpr)) / root.dpr
    readonly property int loupeHalf: Math.max(1, Math.round((root.loupeTargetSize / root.cellSize - 1) / 2))
    readonly property real loupeSize: (root.loupeHalf * 2 + 1) * root.cellSize
    readonly property real ringWidth: 4

    function toPixel(value, size) {
        return Math.max(0, Math.min(size - 1, Math.floor(value * root.dpr + 0.001)));
    }

    function sample(x, y) {
        return WindowsNative.screenshot?.pixelAt(root.screenshotPath, x, y) ?? "";
    }

    function snap(value) {
        return Math.round(value * root.dpr) / root.dpr;
    }

    function pickAt(x, y) {
        root.pointerX = x;
        root.pointerY = y;
        const hex = root.hoveredColor;
        if (hex.length > 0)
            root.picked(hex);
        else
            root.dismiss();
    }

    TempScreenshotProcess {
        id: screenshotProc
        screen: root.screen
        screenshotDir: root.screenshotDir
        screenshotPath: root.screenshotPath
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("[ColorPicker] Screen capture failed, closing the picker");
                root.dismiss();
                return;
            }
            root.screenshotReady = true;
            root.visible = true;
        }
    }

    Component.onCompleted: screenshotProc.running = true
    Component.onDestruction: WindowsNative.screenshot?.releasePixels()

    Image {
        id: frozenShot
        anchors.fill: parent
        cache: false
        asynchronous: false
        smooth: false
        mipmap: false
        fillMode: Image.Stretch
        source: root.screenshotReady ? `file:///${root.screenshotPath}` : ""
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.pointerKnown ? Qt.BlankCursor : Qt.CrossCursor

        focus: root.visible
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.dismiss();
                event.accepted = true;
            }
        }

        onPositionChanged: mouse => {
            root.pointerX = mouse.x;
            root.pointerY = mouse.y;
        }
        onExited: {
            root.pointerX = -1;
            root.pointerY = -1;
        }
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.dismiss();
                return;
            }
            root.pickAt(mouse.x, mouse.y);
        }
        onWheel: wheel => {
            const step = wheel.angleDelta.y > 0 ? 2 : -2;
            root.zoom = Math.max(root.minZoom, Math.min(root.maxZoom, root.zoom + step));
        }
    }

    Item {
        id: loupe
        visible: root.pointerKnown && root.screenshotReady
        width: root.loupeSize + root.ringWidth * 2
        height: width
        x: root.snap(root.pointerX - width / 2)
        y: root.snap(root.pointerY - height / 2)

        StyledRectangularShadow {
            target: loupeRing
        }

        Rectangle {
            id: loupeRing
            anchors.fill: parent
            radius: width / 2
            color: root.hoveredColor.length > 0 ? root.hoveredColor : Appearance.colors.colPrimary
        }

        Item {
            id: loupeContent
            anchors.centerIn: parent
            width: root.loupeSize
            height: root.loupeSize
            clip: true
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: loupeContent.width
                    height: loupeContent.height
                    radius: width / 2
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "black"
            }

            Image {
                source: frozenShot.source
                cache: false
                asynchronous: true
                smooth: false
                mipmap: false
                fillMode: Image.Stretch
                width: root.imageWidth * root.cellSize
                height: root.imageHeight * root.cellSize
                x: (root.loupeHalf - root.pixelX) * root.cellSize
                y: (root.loupeHalf - root.pixelY) * root.cellSize
            }

            Rectangle {
                x: root.loupeHalf * root.cellSize - border.width
                y: root.loupeHalf * root.cellSize - border.width
                width: root.cellSize + border.width * 2
                height: width
                color: "transparent"
                border.width: 1
                border.color: root.hoveredIsDark ? "white" : "black"
            }
        }
    }

    StyledRectangularShadow {
        target: hexPill
        visible: hexPill.visible
    }

    Rectangle {
        id: hexPill
        visible: loupe.visible && root.hoveredColor.length > 0
        readonly property real padding: 6
        readonly property real gap: 8
        readonly property bool fitsBelow: loupe.y + loupe.height + gap + height <= mouseArea.height
        implicitWidth: pillRow.implicitWidth + padding * 2 + 4
        implicitHeight: pillRow.implicitHeight + padding * 2
        radius: height / 2
        color: Appearance.m3colors.m3surfaceContainer
        x: root.snap(Math.max(4, Math.min(mouseArea.width - width - 4, root.pointerX - width / 2)))
        y: root.snap(fitsBelow ? loupe.y + loupe.height + gap : loupe.y - gap - height)

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                radius: width / 2
                color: root.hoveredColor.length > 0 ? root.hoveredColor : "transparent"
                border.width: 1
                border.color: Appearance.m3colors.m3outline
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.hoveredColor
                color: Appearance.m3colors.m3onSurface
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.normal
            }
        }
    }
}

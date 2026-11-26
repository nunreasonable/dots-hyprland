import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.common

FloatingWindow {
    id: root

    signal closeRequested

    readonly property bool ownTitleBar: Platform.isWindows && (Config.options?.windows.showTitlebar ?? true) && WindowsNative.windowFrame !== null
    readonly property bool maximized: content.Window.window?.visibility === Window.Maximized
    readonly property bool backdropBlur: !Platform.isWindows
    readonly property color opaqueBackground: Config.options.appearance.uiBackground === "oled" ? "#000000" : Appearance.colors.colLayer0Base

    function applyTitleBar() {
        const backingWindow = content.Window.window;
        if (!Platform.isWindows || !backingWindow || !WindowsNative.windowFrame)
            return;
        if (root.ownTitleBar)
            WindowsNative.windowFrame.hideTitleBar(backingWindow);
        else
            WindowsNative.windowFrame.showTitleBar(backingWindow);
    }

    function activate() {
        if (!root.visible)
            return;
        const backingWindow = content.Window.window;
        if (backingWindow) {
            if (backingWindow.visibility === Window.Minimized)
                backingWindow.showNormal();
            backingWindow.raise();
            backingWindow.requestActivate();
        }
        if (Platform.isWindows) {
            focusGrab.active = false;
            focusGrab.active = true;
        }
        content.focusContent();
    }

    property bool centered: false
    function center() {
        const backingWindow = content.Window.window;
        if (root.centered || !backingWindow || !root.screen)
            return;
        if (backingWindow.width > root.fitWidth)
            backingWindow.width = root.fitWidth;
        if (backingWindow.height > root.fitHeight)
            backingWindow.height = root.fitHeight;
        backingWindow.x = root.screen.x + Math.round((root.screen.width - backingWindow.width) / 2);
        const barOnTop = !Config.options.bar.bottom && !Config.options.bar.vertical;
        const top = root.screen.y + (barOnTop ? Appearance.sizes.barHeight + 8 : 0) + 32;
        backingWindow.y = Math.max(top, root.screen.y + Math.round((root.screen.height - backingWindow.height) / 2));
        root.centered = true;
    }

    function goToTarget(target) {
        content.goToTarget(target);
    }

    visible: true
    title: "illogical-impulse Settings"
    readonly property real screenWidth: root.screen?.width ?? 1920
    readonly property real screenHeight: root.screen?.height ?? 1080
    readonly property real fitWidth: Math.min(1100, root.screenWidth - 80)
    readonly property real fitHeight: Math.min(680, root.screenHeight - 140)
    implicitWidth: root.fitWidth
    implicitHeight: root.fitHeight
    minimumSize: Qt.size(Math.min(900, root.implicitWidth), Math.min(600, root.implicitHeight))
    color: root.backdropBlur ? Appearance.colors.colUiBackground : root.opaqueBackground

    onClosed: root.closeRequested()
    onOwnTitleBarChanged: root.applyTitleBar()
    onVisibleChanged: {
        if (!root.visible)
            return;
        root.applyTitleBar();
        Qt.callLater(root.center);
        Qt.callLater(root.activate);
    }

    DashboardContent {
        id: content
        anchors.fill: parent
        windowControls: root.ownTitleBar
        onCloseRequested: root.closeRequested()
    }

    Repeater {
        model: root.ownTitleBar && !root.maximized ? [
            { edges: Qt.TopEdge, cursor: Qt.SizeVerCursor, left: 8, right: 8, width: 0 },
            { edges: Qt.TopEdge | Qt.LeftEdge, cursor: Qt.SizeFDiagCursor, left: 0, right: -1, width: 8 },
            { edges: Qt.TopEdge | Qt.RightEdge, cursor: Qt.SizeBDiagCursor, left: -1, right: 0, width: 8 }
        ] : []
        delegate: MouseArea {
            required property var modelData
            z: 100
            y: 0
            height: 5
            x: modelData.left >= 0 ? modelData.left : root.width - modelData.width
            width: modelData.width > 0 ? modelData.width : root.width - modelData.left - modelData.right
            cursorShape: modelData.cursor
            onPressed: content.Window.window?.startSystemResize(modelData.edges)
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        onActiveChanged: {
            if (focusGrab.active)
                Qt.callLater(() => focusGrab.active = false);
        }
    }
}

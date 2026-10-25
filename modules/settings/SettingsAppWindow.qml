import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.common

FloatingWindow {
    id: root
    property bool forceShown: false
    property bool shownOnce: false
    readonly property bool ownTitleBar: Platform.isWindows && (Config.options?.windows.showTitlebar ?? true) && WindowsNative.windowFrame !== null
    readonly property bool maximized: content.Window.window?.visibility === Window.Maximized

    function applyTitleBar() {
        const backingWindow = content.Window.window;
        if (!Platform.isWindows || !backingWindow || !WindowsNative.windowFrame) return;
        if (root.ownTitleBar) WindowsNative.windowFrame.hideTitleBar(backingWindow);
        else WindowsNative.windowFrame.showTitleBar(backingWindow);
    }

    signal closeRequested

    function activate() {
        if (!root.visible)
            return;
        if (root.minimized)
            root.minimized = false;
        const backingWindow = content.Window.window;
        if (backingWindow) {
            backingWindow.raise();
            backingWindow.requestActivate();
        }
        if (Platform.isWindows) {
            focusGrab.active = false;
            focusGrab.active = true;
        }
    }

    visible: content.pageShown || root.forceShown
    title: "illogical-impulse Settings"
    implicitWidth: 1100
    implicitHeight: 750
    minimumSize: Qt.size(750, 500)
    color: Appearance.m3colors.m3background

    onClosed: root.closeRequested()
    onOwnTitleBarChanged: root.applyTitleBar()
    onVisibleChanged: {
        if (root.visible)
            root.applyTitleBar();
        if (!root.visible || root.shownOnce)
            return;
        root.shownOnce = true;
        root.activate();
    }

    Timer {
        interval: 3000
        running: !content.pageShown && !root.forceShown
        onTriggered: root.forceShown = true
    }

    SettingsContent {
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

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.functions as CF

PanelWindow {
    id: panelWindow
    property bool forceShown: false
    readonly property bool shown: settingsContent.pageShown || panelWindow.forceShown
    readonly property bool isMinimal: Config.options.settings.style === "minimal"
    readonly property real sizeScale: panelWindow.isMinimal ? 0.75 : 1.0
    readonly property bool keepOpen: Config.options.settings.keepOpen

    signal closeRequested

    function activate() {
        if (!panelWindow.visible)
            return;
        settingsContent.focusContent();
        panelWindow.takeFocus();
    }

    function takeFocus() {
        if (!Platform.isWindows || !panelWindow.keepOpen || !panelWindow.visible)
            return;
        focusGrab.active = false;
        focusGrab.active = true;
    }

    function goToTarget(target) {
        settingsContent.goToTarget(target);
    }

    function hide() {
        panelWindow.closeRequested();
    }

    visible: panelWindow.shown
    exclusiveZone: 0
    WlrLayershell.namespace: "quickshell:settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: panelWindow.visible ? ((Platform.isWindows && !panelWindow.keepOpen) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand) : WlrKeyboardFocus.None
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    mask: Region {
        item: settingsWindow
    }

    onVisibleChanged: {
        if (panelWindow.visible) {
            Qt.callLater(() => {
                if (panelWindow.visible && !panelWindow.keepOpen)
                    GlobalFocusGrab.addDismissable(panelWindow);
            });
            settingsWindow.userMoved = false;
            Qt.callLater(() => {
                settingsContent.focusContent();
                panelWindow.takeFocus();
            });
        } else {
            GlobalFocusGrab.removeDismissable(panelWindow);
        }
    }

    onKeepOpenChanged: {
        if (!panelWindow.visible)
            return;
        if (panelWindow.keepOpen)
            GlobalFocusGrab.removeDismissable(panelWindow);
        else
            GlobalFocusGrab.addDismissable(panelWindow);
    }

    Component.onDestruction: GlobalFocusGrab.removeDismissable(panelWindow)

    Connections {
        target: GlobalFocusGrab
        function onDismissed() {
            if (panelWindow.visible && !panelWindow.keepOpen)
                panelWindow.hide();
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [panelWindow]
        onActiveChanged: {
            if (focusGrab.active)
                Qt.callLater(() => focusGrab.active = false);
        }
    }

    Timer {
        interval: 3000
        running: !settingsContent.pageShown && !panelWindow.forceShown
        onTriggered: panelWindow.forceShown = true
    }

    Rectangle {
        id: settingsWindow
        width: Math.min(parent.width - 80, 980 * panelWindow.sizeScale)
        height: Math.min(parent.height - 80, 665 * panelWindow.sizeScale)
        color: Appearance.colors.colLayer0
        border.width: Config.options.settings.borderSize
        border.color: CF.ColorUtils.transparentize(Appearance.getColorFromName(Config.options.settings.borderColor), 0.8)
        radius: !panelWindow.isMinimal ? Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 5 : Appearance.rounding.screenRounding + 5

        property bool userMoved: false
        anchors.centerIn: userMoved ? undefined : parent

        opacity: panelWindow.shown ? 1 : 0
        scale: panelWindow.shown ? 1 : 0.95

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Keys.onTabPressed: event => {
            settingsContent.currentPage = (settingsContent.currentPage + 1) % settingsContent.pageCount;
            event.accepted = true;
        }

        Keys.onBacktabPressed: event => {
            settingsContent.currentPage = (settingsContent.currentPage - 1 + settingsContent.pageCount) % settingsContent.pageCount;
            event.accepted = true;
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                panelWindow.hide();
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                const instance = settingsContent.currentPageItem;
                if (instance && instance.contentY !== undefined) {
                    const step = 60;
                    const delta = event.key === Qt.Key_Down ? step : -step;
                    const maxY = Math.max(0, (instance.contentHeight ?? 0) - instance.height);
                    instance.contentY = Math.max(0, Math.min(maxY, instance.contentY + delta));
                }
                event.accepted = true;
            }
        }

        Rectangle {
            id: dragHandle
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 32
            color: "transparent"
            z: 2

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeAllCursor
                drag.target: settingsWindow
                drag.axis: Drag.XAndYAxis
                onPressed: settingsWindow.userMoved = true
                onDoubleClicked: settingsWindow.userMoved = false
            }
        }

        SettingsPcContent {
            id: settingsContent
            anchors.fill: parent
            onCloseRequested: panelWindow.hide()
        }
    }
}

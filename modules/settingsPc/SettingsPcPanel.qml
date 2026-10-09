import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.functions as CF

PanelWindow {
    id: panelWindow
    property bool forceShown: false
    readonly property bool shown: settingsContent.pageShown || panelWindow.forceShown

    signal closeRequested

    function activate() {
        if (!panelWindow.visible)
            return;
        settingsContent.focusContent();
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
    WlrLayershell.keyboardFocus: panelWindow.visible ? (Platform.isWindows ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand) : WlrKeyboardFocus.None
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
            GlobalFocusGrab.addDismissable(panelWindow);
            settingsWindow.userMoved = false;
            Qt.callLater(() => settingsContent.focusContent());
        } else {
            GlobalFocusGrab.removeDismissable(panelWindow);
        }
    }

    Component.onDestruction: GlobalFocusGrab.removeDismissable(panelWindow)

    Connections {
        target: GlobalFocusGrab
        function onDismissed() {
            panelWindow.hide();
        }
    }

    Timer {
        interval: 3000
        running: !settingsContent.pageShown && !panelWindow.forceShown
        onTriggered: panelWindow.forceShown = true
    }

    Rectangle {
        id: settingsWindow
        width: Math.min(parent.width - 80, 980)
        height: Math.min(parent.height - 80, 665)
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: CF.ColorUtils.transparentize(Appearance.colors.colLayer0Border, 0.8)
        radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 5

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

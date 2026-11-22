import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: overviewScope
    property bool dontAutoCancelSearch: false
    readonly property bool spotlight: Config.options.search.spotlight ?? false

    function spotlightToggle(mode) {
        const wanted = mode ?? "";
        if (GlobalStates.spotlightOpen && (wanted === "" || GlobalStates.spotlightMode === wanted)) {
            GlobalStates.spotlightOpen = false;
            return;
        }
        GlobalStates.overviewOpen = false;
        GlobalStates.spotlightMode = wanted;
        GlobalStates.spotlightOpen = true;
    }

    function workspacesToggle() {
        GlobalStates.spotlightOpen = false;
        GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
    }

    PanelWindow {
        id: panelWindow
        readonly property string searchingText: searchWidgetLoader.item?.searchingText ?? ""
        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
        property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)
        visible: GlobalStates.overviewOpen

        WlrLayershell.namespace: "quickshell:overview"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: GlobalStates.overviewOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        readonly property bool windowDragging: (overviewLoader.item?.draggingFromWorkspace ?? -1) !== -1
        readonly property bool useVisibleRegions: Platform.isWindows && GlobalStates.overviewOpen && !panelWindow.windowDragging
        readonly property Item searchSurface: searchWidgetLoader.item?.inputSurface ?? null
        readonly property Item previewSurface: searchWidgetLoader.item?.previewSurface ?? null

        mask: Region {
            item: GlobalStates.overviewOpen
                ? (panelWindow.windowDragging ? fullscreenMask : (Platform.isWindows ? null : columnMask))
                : null

            Region {
                x: columnLayout.x + searchWidgetLoader.x + (panelWindow.searchSurface?.x ?? 0)
                y: columnLayout.y + searchWidgetLoader.y + (panelWindow.searchSurface?.y ?? 0)
                width: panelWindow.useVisibleRegions ? (panelWindow.searchSurface?.width ?? 0) : 0
                height: panelWindow.useVisibleRegions ? (panelWindow.searchSurface?.height ?? 0) : 0
                radius: panelWindow.searchSurface?.radius ?? 0
            }

            Region {
                x: columnLayout.x + searchWidgetLoader.x + (panelWindow.previewSurface?.x ?? 0)
                y: columnLayout.y + searchWidgetLoader.y + (panelWindow.previewSurface?.y ?? 0)
                width: panelWindow.useVisibleRegions && panelWindow.previewSurface?.visible ? panelWindow.previewSurface.width : 0
                height: panelWindow.useVisibleRegions && panelWindow.previewSurface?.visible ? panelWindow.previewSurface.height : 0
            }

            Region {
                x: columnLayout.x + overviewLoader.x
                y: columnLayout.y + overviewLoader.y
                // The grid hides itself while searching, but its loader keeps its
                // size: only a shown grid takes clicks, or the area under a
                // search's results kept the overview from closing.
                width: panelWindow.useVisibleRegions && (overviewLoader.item?.visible ?? false) ? overviewLoader.width : 0
                height: panelWindow.useVisibleRegions && (overviewLoader.item?.visible ?? false) ? overviewLoader.height : 0
            }
        }

        HyprlandFocusGrab {
            windows: [panelWindow]
            active: Platform.isWindows && GlobalStates.overviewOpen
            onCleared: GlobalStates.overviewOpen = false
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Item {
            id: fullscreenMask
            anchors.fill: parent
        }

        Item {
            id: columnMask
            x: columnLayout.x
            y: columnLayout.y
            width: columnLayout.width
            height: columnLayout.height
        }

        Connections {
            target: GlobalStates
            function onOverviewOpenChanged() {
                if (!GlobalStates.overviewOpen) {
                    searchWidgetLoader.item?.disableExpandAnimation();
                    overviewScope.dontAutoCancelSearch = false;
                    GlobalFocusGrab.dismiss();
                } else {
                    if (!overviewScope.dontAutoCancelSearch) {
                        searchWidgetLoader.item?.cancelSearch();
                    }
                    if (!Platform.isWindows)
                        GlobalFocusGrab.addDismissable(panelWindow);
                }
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                GlobalStates.overviewOpen = false;
            }
        }
        implicitWidth: columnLayout.implicitWidth
        implicitHeight: columnLayout.implicitHeight

        function setSearchingText(text) {
            searchWidgetLoader.item?.setSearchingText(text);
            searchWidgetLoader.item?.focusFirstItem();
        }

        Column {
            id: columnLayout
            visible: GlobalStates.overviewOpen
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
            }
            spacing: -8
            focus: overviewScope.spotlight && GlobalStates.overviewOpen

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    GlobalStates.overviewOpen = false;
                }
            }

            Loader {
                id: searchWidgetLoader
                active: !overviewScope.spotlight
                visible: active
                focus: !overviewScope.spotlight
                anchors.horizontalCenter: parent.horizontalCenter
                sourceComponent: SearchWidget {}
            }

            Loader {
                id: overviewLoader
                property bool kept: false
                anchors.horizontalCenter: parent.horizontalCenter
                active: (GlobalStates.overviewOpen || (Platform.isWindows && overviewLoader.kept)) && (Config?.options.overview.enable ?? true)
                onLoaded: overviewLoader.kept = true

                Connections {
                    target: GlobalStates
                    function onOverviewOpenChanged() {
                        if (GlobalStates.overviewOpen)
                            overviewReleaseTimer.stop();
                        else if (Platform.isWindows && overviewLoader.kept)
                            overviewReleaseTimer.restart();
                    }
                }

                Timer {
                    id: overviewReleaseTimer
                    interval: 120000
                    onTriggered: {
                        overviewLoader.kept = false;
                        overviewGcTimer.restart();
                    }
                }

                Timer {
                    id: overviewGcTimer
                    interval: 2000
                    onTriggered: gc()
                }
                sourceComponent: (Config?.options.overview.style ?? "default") === "niri" ? niriComponent : defaultComponent
                Component {
                    id: defaultComponent
                    OverviewWidget {
                        screen: panelWindow.screen
                        visible: (panelWindow.searchingText == "")
                        live: !Platform.isWindows || GlobalStates.overviewOpen
                    }
                }
                Component {
                    id: niriComponent
                    NiriOverview {
                        screen: panelWindow.screen
                        visible: (panelWindow.searchingText == "")
                        live: !Platform.isWindows || GlobalStates.overviewOpen
                    }
                }
            }
        }
    }

    function toggleClipboard() {
        if (overviewScope.spotlight) {
            overviewScope.spotlightToggle("clipboard");
            return;
        }
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false;
            return;
        }
        overviewScope.dontAutoCancelSearch = true;
        panelWindow.setSearchingText(Config.options.search.prefix.clipboard);
        GlobalStates.overviewOpen = true;
    }

    function toggleEmojis() {
        if (overviewScope.spotlight) {
            overviewScope.spotlightToggle("emoji");
            return;
        }
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false;
            return;
        }
        overviewScope.dontAutoCancelSearch = true;
        panelWindow.setSearchingText(Config.options.search.prefix.emojis);
        GlobalStates.overviewOpen = true;
    }

    IpcHandler {
        target: "search"

        function toggle() {
            if (overviewScope.spotlight)
                overviewScope.spotlightToggle("");
            else
                GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
        function workspacesToggle() {
            overviewScope.workspacesToggle();
        }
        function close() {
            GlobalStates.overviewOpen = false;
            GlobalStates.spotlightOpen = false;
        }
        function open() {
            if (overviewScope.spotlight) {
                GlobalStates.spotlightMode = "";
                GlobalStates.spotlightOpen = true;
            } else {
                GlobalStates.overviewOpen = true;
            }
        }
        function toggleReleaseInterrupt() {
            GlobalStates.superReleaseMightTrigger = false;
        }
        function clipboardToggle() {
            overviewScope.toggleClipboard();
        }
    }

    GlobalShortcut {
        name: "searchToggle"
        description: "Toggles search on press"

        onPressed: {
            if (overviewScope.spotlight)
                overviewScope.spotlightToggle("");
            else
                GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }
    GlobalShortcut {
        name: "overviewWorkspacesClose"
        description: "Closes overview on press"

        onPressed: {
            GlobalStates.overviewOpen = false;
        }
    }
    GlobalShortcut {
        name: "overviewWorkspacesToggle"
        description: "Toggles overview on press"

        onPressed: {
            overviewScope.workspacesToggle();
        }
    }
    GlobalShortcut {
        name: "searchToggleRelease"
        description: "Toggles search on release"

        onPressed: {
            GlobalStates.superReleaseMightTrigger = true;
        }

        onReleased: {
            if (!GlobalStates.superReleaseMightTrigger) {
                GlobalStates.superReleaseMightTrigger = true;
                return;
            }
            if (overviewScope.spotlight)
                overviewScope.spotlightToggle("");
            else
                GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }
    GlobalShortcut {
        name: "searchToggleReleaseInterrupt"
        description: "Interrupts possibility of search being toggled on release. " + "This is necessary because GlobalShortcut.onReleased in quickshell triggers whether or not you press something else while holding the key. " + "To make sure this works consistently, use binditn = MODKEYS, catchall in an automatically triggered submap that includes everything."

        onPressed: {
            GlobalStates.superReleaseMightTrigger = false;
        }
    }
    GlobalShortcut {
        name: "overviewClipboardToggle"
        description: "Toggle clipboard query on overview widget"

        onPressed: {
            overviewScope.toggleClipboard();
        }
    }

    GlobalShortcut {
        name: "overviewEmojiToggle"
        description: "Toggle emoji query on overview widget"

        onPressed: {
            overviewScope.toggleEmojis();
        }
    }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root
    property bool isOpen: false

    function load() {
    }

    function open() {
        if (windowLoader.source === "")
            windowLoader.source = Qt.resolvedUrl("SettingsAppWindow.qml");
        if (root.isOpen && windowLoader.item) {
            windowLoader.item.activate();
            return;
        }
        root.isOpen = true;
    }

    function close() {
        root.isOpen = false;
    }

    function toggle() {
        if (root.isOpen)
            root.close();
        else
            root.open();
    }

    LazyLoader {
        id: windowLoader
        active: root.isOpen
    }

    Connections {
        target: windowLoader.item
        function onCloseRequested() {
            root.close();
        }
    }

    IpcHandler {
        target: "settings"

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }

        function toggle(): void {
            root.toggle();
        }
    }

    GlobalShortcut {
        name: "settingsOpen"
        description: "Opens the settings window"

        onPressed: root.open()
    }

    GlobalShortcut {
        name: "settingsToggle"
        description: "Toggles the settings window"

        onPressed: root.toggle()
    }
}

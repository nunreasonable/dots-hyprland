pragma Singleton

import Quickshell

Singleton {
    readonly property bool isWindows: Qt.platform.os === "windows"
}

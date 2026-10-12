pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    readonly property string scriptPath: `${FileUtils.trimFileProtocol(Directories.scriptPath)}/webapp/webapp.sh`

    property var items: []
    property string error: ""
    readonly property bool busy: Platform.isWindows ? (WindowsNative.webapps?.busy ?? false) : createProc.running

    function parseUrls(text) {
        return String(text).split(/[\n,\s]+/).map(line => line.trim()).filter(line => line !== "");
    }

    function refresh() {
        if (Platform.isWindows) {
            WindowsNative.webapps?.refresh();
            return;
        }
        listProc.running = true;
    }

    function create(text) {
        const urls = root.parseUrls(text);
        if (urls.length === 0) return;
        if (Platform.isWindows) {
            WindowsNative.webapps?.create(urls);
            return;
        }
        if (createProc.running) return;
        root.error = "";
        createProc.command = ["bash", root.scriptPath, "create", ...urls];
        createProc.running = true;
    }

    function remove(id) {
        if (Platform.isWindows) {
            WindowsNative.webapps?.remove(id);
            return;
        }
        removeProc.command = ["bash", root.scriptPath, "remove", id];
        removeProc.running = true;
    }

    function open(id) {
        if (Platform.isWindows) {
            WindowsNative.webapps?.open(id);
            return;
        }
        openProc.command = ["bash", root.scriptPath, "open", id];
        openProc.running = true;
    }

    Connections {
        target: Platform.isWindows ? WindowsNative.webapps : null
        function onItemsChanged() {
            root.items = WindowsNative.webapps.items;
        }
        function onErrorChanged() {
            root.error = WindowsNative.webapps.error;
        }
    }

    Connections {
        target: Platform.isWindows ? WindowsNative : null
        function onReadyChanged() {
            root.refresh();
        }
    }

    Component.onCompleted: root.refresh()

    Process {
        id: listProc
        command: ["bash", root.scriptPath, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.items = JSON.parse(text);
                } catch (e) {
                    root.items = [];
                }
            }
        }
    }

    Process {
        id: createProc
        stdout: StdioCollector {
            id: createOut
        }
        onExited: {
            const failures = createOut.text.split("\n").filter(line => line.startsWith("ERR"));
            root.error = failures.map(line => line.replace(/^ERR\s*/, "")).join(", ");
            root.refresh();
        }
    }

    Process {
        id: removeProc
        onExited: root.refresh()
    }

    Process {
        id: openProc
    }
}

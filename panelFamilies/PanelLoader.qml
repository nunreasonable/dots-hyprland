import QtQuick
import Quickshell

import qs.modules.common

LazyLoader {
    id: root
    property bool extraCondition: true
    property string panelSource
    property bool deferred: Platform.isWindows
    property int deferPriority: 0
    property bool released: false
    readonly property bool wanted: Config.ready && extraCondition && released
    active: wanted && (panelSource === "" || source !== "")

    function loadSource() {
        if (wanted && panelSource !== "" && source === "")
            source = panelSource;
    }

    onWantedChanged: loadSource()
    Component.onCompleted: {
        if (deferred)
            PanelLoaderQueue.add(root);
        else
            released = true;
    }
    Component.onDestruction: if (!released) PanelLoaderQueue.remove(root)
}

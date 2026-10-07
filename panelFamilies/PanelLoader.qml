import QtQuick
import Quickshell

import qs.modules.common

LazyLoader {
    id: root
    property bool extraCondition: true
    property bool deferred: Platform.isWindows
    property int deferPriority: 0
    property bool released: !deferred
    active: Config.ready && extraCondition && released

    Component.onCompleted: if (!released) PanelLoaderQueue.add(root)
    Component.onDestruction: if (!released) PanelLoaderQueue.remove(root)
}

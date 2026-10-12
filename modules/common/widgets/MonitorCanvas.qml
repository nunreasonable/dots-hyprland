import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property var monitorConfig
    property real padding: 20
    property int selectedIndex: 0
    property string selectedName: ""
    property var previewPositions: ({})
    property bool dragHasOverlap: false
    property bool dragging: false
    property var frozenBounds: null
    readonly property bool nativeLayout: typeof root.monitorConfig?.previewLayout === "function"

    implicitHeight: 220

    function computeBounds() {
        let minX = Infinity, minY = Infinity
        let maxX = -Infinity, maxY = -Infinity
        const mons = monitorConfig.monitors
        for (let i = 0; i < mons.length; i++) {
            const m = mons[i]
            if (m.disabled && !root.nativeLayout) continue
            const w = monitorConfig.logicalWidth(m)
            const h = monitorConfig.logicalHeight(m)
            const px = previewPositions[m.name]?.x ?? m.x
            const py = previewPositions[m.name]?.y ?? m.y
            minX = Math.min(minX, px)
            minY = Math.min(minY, py)
            maxX = Math.max(maxX, px + w)
            maxY = Math.max(maxY, py + h)
        }
        if (minX === Infinity) return { minX: 0, minY: 0, width: 1920, height: 1080 }
        return { minX, minY, width: maxX - minX, height: maxY - minY }
    }

    property var bounds: root.frozenBounds ?? root.computeBounds()

    property real scaleFactor: {
        if (bounds.width === 0 || bounds.height === 0) return 0.1
        const scaleX = (canvas.width  - padding * 2) / bounds.width
        const scaleY = (canvas.height - padding * 2) / bounds.height
        return Math.min(scaleX, scaleY)
    }

    property point offset: Qt.point(
        (canvas.width  - bounds.width  * scaleFactor) / 2 - bounds.minX * scaleFactor,
        (canvas.height - bounds.height * scaleFactor) / 2 - bounds.minY * scaleFactor
    )

    function selectIndex(idx) {
        root.selectedIndex = idx
        root.selectedName = monitorConfig.monitors[idx]?.name ?? ""
    }

    function syncSelection() {
        const mons = monitorConfig?.monitors ?? []
        if (mons.length === 0) return
        let idx = mons.findIndex(m => m.name === root.selectedName)
        if (idx < 0) idx = Math.max(0, mons.findIndex(m => m.primary === true))
        if (idx >= mons.length) idx = 0
        root.selectIndex(idx)
    }

    function checkOverlap(monitors, idx) {
        const a = monitors[idx]
        const aw = monitorConfig.logicalWidth(a)
        const ah = monitorConfig.logicalHeight(a)
        for (let i = 0; i < monitors.length; i++) {
            if (i === idx) continue
            if (monitors[i].disabled) continue
            const b = monitors[i]
            const bw = monitorConfig.logicalWidth(b)
            const bh = monitorConfig.logicalHeight(b)
            if (a.x < b.x + bw && a.x + aw > b.x &&
                a.y < b.y + bh && a.y + ah > b.y) {
                return true
            }
        }
        return false
    }

    function computeNormalized(monitors, changedIdx, newX, newY) {
        let m = monitors.slice().map(mon => Object.assign({}, mon))
        m[changedIdx].x = newX
        m[changedIdx].y = newY
        let minX = Infinity, minY = Infinity
        for (let i = 0; i < m.length; i++) {
            if (m[i].disabled) continue
            minX = Math.min(minX, m[i].x)
            minY = Math.min(minY, m[i].y)
        }
        const offX = minX < 0 ? -minX : 0
        const offY = minY < 0 ? -minY : 0
        if (offX > 0 || offY > 0) {
            for (let i = 0; i < m.length; i++) {
                m[i].x += offX
                m[i].y += offY
            }
        }
        return m
    }

    function updatePreview(idx, newX, newY) {
        if (root.nativeLayout) {
            root.dragHasOverlap = false
            root.previewPositions = monitorConfig.previewLayout(idx, newX, newY) ?? {}
            return
        }
        const normalized = computeNormalized(monitorConfig.monitors, idx, newX, newY)
        root.dragHasOverlap = checkOverlap(normalized, idx)
        let preview = {}
        for (let i = 0; i < normalized.length; i++) {
            preview[normalized[i].name] = { x: normalized[i].x, y: normalized[i].y }
        }
        root.previewPositions = preview
    }

    function commitPosition(idx, newX, newY) {
        if (root.nativeLayout) {
            const preview = monitorConfig.previewLayout(idx, newX, newY) ?? {}
            const target = preview[monitorConfig.monitors[idx]?.name]
            if (!target || !monitorConfig.commitPosition(idx, target.x, target.y)) {
                root.previewPositions = {}
                return
            }
            root.previewPositions = preview
            previewTimeout.restart()
            return
        }
        const normalized = computeNormalized(monitorConfig.monitors, idx, newX, newY)
        monitorConfig.monitors = normalized
        root.previewPositions = {}
        for (let i = 0; i < normalized.length; i++) {
            monitorConfig.applyMonitor(normalized[i])
        }
        monitorConfig.save()
    }

    Timer {
        id: previewTimeout
        interval: 4000
        onTriggered: root.previewPositions = {}
    }

    Connections {
        target: root.monitorConfig
        ignoreUnknownSignals: true

        function onMonitorsChanged() {
            if (!root.dragging) {
                previewTimeout.stop()
                root.previewPositions = {}
            }
            root.syncSelection()
        }

        function onFailed() {
            previewTimeout.stop()
            root.previewPositions = {}
        }
    }

    Component.onCompleted: root.syncSelection()

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer1
        border.width: 1
        border.color: Appearance.colors.colLayer0Border

        Item {
            id: canvas
            anchors.fill: parent

            Repeater {
                model: root.monitorConfig.monitors.length
                delegate: MonitorRect {
                    required property int index
                    monitor: root.monitorConfig.monitors[index]
                    monitorIndex: index
                    monitorConfig: root.monitorConfig
                    scaleFactor: root.scaleFactor
                    canvasOffset: root.offset
                    allMonitors: root.monitorConfig.monitors
                    isSelected: index === root.selectedIndex
                    previewPositions: root.previewPositions
                    hasOverlap: root.dragHasOverlap && isDragging

                    onIsDraggingChanged: {
                        if (isDragging) {
                            root.frozenBounds = root.bounds
                            root.dragging = true
                        } else {
                            root.dragging = false
                            root.frozenBounds = null
                        }
                    }

                    onMonitorClicked: (idx) => root.selectIndex(idx)
                    onPositionDragging: (idx, x, y) => root.updatePreview(idx, x, y)
                    onPositionCommitted: (idx, x, y) => {
                        const hadOverlap = root.dragHasOverlap
                        root.dragHasOverlap = false
                        root.selectIndex(idx)
                        if (!hadOverlap)
                            root.commitPosition(idx, x, y)
                        else
                            root.previewPositions = {}
                    }
                }
            }
        }
    }
}

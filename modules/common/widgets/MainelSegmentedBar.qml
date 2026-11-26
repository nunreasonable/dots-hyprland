import QtQuick
import qs.modules.common
import qs.modules.common.widgets

// Mainel's segmented value bar: built on MainelPaneGroup so the lit/unlit segments
// get the same pane corner rule as everything else. Used read-only by the OSD;
// `interactive` turns it into a click/drag value setter.
Item {
    id: root

    property real value: 0
    property int segments: 12
    property real segmentSpacing: 3
    property bool interactive: false
    property real radiusOuter: StyleTheme.surface.radiusOuter ?? 18
    property real radiusInner: StyleTheme.surface.radiusInner ?? 3
    property color unfilledColor: StyleTheme.surface.fill ?? Appearance.colors.colLayer1
    signal moved(real value)

    implicitHeight: 36

    readonly property real clampedValue: Math.max(0, Math.min(1, root.value))
    readonly property int filledCount: Math.round(root.clampedValue * root.segments)
    readonly property var accentList: {
        const list = [];
        for (let i = 0; i < root.filledCount; i++)
            list.push(i);
        return list;
    }

    Row {
        id: segmentRow
        anchors.fill: parent
        spacing: root.segmentSpacing

        Repeater {
            model: root.segments
            Item {
                required property int index
                width: (segmentRow.width - root.segmentSpacing * (root.segments - 1)) / root.segments
                height: segmentRow.height
            }
        }
    }

    MainelPaneGroup {
        target: segmentRow
        rows: 1
        columns: root.segments
        radiusOuter: root.radiusOuter
        radiusInner: root.radiusInner
        fill: root.unfilledColor
        accentIndices: root.accentList
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        onPressed: mouse => root.moved(Math.max(0, Math.min(1, mouse.x / width)))
        onPositionChanged: mouse => {
            if (pressed)
                root.moved(Math.max(0, Math.min(1, mouse.x / width)));
        }
    }
}

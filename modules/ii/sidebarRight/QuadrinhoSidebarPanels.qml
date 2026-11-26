pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    required property var column
    readonly property real pad: (root.column.itemSpacing - QuadrinhoTheme.gutterWide) / 2
    readonly property real slant: 10

    Repeater {
        model: root.column.stableKeys

        delegate: QuadrinhoPanel {
            id: panel
            required property string modelData

            visible: root.column.isShown(panel.modelData) && root.column.draggingKey !== panel.modelData
            x: -root.pad
            y: root.column.yForKey(panel.modelData) - root.pad
            width: root.column.width + root.pad * 2
            height: root.column.effectiveHeight(panel.modelData) + root.pad * 2
            bottomRightY: panel.modelData === "banner" ? root.slant : 0
            topLeftX: panel.modelData === "media" ? root.slant * 1.6 : 0
        }
    }
}

import QtQuick
import qs.modules.common

Item {
    id: root

    property string text: ""
    property color color: Appearance.colors.colOnSecondaryContainer
    property font font
    property real cutHeight: 7
    property real offset: 14
    property int horizontalAlignment: Text.AlignHCenter

    implicitWidth: metrics.implicitWidth + root.offset
    implicitHeight: metrics.implicitHeight
    width: implicitWidth
    height: implicitHeight

    readonly property real halfHeight: Math.max(0, (root.height - root.cutHeight) / 2)

    Text {
        id: metrics
        visible: false
        text: root.text
        font: root.font
    }

    Item {
        id: topHalf
        x: 0
        y: 0
        width: root.width - root.offset
        height: root.halfHeight
        clip: true

        Text {
            width: parent.width
            text: root.text
            color: root.color
            font: root.font
            horizontalAlignment: root.horizontalAlignment
        }
    }

    Item {
        id: bottomHalf
        x: root.offset
        y: root.halfHeight + root.cutHeight
        width: root.width - root.offset
        height: root.halfHeight
        clip: true

        Text {
            width: parent.width
            y: -(root.halfHeight + root.cutHeight)
            text: root.text
            color: root.color
            font: root.font
            horizontalAlignment: root.horizontalAlignment
        }
    }
}

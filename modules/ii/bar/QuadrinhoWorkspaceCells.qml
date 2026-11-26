pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    required property var host
    required property var model

    readonly property bool vertical: root.host.vertical
    readonly property real slot: root.host.workspaceButtonWidth
    readonly property real cell: root.slot - 4
    readonly property real depth: Math.max(root.cell, (root.vertical ? root.width : root.height) - 8)
    readonly property int active: root.host.workspaceIndexInGroup

    function occupied(index) {
        return root.model.occupied[index] && root.model.getWorkspaceIdAt(index) !== root.model.fakeWorkspace;
    }

    onActiveChanged: if (QuadrinhoTheme.motion)
        shake.restart()

    Rectangle {
        anchors.fill: parent
        color: QuadrinhoTheme.paper
    }

    Repeater {
        model: root.model.shownCount

        delegate: Rectangle {
            id: frame
            required property int index
            readonly property bool current: frame.index === root.active
            readonly property real along: frame.index * root.slot + (root.slot - root.cell) / 2

            x: (root.vertical ? (root.width - root.depth) / 2 : frame.along) + (frame.current ? shake.offset : 0)
            y: root.vertical ? frame.along : (root.height - root.depth) / 2
            width: root.vertical ? root.depth : root.cell
            height: root.vertical ? root.cell : root.depth
            color: frame.current ? QuadrinhoTheme.ink : QuadrinhoTheme.paper
            border.width: 2
            border.color: QuadrinhoTheme.ink

            QuadrinhoTone {
                visible: !frame.current && root.occupied(frame.index)
                anchors.fill: parent
                anchors.margins: 2
                density: 10
            }
        }
    }

    SequentialAnimation {
        id: shake
        property real offset: 0
        NumberAnimation { target: shake; property: "offset"; to: 3; duration: 15 }
        NumberAnimation { target: shake; property: "offset"; to: -3; duration: 30 }
        NumberAnimation { target: shake; property: "offset"; to: 3; duration: 30 }
        NumberAnimation { target: shake; property: "offset"; to: -3; duration: 30 }
        NumberAnimation { target: shake; property: "offset"; to: 0; duration: 15 }
    }
}

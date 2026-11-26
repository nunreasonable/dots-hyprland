pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    required property var host
    required property var model

    readonly property bool vertical: root.host.vertical
    readonly property real slot: root.host.slotLength
    readonly property int count: root.model.shownCount
    readonly property real diameter: Math.min(root.slot - 5, 22)

    implicitWidth: root.vertical ? root.host.barThickness : root.count * root.slot
    implicitHeight: root.vertical ? root.count * root.slot : root.host.barThickness

    Repeater {
        model: root.count

        delegate: Item {
            id: cell

            required property int index
            readonly property int wsId: root.model.getWorkspaceIdAt(cell.index)
            readonly property bool active: cell.index === root.host.workspaceIndexInGroup
            readonly property bool hovered: root.host.containsMouse && root.host.hoverIndex === cell.index
            readonly property bool occupied: (root.model.occupied[cell.index] ?? false) && cell.wsId !== root.model.fakeWorkspace
            readonly property int windows: cell.occupied ? Math.max(1, HyprlandData.windowList.filter(win => win.workspace?.id === cell.wsId).length) : 0

            x: root.vertical ? 0 : cell.index * root.slot
            y: root.vertical ? cell.index * root.slot : 0
            width: root.vertical ? root.width : root.slot
            height: root.vertical ? root.slot : root.height

            Rectangle {
                anchors.centerIn: parent
                width: root.diameter + 6
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: cell.active ? AquarioTheme.waterDeep : AquarioTheme.rimInner
                opacity: cell.active ? 1 : cell.hovered ? 0.9 : 0

                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

            AquarioBubble {
                id: sphere
                anchors.centerIn: parent
                diameter: root.diameter
                level: cell.windows === 0 ? 0 : [0.32, 0.56, 0.8][Math.min(cell.windows, 3) - 1]
                deep: cell.active
            }

            StyledText {
                anchors.centerIn: sphere
                visible: root.host.superPressAndHeld
                text: Config.options?.bar.workspaces.numberMap[cell.wsId - 1] || cell.wsId
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Bold
                color: cell.windows >= 2 ? AquarioTheme.onWater : AquarioTheme.text
            }
        }
    }
}

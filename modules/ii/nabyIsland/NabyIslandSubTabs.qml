pragma ComponentBehavior: Bound
import qs.modules.common.widgets
import QtQuick

Row {
    id: root

    property var model: []
    property string current: ""

    signal selected(string id)

    spacing: 4
    height: 28

    Repeater {
        model: root.model

        NabyIslandButton {
            id: subTab
            required property var modelData
            readonly property bool active: subTab.modelData.id === root.current
            width: subTabLabel.implicitWidth + 22
            height: 28
            radius: 10
            colNormal: subTab.active ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
            colHover: subTab.active ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.08)
            onClicked: root.selected(subTab.modelData.id)

            StyledText {
                id: subTabLabel
                anchors.centerIn: parent
                text: subTab.modelData.name
                color: "#ffffff"
                opacity: subTab.active ? 1 : 0.6
                font.pixelSize: 12
            }
        }
    }
}

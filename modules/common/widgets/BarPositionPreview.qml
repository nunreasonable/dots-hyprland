import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool vertical: false
    property bool atBottom: false
    property real thickness: 14

    implicitWidth: 130
    implicitHeight: 76

    Rectangle {
        id: screen
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height * 1.7)
        height: width / 1.7
        radius: 14
        color: Qt.rgba(0, 0, 0, 0.35)
        border.width: 2
        border.color: Appearance.colors.colOutlineVariant

        Rectangle {
            id: mockBar
            radius: 7
            color: Appearance.colors.colPrimary
            x: root.vertical ? (root.atBottom ? screen.width - width - 5 : 5) : 5
            y: root.vertical ? 5 : (root.atBottom ? screen.height - height - 5 : 5)
            width: root.vertical ? root.thickness : screen.width - 10
            height: root.vertical ? screen.height - 10 : root.thickness

            Behavior on x {
                SpringAnimation {
                    spring: 3.5
                    damping: 0.3
                }
            }
            Behavior on y {
                SpringAnimation {
                    spring: 3.5
                    damping: 0.3
                }
            }
            Behavior on width {
                SpringAnimation {
                    spring: 3.5
                    damping: 0.3
                }
            }
            Behavior on height {
                SpringAnimation {
                    spring: 3.5
                    damping: 0.3
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 4
                visible: !root.vertical

                Repeater {
                    model: 3
                    Rectangle {
                        width: 11
                        height: 3
                        radius: 1.5
                        color: Appearance.colors.colOnPrimary
                        opacity: 0.8
                    }
                }
            }
            Column {
                anchors.centerIn: parent
                spacing: 4
                visible: root.vertical

                Repeater {
                    model: 3
                    Rectangle {
                        width: 3
                        height: 11
                        radius: 1.5
                        color: Appearance.colors.colOnPrimary
                        opacity: 0.8
                    }
                }
            }
        }
    }
}

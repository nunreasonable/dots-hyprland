pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell

Item {
    id: root

    signal closeRequested

    readonly property var tools: [
        { id: "shelf", icon: "folder", name: Translation.tr("File shelf") },
        { id: "notes", icon: "description", name: Translation.tr("Notes") },
        { id: "clipboard", icon: "content_paste", name: Translation.tr("Clipboard") },
        { id: "calendar", icon: "calendar_month", name: Translation.tr("Calendar") },
        { id: "awake", icon: "coffee", name: Translation.tr("Keep awake") },
    ]
    readonly property string tool: root.tools.some(t => t.id === Persistent.states.nabyIsland.tool) ? Persistent.states.nabyIsland.tool : ""

    implicitHeight: root.tool === "" ? toolList.implicitHeight : backLink.height + 8 + toolLoader.implicitHeight

    function openTool(id) {
        Persistent.states.nabyIsland.tool = id;
    }

    Column {
        id: toolList
        visible: root.tool === ""
        width: parent.width
        spacing: 2

        Repeater {
            model: root.tools

            NabyIslandButton {
                id: toolRow
                required property var modelData
                x: -10
                width: toolList.width + 20
                height: 36
                radius: 12
                onClicked: root.openTool(toolRow.modelData.id)

                MaterialSymbol {
                    id: toolIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: toolRow.modelData.icon
                    iconSize: 20
                    color: "#ffffff"
                }

                StyledText {
                    anchors.left: toolIcon.right
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: toolRow.modelData.name
                    color: "#ffffff"
                    font.pixelSize: 13
                }

                StyledText {
                    anchors.right: toolChevron.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    visible: toolRow.modelData.id === "awake"
                    text: Idle.inhibit ? Translation.tr("On") : Translation.tr("Off")
                    color: "#ffffff"
                    opacity: 0.55
                    font.pixelSize: 12
                }

                MaterialSymbol {
                    id: toolChevron
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "chevron_right"
                    iconSize: 18
                    color: "#ffffff"
                    opacity: toolRow.hovered ? 0.8 : 0.35
                }
            }
        }
    }

    NabyIslandButton {
        id: backLink
        visible: root.tool !== ""
        x: -8
        y: 0
        width: backRow.implicitWidth + 16
        height: 26
        radius: 8
        onClicked: root.openTool("")

        Row {
            id: backRow
            anchors.centerIn: parent
            spacing: 2

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: "chevron_left"
                iconSize: 16
                color: "#ffffff"
                opacity: 0.7
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Translation.tr("All tools")
                color: "#ffffff"
                opacity: 0.7
                font.pixelSize: 12
            }
        }
    }

    Loader {
        id: toolLoader
        anchors.top: backLink.bottom
        anchors.topMargin: 8
        width: parent.width
        active: root.tool !== ""
        sourceComponent: {
            switch (root.tool) {
            case "shelf":
                return shelfView;
            case "notes":
                return notesView;
            case "clipboard":
                return clipboardView;
            case "calendar":
                return calendarView;
            case "awake":
                return awakeView;
            default:
                return null;
            }
        }
    }

    Component {
        id: shelfView
        NabyIslandShelf {
            onCloseRequested: root.closeRequested()
        }
    }

    Component {
        id: notesView
        NabyIslandNotes {}
    }

    Component {
        id: clipboardView
        NabyIslandClipboard {}
    }

    Component {
        id: calendarView
        NabyIslandCalendar {}
    }

    Component {
        id: awakeView

        Item {
            implicitHeight: 150

            NabyIslandButton {
                id: awakeButton
                anchors.horizontalCenter: parent.horizontalCenter
                y: 4
                width: 72
                height: 72
                highlighted: Idle.inhibit
                colNormal: Qt.rgba(1, 1, 1, 0.08)
                colHover: Qt.rgba(1, 1, 1, 0.16)
                onClicked: Idle.toggleInhibit()

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "coffee"
                    iconSize: 34
                    fill: Idle.inhibit ? 1 : 0
                    color: Idle.inhibit ? "#000000" : "#ffffff"
                }
            }

            StyledText {
                id: awakeTitle
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: awakeButton.bottom
                anchors.topMargin: 12
                text: Idle.inhibit ? Translation.tr("Keeping the system awake") : Translation.tr("Keep awake is off")
                color: "#ffffff"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.variableAxes: ({ "wght": 600 })
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: awakeTitle.bottom
                anchors.topMargin: 2
                text: Idle.inhibit ? Translation.tr("It won't go idle or sleep on its own") : Translation.tr("Click the cup to keep the system awake")
                color: "#ffffff"
                opacity: 0.55
                font.pixelSize: 12
            }
        }
    }
}

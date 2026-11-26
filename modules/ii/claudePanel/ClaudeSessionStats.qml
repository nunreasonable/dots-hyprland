pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property var session: null
    readonly property real contextTokens: root.session?.contextTokens ?? 0
    readonly property real contextWindow: ClaudeCode.contextWindow(root.session)
    readonly property real contextRatio: Math.min(1, root.contextTokens / root.contextWindow)
    readonly property var tasks: root.session?.tasks ?? []
    readonly property int doneTasks: root.tasks.filter(task => task.status === "completed").length

    spacing: 12

    component Card: Rectangle {
        id: card
        property string icon: ""
        property string title: ""
        property string trailing: ""
        default property alias content: cardColumn.data
        Layout.fillWidth: true
        implicitHeight: cardColumn.implicitHeight + 28
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer1

        ColumnLayout {
            id: cardColumn
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialSymbol {
                    text: card.icon
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colSubtext
                }
                StyledText {
                    Layout.fillWidth: true
                    text: card.title
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    visible: card.trailing !== ""
                    text: card.trailing
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }

    Card {
        icon: "neurology"
        title: Translation.tr("Model")

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                text: ClaudeCode.modelName(root.session?.model ?? "")
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                elide: Text.ElideRight
            }
            Rectangle {
                visible: (root.session?.effort ?? "") !== ""
                implicitWidth: effortText.implicitWidth + 16
                implicitHeight: 24
                radius: Appearance.rounding.full
                color: Appearance.colors.colSecondaryContainer

                StyledText {
                    id: effortText
                    anchors.centerIn: parent
                    text: ClaudeCode.effortName(root.session?.effort ?? "")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSecondaryContainer
                }
            }
        }
    }

    Card {
        icon: "data_usage"
        title: Translation.tr("Context")
        trailing: `${Math.round(root.contextRatio * 100)}%`

        StyledText {
            Layout.fillWidth: true
            text: `${ClaudeCode.tokensText(root.contextTokens)} / ${ClaudeCode.tokensText(root.contextWindow)}`
            font.pixelSize: Appearance.font.pixelSize.larger
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer1
        }
        StyledProgressBar {
            Layout.fillWidth: true
            value: root.contextRatio
            highlightColor: root.contextRatio >= 0.9 ? Appearance.colors.colError : Appearance.colors.colPrimary
        }
    }

    Card {
        Layout.fillHeight: true
        icon: "checklist"
        title: Translation.tr("Tasks")
        trailing: root.tasks.length > 0 ? `${root.doneTasks}/${root.tasks.length}` : ""

        StyledFlickable {
            id: taskFlickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.tasks.length > 0
            clip: true
            contentWidth: width
            contentHeight: taskColumn.implicitHeight

            ColumnLayout {
                id: taskColumn
                width: taskFlickable.width
                spacing: 8

                Repeater {
                    model: root.tasks

                    delegate: RowLayout {
                        id: taskRow
                        required property var modelData
                        readonly property string status: taskRow.modelData.status ?? "pending"
                        Layout.fillWidth: true
                        spacing: 8

                        MaterialSymbol {
                            Layout.alignment: Qt.AlignTop
                            text: taskRow.status === "completed" ? "check_circle" : taskRow.status === "in_progress" ? "progress_activity" : "radio_button_unchecked"
                            fill: taskRow.status === "completed" ? 1 : 0
                            iconSize: Appearance.font.pixelSize.larger
                            color: taskRow.status === "pending" ? Appearance.colors.colSubtext : Appearance.colors.colPrimary
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: taskRow.status === "in_progress" && taskRow.modelData.activeForm ? taskRow.modelData.activeForm : (taskRow.modelData.subject ?? "")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: taskRow.status === "in_progress" ? Font.Medium : Font.Normal
                            font.strikeout: taskRow.status === "completed"
                            color: taskRow.status === "completed" ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer1
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.tasks.length === 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: Translation.tr("No tasks in this session")
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }
    }
}

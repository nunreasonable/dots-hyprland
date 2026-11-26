pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property var session: null
    signal resumeRequested
    signal openFolderRequested

    color: Appearance.colors.colLayer1
    radius: Appearance.rounding.normal

    component InfoChip: Rectangle {
        id: chip
        property string icon: ""
        property string text: ""
        implicitWidth: chipRow.implicitWidth + 20
        implicitHeight: 28
        radius: Appearance.rounding.full
        color: Appearance.colors.colLayer2

        RowLayout {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6

            MaterialSymbol {
                text: chip.icon
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer2
            }
            StyledText {
                text: chip.text
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnLayer2
            }
        }
    }

    component ActionButton: RippleButton {
        id: action
        property string symbol: ""
        property bool primary: false
        implicitHeight: 40
        implicitWidth: actionRow.implicitWidth + 32
        buttonRadius: Appearance.rounding.full
        colBackground: action.primary ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
        colBackgroundHover: action.primary ? Appearance.colors.colPrimaryHover : Appearance.colors.colSecondaryContainerHover
        colRipple: action.primary ? Appearance.colors.colPrimaryActive : Appearance.colors.colSecondaryContainerActive

        contentItem: Item {
            RowLayout {
                id: actionRow
                anchors.centerIn: parent
                spacing: 8

                MaterialSymbol {
                    text: action.symbol
                    iconSize: Appearance.font.pixelSize.larger
                    color: action.primary ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                }
                StyledText {
                    text: action.buttonText
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: action.primary ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        StyledText {
            Layout.fillWidth: true
            text: root.session?.title || Translation.tr("Untitled session")
            font.family: Appearance.font.family.title
            font.pixelSize: Appearance.font.pixelSize.huge
            color: Appearance.colors.colOnLayer1
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialSymbol {
                Layout.alignment: Qt.AlignTop
                text: "folder"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colSubtext
            }
            StyledText {
                Layout.fillWidth: true
                text: root.session?.cwd || "—"
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.WrapAnywhere
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 8

            InfoChip {
                icon: "schedule"
                text: ClaudeCode.relativeTime(root.session?.mtime ?? 0)
            }
            InfoChip {
                visible: (root.session?.costUsd ?? 0) > 0
                icon: "payments"
                text: ClaudeCode.costText(root.session?.costUsd ?? 0)
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: 4
            text: Translation.tr("Last prompt")
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer1
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.rounding.small
            color: Appearance.colors.colLayer2

            StyledFlickable {
                id: promptFlickable
                anchors.fill: parent
                anchors.margins: 12
                clip: true
                contentWidth: width
                contentHeight: promptText.implicitHeight

                StyledText {
                    id: promptText
                    width: promptFlickable.width
                    text: root.session?.lastPrompt || Translation.tr("No prompt yet")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: root.session?.lastPrompt ? Appearance.colors.colOnLayer2 : Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item {
                Layout.fillWidth: true
            }
            ActionButton {
                symbol: "folder_open"
                buttonText: Translation.tr("Open folder")
                onClicked: root.openFolderRequested()
            }
            ActionButton {
                primary: true
                symbol: "play_arrow"
                buttonText: Translation.tr("Resume session")
                onClicked: root.resumeRequested()
            }
        }
    }
}

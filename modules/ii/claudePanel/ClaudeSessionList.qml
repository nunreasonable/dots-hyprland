pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    property string selectedId: ""
    property bool foldersOpen: false
    signal sessionSelected(string sessionId)
    signal startRequested(string folder)

    color: Appearance.colors.colLayer1
    radius: Appearance.rounding.normal

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.topMargin: 4
            text: Translation.tr("Sessions")
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer1
        }

        RippleButton {
            id: newButton
            Layout.fillWidth: true
            implicitHeight: 40
            buttonRadius: Appearance.rounding.small
            enabled: ClaudeCode.cliFound
            toggled: root.foldersOpen
            colBackground: Appearance.colors.colPrimaryContainer
            colBackgroundHover: Appearance.colors.colPrimaryContainerHover
            colRipple: Appearance.colors.colPrimaryContainerActive
            onClicked: root.foldersOpen = !root.foldersOpen

            contentItem: RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                MaterialSymbol {
                    text: "add"
                    iconSize: Appearance.font.pixelSize.larger
                    color: newButton.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnPrimaryContainer
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("New session")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: newButton.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnPrimaryContainer
                }
                MaterialSymbol {
                    text: root.foldersOpen ? "expand_less" : "expand_more"
                    iconSize: Appearance.font.pixelSize.larger
                    color: newButton.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnPrimaryContainer
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.foldersOpen
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                text: Translation.tr("Start in")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }

            ListView {
                id: folderList
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(folderList.contentHeight, 46 * 4)
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationEnabled: false
                model: root.foldersOpen ? ClaudeCode.folders : []

                delegate: RippleButton {
                    id: folderRow
                    required property string modelData
                    width: ListView.view.width
                    implicitHeight: 44
                    buttonRadius: Appearance.rounding.small
                    onClicked: {
                        root.foldersOpen = false;
                        root.startRequested(folderRow.modelData);
                    }

                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        MaterialSymbol {
                            text: ClaudeCode.folderKey(folderRow.modelData) === ClaudeCode.folderKey(ClaudeCode.homeDir) ? "home" : "folder"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colOnLayer1
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: ClaudeCode.folderName(folderRow.modelData)
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: folderRow.modelData
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                color: Appearance.colors.colSubtext
                                elide: Text.ElideMiddle
                            }
                        }
                    }

                    StyledToolTip {
                        text: folderRow.modelData
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 4
                implicitHeight: 1
                color: Appearance.colors.colOutlineVariant
            }
        }

        StyledListView {
            id: sessionList
            readonly property int selectedIndex: ClaudeCode.sessions.findIndex(session => session.id === root.selectedId)
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: ClaudeCode.sessions.length > 0
            clip: true
            spacing: 2
            animateMovement: true
            keyNavigationEnabled: false
            model: ScriptModel {
                values: ClaudeCode.sessions.map(session => session.id)
            }
            onSelectedIndexChanged: {
                if (sessionList.selectedIndex >= 0)
                    sessionList.positionViewAtIndex(sessionList.selectedIndex, ListView.Contain);
            }

            delegate: RippleButton {
                id: sessionRow
                required property string modelData
                readonly property var session: ClaudeCode.sessionsById[sessionRow.modelData] ?? null
                readonly property bool selected: sessionRow.modelData === root.selectedId
                width: ListView.view.width
                implicitHeight: 56
                buttonRadius: Appearance.rounding.small
                colBackground: sessionRow.selected ? Appearance.colors.colSecondaryContainer : ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, 1)
                colBackgroundHover: sessionRow.selected ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colLayer1Hover
                colRipple: Appearance.colors.colSecondaryContainerActive
                onClicked: root.sessionSelected(sessionRow.modelData)

                contentItem: ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: sessionRow.session?.title || Translation.tr("Untitled session")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: sessionRow.selected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                        elide: Text.ElideRight
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        MaterialSymbol {
                            text: "folder"
                            iconSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: ClaudeCode.folderName(sessionRow.session?.cwd ?? "")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideRight
                        }
                        StyledText {
                            text: ClaudeCode.relativeTime(sessionRow.session?.mtime ?? 0)
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
            visible: !sessionList.visible
        }
    }
}

pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: dropoverScope

    function openOnCursorOrFocusedScreen() {
        if (Platform.isWindows) {
            const cursor = WindowsNative.input?.cursorPosition() ?? {};
            const cursorScreen = Quickshell.screens.find(s => s.name === cursor.screen);
            const focusedScreen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name);
            const screen = cursorScreen ?? focusedScreen ?? Quickshell.screens[0];
            if (!screen)
                return;
            GlobalStates.dropoverScreen = screen;
            GlobalStates.dropoverX = cursorScreen ? cursor.x : screen.width / 2;
            GlobalStates.dropoverY = cursorScreen ? cursor.y : screen.height / 2;
            GlobalStates.dropoverOpen = true;
            return;
        }
        const screen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
        if (!screen)
            return;
        GlobalStates.dropoverScreen = screen;
        GlobalStates.dropoverX = screen.width / 2;
        GlobalStates.dropoverY = screen.height / 2;
        GlobalStates.dropoverOpen = true;
    }

    function toggle() {
        if (GlobalStates.dropoverOpen) {
            GlobalStates.dropoverOpen = false;
            return;
        }
        dropoverScope.openOnCursorOrFocusedScreen();
    }

    IpcHandler {
        target: "dropover"

        function toggle(): void {
            dropoverScope.toggle();
        }
        function open(): void {
            dropoverScope.openOnCursorOrFocusedScreen();
        }
        function close(): void {
            GlobalStates.dropoverOpen = false;
        }
    }

    GlobalShortcut {
        name: "dropoverToggle"
        description: "Toggles ii's drag-and-drop shelf at the cursor"

        onPressed: dropoverScope.toggle()
    }

    LazyLoader {
        active: GlobalStates.dropoverOpen

        PanelWindow {
            id: shelfRoot
            screen: GlobalStates.dropoverScreen
            visible: GlobalStates.dropoverOpen
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:dropover"
            color: "transparent"

            anchors {
                top: true
                left: true
            }
            margins {
                left: Math.max(20, GlobalStates.dropoverX - implicitWidth / 2)
                top: Math.max(20, GlobalStates.dropoverY - implicitHeight - 30)
            }

            implicitWidth: 380
            implicitHeight: contentColumn.implicitHeight + 24

            DropArea {
                anchors.fill: parent
                keys: ["text/uri-list"]

                onEntered: drag => {
                    drag.accepted = drag.hasUrls;
                }

                onDropped: drop => {
                    if (!drop.hasUrls) {
                        drop.accepted = false;
                        return;
                    }
                    DropShelf.addItems(drop.urls);
                    drop.accept();
                }
            }

            StyledRectangularShadow {
                target: shelfBg
            }

            Rectangle {
                id: shelfBg
                anchors.fill: parent
                radius: Appearance.rounding.large
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                ColumnLayout {
                    id: contentColumn
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    ListView {
                        id: shelfList
                        Layout.fillWidth: true
                        Layout.preferredHeight: 110
                        orientation: ListView.Horizontal
                        spacing: 8
                        clip: true
                        model: DropShelf.items

                        Text {
                            anchors.centerIn: parent
                            visible: shelfList.count === 0
                            text: Translation.tr("Drop files here")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.normal
                        }

                        delegate: Item {
                            id: shelfItem
                            required property string modelData
                            width: 100
                            height: 100
                            readonly property bool isImage: /\.(png|jpe?g|webp|bmp|gif)$/i.test(shelfItem.modelData)

                            Loader {
                                anchors.fill: parent
                                sourceComponent: shelfItem.isImage ? imageDelegate : fileDelegate
                            }

                            Component {
                                id: imageDelegate
                                Item {
                                    anchors.fill: parent
                                    StyledImage {
                                        id: shelfImg
                                        anchors.fill: parent
                                        source: Qt.resolvedUrl(shelfItem.modelData)
                                        fillMode: Image.PreserveAspectCrop
                                        cache: false
                                        asynchronous: true

                                        Drag.active: imgDragArea.drag.active
                                        Drag.dragType: Drag.Automatic
                                        Drag.mimeData: ({
                                                "text/uri-list": Qt.resolvedUrl(shelfItem.modelData)
                                            })
                                        Drag.supportedActions: Qt.CopyAction

                                        MouseArea {
                                            id: imgDragArea
                                            anchors.fill: parent
                                            drag.target: parent
                                            cursorShape: Qt.OpenHandCursor
                                            onReleased: {
                                                if (parent.Drag.active)
                                                    parent.Drag.drop();
                                                parent.x = 0;
                                                parent.y = 0;
                                            }
                                        }
                                    }
                                }
                            }

                            Component {
                                id: fileDelegate
                                Item {
                                    anchors.fill: parent
                                    Rectangle {
                                        id: fileBg
                                        anchors.fill: parent
                                        radius: Appearance.rounding.small
                                        color: Appearance.colors.colSurfaceContainerHighest

                                        Drag.active: fileDragArea.drag.active
                                        Drag.dragType: Drag.Automatic
                                        Drag.mimeData: ({
                                                "text/uri-list": Qt.resolvedUrl(shelfItem.modelData)
                                            })
                                        Drag.supportedActions: Qt.CopyAction

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 4
                                            MaterialSymbol {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: "draft"
                                                iconSize: 32
                                                color: Appearance.colors.colOnLayer1
                                            }
                                            StyledText {
                                                Layout.alignment: Qt.AlignHCenter
                                                Layout.maximumWidth: 90
                                                elide: Text.ElideMiddle
                                                text: shelfItem.modelData.split(/[\\/]/).pop()
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                color: Appearance.colors.colOnLayer1
                                            }
                                        }

                                        MouseArea {
                                            id: fileDragArea
                                            anchors.fill: parent
                                            drag.target: parent
                                            cursorShape: Qt.OpenHandCursor
                                            onReleased: {
                                                if (parent.Drag.active)
                                                    parent.Drag.drop();
                                                parent.x = 0;
                                                parent.y = 0;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("%1 elements").arg(DropShelf.items.length)
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer0
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 8

                        RippleButton {
                            Layout.fillWidth: true
                            implicitHeight: 40
                            buttonRadius: height / 2
                            colBackground: Appearance.colors.colSecondaryContainer
                            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                            onClicked: DropShelf.copyAll()
                            contentItem: StyledText {
                                horizontalAlignment: Text.AlignHCenter
                                text: Translation.tr("Copy")
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                        }
                        RippleButton {
                            Layout.fillWidth: true
                            implicitHeight: 40
                            buttonRadius: height / 2
                            colBackground: Appearance.colors.colLayer1
                            colBackgroundHover: Appearance.colors.colLayer1Hover
                            onClicked: DropShelf.clear()
                            contentItem: StyledText {
                                horizontalAlignment: Text.AlignHCenter
                                text: Translation.tr("Clear")
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                        RippleButton {
                            Layout.fillWidth: true
                            implicitHeight: 40
                            buttonRadius: height / 2
                            colBackground: Appearance.colors.colLayer1
                            colBackgroundHover: Appearance.colors.colLayer1Hover
                            onClicked: DropShelf.hide()
                            contentItem: StyledText {
                                horizontalAlignment: Text.AlignHCenter
                                text: Translation.tr("Close")
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }
            }
        }
    }
}

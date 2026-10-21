pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import Quickshell

Item {
    id: root

    signal closeRequested

    readonly property var items: DropShelf.items
    readonly property var screen: QsWindow.window?.screen ?? null

    implicitHeight: 96 + 12 + 30

    function openShelf() {
        const screen = root.screen ?? Quickshell.screens[0];
        root.closeRequested();
        if (!screen)
            return;
        DropShelf.show([], screen, screen.width / 2, screen.height / 2);
    }

    component SmallButton: NabyIslandButton {
        id: smallButton
        property string iconName: ""
        property string label: ""
        width: smallRow.implicitWidth + 20
        height: 30
        radius: 11
        colNormal: Qt.rgba(1, 1, 1, 0.08)
        colHover: Qt.rgba(1, 1, 1, 0.16)

        Row {
            id: smallRow
            anchors.centerIn: parent
            spacing: 5

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: smallButton.iconName
                iconSize: 16
                color: "#ffffff"
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: smallButton.label
                color: "#ffffff"
                font.pixelSize: 12
            }
        }
    }

    Rectangle {
        id: dropZone
        width: parent.width
        height: 96
        radius: 16
        color: dropArea.containsDrag ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
        border.width: 1
        border.color: dropArea.containsDrag ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(1, 1, 1, 0.12)

        DropArea {
            id: dropArea
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

        Column {
            anchors.centerIn: parent
            visible: root.items.length === 0
            spacing: 4

            MaterialSymbol {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "folder"
                iconSize: 26
                color: "#ffffff"
                opacity: 0.6
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Translation.tr("Drop files here")
                color: "#ffffff"
                opacity: 0.55
                font.pixelSize: 12
            }
        }

        ListView {
            id: shelfList
            visible: root.items.length > 0
            anchors.fill: parent
            anchors.margins: 8
            orientation: ListView.Horizontal
            spacing: 6
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.items

            delegate: Item {
                id: shelfItem
                required property string modelData
                readonly property bool isImage: /\.(png|jpe?g|webp|bmp|gif)$/i.test(shelfItem.modelData)
                readonly property string fileName: shelfItem.modelData.split(/[\\/]/).pop()
                readonly property string fileUrl: FileUtils.folderUrl(shelfItem.modelData)
                width: 80
                height: shelfList.height

                Rectangle {
                    id: tile
                    width: shelfItem.width
                    height: shelfItem.height
                    radius: 12
                    color: tileMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.07)
                    clip: true

                    Drag.active: tileMouse.drag.active
                    Drag.dragType: Drag.Automatic
                    Drag.supportedActions: Qt.CopyAction
                    Drag.mimeData: ({
                            "text/uri-list": shelfItem.fileUrl
                        })

                    StyledImage {
                        anchors.fill: parent
                        visible: shelfItem.isImage
                        source: shelfItem.isImage ? shelfItem.fileUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 160
                        sourceSize.height: 160
                        asynchronous: true
                        cache: false
                    }

                    MaterialSymbol {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 10
                        visible: !shelfItem.isImage
                        text: "draft"
                        iconSize: 28
                        color: "#ffffff"
                        opacity: 0.8
                    }

                    StyledText {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 10
                        visible: !shelfItem.isImage
                        horizontalAlignment: Text.AlignHCenter
                        text: shelfItem.fileName
                        color: "#ffffff"
                        font.pixelSize: 10
                        elide: Text.ElideMiddle
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                    }

                    MouseArea {
                        id: tileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        drag.target: tile
                        cursorShape: Qt.OpenHandCursor
                        onReleased: {
                            if (tile.Drag.active)
                                tile.Drag.drop();
                            tile.x = 0;
                            tile.y = 0;
                        }
                    }

                    NabyIslandButton {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 4
                        visible: tileMouse.containsMouse || hovered
                        width: 20
                        height: 20
                        colNormal: Qt.rgba(0, 0, 0, 0.6)
                        colHover: Qt.rgba(0, 0, 0, 0.85)
                        onClicked: DropShelf.removeItem(shelfItem.modelData)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 14
                            color: "#ffffff"
                        }
                    }
                }
            }
        }
    }

    Row {
        anchors.top: dropZone.bottom
        anchors.topMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6

        SmallButton {
            iconName: "open_in_new"
            label: Translation.tr("Open shelf")
            onClicked: root.openShelf()
        }

        SmallButton {
            iconName: "content_copy"
            label: Translation.tr("Copy")
            enabled: root.items.length > 0
            onClicked: DropShelf.copyAll()
        }

        SmallButton {
            iconName: "clear_all"
            label: Translation.tr("Clear")
            enabled: root.items.length > 0
            onClicked: DropShelf.clear()
        }
    }
}

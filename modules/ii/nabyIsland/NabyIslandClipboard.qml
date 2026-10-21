pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick

Item {
    id: root

    readonly property int maxEntries: 30
    readonly property var entries: Cliphist.entries.slice(0, root.maxEntries)
    property string copiedEntry: ""

    implicitHeight: root.entries.length > 0 ? Math.min(6, root.entries.length) * 38 + 34 : 120

    Component.onCompleted: Cliphist.refresh()

    function preview(entry) {
        if (Cliphist.entryIsImage(entry)) {
            const size = entry.match(/(\d+)x(\d+)/);
            return size ? Translation.tr("Image · %1×%2").arg(size[1]).arg(size[2]) : Translation.tr("Image");
        }
        return StringUtils.cleanCliphistEntry(entry).replace(/\s+/g, " ").trim();
    }

    function copy(entry) {
        Cliphist.copy(entry);
        root.copiedEntry = entry;
        copiedTimer.restart();
    }

    Timer {
        id: copiedTimer
        interval: 1200
        onTriggered: root.copiedEntry = ""
    }

    StyledText {
        id: hint
        x: 0
        y: 0
        visible: root.entries.length > 0
        text: Translation.tr("Click an entry to copy it")
        color: "#ffffff"
        opacity: 0.5
        font.pixelSize: 12
    }

    Column {
        anchors.centerIn: parent
        visible: root.entries.length === 0
        spacing: 6

        MaterialSymbol {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "content_paste"
            iconSize: 30
            color: "#ffffff"
            opacity: 0.6
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Translation.tr("Clipboard history is empty")
            color: "#ffffff"
            opacity: 0.55
            font.pixelSize: 13
        }
    }

    ListView {
        id: list
        visible: root.entries.length > 0
        anchors.top: hint.bottom
        anchors.topMargin: 8
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        spacing: 4
        boundsBehavior: Flickable.StopAtBounds
        model: root.entries

        delegate: NabyIslandButton {
            id: entryRow
            required property string modelData
            readonly property bool isImage: Cliphist.entryIsImage(entryRow.modelData)
            readonly property bool copied: root.copiedEntry === entryRow.modelData
            width: list.width
            height: 34
            radius: 11
            colNormal: Qt.rgba(1, 1, 1, 0.06)
            colHover: Qt.rgba(1, 1, 1, 0.12)
            onClicked: root.copy(entryRow.modelData)

            MaterialSymbol {
                id: entryIcon
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: entryRow.copied ? "check" : entryRow.isImage ? "image" : "notes"
                iconSize: 17
                color: "#ffffff"
                opacity: 0.7
            }

            StyledText {
                anchors.left: entryIcon.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: entryRow.copied ? Translation.tr("Copied") : root.preview(entryRow.modelData)
                color: "#ffffff"
                font.pixelSize: 12
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                maximumLineCount: 1
                textFormat: Text.PlainText
            }
        }
    }
}

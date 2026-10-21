pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string editingId: ""
    property bool editing: false
    property string draft: ""
    property bool loadingDraft: false
    readonly property var notes: [...Notes.list].reverse()

    implicitHeight: root.editing ? 262 : Math.max(120, Math.min(5, root.notes.length) * 40 + 46)

    function firstLine(text) {
        const line = (text ?? "").split("\n").find(l => l.trim().length > 0) ?? "";
        return line.trim();
    }

    function startNew() {
        root.editingId = "";
        root.draft = "";
        root.editing = true;
    }

    function startEdit(note) {
        root.editingId = note.id;
        root.draft = note.content ?? "";
        root.editing = true;
    }

    function save() {
        saveTimer.stop();
        if (!root.editing)
            return;
        if (root.editingId.length > 0)
            Notes.updateNote(root.editingId, root.draft);
        else if (root.draft.trim().length > 0)
            root.editingId = Notes.addNote(root.draft);
    }

    function finish() {
        root.save();
        if (root.editingId.length > 0 && root.draft.trim().length === 0)
            Notes.deleteNote(root.editingId);
        root.editing = false;
        root.editingId = "";
    }

    function removeCurrent() {
        saveTimer.stop();
        if (root.editingId.length > 0)
            Notes.deleteNote(root.editingId);
        root.editing = false;
        root.editingId = "";
    }

    Component.onDestruction: root.save()

    Timer {
        id: saveTimer
        interval: 600
        onTriggered: root.save()
    }

    component SmallButton: NabyIslandButton {
        id: smallButton
        property string iconName: ""
        property string label: ""
        width: smallRow.implicitWidth + 20
        height: 28
        radius: 10
        colNormal: Qt.rgba(1, 1, 1, 0.08)
        colHover: Qt.rgba(1, 1, 1, 0.16)

        Row {
            id: smallRow
            anchors.centerIn: parent
            spacing: 4

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                visible: smallButton.iconName.length > 0
                text: smallButton.iconName
                iconSize: 16
                color: "#ffffff"
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: smallButton.label.length > 0
                text: smallButton.label
                color: "#ffffff"
                font.pixelSize: 12
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: !root.editing

        StyledText {
            id: listTitle
            x: 0
            anchors.verticalCenter: newButton.verticalCenter
            text: root.notes.length > 0 ? Translation.tr("%1 notes").arg(root.notes.length) : Translation.tr("Notes")
            color: "#ffffff"
            opacity: 0.6
            font.pixelSize: 12
        }

        SmallButton {
            id: newButton
            anchors.right: parent.right
            y: 0
            iconName: "add"
            label: Translation.tr("New note")
            onClicked: root.startNew()
        }

        StyledText {
            visible: root.notes.length === 0
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: newButton.bottom
            anchors.topMargin: 28
            text: Translation.tr("No notes yet")
            color: "#ffffff"
            opacity: 0.45
            font.pixelSize: 13
        }

        ListView {
            id: notesList
            visible: root.notes.length > 0
            anchors.top: newButton.bottom
            anchors.topMargin: 10
            anchors.bottom: parent.bottom
            width: parent.width
            clip: true
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds
            model: root.notes

            delegate: NabyIslandButton {
                id: noteRow
                required property var modelData
                width: notesList.width
                height: 36
                radius: 12
                colNormal: Qt.rgba(1, 1, 1, 0.06)
                colHover: Qt.rgba(1, 1, 1, 0.12)
                onClicked: root.startEdit(noteRow.modelData)

                MaterialSymbol {
                    id: noteIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "description"
                    iconSize: 18
                    color: "#ffffff"
                    opacity: 0.7
                }

                StyledText {
                    anchors.left: noteIcon.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.firstLine(noteRow.modelData.content) || Translation.tr("Untitled")
                    color: "#ffffff"
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: root.editing

        Rectangle {
            id: editorBackground
            x: 0
            y: 0
            width: parent.width
            height: parent.height - 38
            radius: 14
            color: Qt.rgba(1, 1, 1, 0.06)
            border.width: editor.activeFocus ? 1 : 0
            border.color: Qt.rgba(1, 1, 1, 0.25)

            Flickable {
                id: editorFlick
                anchors.fill: parent
                anchors.margins: 4
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                TextArea.flickable: StyledTextArea {
                    id: editor
                    placeholderText: Translation.tr("Write something…")
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.35)
                    color: "#ffffff"
                    selectionColor: Qt.rgba(1, 1, 1, 0.3)
                    selectedTextColor: "#ffffff"
                    wrapMode: TextEdit.Wrap
                    background: null
                    font.pixelSize: 13
                    onTextChanged: {
                        if (root.loadingDraft || editor.text === root.draft)
                            return;
                        root.draft = editor.text;
                        saveTimer.restart();
                    }
                }
            }
        }

        SmallButton {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            iconName: "delete"
            label: Translation.tr("Delete")
            visible: root.editingId.length > 0
            onClicked: root.removeCurrent()
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: doneButton.verticalCenter
            text: saveTimer.running ? Translation.tr("Saving...") : root.editingId.length > 0 ? Translation.tr("Saved") : ""
            color: "#ffffff"
            opacity: 0.4
            font.pixelSize: 11
        }

        SmallButton {
            id: doneButton
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            iconName: "check"
            label: Translation.tr("Done")
            onClicked: root.finish()
        }
    }

    onEditingChanged: {
        if (!root.editing)
            return;
        root.loadingDraft = true;
        editor.text = root.draft;
        root.loadingDraft = false;
        Qt.callLater(() => {
            editor.forceActiveFocus();
            editor.cursorPosition = editor.length;
        });
    }
}

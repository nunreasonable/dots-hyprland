import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

DashboardCard {
    id: root

    property var control: null
    property string title: ""
    property string icon: "edit"
    property var tileShape: MaterialShape.Shape.Slanted
    property string placeholder: ""

    readonly property bool isList: control?.list === true
    readonly property string current: control ? (root.isList ? (control.get() ?? []).join(", ") : String(control.get() ?? "")) : ""

    tint: Appearance.colors.colSecondaryContainer

    function commit(value) {
        if (!root.control) return;
        if (root.isList) {
            root.control.set(value.split(",").map(s => s.trim()).filter(s => s.length > 0));
        } else {
            root.control.set(value);
        }
    }

    onCurrentChanged: {
        if (!field.activeFocus) field.text = current;
    }
    Component.onCompleted: field.text = current

    Timer {
        id: debounce
        interval: 600
        onTriggered: {
            if (root.control && field.text !== root.current) root.commit(field.text);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            MaterialShapeWrappedMaterialSymbol {
                shape: root.tileShape
                text: root.icon
                iconSize: 22
                fill: 1
                padding: 9
                color: Appearance.colors.colSecondary
                colSymbol: Appearance.colors.colOnSecondary
            }

            StyledText {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnSecondaryContainer
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            MaterialSymbol {
                text: field.activeFocus ? "check" : "edit"
                iconSize: 22
                fill: 1
                color: Appearance.colors.colPrimary

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (field.activeFocus) {
                            field.focus = false;
                            root.pager.forceActiveFocus();
                        } else {
                            field.forceActiveFocus();
                            field.selectAll();
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 40
            radius: 20
            color: Qt.rgba(1, 1, 1, 0.12)
            border.width: field.activeFocus ? 2 : 0
            border.color: Appearance.colors.colSecondary

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                onClicked: field.forceActiveFocus()
            }

            TextInput {
                id: field
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                font.pixelSize: Appearance.font.pixelSize.small
                font.family: Appearance.font.family.main
                color: Appearance.colors.colOnSecondaryContainer
                selectionColor: Appearance.colors.colSecondary
                echoMode: root.control?.secret ? TextInput.Password : TextInput.Normal
                onTextEdited: {
                    if (!root.control?.secret)
                        debounce.restart();
                }
                onEditingFinished: {
                    debounce.stop();
                    if (root.control && text !== root.current) root.commit(text);
                }
                Keys.onEscapePressed: {
                    field.text = root.current;
                    field.focus = false;
                    root.pager.forceActiveFocus();
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: field.text === "" && !field.activeFocus && root.placeholder !== ""
                    text: root.placeholder
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnSecondaryContainer
                    opacity: 0.5
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets as W
import qs.modules.common.functions
import qs.modules.settingsPc.widgets

Flickable {
    id: root
    clip: true
    contentWidth: width
    contentHeight: mainLayout.implicitHeight + 32
    boundsBehavior: Flickable.StopAtBounds

    property bool importDropHover: false

    FileView {
        id: importReadFile
        property string suggestedName: ""
        printErrors: false
        onLoaded: Presets.importJsonText(importReadFile.text(), importReadFile.suggestedName)
    }

    ColumnLayout {
        id: mainLayout
        x: 16
        y: 16
        width: root.width - 32
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ConfigTextArea {
                id: presetNameField
                Layout.fillWidth: true
                buttonIcon: "newsmode"
                text: Translation.tr("Save as")
                placeholderText: Translation.tr("Name, description (optional)")
                confirmButtonVisible: presetNameField.value.trim() !== ""
                confirmButtonIcon: "save"
                onConfirmClicked: {
                    Presets.save(presetNameField.value);
                    presetNameField.value = "";
                }
            }

            W.RippleButtonWithIcon {
                materialIcon: "folder_open"
                mainText: Translation.tr("Open folder")
                colBackground: Appearance.colors.colSecondaryContainer
                colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                colRipple: Appearance.colors.colSecondaryContainerActive
                onClicked: Presets.openPresetsFolder()
            }
        }

        Rectangle {
            id: importDropTarget
            Layout.fillWidth: true
            implicitHeight: 48
            radius: Appearance.rounding.normal
            color: root.importDropHover ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colLayer1
            border.width: root.importDropHover ? 2 : 0
            border.color: Appearance.colors.colPrimary

            RowLayout {
                anchors.centerIn: parent
                spacing: 8
                W.MaterialSymbol {
                    text: "upload_file"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnLayer1
                }
                W.StyledText {
                    text: Translation.tr("Drop a preset .json file here to import it")
                    color: Appearance.colors.colOnLayer1
                }
            }

            DropArea {
                anchors.fill: parent
                keys: ["text/uri-list"]
                onEntered: drag => {
                    drag.accept(Qt.CopyAction);
                    root.importDropHover = true;
                }
                onExited: root.importDropHover = false
                onDropped: drop => {
                    root.importDropHover = false;
                    if (!drop.hasUrls || drop.urls.length === 0)
                        return;
                    const cleanPath = FileUtils.trimFileProtocol(drop.urls[0]);
                    if (!cleanPath.toLowerCase().endsWith(".json"))
                        return;
                    const base = cleanPath.split("/").pop().replace(/\.json$/i, "");
                    importReadFile.suggestedName = base;
                    importReadFile.path = cleanPath;
                    importReadFile.reload();
                }
            }
        }

        W.StyledText {
            Layout.fillWidth: true
            visible: Presets.lastSkippedKeys.length > 0
            wrapMode: Text.Wrap
            text: Translation.tr("Kept your current value for: %1").arg(Presets.lastSkippedKeys.join(", "))
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            W.StyledText {
                text: Translation.tr("My presets")
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer0
            }

            W.StyledText {
                visible: Presets.folderModel.count === 0
                text: Translation.tr("No presets yet")
                color: Appearance.colors.colSubtext
            }

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: 12

                Repeater {
                    model: Presets.folderModel
                    delegate: W.PresetsCard {
                        id: presetDelegate
                        required property string fileName
                        required property string filePath
                        property string presetName: fileName.replace(".json", "")
                        property string presetWallpaper: ""
                        property string presetDescription: ""

                        FileView {
                            path: presetDelegate.filePath
                            printErrors: false
                            onLoaded: {
                                try {
                                    const data = JSON.parse(text());
                                    presetDelegate.presetWallpaper = Presets.previewImage(data);
                                    presetDelegate.presetDescription = data?._presetMeta?.description ?? "";
                                } catch (e) {}
                            }
                        }

                        imageSource: presetDelegate.presetWallpaper
                        title: presetDelegate.presetName
                        description: presetDelegate.presetDescription !== "" ? presetDelegate.presetDescription : Translation.tr("Saved preset")
                        onApply: () => Presets.apply(presetDelegate.presetName)
                        onRemove: () => Presets.remove(presetDelegate.presetName)
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: Presets.onlineFolderModel.count > 0

            W.StyledText {
                text: Translation.tr("Downloaded")
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer0
            }

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: 12

                Repeater {
                    model: Presets.onlineFolderModel
                    delegate: W.PresetsCard {
                        id: onlineDelegate
                        required property string fileName
                        required property string filePath
                        property string presetName: fileName.replace(".json", "")
                        property string presetWallpaper: ""
                        property string presetDescription: ""

                        FileView {
                            path: onlineDelegate.filePath
                            printErrors: false
                            onLoaded: {
                                try {
                                    const data = JSON.parse(text());
                                    onlineDelegate.presetWallpaper = Presets.previewImage(data);
                                    onlineDelegate.presetDescription = data?._presetMeta?.description ?? "";
                                } catch (e) {}
                            }
                        }

                        imageSource: onlineDelegate.presetWallpaper
                        title: onlineDelegate.presetName
                        description: onlineDelegate.presetDescription !== "" ? onlineDelegate.presetDescription : Translation.tr("Downloaded preset")
                        onApply: () => Presets.applyOnline(onlineDelegate.presetName)
                        onRemove: () => Presets.removeOnline(onlineDelegate.presetName)
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: Config.options.profile.onlinePresets

            RowLayout {
                Layout.fillWidth: true
                W.StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Browse Online")
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer0
                }
                W.RippleButtonWithIcon {
                    materialIcon: "refresh"
                    mainText: PresetsOnline.loading ? Translation.tr("Loading…") : Translation.tr("Refresh")
                    enabled: !PresetsOnline.loading
                    colBackground: Appearance.colors.colSecondaryContainer
                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                    colRipple: Appearance.colors.colSecondaryContainerActive
                    onClicked: PresetsOnline.refresh()
                }
            }

            W.StyledText {
                text: PresetsOnline.error !== "" ? PresetsOnline.error : Translation.tr("%1 presets available").arg(PresetsOnline.pending.length)
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
            }

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: 12

                Repeater {
                    model: PresetsOnline.pending
                    delegate: Rectangle {
                        id: onlineCard
                        required property var modelData
                        implicitWidth: 240
                        implicitHeight: 170
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer1

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 110
                                color: Appearance.colors.colLayer2
                                clip: true
                                W.StyledImage {
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    source: onlineCard.modelData.screenshot
                                    cache: true
                                    sourceSize.width: 400
                                    sourceSize.height: 220
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.margins: 8
                                spacing: 6
                                W.StyledText {
                                    Layout.fillWidth: true
                                    text: onlineCard.modelData.title
                                    elide: Text.ElideRight
                                    color: Appearance.colors.colOnLayer1
                                }
                                W.RippleButton {
                                    implicitWidth: 30
                                    implicitHeight: 30
                                    buttonRadius: Appearance.rounding.full
                                    colBackground: Appearance.colors.colPrimary
                                    colBackgroundHover: Appearance.colors.colPrimaryHover
                                    enabled: PresetsOnline.downloadingName === ""
                                    onClicked: PresetsOnline.download(onlineCard.modelData)
                                    contentItem: W.MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: PresetsOnline.downloadingName === onlineCard.modelData.name ? "hourglass_top" : "download"
                                        iconSize: Appearance.font.pixelSize.normal
                                        color: Appearance.colors.colOnPrimary
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

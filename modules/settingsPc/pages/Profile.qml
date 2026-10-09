import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets as W
import qs.modules.common.functions
import qs.modules.settingsPc.widgets

ContentPage {
    id: page
    forceWidth: true

    property string descriptionMode: Config.options.profile.descriptionText === "::uptime::" ? "uptime" : "distro"
    property bool avatarDropHover: false
    property bool importDropHover: false

    Component.onCompleted: {
        if (Config.options.profile.onlinePresets)
            PresetsOnline.refresh();
    }

    FileView {
        id: importReadFile
        property string suggestedName: ""
        printErrors: false
        onLoaded: {
            Presets.importJsonText(importReadFile.text(), importReadFile.suggestedName);
        }
    }

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            icon: "person"
            shape: W.MaterialShape.Shape.Circle
            title: Translation.tr("Avatar")

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Rectangle {
                    id: avatarDropTarget
                    implicitWidth: 72
                    implicitHeight: 72
                    radius: width / 2
                    color: page.avatarDropHover ? Appearance.colors.colPrimaryContainerHover : "transparent"
                    border.width: page.avatarDropHover ? 2 : 0
                    border.color: Appearance.colors.colPrimary

                    UserAvatar {
                        anchors.fill: parent
                        anchors.margins: 4
                    }

                    W.MaterialSymbol {
                        anchors.centerIn: parent
                        visible: page.avatarDropHover
                        text: "download"
                        iconSize: 24
                        color: Appearance.colors.colPrimary
                    }

                    DropArea {
                        anchors.fill: parent
                        keys: ["text/uri-list"]
                        onEntered: drag => {
                            drag.accept(Qt.CopyAction);
                            page.avatarDropHover = true;
                        }
                        onExited: page.avatarDropHover = false
                        onDropped: drop => {
                            page.avatarDropHover = false;
                            if (!drop.hasUrls || drop.urls.length === 0)
                                return;
                            const cleanPath = FileUtils.trimFileProtocol(drop.urls[0]);
                            const ext = cleanPath.split(".").pop().toLowerCase();
                            if (["png", "jpg", "jpeg", "webp", "bmp"].indexOf(ext) === -1)
                                return;
                            Config.options.profile.avatarPicture = cleanPath;
                            Config.options.profile.avatarPath = cleanPath.substring(0, cleanPath.lastIndexOf("/"));
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    W.StyledText {
                        text: Translation.tr("Drag an image here to use it as your avatar")
                        color: Appearance.colors.colOnLayer0
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    W.RippleButtonWithIcon {
                        visible: Config.options.profile.avatarPicture !== ""
                        Layout.alignment: Qt.AlignLeft
                        materialIcon: "restart_alt"
                        mainText: Translation.tr("Use Windows account picture")
                        colBackground: Appearance.colors.colSecondaryContainer
                        colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                        colRipple: Appearance.colors.colSecondaryContainerActive
                        onClicked: {
                            Config.options.profile.avatarPicture = "";
                            Config.options.profile.avatarPath = "";
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Identity")

                GroupedList {
                    ConfigTextArea {
                        id: displayNameField
                        Layout.fillWidth: true
                        buttonIcon: "badge"
                        text: Translation.tr("Display name")
                        placeholderText: SystemInfo.username
                        value: Config.options.profile.displayName

                        Timer {
                            id: displayNameDebounceTimer
                            interval: 800
                            onTriggered: Config.options.profile.displayName = displayNameField.value
                        }
                        onValueChanged: displayNameDebounceTimer.restart()
                    }

                    ConfigSelectionArray {
                        text: Translation.tr("Description text")
                        icon: "subtitles"
                        currentValue: page.descriptionMode
                        onSelected: newValue => {
                            page.descriptionMode = newValue;
                            Config.options.profile.descriptionText = newValue === "uptime" ? "::uptime::" : "::distro::";
                        }
                        options: [
                            { displayName: Translation.tr("Distro"), icon: "deployed_code", value: "distro" },
                            { displayName: Translation.tr("Uptime"), icon: "timelapse", value: "uptime" }
                        ]
                    }
                }
            }
        }

        ContentSection {
            icon: "wall_art"
            shape: W.MaterialShape.Shape.Pentagon
            title: Translation.tr("Presets")

            GroupedList {
                ConfigTextArea {
                    id: presetNameField
                    Layout.fillWidth: true
                    fieldWidth: 300
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

                ConfigSwitch {
                    buttonIcon: "cloud_download"
                    text: Translation.tr("Show online presets")
                    checked: Config.options.profile.onlinePresets
                    onCheckedChanged: {
                        Config.options.profile.onlinePresets = checked;
                        if (checked)
                            PresetsOnline.refresh();
                    }
                }

                W.RippleButtonWithIcon {
                    Layout.fillWidth: true
                    materialIcon: "folder_open"
                    mainText: Translation.tr("Open presets folder")
                    colBackground: Appearance.colors.colSecondaryContainer
                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                    colRipple: Appearance.colors.colSecondaryContainerActive
                    onClicked: Presets.openPresetsFolder()
                }
            }

            Rectangle {
                id: importDropTarget
                Layout.fillWidth: true
                Layout.topMargin: 6
                implicitHeight: 52
                radius: Appearance.rounding.normal
                color: page.importDropHover ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colLayer1
                border.width: page.importDropHover ? 2 : 0
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
                        page.importDropHover = true;
                    }
                    onExited: page.importDropHover = false
                    onDropped: drop => {
                        page.importDropHover = false;
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
                Layout.topMargin: 10
                visible: Presets.lastSkippedKeys.length > 0
                wrapMode: Text.Wrap
                text: Translation.tr("Kept your current value for: %1").arg(Presets.lastSkippedKeys.join(", "))
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
            }

            W.StyledText {
                Layout.fillWidth: true
                Layout.topMargin: 20
                visible: Presets.folderModel.count === 0
                horizontalAlignment: Text.AlignHCenter
                text: Translation.tr("No presets yet")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.normal
            }

            Flow {
                Layout.topMargin: 10
                Layout.fillWidth: true
                width: parent.width
                spacing: 12
                visible: Presets.folderModel.count > 0

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

            ContentSubsection {
                title: Translation.tr("Downloaded")
                visible: Presets.onlineFolderModel.count > 0

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
        }

        ContentSection {
            icon: "link"
            shape: W.MaterialShape.Shape.Bun
            title: Translation.tr("Browse Online")
            visible: Config.options.profile.onlinePresets

            GroupedList {
                W.RippleButtonWithIcon {
                    Layout.fillWidth: true
                    materialIcon: "refresh"
                    mainText: PresetsOnline.loading ? Translation.tr("Loading…") : Translation.tr("Refresh")
                    enabled: !PresetsOnline.loading
                    colBackground: Appearance.colors.colSecondaryContainer
                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                    colRipple: Appearance.colors.colSecondaryContainerActive
                    onClicked: PresetsOnline.refresh()
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6
                    W.MaterialSymbol {
                        text: PresetsOnline.error !== "" ? "error" : "wallpaper"
                        iconSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                    W.StyledText {
                        text: PresetsOnline.error !== "" ? PresetsOnline.error : Translation.tr("%1 presets available").arg(PresetsOnline.pending.length)
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                }
            }

            Flow {
                Layout.topMargin: 10
                Layout.fillWidth: true
                width: parent.width
                spacing: 12
                visible: PresetsOnline.pending.length > 0

                Repeater {
                    model: PresetsOnline.pending
                    delegate: Rectangle {
                        id: onlineCard
                        required property var modelData
                        implicitWidth: 260
                        implicitHeight: 190
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer1

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 120
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
                                Layout.margins: 10
                                spacing: 8

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    W.StyledText {
                                        Layout.fillWidth: true
                                        text: onlineCard.modelData.title
                                        elide: Text.ElideRight
                                        color: Appearance.colors.colOnLayer1
                                    }
                                    W.PresetAuthorChip {
                                        author: onlineCard.modelData.author ?? ""
                                        textColor: Appearance.colors.colSubtext
                                    }
                                }

                                W.RippleButton {
                                    implicitWidth: 32
                                    implicitHeight: 32
                                    buttonRadius: Appearance.rounding.full
                                    colBackground: Appearance.colors.colPrimary
                                    colBackgroundHover: Appearance.colors.colPrimaryHover
                                    colRipple: Appearance.colors.colPrimaryActive
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

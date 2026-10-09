pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "images"

    property list<var> formatOptions: [
        {
            displayName: "PNG",
            icon: "image",
            value: "png"
        },
        {
            displayName: "JPG",
            icon: "photo",
            value: "jpg"
        },
        {
            displayName: "WEBP",
            icon: "motion_photos_on",
            value: "webp"
        },
        {
            displayName: "AVIF",
            icon: "hd",
            value: "avif"
        },
        {
            displayName: "BMP",
            icon: "grid_on",
            value: "bmp"
        },
        {
            displayName: "TIFF",
            icon: "photo_library",
            value: "tiff"
        },
        {
            displayName: "PDF",
            icon: "picture_as_pdf",
            value: "pdf"
        },
    ]

    property string selectedFormat: "webp"
    property string dropStatus: "idle"
    property string statusMessage: ""

    readonly property var acceptedExtensions: ["png", "jpg", "jpeg", "webp", "avif", "bmp", "gif", "tiff", "tif"]

    property var fileQueue: []
    property int queueTotal: 0
    property int queueDone: 0
    property var batchPaths: []

    property bool ffmpegAvailable: !Platform.isWindows
    property bool magickAvailable: !Platform.isWindows

    Component.onCompleted: {
        if (!Platform.isWindows)
            return;
        ffmpegProbe.running = true;
        magickProbe.running = true;
    }

    Process {
        id: ffmpegProbe
        command: ["cmd", "/c", "where", "ffmpeg"]
        onExited: exitCode => root.ffmpegAvailable = exitCode === 0
    }
    Process {
        id: magickProbe
        command: ["cmd", "/c", "where", "magick"]
        onExited: exitCode => root.magickAvailable = exitCode === 0
    }

    implicitWidth: 276
    implicitHeight: 252

    Process {
        id: converter
        property string inputPath: ""
        property string outputPath: ""
        command: ["ffmpeg", "-y", "-i", inputPath, outputPath]
        onExited: exitCode => {
            root.queueDone++;
            if (exitCode !== 0) {
                root.dropStatus = "error";
                root.statusMessage = Translation.tr("Failed: %1").arg(inputPath.replace(/.*\//, ""));
                root.fileQueue = [];
                root.queueTotal = 0;
                root.queueDone = 0;
                resetTimer.start();
                return;
            }
            if (root.fileQueue.length > 0) {
                root.statusMessage = Translation.tr("Converting %1 / %2...").arg(root.queueDone).arg(root.queueTotal);
                processNext();
            } else {
                root.dropStatus = "done";
                root.statusMessage = root.queueTotal === 1 ? Translation.tr("Saved: %1").arg(outputPath.replace(/.*\//, "")) : Translation.tr("%1 files converted").arg(root.queueTotal);
                root.queueTotal = 0;
                root.queueDone = 0;
                resetTimer.start();
            }
        }
    }

    Process {
        id: pdfMaker
        property string outputPath: ""
        onExited: exitCode => {
            if (exitCode === 0) {
                root.dropStatus = "done";
                root.statusMessage = root.batchPaths.length === 1 ? Translation.tr("Saved: %1").arg(outputPath.replace(/.*\//, "")) : Translation.tr("%1 pages → %2").arg(root.batchPaths.length).arg(outputPath.replace(/.*\//, ""));
            } else {
                root.dropStatus = "error";
                root.statusMessage = Translation.tr("PDF failed.\nIs ImageMagick installed?");
            }
            root.batchPaths = [];
            resetTimer.start();
        }
    }

    Timer {
        id: resetTimer
        interval: 3500
        repeat: false
        onTriggered: root.dropStatus = "idle"
    }

    function processNext() {
        const next = root.fileQueue[0];
        root.fileQueue = root.fileQueue.slice(1);
        converter.inputPath = next;
        converter.outputPath = next.replace(/\.[^/.]+$/, "") + "_converted." + root.selectedFormat;
        converter.running = true;
    }

    function enqueueFiles(urls) {
        if (!root.ffmpegAvailable && root.selectedFormat !== "pdf") {
            root.dropStatus = "error";
            root.statusMessage = Translation.tr("ffmpeg not found on PATH.");
            resetTimer.start();
            return;
        }
        if (!root.magickAvailable && root.selectedFormat === "pdf") {
            root.dropStatus = "error";
            root.statusMessage = Translation.tr("ImageMagick (magick) not found on PATH.");
            resetTimer.start();
            return;
        }

        const valid = [];
        for (let i = 0; i < urls.length; i++) {
            const cleanPath = urls[i].toString().replace(/^file:\/\//, "");
            const ext = cleanPath.split(".").pop().toLowerCase();
            if (root.acceptedExtensions.indexOf(ext) !== -1)
                valid.push(cleanPath);
        }
        if (valid.length === 0) {
            root.dropStatus = "error";
            root.statusMessage = Translation.tr("No supported files dropped.");
            resetTimer.start();
            return;
        }

        root.dropStatus = "converting";

        if (root.selectedFormat === "pdf") {
            root.batchPaths = valid;
            root.statusMessage = valid.length === 1 ? Translation.tr("Converting to PDF...") : Translation.tr("Merging %1 images into PDF...").arg(valid.length);
            const outPdf = valid[0].replace(/\.[^/.]+$/, "") + (valid.length > 1 ? "_merged" : "_converted") + ".pdf";
            pdfMaker.outputPath = outPdf;
            pdfMaker.command = ["magick"].concat(valid).concat([outPdf]);
            pdfMaker.running = true;
            return;
        }

        root.fileQueue = valid.slice(1);
        root.queueTotal = valid.length;
        root.queueDone = 0;
        root.statusMessage = valid.length > 1 ? Translation.tr("Converting 0 / %1...").arg(valid.length) : Translation.tr("Converting...");
        converter.inputPath = valid[0];
        converter.outputPath = valid[0].replace(/\.[^/.]+$/, "") + "_converted." + root.selectedFormat;
        converter.running = true;
    }

    WidgetCard {
        id: contentItem
        widget: root
        implicitWidth: 276
        implicitHeight: 252

        ColumnLayout {
            id: columnLayout
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 16
            }
            spacing: 12

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnPrimaryContainer
                opacity: 0.4
                text: "PNG · JPG · WEBP · AVIF · BMP · PDF · TIFF"
            }

            Rectangle {
                id: dropZone
                Layout.fillWidth: true
                implicitHeight: 144
                radius: Appearance.rounding.large
                color: {
                    switch (root.dropStatus) {
                    case "hover":
                        return Appearance.colors.colPrimaryContainer;
                    case "converting":
                        return Appearance.colors.colSecondaryContainer;
                    case "done":
                        return Appearance.colors.colTertiaryContainer;
                    case "error":
                        return Qt.rgba(Appearance.colors.colError.r, Appearance.colors.colError.g, Appearance.colors.colError.b, 0.15);
                    default:
                        return ColorUtils.transparentize(Appearance.colors.colLayer0, 0.8);
                    }
                }
                border.color: {
                    switch (root.dropStatus) {
                    case "hover":
                        return Appearance.colors.colPrimary;
                    case "converting":
                        return Appearance.colors.colSecondary;
                    case "done":
                        return Appearance.colors.colTertiary;
                    case "error":
                        return Appearance.colors.colError;
                    default:
                        return Appearance.colors.colOnPrimaryContainer;
                    }
                }
                border.width: root.dropStatus === "hover" ? 2 : 1

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
                Behavior on border.color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }

                MaterialLoadingIndicator {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -14
                    visible: root.dropStatus === "converting"
                    loading: root.dropStatus === "converting"
                    colBg: Appearance.colors.colPrimary
                    colShape: Appearance.colors.colOnPrimary
                    implicitSize: 48
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -14
                    visible: root.dropStatus !== "converting"
                    iconSize: 32
                    fill: root.dropStatus === "done" ? 1 : 0
                    color: {
                        switch (root.dropStatus) {
                        case "hover":
                            return Appearance.colors.colPrimary;
                        case "done":
                            return Appearance.colors.colTertiary;
                        case "error":
                            return Appearance.colors.colError;
                        default:
                            return Appearance.colors.colOnLayer1;
                        }
                    }
                    text: {
                        switch (root.dropStatus) {
                        case "hover":
                            return "download";
                        case "done":
                            return "check_circle";
                        case "error":
                            return "error";
                        default:
                            return root.selectedFormat === "pdf" ? "picture_as_pdf" : "image";
                        }
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 22
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Appearance.font.pixelSize.small
                    width: parent.width - 24
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    color: {
                        switch (root.dropStatus) {
                        case "hover":
                            return Appearance.colors.colPrimary;
                        case "done":
                            return Appearance.colors.colTertiary;
                        case "error":
                            return Appearance.colors.colError;
                        default:
                            return Appearance.colors.colOnLayer1;
                        }
                    }
                    opacity: root.dropStatus === "idle" ? 0.6 : 1.0
                    text: {
                        switch (root.dropStatus) {
                        case "idle":
                            return Translation.tr("Drop image(s) here\nto convert to .%1").arg(root.selectedFormat.toUpperCase());
                        case "hover":
                            return Translation.tr("Release to convert to .%1").arg(root.selectedFormat.toUpperCase());
                        case "converting":
                            return root.statusMessage;
                        case "done":
                            return root.statusMessage;
                        case "error":
                            return root.statusMessage;
                        default:
                            return "";
                        }
                    }
                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                }

                DropArea {
                    anchors.fill: parent
                    keys: ["text/uri-list"]
                    onEntered: drag => {
                        drag.accept(Qt.CopyAction);
                        root.dropStatus = "hover";
                    }
                    onExited: {
                        if (root.dropStatus === "hover")
                            root.dropStatus = "idle";
                    }
                    onDropped: drop => {
                        if (drop.hasUrls && drop.urls.length > 0) {
                            root.enqueueFiles(drop.urls);
                        } else {
                            root.dropStatus = "error";
                            root.statusMessage = Translation.tr("Could not read file path.");
                            resetTimer.start();
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledText {
                    Layout.leftMargin: 3
                    text: Translation.tr("Convert to:")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    opacity: 0.7
                    Layout.alignment: Qt.AlignVCenter
                }

                StyledComboBox {
                    Layout.fillWidth: true
                    model: root.formatOptions
                    colBackground: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.8)
                    colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.8)
                    colBackgroundActive: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.8)
                    textRole: "displayName"
                    valueRole: "value"
                    currentIndex: {
                        for (let i = 0; i < model.length; i++) {
                            if (model[i].value === root.selectedFormat)
                                return i;
                        }
                        return 0;
                    }
                    onActivated: index => {
                        root.selectedFormat = model[index].value;
                    }
                }
            }
        }
    }
}

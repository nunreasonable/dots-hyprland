import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs
import qs.services
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "media"
    hoverEnabled: true

    readonly property var playerList: MprisController.players
    property MprisPlayer currentPlayer: MprisController.activePlayer
    property var artUrl: currentPlayer?.trackArtUrl
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl)
    property string artFilePath: `${artDownloadLocation}/${artFileName}`

    property real buttonSize: 34
    property real buttonIconSize: 18

    readonly property real cardSpacing: 12
    readonly property real singleWidth: 132
    readonly property real cardHeight: 120
    readonly property real doubleCardHeight: root.cardHeight * 2 + root.cardSpacing

    readonly property real snapWidth1: root.singleWidth
    readonly property real snapWidth2: root.singleWidth * 2 + root.cardSpacing
    readonly property real snapWidth3: root.singleWidth * 3 + root.cardSpacing * 2

    property string sizeMode: root.configEntry.sizeMode ?? "1x3"

    property real widgetWidth: {
        switch (root.sizeMode) {
        case "1x1":
            return root.snapWidth1;
        case "1x2":
            return root.snapWidth2;
        case "2x2":
            return root.snapWidth2;
        default:
            return root.snapWidth3;
        }
    }

    function modeForWidth(value) {
        const mid1 = (root.snapWidth1 + root.snapWidth2) / 2;
        const mid2 = (root.snapWidth2 + root.snapWidth3) / 2;
        if (value < mid1)
            return "1x1";
        if (value < mid2)
            return "1x2";
        return "1x3";
    }

    readonly property real heightEnterFraction: 0.2
    readonly property real heightEnterDelta: (root.doubleCardHeight - root.cardHeight) * root.heightEnterFraction

    function modeForDrag(dx, dy, startWidth) {
        if (dy > root.heightEnterDelta) {
            if (root.sizeMode === "1x3" || root.sizeMode === "2x2")
                return "2x2";
        }
        return root.modeForWidth(startWidth + dx);
    }

    Behavior on widgetWidth {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    property bool downloaded: false

    readonly property bool artIsLocal: Platform.isWindows && String(root.artUrl ?? "").startsWith("file:")
    property string displayedArtFilePath: root.artIsLocal ? root.artUrl : (root.downloaded ? (Platform.isWindows ? `file:///${artFilePath}` : Qt.resolvedUrl(artFilePath)) : "")

    implicitHeight: card.implicitHeight
    implicitWidth: card.implicitWidth

    onArtFilePathChanged: updateArt()

    function updateArt() {
        if (!root.artUrl || root.artUrl.length === 0) {
            root.downloaded = false;
            return;
        }
        if (root.artIsLocal) {
            root.downloaded = true;
            return;
        }
        coverArtDownloader.targetFile = root.artUrl;
        coverArtDownloader.artFilePath = root.artFilePath;
        root.downloaded = false;
        if (Platform.isWindows && WindowsNative.fsUtils?.classify(root.artFilePath) === "file") {
            root.downloaded = true;
            return;
        }
        coverArtDownloader.running = true;
    }

    Process {
        id: coverArtDownloader
        property string targetFile: root.artUrl
        property string artFilePath: root.artFilePath
        command: Platform.isWindows ? ["curl", "-4", "-sSL", targetFile, "-o", artFilePath] : ["bash", "-c", `[ -f ${artFilePath} ] || curl -4 -sSL '${targetFile}' -o '${artFilePath}'`]
        onExited: (exitCode, exitStatus) => {
            root.downloaded = !Platform.isWindows || exitCode === 0;
        }
    }

    StyledRectangularShadow {
        target: card
        z: -2
        visible: !Platform.isWindows && Config.options.background.widgets.shadow
    }

    WidgetCard {
        id: card
        widget: root
        shadowed: false
        implicitWidth: root.widgetWidth
        implicitHeight: root.sizeMode === "2x2" ? root.doubleCardHeight : root.cardHeight
        clip: true

        Behavior on implicitHeight {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Loader {
            anchors.fill: parent
            sourceComponent: {
                if (root.sizeMode === "1x1")
                    return oneByOneContent;
                if (root.sizeMode === "1x2")
                    return oneByTwoContent;
                if (root.sizeMode === "2x2")
                    return twoByTwoContent;
                return oneByThreeContent;
            }
        }

        Component {
            id: oneByOneContent
            Item {
                id: squareArt
                anchors.fill: parent
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: squareArt.width
                        height: squareArt.height
                        radius: card.radius
                    }
                }

                StyledImage {
                    anchors.fill: parent
                    source: root.displayedArtFilePath
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    antialiasing: true
                    sourceSize.width: root.singleWidth * 2
                    sourceSize.height: root.cardHeight * 2
                    visible: root.displayedArtFilePath !== ""
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: 1
                    text: "music_note"
                    iconSize: root.cardHeight / 3
                    color: Appearance.colors.colOnSecondaryContainer
                    visible: root.displayedArtFilePath === ""
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: "transparent"
                        }
                        GradientStop {
                            position: 0.5
                            color: ColorUtils.transparentize("#000000", 0.85)
                        }
                        GradientStop {
                            position: 1.0
                            color: ColorUtils.transparentize("#000000", 0.1)
                        }
                    }
                }

                RowLayout {
                    anchors {
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                        bottomMargin: 10
                    }
                    spacing: 4
                    visible: MprisController.activePlayer !== null

                    RippleButton {
                        implicitWidth: 26
                        implicitHeight: 26
                        buttonRadius: Appearance.rounding?.full ?? 999
                        colBackground: "transparent"
                        colBackgroundHover: ColorUtils.transparentize("#ffffff", 0.8)
                        colRipple: ColorUtils.transparentize("#ffffff", 0.7)
                        downAction: () => root.currentPlayer?.previous()

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "skip_previous"
                            iconSize: 16
                            fill: 1
                            color: Appearance.colors.colPrimary
                        }
                    }

                    MaterialShapeWrappedMaterialSymbol {
                        shape: MaterialShape.Shape.Cookie12Sided
                        color: Appearance.colors.colPrimary
                        colSymbol: Appearance.colors.colOnPrimary
                        text: root.currentPlayer?.isPlaying ? "pause" : "play_arrow"
                        iconSize: 18
                        fill: 1
                        padding: 6

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.currentPlayer?.togglePlaying()
                        }
                    }

                    RippleButton {
                        implicitWidth: 26
                        implicitHeight: 26
                        buttonRadius: Appearance.rounding?.full ?? 999
                        colBackground: "transparent"
                        colBackgroundHover: ColorUtils.transparentize("#ffffff", 0.8)
                        colRipple: ColorUtils.transparentize("#ffffff", 0.7)
                        downAction: () => root.currentPlayer?.next()

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "skip_next"
                            iconSize: 16
                            fill: 1
                            color: Appearance.colors.colPrimary
                        }
                    }
                }
            }
        }

        Component {
            id: oneByTwoContent
            RowLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    id: artBlock
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.cardHeight
                    color: Appearance.colors.colSurfaceContainerLow
                    topLeftRadius: card.radius
                    bottomLeftRadius: card.radius
                    topRightRadius: 0
                    bottomRightRadius: 0
                    clip: true
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: artBlock.width
                            height: artBlock.height
                            topLeftRadius: card.radius
                            bottomLeftRadius: card.radius
                            topRightRadius: 0
                            bottomRightRadius: 0
                        }
                    }

                    StyledImage {
                        anchors.fill: parent
                        source: root.displayedArtFilePath
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        antialiasing: true
                        sourceSize.width: artBlock.width * 2
                        sourceSize.height: artBlock.height * 2
                        visible: root.displayedArtFilePath !== ""
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        fill: 1
                        text: "music_note"
                        iconSize: root.cardHeight / 3
                        color: Appearance.colors.colOnSecondaryContainer
                        visible: root.displayedArtFilePath === ""
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 14
                    Layout.rightMargin: 12
                    Layout.topMargin: 12
                    Layout.bottomMargin: 10
                    spacing: 4

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            Layout.fillWidth: true
                            text: root.currentPlayer?.trackArtist ?? Translation.tr("Play")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnPrimaryContainer
                            elide: Text.ElideRight
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: root.currentPlayer?.trackTitle ?? Translation.tr("Something")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnPrimaryContainer
                            opacity: 0.6
                            elide: Text.ElideRight
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4

                        RippleButton {
                            implicitWidth: 28
                            implicitHeight: 28
                            buttonRadius: Appearance.rounding?.full ?? 999
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                            colRipple: Appearance.colors.colPrimaryContainerActive
                            downAction: () => root.currentPlayer?.previous()

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "skip_previous"
                                iconSize: root.buttonIconSize - 2
                                fill: 1
                                color: Appearance.colors.colOnPrimaryContainer
                            }
                        }

                        MaterialShapeWrappedMaterialSymbol {
                            shape: MaterialShape.Shape.Cookie12Sided
                            color: Appearance.colors.colPrimary
                            colSymbol: Appearance.colors.colOnPrimary
                            text: root.currentPlayer?.isPlaying ? "pause" : "play_arrow"
                            iconSize: root.buttonIconSize + 4
                            fill: 1
                            padding: 7

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.currentPlayer?.togglePlaying()
                            }
                        }

                        RippleButton {
                            implicitWidth: 28
                            implicitHeight: 28
                            buttonRadius: Appearance.rounding?.full ?? 999
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                            colRipple: Appearance.colors.colPrimaryContainerActive
                            downAction: () => root.currentPlayer?.next()

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "skip_next"
                                iconSize: root.buttonIconSize - 2
                                fill: 1
                                color: Appearance.colors.colOnPrimaryContainer
                            }
                        }
                    }
                }
            }
        }

        Component {
            id: twoByTwoContent
            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    id: bigArt
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Appearance.colors.colSurfaceContainerLow
                    topLeftRadius: card.radius
                    topRightRadius: card.radius
                    bottomLeftRadius: 0
                    bottomRightRadius: 0
                    clip: true
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: bigArt.width
                            height: bigArt.height
                            topLeftRadius: card.radius
                            topRightRadius: card.radius
                            bottomLeftRadius: 0
                            bottomRightRadius: 0
                        }
                    }

                    StyledImage {
                        anchors.fill: parent
                        source: root.displayedArtFilePath
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        antialiasing: true
                        sourceSize.width: bigArt.width * 2
                        sourceSize.height: bigArt.height * 2
                        visible: root.displayedArtFilePath !== ""
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        fill: 1
                        text: "music_note"
                        iconSize: root.cardHeight / 2.5
                        color: Appearance.colors.colOnSecondaryContainer
                        visible: root.displayedArtFilePath === ""
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 14
                    Layout.rightMargin: 14
                    Layout.topMargin: 10
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: root.currentPlayer?.trackArtist ?? Translation.tr("Play")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnPrimaryContainer
                        elide: Text.ElideRight
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: root.currentPlayer?.trackTitle ?? Translation.tr("Something")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnPrimaryContainer
                        opacity: 0.65
                        elide: Text.ElideRight
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                    Layout.bottomMargin: 12
                    spacing: 6

                    RippleButton {
                        implicitWidth: 28
                        implicitHeight: 28
                        buttonRadius: Appearance.rounding?.full ?? 999
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                        colRipple: Appearance.colors.colPrimaryContainerActive
                        downAction: () => root.currentPlayer?.previous()

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "skip_previous"
                            iconSize: root.buttonIconSize - 2
                            fill: 1
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                    }

                    MaterialShapeWrappedMaterialSymbol {
                        shape: MaterialShape.Shape.Cookie12Sided
                        color: Appearance.colors.colPrimary
                        colSymbol: Appearance.colors.colOnPrimary
                        text: root.currentPlayer?.isPlaying ? "pause" : "play_arrow"
                        iconSize: root.buttonIconSize + 6
                        fill: 1
                        padding: 8

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.currentPlayer?.togglePlaying()
                        }
                    }

                    RippleButton {
                        implicitWidth: 28
                        implicitHeight: 28
                        buttonRadius: Appearance.rounding?.full ?? 999
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                        colRipple: Appearance.colors.colPrimaryContainerActive
                        downAction: () => root.currentPlayer?.next()

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "skip_next"
                            iconSize: root.buttonIconSize - 2
                            fill: 1
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                    }
                }
            }
        }

        Component {
            id: oneByThreeContent
            Item {
                anchors.fill: parent

                Rectangle {
                    id: artRect
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: root.cardHeight
                    color: Appearance.colors.colSurfaceContainerLow
                    topLeftRadius: card.radius
                    bottomLeftRadius: card.radius
                    topRightRadius: 0
                    bottomRightRadius: 0
                    clip: true
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: artRect.width
                            height: artRect.height
                            topLeftRadius: card.radius
                            bottomLeftRadius: card.radius
                            topRightRadius: 0
                            bottomRightRadius: 0
                        }
                    }

                    StyledImage {
                        anchors.fill: parent
                        source: root.displayedArtFilePath
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        antialiasing: true
                        sourceSize.width: artRect.width * 2
                        sourceSize.height: artRect.height * 2
                        visible: root.displayedArtFilePath !== ""
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        fill: 1
                        text: "music_note"
                        iconSize: root.cardHeight / 3
                        color: Appearance.colors.colOnSecondaryContainer
                        visible: root.displayedArtFilePath === ""
                    }
                }

                ColumnLayout {
                    anchors {
                        left: artRect.right
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                        leftMargin: 16
                        rightMargin: 14
                    }
                    spacing: -10

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        StyledText {
                            Layout.fillWidth: true
                            text: root.currentPlayer?.trackArtist ?? Translation.tr("Play")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnPrimaryContainer
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.currentPlayer?.trackTitle ?? Translation.tr("Something")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnPrimaryContainer
                            opacity: 0.65
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        id: controlsPill
                        Layout.alignment: Qt.AlignRight
                        implicitWidth: controlsRow.implicitWidth + 10
                        implicitHeight: root.buttonSize + 8
                        radius: Appearance.rounding?.full ?? 999
                        color: ColorUtils.transparentize(Appearance.colors.colOnPrimaryContainer, 0.9)

                        RowLayout {
                            id: controlsRow
                            anchors.centerIn: parent
                            spacing: 2

                            RippleButton {
                                implicitWidth: root.buttonSize
                                implicitHeight: root.buttonSize
                                buttonRadius: Appearance.rounding?.full ?? 999
                                colBackground: "transparent"
                                colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                                colRipple: Appearance.colors.colPrimaryContainerActive
                                downAction: () => root.currentPlayer?.previous()

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "skip_previous"
                                    iconSize: root.buttonIconSize
                                    fill: 1
                                    color: Appearance.colors.colOnPrimaryContainer
                                }
                            }

                            MaterialShapeWrappedMaterialSymbol {
                                shape: MaterialShape.Shape.Cookie12Sided
                                color: Appearance.colors.colPrimary
                                colSymbol: Appearance.colors.colOnPrimary
                                text: root.currentPlayer?.isPlaying ? "pause" : "play_arrow"
                                iconSize: root.buttonIconSize + 12
                                fill: 1
                                padding: 8

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.currentPlayer?.togglePlaying()
                                }
                            }

                            RippleButton {
                                implicitWidth: root.buttonSize
                                implicitHeight: root.buttonSize
                                buttonRadius: Appearance.rounding?.full ?? 999
                                colBackground: "transparent"
                                colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                                colRipple: Appearance.colors.colPrimaryContainerActive
                                downAction: () => root.currentPlayer?.next()
                                altAction: () => root.currentPlayer?.previous()

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "skip_next"
                                    iconSize: root.buttonIconSize
                                    fill: 1
                                    color: Appearance.colors.colOnPrimaryContainer
                                }
                            }
                        }
                    }
                }
            }
        }

        ResizeHandler {
            anchorItem: card
            hoverActive: root.containsMouse
            locked: Config.options.background.widgetsLocked
            currentWidth: root.widgetWidth
            resizeMode: "diagonal"
            onResizedXY: (dx, dy, startWidth) => {
                root.sizeMode = root.modeForDrag(dx, dy, startWidth);
            }
            onResizeFinished: {
                root.configEntry.sizeMode = root.sizeMode;
            }
        }
    }
}

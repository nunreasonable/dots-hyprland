import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

MouseArea {
    id: root
    property int columns: Config.options.wallpaperSelector.columns || 4
    property real previewCellAspectRatio: 4 / 3
    property bool useDarkMode: Appearance.m3colors.darkmode
    property bool shown: true
    property string source: "local"
    property bool showControls: false
    readonly property bool toolbarVisible: root.showControls || Config.options.wallpaperSelector.showSearchbar

    property bool spicyRevealed: false
    readonly property bool inSpicyDir: Wallpapers.isInSpicyFolder(Wallpapers.effectiveDirectory)
    readonly property bool spicyBlurActive: root.source === "local" && root.inSpicyDir && !root.spicyRevealed
    onInSpicyDirChanged: if (!root.inSpicyDir)
                             root.spicyRevealed = false

    property var quickDirs: [
        {
            icon: "home",
            name: "Home",
            path: Directories.home,
            visible: Config.options.wallpaperSelector.showHomePath
        },
        {
            icon: "docs",
            name: "Documents",
            path: Directories.documents,
            visible: true
        },
        {
            icon: "download",
            name: "Downloads",
            path: Directories.downloads,
            visible: true
        },
        {
            icon: "image",
            name: "Pictures",
            path: Directories.pictures,
            visible: true
        },
        {
            icon: "movie",
            name: "Videos",
            path: Directories.videos,
            visible: true
        },
        {
            icon: "",
            name: "---",
            path: "INTENTIONALLY_INVALID_DIR",
            visible: true
        },
        {
            icon: "wallpaper",
            name: "Wallpapers",
            path: `${Directories.pictures}/Wallpapers`,
            visible: true
        },
        ...(Config.options.policies.weeb === 1 ? [
                                                     {
                                                         icon: "favorite",
                                                         name: "Homework",
                                                         path: `${Directories.pictures}/homework`,
                                                         visible: true
                                                     }
                                                 ] : []),
        {
            icon: "folder_special",
            name: "Wpp",
            path: Config.options.wallpaperSelector.wppFolder,
            visible: true
        },
        {
            icon: "whatshot",
            name: "Wpp (Spicy)",
            path: Config.options.wallpaperSelector.wppSpicyFolder,
            visible: true,
            spicy: true
        },
        ...(Config.options.wallpaperSelector.userPath?.trim().length > 0 ? [
                                                                               {
                                                                                   icon: "folder_open",
                                                                                   name: Config.options.wallpaperSelector.userPath.split(
                                                                                             "/").filter(s
                                                                                                         => s.length
                                                                                                            > 0).pop()
                                                                                         || "Custom",
                                                                                   path: Config.options.wallpaperSelector.userPath,
                                                                                   visible: true
                                                                               }
                                                                           ] : []),]

    function updateThumbnails() {
        const totalImageMargin = (Appearance.sizes.wallpaperSelectorItemMargins
                                  + Appearance.sizes.wallpaperSelectorItemPadding) * 2;
        const thumbnailSizeName = Images.thumbnailSizeNameForDimensions(grid.cellWidth - totalImageMargin,
                                                                        grid.cellHeight - totalImageMargin);
        Wallpapers.generateThumbnail(thumbnailSizeName);
    }

    Connections {
        target: Wallpapers
        function onDirectoryChanged() {
            if (root.shown && root.source === "local")
                root.updateThumbnails();
        }
    }

    onShownChanged: {
        if (root.shown && root.source === "local")
            root.updateThumbnails();
    }
    onSourceChanged: {
        if (root.shown && root.source === "local")
            root.updateThumbnails();
    }

    function handleFilePasting(event) {
        const currentClipboardEntry = Cliphist.entries[0];
        if (/^\d+\tfile:\/\/\S+/.test(currentClipboardEntry)) {
            const url = StringUtils.cleanCliphistEntry(currentClipboardEntry);
            Wallpapers.setDirectory(FileUtils.trimFileProtocol(decodeURIComponent(url)));
            event.accepted = true;
        } else {
            event.accepted = false; // No image, let text pasting proceed
        }
    }

    function selectWallpaperPath(filePath, isDirectory) {
        if (filePath && filePath.length > 0) {
            Wallpapers.select(filePath, isDirectory, root.useDarkMode);
            filterField.text = "";
        }
    }

    acceptedButtons: Qt.BackButton | Qt.ForwardButton
    onPressed: event => {
        if (event.button === Qt.BackButton) {
            Wallpapers.navigateBack();
        } else if (event.button === Qt.ForwardButton) {
            Wallpapers.navigateForward();
        }
    }

    Keys.onPressed: event => {
        if (root.spicyBlurActive && !(event.modifiers & Qt.AltModifier) && [Qt.Key_Left, Qt.Key_Right,
                                                                            Qt.Key_Up, Qt.Key_Down,
                                                                            Qt.Key_Return,
                                                                            Qt.Key_Enter].includes(
                    event.key)) {
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Escape) {
            GlobalStates.wallpaperSelectorOpen = false;
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key
                   === Qt.Key_V) {

            root.handleFilePasting(event);
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
            if (Config.options.wallpaperSelector.showSearchbar) {
                Config.options.wallpaperSelector.showSearchbar = false;
                root.showControls = false;
            } else {
                root.showControls = !root.showControls;
            }
            event.accepted = true;
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Up) {
            Wallpapers.navigateUp();
            event.accepted = true;
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Left) {
            Wallpapers.navigateBack();
            event.accepted = true;
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Right) {
            Wallpapers.navigateForward();
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            if (root.source === "local")
                grid.moveSelection(-1);
            else
                wallhavenLoader.item?.moveSelection(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            if (root.source === "local")
                grid.moveSelection(1);
            else
                wallhavenLoader.item?.moveSelection(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            if (root.source === "local")
                grid.moveSelection(-grid.columns);
            else
                wallhavenLoader.item?.moveSelection(-root.columns);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            if (root.source === "local")
                grid.moveSelection(grid.columns);
            else
                wallhavenLoader.item?.moveSelection(root.columns);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.source === "local")
                grid.activateCurrent();
            else
                wallhavenLoader.item?.activateCurrent();
            event.accepted = true;
        } else if (event.key === Qt.Key_Backspace) {
            if (filterField.text.length > 0) {
                filterField.text = filterField.text.substring(0, filterField.text.length - 1);
            }
            filterField.forceActiveFocus();
            event.accepted = true;
        } else if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_L) {
            addressBar.focusBreadcrumb();
            event.accepted = true;
        } else if (event.key === Qt.Key_Slash) {
            filterField.forceActiveFocus();
            event.accepted = true;
        } else {
            if (event.text.length > 0) {
                filterField.text += event.text;
                filterField.cursorPosition = filterField.text.length;
                filterField.forceActiveFocus();
            }
            event.accepted = true;
        }
    }

    implicitHeight: mainLayout.implicitHeight
    implicitWidth: mainLayout.implicitWidth

    StyledRectangularShadow {
        target: wallpaperGridBackground
    }
    Rectangle {
        id: wallpaperGridBackground
        anchors {
            fill: parent
            margins: Appearance.sizes.elevationMargin
        }
        focus: true
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        color: Appearance.colors.colLayer0
        radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1

        property int calculatedRows: Math.ceil(grid.count / grid.columns)

        implicitWidth: gridColumnLayout.implicitWidth
        implicitHeight: gridColumnLayout.implicitHeight

        Item {
            anchors {
                fill: parent
                margins: 8
            }
            z: 0

            Rectangle {
                anchors.fill: parent
                radius: wallpaperGridBackground.radius - 4
                color: Appearance.colors.colLayer2
                visible: !Config.options.wallpaperSelector.showBlurBackground
            }

            StyledImage {
                id: wallpaperBgImage
                anchors.fill: parent
                visible: Config.options.wallpaperSelector.showBlurBackground
                fillMode: Image.PreserveAspectCrop
                source: Config.options.wallpaperSelector.showBlurBackground
                        ? Config.options.background.wallpaperPath : ""
                sourceSize: Qt.size(480, 480)
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: wallpaperGridBackground.width - 16
                        height: wallpaperGridBackground.height - 16
                        radius: wallpaperGridBackground.radius - 4
                    }
                }
            }

            FastBlur {
                anchors.fill: parent
                z: 0
                visible: Config.options.wallpaperSelector.showBlurBackground
                source: wallpaperBgImage
                radius: 48
                layer.enabled: visible
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: wallpaperGridBackground.width - 16
                        height: wallpaperGridBackground.height - 16
                        radius: wallpaperGridBackground.radius - 4
                    }
                }
            }
        }

        RowLayout {
            id: mainLayout
            anchors.fill: parent
            spacing: -4
            z: 1

            Rectangle {
                Layout.fillHeight: true
                Layout.margins: 4
                implicitWidth: quickDirColumnLayout.implicitWidth
                implicitHeight: quickDirColumnLayout.implicitHeight
                color: Appearance.colors.colLayer1
                radius: wallpaperGridBackground.radius - Layout.margins

                ColumnLayout {
                    id: quickDirColumnLayout
                    anchors.fill: parent
                    spacing: 0

                    StyledText {
                        Layout.margins: 12
                        font {
                            pixelSize: Appearance.font.pixelSize.normal
                            weight: Font.Medium
                        }
                        text: Translation.tr("Pick a wallpaper")
                    }
                    ListView {
                        // Quick dirs
                        Layout.fillHeight: true
                        Layout.margins: 4
                        implicitWidth: 140
                        clip: true
                        model: root.quickDirs.filter(d => d.visible)
                        delegate: RippleButton {
                            id: quickDirButton
                            required property var modelData
                            readonly property bool isSpicy: modelData.spicy ?? false
                            readonly property bool spicyDisabled: quickDirButton.isSpicy &&
                                                                  !SpicyStuff.allowed
                            anchors {
                                left: parent.left
                                right: parent.right
                            }
                            onClicked: Wallpapers.setDirectory(quickDirButton.modelData.path)
                            enabled: modelData.icon.length > 0
                            toggled: Wallpapers.normalizedPath(Wallpapers.effectiveDirectory) === Wallpapers.normalizedPath(modelData.path)
                            colBackgroundToggled: Appearance.colors.colSecondaryContainer
                            colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                            colRippleToggled: Appearance.colors.colSecondaryContainerActive
                            buttonRadius: height / 2
                            implicitHeight: 38

                            contentItem: RowLayout {
                                MaterialSymbol {
                                    color: quickDirButton.toggled ? Appearance.colors.colOnSecondaryContainer :
                                                                    Appearance.colors.colOnLayer1
                                    opacity: quickDirButton.enabled && !quickDirButton.spicyDisabled ? 1 : 0.4
                                    iconSize: Appearance.font.pixelSize.larger
                                    text: quickDirButton.modelData.icon
                                    fill: quickDirButton.toggled ? 1 : 0
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignLeft
                                    opacity: quickDirButton.enabled && !quickDirButton.spicyDisabled ? 1 : 0.4
                                    color: quickDirButton.toggled ? Appearance.colors.colOnSecondaryContainer :
                                                                    Appearance.colors.colOnLayer1
                                    text: Translation.tr(quickDirButton.modelData.name)
                                }
                                MaterialSymbol {
                                    visible: quickDirButton.spicyDisabled
                                    opacity: 0.6
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer1
                                    text: "lock"
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                id: gridColumnLayout
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                    Layout.margins: 4
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    spacing: 6

                    AddressBar {
                        id: addressBar
                        Layout.fillWidth: true
                        visible: root.source === "local"
                        directory: Wallpapers.effectiveDirectory
                        onNavigateToDirectory: path => {
                            Wallpapers.setDirectory(path.length == 0 ? "/" : path);
                        }
                        radius: wallpaperGridBackground.radius - 4
                    }

                    StyledText {
                        visible: root.source !== "local"
                        Layout.fillWidth: true
                        text: Translation.tr("Wallhaven")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledComboBox {
                        id: sourceCombo
                        implicitWidth: 150
                        model: [
                            {
                                value: "local",
                                displayName: Translation.tr("Local"),
                                icon: "folder"
                            },
                            {
                                value: "wallhaven",
                                displayName: Translation.tr("Wallhaven"),
                                icon: "travel_explore"
                            },
                        ]
                        textRole: "displayName"
                        currentIndex: root.source === "wallhaven" ? 1 : 0
                        onCurrentIndexChanged: {
                            root.source = model[currentIndex].value;
                            root.forceActiveFocus();
                        }
                    }
                }

                Item {
                    id: gridDisplayRegion
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Loader {
                        id: wallhavenLoader
                        anchors.fill: parent
                        active: root.source === "wallhaven"
                        visible: active
                        sourceComponent: WallhavenSearchGrid {
                            columns: root.columns
                            previewCellAspectRatio: root.previewCellAspectRatio
                            useDarkMode: root.useDarkMode
                            onWallpaperApplied: {
                                if (Config.options.wallpaperSelector.closeAfterSelection)
                                    GlobalStates.wallpaperSelectorOpen = false;
                            }
                        }
                    }

                    Item {
                        id: localGridArea
                        anchors.fill: parent
                        visible: root.source === "local"

                        StyledIndeterminateProgressBar {
                            id: indeterminateProgressBar
                            visible: Wallpapers.thumbnailGenerationRunning && value == 0
                            anchors {
                                bottom: parent.top
                                left: parent.left
                                right: parent.right
                                leftMargin: 4
                                rightMargin: 4
                            }
                        }

                        StyledProgressBar {
                            visible: Wallpapers.thumbnailGenerationRunning && value > 0
                            value: Wallpapers.thumbnailGenerationProgress
                            anchors.fill: indeterminateProgressBar
                        }

                        Item {
                            id: localGridBlurWrapper
                            anchors.fill: parent
                            layer.enabled: root.spicyBlurActive
                            layer.effect: FastBlur {
                                radius: 96
                            }

                            GridView {
                                id: grid
                                visible: Wallpapers.folderModel.count > 0

                                readonly property int columns: root.columns
                                readonly property int rows: Math.max(1, Math.ceil(count / columns))
                                property int currentIndex: 0

                                anchors.fill: parent
                                cellWidth: width / root.columns
                                cellHeight: cellWidth / root.previewCellAspectRatio
                                interactive: true
                                clip: true
                                keyNavigationWraps: true
                                boundsBehavior: Flickable.StopAtBounds
                                bottomMargin: extraOptions.implicitHeight
                                ScrollBar.vertical: StyledScrollBar {}

                                Component.onCompleted: {
                                    root.updateThumbnails();
                                }

                                function moveSelection(delta) {
                                    currentIndex = Math.max(0, Math.min(grid.model.count - 1, currentIndex
                                                                        + delta));
                                    positionViewAtIndex(currentIndex, GridView.Contain);
                                }

                                function activateCurrent() {
                                    const filePath = grid.model.get(currentIndex, "filePath");
                                    const isDirectory = grid.model.get(currentIndex, "fileIsDir");
                                    root.selectWallpaperPath(filePath, isDirectory);
                                }

                                model: Wallpapers.folderModel
                                onModelChanged: currentIndex = 0
                                delegate: WallpaperDirectoryItem {
                                    required property var modelData
                                    required property int index
                                    fileModelData: modelData
                                    width: grid.cellWidth
                                    height: grid.cellHeight
                                    colBackground: (index === grid?.currentIndex || containsMouse)
                                                   ? Appearance.colors.colPrimary : (fileModelData.filePath
                                                                                     === Config.options.background.wallpaperPath)
                                                     ? Appearance.colors.colSecondaryContainer :
                                                       ColorUtils.transparentize(
                                                           Appearance.colors.colPrimaryContainer)
                                    colText: (index === grid.currentIndex || containsMouse)
                                             ? Appearance.colors.colOnPrimary : (fileModelData.filePath
                                                                                 === Config.options.background.wallpaperPath)
                                               ? Appearance.colors.colOnSecondaryContainer :
                                                 Appearance.colors.colOnLayer0

                                    onEntered: {
                                        grid.currentIndex = index;
                                    }

                                    onActivated: {
                                        root.selectWallpaperPath(fileModelData.filePath,
                                                                 fileModelData.fileIsDir);
                                    }
                                }

                                layer.enabled: !Platform.isWindows
                                layer.effect: OpacityMask {
                                    maskSource: Rectangle {
                                        width: gridDisplayRegion.width
                                        height: gridDisplayRegion.height
                                        radius: wallpaperGridBackground.radius
                                    }
                                }
                            }
                        }

                        Item {
                            id: spicyWarning
                            anchors.fill: parent
                            visible: root.spicyBlurActive
                            z: 8

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.AllButtons
                                onWheel: wheel => wheel.accepted = true
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.4)
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                implicitWidth: spicyWarningContent.implicitWidth + 48
                                implicitHeight: spicyWarningContent.implicitHeight + 40
                                radius: Appearance.rounding.large
                                color: Appearance.colors.colLayer2

                                ColumnLayout {
                                    id: spicyWarningContent
                                    anchors.centerIn: parent
                                    spacing: 10

                                    MaterialSymbol {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "visibility_off"
                                        iconSize: 40
                                        color: Appearance.colors.colOnLayer2
                                    }
                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: Translation.tr("Sensitive content")
                                        font.pixelSize: Appearance.font.pixelSize.larger
                                        color: Appearance.colors.colOnLayer2
                                    }
                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.maximumWidth: 420
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.Wrap
                                        text: SpicyStuff.allowed ? Translation.tr(
                                                                       "This folder contains spicy wallpapers.\nMake sure no one is looking before showing it.") :
                                                                   SpicyStuff.restriction
                                        color: Appearance.colors.colSubtext
                                    }
                                    RowLayout {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.topMargin: 6
                                        spacing: 8
                                        DialogButton {
                                            buttonText: Translation.tr("Go back")
                                            onClicked: Wallpapers.setDirectory(`${Directories.pictures
                                                                               }/Wallpapers`)
                                        }
                                        DialogButton {
                                            visible: SpicyStuff.allowed
                                            buttonText: Translation.tr("Show")
                                            onClicked: {
                                                root.spicyRevealed = true;
                                                root.forceActiveFocus();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        id: extraOptions
                        anchors {
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                            bottomMargin: 8
                        }
                        spacing: 6

                        Toolbar {
                            visible: root.source === "local"

                            IconToolbarButton {
                                implicitWidth: height
                                onClicked: {
                                    Wallpapers.openFallbackPicker(root.useDarkMode);
                                    GlobalStates.wallpaperSelectorOpen = false;
                                }
                                altAction: () => {
                                    Wallpapers.openFallbackPicker(root.useDarkMode);
                                    GlobalStates.wallpaperSelectorOpen = false;
                                    Config.options.wallpaperSelector.useSystemFileDialog = true;
                                }
                                text: "open_in_new"
                                StyledToolTip {
                                    text: Translation.tr(
                                              "Use the system file picker instead\nRight-click to make this the default behavior")
                                }
                            }

                            IconToolbarButton {
                                implicitWidth: height
                                onClicked: {
                                    Wallpapers.randomFromCurrentFolder();
                                }
                                text: "ifl"
                                StyledToolTip {
                                    text: Translation.tr("Pick random from this folder")
                                }
                            }

                            IconToolbarButton {
                                implicitWidth: height
                                onClicked: root.useDarkMode = !root.useDarkMode
                                text: root.useDarkMode ? "dark_mode" : "light_mode"
                                StyledToolTip {
                                    text: Translation.tr(
                                              "Click to toggle light/dark mode\n(applied when wallpaper is chosen)")
                                }
                            }

                            StyledComboBox {
                                id: sortCombo
                                implicitWidth: 170
                                buttonIcon: "sort"
                                model: [
                                    {
                                        value: "time",
                                        displayName: Translation.tr("Date added (newest first)")
                                    },
                                    {
                                        value: "time_rev",
                                        displayName: Translation.tr("Date added (oldest first)")
                                    },
                                    {
                                        value: "name",
                                        displayName: Translation.tr("Name (A to Z)")
                                    },
                                    {
                                        value: "name_rev",
                                        displayName: Translation.tr("Name (Z to A)")
                                    },
                                    {
                                        value: "size",
                                        displayName: Translation.tr("Size (largest first)")
                                    },
                                    {
                                        value: "size_rev",
                                        displayName: Translation.tr("Size (smallest first)")
                                    },
                                ]
                                textRole: "displayName"
                                Component.onCompleted: {
                                    const i = model.findIndex(m => m.value === Wallpapers.sortMode);
                                    if (i >= 0)
                                        currentIndex = i;
                                }
                                onCurrentIndexChanged: {
                                    if (currentIndex < 0)
                                        return;
                                    Wallpapers.setSortMode(model[currentIndex].value);
                                }
                                StyledToolTip {
                                    text: Translation.tr("Sort wallpapers")
                                }
                            }

                            ToolbarTextField {
                                id: filterField
                                visible: root.toolbarVisible
                                placeholderText: focus ? Translation.tr("Search wallpapers") : Translation.tr(
                                                             "Hit \"/\" to search")

                                // Style
                                clip: true
                                font.pixelSize: Appearance.font.pixelSize.small

                                // Search
                                onTextChanged: {
                                    Wallpapers.searchQuery = text;
                                }

                                Keys.onPressed: event => {
                                    if ((event.modifiers & Qt.ControlModifier) && event.key
                                            === Qt.Key_V) {

                                        root.handleFilePasting(event);
                                        return;
                                    } else if (text.length !== 0) {
                                        // No filtering, just navigate grid
                                        if (event.key === Qt.Key_Down) {
                                            grid.moveSelection(grid.columns);
                                            event.accepted = true;
                                            return;
                                        }
                                        if (event.key === Qt.Key_Up) {
                                            grid.moveSelection(-grid.columns);
                                            event.accepted = true;
                                            return;
                                        }
                                    }
                                    event.accepted = false;
                                }
                            }
                        }

                        Loader {
                            active: root.source === "wallhaven"
                            visible: active
                            sourceComponent: Toolbar {
                                id: wallhavenToolbar

                                property bool _searchFieldReady: false

                                Timer {
                                    id: searchDebounce
                                    interval: 500
                                    onTriggered: WallhavenSearch.search(wallhavenSearchField.text, 1)
                                }

                                ToolbarTextField {
                                    id: wallhavenSearchField
                                    text: WallhavenSearch.currentQuery
                                    placeholderText: Translation.tr("Search Wallhaven...")
                                    implicitWidth: 220
                                    onTextChanged: {
                                        if (wallhavenToolbar._searchFieldReady)
                                            searchDebounce.restart();
                                    }
                                    onAccepted: {
                                        searchDebounce.stop();
                                        WallhavenSearch.search(text, 1);
                                    }
                                    Keys.onPressed: event => {
                                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            event.accepted = true;
                                            return;
                                        }
                                        event.accepted = false;
                                    }
                                    Component.onCompleted: {
                                        Qt.callLater(() => wallhavenToolbar._searchFieldReady = true);
                                    }
                                }

                                RowLayout {
                                    visible: WallhavenSearch.currentResults.length > 0
                                    spacing: 4

                                    IconToolbarButton {
                                        implicitWidth: height
                                        enabled: !WallhavenSearch.fetching && WallhavenSearch.currentPage > 1
                                        text: "chevron_left"
                                        onClicked: WallhavenSearch.previousPage()
                                    }

                                    StyledText {
                                        text: WallhavenSearch.currentPage + " / " + WallhavenSearch.lastPage
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colSubtext
                                    }

                                    IconToolbarButton {
                                        implicitWidth: height
                                        enabled: !WallhavenSearch.fetching && WallhavenSearch.currentPage
                                                 < WallhavenSearch.lastPage
                                        text: "chevron_right"
                                        onClicked: WallhavenSearch.nextPage()
                                    }
                                }

                                IconToolbarButton {
                                    implicitWidth: height
                                    text: "tune"
                                    toggled: wallhavenLoader.item?.showSettings ?? false
                                    onClicked: {
                                        if (wallhavenLoader.item)
                                            wallhavenLoader.item.toggleSettings();
                                    }
                                    StyledToolTip {
                                        text: Translation.tr("Wallhaven search settings")
                                    }
                                }

                                IconToolbarButton {
                                    implicitWidth: height
                                    text: root.useDarkMode ? "dark_mode" : "light_mode"
                                    onClicked: root.useDarkMode = !root.useDarkMode
                                    StyledToolTip {
                                        text: Translation.tr(
                                                  "Click to toggle light/dark mode\n(applied when wallpaper is chosen)")
                                    }
                                }

                                IconToolbarButton {
                                    implicitWidth: height
                                    text: "refresh"
                                    onClicked: WallhavenSearch.search(WallhavenSearch.currentQuery, 1)
                                    StyledToolTip {
                                        text: Translation.tr("Refresh search results")
                                    }
                                }
                            }
                        }

                        ToolbarPairedFab {
                            iconText: "close"
                            onClicked: GlobalStates.wallpaperSelectorOpen = false
                            StyledToolTip {
                                text: Translation.tr("Cancel wallpaper selection")
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: GlobalStates
        function onWallpaperSelectorOpenChanged() {
            if (GlobalStates.wallpaperSelectorOpen && monitorIsFocused) {
                filterField.forceActiveFocus();
            } else if (!GlobalStates.wallpaperSelectorOpen) {
                root.spicyRevealed = false;
                WallhavenSearch.clearQuery();
            }
        }
    }

    Connections {
        target: Wallpapers
        function onChanged() {
            if (Config.options.wallpaperSelector.closeAfterSelection)
                GlobalStates.wallpaperSelectorOpen = false;
        }
    }
}

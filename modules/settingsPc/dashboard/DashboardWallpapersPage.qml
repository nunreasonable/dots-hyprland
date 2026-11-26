import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    required property Item pager
    property int staggerMs: 45
    property int selectedIndex: 0
    property string target: "desktop"
    property bool spicyRevealed: false
    property var allItems: []

    readonly property var intervalControl: ({
        type: "spin",
        get: () => Math.round((Config.options.wallpaperSelector.changeInterval ?? 0) / 60000),
        set: v => {
            Config.options.wallpaperSelector.changeInterval = v * 60000;
        },
        from: 0,
        to: 1440,
        stepSize: 5
    })

    readonly property var transitionControl: ({
        type: "select",
        get: () => Config.options.background.wallpaperAnimation,
        set: v => {
            Config.options.background.wallpaperAnimation = v;
        },
        options: [
            { displayName: Translation.tr("None"), icon: "block", value: "" },
            { displayName: Translation.tr("Circle"), icon: "circle", value: "circleSelect" },
            { displayName: Translation.tr("Circle Pit"), icon: "blur_circular", value: "circlePit" },
            { displayName: Translation.tr("Magic"), icon: "auto_awesome", value: "magic" },
            { displayName: Translation.tr("Doom"), icon: "whatshot", value: "Doom" },
            { displayName: Translation.tr("Peel"), icon: "layers", value: "Peel" },
            { displayName: Translation.tr("Fade"), icon: "gradient", value: "transition" },
            { displayName: Translation.tr("Pixelate"), icon: "grain", value: "pixelate" },
            { displayName: Translation.tr("Stripes"), icon: "texture_minus", value: "stripes" },
            { displayName: Translation.tr("CRT"), icon: "tv", value: "crt" },
            { displayName: Translation.tr("Dissolve"), icon: "blur_on", value: "dissolve" },
            { displayName: Translation.tr("Glitch"), icon: "bug_report", value: "glitch" },
            { displayName: Translation.tr("Ripple"), icon: "water", value: "ripple" },
            { displayName: Translation.tr("Shatter"), icon: "broken_image", value: "shatter" },
            { displayName: Translation.tr("Colonies"), icon: "bubble_chart", value: "colonies" },
            { displayName: Translation.tr("Pop ring"), icon: "radio_button_unchecked", value: "sekaiRing" },
            { displayName: Translation.tr("Pop iris"), icon: "camera", value: "sekaiIris" },
            { displayName: Translation.tr("Pop star"), icon: "star", value: "sekaiStar" },
            { displayName: Translation.tr("Pop blocks"), icon: "grid_view", value: "sekaiBlocks" },
            { displayName: Translation.tr("Random"), icon: "shuffle", value: "random" }
        ]
    })

    function normalizeText(text) {
        return String(text ?? "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "");
    }

    function searchKeyFor(name) {
        return root.normalizeText(name.replace(/\.[^.]+$/, "")).replace(/[_\-.]+/g, " ");
    }

    function scoreToken(key, token) {
        const index = key.indexOf(token);
        if (index >= 0) {
            const wordStart = index === 0 || key.charAt(index - 1) === " ";
            return 200 + (wordStart ? 60 : 0) - Math.min(index, 40) + Math.min(token.length, 12);
        }
        if (token.length < 3) return -1;
        let position = 0;
        let gaps = 0;
        let last = -1;
        for (let i = 0; i < token.length; i++) {
            const found = key.indexOf(token.charAt(i), position);
            if (found < 0) return -1;
            if (last >= 0) gaps += found - last - 1;
            last = found;
            position = found + 1;
        }
        return Math.max(1, 100 - gaps * 3 - token.length);
    }

    function scoreItem(key, tokens) {
        let total = 0;
        for (const token of tokens) {
            const score = root.scoreToken(key, token);
            if (score < 0) return -1;
            total += score;
        }
        return total;
    }

    function rebuild() {
        const model = Wallpapers.folderModel;
        const list = [];
        for (let i = 0; i < model.count; i++) {
            if (model.get(i, "fileIsDir")) continue;
            const name = String(model.get(i, "fileName") ?? "");
            if (!Images.isValidImageByName(name.toLowerCase()) && !Wallpapers.isVideoPath(name)) continue;
            list.push({ path: FileUtils.trimFileProtocol(String(model.get(i, "filePath"))), name: name, key: root.searchKeyFor(name) });
        }
        if (JSON.stringify(list.map(item => item.path)) === JSON.stringify(root.allItems.map(item => item.path))) return;
        root.allItems = list;
    }

    function samePath(a, b) {
        return Wallpapers.normalizedPath(a) === Wallpapers.normalizedPath(b);
    }

    function randomWallpaper() {
        const pool = paths.filter(p => !Wallpapers.isVideoPath(p));
        if (pool.length === 0) return;
        const candidates = pool.filter(p => !root.samePath(p, root.desktopPath));
        const choices = candidates.length > 0 ? candidates : pool;
        const path = choices[Math.floor(Math.random() * choices.length)];
        selectedIndex = Math.max(0, paths.indexOf(path));
        grid.positionViewAtIndex(selectedIndex, GridView.Contain);
        applyTo(path);
    }

    function openSelector() {
        Wallpapers.openSelectorFor(!root.synced && root.target === "lock" ? "lockWall" : "wallpaper");
    }

    readonly property string query: pager.searchQuery ?? ""
    readonly property bool inSpicyDir: Wallpapers.isInSpicyFolder(Wallpapers.effectiveDirectory)
    readonly property bool spicyHidden: root.inSpicyDir && (!SpicyStuff.allowed || !root.spicyRevealed)
    readonly property var paths: {
        if (root.spicyHidden) return [];
        const tokens = root.normalizeText(root.query).split(/\s+/).filter(token => token.length > 0);
        if (tokens.length === 0) return root.allItems.map(item => item.path);
        const scored = [];
        for (const item of root.allItems) {
            const score = root.scoreItem(item.key, tokens);
            if (score >= 0) scored.push({ item: item, score: score });
        }
        scored.sort((a, b) => b.score - a.score || a.item.name.localeCompare(b.item.name, undefined, { numeric: true, sensitivity: "base" }));
        return scored.map(entry => entry.item.path);
    }
    readonly property string desktopPath: Wallpapers.currentDesktopWallpaper || FileUtils.trimFileProtocol(Config.options.background.wallpaperPath ?? "")
    readonly property string lockPath: FileUtils.trimFileProtocol(Config.options.background.lockWall ?? "")
    readonly property bool synced: lockPath === ""
    readonly property int columns: Math.max(2, Math.round(width / 270))

    function applyTo(path) {
        if (synced || target !== "lock") Wallpapers.apply(path);
        else Wallpapers.setLockWallpaper(path);
    }

    function activate() {
        const path = paths[selectedIndex];
        if (path) applyTo(path);
    }

    function activateLock() {
        const path = paths[selectedIndex];
        if (path && !synced) Wallpapers.setLockWallpaper(path);
    }

    function setSynced(value) {
        Wallpapers.setLockWallpaper(value ? "" : desktopPath);
    }

    function moveSelection(dx, dy) {
        const next = selectedIndex + dx + dy * columns;
        if (next < 0 || next >= paths.length) return;
        selectedIndex = next;
        grid.positionViewAtIndex(next, GridView.Contain);
    }

    readonly property int tileWidth: Math.max(1, Math.floor(width / columns) - 12)
    readonly property int tileHeight: Math.max(1, Math.round(Math.floor(width / columns) * 0.76) - 12)

    property bool ready: false

    function generateThumbnails() {
        if (Platform.isWindows) return;
        const size = Images.thumbnailSizeNameForDimensions(tileWidth, tileHeight);
        const key = Wallpapers.effectiveDirectory + "|" + size;
        const requested = root.pager.thumbsRequested;
        if (requested) {
            if (requested[key]) return;
            requested[key] = true;
        }
        Wallpapers.generateThumbnail(size);
    }

    Timer {
        interval: 60
        running: true
        onTriggered: root.ready = true
    }

    Timer {
        id: thumbTimer
        interval: 700
        running: true
        onTriggered: root.generateThumbnails()
    }

    Timer {
        id: rebuildTimer
        interval: 50
        onTriggered: root.rebuild()
    }

    Component.onCompleted: {
        Wallpapers.ensureFolderModel();
        if (Wallpapers.searchQuery !== "") Wallpapers.searchQuery = "";
        root.rebuild();
    }

    Connections {
        target: Wallpapers
        function onDirectoryChanged() {
            root.spicyRevealed = false;
            thumbTimer.restart();
        }
        function onFolderModelChanged() {
            rebuildTimer.restart();
        }
        function onSortModeChanged() {
            rebuildTimer.restart();
        }
    }

    Connections {
        target: Wallpapers.folderModel
        ignoreUnknownSignals: true
        function onCountChanged() {
            rebuildTimer.restart();
        }
        function onStatusChanged() {
            rebuildTimer.restart();
        }
        function onDataChanged() {
            rebuildTimer.restart();
        }
        function onModelReset() {
            rebuildTimer.restart();
        }
    }

    onPathsChanged: selectedIndex = Math.min(selectedIndex, Math.max(0, paths.length - 1))

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 290
            Layout.minimumHeight: 290
            Layout.maximumHeight: 290
            spacing: 12

            DashboardWallpaperPreviewCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 5
                Layout.fillHeight: true
                desktopPath: Wallpapers.stillFor(root.desktopPath)
                lockPath: Wallpapers.stillFor(root.synced ? root.desktopPath : root.lockPath)
                synced: root.synced
                target: root.target
                onTargetSelected: value => root.target = value
                onSyncToggled: value => root.setSynced(value)
                pager: root.pager
                staggerMs: root.staggerMs
                animIndex: 0
                travelX: -200
                travelY: 0
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 6
                Layout.fillHeight: true
                columns: 2
                rowSpacing: 12
                columnSpacing: 12

                DashboardWallpaperToolsCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 1
                    title: Translation.tr("Wallpaper tools")
                    pager: root.pager
                    staggerMs: root.staggerMs
                    animIndex: 1
                    travelX: 0
                    travelY: -120
                    onRandomRequested: root.randomWallpaper()
                    onFoldersRequested: root.openSelector()
                }

                DashboardSpinCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 1
                    control: root.intervalControl
                    title: Translation.tr("Change every (min)")
                    icon: "timer"
                    tileShape: MaterialShape.Shape.Gem
                    pager: root.pager
                    staggerMs: root.staggerMs
                    animIndex: 2
                    travelX: 0
                    travelY: -120
                }

                DashboardComboCard {
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    Layout.fillHeight: true
                    Layout.preferredHeight: 1
                    control: root.transitionControl
                    title: Translation.tr("Transition")
                    icon: "animation"
                    tileShape: MaterialShape.Shape.Puffy
                    pager: root.pager
                    staggerMs: root.staggerMs
                    animIndex: 3
                    travelX: 200
                    travelY: 0
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridView {
                id: grid
                anchors.fill: parent
                visible: !root.spicyHidden
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                cellWidth: Math.floor(width / root.columns)
                cellHeight: Math.round(cellWidth * 0.76)
                model: root.ready ? root.paths : []
                cacheBuffer: 0
                ScrollBar.vertical: StyledScrollBar {}

                delegate: Item {
                    id: cell
                    required property int index
                    required property string modelData

                    readonly property bool selected: root.selectedIndex === index
                    readonly property bool isDesktop: root.samePath(modelData, root.desktopPath)
                    readonly property bool isLock: root.synced ? isDesktop : root.samePath(modelData, root.lockPath)
                    readonly property bool isVideo: Wallpapers.isVideoPath(modelData)

                    width: grid.cellWidth
                    height: grid.cellHeight

                    DashboardCard {
                        id: tile
                        anchors.fill: parent
                        anchors.margins: 6
                        tint: Appearance.colors.colLayer1
                        pager: root.pager
                        staggerMs: root.staggerMs
                        animIndex: cell.index % 8
                        travelX: 0
                        travelY: 80

                        ClippingRectangle {
                            anchors.fill: parent
                            radius: tile.cardRadius
                            color: "transparent"

                            ThumbnailImage {
                                id: thumb
                                anchors.fill: parent
                                generateThumbnail: Platform.isWindows
                                sourcePath: cell.modelData
                                cache: false
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: root.tileWidth
                                sourceSize.height: root.tileHeight

                                Connections {
                                    target: Wallpapers

                                    function onThumbnailGenerated(directory) {
                                        if (thumb.status !== Image.Error) return;
                                        thumb.source = "";
                                        thumb.source = thumb.thumbnailPath;
                                    }

                                    function onThumbnailGeneratedFile(filePath) {
                                        if (thumb.status !== Image.Error) return;
                                        if (Qt.resolvedUrl(thumb.sourcePath) !== Qt.resolvedUrl(filePath)) return;
                                        thumb.source = "";
                                        thumb.source = thumb.thumbnailPath;
                                    }
                                }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: parent.height * 0.55
                                opacity: hover.containsMouse || cell.selected ? 1 : 0
                                gradient: Gradient {
                                    GradientStop { position: 0; color: "transparent" }
                                    GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.75) }
                                }

                                Behavior on opacity {
                                    NumberAnimation { duration: 150 }
                                }
                            }

                            Row {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.margins: 8
                                spacing: 6

                                Repeater {
                                    model: [
                                        { icon: "desktop_windows", on: cell.isDesktop },
                                        { icon: "lock", on: cell.isLock }
                                    ]

                                    delegate: Rectangle {
                                        required property var modelData

                                        visible: modelData.on
                                        width: 30
                                        height: 30
                                        radius: 15
                                        color: Appearance.colors.colPrimary

                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: modelData.icon
                                            iconSize: 18
                                            fill: 1
                                            color: Appearance.colors.colOnPrimary
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                visible: cell.isVideo
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 8
                                width: 30
                                height: 30
                                radius: 15
                                color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.25)

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "play_circle"
                                    iconSize: 18
                                    color: Appearance.colors.colOnLayer0
                                }
                            }

                            MouseArea {
                                id: hover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedIndex = cell.index;
                                    root.pager.forceActiveFocus();
                                    root.applyTo(cell.modelData);
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: tile.cardRadius
                            color: "transparent"
                            border.width: cell.selected ? 3 : 0
                            border.color: Appearance.colors.colPrimary
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width - 32, 420)
                visible: root.spicyHidden
                spacing: 10

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "visibility_off"
                    iconSize: 40
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("Sensitive content")
                    font.pixelSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: SpicyStuff.allowed ? Translation.tr("This folder contains spicy wallpapers.\nMake sure no one is looking before showing it.") : SpicyStuff.restriction
                    color: Appearance.colors.colSubtext
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 6
                    spacing: 8

                    DialogButton {
                        buttonText: Translation.tr("Go back")
                        onClicked: Wallpapers.setDirectory(`${Directories.pictures}/Wallpapers`)
                    }
                    DialogButton {
                        visible: SpicyStuff.allowed
                        buttonText: Translation.tr("Show")
                        onClicked: {
                            root.spicyRevealed = true;
                            root.pager.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }
}

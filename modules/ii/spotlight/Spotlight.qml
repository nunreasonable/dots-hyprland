pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.overview
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property string mode: ""
    property string query: ""
    property int currentIndex: 0
    property bool gridLayout: true
    readonly property string home: FileUtils.trimFileProtocol(Directories.home)
    property string filesFolder: root.home

    readonly property var modes: [
        { id: "apps", icon: "apps", name: Translation.tr("Applications"), placeholder: Translation.tr("Search applications...") },
        { id: "files", icon: "folder_open", name: Translation.tr("Files"), placeholder: Translation.tr("Search files...") },
        { id: "clipboard", icon: "content_paste", name: Translation.tr("Clipboard"), placeholder: Translation.tr("Search clipboard...") },
        { id: "emoji", icon: "mood", name: Translation.tr("Emojis"), placeholder: Translation.tr("Search emojis...") },
        { id: "system", icon: "power_settings_new", name: Translation.tr("System"), placeholder: Translation.tr("Search system actions (lock, reboot, shutdown)...") },
        { id: "web", icon: "travel_explore", name: Translation.tr("Web search"), placeholder: Translation.tr("Search the web...") },
    ]
    readonly property var buttonModes: root.modes.filter(m => m.id !== "web")
    readonly property var currentMode: root.modes.find(m => m.id === root.mode) ?? null
    readonly property bool expanded: root.mode !== "" || root.query !== ""
    readonly property bool hasLayoutToggle: root.mode === "apps" || root.mode === "system"

    readonly property var systemActions: [
        { name: Translation.tr("Lock"), description: Translation.tr("Lock the session"), icon: "lock", run: () => Session.lock() },
        { name: Translation.tr("Sleep"), description: Translation.tr("Suspend to RAM"), icon: "dark_mode", run: () => Session.suspend() },
        { name: Translation.tr("Restart"), description: Translation.tr("Reboot the computer"), icon: "restart_alt", run: () => Session.reboot() },
        { name: Translation.tr("Shut down"), description: Translation.tr("Power off the computer"), icon: "power_settings_new", run: () => Session.poweroff() },
        { name: Translation.tr("Log out"), description: Translation.tr("Close all apps and end the session"), icon: "logout", run: () => Session.logout() },
        { name: Translation.tr("Hibernate"), description: Translation.tr("Save the session to disk and power off"), icon: "downloading", run: () => Session.hibernate() },
        { name: Translation.tr("Reload shell"), description: Translation.tr("Restart Quickshell widgets"), icon: "refresh", run: () => Quickshell.reload(true) },
        { name: Translation.tr("UEFI settings"), description: Translation.tr("Reboot into firmware setup"), icon: "settings_applications", run: () => Session.rebootToFirmware() },
        { name: Translation.tr("Task manager"), description: Translation.tr("Open the task manager"), icon: "browse_activity", run: () => Session.launchTaskManager() },
    ]

    readonly property var items: {
        const q = root.query.trim();
        switch (root.mode) {
        case "":
        case "clipboard":
            return LauncherSearch.results;
        case "apps":
            if (q === "")
                return [...AppSearch.list].sort((a, b) => a.name.localeCompare(b.name));
            return AppSearch.fuzzyQuery(q);
        case "emoji":
            return (q === "" ? Emojis.list : Emojis.fuzzyQuery(q)).slice(0, 400);
        case "system":
            return root.systemActions.filter(a => q === "" || `${a.name} ${a.description}`.toLowerCase().includes(q.toLowerCase()));
        case "files":
            return q === "" ? fileBrowser.entries : fileSearch.results;
        case "web":
            return q === "" ? [] : [q];
        }
        return [];
    }
    readonly property int columns: {
        if (root.mode === "apps" && root.gridLayout) return 7;
        if (root.mode === "system" && root.gridLayout) return 4;
        if (root.mode === "emoji") return 10;
        return 1;
    }

    onItemsChanged: root.currentIndex = 0

    function open(modeId) {
        GlobalStates.overviewOpen = false;
        GlobalStates.spotlightMode = modeId ?? "";
        if (GlobalStates.spotlightOpen)
            root.setMode(GlobalStates.spotlightMode);
        else
            GlobalStates.spotlightOpen = true;
    }

    function close() {
        GlobalStates.spotlightOpen = false;
    }

    function toggle(modeId) {
        if (GlobalStates.spotlightOpen && (modeId === undefined || modeId === root.mode)) {
            root.close();
            return;
        }
        root.open(modeId);
    }

    function setMode(modeId) {
        root.mode = modeId;
        GlobalStates.spotlightMode = modeId;
        root.query = "";
        root.currentIndex = 0;
        root.filesFolder = root.home;
        if (modeId === "clipboard") Cliphist.refresh();
        if (modeId === "files" && Platform.isWindows && WindowsNative.fileIndex) WindowsNative.fileIndex.ensureIndexed();
        if (modeId === "emoji" && Emojis.list.length === 0) Emojis.load();
        if (searchField) {
            searchField.text = "";
            searchField.forceActiveFocus();
        }
    }

    function prefixMode(text) {
        const p = Config.options.search.prefix;
        const map = [[p.app, "apps"], [p.emojis, "emoji"], [p.clipboard, "clipboard"], [p.webSearch, "web"], ["~", "files"], ["!", "system"]];
        for (const pair of map) {
            if (pair[0] && text.startsWith(pair[0]))
                return { id: pair[1], rest: text.slice(pair[0].length) };
        }
        return null;
    }

    function cycleMode(step) {
        const ids = ["", ...root.modes.map(m => m.id)];
        const next = (ids.indexOf(root.mode) + step + ids.length) % ids.length;
        root.setMode(ids[next]);
    }

    function launchApp(entry) {
        root.close();
        if (!entry.runInTerminal)
            entry.execute();
        else
            Quickshell.execDetached(["bash", "-c", `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(entry.command.join(' '))}'`]);
    }

    function fileUrl(path) {
        return /^[A-Za-z]:/.test(path) ? "file:///" + path : "file://" + path;
    }

    function openFile(item) {
        if (item.isDir) {
            root.filesFolder = item.path;
            root.query = "";
            searchField.text = "";
            root.currentIndex = 0;
            return;
        }
        root.close();
        Qt.openUrlExternally(root.fileUrl(item.path));
    }

    function webSearch(text) {
        let url = Config.options.search.engineBaseUrl + text;
        for (const site of Config.options.search.excludedSites)
            url += ` -site:${site}`;
        root.close();
        Qt.openUrlExternally(url);
    }

    function activate(index) {
        const item = root.items[index];
        if (item === undefined) return;
        switch (root.mode) {
        case "":
        case "clipboard":
            root.close();
            item.execute();
            return;
        case "apps":
            root.launchApp(item);
            return;
        case "emoji":
            Quickshell.clipboardText = item.match(/^\s*(\S+)/)?.[1] ?? "";
            root.close();
            return;
        case "system":
            root.close();
            item.run();
            return;
        case "files":
            root.openFile(item);
            return;
        case "web":
            root.webSearch(item);
            return;
        }
    }

    function moveSelection(delta) {
        if (root.items.length === 0) return;
        root.currentIndex = Math.max(0, Math.min(root.items.length - 1, root.currentIndex + delta));
    }

    function goUp() {
        if (root.mode === "files" && root.filesFolder !== root.home && root.filesFolder !== "/") {
            const parent = root.filesFolder.replace(/\/[^\/]+\/?$/, "");
            root.filesFolder = parent === "" ? "/" : /^[A-Za-z]:$/.test(parent) ? parent + "/" : parent;
            root.currentIndex = 0;
            return true;
        }
        if (root.mode !== "") {
            root.setMode("");
            return true;
        }
        return false;
    }

    function fileSubtitle(item) {
        const when = new Date(item.modified * 1000).toLocaleString(Qt.locale(), Locale.ShortFormat);
        const parent = item.path.replace(/\/[^\/]*$/, "").replace(root.home, "~");
        if (item.isDir)
            return `${Translation.tr("Folder")} · ${when} · ${parent}`;
        const ext = item.name.includes(".") ? item.name.split(".").pop().toUpperCase() : Translation.tr("File");
        return `${ext} · ${root.formatSize(item.size)} · ${when} · ${parent}`;
    }

    function formatSize(bytes) {
        if (bytes < 1024) return `${bytes} B`;
        const units = ["KB", "MB", "GB", "TB"];
        let value = bytes / 1024;
        let unit = 0;
        while (value >= 1024 && unit < units.length - 1) {
            value /= 1024;
            unit++;
        }
        return `${value.toFixed(value < 10 ? 1 : 0)} ${units[unit]}`;
    }

    function fileSymbol(item) {
        if (item.isDir) return "folder";
        const ext = item.name.split(".").pop().toLowerCase();
        if (["png", "jpg", "jpeg", "webp", "gif", "bmp", "svg", "avif"].includes(ext)) return "image";
        if (["mp3", "flac", "ogg", "opus", "wav", "m4a"].includes(ext)) return "music_note";
        if (["mp4", "mkv", "webm", "mov", "avi"].includes(ext)) return "movie";
        if (["pdf"].includes(ext)) return "picture_as_pdf";
        if (["zip", "tar", "gz", "xz", "zst", "7z", "rar"].includes(ext)) return "folder_zip";
        if (["sh", "py", "js", "qml", "rs", "c", "cpp", "h", "lua", "json", "toml", "yaml", "yml"].includes(ext)) return "code";
        return "draft";
    }

    function isImage(item) {
        return !item.isDir && ["png", "jpg", "jpeg", "webp", "gif", "bmp", "avif"].includes(item.name.split(".").pop().toLowerCase());
    }

    property var searchField: null

    Binding {
        target: LauncherSearch
        property: "query"
        value: root.mode === "clipboard" ? Config.options.search.prefix.clipboard + root.query : root.query
        when: GlobalStates.spotlightOpen && (root.mode === "" || root.mode === "clipboard")
    }

    QtObject {
        id: fileBrowser
        readonly property var entries: {
            if (folderModel.status !== FolderListModel.Ready || folderModel.folder.toString() === "")
                return [];
            const out = [];
            for (let i = 0; i < folderModel.count; i++) {
                out.push({
                    name: folderModel.get(i, "fileName"),
                    path: folderModel.get(i, "filePath"),
                    isDir: folderModel.get(i, "fileIsDir"),
                    size: folderModel.get(i, "fileSize"),
                    modified: folderModel.get(i, "fileModified").getTime() / 1000
                });
            }
            return out;
        }
    }

    FolderListModel {
        id: folderModel
        folder: root.fileUrl(root.filesFolder)
        showDirsFirst: true
        showHidden: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
    }

    QtObject {
        id: fileSearch
        property var results: []
    }

    Timer {
        id: fileSearchDebounce
        interval: 200
        onTriggered: {
            if (root.mode !== "files" || root.query.trim() === "") return;
            if (Platform.isWindows) {
                fileSearch.results = WindowsNative.fileIndex ? WindowsNative.fileIndex.search(root.query.trim(), 60) : [];
                return;
            }
            fileSearchProc.running = false;
            fileSearchProc.command = ["bash", "-c", `
q="$1"; h="$2"
{ plocate -i -b -l 600 -- "$q" 2>/dev/null || find "$h" -maxdepth 6 -not -path '*/.*' -iname "*$q*" 2>/dev/null; } \\
  | grep -F -- "$h/" | grep -v '/\\.' | head -n 80 \\
  | while IFS= read -r p; do stat -c $'%n\\x1f%s\\x1f%Y\\x1f%F' -- "$p" 2>/dev/null; done
`, "spotlight", root.query.trim(), root.home];
            fileSearchProc.running = true;
        }
    }

    Process {
        id: fileSearchProc
        stdout: StdioCollector {
            id: fileSearchCollector
            onStreamFinished: {
                const q = root.query.trim().toLowerCase();
                const results = fileSearchCollector.text.split("\n").filter(l => l.length > 0).map(line => {
                    const f = line.split("\x1f");
                    const path = f[0];
                    return {
                        name: path.split("/").pop(),
                        path: path,
                        isDir: (f[3] ?? "").startsWith("directory"),
                        size: Number(f[1]) || 0,
                        modified: Number(f[2]) || 0
                    };
                });
                const rank = item => (item.name.toLowerCase().startsWith(q) ? 0 : 1) * 1000 + item.path.split("/").length;
                fileSearch.results = results.sort((a, b) => rank(a) - rank(b)).slice(0, 60);
            }
        }
    }

    onQueryChanged: {
        if (root.mode === "files") {
            if (!Platform.isWindows)
                fileSearch.results = [];
            fileSearchDebounce.restart();
        }
    }

    Connections {
        target: Platform.isWindows ? WindowsNative.fileIndex : null
        function onIndexChanged() {
            if (root.mode === "files" && root.query.trim() !== "")
                fileSearchDebounce.restart();
        }
    }

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.spotlightOpen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:spotlight"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.spotlightOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: Region {
            item: content
        }

        Connections {
            target: GlobalStates
            function onSpotlightModeChanged() {
                if (GlobalStates.spotlightOpen && GlobalStates.spotlightMode !== root.mode)
                    root.setMode(GlobalStates.spotlightMode);
            }
            function onSpotlightOpenChanged() {
                if (GlobalStates.spotlightOpen) {
                    GlobalStates.overviewOpen = false;
                    root.setMode(GlobalStates.spotlightMode);
                    GlobalFocusGrab.addDismissable(panelWindow);
                    Qt.callLater(() => searchInput.forceActiveFocus());
                } else {
                    GlobalFocusGrab.removeDismissable(panelWindow);
                    root.mode = "";
                    root.query = "";
                    searchInput.text = "";
                }
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                root.close();
            }
        }

        Item {
            id: content
            readonly property real maxWidth: Math.min(880, panelWindow.width - 80)
            readonly property real bodyMaxHeight: Math.min(500, panelWindow.height * 0.55)
            x: (panelWindow.width - width) / 2
            y: Math.round(panelWindow.height * 0.18)
            width: root.expanded ? content.maxWidth : panel.pillWidth + 10 + idleRow.implicitWidth
            height: panel.height
            opacity: GlobalStates.spotlightOpen ? 1 : 0
            scale: GlobalStates.spotlightOpen ? 1 : 0.96

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Behavior on scale {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            StyledRectangularShadow {
                target: panel
            }

            Rectangle {
                id: panel
                width: root.expanded ? content.width : pillWidth
                readonly property real pillWidth: 600
                height: header.height + (root.expanded ? body.height + 8 : 0)
                radius: root.expanded ? Appearance.rounding.large : height / 2
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                clip: true

                Behavior on width {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on height {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                RowLayout {
                    id: header
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        leftMargin: 16
                        rightMargin: 12
                    }
                    height: 52
                    spacing: 8

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignVCenter
                        text: "search"
                        iconSize: Appearance.font.pixelSize.huge
                        color: Appearance.colors.colOnLayer0
                    }

                    Rectangle {
                        visible: root.currentMode !== null
                        Layout.alignment: Qt.AlignVCenter
                        implicitHeight: 28
                        implicitWidth: chipRow.implicitWidth + 20
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colSecondaryContainer

                        RowLayout {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol {
                                text: root.currentMode?.icon ?? ""
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                            StyledText {
                                text: root.currentMode?.name ?? ""
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                            MaterialSymbol {
                                text: "close"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnSecondaryContainer
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setMode("")
                                }
                            }
                        }
                    }

                    RippleButton {
                        visible: root.hasLayoutToggle
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 32
                        implicitHeight: 32
                        buttonRadius: Appearance.rounding.full
                        onClicked: {
                            root.gridLayout = !root.gridLayout;
                            searchInput.forceActiveFocus();
                        }
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            text: root.gridLayout ? "view_list" : "grid_view"
                            iconSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colSubtext
                        }
                    }

                    TextField {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        background: null
                        padding: 4
                        color: Appearance.colors.colOnLayer0
                        placeholderTextColor: Appearance.colors.colSubtext
                        placeholderText: root.currentMode?.placeholder ?? Translation.tr("Spotlight search")
                        selectedTextColor: Appearance.colors.colOnSecondaryContainer
                        selectionColor: Appearance.colors.colSecondaryContainer
                        renderType: Text.NativeRendering
                        font {
                            family: Appearance.font.family.main
                            pixelSize: Appearance.font.pixelSize.normal
                            variableAxes: Appearance.font.variableAxes.main
                        }
                        focus: GlobalStates.spotlightOpen
                        Component.onCompleted: root.searchField = searchInput

                        onTextChanged: {
                            if (root.mode === "") {
                                const pm = root.prefixMode(text);
                                if (pm) {
                                    root.setMode(pm.id);
                                    searchInput.text = pm.rest;
                                    return;
                                }
                            }
                            root.query = text;
                        }

                        onAccepted: root.activate(root.currentIndex)

                        Keys.onPressed: event => {
                            const grid = root.columns > 1;
                            if (event.key === Qt.Key_Escape) {
                                root.close();
                            } else if (event.key === Qt.Key_Down) {
                                root.moveSelection(root.columns);
                            } else if (event.key === Qt.Key_Up) {
                                root.moveSelection(-root.columns);
                            } else if (event.key === Qt.Key_Right && grid) {
                                root.moveSelection(1);
                            } else if (event.key === Qt.Key_Left && grid) {
                                root.moveSelection(-1);
                            } else if (event.key === Qt.Key_PageDown) {
                                root.moveSelection(root.columns * 5);
                            } else if (event.key === Qt.Key_PageUp) {
                                root.moveSelection(-root.columns * 5);
                            } else if (event.key === Qt.Key_Tab) {
                                root.cycleMode(1);
                            } else if (event.key === Qt.Key_Backtab) {
                                root.cycleMode(-1);
                            } else if (event.key === Qt.Key_Backspace && searchInput.text === "" && root.goUp()) {
                            } else {
                                return;
                            }
                            event.accepted = true;
                        }
                    }
                }

                Item {
                    id: body
                    visible: root.expanded
                    anchors {
                        top: header.bottom
                        left: parent.left
                        right: parent.right
                        margins: 8
                        topMargin: 0
                    }
                    height: {
                        if (root.mode === "web") return 56;
                        if (root.mode === "" ) return Math.min(content.bodyMaxHeight, Math.max(56, resultsList.contentHeight));
                        return content.bodyMaxHeight;
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 6

                        RowLayout {
                            visible: root.mode === "files"
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: [
                                    { name: Translation.tr("Home"), icon: "home", path: root.home },
                                    { name: Translation.tr("Downloads"), icon: "download", path: FileUtils.trimFileProtocol(Directories.downloads) },
                                    { name: Translation.tr("Documents"), icon: "description", path: FileUtils.trimFileProtocol(Directories.documents) },
                                    { name: Translation.tr("Pictures"), icon: "image", path: FileUtils.trimFileProtocol(Directories.pictures) },
                                    { name: Translation.tr("Music"), icon: "music_note", path: FileUtils.trimFileProtocol(Directories.music) },
                                    { name: Translation.tr("Videos"), icon: "movie", path: FileUtils.trimFileProtocol(Directories.videos) },
                                ]
                                delegate: RippleButton {
                                    id: folderChip
                                    required property var modelData
                                    readonly property bool current: root.filesFolder === modelData.path
                                    implicitHeight: 30
                                    implicitWidth: folderChipRow.implicitWidth + 20
                                    buttonRadius: Appearance.rounding.full
                                    colBackground: current ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer1
                                    colBackgroundHover: current ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colLayer1Hover
                                    onClicked: {
                                        root.filesFolder = modelData.path;
                                        root.query = "";
                                        searchInput.text = "";
                                        searchInput.forceActiveFocus();
                                    }
                                    contentItem: RowLayout {
                                        id: folderChipRow
                                        anchors.centerIn: parent
                                        spacing: 4
                                        MaterialSymbol {
                                            text: folderChip.modelData.icon
                                            iconSize: Appearance.font.pixelSize.normal
                                            color: folderChip.current ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                                        }
                                        StyledText {
                                            text: folderChip.modelData.name
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: folderChip.current ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                                        }
                                    }
                                }
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            StyledText {
                                visible: root.query === ""
                                text: root.filesFolder.replace(root.home, "~")
                                elide: Text.ElideLeft
                                Layout.maximumWidth: 220
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                            }
                        }

                        ListView {
                            id: resultsList
                            visible: root.mode === "" || root.mode === "clipboard"
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 2
                            model: visible ? root.items : []
                            currentIndex: root.currentIndex
                            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                            delegate: SearchItem {
                                required property var modelData
                                required property int index
                                width: ListView.view.width
                                entry: modelData
                                query: root.mode === "clipboard" ? "" : root.query
                                focus: index === root.currentIndex
                                horizontalMargin: 0
                                onClicked: root.close()
                            }
                        }

                        GridView {
                            id: tileGrid
                            visible: (root.mode === "apps" || root.mode === "system") && root.gridLayout || root.mode === "emoji"
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            cellWidth: Math.floor(width / root.columns)
                            cellHeight: root.mode === "emoji" ? cellWidth : root.mode === "system" ? 96 : 104
                            model: visible ? root.items : []
                            currentIndex: root.currentIndex
                            onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
                            boundsBehavior: Flickable.StopAtBounds
                            delegate: Item {
                                id: tileCell
                                required property var modelData
                                required property int index
                                width: GridView.view.cellWidth
                                height: GridView.view.cellHeight

                                SpotlightTile {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    selected: tileCell.index === root.currentIndex
                                    caption: root.mode === "emoji" ? "" : (tileCell.modelData.name ?? "")
                                    bigText: root.mode === "emoji" ? (tileCell.modelData.match(/^\s*(\S+)/)?.[1] ?? "") : ""
                                    symbol: root.mode === "system" ? tileCell.modelData.icon : ""
                                    iconSource: root.mode === "apps" ? Quickshell.iconPath(AppSearch.guessIcon(tileCell.modelData.icon), "image-missing") : ""
                                    onClicked: root.activate(tileCell.index)
                                    onHoveredChanged: if (hovered && root.mode === "emoji") root.currentIndex = tileCell.index
                                }
                            }
                        }

                        ListView {
                            id: rowList
                            visible: (root.mode === "apps" || root.mode === "system") && !root.gridLayout || root.mode === "files" || root.mode === "web"
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 2
                            model: visible ? root.items : []
                            currentIndex: root.currentIndex
                            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                            boundsBehavior: Flickable.StopAtBounds
                            delegate: SpotlightRow {
                                id: row
                                required property var modelData
                                required property int index
                                width: ListView.view.width
                                selected: row.index === root.currentIndex
                                title: {
                                    if (root.mode === "web") return Translation.tr("Search the web for \"%1\"").arg(row.modelData);
                                    return row.modelData.name ?? "";
                                }
                                subtitle: {
                                    if (root.mode === "apps") return row.modelData.comment || row.modelData.genericName || "";
                                    if (root.mode === "system") return row.modelData.description;
                                    if (root.mode === "files") return root.fileSubtitle(row.modelData);
                                    return Config.options.search.engineBaseUrl.replace(/^https?:\/\//, "").split("/")[0];
                                }
                                symbol: {
                                    if (root.mode === "system") return row.modelData.icon;
                                    if (root.mode === "files") return root.fileSymbol(row.modelData);
                                    return "travel_explore";
                                }
                                iconSource: root.mode === "apps" ? Quickshell.iconPath(AppSearch.guessIcon(row.modelData.icon), "image-missing") : ""
                                imageSource: root.mode === "files" && root.isImage(row.modelData) ? root.fileUrl(row.modelData.path) : ""
                                trailingSymbol: root.mode === "files" && row.modelData.isDir ? "open_in_new" : ""
                                onTrailingClicked: {
                                    root.close();
                                    Qt.openUrlExternally(root.fileUrl(row.modelData.path));
                                }
                                onClicked: root.activate(row.index)
                            }
                        }

                        StyledText {
                            visible: root.mode === "emoji" && root.items.length > 0
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            text: root.items[root.currentIndex] ?? ""
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }

                        StyledText {
                            visible: root.mode !== "" && root.mode !== "web" && root.items.length === 0
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: root.mode === "files" && root.query !== "" && (fileSearchProc.running || (Platform.isWindows && (WindowsNative.fileIndex?.indexing ?? false))) ? Translation.tr("Searching...") : Translation.tr("Nothing here")
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }

            Row {
                id: idleRow
                visible: !root.expanded
                spacing: 10
                anchors.verticalCenter: panel.verticalCenter
                x: panel.width + 10
                opacity: root.expanded ? 0 : 1

                Repeater {
                    model: root.buttonModes
                    delegate: SpotlightModeButton {
                        required property var modelData
                        symbol: modelData.icon
                        tooltip: modelData.name
                        onClicked: root.open(modelData.id)
                    }
                }

            }
        }
    }

    GlobalShortcut {
        name: "spotlightToggle"
        description: "Toggles the spotlight search"
        onPressed: root.toggle()
    }

    IpcHandler {
        target: "spotlight"

        function toggle(): void {
            root.toggle();
        }
        function open(): void {
            root.open("");
        }
        function close(): void {
            root.close();
        }
        function openMode(mode: string): void {
            root.open(mode);
        }
    }
}

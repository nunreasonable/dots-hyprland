import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    signal pageExitRequested()
    signal closeRequested()

    property bool windowControls: false
    property int currentPage: GlobalStates.dashboardPage
    property int pendingPage: GlobalStates.dashboardPage
    property int staggerMs: 45 / Math.max(0.5, Config.options.settings.animationSpeed ?? 1)
    property bool searchOpen: false
    property var thumbsRequested: ({})
    property string searchQuery: ""
    property bool editingText: false
    readonly property int homePage: 0
    readonly property int wallpapersPage: 1
    readonly property int presetsPage: 2
    readonly property int mediaPage: 3
    readonly property int settingsPage: 4
    readonly property bool mediaVisible: currentPage === mediaPage && mediaState.displayedArtFilePath !== ""
    readonly property var mediaColors: mediaVisible ? mediaState.blendedColors : Appearance.colors
    readonly property bool isSearchablePage: currentPage === settingsPage || currentPage === wallpapersPage || currentPage === presetsPage

    QtObject {
        id: ui

        readonly property var blended: mediaState.blendedColors
        readonly property bool media: root.mediaVisible && root.pendingPage === root.mediaPage

        readonly property color surface: media ? blended.colLayer1 : Appearance.colors.colLayer1
        readonly property color fgSurface: media ? blended.colOnLayer1 : Appearance.colors.colOnLayer1
        readonly property color subtext: media ? blended.colSubtext : Appearance.colors.colSubtext
        readonly property color hover: media ? blended.colSecondaryContainerHover : Appearance.colors.colLayer1Hover
        readonly property color accent: media ? blended.colPrimary : Appearance.colors.colPrimary
        readonly property color accentHover: media ? blended.colPrimaryHover : Appearance.colors.colPrimaryHover
        readonly property color accentActive: media ? blended.colPrimaryActive : Appearance.colors.colPrimaryActive
        readonly property color fgAccent: media ? blended.colOnPrimary : Appearance.colors.colOnPrimary
    }

    focus: true

    DashboardMediaState {
        id: mediaState
    }

    Component.onCompleted: {
        Wallpapers.load();
        forceActiveFocus();
    }

    function focusContent() {
        root.forceActiveFocus();
    }

    function goToTarget(target) {
        if (root.pendingPage !== root.settingsPage)
            root.goToPage(root.settingsPage);
        root.pendingTarget = target;
        Qt.callLater(root.flushTarget);
    }

    property var pendingTarget: null

    function flushTarget() {
        if (!root.pendingTarget || root.currentPage !== root.settingsPage || !settingsLoader.item)
            return;
        const target = root.pendingTarget;
        root.pendingTarget = null;
        settingsLoader.item.openClassic(target);
    }

    Keys.onPressed: event => {
        if (editingText) {
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Escape) {
            if (currentPage === settingsPage && settingsLoader.item?.classicOpen)
                settingsLoader.item.closeClassic();
            else if (currentPage === presetsPage && presetsLoader.item?.selected)
                presetsLoader.item.back();
            else
                root.closeRequested();
        } else if (currentPage === mediaPage && event.key === Qt.Key_Left) {
            mediaState.player?.previous();
        } else if (currentPage === mediaPage && event.key === Qt.Key_Right) {
            mediaState.player?.next();
        } else if (currentPage === mediaPage && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            mediaState.player?.togglePlaying();
        } else if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
            if (searchOpen)
                closeSearch();
            else
                openSearch();
        } else if (currentPage === settingsPage && event.key === Qt.Key_Slash) {
            openSearch();
        } else if (currentPage === wallpapersPage && (event.key === Qt.Key_Left || event.key === Qt.Key_Right || event.key === Qt.Key_Up || event.key === Qt.Key_Down)) {
            const dx = event.key === Qt.Key_Left ? -1 : event.key === Qt.Key_Right ? 1 : 0;
            const dy = event.key === Qt.Key_Up ? -1 : event.key === Qt.Key_Down ? 1 : 0;
            wallpapersLoader.item?.moveSelection(dx, dy);
        } else if (currentPage === wallpapersPage && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) {
            wallpapersLoader.item?.activate();
        } else if (currentPage === wallpapersPage && event.key === Qt.Key_L && wallpapersLoader.item && !wallpapersLoader.item.synced) {
            wallpapersLoader.item.activateLock();
        } else if (currentPage === settingsPage && (event.key === Qt.Key_Up || event.key === Qt.Key_Down)) {
            settingsLoader.item?.scrollBy(event.key === Qt.Key_Down ? 120 : -120);
        } else if (currentPage === settingsPage && (event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown)) {
            settingsLoader.item?.scrollBy(event.key === Qt.Key_PageDown ? 420 : -420);
        } else if (event.key === Qt.Key_Tab) {
            goToPage((pendingPage + 1) % pageNames.length);
        } else if (event.key === Qt.Key_Backtab) {
            goToPage((pendingPage - 1 + pageNames.length) % pageNames.length);
        } else if (currentPage === homePage && homeLoader.item?.typing) {
            return;
        } else if ((isSearchablePage || currentPage === homePage) && typedCharacter(event)) {
            typeIntoSearch(event.text);
            if (currentPage === homePage)
                goToPage(settingsPage);
        } else {
            return;
        }
        event.accepted = true;
    }

    readonly property var pageNames: [
        { name: Translation.tr("Start"), icon: "home" },
        { name: Translation.tr("Wallpapers"), icon: "wallpaper" },
        { name: Translation.tr("Presets"), icon: "hallway" },
        { name: Translation.tr("Media"), icon: "play_circle" },
        { name: Translation.tr("Settings"), icon: "settings" }
    ]

    function scrollSettingsBy(delta) {
        settingsLoader.item?.scrollBy(delta);
    }

    function typedCharacter(event) {
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
            return false;
        return event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127;
    }

    function typeIntoSearch(character) {
        const previous = searchOpen ? searchInput.text : "";
        searchOpen = true;
        searchInput.text = previous + character;
        searchInput.cursorPosition = searchInput.text.length;
        Qt.callLater(() => searchInput.forceActiveFocus());
    }

    function openSearch() {
        searchOpen = true;
        if (pendingPage !== settingsPage && pendingPage !== wallpapersPage && pendingPage !== presetsPage)
            goToPage(settingsPage);
        Qt.callLater(() => searchInput.forceActiveFocus());
    }

    function closeSearch() {
        searchInput.text = "";
        searchOpen = false;
        forceActiveFocus();
    }

    function goToPage(index) {
        if (index === currentPage || switchTimer.running)
            return;
        if (currentPage !== homePage && searchInput.text !== "")
            searchInput.text = "";
        pendingPage = index;
        pageExitRequested();
        forceActiveFocus();
        switchTimer.restart();
    }

    Timer {
        id: switchTimer
        interval: (320 / Math.max(0.5, Config.options.settings.animationSpeed ?? 1)) + 6 * (root.staggerMs - 4)
        onTriggered: {
            root.currentPage = root.pendingPage;
            GlobalStates.dashboardPage = root.currentPage;
            Qt.callLater(root.flushTarget);
        }
    }

    Image {
        id: dashboardArtSource
        anchors.fill: parent
        source: mediaState.displayedArtFilePath
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize: Qt.size(800, 800)
        visible: false
    }

    FastBlur {
        id: dashboardArt
        anchors.fill: parent
        source: dashboardArtSource
        radius: 64
        opacity: root.mediaVisible ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: mediaState.blendedColors.colLayer0
        opacity: root.mediaVisible ? 0.6 : 0
        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Item {
            id: headerBar
            Layout.fillWidth: true
            implicitHeight: 56

            MouseArea {
                anchors.fill: parent
                visible: root.windowControls
                acceptedButtons: Qt.LeftButton
                onPressed: root.Window.window?.startSystemMove()
                onDoubleClicked: {
                    const backingWindow = root.Window.window;
                    if (!backingWindow)
                        return;
                    if (backingWindow.visibility === Window.Maximized)
                        backingWindow.showNormal();
                    else
                        backingWindow.showMaximized();
                }
            }

            Rectangle {
                id: distroPill
                readonly property real fullWidth: (SystemInfo.logo !== "" ? 30 : 0) + distroName.implicitWidth + 28
                readonly property real searchRoom: headerBar.width - navToolbar.width - fullWidth - 24 - headerActions.othersWidth
                readonly property bool compact: root.searchOpen && searchRoom < 120
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                radius: height / 2
                color: ui.surface
                border.width: 2
                border.color: ui.accent
                implicitHeight: 44
                implicitWidth: compact ? 44 : fullWidth

                RowLayout {
                    id: distroPillRow
                    anchors.centerIn: parent
                    spacing: 8

                    IconImage {
                        implicitSize: 22
                        source: Quickshell.iconPath(SystemInfo.logo, true)
                        visible: SystemInfo.logo !== ""
                    }

                    StyledText {
                        id: distroName
                        visible: !distroPill.compact
                        text: SystemInfo.distroName
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: ui.fgSurface
                    }
                }
            }

            Toolbar {
                id: navToolbar
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(distroPill.width + 12, Math.min((headerBar.width - width) / 2, headerActions.x - width - 12))
                colBackground: ui.surface
                outerShadow: true

                Repeater {
                    model: root.pageNames

                    delegate: RippleButton {
                        id: navBtn
                        required property int index
                        required property var modelData

                        implicitHeight: 38
                        implicitWidth: navContentRow.implicitWidth + 28
                        buttonRadius: height / 2
                        toggled: root.pendingPage === index
                        onClicked: root.goToPage(index)
                        colBackgroundToggled: ui.accent
                        colBackgroundToggledHover: ui.accentHover
                        colRippleToggled: ui.accentActive
                        colBackgroundHover: ui.hover

                        contentItem: RowLayout {
                            id: navContentRow
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialSymbol {
                                text: navBtn.modelData.icon
                                iconSize: Appearance.font.pixelSize.larger
                                color: navBtn.toggled ? ui.fgAccent : ui.fgSurface
                                fill: navBtn.toggled ? 1 : 0
                            }

                            StyledText {
                                text: navBtn.modelData.name
                                color: navBtn.toggled ? ui.fgAccent : ui.fgSurface
                                visible: navBtn.toggled
                            }
                        }
                    }
                }
            }

            RowLayout {
                id: headerActions
                readonly property real othersWidth: (root.windowControls ? 4 : 2) * 54
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Rectangle {
                    id: searchPill
                    implicitHeight: 44
                    implicitWidth: root.searchOpen ? Math.max(100, Math.min(220, distroPill.searchRoom + (distroPill.compact ? distroPill.fullWidth - 44 : 0))) : 44
                    radius: height / 2
                    color: ui.surface
                    border.width: searchInput.activeFocus ? 2 : 0
                    border.color: ui.accent
                    clip: true

                    Behavior on implicitWidth {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }

                    RippleButton {
                        id: searchButton
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 44
                        implicitHeight: 44
                        buttonRadius: 22
                        colBackground: "transparent"
                        onClicked: root.searchOpen ? root.closeSearch() : root.openSearch()
                        contentItem: Item {
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "search"
                                iconSize: Appearance.font.pixelSize.larger
                                color: ui.fgSurface
                            }
                        }
                    }

                    TextInput {
                        id: searchInput
                        anchors.left: searchButton.right
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.searchOpen
                        clip: true
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.family: Appearance.font.family.main
                        color: ui.fgSurface
                        selectionColor: ui.accent
                        onTextChanged: root.searchQuery = text
                        Keys.onEscapePressed: {
                            if (text !== "")
                                text = "";
                            else
                                root.closeSearch();
                        }
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
                                root.closeSearch();
                                event.accepted = true;
                            }
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: searchInput.text === ""
                            text: root.pendingPage === root.presetsPage ? Translation.tr("Search presets") : root.pendingPage === root.wallpapersPage ? Translation.tr("Search wallpapers") : Translation.tr("Search settings")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: ui.subtext
                        }
                    }
                }

                RippleButton {
                    implicitWidth: 44
                    implicitHeight: 44
                    buttonRadius: height / 2
                    colBackground: ui.surface
                    colBackgroundHover: ui.hover
                    onClicked: GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
                    contentItem: Item {
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "notifications"
                            iconSize: Appearance.font.pixelSize.larger
                            color: ui.fgSurface
                        }

                        Rectangle {
                            visible: Notifications.list.length > 0
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: -2
                            anchors.rightMargin: -4
                            radius: height / 2
                            color: Appearance.colors.colError
                            implicitHeight: 16
                            implicitWidth: Math.max(16, badgeText.implicitWidth + 8)

                            StyledText {
                                id: badgeText
                                anchors.centerIn: parent
                                text: Notifications.list.length > 9 ? "9+" : Notifications.list.length
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnError
                            }
                        }
                    }
                }

                Repeater {
                    model: root.windowControls ? ["minimize", "maximize"] : []

                    delegate: RippleButton {
                        id: windowButton
                        required property string modelData
                        readonly property bool maximized: root.Window.window?.visibility === Window.Maximized

                        implicitWidth: 44
                        implicitHeight: 44
                        buttonRadius: height / 2
                        colBackground: ui.surface
                        colBackgroundHover: ui.hover
                        onClicked: {
                            const backingWindow = root.Window.window;
                            if (!backingWindow)
                                return;
                            if (windowButton.modelData === "minimize")
                                backingWindow.showMinimized();
                            else if (windowButton.maximized)
                                backingWindow.showNormal();
                            else
                                backingWindow.showMaximized();
                        }
                        contentItem: Item {
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: windowButton.modelData === "minimize" ? "minimize" : windowButton.maximized ? "filter_none" : "crop_square"
                                iconSize: Appearance.font.pixelSize.larger
                                color: ui.fgSurface
                            }
                        }
                    }
                }

                Item {
                    id: avatarRect
                    implicitWidth: 44
                    implicitHeight: 44

                    UserAvatar {
                        anchors.fill: parent
                        iconSize: 30
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Qt.rgba(0, 0, 0, 0.55)
                        opacity: avatarArea.containsMouse ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 24
                            color: "white"
                        }
                    }

                    MouseArea {
                        id: avatarArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }

                    StyledToolTip {
                        extraVisibleCondition: avatarArea.containsMouse
                        text: Translation.tr("Close")
                    }
                }
            }
        }

        Loader {
            id: presetsLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: active
            active: root.currentPage === root.presetsPage

            sourceComponent: DashboardPresetsPage {
                pager: root
                staggerMs: root.staggerMs
            }
        }

        Loader {
            id: wallpapersLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: active
            active: root.currentPage === root.wallpapersPage

            sourceComponent: DashboardWallpapersPage {
                pager: root
                staggerMs: root.staggerMs
            }
        }

        Loader {
            id: settingsLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: active
            active: root.currentPage === root.settingsPage
            onLoaded: Qt.callLater(root.flushTarget)

            sourceComponent: DashboardSettingsPage {
                pager: root
                staggerMs: root.staggerMs
            }
        }

        Loader {
            id: homeLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: active
            active: root.currentPage === root.homePage

            sourceComponent: DashboardHomePage {
                pager: root
                staggerMs: root.staggerMs
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: active
            active: root.currentPage === root.mediaPage

            sourceComponent: DashboardMediaPage {
                media: mediaState
                colors: root.mediaColors
                pager: root
                blurSource: dashboardArt
                staggerMs: root.staggerMs
            }
        }
    }
}

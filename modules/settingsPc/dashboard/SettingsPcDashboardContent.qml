import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets as W
import qs.modules.common.functions
import qs.modules.settingsPc as Pc
import qs.modules.settingsPc.pages as Pages
import qs.modules.ii.wallpaperSelector as WP

Item {
    id: root

    signal closeRequested

    readonly property int homePage: 0
    readonly property int wallpapersPage: 1
    readonly property int presetsPage: 2
    readonly property int mediaPage: 3
    readonly property int settingsPage: 4

    readonly property var pageNames: [
        { name: Translation.tr("Start"), icon: "home" },
        { name: Translation.tr("Wallpapers"), icon: "wallpaper" },
        { name: Translation.tr("Presets"), icon: "hallway" },
        { name: Translation.tr("Media"), icon: "play_circle" },
        { name: Translation.tr("Settings"), icon: "settings" }
    ]

    property int currentPage: root.homePage
    property bool searchOpen: false

    function focusContent() {
        root.forceActiveFocus();
    }

    function goToTarget(target) {
        root.currentPage = root.settingsPage;
        Qt.callLater(() => settingsLoader.item?.goToTarget(target));
    }

    function closeSearch() {
        searchInput.text = "";
        root.searchOpen = false;
    }

    function runSearch(query) {
        return query.trim().length > 0 ? SettingsSearchIndex.search(query, 20) : [];
    }

    function pickSearchResult(result) {
        root.closeSearch();
        root.goToTarget({
            page: result.pageId,
            label: result.kind === "page" ? "" : (result.rawLabel ?? ""),
            section: result.rawSection ?? "",
            subsection: result.rawSubsection ?? ""
        });
    }

    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            if (root.searchOpen)
                root.closeSearch();
            else
                root.closeRequested();
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Item {
            id: headerBar
            Layout.fillWidth: true
            implicitHeight: 52

            W.Toolbar {
                id: navToolbar
                anchors.centerIn: parent
                colBackground: Appearance.colors.colLayer1

                Repeater {
                    model: root.pageNames

                    delegate: W.RippleButton {
                        id: navBtn
                        required property int index
                        required property var modelData

                        implicitHeight: 38
                        implicitWidth: navContentRow.implicitWidth + 28
                        buttonRadius: height / 2
                        toggled: root.currentPage === index
                        onClicked: {
                            root.currentPage = index;
                            if (index !== root.settingsPage)
                                root.closeSearch();
                        }

                        contentItem: RowLayout {
                            id: navContentRow
                            anchors.centerIn: parent
                            spacing: 6

                            W.MaterialSymbol {
                                text: navBtn.modelData.icon
                                iconSize: Appearance.font.pixelSize.larger
                                color: navBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                fill: navBtn.toggled ? 1 : 0
                            }

                            W.StyledText {
                                text: navBtn.modelData.name
                                color: navBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                visible: navBtn.toggled
                            }
                        }
                    }
                }
            }

            RowLayout {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Rectangle {
                    id: searchPill
                    visible: root.currentPage === root.settingsPage
                    implicitHeight: 40
                    implicitWidth: root.searchOpen ? 240 : 40
                    radius: height / 2
                    color: Appearance.colors.colLayer1
                    border.width: searchInput.activeFocus ? 2 : 0
                    border.color: Appearance.colors.colPrimary
                    clip: true

                    Behavior on implicitWidth {
                        NumberAnimation { duration: 180 / Math.max(0.5, Config.options.settings.animationSpeed ?? 1); easing.type: Easing.OutCubic }
                    }

                    W.RippleButton {
                        id: searchButton
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 40
                        implicitHeight: 40
                        buttonRadius: 20
                        colBackground: "transparent"
                        onClicked: {
                            if (root.searchOpen)
                                root.closeSearch();
                            else {
                                root.searchOpen = true;
                                Qt.callLater(() => searchInput.forceActiveFocus());
                            }
                        }
                        contentItem: W.MaterialSymbol {
                            anchors.centerIn: parent
                            text: "search"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colOnLayer1
                        }
                    }

                    TextInput {
                        id: searchInput
                        anchors.left: searchButton.right
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.searchOpen
                        clip: true
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.family: Appearance.font.family.main
                        color: Appearance.colors.colOnLayer1
                        selectionColor: Appearance.colors.colPrimary
                        Keys.onEscapePressed: {
                            if (text !== "")
                                text = "";
                            else
                                root.closeSearch();
                        }

                        W.StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: searchInput.text === ""
                            text: Translation.tr("Search settings")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                W.RippleButton {
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: 20
                    colBackground: Appearance.colors.colLayer1
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    onClicked: root.closeRequested()
                    contentItem: W.MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnLayer1
                    }
                }
            }

            Rectangle {
                id: searchResultsPanel
                visible: root.searchOpen && searchInput.text.trim().length > 0
                anchors.top: searchPill.bottom
                anchors.right: parent.right
                anchors.topMargin: 6
                width: 320
                implicitHeight: Math.min(320, resultsColumn.implicitHeight + 16)
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                z: 20

                property var results: root.runSearch(searchInput.text)

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 8
                    contentWidth: width
                    contentHeight: resultsColumn.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: resultsColumn
                        width: parent.width
                        spacing: 2

                        W.StyledText {
                            Layout.fillWidth: true
                            visible: searchResultsPanel.results.length === 0
                            text: Translation.tr("No results")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.small
                        }

                        Repeater {
                            model: searchResultsPanel.results

                            delegate: W.RippleButton {
                                id: resultRow
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 36
                                buttonRadius: Appearance.rounding.small
                                colBackground: "transparent"
                                onClicked: root.pickSearchResult(resultRow.modelData)

                                contentItem: RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    W.MaterialSymbol {
                                        text: resultRow.modelData.icon
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: Appearance.colors.colOnLayer1
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: -2
                                        W.StyledText {
                                            Layout.fillWidth: true
                                            text: resultRow.modelData.label
                                            elide: Text.ElideRight
                                            color: Appearance.colors.colOnLayer1
                                            font.pixelSize: Appearance.font.pixelSize.small
                                        }
                                        W.StyledText {
                                            Layout.fillWidth: true
                                            visible: resultRow.modelData.kind !== "page"
                                            text: resultRow.modelData.pageName
                                            elide: Text.ElideRight
                                            color: Appearance.colors.colSubtext
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: root.currentPage === root.homePage
            sourceComponent: Pages.QuickConfig {}
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: root.currentPage === root.wallpapersPage
            sourceComponent: WP.WallpaperSelectorContent {
                shown: root.currentPage === root.wallpapersPage
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: root.currentPage === root.presetsPage
            sourceComponent: DashboardPresetsPage {}
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: root.currentPage === root.mediaPage
            sourceComponent: DashboardMediaPage {}
        }

        Loader {
            id: settingsLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: root.currentPage === root.settingsPage
            sourceComponent: Pc.SettingsPcContent {
                onCloseRequested: root.closeRequested()
            }
        }
    }
}

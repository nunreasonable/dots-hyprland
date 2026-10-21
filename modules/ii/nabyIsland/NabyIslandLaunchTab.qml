pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    signal closeRequested

    readonly property int columns: 5
    readonly property int cellWidth: Math.floor(root.width / root.columns)
    readonly property int cellHeight: 84
    readonly property int maxRows: 3
    property int entriesRevision: 0
    readonly property var apps: {
        root.entriesRevision;
        const ids = [...(Config.options.dock.pinnedApps ?? []), ...(Config.options.launcher.pinnedApps ?? [])];
        const seen = new Set();
        const result = [];
        for (const id of ids) {
            const entry = DesktopEntries.heuristicLookup(id) ?? DesktopEntries.byId(id);
            if (!entry)
                continue;
            const key = (entry.id ?? id).toLowerCase();
            if (seen.has(key))
                continue;
            seen.add(key);
            result.push({ id: id, entry: entry });
        }
        return result;
    }
    readonly property int rows: Math.min(root.maxRows, Math.ceil(root.apps.length / root.columns))

    implicitHeight: (root.apps.length > 0 ? root.rows * root.cellHeight : 96) + 12 + searchButton.height

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.entriesRevision++;
        }
    }

    function launch(entry) {
        root.closeRequested();
        entry.execute();
    }

    function openSearch() {
        root.closeRequested();
        Qt.callLater(() => {
            if (Config.options.search.spotlight) {
                GlobalStates.overviewOpen = false;
                GlobalStates.spotlightMode = "apps";
                GlobalStates.spotlightOpen = true;
            } else {
                GlobalStates.spotlightOpen = false;
                GlobalStates.overviewOpen = true;
            }
        });
    }

    GridView {
        id: grid
        visible: root.apps.length > 0
        width: root.cellWidth * root.columns
        height: root.rows * root.cellHeight
        anchors.horizontalCenter: parent.horizontalCenter
        cellWidth: root.cellWidth
        cellHeight: root.cellHeight
        clip: true
        interactive: root.apps.length > root.columns * root.maxRows
        boundsBehavior: Flickable.StopAtBounds
        model: root.apps

        delegate: NabyIslandButton {
            id: appButton
            required property var modelData
            width: root.cellWidth - 6
            height: root.cellHeight - 6
            radius: 16
            onClicked: root.launch(appButton.modelData.entry)

            Column {
                anchors.centerIn: parent
                width: parent.width - 10
                spacing: 6

                IconImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitSize: 36
                    source: Quickshell.iconPath(appButton.modelData.entry.icon || AppSearch.guessIcon(appButton.modelData.id), "image-missing")
                }

                StyledText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: appButton.modelData.entry.name
                    color: "#ffffff"
                    opacity: appButton.hovered ? 1 : 0.8
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                }
            }
        }
    }

    Column {
        visible: root.apps.length === 0
        anchors.horizontalCenter: parent.horizontalCenter
        y: 18
        spacing: 4

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Translation.tr("No pinned apps")
            color: "#ffffff"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            font.variableAxes: ({ "wght": 600 })
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Translation.tr("Pin apps in the dock or the app list to see them here")
            color: "#ffffff"
            opacity: 0.55
            font.pixelSize: 12
        }
    }

    NabyIslandButton {
        id: searchButton
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: searchRow.implicitWidth + 32
        height: 36
        colNormal: Qt.rgba(1, 1, 1, 0.08)
        colHover: Qt.rgba(1, 1, 1, 0.16)
        onClicked: root.openSearch()

        Row {
            id: searchRow
            anchors.centerIn: parent
            spacing: 8

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: "search"
                iconSize: 18
                color: "#ffffff"
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Translation.tr("Search apps")
                color: "#ffffff"
                font.pixelSize: 13
            }
        }
    }
}

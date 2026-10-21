pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.settings
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root

    property MprisPlayer player: null
    property bool hasMedia: false
    property real cornerRadius: 26

    signal closeRequested

    readonly property var tabs: [
        { id: "media", icon: "play_circle", name: Translation.tr("Media") },
        { id: "focus", icon: "timer", name: Translation.tr("Focus") },
        { id: "status", icon: "monitoring", name: Translation.tr("Status") },
        { id: "launch", icon: "grid_view", name: Translation.tr("Launch") },
        { id: "tools", icon: "home_repair_service", name: Translation.tr("Tools") },
    ]
    readonly property string currentTab: root.tabs.some(t => t.id === Persistent.states.nabyIsland.tab) ? Persistent.states.nabyIsland.tab : "media"

    readonly property int sidePadding: 20
    readonly property int headerHeight: 34
    readonly property int tabRowHeight: 56
    readonly property int bottomPadding: 18

    implicitHeight: root.headerHeight + root.tabRowHeight + contentLoader.implicitHeight + root.bottomPadding
    focus: true

    function selectTab(id) {
        Persistent.states.nabyIsland.tab = id;
    }

    function stepTab(step) {
        const index = root.tabs.findIndex(t => t.id === root.currentTab);
        root.selectTab(root.tabs[(index + step + root.tabs.length) % root.tabs.length].id);
    }

    function openSettings() {
        root.closeRequested();
        if (Platform.isWindows)
            SettingsApp.open();
        else
            Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("settings.qml")]);
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Backtab && (event.modifiers & Qt.ControlModifier)) {
            root.stepTab(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Tab && (event.modifiers & Qt.ControlModifier)) {
            root.stepTab((event.modifiers & Qt.ShiftModifier) ? -1 : 1);
            event.accepted = true;
        }
    }

    NabyIslandArtColor {
        id: artColor
        artUrl: root.hasMedia ? (root.player?.trackArtUrl ?? "") : ""
    }

    NabyIslandGlow {
        anchors.fill: parent
        cornerRadius: root.cornerRadius
        color: artColor.glow
    }

    MouseArea {
        id: header
        x: root.sidePadding
        width: root.width - root.sidePadding * 2
        height: root.headerHeight
        onClicked: root.closeRequested()

        Row {
            anchors.centerIn: parent
            spacing: 10

            NabyIslandWaveform {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.hasMedia
                playing: root.player?.isPlaying ?? false
                barCount: 6
                maxBarHeight: 14
                minBarHeight: 3
                barWidth: 2.5
                barSpacing: 2
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.hasMedia
                width: Math.min(implicitWidth, 220)
                text: StringUtils.cleanMusicTitle(root.player?.trackTitle ?? "")
                color: "#ffffff"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.variableAxes: ({ "wght": 600 })
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                maximumLineCount: 1
            }

            Item {
                visible: root.hasMedia
                width: 14
                height: 1
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: DateTime.time
                color: "#ffffff"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.variableAxes: ({ "wght": 650 })
            }
        }
    }

    Row {
        id: tabRow
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.headerHeight
        height: 50
        spacing: 2

        Repeater {
            model: root.tabs

            NabyIslandButton {
                id: tabButton
                required property var modelData
                readonly property bool active: tabButton.modelData.id === root.currentTab
                width: Math.max(64, tabLabel.implicitWidth + 18)
                height: 50
                radius: 18
                highlighted: tabButton.active
                onClicked: root.selectTab(tabButton.modelData.id)

                Column {
                    anchors.centerIn: parent
                    spacing: 1
                    opacity: tabButton.active || tabButton.hovered ? 1 : 0.62

                    MaterialSymbol {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tabButton.modelData.icon
                        iconSize: 20
                        color: tabButton.active ? "#000000" : "#ffffff"
                    }

                    StyledText {
                        id: tabLabel
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tabButton.modelData.name
                        color: tabButton.active ? "#000000" : "#ffffff"
                        font.pixelSize: 11
                    }
                }
            }
        }
    }

    NabyIslandButton {
        anchors.right: parent.right
        anchors.rightMargin: root.sidePadding - 6
        anchors.verticalCenter: tabRow.verticalCenter
        width: 36
        height: 36
        onClicked: root.openSettings()

        MaterialSymbol {
            anchors.centerIn: parent
            text: "tune"
            iconSize: 20
            color: "#ffffff"
        }
    }

    Loader {
        id: contentLoader
        x: root.sidePadding
        y: root.headerHeight + root.tabRowHeight
        width: root.width - root.sidePadding * 2
        onLoaded: contentFade.restart()
        sourceComponent: {
            switch (root.currentTab) {
            case "focus":
                return focusTab;
            case "status":
                return statusTab;
            case "launch":
                return launchTab;
            case "tools":
                return toolsTab;
            default:
                return mediaTab;
            }
        }

        NumberAnimation {
            id: contentFade
            target: contentLoader
            property: "opacity"
            from: 0
            to: 1
            duration: 180 * Appearance.animationScale
            easing.type: Easing.OutCubic
        }
    }

    Component {
        id: mediaTab
        NabyIslandMediaTab {
            player: root.player
            hasMedia: root.hasMedia
        }
    }

    Component {
        id: focusTab
        NabyIslandFocusTab {}
    }

    Component {
        id: statusTab
        NabyIslandStatusTab {}
    }

    Component {
        id: launchTab
        NabyIslandLaunchTab {
            onCloseRequested: root.closeRequested()
        }
    }

    Component {
        id: toolsTab
        NabyIslandToolsTab {
            onCloseRequested: root.closeRequested()
        }
    }
}

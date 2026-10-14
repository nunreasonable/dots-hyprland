import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Qt.labs.synchronizer

Item {
    id: root
    required property var scopeRoot
    property int sidebarPadding: 10
    anchors.fill: parent
    property bool aiChatEnabled: Config.options.policies.ai !== 0
    property bool translatorEnabled: Config.options.sidebar.translator.enable
    property bool animeEnabled: Config.options.policies.weeb !== 0
    property bool animeCloset: Config.options.policies.weeb === 2
    property bool mediaEnabled: Config.options.sidebar.media.enable
    property var tabButtonList: [
        ...(root.aiChatEnabled ? [{"icon": "neurology", "name": Translation.tr("Intelligence")}] : []),
        ...(root.translatorEnabled ? [{"icon": "translate", "name": Translation.tr("Translator")}] : []),
        ...(root.mediaEnabled ? [{"icon": "music_note", "name": Translation.tr("Media")}] : []),
        ...((root.animeEnabled && !root.animeCloset) ? [{"icon": "bookmark_heart", "name": Translation.tr("Anime")}] : [])
    ]
    property var pageKeys: [
        ...(root.aiChatEnabled ? ["aiChat"] : []),
        ...(root.translatorEnabled ? ["translator"] : []),
        ...(root.mediaEnabled ? ["media"] : []),
        ...((root.tabButtonList.length === 0 || (!root.aiChatEnabled && !root.translatorEnabled && !root.mediaEnabled && root.animeCloset)) ? ["placeholder"] : []),
        ...(root.animeEnabled ? ["anime"] : []),
    ]
    property int tabCount: swipeView.count
    property bool loadAsync: Platform.isWindows && !GlobalStates.sidebarLeftOpen

    onPageKeysChanged: root.syncPages()
    Component.onCompleted: root.syncPages()

    function syncPages() {
        const components = {
            "aiChat": aiChat,
            "translator": translator,
            "media": media,
            "placeholder": placeholder,
            "anime": anime,
        };
        for (let i = swipeView.count - 1; i >= 0; i--) {
            const page = swipeView.itemAt(i);
            if (!root.pageKeys.includes(page.pageKey))
                swipeView.removeItem(page);
        }
        root.pageKeys.forEach((key, index) => {
            if (swipeView.itemAt(index)?.pageKey !== key)
                swipeView.insertItem(index, components[key].createObject(null));
        });
    }

    function focusActiveItem() {
        swipeView.currentItem.forceActiveFocus()
    }

    Keys.onPressed: (event) => {
        if (event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                swipeView.incrementCurrentIndex()
                event.accepted = true;
            }
            else if (event.key === Qt.Key_PageUp) {
                swipeView.decrementCurrentIndex()
                event.accepted = true;
            }
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: sidebarPadding
        }
        spacing: sidebarPadding

        Toolbar {
            visible: tabButtonList.length > 0
            Layout.alignment: Qt.AlignHCenter
            enableShadow: false
            ToolbarTabBar {
                id: tabBar
                Layout.alignment: Qt.AlignHCenter
                tabButtonList: root.tabButtonList
                currentIndex: swipeView.currentIndex
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: swipeView.implicitWidth
            implicitHeight: swipeView.implicitHeight
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            SwipeView { // Content pages
                id: swipeView
                anchors.fill: parent
                spacing: 10
                currentIndex: tabBar.currentIndex

                clip: true
                layer.enabled: !Platform.isWindows
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: swipeView.width
                        height: swipeView.height
                        radius: Appearance.rounding.small
                    }
                }
            }
        }

        Component {
            id: aiChat
            SidebarLeftPage {
                pageKey: "aiChat"
                sourceComponent: AiChat {}
            }
        }
        Component {
            id: translator
            SidebarLeftPage {
                pageKey: "translator"
                sourceComponent: Translator {}
            }
        }
        Component {
            id: media
            SidebarLeftPage {
                pageKey: "media"
                sourceComponent: SidebarPlayerControl {}
            }
        }
        Component {
            id: anime
            SidebarLeftPage {
                pageKey: "anime"
                sourceComponent: Anime {}
            }
        }
        Component {
            id: placeholder
            Item {
                property string pageKey: "placeholder"
                StyledText {
                    anchors.centerIn: parent
                    text: root.animeCloset ? Translation.tr("Nothing") : Translation.tr("Enjoy your empty sidebar...")
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }

    component SidebarLeftPage: Loader {
        id: page
        property string pageKey
        property bool wasLoaded: false
        readonly property bool current: page.SwipeView.isCurrentItem
        active: !Platform.isWindows || page.current || page.wasLoaded || root.loadAsync
        asynchronous: Platform.isWindows && (!page.current || root.loadAsync)
        onLoaded: {
            page.wasLoaded = true;
            page.item.focus = Qt.binding(() => page.current);
            if (page.item.pageActive !== undefined)
                page.item.pageActive = Qt.binding(() => page.current);
        }
    }
}
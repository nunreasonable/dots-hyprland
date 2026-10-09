import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF
import qs.modules.settingsPc.widgets as Pc

Item {
    id: root
    property real contentPadding: 8
    property bool asynchronousFirstPage: true
    property int currentPage: 0
    readonly property bool lookReady: Config.ready && MaterialThemeLoader.ready && Translation.ready
    property bool ready: false
    readonly property bool pageShown: pageArea.shownPage !== -1
    readonly property var pages: SettingsPages.pages
    readonly property int pageCount: SettingsPages.sources.length
    readonly property Item currentPageItem: pageArea.shownPage === -1 ? null : (pagesRepeater.itemAt(pageArea.shownPage)?.item ?? null)

    signal closeRequested

    function focusContent() {
        keyHandler.forceActiveFocus();
    }

    function goToTarget(target) {
        const idx = SettingsPages.indexOf(target.page);
        if (idx < 0)
            return;
        root.currentPage = idx;
        if (!target.label)
            return;

        const run = () => {
            const loader = pagesRepeater.itemAt(idx);
            loader?.item?.goTo(target.label, target.section, target.subsection);
        };
        const loader = pagesRepeater.itemAt(idx);
        if (loader?.item) {
            run();
            return;
        }
        pendingTarget.page = idx;
        pendingTarget.run = run;
    }

    QtObject {
        id: pendingTarget
        property int page: -1
        property var run: null

        function flush(index) {
            if (pendingTarget.page !== index || !pendingTarget.run)
                return;
            const run = pendingTarget.run;
            pendingTarget.page = -1;
            pendingTarget.run = null;
            Qt.callLater(run);
        }
    }

    Binding on ready {
        when: root.lookReady
        value: true
        restoreMode: Binding.RestoreNone
    }

    Timer {
        interval: 1500
        running: Config.ready && !root.ready
        onTriggered: root.ready = true
    }

    onCurrentPageChanged: pageArea.showPending()

    ColumnLayout {
        id: keyHandler
        anchors {
            fill: parent
            margins: root.contentPadding
        }
        focus: true

        Keys.onPressed: event => {
            if (event.modifiers === Qt.ControlModifier) {
                if (event.key === Qt.Key_PageDown) {
                    root.currentPage = Math.min(root.currentPage + 1, root.pageCount - 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_PageUp) {
                    root.currentPage = Math.max(root.currentPage - 1, 0);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Tab) {
                    root.currentPage = (root.currentPage + 1) % root.pageCount;
                    event.accepted = true;
                } else if (event.key === Qt.Key_Backtab) {
                    root.currentPage = (root.currentPage - 1 + root.pageCount) % root.pageCount;
                    event.accepted = true;
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.contentPadding

            Rectangle {
                id: navRailWrapper
                Layout.fillHeight: true
                Layout.margins: 0
                implicitWidth: navRail.expanded ? 195 : fab.baseSize + 40
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.normal

                Behavior on implicitWidth {
                    NumberAnimation {
                        alwaysRunToEnd: true
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }

                NavigationRail {
                    id: navRail
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom; leftMargin: 20 }
                    spacing: 10
                    expanded: root.width > 900

                    Item {
                        id: profileRowContainer
                        Layout.fillWidth: false
                        Layout.margins: 5
                        Layout.topMargin: 15
                        implicitHeight: profileRow.implicitHeight
                        implicitWidth: profileRow.implicitWidth

                        RowLayout {
                            id: profileRow
                            anchors.fill: parent
                            spacing: 10

                            Pc.UserAvatar {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                            }

                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true
                                visible: navRail.expanded

                                StyledText {
                                    text: SystemInfo.username
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer1
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 100
                                }

                                StyledText {
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 100
                                    text: SystemInfo.distroName
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: navRail.expanded ? 160 : fab.baseSize
                        Layout.topMargin: -5
                        height: 2
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.2; color: Appearance.colors.colOutline }
                            GradientStop { position: 0.8; color: Appearance.colors.colOutline }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                        opacity: 0.15
                    }

                    FloatingActionButton {
                        id: fab
                        Layout.bottomMargin: -25
                        property bool justCopied: false
                        iconText: justCopied ? "check" : "edit"
                        buttonText: justCopied ? Translation.tr("Path copied") : Translation.tr("Config file")
                        expanded: navRail.expanded
                        downAction: () => {
                            Qt.openUrlExternally(`${Directories.config}/illogical-impulse/config.json`);
                        }
                        altAction: () => {
                            Quickshell.clipboardText = CF.FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse/config.json`);
                            fab.justCopied = true;
                            revertTextTimer.restart();
                        }
                        Timer {
                            id: revertTextTimer
                            interval: 1500
                            onTriggered: fab.justCopied = false
                        }
                        StyledToolTip {
                            text: Translation.tr("Open the shell config file\nAlternatively right-click to copy path")
                        }
                    }

                    NavigationRailTabArray {
                        currentIndex: root.currentPage
                        expanded: navRail.expanded
                        Repeater {
                            model: root.ready ? root.pages : []
                            NavigationRailButton {
                                required property var index
                                required property var modelData
                                toggled: root.currentPage === index
                                onPressed: root.currentPage = index
                                expanded: navRail.expanded
                                buttonIcon: modelData.icon
                                buttonIconRotation: modelData.iconRotation || 0
                                buttonText: modelData.name
                                showToggledHighlight: false
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Item {
                    id: pageArea
                    property int shownPage: -1
                    property bool animate: false
                    anchors.fill: parent

                    function showPending() {
                        const loader = pagesRepeater.itemAt(root.currentPage);
                        if (!loader || loader.status !== Loader.Ready)
                            return;
                        const first = pageArea.shownPage === -1;
                        pageArea.shownPage = root.currentPage;
                        if (first)
                            Qt.callLater(() => {
                                pageArea.animate = true;
                            });
                    }

                    Repeater {
                        id: pagesRepeater
                        model: root.pageCount
                        delegate: Loader {
                            id: pageLoader
                            required property int index
                            property bool visited: false
                            readonly property bool isActive: pageArea.shownPage === index

                            anchors.fill: parent
                            anchors.topMargin: isActive ? 0 : 12
                            opacity: isActive ? 1 : 0
                            visible: isActive
                            enabled: isActive
                            asynchronous: index !== 0 || root.asynchronousFirstPage
                            active: root.ready && visited
                            source: SettingsPages.sources[index]
                            onLoaded: {
                                pageArea.showPending();
                                pendingTarget.flush(index);
                            }

                            Binding on visited {
                                when: pageLoader.index === root.currentPage
                                value: true
                                restoreMode: Binding.RestoreNone
                            }

                            Behavior on opacity {
                                enabled: pageArea.animate
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                            Behavior on anchors.topMargin {
                                enabled: pageArea.animate
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                        }
                    }
                }
            }
        }
    }
}

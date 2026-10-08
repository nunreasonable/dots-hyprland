import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF

Item {
    id: root
    property real contentPadding: 8
    property bool asynchronousFirstPage: true
    property int currentPage: 0
    readonly property bool lookReady: Config.ready && MaterialThemeLoader.ready && Translation.ready
    property bool ready: false
    readonly property bool pageShown: pageArea.shownPage !== -1
    readonly property list<url> pageSources: [
        Qt.resolvedUrl("QuickConfig.qml"),
        Qt.resolvedUrl("GeneralConfig.qml"),
        Qt.resolvedUrl("BarConfig.qml"),
        Qt.resolvedUrl("BackgroundConfig.qml"),
        Qt.resolvedUrl("InterfaceConfig.qml"),
        Qt.resolvedUrl("ServicesConfig.qml"),
        Qt.resolvedUrl("AdvancedConfig.qml"),
        Qt.resolvedUrl("About.qml")
    ]
    property var pages: [
        {
            name: Translation.tr("Quick"),
            icon: "instant_mix"
        },
        {
            name: Translation.tr("General"),
            icon: "browse"
        },
        {
            name: Translation.tr("Bar"),
            icon: "toast",
            iconRotation: 180
        },
        {
            name: Translation.tr("Background"),
            icon: "texture"
        },
        {
            name: Translation.tr("Interface"),
            icon: "bottom_app_bar"
        },
        {
            name: Translation.tr("Services"),
            icon: "settings"
        },
        {
            name: Translation.tr("Advanced"),
            icon: "construction"
        },
        {
            name: Translation.tr("About"),
            icon: "info"
        }
    ]

    signal closeRequested

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

    onCurrentPageChanged: pageArea.switchPage()

    ColumnLayout {
        anchors {
            fill: parent
            margins: root.contentPadding
        }

        Keys.onPressed: event => {
            if (event.modifiers === Qt.ControlModifier) {
                if (event.key === Qt.Key_PageDown) {
                    root.currentPage = Math.min(root.currentPage + 1, root.pageSources.length - 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_PageUp) {
                    root.currentPage = Math.max(root.currentPage - 1, 0);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Tab) {
                    root.currentPage = (root.currentPage + 1) % root.pageSources.length;
                    event.accepted = true;
                } else if (event.key === Qt.Key_Backtab) {
                    root.currentPage = (root.currentPage - 1 + root.pageSources.length) % root.pageSources.length;
                    event.accepted = true;
                }
            }
        }

        Item {
            visible: Config.options?.windows.showTitlebar
            Layout.fillWidth: true
            Layout.fillHeight: false
            implicitHeight: Math.max(titleText.implicitHeight, windowControlsRow.implicitHeight)
            StyledText {
                id: titleText
                anchors {
                    left: Config.options.windows.centerTitle ? undefined : parent.left
                    horizontalCenter: Config.options.windows.centerTitle ? parent.horizontalCenter : undefined
                    verticalCenter: parent.verticalCenter
                    leftMargin: 12
                }
                color: Appearance.colors.colOnLayer0
                text: Translation.tr("Settings")
                font {
                    family: Appearance.font.family.title
                    pixelSize: Appearance.font.pixelSize.title
                    variableAxes: Appearance.font.variableAxes.title
                }
            }
            RowLayout {
                id: windowControlsRow
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                RippleButton {
                    buttonRadius: Appearance.rounding.full
                    implicitWidth: 35
                    implicitHeight: 35
                    onClicked: root.closeRequested()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: "close"
                        iconSize: 20
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.contentPadding
            Item {
                id: navRailWrapper
                Layout.fillHeight: true
                Layout.margins: 5
                implicitWidth: navRail.expanded ? 150 : fab.baseSize
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
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    spacing: 10
                    expanded: root.width > 900

                    NavigationRailExpandButton {
                        focus: root.visible
                    }

                    FloatingActionButton {
                        id: fab
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
                            onTriggered: {
                                fab.justCopied = false;
                            }
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

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Appearance.m3colors.m3surfaceContainerLow
                radius: Appearance.rounding.windowRounding - root.contentPadding

                Item {
                    id: pageArea
                    property int shownPage: -1
                    property bool pageHidden: true

                    function showPending() {
                        if (fadeOut.running || !pageArea.pageHidden)
                            return;
                        const loader = pageRepeater.itemAt(root.currentPage);
                        if (!loader || loader.status !== Loader.Ready)
                            return;
                        const first = pageArea.shownPage === -1;
                        pageArea.shownPage = root.currentPage;
                        pageArea.pageHidden = false;
                        if (first) {
                            pageArea.opacity = 1;
                            pageArea.anchors.topMargin = 0;
                        } else {
                            fadeIn.restart();
                        }
                    }

                    function switchPage() {
                        if (pageArea.shownPage === root.currentPage && !pageArea.pageHidden)
                            return;
                        fadeIn.stop();
                        pageArea.pageHidden = true;
                        if (pageArea.shownPage === -1) {
                            pageArea.showPending();
                            return;
                        }
                        fadeOut.restart();
                    }

                    anchors.fill: parent
                    opacity: 0

                    Repeater {
                        id: pageRepeater
                        model: root.pageSources.length
                        delegate: Loader {
                            id: pageLoader
                            required property int index
                            property bool visited: false
                            anchors.fill: parent
                            visible: index === pageArea.shownPage
                            asynchronous: index !== 0 || root.asynchronousFirstPage
                            active: root.ready && visited
                            source: root.pageSources[index]
                            onLoaded: pageArea.showPending()

                            Binding on visited {
                                when: pageLoader.index === root.currentPage
                                value: true
                                restoreMode: Binding.RestoreNone
                            }
                        }
                    }

                    NumberAnimation {
                        id: fadeOut
                        target: pageArea
                        property: "opacity"
                        to: 0
                        duration: 100
                        easing.type: Appearance.animation.elementMoveExit.type
                        easing.bezierCurve: Appearance.animationCurves.emphasizedFirstHalf
                        onFinished: pageArea.showPending()
                    }

                    ParallelAnimation {
                        id: fadeIn
                        NumberAnimation {
                            target: pageArea
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: 200
                            easing.type: Appearance.animation.elementMoveEnter.type
                            easing.bezierCurve: Appearance.animationCurves.emphasizedLastHalf
                        }
                        NumberAnimation {
                            target: pageArea
                            property: "anchors.topMargin"
                            from: 20
                            to: 0
                            duration: 200
                            easing.type: Appearance.animation.elementMoveEnter.type
                            easing.bezierCurve: Appearance.animationCurves.emphasizedLastHalf
                        }
                    }
                }
            }
        }
    }
}

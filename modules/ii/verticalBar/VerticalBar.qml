import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Scope {
    id: bar
    property bool showBarBackground: Config.options.bar.showBackground

    Variants {
        // For each monitor
        model: {
            const screens = Quickshell.screens;
            const list = Config.options.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }
        LazyLoader {
            id: barLoader
            active: GlobalStates.barOpen && !GlobalStates.screenLocked
            required property ShellScreen modelData
            component: PanelWindow { // Bar window
                id: barRoot
                screen: barLoader.modelData

                property var brightnessMonitor: Brightness.getMonitorForScreen(barLoader.modelData)
                
                Timer {
                    id: showBarTimer
                    interval: (Config?.options.bar.autoHide.showWhenPressingSuper.delay ?? 100)
                    repeat: false
                    onTriggered: {
                        barRoot.superShow = true
                    }
                }
                Connections {
                    target: GlobalStates
                    function onSuperDownChanged() {
                        if (!Config?.options.bar.autoHide.showWhenPressingSuper.enable) return;
                        if (GlobalStates.superDown) showBarTimer.restart();
                        else {
                            showBarTimer.stop();
                            barRoot.superShow = false;
                        }
                    }
                }
                property bool superShow: false
                property bool mustShow: hoverRegion.containsMouse || superShow
                    || (Config.options.bar.autoHide.enable && GlobalStates.isFrameHovered(barRoot.screen?.name, Config.options.bar.bottom ? "right" : "left"))
                readonly property bool barClosing: Config.options.bar.autoHide.enable && !barRoot.mustShow
                property bool contentShown: true
                onBarClosingChanged: {
                    if (barRoot.barClosing) {
                        contentHideTimer.restart();
                    } else {
                        contentHideTimer.stop();
                        barRoot.contentShown = true;
                    }
                }
                onContentShownChanged: GlobalStates.setBarContentShown(barRoot.screen?.name, barRoot.contentShown)
                Timer {
                    id: contentHideTimer
                    interval: Appearance.animation.elementMoveFast.duration
                    repeat: false
                    onTriggered: barRoot.contentShown = false
                }
                readonly property real frameInset: BarLayouts.windowsFrameInset
                readonly property int normalExclusiveZone: (Config?.options.bar.autoHide.enable && (!mustShow || !Config?.options.bar.autoHide.pushWindows)) ? 0 :
                    Appearance.sizes.baseVerticalBarWidth + BarLayouts.styleZone
                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: (barContent.centerOnly && Config.options.bar.showFrame && Config.options.bar.centerOnlyReserveFrame)
                    ? Config.options.bar.frameThickness
                    : normalExclusiveZone + barRoot.frameInset
                WlrLayershell.namespace: "quickshell:verticalBar"
                // WlrLayershell.layer: WlrLayer.Overlay // TODO enable this when bar can hide when fullscreen
                implicitWidth: Appearance.sizes.verticalBarWidth + Appearance.rounding.screenRounding
                readonly property bool pillMask: barContent.item?.pillMask ?? false
                mask: Region {
                    item: barRoot.pillMask ? null : hoverMaskRegion
                    Region {
                        item: barRoot.pillMask ? topPillMask : null
                    }
                    Region {
                        item: barRoot.pillMask ? middlePillMask : null
                    }
                    Region {
                        item: barRoot.pillMask ? bottomPillMask : null
                    }
                }
                color: "transparent"

                // Positioning
                anchors {
                    left: !Config.options.bar.bottom
                    right: Config.options.bar.bottom
                    top: true
                    bottom: true
                }

                margins {
                    left: Config.options.bar.bottom ? 0 : barRoot.frameInset
                    right: Config.options.bar.bottom ? barRoot.frameInset : 0
                }

                // Include in focus grab
                Component.onCompleted: {
                    GlobalFocusGrab.addPersistent(barRoot);
                    barRoot.contentShown = !barRoot.barClosing;
                    GlobalStates.setBarContentShown(barRoot.screen?.name, barRoot.contentShown);
                }
                Component.onDestruction: {
                    GlobalFocusGrab.removePersistent(barRoot);
                    GlobalStates.setBarContentShown(barRoot.screen?.name, true);
                }

                MouseArea  {
                    id: hoverRegion
                    hoverEnabled: true
                    anchors.fill: parent

                    Item {
                        id: hoverMaskRegion
                        anchors {
                            fill: barContent
                            leftMargin: -Config.options.bar.autoHide.hoverRegionWidth
                            rightMargin: -Config.options.bar.autoHide.hoverRegionWidth
                        }
                    }

                    Item {
                        id: topPillMask
                        readonly property rect area: barRoot.pillMask ? barContent.item.leftMaskRect : Qt.rect(0, 0, 0, 0)
                        x: barContent.x + area.x
                        y: barContent.y + area.y
                        width: area.width
                        height: area.height
                    }

                    Item {
                        id: middlePillMask
                        readonly property rect area: barRoot.pillMask ? barContent.item.centerMaskRect : Qt.rect(0, 0, 0, 0)
                        x: barContent.x + area.x
                        y: barContent.y + area.y
                        width: area.width
                        height: area.height
                    }

                    Item {
                        id: bottomPillMask
                        readonly property rect area: barRoot.pillMask ? barContent.item.rightMaskRect : Qt.rect(0, 0, 0, 0)
                        x: barContent.x + area.x
                        y: barContent.y + area.y
                        width: area.width
                        height: area.height
                    }

                    Component {
                        id: classicContent
                        VerticalBarContent {}
                    }

                    Component {
                        id: layoutContent
                        VerticalBarLayoutContent {}
                    }

                    Loader {
                        id: barContent
                        readonly property bool centerOnly: barContent.item?.centerOnly ?? false

                        width: Appearance.sizes.verticalBarWidth
                        sourceComponent: BarLayouts.classicContent ? classicContent : layoutContent
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            left: parent.left
                            right: undefined
                            leftMargin: (Config?.options.bar.autoHide.enable && !mustShow) ? -Appearance.sizes.verticalBarWidth : BarLayouts.edgeGap
                            rightMargin: 0
                        }
                        Behavior on anchors.leftMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on anchors.rightMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                        states: State {
                            name: "right"
                            when: Config.options.bar.bottom
                            AnchorChanges {
                                target: barContent
                                anchors {
                                    top: parent.top
                                    bottom: parent.bottom
                                    left: undefined
                                    right: parent.right
                                }
                            }
                            PropertyChanges {
                                target: barContent
                                anchors.topMargin: 0
                                anchors.rightMargin: (Config?.options.bar.autoHide.enable && !mustShow) ? -Appearance.sizes.barHeight : BarLayouts.edgeGap
                            }
                        }
                    }

                    // Round decorators
                    Loader {
                        id: roundDecorators
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            left: barContent.right
                            right: undefined
                        }
                        width: Appearance.rounding.screenRounding
                        active: (showBarBackground && Config.options.bar.cornerStyle === 0 && !barContent.centerOnly)
                            || Config.options.bar.cornerStyle === 4 || Config.options.bar.cornerStyle === 6

                        states: State {
                            name: "right"
                            when: Config.options.bar.bottom
                            AnchorChanges {
                                target: roundDecorators
                                anchors {
                                    top: parent.top
                                    bottom: parent.bottom
                                    left: undefined
                                    right: barContent.left
                                }
                            }
                        }

                        sourceComponent: Item {
                            implicitHeight: Appearance.rounding.screenRounding
                            readonly property color decoratorColor: (!showBarBackground && Config.options.bar.cornerStyle !== 4 && Config.options.bar.cornerStyle !== 6) ? "transparent" : Config.options.bar.followFrameColor ? Appearance.getColorFromName(Config.options.bar.frameColor) : Appearance.colors.colLayer0
                            RoundCorner {
                                id: topCorner
                                visible: Config.options.bar.cornerStyle === 0 || (barContent.item?.effectiveLeftLayout.length ?? 0) > 0
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                }

                                implicitSize: Appearance.rounding.screenRounding
                                color: parent.decoratorColor

                                corner: RoundCorner.CornerEnum.TopLeft
                                states: State {
                                    name: "bottom"
                                    when: Config.options.bar.bottom
                                    PropertyChanges {
                                        topCorner.corner: RoundCorner.CornerEnum.TopRight
                                    }
                                }
                            }
                            RoundCorner {
                                id: bottomCorner
                                visible: Config.options.bar.cornerStyle === 0 || (barContent.item?.effectiveRightLayout.length ?? 0) > 0
                                anchors {
                                    bottom: parent.bottom
                                    left: !Config.options.bar.bottom ? parent.left : undefined
                                    right: Config.options.bar.bottom ? parent.right : undefined
                                }
                                implicitSize: Appearance.rounding.screenRounding
                                color: parent.decoratorColor

                                corner: RoundCorner.CornerEnum.BottomLeft
                                states: State {
                                    name: "bottom"
                                    when: Config.options.bar.bottom
                                    PropertyChanges {
                                        bottomCorner.corner: RoundCorner.CornerEnum.BottomRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "bar"

        function toggle(): void {
            GlobalStates.barOpen = !GlobalStates.barOpen
        }

        function close(): void {
            GlobalStates.barOpen = false
        }

        function open(): void {
            GlobalStates.barOpen = true
        }
    }

    GlobalShortcut {
        name: "barToggle"
        description: "Toggles bar on press"

        onPressed: {
            GlobalStates.barOpen = !GlobalStates.barOpen;
        }
    }

    GlobalShortcut {
        name: "barOpen"
        description: "Opens bar on press"

        onPressed: {
            GlobalStates.barOpen = true;
        }
    }

    GlobalShortcut {
        name: "barClose"
        description: "Closes bar on press"

        onPressed: {
            GlobalStates.barOpen = false;
        }
    }
}

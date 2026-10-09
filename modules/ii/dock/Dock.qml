import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property bool pinned: Config.options?.dock.pinnedOnStartup ?? false
    property bool barState: false
    property bool ready: false

    function colorFromName(name) {
        if (name === "black" || name === "transparent")
            return name;
        return Appearance.colors["col" + name.charAt(0).toUpperCase() + name.slice(1)] ?? Appearance.colors.colLayer0;
    }

    Component.onCompleted: {
        barSettleTimer.start()
    }

    Timer {
        id: barSettleTimer
        interval: 300
        onTriggered: {
            root.barState = GlobalStates.barOpen
            root.ready = true
        }
    }

    Connections {
        target: Config.options.dock
        function onPositionChanged() {
            root.ready = false
            barSettleTimer.restart()
        }
        function onStyleChanged() {
            root.ready = false
            barSettleTimer.restart()
        }
    }

    Connections {
        target: GlobalStates
        function onBarOpenChanged() { barSettleTimer.restart() }
    }

    Variants {
        model: !root.ready ? [] : Quickshell.screens.map(screen => ({
            screen: screen,
            position: Config.options.dock.position,
            layout: `${Config.options.dock.position}|${Config.options.dock.style}|${Config.options.dock.height}|${root.barState}`
        }))

        PanelWindow {
            id: dockRoot
            required property var modelData
            screen: modelData.screen
            visible: !GlobalStates.screenLocked

            readonly property bool hug: DockStyle.hug
            readonly property string position: modelData.position
            readonly property bool vertical: position !== "bottom"
            readonly property real gap: Appearance.sizes.hyprlandGapsOut
            readonly property real shadowMargin: Appearance.sizes.elevationMargin
            readonly property color backgroundColor: (hug && Config.options.dock.followFrameColor && Config.options.bar?.showFrame && Config.options.bar?.frameColor)
                ? root.colorFromName(Config.options.bar.frameColor)
                : root.colorFromName(Config.options.dock.backgroundColor)
            readonly property real borderWidth: (Config.options.dock.showBackground && Config.options.dock.showBorder && !hug) ? Config.options.dock.borderWidth : 0

            property bool reveal: {
                if (root.pinned)
                    return true;
                if (Config.options?.dock.hoverToReveal) {
                    const frameHovered = typeof GlobalStates.isFrameHovered === "function"
                        && GlobalStates.isFrameHovered(dockRoot.screen?.name, dockRoot.position);
                    if (dockMouseArea.containsMouse || frameHovered)
                        return true;
                }
                if (dockApps.requestDockShow)
                    return true;
                return !ToplevelManager.activeToplevel?.activated;
            }

            exclusiveZone: root.pinned ? DockStyle.zone : 0

            anchors {
                top: dockRoot.vertical
                bottom: true
                left: dockRoot.position !== "right"
                right: dockRoot.position !== "left"
            }
            margins {
                bottom: dockRoot.hug && dockRoot.position === "bottom" ? -dockRoot.gap : 0
                left: dockRoot.hug && dockRoot.position === "left" ? -dockRoot.gap : 0
                right: dockRoot.hug && dockRoot.position === "right" ? -dockRoot.gap : 0
            }
            implicitWidth: dockRoot.vertical ? DockStyle.thickness : dockBackground.implicitWidth
            implicitHeight: dockRoot.vertical ? dockBackground.implicitHeight : DockStyle.thickness
            WlrLayershell.namespace: "quickshell:dock"
            color: "transparent"

            mask: Region { item: dockMouseArea }

            MouseArea {
                id: dockMouseArea
                hoverEnabled: true
                width: dockRoot.vertical ? parent.width : implicitWidth
                height: dockRoot.vertical ? implicitHeight : parent.height
                implicitWidth: dockHoverRegion.implicitWidth + dockRoot.shadowMargin * 2
                implicitHeight: dockHoverRegion.implicitHeight + dockRoot.shadowMargin * 2

                readonly property real hiddenOffset: Config.options?.dock.hoverToReveal
                    ? (DockStyle.thickness - Config.options.dock.hoverRegionHeight)
                    : (DockStyle.thickness + 1)
                property real offset: dockRoot.reveal ? 0 : hiddenOffset

                Behavior on offset {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                anchors {
                    top: dockRoot.vertical ? undefined : parent.top
                    topMargin: dockMouseArea.offset
                    horizontalCenter: dockRoot.vertical ? undefined : parent.horizontalCenter
                    verticalCenter: dockRoot.vertical ? parent.verticalCenter : undefined
                    left: dockRoot.position === "left" ? parent.left : undefined
                    leftMargin: -dockMouseArea.offset
                    right: dockRoot.position === "right" ? parent.right : undefined
                    rightMargin: -dockMouseArea.offset
                }

                Item {
                    id: dockHoverRegion
                    anchors.fill: parent
                    implicitWidth: dockBackground.implicitWidth
                    implicitHeight: dockBackground.implicitHeight

                    Item {
                        id: dockBackground
                        anchors {
                            top: dockRoot.vertical ? undefined : parent.top
                            bottom: dockRoot.vertical ? undefined : parent.bottom
                            left: dockRoot.vertical ? parent.left : undefined
                            right: dockRoot.vertical ? parent.right : undefined
                            horizontalCenter: dockRoot.vertical ? undefined : parent.horizontalCenter
                            verticalCenter: dockRoot.vertical ? parent.verticalCenter : undefined
                        }
                        implicitWidth: dockRow.implicitWidth + DockStyle.backgroundPadding * 2
                        implicitHeight: dockRow.implicitHeight + DockStyle.backgroundPadding * 2

                        StyledRectangularShadow {
                            target: dockVisualBackground
                            visible: false
                        }

                        Rectangle {
                            id: dockVisualBackground
                            anchors.fill: parent
                            anchors.topMargin: dockRoot.position === "bottom" ? dockRoot.shadowMargin : 0
                            anchors.bottomMargin: dockRoot.position === "bottom" ? dockRoot.gap : 0
                            anchors.leftMargin: dockRoot.position === "left" ? dockRoot.gap : dockRoot.position === "right" ? dockRoot.shadowMargin : 0
                            anchors.rightMargin: dockRoot.position === "right" ? dockRoot.gap : dockRoot.position === "left" ? dockRoot.shadowMargin : 0
                            color: Config.options.dock.showBackground ? dockRoot.backgroundColor : "transparent"
                            border.width: dockRoot.borderWidth
                            border.color: root.colorFromName(Config.options.dock.borderColor)
                            radius: Config.options.dock.radius
                            topLeftRadius: dockRoot.hug && dockRoot.position === "left" ? 0 : radius
                            bottomLeftRadius: dockRoot.hug && (dockRoot.position === "left" || dockRoot.position === "bottom") ? 0 : radius
                            topRightRadius: dockRoot.hug && dockRoot.position === "right" ? 0 : radius
                            bottomRightRadius: dockRoot.hug && (dockRoot.position === "right" || dockRoot.position === "bottom") ? 0 : radius
                        }

                        RoundCorner {
                            visible: dockRoot.hug && Config.options.dock.showBackground
                            anchors.right: dockRoot.vertical ? (dockRoot.position === "right" ? dockVisualBackground.right : undefined) : dockVisualBackground.left
                            anchors.bottom: dockRoot.vertical ? dockVisualBackground.top : dockVisualBackground.bottom
                            anchors.left: dockRoot.position === "left" ? dockVisualBackground.left : undefined
                            implicitSize: Appearance.rounding.screenRounding
                            color: dockRoot.backgroundColor
                            corner: dockRoot.position === "left" ? RoundCorner.CornerEnum.BottomLeft : RoundCorner.CornerEnum.BottomRight
                        }

                        RoundCorner {
                            visible: dockRoot.hug && Config.options.dock.showBackground
                            anchors.left: dockRoot.vertical ? (dockRoot.position === "left" ? dockVisualBackground.left : undefined) : dockVisualBackground.right
                            anchors.bottom: dockRoot.vertical ? undefined : dockVisualBackground.bottom
                            anchors.top: dockRoot.vertical ? dockVisualBackground.bottom : undefined
                            anchors.right: dockRoot.position === "right" ? dockVisualBackground.right : undefined
                            implicitSize: Appearance.rounding.screenRounding
                            color: dockRoot.backgroundColor
                            corner: dockRoot.position === "left" ? RoundCorner.CornerEnum.TopLeft
                                : dockRoot.position === "right" ? RoundCorner.CornerEnum.TopRight
                                : RoundCorner.CornerEnum.BottomLeft
                        }

                        GridLayout {
                            id: dockRow
                            anchors.top: dockRoot.vertical ? undefined : parent.top
                            anchors.bottom: dockRoot.vertical ? undefined : parent.bottom
                            anchors.left: dockRoot.vertical ? parent.left : undefined
                            anchors.right: dockRoot.vertical ? parent.right : undefined
                            anchors.horizontalCenter: dockRoot.vertical ? undefined : parent.horizontalCenter
                            anchors.verticalCenter: dockRoot.vertical ? parent.verticalCenter : undefined
                            columns: dockRoot.vertical ? 1 : -1
                            rowSpacing: DockStyle.padding - 2
                            columnSpacing: DockStyle.padding - 2
                            property real padding: DockStyle.padding

                            DockPinButton {
                                pinned: root.pinned
                                onToggled: root.pinned = !root.pinned
                            }

                            DockSeparator {
                                visible: Config.options.dock.showPinButton
                            }

                            DockApps {
                                id: dockApps
                                buttonPadding: dockRow.padding
                            }

                            DockSeparator {
                                visible: Config.options.dock.showMedia
                            }

                            Loader {
                                active: Config.options.dock.showMedia
                                visible: active
                                Layout.fillHeight: !DockStyle.vertical
                                Layout.fillWidth: DockStyle.vertical
                                sourceComponent: DockMedia {}
                            }

                            DockSeparator {
                                visible: Config.options.dock.showAppsButton
                            }

                            DockAppsButton {
                                onClicked: {
                                    if (Config.options.search.spotlight ?? false) {
                                        GlobalStates.spotlightMode = "apps";
                                        GlobalStates.spotlightOpen = !GlobalStates.spotlightOpen;
                                    } else {
                                        GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

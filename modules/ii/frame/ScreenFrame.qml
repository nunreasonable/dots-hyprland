pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: root
    readonly property real frameThickness: Config.options.bar.frameThickness
    readonly property color frameColor: Appearance.getColorFromName(Config.options.bar.frameColor)
    readonly property real cornerSize: Math.max(0, Appearance.rounding.screenRounding - root.frameThickness)

    function edgeNeedsInput(side) {
        return BarLayouts.frameVisibleFor(side) && Config.options.bar.autoHide.enable && BarLayouts.barEdge === side;
    }

    component FrameHoverArea: MouseArea {
        required property string side
        required property string screenName
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        enabled: root.edgeNeedsInput(side)
        onContainsMouseChanged: GlobalStates.setFrameHover(screenName, side, containsMouse)
    }

    component LinuxEdge: PanelWindow {
        id: edgeWindow
        required property string side
        readonly property bool horizontal: side === "top" || side === "bottom"
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: BarLayouts.frameVisibleFor(side) ? root.frameThickness : 0
        WlrLayershell.namespace: "quickshell:screenframe"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        color: "transparent"
        implicitHeight: root.frameThickness
        implicitWidth: root.frameThickness
        anchors {
            top: edgeWindow.side === "top" || !edgeWindow.horizontal
            bottom: edgeWindow.side === "bottom" || !edgeWindow.horizontal
            left: edgeWindow.side === "left" || edgeWindow.horizontal
            right: edgeWindow.side === "right" || edgeWindow.horizontal
        }
        mask: Region {
            item: root.edgeNeedsInput(edgeWindow.side) ? edgeRect : null
        }

        Rectangle {
            id: edgeRect
            anchors.fill: parent
            color: root.frameColor
            visible: BarLayouts.frameVisibleFor(edgeWindow.side)
        }

        FrameHoverArea {
            side: edgeWindow.side
            screenName: edgeWindow.screen?.name ?? ""
        }
    }

    component LinuxCorner: PanelWindow {
        id: cornerPanelWindow
        property var corner
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}
        WlrLayershell.namespace: "quickshell:screenframe-corner"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: cornerWidget.isTopLeft || cornerWidget.isTopRight
            left: cornerWidget.isBottomLeft || cornerWidget.isTopLeft
            bottom: cornerWidget.isBottomLeft || cornerWidget.isBottomRight
            right: cornerWidget.isTopRight || cornerWidget.isBottomRight
        }
        margins {
            left: cornerWidget.isLeft ? root.frameThickness : 0
            right: cornerWidget.isRight ? root.frameThickness : 0
            top: cornerWidget.isTop ? root.frameThickness : 0
            bottom: cornerWidget.isBottom ? root.frameThickness : 0
        }

        implicitWidth: cornerWidget.implicitWidth
        implicitHeight: cornerWidget.implicitHeight

        RoundCorner {
            id: cornerWidget
            anchors.fill: parent
            corner: cornerPanelWindow.corner
            implicitSize: root.cornerSize
            color: root.frameColor
        }
    }

    component WindowsEdge: LazyLoader {
        id: edgeLoader
        required property var screenModel
        required property string side
        readonly property bool horizontal: edgeLoader.side === "top" || edgeLoader.side === "bottom"
        readonly property bool barSide: edgeLoader.side === BarLayouts.barEdge && BarLayouts.barOnScreen(edgeLoader.screenModel?.name ?? "")

        function zone(edge) {
            if (edge === BarLayouts.barEdge && BarLayouts.barOnScreen(edgeLoader.screenModel?.name ?? ""))
                return BarLayouts.barZone;
            return BarLayouts.frameVisibleFor(edge) ? root.frameThickness : 0;
        }

        active: Platform.isWindows && BarLayouts.frameVisibleFor(edgeLoader.side)

        component: PanelWindow {
            id: edgeWindow
            screen: edgeLoader.screenModel
            exclusiveZone: edgeLoader.barSide ? -1 : root.frameThickness
            WlrLayershell.namespace: "quickshell:screenframe"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            color: "transparent"
            implicitHeight: root.frameThickness
            implicitWidth: root.frameThickness + root.cornerSize
            anchors {
                top: edgeLoader.side === "top" || !edgeLoader.horizontal
                bottom: edgeLoader.side === "bottom" || !edgeLoader.horizontal
                left: edgeLoader.side === "left" || edgeLoader.horizontal
                right: edgeLoader.side === "right" || edgeLoader.horizontal
            }
            margins {
                top: (!edgeLoader.horizontal && !edgeLoader.barSide) ? -edgeLoader.zone("top") : 0
                bottom: (!edgeLoader.horizontal && !edgeLoader.barSide) ? -edgeLoader.zone("bottom") : 0
                left: (edgeLoader.horizontal && !edgeLoader.barSide) ? -edgeLoader.zone("left") : 0
                right: (edgeLoader.horizontal && !edgeLoader.barSide) ? -edgeLoader.zone("right") : 0
            }
            mask: Region {
                item: root.edgeNeedsInput(edgeLoader.side) ? edgeRect : null
            }

            Rectangle {
                id: edgeRect
                x: edgeLoader.side === "right" ? root.cornerSize : 0
                width: edgeLoader.horizontal ? parent.width : root.frameThickness
                height: parent.height
                color: root.frameColor

                FrameHoverArea {
                    side: edgeLoader.side
                    screenName: edgeLoader.screenModel?.name ?? ""
                }
            }

            RoundCorner {
                visible: !edgeLoader.horizontal && BarLayouts.frameVisibleFor("top")
                x: edgeLoader.side === "left" ? root.frameThickness : 0
                y: root.frameThickness
                implicitSize: root.cornerSize
                color: root.frameColor
                corner: edgeLoader.side === "left" ? RoundCorner.CornerEnum.TopLeft : RoundCorner.CornerEnum.TopRight
            }

            RoundCorner {
                visible: !edgeLoader.horizontal && BarLayouts.frameVisibleFor("bottom")
                x: edgeLoader.side === "left" ? root.frameThickness : 0
                y: parent.height - root.frameThickness - root.cornerSize
                implicitSize: root.cornerSize
                color: root.frameColor
                corner: edgeLoader.side === "left" ? RoundCorner.CornerEnum.BottomLeft : RoundCorner.CornerEnum.BottomRight
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: frameGroup
            required property ShellScreen modelData

            LazyLoader {
                active: !Platform.isWindows
                component: Scope {
                    LinuxEdge {
                        screen: frameGroup.modelData
                        side: "top"
                    }
                    LinuxEdge {
                        screen: frameGroup.modelData
                        side: "bottom"
                    }
                    LinuxEdge {
                        screen: frameGroup.modelData
                        side: "left"
                    }
                    LinuxEdge {
                        screen: frameGroup.modelData
                        side: "right"
                    }
                    LinuxCorner {
                        screen: frameGroup.modelData
                        corner: RoundCorner.CornerEnum.TopLeft
                    }
                    LinuxCorner {
                        screen: frameGroup.modelData
                        corner: RoundCorner.CornerEnum.TopRight
                    }
                    LinuxCorner {
                        screen: frameGroup.modelData
                        corner: RoundCorner.CornerEnum.BottomLeft
                    }
                    LinuxCorner {
                        screen: frameGroup.modelData
                        corner: RoundCorner.CornerEnum.BottomRight
                    }
                }
            }

            WindowsEdge {
                screenModel: frameGroup.modelData
                side: "top"
            }
            WindowsEdge {
                screenModel: frameGroup.modelData
                side: "bottom"
            }
            WindowsEdge {
                screenModel: frameGroup.modelData
                side: "left"
            }
            WindowsEdge {
                screenModel: frameGroup.modelData
                side: "right"
            }
        }
    }
}

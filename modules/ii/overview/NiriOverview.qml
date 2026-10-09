pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    required property var screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property int effectiveActiveWorkspaceId: Math.max(1, Math.min(100, monitor?.activeWorkspace?.id ?? 1))
    property bool monitorIsFocused: (Hyprland.focusedMonitor?.name == monitor?.name)
    property bool live: true
    property bool animate: true
    property var windowByAddress: HyprlandData.windowByAddress
    property var monitors: HyprlandData.monitors
    property var monitorData: root.monitors.find(m => m.id === root.monitor?.id)
    property real scale: Config.options.overview.scale
    property color activeBorderColor: Appearance.colors.colSecondary

    property real workspaceImplicitWidth: (monitorData?.transform % 2 === 1) ?
        ((monitor.height - monitorData?.reserved[0] - monitorData?.reserved[2]) * root.scale / monitor.scale) :
        ((monitor.width - monitorData?.reserved[0] - monitorData?.reserved[2]) * root.scale / monitor.scale)
    property real workspaceImplicitHeight: (monitorData?.transform % 2 === 1) ?
        ((monitor.width - monitorData?.reserved[1] - monitorData?.reserved[3]) * root.scale / monitor.scale) :
        ((monitor.height - monitorData?.reserved[1] - monitorData?.reserved[3]) * root.scale / monitor.scale)
    property real rowRadius: Appearance.rounding.large
    property real rowSpacing: 5
    property real maxVisibleRows: 3

    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1

    implicitWidth: overviewBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
    implicitHeight: overviewBackground.implicitHeight + Appearance.sizes.elevationMargin * 2

    readonly property var workspaceIds: {
        const ids = new Set([root.effectiveActiveWorkspaceId]);
        for (const toplevel of ToplevelManager.toplevels.values) {
            const address = `0x${toplevel.HyprlandToplevel?.address}`;
            const win = root.windowByAddress[address];
            if (win?.monitor === root.monitor?.id && win?.workspace?.id)
                ids.add(Math.max(1, Math.min(100, win.workspace.id)));
        }
        return [...ids].sort((a, b) => a - b);
    }

    function windowsInWorkspace(wsId) {
        return ToplevelManager.toplevels.values.filter(toplevel => {
            const address = `0x${toplevel.HyprlandToplevel?.address}`;
            const win = root.windowByAddress[address];
            return win?.workspace?.id === wsId;
        });
    }

    onLiveChanged: {
        if (root.live) {
            animateTimer.restart();
        } else {
            animateTimer.stop();
            root.animate = false;
        }
    }

    Timer {
        id: animateTimer
        interval: 0
        onTriggered: root.animate = true
    }

    Binding {
        target: root
        property: "windowByAddress"
        when: root.live
        value: HyprlandData.windowByAddress
        restoreMode: Binding.RestoreNone
    }

    Binding {
        target: root
        property: "monitors"
        when: root.live
        value: HyprlandData.monitors
        restoreMode: Binding.RestoreNone
    }

    function scrollToActive(animated) {
        const idx = root.workspaceIds.indexOf(root.effectiveActiveWorkspaceId);
        if (idx === -1)
            return;
        const targetY = idx * (root.workspaceImplicitHeight + root.rowSpacing);
        if (animated && root.animate) {
            scrollAnim.to = targetY;
            scrollAnim.restart();
        } else {
            scrollAnim.stop();
            flick.contentY = targetY;
        }
    }

    onEffectiveActiveWorkspaceIdChanged: scrollToActive(true)
    onWorkspaceIdsChanged: scrollToActive(false)
    Component.onCompleted: scrollToActive(false)

    NumberAnimation {
        id: scrollAnim
        target: flick
        property: "contentY"
        duration: Appearance.animation.elementMoveFast.duration
        easing.type: Appearance.animation.elementMoveFast.type
    }

    StyledRectangularShadow {
        target: overviewBackground
    }
    Rectangle {
        id: overviewBackground
        property real padding: 10
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        clip: true

        implicitWidth: root.workspaceImplicitWidth + padding * 2
        implicitHeight: Math.min(wsColumn.implicitHeight, root.maxVisibleRows * root.workspaceImplicitHeight + (root.maxVisibleRows - 1) * root.rowSpacing) + padding * 2
        radius: root.rowRadius + padding
        color: Appearance.colors.colBackgroundSurfaceContainer

        Behavior on implicitHeight {
            enabled: root.animate
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: overviewBackground.padding
            contentWidth: width
            contentHeight: wsColumn.implicitHeight
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Column {
                id: wsColumn
                width: flick.width
                spacing: root.rowSpacing

                Repeater {
                    model: root.workspaceIds
                    delegate: Rectangle {
                        id: wsRow
                        required property int modelData
                        readonly property int wsId: modelData
                        property color defaultWorkspaceColor: Appearance.colors.colSurfaceContainerLow
                        property color hoveredWorkspaceColor: ColorUtils.mix(defaultWorkspaceColor, Appearance.colors.colLayer1Hover, 0.1)
                        property bool hoveredWhileDragging: false

                        width: root.workspaceImplicitWidth
                        height: root.workspaceImplicitHeight
                        radius: root.rowRadius
                        color: hoveredWhileDragging ? hoveredWorkspaceColor : defaultWorkspaceColor
                        border.width: 2
                        border.color: wsRow.wsId === root.effectiveActiveWorkspaceId ? root.activeBorderColor : "transparent"

                        StyledText {
                            anchors.centerIn: parent
                            text: wsRow.wsId
                            font {
                                pixelSize: 150 * root.scale
                                weight: Font.DemiBold
                                family: Appearance.font.family.expressive
                            }
                            color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.8)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            onPressed: {
                                if (root.draggingTargetWorkspace === -1) {
                                    GlobalStates.overviewOpen = false;
                                    Hyprland.dispatch(`hl.dsp.focus({ workspace = ${wsRow.wsId} })`);
                                }
                            }
                        }

                        DropArea {
                            anchors.fill: parent
                            onEntered: {
                                root.draggingTargetWorkspace = wsRow.wsId;
                                if (root.draggingFromWorkspace !== root.draggingTargetWorkspace)
                                    wsRow.hoveredWhileDragging = true;
                            }
                            onExited: {
                                wsRow.hoveredWhileDragging = false;
                                if (root.draggingTargetWorkspace === wsRow.wsId)
                                    root.draggingTargetWorkspace = -1;
                            }
                        }

                        Repeater {
                            model: ScriptModel {
                                values: root.windowsInWorkspace(wsRow.wsId)
                            }
                            delegate: OverviewWindow {
                                id: window
                                required property var modelData
                                property var address: `0x${modelData.HyprlandToplevel.address}`
                                toplevel: modelData
                                monitorData: root.monitorData
                                scale: root.scale
                                animate: root.animate
                                widgetMonitor: root.monitorData
                                windowData: root.windowByAddress[address]

                                z: Drag.active ? 99999 : (1 + (windowData?.floating ?? 0) + (windowData?.fullscreen ?? 0) * 2)
                                Drag.hotSpot.x: width / 2
                                Drag.hotSpot.y: height / 2

                                MouseArea {
                                    id: dragArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: window.hovered = true
                                    onExited: window.hovered = false
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                    drag.target: window
                                    onPressed: (mouse) => {
                                        root.draggingFromWorkspace = wsRow.wsId;
                                        window.pressed = true;
                                        window.Drag.active = true;
                                        window.Drag.source = window;
                                        window.Drag.hotSpot.x = mouse.x;
                                        window.Drag.hotSpot.y = mouse.y;
                                    }
                                    onReleased: {
                                        const targetWorkspace = root.draggingTargetWorkspace;
                                        window.pressed = false;
                                        window.Drag.active = false;
                                        root.draggingFromWorkspace = -1;
                                        if (targetWorkspace !== -1 && targetWorkspace !== wsRow.wsId)
                                            Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${targetWorkspace}, follow = false, window = "address:${window.windowData?.address}" })`);
                                        window.x = Qt.binding(() => window.initX);
                                        window.y = Qt.binding(() => window.initY);
                                    }
                                    onClicked: (event) => {
                                        if (!window.windowData)
                                            return;
                                        if (event.button === Qt.LeftButton) {
                                            GlobalStates.overviewOpen = false;
                                            Hyprland.dispatch(`hl.dsp.focus({window = "address:${window.windowData.address}"})`);
                                            event.accepted = true;
                                        } else if (event.button === Qt.MiddleButton) {
                                            Hyprland.dispatch(`hl.dsp.window.close({window = "address:${window.windowData.address}"})`);
                                            event.accepted = true;
                                        }
                                    }

                                    StyledToolTip {
                                        extraVisibleCondition: false
                                        alternativeVisibleCondition: dragArea.containsMouse && !window.Drag.active
                                        text: `${window.windowData?.title}\n[${window.windowData?.class}] ${window.windowData?.xwayland ? "[XWayland] " : ""}`
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

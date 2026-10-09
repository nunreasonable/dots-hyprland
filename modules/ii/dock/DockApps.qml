pragma ComponentBehavior: Bound
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    property real maxWindowPreviewHeight: 200
    property real maxWindowPreviewWidth: 300
    property real windowControlsHeight: 30
    property real buttonPadding: 5

    property Item lastHoveredButton: null
    property bool buttonHovered: false
    property bool requestDockShow: previewPopup.show

    Layout.fillHeight: !DockStyle.vertical
    Layout.fillWidth: DockStyle.vertical
    Layout.topMargin: DockStyle.vertical ? 0 : Appearance.sizes.hyprlandGapsOut
    implicitWidth: DockStyle.vertical ? (parent?.width ?? listView.implicitWidth) : listView.implicitWidth
    implicitHeight: DockStyle.vertical ? listView.implicitHeight : (parent?.height ?? listView.implicitHeight)

    function popupCenterForButton(button) {
        if (!button || !root.QsWindow)
            return 0;
        const point = root.QsWindow.mapFromItem(button, button.width / 2, button.height / 2);
        return DockStyle.vertical ? point.y : point.x;
    }

    StyledListView {
        id: listView
        spacing: DockStyle.listSpacing
        orientation: DockStyle.vertical ? ListView.Vertical : ListView.Horizontal
        anchors {
            top: DockStyle.vertical ? undefined : parent.top
            bottom: DockStyle.vertical ? undefined : parent.bottom
            left: DockStyle.vertical ? parent.left : undefined
            right: DockStyle.vertical ? parent.right : undefined
        }
        implicitWidth: DockStyle.vertical ? (parent?.width ?? contentWidth) : contentWidth
        implicitHeight: DockStyle.vertical ? contentHeight : (parent?.height ?? contentHeight)

        Behavior on implicitWidth {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on implicitHeight {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        model: ScriptModel {
            objectProp: "appId"
            values: TaskbarApps.apps
        }
        delegate: DockAppButton {
            required property var modelData
            appToplevel: modelData
            appListRoot: root

            innerInset: Appearance.sizes.hyprlandGapsOut + root.buttonPadding
            outerInset: Appearance.sizes.hyprlandGapsOut + root.buttonPadding
        }
    }

    PopupWindow {
        id: previewPopup
        property var appTopLevel: root.lastHoveredButton?.appToplevel

        property bool shouldShow: Config.options.dock.showPreviews
            && (popupMouseArea.containsMouse || root.buttonHovered)
            && appTopLevel && appTopLevel.toplevels && appTopLevel.toplevels.length > 0

        property bool show: false
        property real cachedCenter: 0
        readonly property real shiftX: DockStyle.position === "left" ? -12 : DockStyle.position === "right" ? 12 : 0
        readonly property real shiftY: DockStyle.vertical ? 0 : 12

        Connections {
            target: root
            function onLastHoveredButtonChanged() {
                if (root.lastHoveredButton && root.QsWindow)
                    previewPopup.cachedCenter = root.popupCenterForButton(root.lastHoveredButton);
            }
            function onButtonHoveredChanged() {
                if (root.buttonHovered && root.lastHoveredButton && root.QsWindow)
                    previewPopup.cachedCenter = root.popupCenterForButton(root.lastHoveredButton);
                updateTimer.restart();
            }
        }

        onShouldShowChanged: {
            updateTimer.restart();
        }

        onShowChanged: {
            if (show) {
                closeAnim.stop();
                openAnim.restart();
            } else {
                openAnim.stop();
                closeAnim.restart();
            }
        }

        ParallelAnimation {
            id: openAnim
            NumberAnimation {
                target: bodyScale
                properties: "xScale,yScale"
                from: 0.85
                to: 1
                duration: 220
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
            }
            NumberAnimation {
                target: bodyShift
                property: "x"
                from: previewPopup.shiftX
                to: 0
                duration: 220
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
            }
            NumberAnimation {
                target: bodyShift
                property: "y"
                from: previewPopup.shiftY
                to: 0
                duration: 220
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
            }
            NumberAnimation {
                target: body
                property: "opacity"
                to: 1
                duration: 130
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveEffects
            }
        }

        ParallelAnimation {
            id: closeAnim
            NumberAnimation {
                target: bodyScale
                properties: "xScale,yScale"
                to: 0.9
                duration: 110
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedAccel
            }
            NumberAnimation {
                target: bodyShift
                property: "x"
                to: previewPopup.shiftX * 0.6
                duration: 110
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedAccel
            }
            NumberAnimation {
                target: bodyShift
                property: "y"
                to: previewPopup.shiftY * 0.6
                duration: 110
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedAccel
            }
            NumberAnimation {
                target: body
                property: "opacity"
                to: 0
                duration: 90
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedAccel
            }
        }

        Timer {
            id: updateTimer
            interval: previewPopup.shouldShow ? 100 : 30
            onTriggered: {
                previewPopup.show = previewPopup.shouldShow;
            }
        }

        anchor {
            window: root.QsWindow.window
            adjustment: PopupAdjustment.None
            gravity: DockStyle.position === "left" ? (Edges.Bottom | Edges.Right)
                : DockStyle.position === "right" ? (Edges.Bottom | Edges.Left)
                : (Edges.Top | Edges.Right)
            edges: Edges.Top | Edges.Left
            rect.x: DockStyle.position === "left"
                ? DockStyle.zone + Appearance.sizes.hyprlandGapsOut - Appearance.sizes.elevationMargin
                : DockStyle.position === "right"
                    ? (root.QsWindow.window?.width ?? 0) - DockStyle.zone - Appearance.sizes.hyprlandGapsOut + Appearance.sizes.elevationMargin
                    : 0
        }

        visible: body.opacity > 0
        color: "transparent"
        implicitWidth: DockStyle.vertical ? popupMouseArea.implicitWidth : (root.QsWindow.window?.width ?? 1)
        implicitHeight: DockStyle.vertical
            ? (root.QsWindow.window?.height ?? 1)
            : popupMouseArea.implicitHeight + root.windowControlsHeight + Appearance.sizes.elevationMargin * 2

        MouseArea {
            id: popupMouseArea
            anchors.bottom: DockStyle.vertical ? undefined : parent.bottom
            anchors.left: DockStyle.position === "left" ? parent.left : undefined
            anchors.right: DockStyle.position === "right" ? parent.right : undefined
            implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: DockStyle.vertical
                ? popupBackground.implicitHeight + Appearance.sizes.elevationMargin * 2
                : root.maxWindowPreviewHeight + root.windowControlsHeight + Appearance.sizes.elevationMargin * 2
            hoverEnabled: true
            x: DockStyle.vertical ? 0 : previewPopup.cachedCenter - width / 2
            y: DockStyle.vertical
                ? Math.max(0, Math.min((root.QsWindow.window?.height ?? 0) - height, previewPopup.cachedCenter - height / 2))
                : 0

            Item {
                id: body
                anchors.fill: parent
                opacity: 0
                visible: opacity > 0
                transform: [
                    Scale {
                        id: bodyScale
                        origin.x: DockStyle.position === "left" ? Appearance.sizes.elevationMargin
                            : DockStyle.position === "right" ? body.width - Appearance.sizes.elevationMargin
                            : body.width / 2
                        origin.y: DockStyle.vertical ? body.height / 2 : body.height - Appearance.sizes.elevationMargin
                        xScale: 0.85
                        yScale: 0.85
                    },
                    Translate {
                        id: bodyShift
                    }
                ]

                StyledRectangularShadow {
                    target: popupBackground
                }

                Rectangle {
                    id: popupBackground
                    property real padding: 5
                    clip: true
                    color: Appearance.m3colors.m3surfaceContainer
                    radius: Appearance.rounding.normal
                    anchors.bottom: DockStyle.vertical ? undefined : parent.bottom
                    anchors.bottomMargin: Appearance.sizes.elevationMargin
                    anchors.horizontalCenter: DockStyle.vertical ? undefined : parent.horizontalCenter
                    anchors.verticalCenter: DockStyle.vertical ? parent.verticalCenter : undefined
                    anchors.left: DockStyle.position === "left" ? parent.left : undefined
                    anchors.right: DockStyle.position === "right" ? parent.right : undefined
                    anchors.leftMargin: Appearance.sizes.elevationMargin
                    anchors.rightMargin: Appearance.sizes.elevationMargin
                    implicitHeight: previewRowLayout.implicitHeight + padding * 2
                    implicitWidth: previewRowLayout.implicitWidth + padding * 2
                    Behavior on implicitWidth {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    Behavior on implicitHeight {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }

                    RowLayout {
                        id: previewRowLayout
                        anchors.centerIn: parent
                        Repeater {
                            model: ScriptModel {
                                values: previewPopup.appTopLevel?.toplevels ?? []
                            }
                            RippleButton {
                                id: windowButton
                                Layout.fillHeight: true
                                required property var modelData
                                padding: 0
                                middleClickAction: () => {
                                    windowButton.modelData?.close();
                                }
                                onClicked: {
                                    windowButton.modelData?.activate();
                                }
                                contentItem: ColumnLayout {
                                    implicitWidth: screencopyView.implicitWidth
                                    implicitHeight: screencopyView.implicitHeight

                                    ButtonGroup {
                                        contentWidth: parent.width - anchors.margins * 2
                                        StyledText {
                                            Layout.margins: 5
                                            Layout.fillWidth: true
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            text: windowButton.modelData?.title
                                            elide: Text.ElideRight
                                            color: Appearance.m3colors.m3onSurface
                                        }
                                        GroupButton {
                                            id: closeButton
                                            colBackground: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer)
                                            baseWidth: root.windowControlsHeight
                                            baseHeight: root.windowControlsHeight
                                            buttonRadius: Appearance.rounding.full
                                            contentItem: MaterialSymbol {
                                                anchors.centerIn: parent
                                                horizontalAlignment: Text.AlignHCenter
                                                text: "close"
                                                iconSize: Appearance.font.pixelSize.normal
                                                color: Appearance.m3colors.m3onSurface
                                            }
                                            onClicked: {
                                                windowButton.modelData?.close();
                                            }
                                        }
                                    }
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        implicitHeight: screencopyView.height
                                        implicitWidth: screencopyView.width
                                        ScreencopyView {
                                            id: screencopyView
                                            anchors.centerIn: parent
                                            captureSource: windowButton.modelData
                                            live: true
                                            paintCursor: true
                                            constraintSize: Qt.size(root.maxWindowPreviewWidth, root.maxWindowPreviewHeight)
                                            layer.enabled: !Platform.isWindows
                                            layer.effect: OpacityMask {
                                                maskSource: Rectangle {
                                                    width: screencopyView.width
                                                    height: screencopyView.height
                                                    radius: Appearance.rounding.small
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
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    property string appId: ""
    property QtObject desktopEntry: null
    property bool showPinDock: true
    property var executeApp: null
    property var onLaunched: null
    property alias isOpen: menuLoader.active
    property rect anchorRect

    readonly property string entryId: root.desktopEntry?.id ?? root.appId
    readonly property var appInfo: (root.isOpen && Platform.isWindows && root.entryId !== "" && WindowsNative.appActions)
        ? WindowsNative.appActions.info(root.entryId) : null
    readonly property bool pinnedDock: root.appId !== "" && TaskbarApps.isPinned(root.appId)

    function open(item, desktopEntry, options) {
        const opts = options ?? {};
        menuLoader.active = false;
        const topLeft = root.QsWindow.mapFromItem(item, 0, 0);
        root.anchorRect = Qt.rect(topLeft.x, topLeft.y, item.width, item.height);
        root.desktopEntry = desktopEntry ?? null;
        root.appId = opts.appId ?? desktopEntry?.id ?? "";
        root.showPinDock = opts.showPinDock ?? true;
        root.executeApp = opts.executeApp ?? null;
        root.onLaunched = opts.onLaunched ?? null;
        menuLoader.active = true;
    }

    function close() {
        menuLoader.active = false;
    }

    function _defaultExecute() {
        const entry = root.desktopEntry;
        if (!entry) return;
        if (!entry.runInTerminal || Platform.isWindows) {
            entry.execute();
        } else {
            Quickshell.execDetached(["bash", "-c", `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(entry.command.join(' '))}'`]);
        }
    }

    function _open() {
        (root.executeApp ?? root._defaultExecute)();
        root.onLaunched?.();
        root.close();
    }

    function _runAsAdmin() {
        WindowsNative.appActions?.runAsAdmin(root.entryId);
        root.onLaunched?.();
        root.close();
    }

    function _openFileLocation() {
        WindowsNative.appActions?.openFileLocation(root.entryId);
        root.close();
    }

    function _uninstall() {
        WindowsNative.appActions?.uninstall(root.entryId);
        root.close();
    }

    function _togglePinDock() {
        TaskbarApps.togglePin(root.appId);
        root.close();
    }

    Loader {
        id: menuLoader
        active: false
        sourceComponent: PopupWindow {
            id: contextPopup
            visible: true

            anchor {
                window: root.QsWindow.window
                rect: root.anchorRect
                gravity: Edges.Bottom | Edges.Right
                edges: Edges.Bottom | Edges.Left
                adjustment: PopupAdjustment.Slide
            }

            HyprlandFocusGrab {
                active: true
                windows: [contextPopup]
                onCleared: root.close()
            }

            color: "transparent"
            mask: Region {
                item: menuInputArea
            }
            implicitWidth: menuBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: menuBackground.implicitHeight + Appearance.sizes.elevationMargin * 2

            Item {
                id: menuInputArea
                anchors.fill: menuBackground
            }

            StyledRectangularShadow {
                target: menuBackground
            }

            Rectangle {
                id: menuBackground
                property real padding: 4

                anchors.centerIn: parent
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.normal
                implicitWidth: menuColumn.implicitWidth + padding * 2
                implicitHeight: menuColumn.implicitHeight + padding * 2
                focus: true
                Keys.onEscapePressed: root.close()

                opacity: 0
                transform: Scale {
                    id: menuScale
                    origin.x: 0
                    origin.y: 0
                    xScale: 0.8
                    yScale: 0.01
                }

                Component.onCompleted: openAnim.start()

                ParallelAnimation {
                    id: openAnim
                    NumberAnimation {
                        target: menuScale
                        property: "yScale"
                        to: 1
                        duration: 500
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
                    }
                    NumberAnimation {
                        target: menuScale
                        property: "xScale"
                        to: 1
                        duration: Appearance.animationCurves.expressiveDefaultSpatialDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                    }
                    NumberAnimation {
                        target: menuBackground
                        property: "opacity"
                        to: 1
                        duration: Appearance.animationCurves.expressiveEffectsDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                    }
                }

                ColumnLayout {
                    id: menuColumn
                    anchors {
                        fill: parent
                        margins: parent.padding
                    }
                    spacing: 0

                    ContextMenuItem {
                        iconName: "open_in_new"
                        label: Translation.tr("Open")
                        enabled: root.desktopEntry !== null || root.executeApp !== null
                        onClicked: root._open()
                    }

                    ContextMenuItem {
                        visible: Platform.isWindows && (root.appInfo?.canRunAsAdmin ?? false)
                        iconName: "admin_panel_settings"
                        label: Translation.tr("Run as administrator")
                        onClicked: root._runAsAdmin()
                    }

                    ContextMenuItem {
                        visible: Platform.isWindows && (root.appInfo?.canOpenLocation ?? false)
                        iconName: "folder_open"
                        label: Translation.tr("Open file location")
                        onClicked: root._openFileLocation()
                    }

                    ContextMenuSeparator {
                        visible: root.showPinDock
                    }

                    ContextMenuItem {
                        visible: root.showPinDock
                        iconName: root.pinnedDock ? "keep_off" : "keep"
                        label: root.pinnedDock ? Translation.tr("Unpin") : Translation.tr("Pin to dock")
                        enabled: root.appId !== ""
                        onClicked: root._togglePinDock()
                    }

                    ContextMenuSeparator {
                        visible: Platform.isWindows && (root.appInfo?.canUninstall ?? false)
                    }

                    ContextMenuItem {
                        visible: Platform.isWindows && (root.appInfo?.canUninstall ?? false)
                        iconName: "delete"
                        label: Translation.tr("Uninstall")
                        onClicked: root._uninstall()
                    }
                }
            }
        }
    }

    component ContextMenuItem: RippleButton {
        id: menuItemRoot
        property string iconName
        property string iconSource
        property string label
        readonly property color contentColor: enabled ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3outline
        Layout.fillWidth: true
        implicitHeight: 36
        implicitWidth: Math.max(itemRow.implicitWidth + itemRow.anchors.leftMargin + itemRow.anchors.rightMargin, 180)
        buttonRadius: Appearance.rounding.small

        contentItem: RowLayout {
            id: itemRow
            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 14
            }
            spacing: 8

            IconImage {
                visible: menuItemRoot.iconSource !== ""
                source: menuItemRoot.iconSource
                implicitSize: Appearance.font.pixelSize.normal
                Layout.alignment: Qt.AlignVCenter
            }

            MaterialSymbol {
                text: menuItemRoot.iconName
                iconSize: Appearance.font.pixelSize.normal
                color: menuItemRoot.contentColor
                visible: menuItemRoot.iconSource === "" && menuItemRoot.iconName !== ""
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                Layout.fillWidth: true
                text: menuItemRoot.label
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: Appearance.font.pixelSize.small
                color: menuItemRoot.contentColor
                elide: Text.ElideRight
            }
        }
    }

    component ContextMenuSeparator: Item {
        Layout.fillWidth: true
        implicitHeight: 9

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 10
                rightMargin: 10
            }
            implicitHeight: 1
            color: ColorUtils.transparentize(Appearance.m3colors.m3outline, 0.7)
        }
    }
}

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    property color contentColor: Appearance.colors.colOnLayer0
    property bool contentColorOverridden: false
    property bool classic: false
    property bool vertical: false
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    property string activeWindowAddress: `0x${activeWindow?.HyprlandToplevel?.address}`
    property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name
    property var biggestWindow: HyprlandData.biggestWindowForWorkspace(HyprlandData.monitors[root.monitor?.id]?.activeWorkspace.id)
    readonly property string activeAppClass: (root.focusingThisMonitor && root.activeWindow?.activated) ? (root.activeWindow?.appId ?? root.biggestWindow?.class ?? "") : (root.biggestWindow?.class ?? "")

    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : root.classic ? colLayout.implicitWidth : Math.min(colLayout.implicitWidth + 12, 280)
    implicitHeight: root.vertical ? 22 : root.classic ? 0 : Appearance.sizes.barHeight

    Loader {
        active: root.vertical
        visible: active
        anchors.centerIn: parent
        sourceComponent: Image {
            width: 18
            height: 18
            sourceSize: Qt.size(18, 18)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            source: Quickshell.iconPath(AppSearch.guessIcon(root.activeAppClass !== "" ? root.activeAppClass : "user-desktop"), "image-missing")
        }
    }

    ColumnLayout {
        id: colLayout
        visible: !root.vertical

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.classic ? 0 : 6
        spacing: -4

        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: root.contentColorOverridden ? Qt.alpha(root.contentColor, 0.7) : Appearance.colors.colSubtext
            elide: Text.ElideRight
            text: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ?
                (Platform.isWindows
                    ? (DesktopEntries.heuristicLookup(root.activeWindow?.appId)?.name ?? root.activeWindow?.appId)
                    : root.activeWindow?.appId) :
                (Platform.isWindows && root.biggestWindow
                    ? (DesktopEntries.heuristicLookup(root.biggestWindow.class)?.name ?? root.biggestWindow.class)
                    : root.biggestWindow?.class) ?? Translation.tr("Desktop")

        }

        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.contentColor
            elide: Text.ElideRight
            text: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ?
                root.activeWindow?.title :
                (root.biggestWindow?.title) ?? `${Translation.tr("Workspace")} ${monitor?.activeWorkspace?.id ?? 1}`
        }

    }

}

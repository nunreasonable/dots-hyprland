import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

DockButton {
    visible: Config.options.dock.showAppsButton
    Layout.topMargin: 0
    Layout.leftMargin: 0
    innerInset: DockStyle.appsButtonInset
    outerInset: DockStyle.appsButtonInset

    contentItem: Item {
        MaterialSymbol {
            visible: StyleTheme.key !== "mainel"
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            iconSize: parent.width / 2
            text: "apps"
            color: Appearance.colors.colOnLayer0
        }

        MainelAsterisk {
            visible: StyleTheme.key === "mainel"
            anchors.centerIn: parent
            size: parent.width / 2
            color: MainelTheme.jadeMid
        }
    }
}

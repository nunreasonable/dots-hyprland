pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property color contentColor: Appearance.colors.colOnLayer1
    property bool contentColorOverridden: false
    signal styleEditorRequested
    property bool vertical: false
    property bool hovered: false
    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : rowLayout.implicitWidth + 10 * 2
    implicitHeight: root.vertical ? columnLayout.implicitHeight : Appearance.sizes.barHeight

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    onPressed: {
        if (mouse.button === Qt.RightButton) {
            Weather.getData();
            Notifications.sendDesktop(
                Translation.tr("Weather"),
                Translation.tr("Refreshing (manually triggered)"),
                ["-a", "Shell"]
            )
            mouse.accepted = false
        }
    }

    RowLayout {
        id: rowLayout
        visible: !root.vertical
        anchors.centerIn: parent

        MaterialSymbol {
            fill: 0
            text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
            iconSize: Appearance.font.pixelSize.large
            color: root.contentColor
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            visible: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.contentColor
            text: Weather.data?.temp ?? "--°"
            Layout.alignment: Qt.AlignVCenter
        }
    }

    ColumnLayout {
        id: columnLayout
        visible: root.vertical
        anchors.centerIn: parent
        spacing: 0

        MaterialSymbol {
            fill: 0
            text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
            iconSize: Appearance.font.pixelSize.large
            color: root.contentColor
            Layout.alignment: Qt.AlignHCenter
        }

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.contentColor
            text: (Weather.data?.temp ?? "--°").replace(/[CF]$/, "")
            Layout.alignment: Qt.AlignHCenter
        }
    }

    WeatherPopup {
        id: weatherPopup
        hoverTarget: root
    }
}

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
    property bool isMaterial: Config.options.bar.cornerStyle === 3 || Config.options.bar.cornerStyle === 4
    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : rowLayout.implicitWidth + (root.isMaterial ? 4 : 10 * 2)
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
        spacing: root.isMaterial ? 6 : 5

        MaterialSymbol {
            visible: !root.isMaterial
            fill: 0
            text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
            iconSize: Appearance.font.pixelSize.large
            color: root.contentColor
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.isMaterial ? Appearance.colors.colOnLayer0 : root.contentColor
            text: Weather.data?.temp ?? "--°"
            Layout.alignment: Qt.AlignVCenter
            leftPadding: root.isMaterial ? 5 : 0
        }

        Rectangle {
            visible: root.isMaterial
            implicitWidth: 25
            implicitHeight: 25
            radius: Appearance.rounding.full
            color: Appearance.colors.colPrimary
            Layout.alignment: Qt.AlignVCenter

            MaterialSymbol {
                anchors.centerIn: parent
                fill: 0
                text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnPrimary
            }
        }
    }

    ColumnLayout {
        id: columnLayout
        visible: root.vertical
        anchors.centerIn: parent
        spacing: root.isMaterial ? 2 : 0

        MaterialSymbol {
            visible: !root.isMaterial
            fill: 0
            text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
            iconSize: Appearance.font.pixelSize.large
            color: root.contentColor
            Layout.alignment: Qt.AlignHCenter
        }

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.isMaterial ? Appearance.colors.colPrimary : root.contentColor
            text: (Weather.data?.temp ?? "--°").replace(/[CF]$/, "")
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: root.isMaterial ? 3 : 0
        }

        Rectangle {
            visible: root.isMaterial
            implicitWidth: 25
            implicitHeight: 25
            radius: Appearance.rounding.full
            color: Appearance.colors.colPrimary
            Layout.alignment: Qt.AlignHCenter

            MaterialSymbol {
                anchors.centerIn: parent
                fill: 0
                text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnPrimary
            }
        }
    }

    WeatherPopup {
        id: weatherPopup
        hoverTarget: root
    }
}

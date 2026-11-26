import QtQuick
import qs.modules.common
import qs.modules.common.widgets

DashboardCard {
    id: root

    tint: Appearance.colors.colLayer1

    WeatherMapPreview {
        anchors.fill: parent
        cardRadius: root.cardRadius
    }
}

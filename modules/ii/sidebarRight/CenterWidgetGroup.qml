import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.sidebarRight.notifications
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    radius: StyleTheme.surface.radiusOuter ?? Appearance.rounding.normal
    StyleShadow {
        radius: root.radius
    }
    StyleFrame {
        radius: root.radius
        visible: StyleTheme.surface.frame && !QuadrinhoTheme.active
    }
    color: StyleTheme.surface.fill ?? Appearance.colors.colLayer1

    NotificationList {
        anchors.fill: parent
        anchors.margins: 5
    }
}

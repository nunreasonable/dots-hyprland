import QtQuick
import qs.modules.common

Rectangle {
    id: root

    anchors.fill: parent
    anchors.topMargin: SekaiTheme.shadowOffset
    anchors.bottomMargin: -SekaiTheme.shadowOffset
    z: -3
    visible: SekaiTheme.active
    color: SekaiTheme.shadow
    antialiasing: true
}

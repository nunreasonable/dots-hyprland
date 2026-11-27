import QtQuick

Item {
    id: root

    property real radius: 0

    StyleShadow {
        radius: root.radius
    }

    StyleFrame {
        radius: root.radius
    }
}

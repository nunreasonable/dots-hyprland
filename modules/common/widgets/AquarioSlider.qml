import QtQuick
import qs.modules.common

AquarioTube {
    id: root

    required property Item slider

    value: root.slider.visualPosition
    smooth: !root.slider.pressed

    Binding {
        target: root.slider.background
        property: "visible"
        value: false
    }

    Binding {
        target: root.slider.handle
        property: "opacity"
        value: 0
    }
}

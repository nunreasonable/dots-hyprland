import QtQuick
import qs.modules.common

Item {
    id: root

    required property Item shadow
    readonly property bool shown: (root.shadow?.visible ?? false) && (root.Window.window?.visible ?? false)

    function play() {
        if (root.shown && Appearance.animationsEnabled)
            settle.restart();
    }

    onShownChanged: root.play()
    Component.onCompleted: root.play()
    Component.onDestruction: {
        if (root.shadow)
            root.shadow.lift = 0;
    }

    NumberAnimation {
        id: settle
        target: root.shadow
        property: "lift"
        from: 10 - StyleTheme.elevation.y
        to: 0
        duration: 180
        easing.type: Easing.OutBack
        easing.overshoot: 1.2
    }
}

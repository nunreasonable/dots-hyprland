import QtQuick
import qs.modules.common

Item {
    id: root

    property string appName: ""
    property bool critical: false
    property string tailSide: "none"
    property real topSpace: 12
    property real bottomSpace: 0

    readonly property string position: Config.options.notifications.position ?? "top_right"
    readonly property real tipAt: root.position.endsWith("left") ? 0.08 : root.position.endsWith("center") ? 0.5 : 0.92

    QuadrinhoBalloon {
        anchors.fill: parent
        anchors.topMargin: root.tailSide === "top" ? 0 : root.topSpace
        shout: root.critical
        tailSide: root.tailSide
        tailLength: root.tailSide === "top" ? root.topSpace : root.bottomSpace
        tailTip: root.tipAt
        tailBase: root.tipAt > 0.5 ? root.tipAt - 0.14 : root.tipAt + 0.14
    }

    QuadrinhoCaption {
        x: 18
        y: Math.max(0, root.topSpace - height / 2 - 1)
        visible: root.appName !== ""
        maximumWidth: root.width * 0.6
        text: root.appName
    }
}

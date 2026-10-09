import qs.modules.common.widgets
import qs.modules.common
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    readonly property alias hovered: hoverHandler.hovered
    property string text: ""
    property string icon
    property alias value: spinBoxWidget.value
    property alias stepSize: spinBoxWidget.stepSize
    property alias from: spinBoxWidget.from
    property alias to: spinBoxWidget.to
    signal valueModified()
    spacing: 10
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    HoverHandler {
        id: hoverHandler
    }

    RowLayout {
        spacing: 10
        OptionalMaterialSymbol {
            icon: root.icon
            opacity: root.enabled ? 1 : 0.4
        }
        StyledText {
            id: labelWidget
            Layout.fillWidth: true
            text: root.text
            color: Appearance.colors.colOnSecondaryContainer
            opacity: root.enabled ? 1 : 0.4
        }
    }

    StyledSpinBox {
        id: spinBoxWidget
        Layout.fillWidth: false
        value: root.value
        onValueModified: root.valueModified()
    }
}

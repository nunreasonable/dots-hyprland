import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

/**
 * Material 3 expressive style toolbar.
 * https://m3.material.io/components/toolbars
 */
Item {
    id: root

    property bool enableShadow: true
    property bool outerShadow: false
    property real padding: 8
    property alias colBackground: background.color
    property alias spacing: toolbarLayout.spacing
    default property alias toolbarData: toolbarLayout.data
    implicitWidth: background.implicitWidth
    implicitHeight: background.implicitHeight
    property alias radius: background.radius

    Component {
        id: plainShadow

        StyledRectangularShadow {
            target: background
            anchors.fill: undefined
        }
    }

    Component {
        id: outerShadowOnly

        StyledOuterShadow {
            target: background
        }
    }

    Loader {
        active: root.enableShadow
        anchors.fill: background
        sourceComponent: root.outerShadow ? outerShadowOnly : plainShadow
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: Appearance.m3colors.m3surfaceContainer
        implicitHeight: 56
        implicitWidth: toolbarLayout.implicitWidth + root.padding * 2
        radius: height / 2

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
            onClicked: mouse => mouse.accepted = true
            onWheel: wheel => wheel.accepted = true
        }

        RowLayout {
            id: toolbarLayout
            spacing: 4
            anchors {
                fill: parent
                margins: root.padding
            }
        }
    }
}

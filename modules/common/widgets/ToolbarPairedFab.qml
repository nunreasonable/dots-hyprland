pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common

Item {
    id: root

    signal clicked(event: var)
    property alias iconText: fabWidget.iconText
    property alias baseSize: fabWidget.baseSize
    default property alias fabData: fabWidget.data
    property bool enableShadow: true

    anchors {
        verticalCenter: parent.verticalCenter
    }
    implicitWidth: fabWidget.implicitWidth
    implicitHeight: fabWidget.implicitHeight
    // As Toolbar does: the shadow can't anchor to the button from inside the
    // Loader (it isn't a sibling), and an unanchored one shows as a thin
    // sliver at the button's edge. The Loader sizes it to the button instead.
    Loader {
        active: root.enableShadow
        anchors.fill: fabWidget
        sourceComponent: StyledRectangularShadow {
            target: fabWidget
            anchors.fill: undefined
            radius: fabWidget.buttonRadius
        }
    }
    FloatingActionButton {
        id: fabWidget
        onClicked: e => root.clicked(e)
        baseSize: 48
        colBackground: Appearance.colors.colTertiaryContainer
        colBackgroundHover: Appearance.colors.colTertiaryContainerHover
        colRipple: Appearance.colors.colTertiaryContainerActive
        colOnBackground: Appearance.colors.colOnTertiaryContainer
    }
}
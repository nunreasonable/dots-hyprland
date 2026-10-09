import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: root
    property string title: ""
    property string tooltip: ""
    default property alias contentData: sectionContent.data

    property real flashScan: 0
    property real flashTint: 0

    function flashTitle() {
        titleFlash.restart()
    }

    ParallelAnimation {
        id: titleFlash

        SequentialAnimation {
            NumberAnimation { target: root; property: "flashTint"; to: 1; duration: 150 }
            PauseAnimation { duration: 1800 }
            NumberAnimation { target: root; property: "flashTint"; to: 0; duration: 500 }
        }

        SequentialAnimation {
            PropertyAction { target: root; property: "flashScan"; value: 0 }
            SequentialAnimation {
                loops: 2
                NumberAnimation { target: root; property: "flashScan"; to: 1; duration: 450; easing.type: Easing.InOutSine }
                NumberAnimation { target: root; property: "flashScan"; to: 0; duration: 450; easing.type: Easing.InOutSine }
            }
        }
    }

    Layout.fillWidth: true
    Layout.topMargin: 4
    spacing: 2

    RowLayout {
        ContentSubsectionLabel {
            visible: root.title && root.title.length > 0
            text: root.title
            color: Qt.tint(Appearance.colors.colSubtext, Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, root.flashTint))

            Loader {
                active: root.flashTint > 0
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -3
                width: parent.width
                sourceComponent: TitleScanLine {
                    position: root.flashScan
                    opacity: root.flashTint
                }
            }
        }
        Loader {
            active: root.tooltip.length > 0
            visible: active
            sourceComponent: MaterialSymbol {
                text: "info"
                iconSize: Appearance.font.pixelSize.large

                color: Appearance.colors.colSubtext
                MouseArea {
                    id: infoMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.WhatsThisCursor
                    StyledToolTip {
                        extraVisibleCondition: false
                        alternativeVisibleCondition: infoMouseArea.containsMouse
                        text: root.tooltip
                    }
                }
            }
        }
        Item { Layout.fillWidth: true }
    }
    ColumnLayout {
        id: sectionContent
        Layout.fillWidth: true
        spacing: 2
    }
}

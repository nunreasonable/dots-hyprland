import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Popup {
    id: root

    property list<var> actions: []

    width: 220
    padding: 8
    modal: false
    closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape

    background: Item {
        StyledRectangularShadow { target: popupBg }
        Rectangle {
            id: popupBg
            anchors.fill: parent
            radius: Appearance.rounding.small
            color: Appearance.m3colors.m3surfaceContainerHigh
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
        }
    }

    contentItem: ColumnLayout {
        spacing: 2

        Repeater {
            model: root.actions

            delegate: RippleButton {
                id: actionButton
                required property var modelData

                property bool confirming: false

                Layout.fillWidth: true
                implicitHeight: 40
                buttonRadius: Appearance.rounding.small
                colBackground: "transparent"
                colBackgroundHover: actionButton.confirming ? ColorUtils.transparentize(Appearance.colors.colError, 0.75) : Appearance.colors.colLayer2Hover
                colRipple: Appearance.colors.colLayer2Active
                horizontalPadding: 12

                Timer {
                    id: confirmResetTimer
                    interval: 2500
                    onTriggered: actionButton.confirming = false
                }

                onClicked: {
                    if (actionButton.modelData.confirm && !actionButton.confirming) {
                        actionButton.confirming = true;
                        confirmResetTimer.restart();
                        return;
                    }
                    actionButton.confirming = false;
                    root.close();
                    actionButton.modelData.onTrigger?.();
                }

                contentItem: RowLayout {
                    spacing: 10
                    MaterialSymbol {
                        text: actionButton.confirming ? "warning" : actionButton.modelData.icon
                        iconSize: Appearance.font.pixelSize.normal
                        color: actionButton.confirming ? Appearance.colors.colError : Appearance.colors.colOnLayer0
                    }
                    StyledText {
                        text: actionButton.confirming ? Translation.tr("Tap again to confirm") : actionButton.modelData.label
                        color: actionButton.confirming ? Appearance.colors.colError : Appearance.colors.colOnLayer0
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }
            }
        }
    }
}

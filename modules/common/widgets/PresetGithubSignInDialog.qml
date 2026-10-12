import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Popup {
    id: root

    modal: true
    focus: true
    closePolicy: Popup.NoAutoClose
    anchors.centerIn: parent
    width: 420
    padding: 24

    background: Item {
        StyledRectangularShadow { target: popupBg }
        Rectangle {
            id: popupBg
            anchors.fill: parent
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
        }
    }

    contentItem: ColumnLayout {
        spacing: 14

        MaterialSymbol {
            Layout.alignment: Qt.AlignHCenter
            text: "login"
            iconSize: 36
            color: Appearance.colors.colPrimary
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Translation.tr("Sign in to GitHub")
            font.pixelSize: Appearance.font.pixelSize.larger
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: Translation.tr("A browser window just opened. Enter this code there to connect your GitHub account.")
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: codeText.implicitWidth + 32
            implicitHeight: codeText.implicitHeight + 20
            radius: Appearance.rounding.small
            color: Appearance.colors.colLayer2

            StyledText {
                id: codeText
                anchors.centerIn: parent
                text: Presets.deviceFlowUserCode
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.Bold
                font.letterSpacing: 2
                color: Appearance.colors.colOnLayer2
            }
        }

        RippleButtonWithIcon {
            Layout.alignment: Qt.AlignHCenter
            materialIcon: "open_in_new"
            mainText: Translation.tr("Open GitHub again")
            colBackground: Appearance.colors.colSecondaryContainer
            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
            onClicked: Qt.openUrlExternally(Presets.deviceFlowVerificationUri)
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Translation.tr("Waiting for you to finish in the browser…")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }

        RippleButton {
            Layout.alignment: Qt.AlignHCenter
            implicitHeight: 40
            horizontalPadding: 20
            buttonRadius: 20
            colBackground: "transparent"
            colBackgroundHover: Appearance.colors.colLayer1Hover
            onClicked: Presets.cancelDeviceFlow()
            contentItem: StyledText {
                text: Translation.tr("Cancel")
                color: Appearance.colors.colOnLayer1
            }
        }
    }
}

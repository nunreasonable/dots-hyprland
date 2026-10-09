import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets as W
import qs.modules.ii.mediaControls as MC

Item {
    id: root

    readonly property var activePlayer: MprisController.activePlayer

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16
        visible: root.activePlayer === null

        W.MaterialSymbol {
            Layout.alignment: Qt.AlignHCenter
            text: "music_off"
            iconSize: Appearance.font.pixelSize.huge * 1.5
            color: Appearance.colors.colSubtext
        }
        W.StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Translation.tr("Nothing is playing")
            color: Appearance.colors.colSubtext
        }
    }

    Loader {
        anchors.centerIn: parent
        active: root.activePlayer !== null
        sourceComponent: MC.PlayerControl {
            player: root.activePlayer
            shown: true
            implicitWidth: Math.min(480, root.width - 32)
            implicitHeight: Math.min(320, root.height - 32)
            radius: Appearance.rounding.large
        }
    }
}

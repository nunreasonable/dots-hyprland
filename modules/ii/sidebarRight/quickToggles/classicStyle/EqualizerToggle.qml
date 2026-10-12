import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell.Io
import Quickshell

QuickToggleButton {
    id: root
    visible: Platform.isWindows && !!WindowsNative.equalizer && WindowsNative.equalizer.ready && WindowsNative.equalizer.hooked
    toggled: visible && !EqualizerApoBackend.bypassed
    buttonIcon: "equalizer"

    onClicked: {
        EqualizerApoBackend.toggleBypass()
    }

    altAction: () => {
        GlobalStates.equalizerOpen = true
        GlobalStates.sidebarRightOpen = false
    }

    StyledToolTip {
        text: Translation.tr("Equalizer | Right-click to open")
    }
}

import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick

QuickToggleModel {
    name: Translation.tr("Equalizer")

    available: Platform.isWindows && !!WindowsNative.equalizer && WindowsNative.equalizer.ready && WindowsNative.equalizer.hooked
    toggled: available && !EqualizerApoBackend.bypassed
    icon: "equalizer"

    mainAction: () => {
        EqualizerApoBackend.toggleBypass()
    }

    altAction: () => {
        GlobalStates.equalizerOpen = true
        GlobalStates.sidebarRightOpen = false
    }

    tooltipText: Translation.tr("Equalizer | Right-click to open")
}

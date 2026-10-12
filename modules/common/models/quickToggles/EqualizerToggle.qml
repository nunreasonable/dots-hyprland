import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick

// Windows-only - EasyEffects has its own toggle (EasyEffectsToggle.qml) on
// Linux. Left click bypasses/enables the Equalizer APO curve written by
// EqualizerApoBackend.qml; right click opens the full popup (bands/presets/
// Auto). Only shows as available once Equalizer APO is actually installed,
// active on the current output device, and hooked into config.txt - see
// WindowsNative.equalizer / EqualizerView.qml's apoUiReady for the same check.
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

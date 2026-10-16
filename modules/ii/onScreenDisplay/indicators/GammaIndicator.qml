import qs.services
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.ii.onScreenDisplay

OsdValueIndicator {
    id: rotateIcon

    icon: "wb_twilight"
    name: Platform.isWindows ? Translation.tr("Extra dimming") : Translation.tr("Gamma")
    from: Hyprsunset.gammaLowerLimit / 100
    value: Hyprsunset.gamma / 100 ?? 0.5
}

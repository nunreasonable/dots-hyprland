import QtQuick
import Quickshell

import qs.modules.common
import qs.modules.waffle.actionCenter
import qs.modules.waffle.background
import qs.modules.waffle.bar
import qs.modules.waffle.lock
import qs.modules.waffle.notificationCenter
import qs.modules.waffle.notificationPopup
import qs.modules.waffle.onScreenDisplay
// import qs.modules.waffle.overlay
import qs.modules.waffle.polkit
import qs.modules.waffle.screenSnip
import qs.modules.waffle.startMenu
import qs.modules.waffle.sessionScreen
import qs.modules.waffle.taskView

// Fallbacks
import qs.modules.ii.cheatsheet
import qs.modules.ii.colorPicker
import qs.modules.ii.onScreenKeyboard
import qs.modules.ii.overlay
import qs.modules.ii.screenTranslator
import qs.modules.ii.wallpaperSelector

Scope {
    PanelLoader { deferPriority: 1; panelSource: "../modules/waffle/actionCenter/WaffleActionCenter.qml" }
    PanelLoader { deferred: false; panelSource: "../modules/waffle/bar/WaffleBar.qml" }
    PanelLoader { deferPriority: 2; panelSource: "../modules/waffle/background/WaffleBackground.qml" }
    PanelLoader { deferred: Platform.isWindows && !Config.options.lock.launchOnStartup; panelSource: "../modules/waffle/lock/WaffleLock.qml" }
    PanelLoader { panelSource: "../modules/waffle/notificationCenter/WaffleNotificationCenter.qml" }
    PanelLoader { panelSource: "../modules/waffle/notificationPopup/WaffleNotificationPopup.qml" }
    PanelLoader { panelSource: "../modules/waffle/onScreenDisplay/WaffleOSD.qml" }
    // PanelLoader { component: WaffleOverlay {} }
    PanelLoader { panelSource: "../modules/waffle/polkit/WafflePolkit.qml" }
    PanelLoader { panelSource: "../modules/waffle/screenSnip/WScreenSnip.qml" }
    PanelLoader { deferPriority: 1; panelSource: "../modules/waffle/startMenu/WaffleStartMenu.qml" }
    PanelLoader { panelSource: "../modules/waffle/sessionScreen/WaffleSessionScreen.qml" }
    PanelLoader { panelSource: "../modules/waffle/taskView/WaffleTaskView.qml" }

    PanelLoader { panelSource: "../modules/ii/cheatsheet/Cheatsheet.qml" }
    PanelLoader { extraCondition: Platform.isWindows; panelSource: "../modules/ii/colorPicker/ColorPicker.qml" }
    PanelLoader { panelSource: "../modules/ii/onScreenKeyboard/OnScreenKeyboard.qml" }
    PanelLoader { panelSource: "../modules/ii/overlay/Overlay.qml" }
    PanelLoader { panelSource: "../modules/ii/screenTranslator/ScreenTranslator.qml" }
    PanelLoader { panelSource: "../modules/ii/wallpaperSelector/WallpaperSelector.qml" }
}

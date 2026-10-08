import QtQuick
import Quickshell

import qs.modules.common

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

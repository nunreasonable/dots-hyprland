import QtQuick
import Quickshell

import qs.modules.common

Scope {
    PanelLoader { deferred: false; extraCondition: !Config.options.bar.vertical && !(Platform.isWindows && Config.options.windowsPort.nativeTaskbar); panelSource: "../modules/ii/bar/Bar.qml" }
    PanelLoader { deferPriority: 2; panelSource: "../modules/ii/background/Background.qml" }
    PanelLoader { panelSource: "../modules/ii/cheatsheet/Cheatsheet.qml" }
    PanelLoader { deferPriority: 1; panelSource: "../modules/ii/desktopMenu/DesktopMenu.qml" }
    PanelLoader { deferPriority: 1; panelSource: "../modules/ii/dropover/DropShelfPanel.qml" }
    PanelLoader { extraCondition: Platform.isWindows; panelSource: "../modules/ii/colorPicker/ColorPicker.qml" }
    PanelLoader { deferPriority: 1; extraCondition: Config.options.dock.enable; panelSource: "../modules/ii/dock/Dock.qml" }
    PanelLoader { deferPriority: 2; extraCondition: Config.options.bar.showFrame; panelSource: "../modules/ii/frame/ScreenFrame.qml" }
    PanelLoader { deferred: Platform.isWindows && !Config.options.lock.launchOnStartup; panelSource: "../modules/ii/lock/Lock.qml" }
    PanelLoader { panelSource: "../modules/ii/mediaControls/MediaControls.qml" }
    PanelLoader { panelSource: "../modules/ii/notificationPopup/NotificationPopup.qml" }
    PanelLoader { panelSource: "../modules/ii/onScreenDisplay/OnScreenDisplay.qml" }
    PanelLoader { panelSource: "../modules/ii/onScreenKeyboard/OnScreenKeyboard.qml" }
    PanelLoader { panelSource: "../modules/ii/overlay/Overlay.qml" }
    PanelLoader { deferPriority: 1; panelSource: "../modules/ii/overview/Overview.qml" }
    PanelLoader { deferPriority: 1; extraCondition: Config.options.search.spotlight; panelSource: "../modules/ii/spotlight/Spotlight.qml" }
    PanelLoader { panelSource: "../modules/ii/polkit/Polkit.qml" }
    PanelLoader { panelSource: "../modules/ii/regionSelector/RegionSelector.qml" }
    PanelLoader { deferPriority: 1; panelSource: "../modules/ii/screenCorners/ScreenCorners.qml" }
    PanelLoader { panelSource: "../modules/ii/screenTranslator/ScreenTranslator.qml" }
    PanelLoader { panelSource: "../modules/ii/sessionScreen/SessionScreen.qml" }
    PanelLoader { deferPriority: 1; panelSource: "../modules/ii/sidebarLeft/SidebarLeft.qml" }
    PanelLoader { deferPriority: 1; panelSource: "../modules/ii/sidebarRight/SidebarRight.qml" }
    PanelLoader { deferred: false; extraCondition: Config.options.bar.vertical && !(Platform.isWindows && Config.options.windowsPort.nativeTaskbar); panelSource: "../modules/ii/verticalBar/VerticalBar.qml" }
    PanelLoader { panelSource: "../modules/ii/wallpaperSelector/WallpaperSelector.qml" }
}

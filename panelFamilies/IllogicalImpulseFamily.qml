import QtQuick
import Quickshell

import qs.modules.common
import qs.modules.ii.background
import qs.modules.ii.bar
import qs.modules.ii.cheatsheet
import qs.modules.ii.colorPicker
import qs.modules.ii.dock
import qs.modules.ii.lock
import qs.modules.ii.mediaControls
import qs.modules.ii.notificationPopup
import qs.modules.ii.onScreenDisplay
import qs.modules.ii.onScreenKeyboard
import qs.modules.ii.overview
import qs.modules.ii.polkit
import qs.modules.ii.regionSelector
import qs.modules.ii.screenCorners
import qs.modules.ii.screenTranslator
import qs.modules.ii.sessionScreen
import qs.modules.ii.sidebarLeft
import qs.modules.ii.sidebarRight
import qs.modules.ii.spotlight
import qs.modules.ii.overlay
import qs.modules.ii.verticalBar
import qs.modules.ii.wallpaperSelector

Scope {
    PanelLoader { deferred: false; extraCondition: !Config.options.bar.vertical; panelSource: "../modules/ii/bar/Bar.qml" }
    PanelLoader { deferPriority: 2; panelSource: "../modules/ii/background/Background.qml" }
    PanelLoader { panelSource: "../modules/ii/cheatsheet/Cheatsheet.qml" }
    PanelLoader { extraCondition: Platform.isWindows; panelSource: "../modules/ii/colorPicker/ColorPicker.qml" }
    PanelLoader { deferPriority: 1; extraCondition: Config.options.dock.enable; panelSource: "../modules/ii/dock/Dock.qml" }
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
    PanelLoader { deferred: false; extraCondition: Config.options.bar.vertical; panelSource: "../modules/ii/verticalBar/VerticalBar.qml" }
    PanelLoader { panelSource: "../modules/ii/wallpaperSelector/WallpaperSelector.qml" }
}

import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property bool barOpen: true
    property bool colorPickerOpen: false
    property string colorPickerAction: "copy"
    property bool crosshairOpen: false
    property bool desktopMenuOpen: false
    property var desktopMenuScreen: null
    property real desktopMenuX: 0
    property real desktopMenuY: 0
    property bool dropoverOpen: false
    property var dropoverScreen: null
    property real dropoverX: 0
    property real dropoverY: 0
    property bool sidebarLeftOpen: false
    property bool sidebarRightOpen: false
    property bool mediaControlsOpen: false
    property bool osdBrightnessOpen: false
    property bool osdVolumeOpen: false
    property bool oskOpen: false
    property bool overlayOpen: false
    property bool overviewOpen: false
    property bool regionSelectorOpen: false
    property bool searchOpen: false
    property bool screenLocked: false
    property bool screenLockContainsCharacters: false
    property bool screenUnlockFailed: false
    property bool screenTranslatorOpen: false
    property bool sessionOpen: false
    property bool superDown: false
    property bool superReleaseMightTrigger: true
    property bool spotlightOpen: false
    property string spotlightMode: ""
    property bool wallpaperSelectorOpen: false
    property bool workspaceShowNumbers: false
    property bool barStyleEditorOpen: false
    property bool barCenterOnly: false
    property bool diSessionOpen: false
    property string osdIndicatorType: "volume"
    property var frameHover: ({})
    readonly property bool dynamicIslandEnabled: !Config.options.bar.vertical
        && Config.options.bar.layouts.middleLayout.includes("dynamicIsland")
    property int dynamicIslandsShown: 0
    readonly property bool dynamicIslandActive: root.dynamicIslandEnabled && root.dynamicIslandsShown > 0 && root.barOpen && !root.screenLocked
        && !(Platform.isWindows && Config.options.windowsPort.nativeTaskbar)

    function setFrameHover(screenName, side, hovered) {
        const key = `${screenName}:${side}`;
        if ((root.frameHover[key] ?? false) === hovered)
            return;
        const next = Object.assign({}, root.frameHover);
        next[key] = hovered;
        root.frameHover = next;
    }

    function isFrameHovered(screenName, side) {
        return root.frameHover[`${screenName}:${side}`] ?? false;
    }
    property bool desktopWidgetKeyboardFocus: false

    readonly property var centeredShapeOptions: [
        "Circle", "Square", "Slanted", "Arch", "Arrow", "SemiCircle", "Oval", "Pill",
        "Triangle", "Diamond", "ClamShell", "Pentagon", "Gem", "Sunny", "VerySunny",
        "Cookie4Sided", "Cookie6Sided", "Cookie7Sided", "Cookie9Sided", "Cookie12Sided",
        "Ghostish", "Clover4Leaf", "Clover8Leaf", "Burst", "SoftBurst", "Flower",
        "Puffy", "PuffyDiamond", "PixelCircle", "Bun", "Heart"
    ]
    property bool bluetoothDialogRequested: false

    readonly property var hotCornerOptions: [
        { displayName: Translation.tr("None"), value: "none" },
        { displayName: Translation.tr("Left Sidebar"), value: "sidebarLeftOpen" },
        { displayName: Translation.tr("Right Sidebar"), value: "sidebarRightOpen" },
        { displayName: Translation.tr("Overview"), value: "overviewOpen" },
        { displayName: Translation.tr("Spotlight search"), value: "spotlightOpen" },
        { displayName: Translation.tr("Wallpaper selector"), value: "wallpaperSelectorOpen" },
        { displayName: Translation.tr("Media Controls"), value: "mediaControlsOpen" },
        { displayName: Translation.tr("Overlay"), value: "overlayOpen" },
        { displayName: Translation.tr("Screenshot Region"), value: "regionSelectorOpen" },
        { displayName: Translation.tr("Screen Translator"), value: "screenTranslatorOpen" },
        { displayName: Translation.tr("On-screen keyboard"), value: "oskOpen" },
        { displayName: Translation.tr("Session Menu"), value: "sessionOpen" }
    ]

    function toggleState(name) {
        if (!name || name === "none") return;
        root[name] = !root[name];
    }

    onSidebarRightOpenChanged: {
        if (GlobalStates.sidebarRightOpen) {
            Notifications.timeoutAll();
            Notifications.markAllRead();
        }
    }

    GlobalShortcut {
        name: "workspaceNumber"
        description: "Hold to show workspace numbers, release to show icons"

        onPressed: {
            root.superDown = true
        }
        onReleased: {
            root.superDown = false
        }
    }
}
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "view_quilt"
        title: Translation.tr("Panel style")

        ConfigSelectionArray {
            currentValue: Config.options.panelFamily
            onSelected: newValue => {
                Config.options.panelFamily = newValue;
            }
            options: [
                { displayName: Translation.tr("illogical-impulse"), icon: "view_quilt", value: "ii" },
                { displayName: Translation.tr("Waffle"), icon: "widgets", value: "waffle" }
            ]
        }
    }

    ContentSection {
        icon: "keyboard"
        title: Translation.tr("Cheat sheet")

        ContentSubsection {
            title: Translation.tr("Super key symbol")
            tooltip: Translation.tr("You can also manually edit cheatsheet.superKey")
            ConfigSelectionArray {
                currentValue: Config.options.cheatsheet.superKey
                onSelected: newValue => {
                    Config.options.cheatsheet.superKey = newValue;
                }
                // Use a nerdfont to see the icons
                options: ([
                  "󰖳", "", "󰨡", "", "󰌽", "󰣇", "", "", "", 
                  "", "", "󱄛", "", "", "", "⌘", "󰀲", "󰟍", ""
                ]).map(icon => { return {
                  displayName: icon,
                  value: icon
                  }
                })
            }
        }

        ConfigSwitch {
            buttonIcon: "󰘵"
            text: Translation.tr("Use macOS-like symbols for mods keys")
            checked: Config.options.cheatsheet.useMacSymbol
            onCheckedChanged: {
                Config.options.cheatsheet.useMacSymbol = checked;
            }
            StyledToolTip {
                text: Translation.tr("e.g. 󰘴  for Ctrl, 󰘵  for Alt, 󰘶  for Shift, etc")
            }
        }

        ConfigSwitch {
            buttonIcon: "󱊶"
            text: Translation.tr("Use symbols for function keys")
            checked: Config.options.cheatsheet.useFnSymbol
            onCheckedChanged: {
                Config.options.cheatsheet.useFnSymbol = checked;
            }
            StyledToolTip {
              text: Translation.tr("e.g. 󱊫 for F1, 󱊶  for F12")
            }
        }
        ConfigSwitch {
            buttonIcon: "󰍽"
            text: Translation.tr("Use symbols for mouse")
            checked: Config.options.cheatsheet.useMouseSymbol
            onCheckedChanged: {
                Config.options.cheatsheet.useMouseSymbol = checked;
            }
            StyledToolTip {
              text: Translation.tr("Replace 󱕐   for \"Scroll ↓\", 󱕑   \"Scroll ↑\", L󰍽   \"LMB\", R󰍽   \"RMB\", 󱕒   \"Scroll ↑/↓\" and ⇞/⇟ for \"Page_↑/↓\"")
            }
        }
        ConfigSwitch {
            buttonIcon: "highlight_keyboard_focus"
            text: Translation.tr("Split buttons")
            checked: Config.options.cheatsheet.splitButtons
            onCheckedChanged: {
                Config.options.cheatsheet.splitButtons = checked;
            }
            StyledToolTip {
                text: Translation.tr("Display modifiers and keys in multiple keycap (e.g., \"Ctrl + A\" instead of \"Ctrl A\" or \"󰘴 + A\" instead of \"󰘴 A\")")
            }

        }

        ConfigSpinBox {
            text: Translation.tr("Keybind font size")
            value: Config.options.cheatsheet.fontSize.key
            from: 8
            to: 30
            stepSize: 1
            onValueChanged: {
                Config.options.cheatsheet.fontSize.key = value;
            }
        }
        ConfigSpinBox {
            text: Translation.tr("Description font size")
            value: Config.options.cheatsheet.fontSize.comment
            from: 8
            to: 30
            stepSize: 1
            onValueChanged: {
                Config.options.cheatsheet.fontSize.comment = value;
            }
        }
    }
    ContentSection {
        icon: "call_to_action"
        title: Translation.tr("Dock")

        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable")
            checked: Config.options.dock.enable
            onCheckedChanged: {
                Config.options.dock.enable = checked;
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "highlight_mouse_cursor"
                text: Translation.tr("Hover to reveal")
                checked: Config.options.dock.hoverToReveal
                onCheckedChanged: {
                    Config.options.dock.hoverToReveal = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "keep"
                text: Translation.tr("Pinned on startup")
                checked: Config.options.dock.pinnedOnStartup
                onCheckedChanged: {
                    Config.options.dock.pinnedOnStartup = checked;
                }
            }
        }
        ConfigSwitch {
            buttonIcon: "colors"
            text: Translation.tr("Tint app icons")
            checked: Config.options.dock.monochromeIcons
            onCheckedChanged: {
                Config.options.dock.monochromeIcons = checked;
            }
        }

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "height"
                text: Translation.tr("Height (px)")
                value: Config.options.dock.height
                from: 20
                to: 200
                stepSize: 1
                onValueChanged: {
                    Config.options.dock.height = value;
                }
            }
            ConfigSpinBox {
                icon: "swipe_up"
                text: Translation.tr("Hover region height (px)")
                value: Config.options.dock.hoverRegionHeight
                from: 1
                to: 50
                stepSize: 1
                onValueChanged: {
                    Config.options.dock.hoverRegionHeight = value;
                }
                StyledToolTip {
                    text: Translation.tr("How tall the strip at the screen edge has to be hovered to reveal the dock")
                }
            }
        }

        ConfigRow {
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("App IDs to hide from the dock, as regexes, comma-separated (e.g. explorer.exe, ^Shell_)")
                text: Config.options.dock.ignoredAppRegexes.join(", ")
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.dock.ignoredAppRegexes = text.split(",").map(s => s.trim()).filter(s => s.length > 0);
                }
            }
        }
    }

    ContentSection {
        visible: Platform.isWindows
        icon: "toolbar"
        title: Translation.tr("Windows taskbar")

        ConfigSwitch {
            buttonIcon: "web_traffic"
            text: Translation.tr("Show only when the cursor touches its screen edge")
            checked: Config.options.windowsPort.taskbarHoverOnly
            onCheckedChanged: {
                Config.options.windowsPort.taskbarHoverOnly = checked;
            }
            StyledToolTip {
                text: Translation.tr("Keeps Windows from bringing the taskbar up when an app flashes or nothing else is focused.\nTurns on the taskbar's auto-hide while enabled.")
            }
        }
    }

    ContentSection {
        visible: Platform.isWindows
        icon: "dashboard"
        title: Translation.tr("Windows tiling")

        ConfigSwitch {
            buttonIcon: "grid_view"
            text: Translation.tr("Tile windows")
            checked: Config.options.windowsPort.tiling.enable
            onCheckedChanged: {
                Config.options.windowsPort.tiling.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Arranges windows in a dwindle layout (like Hyprland) inside the space left by the bar and the taskbar.\nOff by default; turning it off puts every window back where it was before tiling.")
            }
        }

        ConfigSwitch {
            buttonIcon: "open_with"
            text: Translation.tr("Super + drag moves and resizes windows")
            checked: Config.options.windowsPort.superDrag
            onCheckedChanged: {
                Config.options.windowsPort.superDrag = checked;
            }
            StyledToolTip {
                text: Translation.tr("Hold the Windows key and drag with the left button to move a window, or with the right button to resize it from the nearest corner.\nWorks with tiling on or off; with tiling on, dropping a window on another one swaps them and resizing moves the split.")
            }
        }

        ConfigSpinBox {
            icon: "space_bar"
            text: Translation.tr("Gap between windows (px)")
            value: Config.options.windowsPort.tiling.gapsIn
            from: 0
            to: 64
            stepSize: 1
            onValueChanged: {
                Config.options.windowsPort.tiling.gapsIn = value;
            }
        }

        ConfigSpinBox {
            icon: "space_dashboard"
            text: Translation.tr("Gap to screen edges (px)")
            value: Config.options.windowsPort.tiling.gapsOut
            from: 0
            to: 64
            stepSize: 1
            onValueChanged: {
                Config.options.windowsPort.tiling.gapsOut = value;
            }
        }

        ConfigSwitch {
            buttonIcon: "splitscreen"
            text: Translation.tr("Keep each split's direction")
            checked: Config.options.windowsPort.tiling.preserveSplit
            onCheckedChanged: {
                Config.options.windowsPort.tiling.preserveSplit = checked;
            }
            StyledToolTip {
                text: Translation.tr("A split keeps the direction it was made with until Super+\\ flips it.\nOff: a split follows its area's shape instead.")
            }
        }

        ConfigRow {
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Apps that always float, one per line: process name (notepad.exe), app id, window class, or title:<pattern>")
                text: Config.options.windowsPort.tiling.excluded.join("\n")
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.windowsPort.tiling.excluded = text.split("\n").map(s => s.trim());
                }
            }
        }
    }

    ContentSection {
        icon: "swipe"
        title: Translation.tr("Interactions")

        ConfigSwitch {
            buttonIcon: "swipe"
            text: Translation.tr("Faster touchpad/mouse scrolling")
            checked: Config.options.interactions.scrolling.fasterTouchpadScroll
            onCheckedChanged: {
                Config.options.interactions.scrolling.fasterTouchpadScroll = checked;
            }
            StyledToolTip {
                text: Translation.tr("Replaces the default scroll handling with an animated one, using the factors below")
            }
        }

        ConfigSpinBox {
            enabled: Config.options.interactions.scrolling.fasterTouchpadScroll
            icon: "mouse"
            text: Translation.tr("Mouse wheel detection threshold")
            value: Config.options.interactions.scrolling.mouseScrollDeltaThreshold
            from: 1
            to: 1000
            stepSize: 10
            onValueChanged: {
                Config.options.interactions.scrolling.mouseScrollDeltaThreshold = value;
            }
            StyledToolTip {
                text: Translation.tr("A scroll delta at or above this is treated as a mouse wheel notch instead of a touchpad swipe")
            }
        }

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                enabled: Config.options.interactions.scrolling.fasterTouchpadScroll
                icon: "mouse"
                text: Translation.tr("Mouse scroll factor")
                value: Config.options.interactions.scrolling.mouseScrollFactor
                from: 10
                to: 2000
                stepSize: 10
                onValueChanged: {
                    Config.options.interactions.scrolling.mouseScrollFactor = value;
                }
            }
            ConfigSpinBox {
                enabled: Config.options.interactions.scrolling.fasterTouchpadScroll
                icon: "swipe"
                text: Translation.tr("Touchpad scroll factor")
                value: Config.options.interactions.scrolling.touchpadScrollFactor
                from: 10
                to: 2000
                stepSize: 10
                onValueChanged: {
                    Config.options.interactions.scrolling.touchpadScrollFactor = value;
                }
                StyledToolTip {
                    text: Translation.tr("Higher moves more per scroll notch/swipe")
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "border_right"
            text: Translation.tr("Dead pixel workaround")
            checked: Config.options.interactions.deadPixelWorkaround.enable
            onCheckedChanged: {
                Config.options.interactions.deadPixelWorkaround.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Shifts the bar and screen corners 1px so a display that leaves out its edge pixel still gets full hover/click coverage")
            }
        }
    }

    ContentSection {
        icon: "lock"
        title: Translation.tr("Lock screen")
        visible: !Platform.isWindows

        ConfigSwitch {
            buttonIcon: "water_drop"
            text: Translation.tr('Use Hyprlock (instead of Quickshell)')
            checked: Config.options.lock.useHyprlock
            onCheckedChanged: {
                Config.options.lock.useHyprlock = checked;
            }
            StyledToolTip {
                text: Translation.tr("If you want to somehow use fingerprint unlock...")
            }
        }

        ConfigSwitch {
            buttonIcon: "account_circle"
            text: Translation.tr('Launch on startup')
            checked: Config.options.lock.launchOnStartup
            onCheckedChanged: {
                Config.options.lock.launchOnStartup = checked;
            }
        }

        ContentSubsection {
            title: Translation.tr("Security")

            ConfigSwitch {
                buttonIcon: "settings_power"
                text: Translation.tr('Require password to power off/restart')
                checked: Config.options.lock.security.requirePasswordToPower
                onCheckedChanged: {
                    Config.options.lock.security.requirePasswordToPower = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Remember that on most devices one can always hold the power button to force shutdown\nThis only makes it a tiny bit harder for accidents to happen")
                }
            }

            ConfigSwitch {
                buttonIcon: "key_vertical"
                text: Translation.tr('Also unlock keyring')
                checked: Config.options.lock.security.unlockKeyring
                onCheckedChanged: {
                    Config.options.lock.security.unlockKeyring = checked;
                }
                StyledToolTip {
                    text: Translation.tr("This is usually safe and needed for your browser and AI sidebar anyway\nMostly useful for those who use lock on startup instead of a display manager that does it (GDM, SDDM, etc.)")
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Style: general")

            ConfigSwitch {
                buttonIcon: "center_focus_weak"
                text: Translation.tr('Center clock')
                checked: Config.options.lock.centerClock
                onCheckedChanged: {
                    Config.options.lock.centerClock = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "info"
                text: Translation.tr('Show "Locked" text')
                checked: Config.options.lock.showLockedText
                onCheckedChanged: {
                    Config.options.lock.showLockedText = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "shapes"
                text: Translation.tr('Use varying shapes for password characters')
                checked: Config.options.lock.materialShapeChars
                onCheckedChanged: {
                    Config.options.lock.materialShapeChars = checked;
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Style: Blurred")

            ConfigSwitch {
                buttonIcon: "blur_on"
                text: Translation.tr('Enable blur')
                checked: Config.options.lock.blur.enable
                onCheckedChanged: {
                    Config.options.lock.blur.enable = checked;
                }
            }

            ConfigSpinBox {
                icon: "loupe"
                text: Translation.tr("Extra wallpaper zoom (%)")
                value: Config.options.lock.blur.extraZoom * 100
                from: 1
                to: 150
                stepSize: 2
                onValueChanged: {
                    Config.options.lock.blur.extraZoom = value / 100;
                }
            }
        }
    }

    ContentSection {
        icon: "notifications"
        title: Translation.tr("Notifications")

        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Timeout duration (if not defined by notification) (ms)")
            value: Config.options.notifications.timeout
            from: 1000
            to: 60000
            stepSize: 1000
            onValueChanged: {
                Config.options.notifications.timeout = value;
            }
        }

        ConfigSwitch {
            buttonIcon: "monitor"
            text: Translation.tr("Force specific monitor")
            checked: Config.options.notifications.forceMonitor.enable
            onCheckedChanged: {
                Config.options.notifications.forceMonitor.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("If you have multiple monitors and want notifications to only show on one of them, enable this and enter the monitor name below (e.g., eDP-1)")
            }
        }

        ConfigRow {
            enabled: Config.options.notifications.forceMonitor.enable
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Monitor name to show notifications on (e.g., eDP-1)")
                text: Config.options.notifications.forceMonitor.name
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.notifications.forceMonitor.name = text;
                }
            }
        }
    }

    ContentSection {
        icon: "music_note"
        title: Translation.tr("Media")

        ConfigSwitch {
            buttonIcon: "music_note"
            text: Translation.tr("Filter duplicate players")
            checked: Config.options.media.filterDuplicatePlayers
            onCheckedChanged: {
                Config.options.media.filterDuplicatePlayers = checked;
            }
            StyledToolTip {
                text: Translation.tr("Hides a player that looks like a duplicate of another one (e.g. a browser's native player showing up alongside its tab-aggregated one)")
            }
        }
    }

    ContentSection {
        icon: "select_window"
        title: Translation.tr("Overlay: General")

        ConfigSwitch {
            buttonIcon: "high_density"
            text: Translation.tr("Enable opening zoom animation")
            checked: Config.options.overlay.openingZoomAnimation
            onCheckedChanged: {
                Config.options.overlay.openingZoomAnimation = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "texture"
            text: Translation.tr("Darken screen")
            checked: Config.options.overlay.darkenScreen
            onCheckedChanged: {
                Config.options.overlay.darkenScreen = checked;
            }
        }
        ConfigSpinBox {
            icon: "opacity"
            text: Translation.tr("Clickthrough widget opacity (%)")
            value: Config.options.overlay.clickthroughOpacity * 100
            from: 0
            to: 100
            stepSize: 5
            onValueChanged: {
                Config.options.overlay.clickthroughOpacity = value / 100;
            }
            StyledToolTip {
                text: Translation.tr("How visible pinned, clickthrough overlay widgets (like the floating image) stay while the overlay menu is closed")
            }
        }
    }

    ContentSection {
        icon: "point_scan"
        title: Translation.tr("Overlay: Crosshair")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Crosshair code (in Valorant's format)")
            text: Config.options.crosshair.code
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.crosshair.code = text;
            }
        }

        RowLayout {
            StyledText {
                Layout.leftMargin: 10
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smallie
                text: Translation.tr("Press Super+G to open the overlay and pin the crosshair")
            }
            Item {
                Layout.fillWidth: true
            }
            RippleButtonWithIcon {
                id: editorButton
                buttonRadius: Appearance.rounding.full
                materialIcon: "open_in_new"
                mainText: Translation.tr("Open editor")
                onClicked: {
                    Qt.openUrlExternally(`https://www.vcrdb.net/builder?c=${Config.options.crosshair.code}`);
                }
                StyledToolTip {
                    text: "www.vcrdb.net"
                }
            }
        }
    }

    ContentSection {
        icon: "point_scan"
        title: Translation.tr("Overlay: Floating Image")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Image source")
            text: Config.options.overlay.floatingImage.imageSource
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.overlay.floatingImage.imageSource = text;
            }
        }

        ConfigSpinBox {
            icon: "loupe"
            text: Translation.tr("Scale (%)")
            value: Config.options.overlay.floatingImage.scale * 100
            from: 10
            to: 500
            stepSize: 10
            onValueChanged: {
                Config.options.overlay.floatingImage.scale = value / 100;
            }
            StyledToolTip {
                text: Translation.tr("Can also be changed by scrolling on the image itself")
            }
        }
    }

    ContentSection {
        icon: "screenshot_frame_2"
        title: Translation.tr("Region selector (screen snipping/Google Lens)")

        ContentSubsection {
            title: Translation.tr("Hint target regions")
            ConfigRow {
                ConfigSwitch {
                    buttonIcon: "select_window"
                    text: Translation.tr('Windows')
                    checked: Config.options.regionSelector.targetRegions.windows
                    onCheckedChanged: {
                        Config.options.regionSelector.targetRegions.windows = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "right_panel_open"
                    text: Translation.tr('Layers')
                    checked: Config.options.regionSelector.targetRegions.layers
                    onCheckedChanged: {
                        Config.options.regionSelector.targetRegions.layers = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "nearby"
                    text: Translation.tr('Content')
                    checked: Config.options.regionSelector.targetRegions.content
                    onCheckedChanged: {
                        Config.options.regionSelector.targetRegions.content = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Could be images or parts of the screen that have some containment.\nMight not always be accurate.\nThis is done with an image processing algorithm run locally and no AI is used.")
                    }
                }
            }

            ConfigSwitch {
                buttonIcon: "label"
                text: Translation.tr("Show label")
                checked: Config.options.regionSelector.targetRegions.showLabel
                onCheckedChanged: {
                    Config.options.regionSelector.targetRegions.showLabel = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Shows the app/window name on top of a hinted region")
                }
            }

            ConfigRow {
                uniform: true
                ConfigSpinBox {
                    icon: "opacity"
                    text: Translation.tr("Window/layer opacity (%)")
                    value: Config.options.regionSelector.targetRegions.opacity * 100
                    from: 0
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.options.regionSelector.targetRegions.opacity = value / 100;
                    }
                }
                ConfigSpinBox {
                    visible: !Platform.isWindows
                    icon: "opacity"
                    text: Translation.tr("Content region opacity (%)")
                    value: Config.options.regionSelector.targetRegions.contentRegionOpacity * 100
                    from: 0
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.options.regionSelector.targetRegions.contentRegionOpacity = value / 100;
                    }
                }
            }

            ConfigSpinBox {
                icon: "screenshot_frame_2"
                text: Translation.tr("Selection padding (px)")
                value: Config.options.regionSelector.targetRegions.selectionPadding
                from: 0
                to: 50
                stepSize: 1
                onValueChanged: {
                    Config.options.regionSelector.targetRegions.selectionPadding = value;
                }
                StyledToolTip {
                    text: Translation.tr("Extra padding added around a hinted region when it's picked as the selection")
                }
            }
        }

        ContentSubsection {
            visible: !Platform.isWindows
            title: Translation.tr("Annotation")

            ConfigSwitch {
                buttonIcon: "draw"
                text: Translation.tr("Use Satty")
                checked: Config.options.regionSelector.annotation.useSatty
                onCheckedChanged: {
                    Config.options.regionSelector.annotation.useSatty = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Needs satty installed. When off, uses swappy instead")
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Google Lens")
            
            ConfigSelectionArray {
                currentValue: Config.options.search.imageSearch.useCircleSelection ? "circle" : "rectangles"
                onSelected: newValue => {
                    Config.options.search.imageSearch.useCircleSelection = (newValue === "circle");
                }
                options: [
                    { icon: "activity_zone", value: "rectangles", displayName: Translation.tr("Rectangular selection") },
                    { icon: "gesture", value: "circle", displayName: Translation.tr("Circle to Search") }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Rectangular selection")

            ConfigSwitch {
                buttonIcon: "point_scan"
                text: Translation.tr("Show aim lines")
                checked: Config.options.regionSelector.rect.showAimLines
                onCheckedChanged: {
                    Config.options.regionSelector.rect.showAimLines = checked;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Circle selection")
            
            ConfigSpinBox {
                icon: "eraser_size_3"
                text: Translation.tr("Stroke width")
                value: Config.options.regionSelector.circle.strokeWidth
                from: 1
                to: 20
                stepSize: 1
                onValueChanged: {
                    Config.options.regionSelector.circle.strokeWidth = value;
                }
            }

            ConfigSpinBox {
                icon: "screenshot_frame_2"
                text: Translation.tr("Padding")
                value: Config.options.regionSelector.circle.padding
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.regionSelector.circle.padding = value;
                }
            }
        }
    }

    ContentSection {
        icon: "keyboard"
        title: Translation.tr("On-screen keyboard")

        ContentSubsection {
            title: Translation.tr("Layout")
            ConfigSelectionArray {
                currentValue: Config.options.osk.layout
                onSelected: newValue => {
                    Config.options.osk.layout = newValue;
                }
                options: [
                    { displayName: Translation.tr("English (US)"), value: "English (US)" },
                    { displayName: Translation.tr("German"), value: "German" },
                    { displayName: Translation.tr("Russian"), value: "Russian" }
                ]
            }
        }

        ConfigSwitch {
            buttonIcon: "keep"
            text: Translation.tr("Pinned on startup")
            checked: Config.options.osk.pinnedOnStartup
            onCheckedChanged: {
                Config.options.osk.pinnedOnStartup = checked;
            }
        }
    }

    ContentSection {
        icon: "side_navigation"
        title: Translation.tr("Sidebars")

        ConfigSwitch {
            buttonIcon: "memory"
            text: Translation.tr('Keep right sidebar loaded')
            checked: Config.options.sidebar.keepRightSidebarLoaded
            onCheckedChanged: {
                Config.options.sidebar.keepRightSidebarLoaded = checked;
            }
            StyledToolTip {
                text: Translation.tr("When enabled keeps the content of the right sidebar loaded to reduce the delay when opening,\nat the cost of around 15MB of consistent RAM usage. Delay significance depends on your system's performance.\nUsing a custom kernel like linux-cachyos might help")
            }
        }

        ConfigSwitch {
            buttonIcon: "translate"
            text: Translation.tr('Enable translator')
            checked: Config.options.sidebar.translator.enable
            onCheckedChanged: {
                Config.options.sidebar.translator.enable = checked;
            }
        }

        ContentSubsection {
            title: Translation.tr("Quick toggles")
            
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.sidebar.quickToggles.style
                onSelected: newValue => {
                    Config.options.sidebar.quickToggles.style = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "password_2",
                        value: "classic"
                    },
                    {
                        displayName: Translation.tr("Android"),
                        icon: "action_key",
                        value: "android"
                    }
                ]
            }

            ConfigSpinBox {
                enabled: Config.options.sidebar.quickToggles.style === "android"
                icon: "splitscreen_left"
                text: Translation.tr("Columns")
                value: Config.options.sidebar.quickToggles.android.columns
                from: 1
                to: 8
                stepSize: 1
                onValueChanged: {
                    Config.options.sidebar.quickToggles.android.columns = value;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Sliders")

            ConfigSwitch {
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.sidebar.quickSliders.enable
                onCheckedChanged: {
                    Config.options.sidebar.quickSliders.enable = checked;
                }
            }
            
            ConfigSwitch {
                buttonIcon: "brightness_6"
                text: Translation.tr("Brightness")
                enabled: Config.options.sidebar.quickSliders.enable
                checked: Config.options.sidebar.quickSliders.showBrightness
                onCheckedChanged: {
                    Config.options.sidebar.quickSliders.showBrightness = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "volume_up"
                text: Translation.tr("Volume")
                enabled: Config.options.sidebar.quickSliders.enable
                checked: Config.options.sidebar.quickSliders.showVolume
                onCheckedChanged: {
                    Config.options.sidebar.quickSliders.showVolume = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "mic"
                text: Translation.tr("Microphone")
                enabled: Config.options.sidebar.quickSliders.enable
                checked: Config.options.sidebar.quickSliders.showMic
                onCheckedChanged: {
                    Config.options.sidebar.quickSliders.showMic = checked;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Corner open")
            tooltip: Translation.tr("Allows you to open sidebars by clicking or hovering screen corners regardless of bar position")
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.sidebar.cornerOpen.enable
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.enable = checked;
                    }
                }
            }
            ConfigSwitch {
                buttonIcon: "highlight_mouse_cursor"
                text: Translation.tr("Hover to trigger")
                checked: Config.options.sidebar.cornerOpen.clickless
                onCheckedChanged: {
                    Config.options.sidebar.cornerOpen.clickless = checked;
                }

                StyledToolTip {
                    text: Translation.tr("When this is off you'll have to click")
                }
            }
            Row {
                ConfigSwitch {
                    enabled: !Config.options.sidebar.cornerOpen.clickless
                    text: Translation.tr("Force hover open at absolute corner")
                    checked: Config.options.sidebar.cornerOpen.clicklessCornerEnd
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.clicklessCornerEnd = checked;
                    }

                    StyledToolTip {
                        text: Translation.tr("When the previous option is off and this is on,\nyou can still hover the corner's end to open sidebar,\nand the remaining area can be used for volume/brightness scroll")
                    }
                }
                ConfigSpinBox {
                    icon: "arrow_cool_down"
                    text: Translation.tr("with vertical offset")
                    value: Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset
                    from: 0
                    to: 20
                    stepSize: 1
                    onValueChanged: {
                        Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset = value;
                    }
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                        StyledToolTip {
                            extraVisibleCondition: mouseArea.containsMouse
                            text: Translation.tr("Why this is cool:\nFor non-0 values, it won't trigger when you reach the\nscreen corner along the horizontal edge, but it will when\nyou do along the vertical edge")
                        }
                    }
                }
            }
            
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "vertical_align_bottom"
                    text: Translation.tr("Place at bottom")
                    checked: Config.options.sidebar.cornerOpen.bottom
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.bottom = checked;
                    }

                    StyledToolTip {
                        text: Translation.tr("Place the corners to trigger at the bottom")
                    }
                }
                ConfigSwitch {
                    buttonIcon: "unfold_more_double"
                    text: Translation.tr("Value scroll")
                    checked: Config.options.sidebar.cornerOpen.valueScroll
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.valueScroll = checked;
                    }

                    StyledToolTip {
                        text: Translation.tr("Brightness and volume")
                    }
                }
            }
            ConfigSwitch {
                buttonIcon: "visibility"
                text: Translation.tr("Visualize region")
                checked: Config.options.sidebar.cornerOpen.visualize
                onCheckedChanged: {
                    Config.options.sidebar.cornerOpen.visualize = checked;
                }
            }
            ConfigRow {
                ConfigSpinBox {
                    icon: "arrow_range"
                    text: Translation.tr("Region width")
                    value: Config.options.sidebar.cornerOpen.cornerRegionWidth
                    from: 1
                    to: 300
                    stepSize: 1
                    onValueChanged: {
                        Config.options.sidebar.cornerOpen.cornerRegionWidth = value;
                    }
                }
                ConfigSpinBox {
                    icon: "height"
                    text: Translation.tr("Region height")
                    value: Config.options.sidebar.cornerOpen.cornerRegionHeight
                    from: 1
                    to: 300
                    stepSize: 1
                    onValueChanged: {
                        Config.options.sidebar.cornerOpen.cornerRegionHeight = value;
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "voting_chip"
        title: Translation.tr("On-screen display")

        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Timeout (ms)")
            value: Config.options.osd.timeout
            from: 100
            to: 3000
            stepSize: 100
            onValueChanged: {
                Config.options.osd.timeout = value;
            }
        }
    }

    ContentSection {
        icon: "overview_key"
        title: Translation.tr("Overview")

        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable")
            checked: Config.options.overview.enable
            onCheckedChanged: {
                Config.options.overview.enable = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "center_focus_strong"
            text: Translation.tr("Center icons")
            checked: Config.options.overview.centerIcons
            onCheckedChanged: {
                Config.options.overview.centerIcons = checked;
            }
        }
        ConfigSpinBox {
            icon: "loupe"
            text: Translation.tr("Scale (%)")
            value: Config.options.overview.scale * 100
            from: 1
            to: 100
            stepSize: 1
            onValueChanged: {
                Config.options.overview.scale = value / 100;
            }
        }
        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "splitscreen_bottom"
                text: Translation.tr("Rows")
                value: Config.options.overview.rows
                from: 1
                to: 20
                stepSize: 1
                onValueChanged: {
                    Config.options.overview.rows = value;
                }
            }
            ConfigSpinBox {
                icon: "splitscreen_right"
                text: Translation.tr("Columns")
                value: Config.options.overview.columns
                from: 1
                to: 20
                stepSize: 1
                onValueChanged: {
                    Config.options.overview.columns = value;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSelectionArray {
                currentValue: Config.options.overview.orderRightLeft
                onSelected: newValue => {
                    Config.options.overview.orderRightLeft = newValue
                }
                options: [
                    {
                        displayName: Translation.tr("Left to right"),
                        icon: "arrow_forward",
                        value: 0
                    },
                    {
                        displayName: Translation.tr("Right to left"),
                        icon: "arrow_back",
                        value: 1
                    }
                ]
            }
            ConfigSelectionArray {
                currentValue: Config.options.overview.orderBottomUp
                onSelected: newValue => {
                    Config.options.overview.orderBottomUp = newValue
                }
                options: [
                    {
                        displayName: Translation.tr("Top-down"),
                        icon: "arrow_downward",
                        value: 0
                    },
                    {
                        displayName: Translation.tr("Bottom-up"),
                        icon: "arrow_upward",
                        value: 1
                    }
                ]
            }
        }
    }

    ContentSection {
        icon: "widgets"
        title: Translation.tr("Waffle panel")

        ContentSubsection {
            title: Translation.tr("Tweaks")
            tooltip: Translation.tr("Some spots are a bit janky; turning these off makes them match for accuracy instead")

            ConfigSwitch {
                buttonIcon: "toggle_on"
                text: Translation.tr("Fix switch handle position")
                checked: Config.options.waffles.tweaks.switchHandlePositionFix
                onCheckedChanged: {
                    Config.options.waffles.tweaks.switchHandlePositionFix = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "menu_open"
                text: Translation.tr("Smoother menu animations")
                checked: Config.options.waffles.tweaks.smootherMenuAnimations
                onCheckedChanged: {
                    Config.options.waffles.tweaks.smootherMenuAnimations = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "search"
                text: Translation.tr("Smoother search bar")
                checked: Config.options.waffles.tweaks.smootherSearchBar
                onCheckedChanged: {
                    Config.options.waffles.tweaks.smootherSearchBar = checked;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Bar")
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "vertical_align_bottom"
                    text: Translation.tr("Bar at bottom")
                    checked: Config.options.waffles.bar.bottom
                    onCheckedChanged: {
                        Config.options.waffles.bar.bottom = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "format_align_left"
                    text: Translation.tr("Left-align apps")
                    checked: Config.options.waffles.bar.leftAlignApps
                    onCheckedChanged: {
                        Config.options.waffles.bar.leftAlignApps = checked;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Calendar")
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Locale for the calendar, e.g. en-GB")
                text: Config.options.calendar.locale
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.calendar.locale = text;
                }
            }
            ConfigSwitch {
                buttonIcon: "calendar_view_week"
                text: Translation.tr("Short day-of-week labels")
                checked: Config.options.waffles.calendar.force2CharDayOfWeek
                onCheckedChanged: {
                    Config.options.waffles.calendar.force2CharDayOfWeek = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Shortens the day of week to 2 characters (e.g. \"Mo\" instead of \"Monday\")")
                }
            }
        }
    }

    ContentSection {
        icon: "wallpaper_slideshow"
        title: Translation.tr("Wallpaper selector")

        ConfigSwitch {
            buttonIcon: "ad"
            text: Translation.tr('Use system file picker')
            checked: Config.options.wallpaperSelector.useSystemFileDialog
            onCheckedChanged: {
                Config.options.wallpaperSelector.useSystemFileDialog = checked;
            }
        }
    }

    ContentSection {
        icon: "text_format"
        title: Translation.tr("Fonts")

        ContentSubsection {
            title: Translation.tr("Main font")
            tooltip: Translation.tr("Used for general UI text")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Font family name (e.g., Google Sans Flex)")
                text: Config.options.appearance.fonts.main
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.appearance.fonts.main = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Numbers font")
            tooltip: Translation.tr("Used for displaying numbers")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Font family name")
                text: Config.options.appearance.fonts.numbers
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.appearance.fonts.numbers = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Title font")
            tooltip: Translation.tr("Used for headings and titles")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Font family name")
                text: Config.options.appearance.fonts.title
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.appearance.fonts.title = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Monospace font")
            tooltip: Translation.tr("Used for code and terminal")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Font family name (e.g., JetBrains Mono NF)")
                text: Config.options.appearance.fonts.monospace
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.appearance.fonts.monospace = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Nerd font icons")
            tooltip: Translation.tr("Font used for Nerd Font icons")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Font family name (e.g., JetBrains Mono NF)")
                text: Config.options.appearance.fonts.iconNerd
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.appearance.fonts.iconNerd = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Reading font")
            tooltip: Translation.tr("Used for reading large blocks of text")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Font family name (e.g., Readex Pro)")
                text: Config.options.appearance.fonts.reading
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.appearance.fonts.reading = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Expressive font")
            tooltip: Translation.tr("Used for decorative/expressive text")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Font family name (e.g., Space Grotesk)")
                text: Config.options.appearance.fonts.expressive
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.appearance.fonts.expressive = text;
                }
            }
        }
    }

}

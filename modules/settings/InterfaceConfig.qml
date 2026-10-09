import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
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

        ConfigRow {
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("App IDs to hide from the dock, as regexes, comma-separated (e.g. explorer.exe, ^Shell_)")
                text: Config.options.dock.ignoredAppRegexes.join(", ")
                wrapMode: TextEdit.Wrap
                onEditingFinished: {
                    const items = text.split(",").map(s => s.trim()).filter(s => s.length > 0);
                    if (items.join(", ") !== Config.options.dock.ignoredAppRegexes.join(", "))
                        Config.options.dock.ignoredAppRegexes = items;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Appearance")

            ContentSubsection {
                title: Translation.tr("Style")
                ConfigSelectionArray {
                    currentValue: Config.options.dock.style
                    onSelected: newValue => { Config.options.dock.style = newValue }
                    options: [
                        { displayName: Translation.tr("Float"), icon: "call_to_action", value: "float" },
                        { displayName: Translation.tr("Hug"), icon: "dock_to_bottom", value: "hug" }
                    ]
                }
            }
            ContentSubsection {
                title: Translation.tr("Position")
                ConfigSelectionArray {
                    currentValue: Config.options.dock.position
                    onSelected: newValue => { Config.options.dock.position = newValue }
                    options: [
                        { displayName: Translation.tr("Left"), icon: "dock_to_left", value: "left" },
                        { displayName: Translation.tr("Bottom"), icon: "dock_to_bottom", value: "bottom" },
                        { displayName: Translation.tr("Right"), icon: "dock_to_right", value: "right" }
                    ]
                }
            }
            ConfigSwitch {
                buttonIcon: "background_dot_small"
                text: Translation.tr("Background")
                checked: Config.options.dock.showBackground
                onCheckedChanged: { Config.options.dock.showBackground = checked }
            }
            ConfigSpinBox {
                icon: "rounded_corner"
                text: Translation.tr("Corner radius")
                value: Config.options.dock.radius
                from: 0
                to: 40
                stepSize: 1
                onValueChanged: { Config.options.dock.radius = value }
            }
            ColorSelectionArray {
                icon: "format_paint"
                text: Translation.tr("Background color")
                options: ["layer0", "layer1", "primaryContainer", "secondaryContainer", "tertiaryContainer", "primary", "secondary", "tertiary"]
                currentValue: Config.options.dock.backgroundColor
                onSelected: newValue => { Config.options.dock.backgroundColor = newValue }
            }
            ConfigSwitch {
                enabled: Config.options.dock.style === "hug"
                buttonIcon: "filter_frames"
                text: Translation.tr("Follow frame color")
                checked: Config.options.dock.followFrameColor
                onCheckedChanged: { Config.options.dock.followFrameColor = checked }
            }
            ConfigSwitch {
                enabled: Config.options.dock.style !== "hug"
                buttonIcon: "border_style"
                text: Translation.tr("Border")
                checked: Config.options.dock.showBorder
                onCheckedChanged: { Config.options.dock.showBorder = checked }
            }
            ConfigSpinBox {
                enabled: Config.options.dock.showBorder && Config.options.dock.style !== "hug"
                icon: "line_weight"
                text: Translation.tr("Border width")
                value: Config.options.dock.borderWidth
                from: 1
                to: 10
                stepSize: 1
                onValueChanged: { Config.options.dock.borderWidth = value }
            }
            ColorSelectionArray {
                enabled: Config.options.dock.showBorder && Config.options.dock.style !== "hug"
                icon: "format_paint"
                text: Translation.tr("Border color")
                options: ["layer0Border", "primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer", "layer1"]
                currentValue: Config.options.dock.borderColor
                onSelected: newValue => { Config.options.dock.borderColor = newValue }
            }
        }

        ContentSubsection {
            title: Translation.tr("Icons")

            ConfigSwitch {
                buttonIcon: "preview"
                text: Translation.tr("Window previews")
                checked: Config.options.dock.showPreviews
                onCheckedChanged: { Config.options.dock.showPreviews = checked }
            }
            ConfigSpinBox {
                icon: "photo_size_select_large"
                text: Translation.tr("Icon size")
                value: Config.options.dock.iconSize
                from: 20
                to: 48
                stepSize: 1
                onValueChanged: { Config.options.dock.iconSize = value }
            }
            ConfigSpinBox {
                icon: "space_bar"
                text: Translation.tr("Icon spacing")
                value: Config.options.dock.iconSpacing
                from: 0
                to: 12
                stepSize: 1
                onValueChanged: { Config.options.dock.iconSpacing = value }
            }
        }

        ContentSubsection {
            title: Translation.tr("Buttons & Media")

            ConfigSwitch {
                buttonIcon: "music_note"
                text: Translation.tr("Media Player")
                checked: Config.options.dock.showMedia
                onCheckedChanged: { Config.options.dock.showMedia = checked }
            }
            ConfigSwitch {
                buttonIcon: "keep"
                text: Translation.tr("Show Pin Button")
                checked: Config.options.dock.showPinButton
                onCheckedChanged: { Config.options.dock.showPinButton = checked }
            }
            ConfigSwitch {
                buttonIcon: "apps"
                text: Translation.tr("Show Apps Button")
                checked: Config.options.dock.showAppsButton
                onCheckedChanged: { Config.options.dock.showAppsButton = checked }
            }
        }
    }

    ContentSection {
        visible: Platform.isWindows
        icon: "toolbar"
        title: Translation.tr("Windows taskbar")

        ConfigSwitch {
            buttonIcon: "dock_to_bottom"
            text: Translation.tr("Use the Windows taskbar instead of ii's bar")
            checked: Config.options.windowsPort.nativeTaskbar
            onCheckedChanged: {
                Config.options.windowsPort.nativeTaskbar = checked;
            }
            StyledToolTip {
                text: Translation.tr("Hides ii's bar and brings back the normal Windows taskbar. Desktop widgets, sidebars, search and shortcuts stay as they are. Ctrl+Super+P switches it")
            }
        }

        ConfigSwitch {
            buttonIcon: "web_traffic"
            enabled: !Config.options.windowsPort.nativeTaskbar
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

        ContentSubsection {
            title: Translation.tr("Inertial scrolling (touchpad)")
            tooltip: Translation.tr("Fling and bounce physics used for touchpad input once faster scrolling is enabled above.")

            ConfigRow {
                uniform: true
                ConfigSpinBox {
                    enabled: Config.options.interactions.scrolling.fasterTouchpadScroll
                    icon: "swipe"
                    text: Translation.tr("Touchpad sensitivity")
                    value: Config.options.interactions.scrolling.touchpadSensitivity * 100
                    from: 50
                    to: 2000
                    stepSize: 10
                    onValueChanged: {
                        Config.options.interactions.scrolling.touchpadSensitivity = value / 100;
                    }
                }
                ConfigSpinBox {
                    enabled: Config.options.interactions.scrolling.fasterTouchpadScroll
                    icon: "speed"
                    text: Translation.tr("Fling friction")
                    value: Config.options.interactions.scrolling.flingFriction * 10000
                    from: 1
                    to: 500
                    stepSize: 1
                    onValueChanged: {
                        Config.options.interactions.scrolling.flingFriction = value / 10000;
                    }
                }
            }
            ConfigRow {
                uniform: true
                ConfigSpinBox {
                    enabled: Config.options.interactions.scrolling.fasterTouchpadScroll
                    icon: "stop_circle"
                    text: Translation.tr("Fling stop threshold")
                    value: Config.options.interactions.scrolling.flingStopThreshold * 1000
                    from: 1
                    to: 200
                    stepSize: 1
                    onValueChanged: {
                        Config.options.interactions.scrolling.flingStopThreshold = value / 1000;
                    }
                }
                ConfigSpinBox {
                    enabled: Config.options.interactions.scrolling.fasterTouchpadScroll
                    icon: "vertical_align_center"
                    text: Translation.tr("Bounce damping")
                    value: Config.options.interactions.scrolling.bounceDamping * 100
                    from: 0
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.options.interactions.scrolling.bounceDamping = value / 100;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Inertial scrolling (mouse wheel)")

            ConfigSpinBox {
                enabled: Config.options.interactions.scrolling.fasterTouchpadScroll
                icon: "mouse"
                text: Translation.tr("Wheel scroll amount")
                value: Config.options.interactions.scrolling.wheelScrollAmount
                from: 10
                to: 2000
                stepSize: 10
                onValueChanged: {
                    Config.options.interactions.scrolling.wheelScrollAmount = value;
                }
            }
            ConfigRow {
                uniform: true
                ConfigSpinBox {
                    enabled: Config.options.interactions.scrolling.fasterTouchpadScroll
                    icon: "timer"
                    text: Translation.tr("Minimum duration (ms)")
                    value: Config.options.interactions.scrolling.wheelDurationMin
                    from: 50
                    to: 1000
                    stepSize: 10
                    onValueChanged: {
                        Config.options.interactions.scrolling.wheelDurationMin = value;
                    }
                }
                ConfigSpinBox {
                    enabled: Config.options.interactions.scrolling.fasterTouchpadScroll
                    icon: "timer"
                    text: Translation.tr("Maximum duration (ms)")
                    value: Config.options.interactions.scrolling.wheelDurationMax
                    from: 50
                    to: 2000
                    stepSize: 10
                    onValueChanged: {
                        Config.options.interactions.scrolling.wheelDurationMax = value;
                    }
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

    Loader {
        Layout.fillWidth: true
        active: !Platform.isWindows
        visible: active
        sourceComponent: ContentSection {
            icon: "lock"
            title: Translation.tr("Lock screen")

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
    }

    ContentSection {
        icon: "notifications"
        title: Translation.tr("Notifications")

        ContentSubsection {
            title: Translation.tr("Popup position")
            ConfigRow {
                uniform: true
                ConfigSelectionArray {
                    currentValue: Config.options.notifications.position
                    onSelected: newValue => {
                        Config.options.notifications.position = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Top left"),
                            icon: "north_west",
                            value: "top_left"
                        },
                        {
                            displayName: Translation.tr("Top center"),
                            icon: "north",
                            value: "top_center"
                        },
                        {
                            displayName: Translation.tr("Top right"),
                            icon: "north_east",
                            value: "top_right"
                        }
                    ]
                }
            }
            ConfigRow {
                uniform: true
                ConfigSelectionArray {
                    currentValue: Config.options.notifications.position
                    onSelected: newValue => {
                        Config.options.notifications.position = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Bottom left"),
                            icon: "south_west",
                            value: "bottom_left"
                        },
                        {
                            displayName: Translation.tr("Bottom center"),
                            icon: "south",
                            value: "bottom_center"
                        },
                        {
                            displayName: Translation.tr("Bottom right"),
                            icon: "south_east",
                            value: "bottom_right"
                        }
                    ]
                }
            }
        }

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
                Loader {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    active: !Platform.isWindows
                    visible: active
                    sourceComponent: ConfigSpinBox {
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

        Loader {
            Layout.fillWidth: true
            Layout.topMargin: 4
            active: !Platform.isWindows
            visible: active
            sourceComponent: ContentSubsection {
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

        ConfigSwitch {
            buttonIcon: "wallpaper"
            text: Translation.tr('Show banner')
            checked: Config.options.sidebar.banner
            onCheckedChanged: {
                Config.options.sidebar.banner = checked;
            }
            StyledToolTip {
                text: Translation.tr("Shows a banner image at the top of the right sidebar.\nDrag an image onto it to set it, right-click to reset")
            }
        }

        ConfigSwitch {
            buttonIcon: "calendar_month"
            text: Translation.tr('Show bottom group')
            checked: Config.options.sidebar.bottomGroup
            onCheckedChanged: {
                Config.options.sidebar.bottomGroup = checked;
            }
            StyledToolTip {
                text: Translation.tr("Calendar, to-do list and timer at the bottom of the right sidebar")
            }
        }

        ContentSubsection {
            title: Translation.tr("Media player")

            ConfigSwitch {
                buttonIcon: "check"
                text: Translation.tr("Show in sidebar")
                checked: Config.options.sidebar.mediaPlayer
                onCheckedChanged: {
                    Config.options.sidebar.mediaPlayer = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "play_circle"
                text: Translation.tr("Enable media card")
                enabled: Config.options.sidebar.mediaPlayer
                checked: Config.options.sidebar.media.enable
                onCheckedChanged: {
                    Config.options.sidebar.media.enable = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "lyrics"
                text: Translation.tr("Show lyrics")
                enabled: Config.options.sidebar.mediaPlayer && Config.options.sidebar.media.enable
                checked: Config.options.sidebar.media.showLyrics
                onCheckedChanged: {
                    Config.options.sidebar.media.showLyrics = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "palette"
                text: Translation.tr("Color from album art")
                enabled: Config.options.sidebar.mediaPlayer && Config.options.sidebar.media.enable
                checked: Config.options.sidebar.media.artColors
                onCheckedChanged: {
                    Config.options.sidebar.media.artColors = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "blur_on"
                text: Translation.tr("Blurred art background")
                enabled: Config.options.sidebar.mediaPlayer && Config.options.sidebar.media.enable
                checked: Config.options.sidebar.media.blurredBackground
                onCheckedChanged: {
                    Config.options.sidebar.media.blurredBackground = checked;
                }
            }

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "shapes"
                    text: Translation.tr("Shaped art")
                    enabled: Config.options.sidebar.mediaPlayer && Config.options.sidebar.media.enable
                    checked: Config.options.sidebar.media.shapeArt
                    onCheckedChanged: {
                        Config.options.sidebar.media.shapeArt = checked;
                    }
                }
                StyledComboBox {
                    id: mediaArtShapeSelector
                    enabled: Config.options.sidebar.mediaPlayer && Config.options.sidebar.media.enable && Config.options.sidebar.media.shapeArt
                    textRole: "displayName"
                    model: GlobalStates.centeredShapeOptions.map(shape => ({ displayName: shape, value: shape }))
                    currentIndex: {
                        const index = model.findIndex(item => item.value === Config.options.sidebar.media.artShape);
                        return index !== -1 ? index : 0;
                    }
                    onActivated: index => {
                        Config.options.sidebar.media.artShape = model[index].value;
                    }
                }
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
            ConfigRow {
                uniform: true
                Column {
                    Layout.fillWidth: true
                    spacing: 4
                    StyledText {
                        text: Translation.tr("Bottom-left corner")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                    StyledComboBox {
                        id: bottomLeftActionSelector
                        buttonIcon: "first_page"
                        textRole: "displayName"
                        model: GlobalStates.hotCornerOptions
                        currentIndex: {
                            const index = model.findIndex(item => item.value === Config.options.sidebar.cornerOpen.bottomLeftAction);
                            return index !== -1 ? index : 0;
                        }
                        onActivated: index => {
                            Config.options.sidebar.cornerOpen.bottomLeftAction = model[index].value;
                        }
                    }
                }
                Column {
                    Layout.fillWidth: true
                    spacing: 4
                    StyledText {
                        text: Translation.tr("Bottom-right corner")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                    StyledComboBox {
                        id: bottomRightActionSelector
                        buttonIcon: "last_page"
                        textRole: "displayName"
                        model: GlobalStates.hotCornerOptions
                        currentIndex: {
                            const index = model.findIndex(item => item.value === Config.options.sidebar.cornerOpen.bottomRightAction);
                            return index !== -1 ? index : 0;
                        }
                        onActivated: index => {
                            Config.options.sidebar.cornerOpen.bottomRightAction = model[index].value;
                        }
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
        ConfigRow {
            uniform: true
            ConfigSelectionArray {
                currentValue: Config.options.overview.style
                onSelected: newValue => {
                    Config.options.overview.style = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Default"),
                        icon: "grid_on",
                        value: "default"
                    },
                    {
                        displayName: Translation.tr("Niri-like"),
                        icon: "view_agenda",
                        value: "niri"
                    }
                ]
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
            enabled: Config.options.overview.style !== "niri"
            opacity: enabled ? 1 : 0.4
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
            enabled: Config.options.overview.style !== "niri"
            opacity: enabled ? 1 : 0.4
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

        ConfigSwitch {
            buttonIcon: "home"
            text: Translation.tr('Show home directory in quick access')
            checked: Config.options.wallpaperSelector.showHomePath
            onCheckedChanged: {
                Config.options.wallpaperSelector.showHomePath = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "done"
            text: Translation.tr('Close after selection')
            checked: Config.options.wallpaperSelector.closeAfterSelection
            onCheckedChanged: {
                Config.options.wallpaperSelector.closeAfterSelection = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "blur_on"
            text: Translation.tr('Show blur background')
            checked: Config.options.wallpaperSelector.showBlurBackground
            onCheckedChanged: {
                Config.options.wallpaperSelector.showBlurBackground = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "search"
            text: Translation.tr('Always show search bar')
            checked: Config.options.wallpaperSelector.showSearchbar
            onCheckedChanged: {
                Config.options.wallpaperSelector.showSearchbar = checked;
            }
        }

        ConfigSpinBox {
            icon: "grid_on"
            text: Translation.tr("Columns in grid view")
            value: Config.options.wallpaperSelector.columns
            from: 3
            to: 10
            stepSize: 1
            onValueChanged: {
                Config.options.wallpaperSelector.columns = value;
            }
        }

        ConfigSpinBox {
            icon: "timer"
            text: Translation.tr("Wallpaper change interval (min)")
            value: Config.options.wallpaperSelector.changeInterval / 60000
            from: 0
            to: 1440
            stepSize: 5
            onValueChanged: {
                Config.options.wallpaperSelector.changeInterval = value * 60000;
            }
        }

        ContentSubsection {
            title: Translation.tr("Sort wallpapers by")
            ConfigSelectionArray {
                currentValue: Config.options.wallpaperSelector.sortMode
                options: [
                    { "displayName": Translation.tr("Newest first"), "icon": "schedule", "value": "time" },
                    { "displayName": Translation.tr("Oldest first"), "icon": "history", "value": "time_rev" },
                    { "displayName": Translation.tr("Name A-Z"), "icon": "sort_by_alpha", "value": "name" },
                    { "displayName": Translation.tr("Name Z-A"), "icon": "sort_by_alpha", "value": "name_rev" },
                    { "displayName": Translation.tr("Largest first"), "icon": "straighten", "value": "size" },
                    { "displayName": Translation.tr("Smallest first"), "icon": "straighten", "value": "size_rev" },
                ]
                onSelected: newValue => {
                    Config.options.wallpaperSelector.sortMode = newValue;
                }
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Custom wallpaper folder, e.g. C:/Users/you/Pictures")
            text: Config.options.wallpaperSelector.userPath ?? ""
            wrapMode: TextEdit.NoWrap
            onTextChanged: {
                Config.options.wallpaperSelector.userPath = text;
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            visible: !Platform.isWindows
            placeholderText: Translation.tr("Live wallpaper folder (not supported on Windows yet)")
            text: Config.options.wallpaperSelector.liveWallpapersPath ?? ""
            wrapMode: TextEdit.NoWrap
            onTextChanged: {
                Config.options.wallpaperSelector.liveWallpapersPath = text;
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Wpp folder")
            text: Config.options.wallpaperSelector.wppFolder ?? ""
            wrapMode: TextEdit.NoWrap
            onTextChanged: {
                Config.options.wallpaperSelector.wppFolder = text;
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Wpp (Spicy) folder")
            text: Config.options.wallpaperSelector.wppSpicyFolder ?? ""
            wrapMode: TextEdit.NoWrap
            onTextChanged: {
                Config.options.wallpaperSelector.wppSpicyFolder = text;
            }
            StyledToolTip {
                text: Translation.tr("On Windows this folder is only reachable from an age-verified Microsoft account")
            }
        }
    }

    ContentSection {
        icon: "travel_explore"
        title: Translation.tr("Wallhaven")

        StyledText {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: Appearance.colors.colSubtext
            text: Translation.tr("Search filters can also be changed from the wallpaper selector's own Wallhaven tab.")
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            spacing: 10

            StyledText {
                text: Translation.tr("Wallhaven API key")
            }
            TextField {
                id: wallhavenApiKeyField
                Layout.fillWidth: true
                echoMode: TextInput.Password
                placeholderText: Translation.tr("Optional — needed for Spicy results")
                text: Config.options.wallpaperSelector.wallhavenApiKey ?? ""
                color: Appearance.colors.colOnLayer1
                background: Rectangle {
                    color: Appearance.colors.colLayer1
                    radius: Appearance.rounding.small
                    border.width: 1
                    border.color: wallhavenApiKeyField.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                }
                onEditingFinished: {
                    Config.options.wallpaperSelector.wallhavenApiKey = text;
                    WallhavenSearch.apiKey = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Default sort")
            ConfigSelectionArray {
                currentValue: Config.options.wallpaperSelector.wallhavenSorting
                options: [
                    { "displayName": Translation.tr("Relevance"), "icon": "search", "value": "relevance" },
                    { "displayName": Translation.tr("Date Added"), "icon": "schedule", "value": "date_added" },
                    { "displayName": Translation.tr("Top List"), "icon": "trending_up", "value": "toplist" },
                    { "displayName": Translation.tr("Random"), "icon": "casino", "value": "random" },
                ]
                onSelected: newValue => {
                    Config.options.wallpaperSelector.wallhavenSorting = newValue;
                    WallhavenSearch.sorting = newValue;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Order")
            ConfigSelectionArray {
                currentValue: Config.options.wallpaperSelector.wallhavenOrder
                options: [
                    { "displayName": Translation.tr("Descending"), "icon": "arrow_downward", "value": "desc" },
                    { "displayName": Translation.tr("Ascending"), "icon": "arrow_upward", "value": "asc" },
                ]
                onSelected: newValue => {
                    Config.options.wallpaperSelector.wallhavenOrder = newValue;
                    WallhavenSearch.order = newValue;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Top list range")
            ConfigSelectionArray {
                currentValue: Config.options.wallpaperSelector.wallhavenTopRange
                options: [
                    { "displayName": Translation.tr("1 Day"), "icon": "today", "value": "1d" },
                    { "displayName": Translation.tr("1 Week"), "icon": "view_week", "value": "1w" },
                    { "displayName": Translation.tr("1 Month"), "icon": "calendar_month", "value": "1m" },
                    { "displayName": Translation.tr("1 Year"), "icon": "event_repeat", "value": "1y" },
                ]
                onSelected: newValue => {
                    Config.options.wallpaperSelector.wallhavenTopRange = newValue;
                    WallhavenSearch.topRange = newValue;
                }
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "category"
                text: Translation.tr('General')
                checked: Config.options.wallpaperSelector.wallhavenCategories.charAt(0) === "1"
                onCheckedChanged: {
                    const c = Config.options.wallpaperSelector.wallhavenCategories;
                    Config.options.wallpaperSelector.wallhavenCategories = (checked ? "1" : "0") + c.charAt(1) + c.charAt(2);
                    WallhavenSearch.categories = Config.options.wallpaperSelector.wallhavenCategories;
                }
            }
            ConfigSwitch {
                buttonIcon: "animation"
                text: Translation.tr('Anime')
                checked: Config.options.wallpaperSelector.wallhavenCategories.charAt(1) === "1"
                onCheckedChanged: {
                    const c = Config.options.wallpaperSelector.wallhavenCategories;
                    Config.options.wallpaperSelector.wallhavenCategories = c.charAt(0) + (checked ? "1" : "0") + c.charAt(2);
                    WallhavenSearch.categories = Config.options.wallpaperSelector.wallhavenCategories;
                }
            }
            ConfigSwitch {
                buttonIcon: "people"
                text: Translation.tr('People')
                checked: Config.options.wallpaperSelector.wallhavenCategories.charAt(2) === "1"
                onCheckedChanged: {
                    const c = Config.options.wallpaperSelector.wallhavenCategories;
                    Config.options.wallpaperSelector.wallhavenCategories = c.charAt(0) + c.charAt(1) + (checked ? "1" : "0");
                    WallhavenSearch.categories = Config.options.wallpaperSelector.wallhavenCategories;
                }
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "wb_sunny"
                text: "SFW"
                checked: Config.options.wallpaperSelector.wallhavenPurity.charAt(0) === "1"
                onCheckedChanged: {
                    const p = Config.options.wallpaperSelector.wallhavenPurity;
                    Config.options.wallpaperSelector.wallhavenPurity = (checked ? "1" : "0") + p.charAt(1) + p.charAt(2);
                    WallhavenSearch.purity = Config.options.wallpaperSelector.wallhavenPurity;
                }
            }
            ConfigSwitch {
                buttonIcon: "warning"
                text: Translation.tr('Sketchy')
                enabled: SpicyStuff.allowed
                checked: Config.options.wallpaperSelector.wallhavenPurity.charAt(1) === "1" && SpicyStuff.allowed
                onCheckedChanged: {
                    if (!SpicyStuff.allowed)
                        return;
                    const p = Config.options.wallpaperSelector.wallhavenPurity;
                    Config.options.wallpaperSelector.wallhavenPurity = p.charAt(0) + (checked ? "1" : "0") + p.charAt(2);
                    WallhavenSearch.purity = Config.options.wallpaperSelector.wallhavenPurity;
                }
            }
            ConfigSwitch {
                visible: Config.options.wallpaperSelector.wallhavenApiKey.length > 0
                buttonIcon: "whatshot"
                text: Translation.tr('Spicy')
                enabled: SpicyStuff.allowed
                checked: Config.options.wallpaperSelector.wallhavenPurity.charAt(2) === "1" && SpicyStuff.allowed
                onCheckedChanged: {
                    if (!SpicyStuff.allowed)
                        return;
                    const p = Config.options.wallpaperSelector.wallhavenPurity;
                    Config.options.wallpaperSelector.wallhavenPurity = p.charAt(0) + p.charAt(1) + (checked ? "1" : "0");
                    WallhavenSearch.purity = Config.options.wallpaperSelector.wallhavenPurity;
                }
            }
        }

        NoticeBox {
            Layout.fillWidth: true
            visible: !SpicyStuff.allowed
            materialIcon: SpicyStuff.checking ? "hourglass_top" : "lock"
            text: SpicyStuff.restriction
        }

        ContentSubsection {
            title: Translation.tr("Aspect ratio")
            ConfigSelectionArray {
                currentValue: Config.options.wallpaperSelector.wallhavenRatios
                options: [
                    { "displayName": Translation.tr("Any"), "icon": "crop_free", "value": "" },
                    { "displayName": "16x9", "icon": "crop_16_9", "value": "16x9" },
                    { "displayName": "21x9", "icon": "panorama_wide_angle", "value": "21x9" },
                    { "displayName": "9x16", "icon": "crop_portrait", "value": "9x16" },
                    { "displayName": "1x1", "icon": "crop_square", "value": "1x1" },
                ]
                onSelected: newValue => {
                    Config.options.wallpaperSelector.wallhavenRatios = newValue;
                    WallhavenSearch.ratios = newValue;
                }
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Default search query")
            text: Config.options.wallpaperSelector.wallhavenQuery ?? ""
            wrapMode: TextEdit.NoWrap
            onTextChanged: {
                Config.options.wallpaperSelector.wallhavenQuery = text;
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Color filter, comma-separated hex (e.g. cc0000,0066cc)")
            text: Config.options.wallpaperSelector.wallhavenColors ?? ""
            wrapMode: TextEdit.NoWrap
            onTextChanged: {
                Config.options.wallpaperSelector.wallhavenColors = text;
                WallhavenSearch.colors = text;
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

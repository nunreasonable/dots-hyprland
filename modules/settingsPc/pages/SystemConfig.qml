import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets as W
import qs.modules.settingsPc.widgets

ContentPage {
    id: page
    forceWidth: true
    bottomContentPadding: 15

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            icon: "monitor"
            shape: W.MaterialShape.Shape.Cookie6Sided
            title: Translation.tr("Displays")
        }

        ContentSection {
            id: windowsSection
            icon: "select_window"
            shape: W.MaterialShape.Shape.Gem
            title: Translation.tr("Windows")

            readonly property bool dwmDecorations: parseInt(SystemInfo.windowsBuild) >= 22000
            readonly property var borderColorRoles: ["primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer", "layer0Border"]

            W.NoticeBox {
                Layout.fillWidth: true
                visible: !Config.options.windowsPort.tiling.enable
                text: Translation.tr("The layout options apply while tiling is on (Interface > Windows tiling).")
            }

            GroupedList {
                ConfigSelectionArray {
                    text: Translation.tr("Tiling Layout")
                    icon: "responsive_layout"
                    currentValue: Config.options.hyprland.general.layout === "master" ? "master" : "dwindle"
                    onSelected: newValue => {
                        Config.options.hyprland.general.layout = newValue;
                    }
                    options: [
                        { displayName: Translation.tr("Dwindle"), icon: "browse", value: "dwindle" },
                        { displayName: Translation.tr("Master"), icon: "auto_awesome_mosaic", value: "master" }
                    ]
                }
            }

            ContentSubsection {
                Layout.topMargin: 10
                visible: Config.options.hyprland.general.layout !== "master"
                title: Translation.tr("Dwindle")

                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "smart_toy"
                        text: Translation.tr("Smart split (follow the cursor)")
                        checked: Config.options.windowsPort.tiling.smartSplit
                        onCheckedChanged: {
                            if (checked !== Config.options.windowsPort.tiling.smartSplit)
                                Config.options.windowsPort.tiling.smartSplit = checked;
                        }
                        W.StyledToolTip {
                            text: Translation.tr("A new window takes the side of the focused window the cursor is closest to, and splits keep their direction.")
                        }
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("Force split side")
                        icon: "splitscreen"
                        enabled: !Config.options.windowsPort.tiling.smartSplit
                        currentValue: Config.options.windowsPort.tiling.forceSplit
                        onSelected: newValue => {
                            Config.options.windowsPort.tiling.forceSplit = newValue;
                        }
                        options: [
                            { displayName: Translation.tr("Auto"), icon: "auto_mode", value: 0 },
                            { displayName: Translation.tr("Left / top"), icon: "align_horizontal_left", value: 1 },
                            { displayName: Translation.tr("Right / bottom"), icon: "align_horizontal_right", value: 2 }
                        ]
                    }
                    ConfigSpinBox {
                        icon: "percent"
                        text: Translation.tr("Default split ratio (%)")
                        value: Math.round(Config.options.windowsPort.tiling.defaultSplitRatio * 50)
                        from: 5; to: 95; stepSize: 5
                        onValueChanged: {
                            if (value !== Math.round(Config.options.windowsPort.tiling.defaultSplitRatio * 50))
                                Config.options.windowsPort.tiling.defaultSplitRatio = value / 50;
                        }
                    }
                }
            }

            ContentSubsection {
                Layout.topMargin: 10
                visible: Config.options.hyprland.general.layout === "master"
                title: Translation.tr("Master")

                GroupedList {
                    ConfigSelectionArray {
                        text: Translation.tr("New windows become")
                        icon: "add_box"
                        currentValue: Config.options.windowsPort.tiling.master.newStatus
                        onSelected: newValue => {
                            Config.options.windowsPort.tiling.master.newStatus = newValue;
                        }
                        options: [
                            { displayName: Translation.tr("Master"), icon: "star", value: "master" },
                            { displayName: Translation.tr("Slave"), icon: "view_agenda", value: "slave" },
                            { displayName: Translation.tr("Inherit"), icon: "content_copy", value: "inherit" }
                        ]
                    }
                    ConfigSwitch {
                        buttonIcon: "vertical_align_top"
                        text: Translation.tr("New windows go on top of the stack")
                        checked: Config.options.windowsPort.tiling.master.newOnTop
                        onCheckedChanged: {
                            if (checked !== Config.options.windowsPort.tiling.master.newOnTop)
                                Config.options.windowsPort.tiling.master.newOnTop = checked;
                        }
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("Master position")
                        icon: "screen_rotation"
                        currentValue: Config.options.windowsPort.tiling.master.orientation
                        onSelected: newValue => {
                            Config.options.windowsPort.tiling.master.orientation = newValue;
                        }
                        options: [
                            { displayName: Translation.tr("Left"), icon: "align_horizontal_left", value: "left" },
                            { displayName: Translation.tr("Right"), icon: "align_horizontal_right", value: "right" },
                            { displayName: Translation.tr("Top"), icon: "align_vertical_top", value: "top" },
                            { displayName: Translation.tr("Bottom"), icon: "align_vertical_bottom", value: "bottom" },
                            { displayName: Translation.tr("Center"), icon: "align_horizontal_center", value: "center" }
                        ]
                    }
                    ConfigSpinBox {
                        icon: "aspect_ratio"
                        text: Translation.tr("Master size")
                        value: Math.round(Config.options.windowsPort.tiling.master.mfact * 100)
                        from: 10; to: 90; stepSize: 5
                        onValueChanged: {
                            if (value !== Math.round(Config.options.windowsPort.tiling.master.mfact * 100))
                                Config.options.windowsPort.tiling.master.mfact = value / 100;
                        }
                    }
                }
            }

            ContentSubsection {
                Layout.topMargin: 10
                visible: windowsSection.dwmDecorations
                title: Translation.tr("Borders and corners")

                GroupedList {
                    ConfigSelectionArray {
                        text: Translation.tr("Window borders")
                        icon: "border_outer"
                        currentValue: Config.options.hyprland.general.borderSize <= 0 ? "none" : Config.options.hyprland.general.borderColor.enable ? "colors" : "system"
                        onSelected: newValue => {
                            Config.options.hyprland.general.borderSize = newValue === "none" ? 0 : Math.max(1, Config.options.hyprland.general.borderSize);
                            Config.options.hyprland.general.borderColor.enable = newValue === "colors";
                        }
                        options: [
                            { displayName: Translation.tr("System"), icon: "desktop_windows", value: "system" },
                            { displayName: Translation.tr("Palette"), icon: "palette", value: "colors" },
                            { displayName: Translation.tr("None"), icon: "block", value: "none" }
                        ]
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("Window corners")
                        icon: "rounded_corner"
                        currentValue: Config.options.windowsPort.decoration.corners
                        onSelected: newValue => {
                            Config.options.windowsPort.decoration.corners = newValue;
                        }
                        options: [
                            { displayName: Translation.tr("Default"), icon: "settings_backup_restore", value: "default" },
                            { displayName: Translation.tr("Rounded"), icon: "rounded_corner", value: "round" },
                            { displayName: Translation.tr("Slightly rounded"), icon: "crop_square", value: "roundSmall" },
                            { displayName: Translation.tr("Square"), icon: "square", value: "square" }
                        ]
                    }
                }
            }

            ContentSubsection {
                Layout.topMargin: 10
                visible: windowsSection.dwmDecorations && Config.options.hyprland.general.borderSize > 0 && Config.options.hyprland.general.borderColor.enable
                title: Translation.tr("Border Color Management")

                GroupedList {
                    W.ColorSelectionArray {
                        icon: "border_color"
                        text: Translation.tr("Active border")
                        options: windowsSection.borderColorRoles
                        currentValue: Config.options.hyprland.general.borderColor.activeRole
                        onSelected: newValue => {
                            Config.options.hyprland.general.borderColor.activeRole = newValue;
                        }
                    }
                    ConfigSpinBox {
                        icon: "opacity"
                        text: Translation.tr("Active border opacity")
                        value: Math.round(Config.options.hyprland.general.borderColor.activeOpacity * 100)
                        from: 0; to: 100; stepSize: 5
                        onValueChanged: {
                            if (value !== Math.round(Config.options.hyprland.general.borderColor.activeOpacity * 100))
                                Config.options.hyprland.general.borderColor.activeOpacity = value / 100;
                        }
                    }
                    W.ColorSelectionArray {
                        icon: "border_color"
                        text: Translation.tr("Inactive border")
                        options: windowsSection.borderColorRoles
                        currentValue: Config.options.hyprland.general.borderColor.inactiveRole
                        onSelected: newValue => {
                            Config.options.hyprland.general.borderColor.inactiveRole = newValue;
                        }
                    }
                    ConfigSpinBox {
                        icon: "opacity"
                        text: Translation.tr("Inactive border opacity")
                        value: Math.round(Config.options.hyprland.general.borderColor.inactiveOpacity * 100)
                        from: 0; to: 100; stepSize: 5
                        onValueChanged: {
                            if (value !== Math.round(Config.options.hyprland.general.borderColor.inactiveOpacity * 100))
                                Config.options.hyprland.general.borderColor.inactiveOpacity = value / 100;
                        }
                    }
                }
            }

            ContentSubsection {
                Layout.topMargin: 10
                title: Translation.tr("Workspaces")

                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "swap_horiz"
                        text: Translation.tr("Switching to the current workspace goes back")
                        checked: Config.options.windowsPort.binds.workspaceBackAndForth
                        onCheckedChanged: {
                            if (checked !== Config.options.windowsPort.binds.workspaceBackAndForth)
                                Config.options.windowsPort.binds.workspaceBackAndForth = checked;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "ads_click"
                        text: Translation.tr("Move cursor to the new workspace")
                        checked: Config.options.windowsPort.cursor.warpOnChangeWorkspace !== 0
                        onCheckedChanged: {
                            const mode = checked ? 1 : 0;
                            if (mode !== Config.options.windowsPort.cursor.warpOnChangeWorkspace)
                                Config.options.windowsPort.cursor.warpOnChangeWorkspace = mode;
                        }
                        W.StyledToolTip {
                            text: Translation.tr("After a workspace switch from a shortcut, the cursor jumps to the focused window. Not when the switch came from a click on the bar or the overview.")
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "keyboard"
            shape: W.MaterialShape.Shape.Puffy
            title: Translation.tr("Input")

            ContentSubsection {
                title: Translation.tr("Keyboard")

                GroupedList {
                    ConfigSelectionArray {
                        text: Translation.tr("Repeat delay")
                        icon: "keyboard_return"
                        currentValue: WindowsNative.inputSettings?.keyboardRepeatDelay ?? 0
                        onSelected: newValue => {
                            if (WindowsNative.inputSettings) WindowsNative.inputSettings.keyboardRepeatDelay = newValue;
                        }
                        options: [
                            { displayName: Translation.tr("Short"), icon: "bolt", value: 0 },
                            { displayName: Translation.tr("Medium-short"), icon: "timer", value: 1 },
                            { displayName: Translation.tr("Medium-long"), icon: "av_timer", value: 2 },
                            { displayName: Translation.tr("Long"), icon: "hourglass_empty", value: 3 }
                        ]
                    }

                    ConfigSpinBox {
                        icon: "speed"
                        text: Translation.tr("Repeat rate")
                        value: WindowsNative.inputSettings?.keyboardRepeatRate ?? 0
                        from: 0; to: 31; stepSize: 1
                        onValueChanged: {
                            if (WindowsNative.inputSettings && value !== WindowsNative.inputSettings.keyboardRepeatRate)
                                WindowsNative.inputSettings.keyboardRepeatRate = value;
                        }
                    }

                    ConfigSwitch {
                        buttonIcon: "numbers"
                        text: Translation.tr("Numlock by default")
                        checked: WindowsNative.inputSettings?.numLockOnAtSignIn ?? false
                        onCheckedChanged: {
                            if (WindowsNative.inputSettings && checked !== WindowsNative.inputSettings.numLockOnAtSignIn)
                                WindowsNative.inputSettings.numLockOnAtSignIn = checked;
                        }
                    }

                    ConfigComboBox {
                        Layout.fillWidth: true
                        buttonIcon: "keyboard"
                        text: Translation.tr("Keyboard layout")
                        description: WindowsNative.keyboard?.currentLayoutName ?? ""
                        textRole: "displayName"
                        model: (WindowsNative.keyboard?.layoutCodes ?? []).map(code => ({ displayName: code, value: code }))
                        currentValue: WindowsNative.keyboard?.currentLayoutCode ?? ""
                        onSelected: newValue => {
                            if (WindowsNative.keyboard) WindowsNative.keyboard.activateLayout(newValue);
                        }
                    }
                }

                W.NoticeBox {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    text: Translation.tr("To add or remove keyboard layouts, use Windows Settings > Time & Language > Language")
                }
            }

            ContentSubsection {
                Layout.topMargin: 10
                title: Translation.tr("Mouse")

                GroupedList {
                    ConfigSpinBox {
                        icon: "speed"
                        text: Translation.tr("Pointer speed")
                        value: WindowsNative.inputSettings?.pointerSpeed ?? 10
                        from: 1; to: 20; stepSize: 1
                        onValueChanged: {
                            if (WindowsNative.inputSettings && value !== WindowsNative.inputSettings.pointerSpeed)
                                WindowsNative.inputSettings.pointerSpeed = value;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "ads_click"
                        text: Translation.tr("Enhance pointer precision")
                        checked: WindowsNative.inputSettings?.enhancePointerPrecision ?? false
                        onCheckedChanged: {
                            if (WindowsNative.inputSettings && checked !== WindowsNative.inputSettings.enhancePointerPrecision)
                                WindowsNative.inputSettings.enhancePointerPrecision = checked;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "front_hand"
                        text: Translation.tr("Swap mouse buttons (left-handed)")
                        checked: WindowsNative.inputSettings?.leftHanded ?? false
                        onCheckedChanged: {
                            if (WindowsNative.inputSettings && checked !== WindowsNative.inputSettings.leftHanded)
                                WindowsNative.inputSettings.leftHanded = checked;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "keyboard_hide"
                        text: Translation.tr("Hide pointer while typing")
                        checked: WindowsNative.inputSettings?.hidePointerWhileTyping ?? false
                        onCheckedChanged: {
                            if (WindowsNative.inputSettings && checked !== WindowsNative.inputSettings.hidePointerWhileTyping)
                                WindowsNative.inputSettings.hidePointerWhileTyping = checked;
                        }
                    }
                    ConfigSpinBox {
                        icon: "mouse"
                        text: Translation.tr("Wheel scroll lines")
                        value: WindowsNative.inputSettings?.wheelScrollLines ?? 3
                        from: 1; to: 100; stepSize: 1
                        onValueChanged: {
                            if (WindowsNative.inputSettings && value !== WindowsNative.inputSettings.wheelScrollLines)
                                WindowsNative.inputSettings.wheelScrollLines = value;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "mouse"
                        text: Translation.tr("Focus follows mouse")
                        checked: WindowsNative.inputSettings?.focusFollowsMouse ?? false
                        onCheckedChanged: {
                            if (WindowsNative.inputSettings && checked !== WindowsNative.inputSettings.focusFollowsMouse)
                                WindowsNative.inputSettings.focusFollowsMouse = checked;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "center_focus_strong"
                        enabled: WindowsNative.inputSettings?.focusFollowsMouse ?? false
                        text: Translation.tr("Raise window on focus")
                        checked: WindowsNative.inputSettings?.raiseOnFocus ?? false
                        onCheckedChanged: {
                            if (WindowsNative.inputSettings && checked !== WindowsNative.inputSettings.raiseOnFocus)
                                WindowsNative.inputSettings.raiseOnFocus = checked;
                        }
                    }
                    ConfigSpinBox {
                        icon: "hourglass_empty"
                        enabled: WindowsNative.inputSettings?.focusFollowsMouse ?? false
                        text: Translation.tr("Delay before raising (ms)")
                        value: WindowsNative.inputSettings?.focusFollowsMouseDelayMs ?? 0
                        from: 0; to: 5000; stepSize: 50
                        onValueChanged: {
                            if (WindowsNative.inputSettings && value !== WindowsNative.inputSettings.focusFollowsMouseDelayMs)
                                WindowsNative.inputSettings.focusFollowsMouseDelayMs = value;
                        }
                    }
                }
            }

            ContentSubsection {
                Layout.topMargin: 10
                title: Translation.tr("Touchpad")
                visible: WindowsNative.inputSettings?.touchpadAvailable ?? false

                GroupedList {
                    visible: WindowsNative.inputSettings?.touchpadAvailable ?? false

                    ConfigSwitch {
                        buttonIcon: "trackpad_input"
                        text: Translation.tr("Touchpad")
                        checked: WindowsNative.inputSettings?.touchpadEnabled ?? true
                        onCheckedChanged: {
                            if (WindowsNative.inputSettings && checked !== WindowsNative.inputSettings.touchpadEnabled)
                                WindowsNative.inputSettings.touchpadEnabled = checked;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "touch_app"
                        enabled: WindowsNative.inputSettings?.touchpadEnabled ?? true
                        text: Translation.tr("Tap to click")
                        checked: WindowsNative.inputSettings?.touchpadTapToClick ?? true
                        onCheckedChanged: {
                            if (WindowsNative.inputSettings && checked !== WindowsNative.inputSettings.touchpadTapToClick)
                                WindowsNative.inputSettings.touchpadTapToClick = checked;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "swap_vert"
                        enabled: WindowsNative.inputSettings?.touchpadEnabled ?? true
                        text: Translation.tr("Natural scrolling")
                        checked: WindowsNative.inputSettings?.touchpadNaturalScroll ?? false
                        onCheckedChanged: {
                            if (WindowsNative.inputSettings && checked !== WindowsNative.inputSettings.touchpadNaturalScroll)
                                WindowsNative.inputSettings.touchpadNaturalScroll = checked;
                        }
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("Sensitivity")
                        icon: "touch_app"
                        enabled: WindowsNative.inputSettings?.touchpadEnabled ?? true
                        currentValue: WindowsNative.inputSettings?.touchpadSensitivity ?? 2
                        onSelected: newValue => {
                            if (WindowsNative.inputSettings) WindowsNative.inputSettings.touchpadSensitivity = newValue;
                        }
                        options: [
                            { displayName: Translation.tr("Most sensitive"), icon: "touch_app", value: 0 },
                            { displayName: Translation.tr("High sensitivity"), icon: "ads_click", value: 1 },
                            { displayName: Translation.tr("Medium sensitivity"), icon: "mouse", value: 2 },
                            { displayName: Translation.tr("Low sensitivity"), icon: "front_hand", value: 3 },
                            { displayName: Translation.tr("Least sensitive"), icon: "pan_tool", value: 4 }
                        ]
                    }
                }
            }

            ContentSubsection {
                Layout.topMargin: 10
                title: Translation.tr("Cursor")

                GroupedList {
                    ConfigComboBox {
                        Layout.fillWidth: true
                        buttonIcon: "mouse"
                        text: Translation.tr("Cursor scheme")
                        searchable: true
                        textRole: "displayName"
                        model: (WindowsNative.inputSettings?.cursorSchemeNames ?? []).map(name => ({ displayName: name, value: name }))
                        currentValue: WindowsNative.inputSettings?.cursorSchemeName ?? ""
                        onSelected: newValue => {
                            if (WindowsNative.inputSettings) WindowsNative.inputSettings.setCursorScheme(newValue);
                        }
                    }
                    ConfigSpinBox {
                        icon: "zoom_in"
                        text: Translation.tr("Cursor size")
                        value: WindowsNative.inputSettings?.cursorSize ?? 1
                        from: 1; to: 15; stepSize: 1
                        onValueChanged: {
                            if (WindowsNative.inputSettings && value !== WindowsNative.inputSettings.cursorSize)
                                WindowsNative.inputSettings.cursorSize = value;
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "bedtime"
            shape: W.MaterialShape.Shape.Sunny
            title: Translation.tr("Idle")
        }

        ContentSection {
            icon: "rocket_launch"
            shape: W.MaterialShape.Shape.Pentagon
            title: Translation.tr("Autostart")
        }

        ContentSection {
            icon: "animation"
            shape: W.MaterialShape.Shape.SoftBurst
            title: Translation.tr("Animations")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Menu and tooltip animations")
                    checked: WindowsNative.inputSettings?.clientAreaAnimations ?? true
                    onCheckedChanged: {
                        if (WindowsNative.inputSettings && checked !== WindowsNative.inputSettings.clientAreaAnimations)
                            WindowsNative.inputSettings.clientAreaAnimations = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "animation"
                    text: Translation.tr("Minimize and maximize animations")
                    checked: WindowsNative.inputSettings?.minimizeRestoreAnimations ?? true
                    onCheckedChanged: {
                        if (WindowsNative.inputSettings && checked !== WindowsNative.inputSettings.minimizeRestoreAnimations)
                            WindowsNative.inputSettings.minimizeRestoreAnimations = checked;
                    }
                }
            }
        }
    }
}

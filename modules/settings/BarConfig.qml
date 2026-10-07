import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "notifications"
        title: Translation.tr("Notifications")
        ConfigSwitch {
            buttonIcon: "counter_2"
            text: Translation.tr("Unread indicator: show count")
            checked: Config.options.bar.indicators.notifications.showUnreadCount
            onCheckedChanged: {
                Config.options.bar.indicators.notifications.showUnreadCount = checked;
            }
        }
    }
    
    ContentSection {
        icon: "spoke"
        title: Translation.tr("Positioning")

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Bar position")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Top"),
                            icon: "arrow_upward",
                            value: 0 // bottom: false, vertical: false
                        },
                        {
                            displayName: Translation.tr("Left"),
                            icon: "arrow_back",
                            value: 2 // bottom: false, vertical: true
                        },
                        {
                            displayName: Translation.tr("Bottom"),
                            icon: "arrow_downward",
                            value: 1 // bottom: true, vertical: false
                        },
                        {
                            displayName: Translation.tr("Right"),
                            icon: "arrow_forward",
                            value: 3 // bottom: true, vertical: true
                        }
                    ]
                }
            }
            ContentSubsection {
                title: Translation.tr("Automatically hide")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.autoHide.enable
                    onSelected: newValue => {
                        Config.options.bar.autoHide.enable = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: false
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: true
                        }
                    ]
                }
            }
        }

        ConfigRow {
            
            ContentSubsection {
                title: Translation.tr("Corner style")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => {
                        Config.options.bar.cornerStyle = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Hug"),
                            icon: "line_curve",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Float"),
                            icon: "page_header",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Rect"),
                            icon: "toolbar",
                            value: 2
                        }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Group style")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.borderless
                    onSelected: newValue => {
                        Config.options.bar.borderless = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Pills"),
                            icon: "location_chip",
                            value: false
                        },
                        {
                            displayName: Translation.tr("Line-separated"),
                            icon: "split_scene",
                            value: true
                        }
                    ]
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Auto-hide behavior")

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    enabled: Config.options.bar.autoHide.enable
                    buttonIcon: "fit_screen"
                    text: Translation.tr("Push windows out of the way")
                    checked: Config.options.bar.autoHide.pushWindows
                    onCheckedChanged: {
                        Config.options.bar.autoHide.pushWindows = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("When the bar is shown, reserve its space so windows get pushed out of the way instead of going underneath it.")
                    }
                }
                ConfigSwitch {
                    enabled: Config.options.bar.autoHide.enable
                    buttonIcon: "keyboard_command_key"
                    text: Translation.tr("Show when holding Super")
                    checked: Config.options.bar.autoHide.showWhenPressingSuper.enable
                    onCheckedChanged: {
                        Config.options.bar.autoHide.showWhenPressingSuper.enable = checked;
                    }
                }
            }

            ConfigSpinBox {
                enabled: Config.options.bar.autoHide.enable
                icon: "swipe"
                text: Translation.tr("Hover trigger region width (px)")
                value: Config.options.bar.autoHide.hoverRegionWidth
                from: 0
                to: 50
                stepSize: 1
                onValueChanged: {
                    Config.options.bar.autoHide.hoverRegionWidth = value;
                }
            }

            ConfigSpinBox {
                enabled: Config.options.bar.autoHide.enable && Config.options.bar.autoHide.showWhenPressingSuper.enable
                icon: "timer"
                text: Translation.tr("Show delay when holding Super (ms)")
                value: Config.options.bar.autoHide.showWhenPressingSuper.delay
                from: 0
                to: 1000
                stepSize: 10
                onValueChanged: {
                    Config.options.bar.autoHide.showWhenPressingSuper.delay = value;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Shown on monitors")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("All monitors")
                text: Config.options.bar.screenList.join(", ")
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.bar.screenList = text.split(",").map(s => s.trim()).filter(s => s.length > 0);
                }
                StyledToolTip {
                    text: Translation.tr("Comma-separated monitor names to show the bar on, like \"eDP-1, DP-1\". Leave empty to show it on every monitor.")
                }
            }
        }
    }

    ContentSection {
        icon: "palette"
        title: Translation.tr("Bar appearance")

        ConfigSwitch {
            buttonIcon: "format_paint"
            text: Translation.tr("Show background")
            checked: Config.options.bar.showBackground
            onCheckedChanged: {
                Config.options.bar.showBackground = checked;
            }
        }

        ConfigSwitch {
            enabled: Config.options.bar.cornerStyle === 1
            buttonIcon: "shadow"
            text: Translation.tr("Shadow behind bar")
            checked: Config.options.bar.floatStyleShadow
            onCheckedChanged: {
                Config.options.bar.floatStyleShadow = checked;
            }
            StyledToolTip {
                text: Translation.tr("Only visible when Corner style above is set to Float.")
            }
        }

        ConfigSwitch {
            buttonIcon: "subject"
            text: Translation.tr("Verbose")
            checked: Config.options.bar.verbose
            onCheckedChanged: {
                Config.options.bar.verbose = checked;
            }
            StyledToolTip {
                text: Translation.tr("Shows fuller text, like the date next to the clock, in the bar's center modules instead of compact icons.")
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Top-left icon")
            text: Config.options.bar.topLeftIcon
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.bar.topLeftIcon = text;
            }
            StyledToolTip {
                text: Translation.tr("Icon shown at the bar's top left, which opens the left sidebar. Use \"distro\" for your OS logo, or the name of an icon file in ~/.config/quickshell/ii/assets/icons.")
            }
        }
    }

    ContentSection {
        icon: "shelf_auto_hide"
        title: Translation.tr("Tray")

        ConfigSwitch {
            buttonIcon: "keep"
            text: Translation.tr('Make icons pinned by default')
            checked: Config.options.tray.invertPinnedItems
            onCheckedChanged: {
                Config.options.tray.invertPinnedItems = checked;
            }
        }
        
        ConfigSwitch {
            buttonIcon: "colors"
            text: Translation.tr('Tint icons')
            checked: Config.options.tray.monochromeIcons
            onCheckedChanged: {
                Config.options.tray.monochromeIcons = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "visibility_off"
            text: Translation.tr('Hide passive icons')
            checked: Config.options.tray.filterPassive
            onCheckedChanged: {
                Config.options.tray.filterPassive = checked;
            }
            StyledToolTip {
                text: Translation.tr("Hides tray icons that report themselves as passive (inactive).")
            }
        }

        ConfigSwitch {
            buttonIcon: "label"
            text: Translation.tr('Show item ID in tooltip')
            checked: Config.options.tray.showItemId
            onCheckedChanged: {
                Config.options.tray.showItemId = checked;
            }
            StyledToolTip {
                text: Translation.tr("Appends the tray icon's internal ID to its tooltip; useful for finding the ID to pin or filter it.")
            }
        }
    }

    ContentSection {
        icon: "monitor_heart"
        title: Translation.tr("Resources")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "planner_review"
                text: Translation.tr("Always show CPU")
                checked: Config.options.bar.resources.alwaysShowCpu
                onCheckedChanged: {
                    Config.options.bar.resources.alwaysShowCpu = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "swap_horiz"
                text: Translation.tr("Always show swap")
                checked: Config.options.bar.resources.alwaysShowSwap
                onCheckedChanged: {
                    Config.options.bar.resources.alwaysShowSwap = checked;
                }
            }
        }

        ConfigSpinBox {
            icon: "memory"
            text: Translation.tr("Memory warning threshold (%)")
            value: Config.options.bar.resources.memoryWarningThreshold
            from: 0
            to: 100
            stepSize: 5
            onValueChanged: {
                Config.options.bar.resources.memoryWarningThreshold = value;
            }
        }

        ConfigSpinBox {
            icon: "swap_horiz"
            text: Translation.tr("Swap warning threshold (%)")
            value: Config.options.bar.resources.swapWarningThreshold
            from: 0
            to: 100
            stepSize: 5
            onValueChanged: {
                Config.options.bar.resources.swapWarningThreshold = value;
            }
        }

        ConfigSpinBox {
            icon: "planner_review"
            text: Translation.tr("CPU warning threshold (%)")
            value: Config.options.bar.resources.cpuWarningThreshold
            from: 0
            to: 100
            stepSize: 5
            onValueChanged: {
                Config.options.bar.resources.cpuWarningThreshold = value;
            }
        }
    }

    ContentSection {
        icon: "widgets"
        title: Translation.tr("Utility buttons")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "content_cut"
                text: Translation.tr("Screen snip")
                checked: Config.options.bar.utilButtons.showScreenSnip
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenSnip = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "colorize"
                text: Translation.tr("Color picker")
                checked: Config.options.bar.utilButtons.showColorPicker
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showColorPicker = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "keyboard"
                text: Translation.tr("Keyboard toggle")
                checked: Config.options.bar.utilButtons.showKeyboardToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showKeyboardToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "mic"
                text: Translation.tr("Mic toggle")
                checked: Config.options.bar.utilButtons.showMicToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showMicToggle = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "dark_mode"
                text: Translation.tr("Dark/Light toggle")
                checked: Config.options.bar.utilButtons.showDarkModeToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showDarkModeToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "speed"
                text: Translation.tr("Performance Profile toggle")
                checked: Config.options.bar.utilButtons.showPerformanceProfileToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showPerformanceProfileToggle = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "videocam"
                text: Translation.tr("Record")
                checked: Config.options.bar.utilButtons.showScreenRecord
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenRecord = checked;
                }
            }
        }
    }

    ContentSection {
        icon: "cloud"
        title: Translation.tr("Weather")
        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable")
            checked: Config.options.bar.weather.enable
            onCheckedChanged: {
                Config.options.bar.weather.enable = checked;
            }
        }
    }

    ContentSection {
        icon: "workspaces"
        title: Translation.tr("Workspaces")

        ConfigSwitch {
            buttonIcon: "counter_1"
            text: Translation.tr('Always show numbers')
            checked: Config.options.bar.workspaces.alwaysShowNumbers
            onCheckedChanged: {
                Config.options.bar.workspaces.alwaysShowNumbers = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "award_star"
            text: Translation.tr('Show app icons')
            checked: Config.options.bar.workspaces.showAppIcons
            onCheckedChanged: {
                Config.options.bar.workspaces.showAppIcons = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "colors"
            text: Translation.tr('Tint app icons')
            checked: Config.options.bar.workspaces.monochromeIcons
            onCheckedChanged: {
                Config.options.bar.workspaces.monochromeIcons = checked;
            }
        }

        ConfigSpinBox {
            icon: "view_column"
            text: Translation.tr("Workspaces shown")
            value: Config.options.bar.workspaces.shown
            from: 1
            to: 30
            stepSize: 1
            onValueChanged: {
                Config.options.bar.workspaces.shown = value;
            }
        }

        ConfigSpinBox {
            icon: "touch_long"
            text: Translation.tr("Number show delay when pressing Super (ms)")
            value: Config.options.bar.workspaces.showNumberDelay
            from: 0
            to: 1000
            stepSize: 50
            onValueChanged: {
                Config.options.bar.workspaces.showNumberDelay = value;
            }
        }

        ConfigSwitch {
            buttonIcon: "font_download"
            text: Translation.tr('Use Nerd Font for numbers')
            checked: Config.options.bar.workspaces.useNerdFont
            onCheckedChanged: {
                Config.options.bar.workspaces.useNerdFont = checked;
            }
            StyledToolTip {
                text: Translation.tr("Renders workspace numbers with a Nerd Font glyph set instead of the regular font. The font must be installed.")
            }
        }

        ContentSubsection {
            title: Translation.tr("Number style")

            ConfigSelectionArray {
                currentValue: JSON.stringify(Config.options.bar.workspaces.numberMap)
                onSelected: newValue => {
                    Config.options.bar.workspaces.numberMap = JSON.parse(newValue)
                }
                options: [
                    {
                        displayName: Translation.tr("Normal"),
                        icon: "timer_10",
                        value: '[]'
                    },
                    {
                        displayName: Translation.tr("Han chars"),
                        icon: "square_dot",
                        value: '["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]'
                    },
                    {
                        displayName: Translation.tr("Roman"),
                        icon: "account_balance",
                        value: '["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"]'
                    }
                ]
            }
        }
    }

    ContentSection {
        icon: "tooltip"
        title: Translation.tr("Tooltips")
        ConfigSwitch {
            buttonIcon: "ads_click"
            text: Translation.tr("Click to show")
            checked: Config.options.bar.tooltips.clickToShow
            onCheckedChanged: {
                Config.options.bar.tooltips.clickToShow = checked;
            }
        }
    }
}

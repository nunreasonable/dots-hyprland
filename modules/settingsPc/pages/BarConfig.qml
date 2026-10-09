import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets as W
import qs.modules.settingsPc.widgets

ContentPage {
    id: page
    forceWidth: true

    readonly property var screenNames: Quickshell.screens.map(screen => screen.name)

    readonly property var shownOn: name => Config.options.bar.screenList.length === 0 || Config.options.bar.screenList.includes(name)
    readonly property var forcedMonitorOptions: page.screenNames
        .concat(Config.options.notifications.forceMonitor.name.length > 0 && !page.screenNames.includes(Config.options.notifications.forceMonitor.name) ? [Config.options.notifications.forceMonitor.name] : [])
        .map(name => ({ displayName: name, value: name }))

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            icon: "monitor"
            shape: W.MaterialShape.Shape.ClamShell
            visible: page.screenNames.length > 1 || Config.options.bar.screenList.length > 0
            title: Translation.tr("Screens")
            ContentSubsection {
                title: Translation.tr("Shown on monitors")

                ColumnLayout {
                    id: monitorsCol
                    Layout.fillWidth: true
                    spacing: 2

                    Rectangle {
                        id: allRow
                        Layout.fillWidth: true
                        implicitHeight: allSwitchItem.implicitHeight + 16 + 8
                        color: Appearance.colors.colLayer1
                        topLeftRadius: Appearance.rounding.normal
                        topRightRadius: Appearance.rounding.normal
                        bottomLeftRadius: Appearance.rounding.unsharpenmore
                        bottomRightRadius: Appearance.rounding.unsharpenmore

                        ConfigSwitch {
                            id: allSwitchItem
                            anchors { fill: parent; margins: 8 }
                            buttonIcon: "tv_displays"
                            text: Translation.tr("All monitors")
                            onCheckedChanged: {
                                if (checked && Config.options.bar.screenList.length > 0)
                                    Config.options.bar.screenList = [];
                                Qt.callLater(() => {
                                    allSwitchItem.checked = Config.options.bar.screenList.length === 0;
                                });
                            }

                            Binding {
                                target: allSwitchItem
                                property: "checked"
                                value: Config.options.bar.screenList.length === 0
                                restoreMode: Binding.RestoreBinding
                            }
                        }
                    }

                    Repeater {
                        model: page.screenNames
                        delegate: Rectangle {
                            id: monitorRow
                            required property string modelData
                            required property int index
                            readonly property bool isLast: index === page.screenNames.length - 1

                            Layout.fillWidth: true
                            implicitHeight: switchItem.implicitHeight + 16 + 8
                            color: Appearance.colors.colLayer1
                            topLeftRadius:     Appearance.rounding.unsharpenmore
                            topRightRadius:    Appearance.rounding.unsharpenmore
                            bottomLeftRadius:  isLast ? Appearance.rounding.normal : Appearance.rounding.unsharpenmore
                            bottomRightRadius: isLast ? Appearance.rounding.normal : Appearance.rounding.unsharpenmore

                            ConfigSwitch {
                                id: switchItem
                                anchors { fill: parent; margins: 8 }
                                buttonIcon: "monitor"
                                text: monitorRow.modelData
                                onCheckedChanged: {
                                    if (checked !== page.shownOn(monitorRow.modelData)) {
                                        const allNames = page.screenNames
                                        let list = Config.options.bar.screenList.length === 0 ? allNames.slice() : Config.options.bar.screenList.slice()
                                        if (checked) {
                                            if (!list.includes(monitorRow.modelData)) list.push(monitorRow.modelData)
                                        } else {
                                            list = list.filter(s => s !== monitorRow.modelData)
                                        }
                                        if (list.length > 0)
                                            Config.options.bar.screenList = allNames.every(name => list.includes(name)) ? [] : list
                                    }
                                    Qt.callLater(() => {
                                        switchItem.checked = page.shownOn(monitorRow.modelData);
                                    });
                                }

                                Binding {
                                    target: switchItem
                                    property: "checked"
                                    value: page.shownOn(monitorRow.modelData)
                                    restoreMode: Binding.RestoreBinding
                                }
                            }
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "pivot_table_chart"
            shape: W.MaterialShape.Shape.Gem
            title: Translation.tr("Positioning & Styles")
            GroupedList {
                ConfigSelectionArray {
                    text: Translation.tr("Bar position")
                    icon: "swap_vert"
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [
                        { displayName: Translation.tr("Top"),    icon: "arrow_upward",   value: 0 },
                        { displayName: Translation.tr("Left"),   icon: "arrow_back",     value: 2 },
                        { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: 1 },
                        { displayName: Translation.tr("Right"),  icon: "arrow_forward",  value: 3 }
                    ]
                }
                ConfigSelectionArray {
                    text: Translation.tr("Corner style")
                    icon: "style"
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => { Config.options.bar.cornerStyle = newValue; }
                    options: [
                        { displayName: Translation.tr("Hug"),   icon: "line_curve",  value: 0 },
                        { displayName: Translation.tr("Float"), icon: "page_header", value: 1 },
                        { displayName: Translation.tr("Rect"),  icon: "toolbar",     value: 2 }
                    ]
                }
                ConfigSelectionArray {
                    text: Translation.tr("Group style")
                    icon: "tab_group"
                    currentValue: Config.options.bar.borderless
                    onSelected: newValue => { Config.options.bar.borderless = newValue; }
                    options: [
                        { displayName: Translation.tr("Pills"),          icon: "location_chip", value: false },
                        { displayName: Translation.tr("Line-separated"), icon: "split_scene",   value: true }
                    ]
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "format_paint"
                        text: Translation.tr("Show background")
                        checked: Config.options.bar.showBackground
                        onCheckedChanged: { Config.options.bar.showBackground = checked; }
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("Automatically hide")
                        icon: "preview_off"
                        currentValue: Config.options.bar.autoHide.enable
                        onSelected: newValue => { Config.options.bar.autoHide.enable = newValue; }
                        options: [
                            { displayName: Translation.tr("No"),  icon: "close", value: false },
                            { displayName: Translation.tr("Yes"), icon: "check", value: true }
                        ]
                    }
                }
                ConfigSwitch {
                    enabled: Config.options.bar.cornerStyle === 1
                    buttonIcon: "shadow"
                    text: Translation.tr("Shadow behind bar")
                    checked: Config.options.bar.floatStyleShadow
                    onCheckedChanged: { Config.options.bar.floatStyleShadow = checked; }
                    W.StyledToolTip {
                        text: Translation.tr("Only visible when Corner style above is set to Float.")
                    }
                }
                ConfigSwitch {
                    buttonIcon: "subject"
                    text: Translation.tr("Verbose")
                    checked: Config.options.bar.verbose
                    onCheckedChanged: { Config.options.bar.verbose = checked; }
                    W.StyledToolTip {
                        text: Translation.tr("Shows fuller text, like the date next to the clock, in the bar's center modules instead of compact icons.")
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Auto-hide behavior")

                GroupedList {
                    ConfigSwitch {
                        enabled: Config.options.bar.autoHide.enable
                        buttonIcon: "fit_screen"
                        text: Translation.tr("Push windows out of the way")
                        checked: Config.options.bar.autoHide.pushWindows
                        onCheckedChanged: {
                            Config.options.bar.autoHide.pushWindows = checked;
                        }
                        W.StyledToolTip {
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
            }
        }

        ContentSection {
            icon: "notifications"
            shape: W.MaterialShape.Shape.Bun
            title: Translation.tr("Notifications")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "monitor"
                    text: Translation.tr("Force specific monitor")
                    checked: Config.options.notifications.forceMonitor.enable
                    onCheckedChanged: { Config.options.notifications.forceMonitor.enable = checked; }
                    W.StyledToolTip {
                        text: Translation.tr("If you have multiple monitors and want notifications to only show on one of them, enable this and enter the monitor name below (e.g., eDP-1)")
                    }
                }
                ConfigComboBox {
                    enabled: Config.options.notifications.forceMonitor.enable
                    text: Translation.tr("Popup monitor")
                    buttonIcon: "desktop_windows"
                    currentValue: Config.options.notifications.forceMonitor.name
                    fieldWidth: 220
                    fixedWidth: true
                    onSelected: newValue => {
                        Config.options.notifications.forceMonitor.name = newValue;
                    }
                    model: page.forcedMonitorOptions
                }
                ConfigSwitch {
                    buttonIcon: "counter_2"
                    text: Translation.tr("Unread indicator: show count")
                    checked: Config.options.bar.indicators.notifications.showUnreadCount
                    onCheckedChanged: { Config.options.bar.indicators.notifications.showUnreadCount = checked; }
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
            }
        }

        ContentSection {
            shape: W.MaterialShape.Shape.Square
            icon: "inbox_customize"
            title: Translation.tr("Tray")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "keep"
                    text: Translation.tr("Make icons pinned by default")
                    checked: Config.options.tray.invertPinnedItems
                    onCheckedChanged: { Config.options.tray.invertPinnedItems = checked; }
                }
                ConfigSwitch {
                    buttonIcon: "colors"
                    text: Translation.tr("Tint icons")
                    checked: Config.options.tray.monochromeIcons
                    onCheckedChanged: { Config.options.tray.monochromeIcons = checked; }
                }
                ConfigSwitch {
                    buttonIcon: "visibility_off"
                    text: Translation.tr("Hide passive icons")
                    checked: Config.options.tray.filterPassive
                    onCheckedChanged: { Config.options.tray.filterPassive = checked; }
                    W.StyledToolTip {
                        text: Translation.tr("Hides tray icons that report themselves as passive (inactive).")
                    }
                }
                ConfigSwitch {
                    buttonIcon: "label"
                    text: Translation.tr("Show item ID in tooltip")
                    checked: Config.options.tray.showItemId
                    onCheckedChanged: { Config.options.tray.showItemId = checked; }
                    W.StyledToolTip {
                        text: Translation.tr("Appends the tray icon's internal ID to its tooltip; useful for finding the ID to pin or filter it.")
                    }
                }
            }
        }

        ContentSection {
            icon: "right_panel_open"
            shape: W.MaterialShape.Shape.Pentagon
            title: Translation.tr("Left sidebar button")

            GroupedList {
                ConfigTextArea {
                    id: topLeftIconField
                    Layout.fillWidth: true
                    buttonIcon: "image"
                    text: Translation.tr("Top-left icon")
                    placeholderText: "distro"
                    value: Config.options.bar.topLeftIcon
                    onValueChanged: {
                        Config.options.bar.topLeftIcon = value;
                    }
                    W.StyledToolTip {
                        text: Translation.tr("Icon shown at the bar's top left, which opens the left sidebar. Use \"distro\" for your OS logo, or the name of an icon file in ~/.config/quickshell/ii/assets/icons.")
                    }
                }
            }
        }

        ContentSection {
            icon: "buttons_alt"
            shape: W.MaterialShape.Shape.SoftBurst
            title: Translation.tr("Utility buttons")

            GroupedList {
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "content_cut"
                        text: Translation.tr("Screen snip")
                        checked: Config.options.bar.utilButtons.showScreenSnip
                        onCheckedChanged: { Config.options.bar.utilButtons.showScreenSnip = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "colorize"
                        text: Translation.tr("Color picker")
                        checked: Config.options.bar.utilButtons.showColorPicker
                        onCheckedChanged: { Config.options.bar.utilButtons.showColorPicker = checked }
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "keyboard"
                        text: Translation.tr("Keyboard toggle")
                        checked: Config.options.bar.utilButtons.showKeyboardToggle
                        onCheckedChanged: { Config.options.bar.utilButtons.showKeyboardToggle = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "mic"
                        text: Translation.tr("Mic toggle")
                        checked: Config.options.bar.utilButtons.showMicToggle
                        onCheckedChanged: { Config.options.bar.utilButtons.showMicToggle = checked }
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "dark_mode"
                        text: Translation.tr("Dark/Light toggle")
                        checked: Config.options.bar.utilButtons.showDarkModeToggle
                        onCheckedChanged: { Config.options.bar.utilButtons.showDarkModeToggle = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "speed"
                        text: Translation.tr("Performance Profile toggle")
                        checked: Config.options.bar.utilButtons.showPerformanceProfileToggle
                        onCheckedChanged: { Config.options.bar.utilButtons.showPerformanceProfileToggle = checked }
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "videocam"
                        text: Translation.tr("Record")
                        checked: Config.options.bar.utilButtons.showScreenRecord
                        onCheckedChanged: { Config.options.bar.utilButtons.showScreenRecord = checked }
                    }
                }
            }
        }

        ContentSection {
            shape: W.MaterialShape.Shape.Cookie12Sided
            icon: "steppers"
            title: Translation.tr("Workspaces")
            GroupedList {
                ConfigSpinBox {
                    icon: "view_column"
                    text: Translation.tr("Workspaces shown")
                    value: Config.options.bar.workspaces.shown
                    from: 1
                    to: 30
                    stepSize: 1
                    onValueChanged: { Config.options.bar.workspaces.shown = value; }
                }
                ConfigSwitch {
                    buttonIcon: "counter_1"
                    text: Translation.tr("Always show numbers")
                    checked: Config.options.bar.workspaces.alwaysShowNumbers
                    onCheckedChanged: { Config.options.bar.workspaces.alwaysShowNumbers = checked; }
                }
                ConfigSelectionArray {
                    text: Translation.tr("Number style")
                    icon: "looks_3"
                    currentValue: JSON.stringify(Config.options.bar.workspaces.numberMap)
                    onSelected: newValue => {
                        Config.options.bar.workspaces.numberMap = JSON.parse(newValue)
                    }
                    options: [
                        { displayName: Translation.tr("Normal"),    icon: "timer_10",        value: '[]' },
                        { displayName: Translation.tr("Han chars"), icon: "square_dot",      value: '["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]' },
                        { displayName: Translation.tr("Roman"),     icon: "account_balance", value: '["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"]' }
                    ]
                }
                ConfigSwitch {
                    buttonIcon: "font_download"
                    text: Translation.tr("Use Nerd Font for numbers")
                    checked: Config.options.bar.workspaces.useNerdFont
                    onCheckedChanged: { Config.options.bar.workspaces.useNerdFont = checked; }
                    W.StyledToolTip {
                        text: Translation.tr("Renders workspace numbers with a Nerd Font glyph set instead of the regular font. The font must be installed.")
                    }
                }
                ConfigSpinBox {
                    icon: "touch_long"
                    text: Translation.tr("Number show delay when pressing Super (ms)")
                    value: Config.options.bar.workspaces.showNumberDelay
                    from: 0
                    to: 1000
                    stepSize: 50
                    onValueChanged: { Config.options.bar.workspaces.showNumberDelay = value; }
                }
                ConfigSwitch {
                    buttonIcon: "award_star"
                    text: Translation.tr("Show app icons")
                    checked: Config.options.bar.workspaces.showAppIcons
                    onCheckedChanged: { Config.options.bar.workspaces.showAppIcons = checked; }
                }
                ConfigSwitch {
                    buttonIcon: "palette"
                    text: Translation.tr("Tint app icons")
                    checked: Config.options.bar.workspaces.monochromeIcons
                    onCheckedChanged: { Config.options.bar.workspaces.monochromeIcons = checked; }
                }
            }
        }

        ContentSection {
            icon: "empty_dashboard"
            shape: W.MaterialShape.Shape.Burst
            title: Translation.tr("Resources")

            GroupedList {
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "planner_review"
                        text: Translation.tr("Always show CPU")
                        checked: Config.options.bar.resources.alwaysShowCpu
                        onCheckedChanged: { Config.options.bar.resources.alwaysShowCpu = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "swap_horiz"
                        text: Translation.tr("Always show swap")
                        checked: Config.options.bar.resources.alwaysShowSwap
                        onCheckedChanged: { Config.options.bar.resources.alwaysShowSwap = checked }
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
        }

        ContentSection {
            icon: "cloud"
            shape: W.MaterialShape.Shape.Pill
            title: Translation.tr("Weather")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.bar.weather.enable
                    onCheckedChanged: { Config.options.bar.weather.enable = checked; }
                }
            }
        }

        ContentSection {
            shape: W.MaterialShape.Shape.Puffy
            icon: "tooltip"
            title: Translation.tr("Tooltips")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "ads_click"
                    text: Translation.tr("Click to show")
                    checked: Config.options.bar.tooltips.clickToShow
                    onCheckedChanged: { Config.options.bar.tooltips.clickToShow = checked; }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    readonly property color leftIconColor: {
        const name = Config.options.custom.iconColor || "onLayer0";
        return Appearance.colors[`col${name.charAt(0).toUpperCase()}${name.slice(1)}`] ?? Appearance.colors.colOnLayer0;
    }

    ContentSection {
        icon: "splitscreen_add"
        title: Translation.tr("Bar layout")

        StyledText {
            Layout.fillWidth: true
            text: BarLayouts.classic ? Translation.tr("The default layout is ii's original bar. Changing any widget switches to the configurable layout.") : Translation.tr("Drag widgets to reorder them, click one to remove it, or press + to add one.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        ContentSubsection {
            title: Config.options.bar.vertical ? Translation.tr("Top") : Translation.tr("Left")
            BarLayoutChips {
                layout: Config.options.bar.layouts.leftLayout
                availableWidgets: BarLayouts.availableFor("left")
                getWidgetName: id => BarLayouts.name(id)
                onLayoutEdited: list => {
                    Config.options.bar.layouts.leftLayout = list;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Center")
            BarLayoutChips {
                layout: Config.options.bar.layouts.middleLayout
                availableWidgets: BarLayouts.availableFor("middle")
                getWidgetName: id => BarLayouts.name(id)
                onLayoutEdited: list => {
                    Config.options.bar.layouts.middleLayout = list;
                }
            }
        }

        ContentSubsection {
            title: Config.options.bar.vertical ? Translation.tr("Bottom") : Translation.tr("Right")
            BarLayoutChips {
                layout: Config.options.bar.layouts.rightLayout
                availableWidgets: BarLayouts.availableFor("right")
                getWidgetName: id => BarLayouts.name(id)
                onLayoutEdited: list => {
                    Config.options.bar.layouts.rightLayout = list;
                }
            }
        }

        ConfigRow {
            uniform: true
            RippleButtonWithIcon {
                Layout.fillWidth: true
                enabled: !BarLayouts.classic
                materialIcon: "restart_alt"
                mainText: Translation.tr("ii layout")
                onClicked: {
                    Config.options.bar.layouts.leftLayout = BarLayouts.classicLeft;
                    Config.options.bar.layouts.middleLayout = BarLayouts.classicMiddle;
                    Config.options.bar.layouts.rightLayout = BarLayouts.classicRight;
                }
            }
            RippleButtonWithIcon {
                Layout.fillWidth: true
                materialIcon: "dashboard_customize"
                mainText: Translation.tr("end4-pC layout")
                onClicked: {
                    Config.options.bar.layouts.leftLayout = BarLayouts.end4pcLeft;
                    Config.options.bar.layouts.middleLayout = BarLayouts.end4pcMiddle;
                    Config.options.bar.layouts.rightLayout = BarLayouts.end4pcRight;
                }
            }
        }
    }

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
                onEditingFinished: {
                    const items = text.split(",").map(s => s.trim()).filter(s => s.length > 0);
                    if (items.join(", ") !== Config.options.bar.screenList.join(", "))
                        Config.options.bar.screenList = items;
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

        ContentSubsection {
            title: Translation.tr("Group color")
            ColorSelectionArray {
                Layout.leftMargin: 0
                showLabel: false
                showTooltip: true
                options: ["primaryContainer", "secondaryContainer", "tertiaryContainer", "layer1", "layer0"]
                currentValue: Config.options.bar.groupColor
                onSelected: newValue => {
                    Config.options.bar.groupColor = newValue;
                }
            }
        }

        RippleButtonWithIcon {
            enabled: (Config.options.bar.widgetStyles ?? []).length > 0
            materialIcon: "format_color_reset"
            mainText: Translation.tr("Reset widget styles")
            onClicked: {
                Config.options.bar.widgetStyles = [];
            }
            StyledToolTip {
                text: Translation.tr("Right-click a widget on the bar to change its background, border, radius and padding (configurable layout only).")
            }
        }

        ContentSubsection {
            title: Translation.tr("Left sidebar button icon")

            ConfigRow {
                CustomIcon {
                    source: Config.options.custom.distroIcon || (Config.options.bar.topLeftIcon == "distro" ? SystemInfo.distroIcon : `${Config.options.bar.topLeftIcon}-symbolic`)
                    customFolder: Config.options.custom.distroIcon !== "" ? Config.options.custom.iconsPath : ""
                    colorize: Config.options.custom.colorizeIcon
                    color: page.leftIconColor
                    width: Appearance.font.pixelSize.larger
                    height: Appearance.font.pixelSize.larger
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Config.options.custom.distroIcon !== "" ? Config.options.custom.distroIcon.replace("-symbolic", "") : Translation.tr("Top-left icon")
                    color: Appearance.colors.colSubtext
                }
                RippleButtonWithIcon {
                    enabled: Config.options.custom.distroIcon !== ""
                    materialIcon: "restart_alt"
                    mainText: Translation.tr("Default")
                    onClicked: {
                        Config.options.custom.distroIcon = "";
                    }
                }
            }

            IconPickerGrid {
                customFolder: Config.options.custom.iconsPath
                currentValue: Config.options.custom.distroIcon
                colorize: Config.options.custom.colorizeIcon
                iconColor: page.leftIconColor
                onSelected: name => {
                    Config.options.custom.distroIcon = name;
                }
            }

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Custom icons folder")
                text: Config.options.custom.iconsPath
                wrapMode: TextEdit.Wrap
                onEditingFinished: {
                    if (text !== Config.options.custom.iconsPath)
                        Config.options.custom.iconsPath = text;
                }
                StyledToolTip {
                    text: Platform.isWindows ? Translation.tr("Leave empty to use the built-in icons, e.g. %USERPROFILE%\\Pictures\\icons") : Translation.tr("Leave empty to use the built-in icons, e.g. ~/Pictures/icons")
                }
            }

            ConfigSwitch {
                buttonIcon: "colors"
                text: Translation.tr("Colorize icon")
                checked: Config.options.custom.colorizeIcon
                onCheckedChanged: {
                    Config.options.custom.colorizeIcon = checked;
                }
            }

            ColorSelectionArray {
                Layout.leftMargin: 0
                enabled: Config.options.custom.colorizeIcon
                opacity: enabled ? 1 : 0.4
                icon: "palette"
                text: Translation.tr("Icon color")
                options: ["onLayer0", "primary", "secondary", "tertiary", "onPrimaryContainer", "onSecondaryContainer", "onTertiaryContainer"]
                currentValue: Config.options.custom.iconColor
                onSelected: newValue => {
                    Config.options.custom.iconColor = newValue;
                }
            }
        }
    }

    ContentSection {
        icon: "panorama_wide_angle"
        title: Translation.tr("Screen frame")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "panorama_wide_angle"
                text: Translation.tr("Show frame")
                checked: Config.options.bar.showFrame
                onCheckedChanged: {
                    Config.options.bar.showFrame = checked;
                }
            }
            ConfigSwitch {
                enabled: Config.options.bar.showFrame
                buttonIcon: "colors"
                text: Translation.tr("Follow frame color")
                checked: Config.options.bar.followFrameColor
                onCheckedChanged: {
                    Config.options.bar.followFrameColor = checked;
                }
                StyledToolTip {
                    text: Translation.tr("The bar background uses the frame color.")
                }
            }
        }

        ConfigSpinBox {
            enabled: Config.options.bar.showFrame
            icon: "eraser_size_1"
            text: Translation.tr("Frame thickness")
            value: Config.options.bar.frameThickness
            from: 2
            to: 10
            stepSize: 1
            onValueChanged: {
                Config.options.bar.frameThickness = value;
            }
        }

        ContentSubsection {
            title: Translation.tr("Frame color")
            ColorSelectionArray {
                Layout.leftMargin: 0
                enabled: Config.options.bar.showFrame
                opacity: enabled ? 1 : 0.5
                showLabel: false
                showTooltip: true
                options: ["primaryContainer", "secondaryContainer", "tertiaryContainer", "layer0", "black"]
                currentValue: Config.options.bar.frameColor
                onSelected: newValue => {
                    Config.options.bar.frameColor = newValue;
                }
            }
        }

        ConfigSwitch {
            enabled: Config.options.bar.showFrame
            buttonIcon: "expand"
            text: Translation.tr("Overlap windows when center-only")
            checked: Config.options.bar.centerOnlyReserveFrame
            onCheckedChanged: {
                Config.options.bar.centerOnlyReserveFrame = checked;
            }
            StyledToolTip {
                text: Translation.tr("When the left and right sides of the bar are empty, only the frame reserves space and windows go under the bar.")
            }
        }
    }

    ContentSection {
        icon: "nest_wifi_pro"
        title: Translation.tr("Dynamic Island")

        StyledText {
            Layout.fillWidth: true
            visible: !BarLayouts.isUsed("dynamicIsland")
            text: Translation.tr("Add the Dynamic Island to the center of the bar layout to use it.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Left widget")
                Layout.fillWidth: true
                ConfigSelectionArray {
                    currentValue: Config.options.bar.dynamicIsland.leftWidget
                    onSelected: newValue => {
                        Config.options.bar.dynamicIsland.leftWidget = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("None"),
                            icon: "block",
                            value: "none"
                        },
                        {
                            displayName: Translation.tr("Clock and date"),
                            icon: "schedule",
                            value: "clockWidget"
                        },
                        {
                            displayName: Translation.tr("Weather"),
                            icon: "partly_cloudy_day",
                            value: "weatherBar"
                        }
                    ]
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Right widget")
            ConfigSelectionArray {
                currentValue: Config.options.bar.dynamicIsland.rightWidget
                onSelected: newValue => {
                    Config.options.bar.dynamicIsland.rightWidget = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("None"),
                        icon: "block",
                        value: "none"
                    },
                    {
                        displayName: Translation.tr("System Icons"),
                        icon: "settings",
                        value: "systemIcons"
                    },
                    {
                        displayName: Translation.tr("Tray"),
                        icon: "apps",
                        value: "sysTray"
                    },
                    {
                        displayName: Translation.tr("Util Buttons"),
                        icon: "widgets",
                        value: "utilButtons"
                    }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Visualizer style")
            ConfigSelectionArray {
                currentValue: Config.options.bar.dynamicIsland.visualizerStyle
                onSelected: newValue => {
                    Config.options.bar.dynamicIsland.visualizerStyle = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("None"),
                        icon: "block",
                        value: "none"
                    },
                    {
                        displayName: Translation.tr("Dots"),
                        icon: "steppers",
                        value: "dots"
                    },
                    {
                        displayName: Translation.tr("Wave"),
                        icon: "ssid_chart",
                        value: "wave"
                    }
                ]
            }
        }

        ConfigSwitch {
            buttonIcon: "play_circle"
            text: Translation.tr("Show media controls")
            checked: Config.options.bar.dynamicIsland.showMediaControls
            onCheckedChanged: {
                Config.options.bar.dynamicIsland.showMediaControls = checked;
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
                buttonIcon: "memory"
                text: Translation.tr("RAM")
                checked: Config.options.bar.resources.alwaysShowRam
                onCheckedChanged: {
                    Config.options.bar.resources.alwaysShowRam = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "storage"
                text: Translation.tr("Disk")
                checked: Config.options.bar.resources.alwaysShowDisk
                onCheckedChanged: {
                    Config.options.bar.resources.alwaysShowDisk = checked;
                }
                StyledToolTip {
                    text: Platform.isWindows ? Translation.tr("Usage of the system drive") : Translation.tr("Usage of the root partition")
                }
            }
        }

        ConfigSwitch {
            visible: !Platform.isWindows
            buttonIcon: "thermostat"
            text: Translation.tr("CPU temperature")
            checked: Config.options.bar.resources.alwaysShowCpuTemp
            onCheckedChanged: {
                Config.options.bar.resources.alwaysShowCpuTemp = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "decimal_increase"
            text: Translation.tr("Show percentage")
            checked: Config.options.bar.resources.showValue
            onCheckedChanged: {
                Config.options.bar.resources.showValue = checked;
            }
        }

        ContentSubsection {
            title: Translation.tr("Style")
            ConfigSelectionArray {
                currentValue: Config.options.bar.resources.style
                onSelected: newValue => {
                    Config.options.bar.resources.style = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Filled"),
                        icon: "incomplete_circle",
                        value: "filled"
                    },
                    {
                        displayName: Translation.tr("Outline"),
                        icon: "circles",
                        value: "outline"
                    },
                    {
                        displayName: Translation.tr("Text"),
                        icon: "text_fields",
                        value: "text"
                    }
                ]
            }
        }

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
            ConfigSwitch {
                buttonIcon: "imagesmode"
                text: Translation.tr("Wallpapers toggle")
                checked: Config.options.bar.utilButtons.showWallpaperToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showWallpaperToggle = checked;
                }
            }
        }
    }

    ContentSection {
        icon: "music_note"
        title: Translation.tr("Media")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Preferred player")
            text: Config.options.bar.media.preferredPlayer
            wrapMode: TextEdit.Wrap
            onEditingFinished: {
                if (text !== Config.options.bar.media.preferredPlayer)
                    Config.options.bar.media.preferredPlayer = text;
            }
            StyledToolTip {
                text: Platform.isWindows ? Translation.tr("e.g. spotify, chrome") : Translation.tr("e.g. spotify, firefox")
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "keep"
                text: Translation.tr("Pin media controls")
                checked: Config.options.bar.media.alwaysVisible
                onCheckedChanged: {
                    Config.options.bar.media.alwaysVisible = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Media controls stay open when clicking elsewhere.")
                }
            }
            ConfigSwitch {
                buttonIcon: "lyrics"
                text: Translation.tr("Show lyrics")
                checked: Config.options.bar.media.showLyrics
                onCheckedChanged: {
                    Config.options.bar.media.showLyrics = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Synced lyrics in the media controls, fetched from lrclib.net.")
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "titlecase"
            text: Translation.tr("Show only title")
            checked: Config.options.bar.media.onlyTitle
            onCheckedChanged: {
                Config.options.bar.media.onlyTitle = checked;
            }
        }

        ConfigSpinBox {
            enabled: !BarLayouts.classic
            icon: "width"
            text: Translation.tr("Max media width")
            value: Config.options.bar.media.maxWidth
            from: 100
            to: 500
            stepSize: 10
            onValueChanged: {
                Config.options.bar.media.maxWidth = value;
            }
        }

        ConfigSpinBox {
            enabled: !BarLayouts.classic
            icon: "width_normal"
            text: Translation.tr("Min media width")
            value: Config.options.bar.media.minWidth
            from: 0
            to: 500
            stepSize: 10
            onValueChanged: {
                Config.options.bar.media.minWidth = value;
            }
        }
    }

    ContentSection {
        icon: "neurology"
        title: Translation.tr("AI Usage")

        ConfigSpinBox {
            icon: "token"
            text: Translation.tr("Token limit per 5 hours")
            value: Config.options.bar.aiUsage.tokenLimit
            from: 10000
            to: 100000000
            stepSize: 100000
            onValueChanged: {
                Config.options.bar.aiUsage.tokenLimit = value;
            }
        }

        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Update interval (s)")
            value: Config.options.bar.aiUsage.updateInterval
            from: 10
            to: 3600
            stepSize: 10
            onValueChanged: {
                Config.options.bar.aiUsage.updateInterval = value;
            }
        }
    }

    ContentSection {
        icon: "vertical_align_center"
        title: Translation.tr("Divider")

        ContentSubsection {
            title: Translation.tr("Style")
            ConfigSelectionArray {
                currentValue: Config.options.bar.divider.style
                onSelected: newValue => {
                    Config.options.bar.divider.style = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Line"),
                        icon: "more_vert",
                        value: "rect"
                    },
                    {
                        displayName: Translation.tr("Dot"),
                        icon: "fiber_manual_record",
                        value: "dot"
                    },
                    {
                        displayName: Translation.tr("Space"),
                        icon: "space_bar",
                        value: "space"
                    }
                ]
            }
        }

        ConfigSpinBox {
            enabled: Config.options.bar.divider.style === "space"
            icon: "width"
            text: Translation.tr("Space width (px)")
            value: Config.options.bar.divider.spacing
            from: 4
            to: 400
            stepSize: 2
            onValueChanged: {
                Config.options.bar.divider.spacing = value;
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
            StyledToolTip {
                text: Translation.tr("For the default layout. In a customized layout, add the Weather widget instead.")
            }
        }
    }

    ContentSection {
        icon: "workspaces"
        title: Translation.tr("Workspaces")

        ContentSubsection {
            title: Translation.tr("Style")
            ConfigSelectionArray {
                currentValue: Config.options.bar.workspaces.style ?? "default"
                onSelected: newValue => {
                    Config.options.bar.workspaces.style = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Default"),
                        icon: "view_carousel",
                        value: "default"
                    },
                    {
                        displayName: Translation.tr("GNOME"),
                        icon: "more_horiz",
                        value: "gnome"
                    },
                    {
                        displayName: Translation.tr("Dots"),
                        icon: "hdr_weak",
                        value: "dots"
                    },
                    {
                        displayName: Translation.tr("Ticks"),
                        icon: "more_vert",
                        value: "ticks"
                    }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Indicator style")
            enabled: (Config.options.bar.workspaces.style ?? "default") === "default"
            ConfigSelectionArray {
                currentValue: Config.options.bar.workspaces.indicatorStyle ?? "dot"
                onSelected: newValue => {
                    Config.options.bar.workspaces.indicatorStyle = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Dots"),
                        icon: "radio_button_checked",
                        value: "dot"
                    },
                    {
                        displayName: Translation.tr("Icons"),
                        icon: "interests",
                        value: "icon"
                    }
                ]
            }
        }

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
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "visibility"
                text: Translation.tr("Enable")
                checked: Config.options.bar.tooltips.enable
                onCheckedChanged: {
                    Config.options.bar.tooltips.enable = checked;
                }
            }
            ConfigSwitch {
                enabled: Config.options.bar.tooltips.enable
                buttonIcon: "ads_click"
                text: Translation.tr("Click to show")
                checked: Config.options.bar.tooltips.clickToShow
                onCheckedChanged: {
                    Config.options.bar.tooltips.clickToShow = checked;
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Style")
            enabled: Config.options.bar.tooltips.enable
            ConfigSelectionArray {
                currentValue: Config.options.bar.tooltips.style
                onSelected: newValue => {
                    Config.options.bar.tooltips.style = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Default"),
                        icon: "tooltip",
                        value: "default"
                    },
                    {
                        displayName: Translation.tr("Morph"),
                        icon: "join_inner",
                        value: "morph"
                    }
                ]
            }
        }
    }
}

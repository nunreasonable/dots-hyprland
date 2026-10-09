import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets as W
import qs.modules.settingsPc.widgets

ContentPage {
    id: page
    forceWidth: true

    readonly property var placementOptions: [
        {
            displayName: Translation.tr("Draggable"),
            icon: "drag_pan",
            value: "free"
        },
        {
            displayName: Translation.tr("Least busy"),
            icon: "category",
            value: "leastBusy"
        },
        {
            displayName: Translation.tr("Most busy"),
            icon: "shapes",
            value: "mostBusy"
        },
    ]

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            icon: "panorama"
            title: Translation.tr("Wallpaper")
            shape: W.MaterialShape.Shape.Clover4Leaf

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "fullscreen"
                    text: Translation.tr("Hide when fullscreen")
                    checked: Config.options.background.hideWhenFullscreen
                    onCheckedChanged: {
                        Config.options.background.hideWhenFullscreen = checked;
                    }
                    W.StyledToolTip {
                        text: Translation.tr("Hides the wallpaper and its widgets while a window on that monitor is fullscreen.")
                    }
                }
            }

            Loader {
                Layout.fillWidth: true
                active: !Platform.isWindows
                visible: active
                sourceComponent: GroupedList {
                    ConfigSlider {
                        text: Translation.tr("Lock screen blur radius")
                        buttonIcon: "blur_on"
                        usePercentTooltip: false
                        value: Config.options.lock.blur.radius
                        from: 0
                        to: 250
                        stopIndicatorValues: [100]
                        onValueChanged: {
                            Config.options.lock.blur.radius = value;
                        }
                    }
                }
            }
        }

        ContentSection {
            visible: Platform.isWindows
            icon: "desktop_windows"
            shape: W.MaterialShape.Shape.Ghostish
            title: Translation.tr("Windows desktop")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "wallpaper"
                    text: Translation.tr("Put the background behind the desktop icons")
                    checked: Config.options.windowsPort.backgroundBehindIcons
                    onCheckedChanged: {
                        Config.options.windowsPort.backgroundBehindIcons = checked;
                    }
                    W.StyledToolTip {
                        text: Translation.tr("The wallpaper and its widgets become part of the Windows desktop, and Show desktop (Win+D) keeps them.\nThe wallpaper goes behind the icons; the widgets stay above them and can still be dragged, and the icons work everywhere around them.\nIf the desktop isn't available, the background stays a window.")
                    }
                }

                ConfigSwitch {
                    buttonIcon: "animation"
                    text: Translation.tr("Draw ii's own wallpaper")
                    enabled: Config.options.windowsPort.backgroundBehindIcons
                    checked: Config.options.windowsPort.ownWallpaper
                    onCheckedChanged: {
                        Config.options.windowsPort.ownWallpaper = checked;
                    }
                    W.StyledToolTip {
                        text: Translation.tr("Off: Windows draws the wallpaper, which ii keeps the same as the one you pick, and only ii's widgets go on the desktop. Changing the wallpaper in Windows' settings changes ii's too.\nOn: ii draws its own wallpaper over Windows' one, with parallax between workspaces.")
                    }
                }
            }
        }

        ContentSection {
            icon: "sync_alt"
            shape: W.MaterialShape.Shape.Oval
            title: Translation.tr("Parallax")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "unfold_more_double"
                    text: Translation.tr("Vertical")
                    checked: Config.options.background.parallax.vertical
                    onCheckedChanged: {
                        Config.options.background.parallax.vertical = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "screen_rotation"
                    text: Translation.tr("Automatic vertical")
                    checked: Config.options.background.parallax.autoVertical
                    onCheckedChanged: {
                        Config.options.background.parallax.autoVertical = checked;
                    }
                    W.StyledToolTip {
                        text: Translation.tr("Uses vertical parallax automatically when the wallpaper is taller than it is wide. Ignored when Vertical above is on.")
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "counter_1"
                        text: Translation.tr("Depends on workspace")
                        checked: Config.options.background.parallax.enableWorkspace
                        onCheckedChanged: {
                            Config.options.background.parallax.enableWorkspace = checked;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "side_navigation"
                        text: Translation.tr("Depends on sidebars")
                        checked: Config.options.background.parallax.enableSidebar
                        onCheckedChanged: {
                            Config.options.background.parallax.enableSidebar = checked;
                        }
                    }
                }
                ConfigSpinBox {
                    icon: "loupe"
                    text: Translation.tr("Preferred wallpaper zoom (%)")
                    value: Config.options.background.parallax.workspaceZoom * 100
                    from: 10
                    to: 200
                    stepSize: 1
                    onValueChanged: {
                        Config.options.background.parallax.workspaceZoom = value / 100;
                    }
                }
                ConfigSpinBox {
                    icon: "open_with"
                    text: Translation.tr("Widgets parallax strength (%)")
                    value: Config.options.background.parallax.widgetsFactor * 100
                    from: 0
                    to: 300
                    stepSize: 5
                    onValueChanged: {
                        Config.options.background.parallax.widgetsFactor = value / 100;
                    }
                }
            }
        }

        ContentSection {
            id: settingsClock
            icon: "clock_loader_40"
            shape: W.MaterialShape.Shape.Bun
            title: Translation.tr("Widget: Clock")

            readonly property bool digitalPresent: (!Config.options.background.widgets.clock.showOnlyWhenLocked && Config.options.background.widgets.clock.style === "digital") || Config.options.background.widgets.clock.styleLocked === "digital"
            readonly property bool cookiePresent: (!Config.options.background.widgets.clock.showOnlyWhenLocked && Config.options.background.widgets.clock.style === "cookie") || Config.options.background.widgets.clock.styleLocked === "cookie"

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.background.widgets.clock.enable
                    onCheckedChanged: {
                        Config.options.background.widgets.clock.enable = checked;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "lock_clock"
                    text: Translation.tr("Show only when locked")
                    checked: Config.options.background.widgets.clock.showOnlyWhenLocked
                    onCheckedChanged: {
                        Config.options.background.widgets.clock.showOnlyWhenLocked = checked;
                    }
                }
                ConfigSelectionArray {
                    text: Translation.tr("Placement strategy")
                    icon: "move"
                    currentValue: Config.options.background.widgets.clock.placementStrategy
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.placementStrategy = newValue;
                    }
                    options: page.placementOptions
                }
                ConfigSelectionArray {
                    enabled: !Config.options.background.widgets.clock.showOnlyWhenLocked
                    text: Translation.tr("Clock style")
                    icon: "nest_clock_farsight_analog"
                    currentValue: Config.options.background.widgets.clock.style
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.style = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Digital"),
                            icon: "timer_10",
                            value: "digital"
                        },
                        {
                            displayName: Translation.tr("Cookie"),
                            icon: "cookie",
                            value: "cookie"
                        }
                    ]
                }
                ConfigSelectionArray {
                    text: Translation.tr("Clock style (locked)")
                    icon: "shield_watch"
                    currentValue: Config.options.background.widgets.clock.styleLocked
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.styleLocked = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Digital"),
                            icon: "timer_10",
                            value: "digital"
                        },
                        {
                            displayName: Translation.tr("Cookie"),
                            icon: "cookie",
                            value: "cookie"
                        }
                    ]
                }
            }

            Loader {
                Layout.fillWidth: true
                active: settingsClock.digitalPresent
                visible: active
                sourceComponent: ContentSubsection {
                    title: Translation.tr("Digital clock settings")
                    tooltip: Translation.tr("Font width and roundness settings are only available for some fonts like Google Sans Flex")

                    GroupedList {
                        ConfigRow {
                            uniform: true
                            ConfigSwitch {
                                buttonIcon: "vertical_distribute"
                                text: Translation.tr("Vertical")
                                checked: Config.options.background.widgets.clock.digital.vertical
                                onCheckedChanged: { Config.options.background.widgets.clock.digital.vertical = checked }
                            }
                            ConfigSwitch {
                                buttonIcon: "animation"
                                text: Translation.tr("Animate time change")
                                checked: Config.options.background.widgets.clock.digital.animateChange
                                onCheckedChanged: { Config.options.background.widgets.clock.digital.animateChange = checked }
                            }
                        }
                        ConfigRow {
                            uniform: true
                            ConfigSwitch {
                                buttonIcon: "date_range"
                                text: Translation.tr("Show date")
                                checked: Config.options.background.widgets.clock.digital.showDate
                                onCheckedChanged: { Config.options.background.widgets.clock.digital.showDate = checked }
                            }
                            ConfigSwitch {
                                buttonIcon: "activity_zone"
                                text: Translation.tr("Use adaptive alignment")
                                checked: Config.options.background.widgets.clock.digital.adaptiveAlignment
                                onCheckedChanged: { Config.options.background.widgets.clock.digital.adaptiveAlignment = checked }
                                W.StyledToolTip {
                                    text: Translation.tr("Aligns the date and quote to left, center or right depending on its position on the screen.")
                                }
                            }
                        }
                    }

                    GroupedList {
                        ConfigComboBox {
                            Layout.fillWidth: true
                            buttonIcon: "font_download"
                            text: Translation.tr("Font family")
                            fieldWidth: 260
                            fixedWidth: true
                            searchable: true
                            model: SettingsPages.fontOptions(Config.options.background.widgets.clock.digital.font.family)
                            currentValue: Config.options.background.widgets.clock.digital.font.family
                            onSelected: newValue => { Config.options.background.widgets.clock.digital.font.family = newValue }
                        }
                        ConfigSlider {
                            text: Translation.tr("Font weight")
                            value: Config.options.background.widgets.clock.digital.font.weight
                            usePercentTooltip: false
                            buttonIcon: "format_bold"
                            from: 1
                            to: 1000
                            stopIndicatorValues: [350]
                            onValueChanged: {
                                Config.options.background.widgets.clock.digital.font.weight = value;
                            }
                        }
                        ConfigSlider {
                            text: Translation.tr("Font size")
                            value: Config.options.background.widgets.clock.digital.font.size
                            usePercentTooltip: false
                            buttonIcon: "format_size"
                            from: 50
                            to: 700
                            stopIndicatorValues: [90]
                            onValueChanged: {
                                Config.options.background.widgets.clock.digital.font.size = value;
                            }
                        }
                        ConfigSlider {
                            text: Translation.tr("Font width")
                            value: Config.options.background.widgets.clock.digital.font.width
                            usePercentTooltip: false
                            buttonIcon: "fit_width"
                            from: 25
                            to: 125
                            stopIndicatorValues: [100]
                            onValueChanged: {
                                Config.options.background.widgets.clock.digital.font.width = value;
                            }
                        }
                        ConfigSlider {
                            text: Translation.tr("Font roundness")
                            value: Config.options.background.widgets.clock.digital.font.roundness
                            usePercentTooltip: false
                            buttonIcon: "line_curve"
                            from: 0
                            to: 100
                            onValueChanged: {
                                Config.options.background.widgets.clock.digital.font.roundness = value;
                            }
                        }
                    }
                }
            }

            Loader {
                Layout.fillWidth: true
                active: settingsClock.cookiePresent
                visible: active
                sourceComponent: ContentSubsection {
                    title: Translation.tr("Cookie clock settings")

                    GroupedList {
                        ConfigSwitch {
                            buttonIcon: "wand_stars"
                            text: Translation.tr("Auto styling with Gemini")
                            checked: Config.options.background.widgets.clock.cookie.aiStyling
                            onCheckedChanged: {
                                Config.options.background.widgets.clock.cookie.aiStyling = checked;
                            }
                            W.StyledToolTip {
                                text: Translation.tr("Uses Gemini to categorize the wallpaper then picks a preset based on it.\nYou'll need to set Gemini API key on the left sidebar first.\nImages are downscaled for performance, but just to be safe,\ndo not select wallpapers with sensitive information.")
                            }
                        }

                        ConfigSwitch {
                            buttonIcon: "airwave"
                            text: Translation.tr("Use old sine wave cookie implementation")
                            checked: Config.options.background.widgets.clock.cookie.useSineCookie
                            onCheckedChanged: {
                                Config.options.background.widgets.clock.cookie.useSineCookie = checked;
                            }
                            W.StyledToolTip {
                                text: Translation.tr("Looks a bit softer and more consistent with different number of sides,\nbut has less impressive morphing")
                            }
                        }

                        ConfigSpinBox {
                            icon: "add_triangle"
                            text: Translation.tr("Sides")
                            value: Config.options.background.widgets.clock.cookie.sides
                            from: 0
                            to: 40
                            stepSize: 1
                            onValueChanged: {
                                Config.options.background.widgets.clock.cookie.sides = value;
                            }
                        }

                        ConfigSwitch {
                            buttonIcon: "autoplay"
                            text: Translation.tr("Constantly rotate")
                            checked: Config.options.background.widgets.clock.cookie.constantlyRotate
                            onCheckedChanged: {
                                Config.options.background.widgets.clock.cookie.constantlyRotate = checked;
                            }
                            W.StyledToolTip {
                                text: Translation.tr("Makes the clock always rotate. This is extremely expensive\n(expect 50% usage on Intel UHD Graphics) and thus impractical.")
                            }
                        }

                        ConfigRow {
                            ConfigSwitch {
                                enabled: Config.options.background.widgets.clock.cookie.dialNumberStyle === "dots" || Config.options.background.widgets.clock.cookie.dialNumberStyle === "full"
                                buttonIcon: "brightness_7"
                                text: Translation.tr("Hour marks")
                                checked: Config.options.background.widgets.clock.cookie.hourMarks
                                onEnabledChanged: {
                                    checked = Config.options.background.widgets.clock.cookie.hourMarks;
                                }
                                onCheckedChanged: {
                                    Config.options.background.widgets.clock.cookie.hourMarks = checked;
                                }
                                W.StyledToolTip {
                                    text: Translation.tr("Can only be turned on using the 'Dots' or 'Full' dial style for aesthetic reasons")
                                }
                            }

                            ConfigSwitch {
                                enabled: Config.options.background.widgets.clock.cookie.dialNumberStyle !== "numbers"
                                buttonIcon: "timer_10"
                                text: Translation.tr("Digits in the middle")
                                checked: Config.options.background.widgets.clock.cookie.timeIndicators
                                onEnabledChanged: {
                                    checked = Config.options.background.widgets.clock.cookie.timeIndicators;
                                }
                                onCheckedChanged: {
                                    Config.options.background.widgets.clock.cookie.timeIndicators = checked;
                                }
                                W.StyledToolTip {
                                    text: Translation.tr("Can't be turned on when using 'Numbers' dial style for aesthetic reasons")
                                }
                            }
                        }
                    }

                    GroupedList {
                        Layout.topMargin: 10
                        ConfigSelectionArray {
                            text: Translation.tr("Dial style")
                            icon: "graph_6"
                            currentValue: Config.options.background.widgets.clock.cookie.dialNumberStyle
                            onSelected: newValue => {
                                Config.options.background.widgets.clock.cookie.dialNumberStyle = newValue;
                                if (newValue !== "dots" && newValue !== "full") {
                                    Config.options.background.widgets.clock.cookie.hourMarks = false;
                                }
                                if (newValue === "numbers") {
                                    Config.options.background.widgets.clock.cookie.timeIndicators = false;
                                }
                            }
                            options: [
                                {
                                    displayName: "",
                                    icon: "block",
                                    value: "none"
                                },
                                {
                                    displayName: Translation.tr("Dots"),
                                    icon: "graph_6",
                                    value: "dots"
                                },
                                {
                                    displayName: Translation.tr("Full"),
                                    icon: "history_toggle_off",
                                    value: "full"
                                },
                                {
                                    displayName: Translation.tr("Numbers"),
                                    icon: "counter_1",
                                    value: "numbers"
                                }
                            ]
                        }
                        ConfigSelectionArray {
                            icon: "highlighter_size_2"
                            text: Translation.tr("Hour hand")
                            currentValue: Config.options.background.widgets.clock.cookie.hourHandStyle
                            onSelected: newValue => {
                                Config.options.background.widgets.clock.cookie.hourHandStyle = newValue;
                            }
                            options: [
                                {
                                    displayName: "",
                                    icon: "block",
                                    value: "hide"
                                },
                                {
                                    displayName: Translation.tr("Classic"),
                                    icon: "radio",
                                    value: "classic"
                                },
                                {
                                    displayName: Translation.tr("Hollow"),
                                    icon: "circle",
                                    value: "hollow"
                                },
                                {
                                    displayName: Translation.tr("Fill"),
                                    icon: "eraser_size_5",
                                    value: "fill"
                                },
                            ]
                        }
                        ConfigSelectionArray {
                            text: Translation.tr("Minute hand")
                            icon: "eraser_size_1"
                            currentValue: Config.options.background.widgets.clock.cookie.minuteHandStyle
                            onSelected: newValue => {
                                Config.options.background.widgets.clock.cookie.minuteHandStyle = newValue;
                            }
                            options: [
                                {
                                    displayName: "",
                                    icon: "block",
                                    value: "hide"
                                },
                                {
                                    displayName: Translation.tr("Classic"),
                                    icon: "radio",
                                    value: "classic"
                                },
                                {
                                    displayName: Translation.tr("Thin"),
                                    icon: "line_end",
                                    value: "thin"
                                },
                                {
                                    displayName: Translation.tr("Medium"),
                                    icon: "eraser_size_2",
                                    value: "medium"
                                },
                                {
                                    displayName: Translation.tr("Bold"),
                                    icon: "eraser_size_4",
                                    value: "bold"
                                },
                            ]
                        }
                        ConfigSelectionArray {
                            text: Translation.tr("Second hand")
                            icon: "pen_size_1"
                            currentValue: Config.options.background.widgets.clock.cookie.secondHandStyle
                            onSelected: newValue => {
                                Config.options.background.widgets.clock.cookie.secondHandStyle = newValue;
                            }
                            options: [
                                {
                                    displayName: "",
                                    icon: "block",
                                    value: "hide"
                                },
                                {
                                    displayName: Translation.tr("Classic"),
                                    icon: "radio",
                                    value: "classic"
                                },
                                {
                                    displayName: Translation.tr("Line"),
                                    icon: "line_end",
                                    value: "line"
                                },
                                {
                                    displayName: Translation.tr("Dot"),
                                    icon: "adjust",
                                    value: "dot"
                                },
                            ]
                        }
                        ConfigSelectionArray {
                            text: Translation.tr("Date style")
                            icon: "date_range"
                            currentValue: Config.options.background.widgets.clock.cookie.dateStyle
                            onSelected: newValue => {
                                Config.options.background.widgets.clock.cookie.dateStyle = newValue;
                            }
                            options: [
                                {
                                    displayName: "",
                                    icon: "block",
                                    value: "hide"
                                },
                                {
                                    displayName: Translation.tr("Bubble"),
                                    icon: "bubble_chart",
                                    value: "bubble"
                                },
                                {
                                    displayName: Translation.tr("Border"),
                                    icon: "rotate_right",
                                    value: "border"
                                },
                                {
                                    displayName: Translation.tr("Rect"),
                                    icon: "rectangle",
                                    value: "rect"
                                }
                            ]
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Quote")
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "check"
                        text: Translation.tr("Enable")
                        checked: Config.options.background.widgets.clock.quote.enable
                        onCheckedChanged: {
                            Config.options.background.widgets.clock.quote.enable = checked;
                        }
                    }
                    ConfigTextArea {
                        Layout.fillWidth: true
                        fieldWidth: 300
                        buttonIcon: "format_quote"
                        text: Translation.tr("Quote")
                        placeholderText: Translation.tr("Quote")
                        value: Config.options.background.widgets.clock.quote.text
                        onValueChanged: {
                            Config.options.background.widgets.clock.quote.text = value;
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "widgets"
            shape: W.MaterialShape.Shape.Pill
            title: Translation.tr("Widgets")

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8
                Rectangle {
                    id: weatherCard
                    readonly property bool widgetEnabled: Config.options.background.widgets.weather.enable
                    Layout.fillWidth: true
                    Layout.preferredHeight: 105
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    ColumnLayout {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            W.MaterialSymbol {
                                text: "weather_mix"
                                iconSize: Appearance.font.pixelSize.normal + 5
                                color: Appearance.colors.colPrimary
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            ConfigSwitch {
                                Layout.fillWidth: false
                                checked: weatherCard.widgetEnabled
                                onCheckedChanged: {
                                    Config.options.background.widgets.weather.enable = checked;
                                }
                            }
                        }
                        W.StyledText {
                            text: Translation.tr("Weather")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                        W.StyledText {
                            text: weatherCard.widgetEnabled ? Translation.tr("Enabled") : Translation.tr("Disabled")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
                Rectangle {
                    id: resourcesCard
                    readonly property bool widgetEnabled: Config.options.background.widgets.resources.enable
                    Layout.fillWidth: true
                    Layout.preferredHeight: 105
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    ColumnLayout {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            W.MaterialSymbol {
                                text: "memory"
                                iconSize: Appearance.font.pixelSize.normal + 5
                                color: Appearance.colors.colPrimary
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            ConfigSwitch {
                                Layout.fillWidth: false
                                checked: resourcesCard.widgetEnabled
                                onCheckedChanged: {
                                    Config.options.background.widgets.resources.enable = checked;
                                }
                            }
                        }
                        W.StyledText {
                            text: Translation.tr("Resources")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                        W.StyledText {
                            text: resourcesCard.widgetEnabled ? Translation.tr("Enabled") : Translation.tr("Disabled")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
                Rectangle {
                    id: calendarCard
                    readonly property bool widgetEnabled: Config.options.background.widgets.calendar.enable
                    Layout.fillWidth: true
                    Layout.preferredHeight: 105
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    ColumnLayout {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            W.MaterialSymbol {
                                text: "calendar_month"
                                iconSize: Appearance.font.pixelSize.normal + 5
                                color: Appearance.colors.colPrimary
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            ConfigSwitch {
                                Layout.fillWidth: false
                                checked: calendarCard.widgetEnabled
                                onCheckedChanged: {
                                    Config.options.background.widgets.calendar.enable = checked;
                                }
                            }
                        }
                        W.StyledText {
                            text: Translation.tr("Calendar")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                        W.StyledText {
                            text: calendarCard.widgetEnabled ? Translation.tr("Enabled") : Translation.tr("Disabled")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
                Rectangle {
                    id: customTextCard
                    readonly property bool widgetEnabled: Config.options.background.widgets.customText.enable
                    Layout.fillWidth: true
                    Layout.preferredHeight: 105
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    ColumnLayout {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            W.MaterialSymbol {
                                text: "text_fields"
                                iconSize: Appearance.font.pixelSize.normal + 5
                                color: Appearance.colors.colPrimary
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            ConfigSwitch {
                                Layout.fillWidth: false
                                checked: customTextCard.widgetEnabled
                                onCheckedChanged: {
                                    Config.options.background.widgets.customText.enable = checked;
                                }
                            }
                        }
                        W.StyledText {
                            text: Translation.tr("Custom text")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                        W.StyledText {
                            text: customTextCard.widgetEnabled ? Translation.tr("Enabled") : Translation.tr("Disabled")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
                Rectangle {
                    id: customImageCard
                    readonly property bool widgetEnabled: Config.options.background.widgets.customImage.enable
                    Layout.fillWidth: true
                    Layout.preferredHeight: 105
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    ColumnLayout {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            W.MaterialSymbol {
                                text: "sticky_note_2"
                                iconSize: Appearance.font.pixelSize.normal + 5
                                color: Appearance.colors.colPrimary
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            ConfigSwitch {
                                Layout.fillWidth: false
                                checked: customImageCard.widgetEnabled
                                onCheckedChanged: {
                                    Config.options.background.widgets.customImage.enable = checked;
                                }
                            }
                        }
                        W.StyledText {
                            text: Translation.tr("Custom image")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                        W.StyledText {
                            text: customImageCard.widgetEnabled ? Translation.tr("Enabled") : Translation.tr("Disabled")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
                Rectangle {
                    id: imageCardCard
                    readonly property bool widgetEnabled: Config.options.background.widgets.imageCard.enable
                    Layout.fillWidth: true
                    Layout.preferredHeight: 105
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    ColumnLayout {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            W.MaterialSymbol {
                                text: "image"
                                iconSize: Appearance.font.pixelSize.normal + 5
                                color: Appearance.colors.colPrimary
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            ConfigSwitch {
                                Layout.fillWidth: false
                                checked: imageCardCard.widgetEnabled
                                onCheckedChanged: {
                                    Config.options.background.widgets.imageCard.enable = checked;
                                }
                            }
                        }
                        W.StyledText {
                            text: Translation.tr("Image card")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                        W.StyledText {
                            text: imageCardCard.widgetEnabled ? Translation.tr("Enabled") : Translation.tr("Disabled")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
                Rectangle {
                    id: stickerCard
                    readonly property bool widgetEnabled: Config.options.background.widgets.sticker.enable
                    Layout.fillWidth: true
                    Layout.preferredHeight: 105
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    ColumnLayout {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            W.MaterialSymbol {
                                text: "sticky_note_2"
                                iconSize: Appearance.font.pixelSize.normal + 5
                                color: Appearance.colors.colPrimary
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            ConfigSwitch {
                                Layout.fillWidth: false
                                checked: stickerCard.widgetEnabled
                                onCheckedChanged: {
                                    Config.options.background.widgets.sticker.enable = checked;
                                }
                            }
                        }
                        W.StyledText {
                            text: Translation.tr("Sticker")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                        W.StyledText {
                            text: stickerCard.widgetEnabled ? Translation.tr("Enabled") : Translation.tr("Disabled")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
                Rectangle {
                    id: imagesCard
                    readonly property bool widgetEnabled: Config.options.background.widgets.images.enable
                    Layout.fillWidth: true
                    Layout.preferredHeight: 105
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    ColumnLayout {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            W.MaterialSymbol {
                                text: "transform"
                                iconSize: Appearance.font.pixelSize.normal + 5
                                color: Appearance.colors.colPrimary
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            ConfigSwitch {
                                Layout.fillWidth: false
                                checked: imagesCard.widgetEnabled
                                onCheckedChanged: {
                                    Config.options.background.widgets.images.enable = checked;
                                }
                            }
                        }
                        W.StyledText {
                            text: Translation.tr("Image converter")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                        W.StyledText {
                            text: imagesCard.widgetEnabled ? Translation.tr("Enabled") : Translation.tr("Disabled")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
                Rectangle {
                    id: mediaCard
                    readonly property bool widgetEnabled: Config.options.background.widgets.media.enable
                    Layout.fillWidth: true
                    Layout.preferredHeight: 105
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    ColumnLayout {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            W.MaterialSymbol {
                                text: "music_note"
                                iconSize: Appearance.font.pixelSize.normal + 5
                                color: Appearance.colors.colPrimary
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            ConfigSwitch {
                                Layout.fillWidth: false
                                checked: mediaCard.widgetEnabled
                                onCheckedChanged: {
                                    Config.options.background.widgets.media.enable = checked;
                                }
                            }
                        }
                        W.StyledText {
                            text: Translation.tr("Media")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                        W.StyledText {
                            text: mediaCard.widgetEnabled ? Translation.tr("Enabled") : Translation.tr("Disabled")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
                Rectangle {
                    id: notesCard
                    readonly property bool widgetEnabled: Config.options.background.widgets.notes.enable
                    Layout.fillWidth: true
                    Layout.preferredHeight: 105
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    ColumnLayout {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            W.MaterialSymbol {
                                text: "sticky_note_2"
                                iconSize: Appearance.font.pixelSize.normal + 5
                                color: Appearance.colors.colPrimary
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            ConfigSwitch {
                                Layout.fillWidth: false
                                checked: notesCard.widgetEnabled
                                onCheckedChanged: {
                                    Config.options.background.widgets.notes.enable = checked;
                                }
                            }
                        }
                        W.StyledText {
                            text: Translation.tr("Notes")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                        W.StyledText {
                            text: notesCard.widgetEnabled ? Translation.tr("Enabled") : Translation.tr("Disabled")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
                Rectangle {
                    id: timersCard
                    readonly property bool widgetEnabled: Config.options.background.widgets.timers.enable
                    Layout.fillWidth: true
                    Layout.preferredHeight: 105
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    ColumnLayout {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            W.MaterialSymbol {
                                text: "timer"
                                iconSize: Appearance.font.pixelSize.normal + 5
                                color: Appearance.colors.colPrimary
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            ConfigSwitch {
                                Layout.fillWidth: false
                                checked: timersCard.widgetEnabled
                                onCheckedChanged: {
                                    Config.options.background.widgets.timers.enable = checked;
                                }
                            }
                        }
                        W.StyledText {
                            text: Translation.tr("Timers")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                        W.StyledText {
                            text: timersCard.widgetEnabled ? Translation.tr("Enabled") : Translation.tr("Disabled")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
                Rectangle {
                    id: todoCard
                    readonly property bool widgetEnabled: Config.options.background.widgets.todo.enable
                    Layout.fillWidth: true
                    Layout.preferredHeight: 105
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    ColumnLayout {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            W.MaterialSymbol {
                                text: "checklist"
                                iconSize: Appearance.font.pixelSize.normal + 5
                                color: Appearance.colors.colPrimary
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            ConfigSwitch {
                                Layout.fillWidth: false
                                checked: todoCard.widgetEnabled
                                onCheckedChanged: {
                                    Config.options.background.widgets.todo.enable = checked;
                                }
                            }
                        }
                        W.StyledText {
                            text: Translation.tr("To-Do")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                        W.StyledText {
                            text: todoCard.widgetEnabled ? Translation.tr("Enabled") : Translation.tr("Disabled")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
                Rectangle {
                    id: userCardCard
                    readonly property bool widgetEnabled: Config.options.background.widgets.userCard.enable
                    Layout.fillWidth: true
                    Layout.preferredHeight: 105
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    ColumnLayout {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            W.MaterialSymbol {
                                text: "badge"
                                iconSize: Appearance.font.pixelSize.normal + 5
                                color: Appearance.colors.colPrimary
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            ConfigSwitch {
                                Layout.fillWidth: false
                                checked: userCardCard.widgetEnabled
                                onCheckedChanged: {
                                    Config.options.background.widgets.userCard.enable = checked;
                                }
                            }
                        }
                        W.StyledText {
                            text: Translation.tr("User card")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                        W.StyledText {
                            text: userCardCard.widgetEnabled ? Translation.tr("Enabled") : Translation.tr("Disabled")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
                Rectangle {
                    id: visualizerCard
                    readonly property bool widgetEnabled: Config.options.background.widgets.visualizer.enable
                    Layout.fillWidth: true
                    Layout.preferredHeight: 105
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    ColumnLayout {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            W.MaterialSymbol {
                                text: "graphic_eq"
                                iconSize: Appearance.font.pixelSize.normal + 5
                                color: Appearance.colors.colPrimary
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            ConfigSwitch {
                                Layout.fillWidth: false
                                checked: visualizerCard.widgetEnabled
                                onCheckedChanged: {
                                    Config.options.background.widgets.visualizer.enable = checked;
                                }
                            }
                        }
                        W.StyledText {
                            text: Translation.tr("Visualizer")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                        W.StyledText {
                            text: visualizerCard.widgetEnabled ? Translation.tr("Enabled") : Translation.tr("Disabled")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
                Rectangle {
                    id: worldClockCard
                    readonly property bool widgetEnabled: Config.options.background.widgets.worldClock.enable
                    Layout.fillWidth: true
                    Layout.preferredHeight: 105
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    ColumnLayout {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            W.MaterialSymbol {
                                text: "public"
                                iconSize: Appearance.font.pixelSize.normal + 5
                                color: Appearance.colors.colPrimary
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            ConfigSwitch {
                                Layout.fillWidth: false
                                checked: worldClockCard.widgetEnabled
                                onCheckedChanged: {
                                    Config.options.background.widgets.worldClock.enable = checked;
                                }
                            }
                        }
                        W.StyledText {
                            text: Translation.tr("World clock")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                        W.StyledText {
                            text: worldClockCard.widgetEnabled ? Translation.tr("Enabled") : Translation.tr("Disabled")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Placement strategy")

                GroupedList {
                    ConfigSelectionArray {
                        text: Translation.tr("Weather")
                        icon: "weather_mix"
                        currentValue: Config.options.background.widgets.weather.placementStrategy
                        onSelected: newValue => {
                            Config.options.background.widgets.weather.placementStrategy = newValue;
                        }
                        options: page.placementOptions
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("Resources")
                        icon: "memory"
                        currentValue: Config.options.background.widgets.resources.placementStrategy
                        onSelected: newValue => {
                            Config.options.background.widgets.resources.placementStrategy = newValue;
                        }
                        options: page.placementOptions
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("Calendar")
                        icon: "calendar_month"
                        currentValue: Config.options.background.widgets.calendar.placementStrategy
                        onSelected: newValue => {
                            Config.options.background.widgets.calendar.placementStrategy = newValue;
                        }
                        options: page.placementOptions
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("Custom text")
                        icon: "text_fields"
                        currentValue: Config.options.background.widgets.customText.placementStrategy
                        onSelected: newValue => {
                            Config.options.background.widgets.customText.placementStrategy = newValue;
                        }
                        options: page.placementOptions
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("Custom image")
                        icon: "sticky_note_2"
                        currentValue: Config.options.background.widgets.customImage.placementStrategy
                        onSelected: newValue => {
                            Config.options.background.widgets.customImage.placementStrategy = newValue;
                        }
                        options: page.placementOptions
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("Image card")
                        icon: "image"
                        currentValue: Config.options.background.widgets.imageCard.placementStrategy
                        onSelected: newValue => {
                            Config.options.background.widgets.imageCard.placementStrategy = newValue;
                        }
                        options: page.placementOptions
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("Sticker")
                        icon: "sticky_note_2"
                        currentValue: Config.options.background.widgets.sticker.placementStrategy
                        onSelected: newValue => {
                            Config.options.background.widgets.sticker.placementStrategy = newValue;
                        }
                        options: page.placementOptions
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("Image converter")
                        icon: "transform"
                        currentValue: Config.options.background.widgets.images.placementStrategy
                        onSelected: newValue => {
                            Config.options.background.widgets.images.placementStrategy = newValue;
                        }
                        options: page.placementOptions
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("Media")
                        icon: "music_note"
                        currentValue: Config.options.background.widgets.media.placementStrategy
                        onSelected: newValue => {
                            Config.options.background.widgets.media.placementStrategy = newValue;
                        }
                        options: page.placementOptions
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("Notes")
                        icon: "sticky_note_2"
                        currentValue: Config.options.background.widgets.notes.placementStrategy
                        onSelected: newValue => {
                            Config.options.background.widgets.notes.placementStrategy = newValue;
                        }
                        options: page.placementOptions
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("Timers")
                        icon: "timer"
                        currentValue: Config.options.background.widgets.timers.placementStrategy
                        onSelected: newValue => {
                            Config.options.background.widgets.timers.placementStrategy = newValue;
                        }
                        options: page.placementOptions
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("To-Do")
                        icon: "checklist"
                        currentValue: Config.options.background.widgets.todo.placementStrategy
                        onSelected: newValue => {
                            Config.options.background.widgets.todo.placementStrategy = newValue;
                        }
                        options: page.placementOptions
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("User card")
                        icon: "badge"
                        currentValue: Config.options.background.widgets.userCard.placementStrategy
                        onSelected: newValue => {
                            Config.options.background.widgets.userCard.placementStrategy = newValue;
                        }
                        options: page.placementOptions
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("Visualizer")
                        icon: "graphic_eq"
                        currentValue: Config.options.background.widgets.visualizer.placementStrategy
                        onSelected: newValue => {
                            Config.options.background.widgets.visualizer.placementStrategy = newValue;
                        }
                        options: page.placementOptions
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("World clock")
                        icon: "public"
                        currentValue: Config.options.background.widgets.worldClock.placementStrategy
                        onSelected: newValue => {
                            Config.options.background.widgets.worldClock.placementStrategy = newValue;
                        }
                        options: page.placementOptions
                    }
                }
            }
        }

        ContentSection {
            icon: "tune"
            shape: W.MaterialShape.Shape.Flower
            title: Translation.tr("Desktop widgets")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "grid_on"
                    text: Translation.tr("Show grid while dragging")
                    checked: Config.options.background.showGrid
                    onCheckedChanged: {
                        Config.options.background.showGrid = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "straighten"
                    text: Translation.tr("Show snap lines")
                    checked: Config.options.background.showSnapLines
                    onCheckedChanged: {
                        Config.options.background.showSnapLines = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "lock"
                    text: Translation.tr("Lock widget positions")
                    checked: Config.options.background.widgetsLocked
                    onCheckedChanged: {
                        Config.options.background.widgetsLocked = checked;
                    }
                }
                ConfigSwitch {
                    visible: !Platform.isWindows
                    buttonIcon: "shadow"
                    text: Translation.tr("Widget shadows")
                    checked: Config.options.background.widgets.shadow
                    onCheckedChanged: {
                        Config.options.background.widgets.shadow = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "lock_person"
                    text: Translation.tr("Show widgets on the lock screen")
                    checked: Config.options.lock.showWidgets
                    onCheckedChanged: {
                        Config.options.lock.showWidgets = checked;
                    }
                }
            }

            Loader {
                Layout.fillWidth: true
                active: !Platform.isWindows
                visible: active
                sourceComponent: GroupedList {
                    ConfigSwitch {
                        buttonIcon: "blur_on"
                        text: Translation.tr("Blur widget backgrounds")
                        checked: Config.options.background.widgets.blurWidgets
                        onCheckedChanged: {
                            Config.options.background.widgets.blurWidgets = checked;
                        }
                    }
                    ConfigSlider {
                        visible: Config.options.background.widgets.blurWidgets
                        text: Translation.tr("Widget blur radius")
                        buttonIcon: "aspect_ratio"
                        usePercentTooltip: false
                        value: Config.options.background.widgets.blurRadius
                        from: 1
                        to: 64
                        stopIndicatorValues: [32]
                        onValueChanged: {
                            Config.options.background.widgets.blurRadius = value;
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "calendar_month"
            shape: W.MaterialShape.Shape.SemiCircle
            title: Translation.tr("Widget: Calendar")

            GroupedList {
                ConfigSelectionArray {
                    text: Translation.tr("Size")
                    icon: "aspect_ratio"
                    currentValue: Config.options.background.widgets.calendar.sizeMode
                    onSelected: newValue => {
                        Config.options.background.widgets.calendar.sizeMode = newValue;
                    }
                    options: [
                        {
                            displayName: "1×1",
                            icon: "crop_square",
                            value: "1x1"
                        },
                        {
                            displayName: "1×2",
                            icon: "crop_landscape",
                            value: "1x2"
                        },
                        {
                            displayName: "2×2",
                            icon: "crop_square",
                            value: "2x2"
                        },
                        {
                            displayName: "2×3",
                            icon: "crop_portrait",
                            value: "2x3"
                        },
                    ]
                }
            }
        }

        ContentSection {
            icon: "text_fields"
            shape: W.MaterialShape.Shape.Diamond
            title: Translation.tr("Widget: Custom text")

            GroupedList {
                ConfigTextArea {
                    Layout.fillWidth: true
                    fieldWidth: 300
                    buttonIcon: "edit"
                    text: Translation.tr("Content")
                    placeholderText: Translation.tr("Content")
                    value: Config.options.background.widgets.customText.content
                    onValueChanged: {
                        Config.options.background.widgets.customText.content = value;
                    }
                }
                ConfigTextArea {
                    Layout.fillWidth: true
                    fieldWidth: 220
                    buttonIcon: "font_download"
                    text: Translation.tr("Font family")
                    placeholderText: Translation.tr("Font family")
                    value: Config.options.background.widgets.customText.fontFamily
                    onValueChanged: {
                        Config.options.background.widgets.customText.fontFamily = value;
                    }
                }
                ConfigSelectionArray {
                    text: Translation.tr("Alignment")
                    icon: "format_align_center"
                    currentValue: Config.options.background.widgets.customText.alignment
                    onSelected: newValue => {
                        Config.options.background.widgets.customText.alignment = newValue;
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "format_align_left",
                            value: "left"
                        },
                        {
                            displayName: "",
                            icon: "format_align_center",
                            value: "center"
                        },
                        {
                            displayName: "",
                            icon: "format_align_right",
                            value: "right"
                        },
                    ]
                }
                ConfigSlider {
                    text: Translation.tr("Font size")
                    buttonIcon: "format_size"
                    usePercentTooltip: false
                    value: Config.options.background.widgets.customText.fontSize
                    from: 12
                    to: 400
                    stopIndicatorValues: [72]
                    onValueChanged: {
                        Config.options.background.widgets.customText.fontSize = value;
                    }
                }
                ConfigSwitch {
                    visible: !Platform.isWindows
                    buttonIcon: "shadow"
                    text: Translation.tr("Shadow")
                    checked: Config.options.background.widgets.customText.shadow
                    onCheckedChanged: {
                        Config.options.background.widgets.customText.shadow = checked;
                    }
                }
            }
        }

        ContentSection {
            icon: "sticky_note_2"
            shape: W.MaterialShape.Shape.ClamShell
            title: Translation.tr("Widget: Custom image")

            GroupedList {
                ConfigTextArea {
                    Layout.fillWidth: true
                    fieldWidth: 300
                    buttonIcon: "folder_open"
                    text: Translation.tr("Image path")
                    placeholderText: Translation.tr("Or drop an image on the widget")
                    value: Config.options.background.widgets.customImage.path
                    onValueChanged: {
                        Config.options.background.widgets.customImage.path = value;
                    }
                }
                ConfigSelectionArray {
                    text: Translation.tr("Shape")
                    icon: "category"
                    currentValue: Config.options.background.widgets.customImage.shape
                    onSelected: newValue => {
                        Config.options.background.widgets.customImage.shape = newValue;
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "circle",
                            value: "Circle"
                        },
                        {
                            displayName: "",
                            icon: "square",
                            value: "Square"
                        },
                        {
                            displayName: "",
                            icon: "cookie",
                            value: "Cookie4Sided"
                        },
                        {
                            displayName: "",
                            icon: "cookie",
                            value: "Cookie7Sided"
                        },
                        {
                            displayName: "",
                            icon: "bubble_chart",
                            value: "Oval"
                        },
                        {
                            displayName: "",
                            icon: "favorite",
                            value: "Heart"
                        },
                    ]
                }
                ConfigSlider {
                    text: Translation.tr("Size")
                    buttonIcon: "aspect_ratio"
                    usePercentTooltip: false
                    value: Config.options.background.widgets.customImage.size
                    from: 80
                    to: 500
                    stopIndicatorValues: [200]
                    onValueChanged: {
                        Config.options.background.widgets.customImage.size = value;
                    }
                }
            }
        }

        ContentSection {
            icon: "image"
            shape: W.MaterialShape.Shape.Boom
            title: Translation.tr("Widget: Image card")

            GroupedList {
                ConfigTextArea {
                    Layout.fillWidth: true
                    fieldWidth: 300
                    buttonIcon: "folder_open"
                    text: Translation.tr("Image path")
                    placeholderText: Translation.tr("Or drop an image on the widget")
                    value: Config.options.background.widgets.imageCard.path
                    onValueChanged: {
                        Config.options.background.widgets.imageCard.path = value;
                    }
                }
                ConfigSelectionArray {
                    text: Translation.tr("Size")
                    icon: "aspect_ratio"
                    currentValue: Config.options.background.widgets.imageCard.sizeMode
                    onSelected: newValue => {
                        Config.options.background.widgets.imageCard.sizeMode = newValue;
                    }
                    options: [
                        {
                            displayName: "1×1",
                            icon: "crop_square",
                            value: "1x1"
                        },
                        {
                            displayName: "1×2",
                            icon: "crop_landscape",
                            value: "1x2"
                        },
                        {
                            displayName: "2×2",
                            icon: "crop_square",
                            value: "2x2"
                        },
                        {
                            displayName: "2×3",
                            icon: "crop_portrait",
                            value: "2x3"
                        },
                    ]
                }
            }
        }

        ContentSection {
            icon: "sticky_note_2"
            shape: W.MaterialShape.Shape.Puffy
            title: Translation.tr("Widget: Sticker")

            GroupedList {
                ConfigTextArea {
                    Layout.fillWidth: true
                    fieldWidth: 300
                    buttonIcon: "folder_open"
                    text: Translation.tr("Image path")
                    placeholderText: Translation.tr("Or drop an image on the widget")
                    value: Config.options.background.widgets.sticker.path
                    onValueChanged: {
                        Config.options.background.widgets.sticker.path = value;
                    }
                }
                ConfigSlider {
                    text: Translation.tr("Size")
                    buttonIcon: "aspect_ratio"
                    usePercentTooltip: false
                    value: Config.options.background.widgets.sticker.size
                    from: 60
                    to: 500
                    stopIndicatorValues: [200]
                    onValueChanged: {
                        Config.options.background.widgets.sticker.size = value;
                    }
                }
                ConfigSlider {
                    text: Translation.tr("Outline width")
                    buttonIcon: "line_weight"
                    usePercentTooltip: false
                    value: Config.options.background.widgets.sticker.outlineWidth
                    from: 0
                    to: 24
                    stopIndicatorValues: [8]
                    onValueChanged: {
                        Config.options.background.widgets.sticker.outlineWidth = value;
                    }
                }
                ConfigTextArea {
                    Layout.fillWidth: true
                    fieldWidth: 160
                    buttonIcon: "format_color_fill"
                    text: Translation.tr("Outline color")
                    placeholderText: "#ffffff"
                    value: Config.options.background.widgets.sticker.outlineColor
                    onValueChanged: {
                        Config.options.background.widgets.sticker.outlineColor = value;
                    }
                }
            }
        }

        ContentSection {
            icon: "transform"
            shape: W.MaterialShape.Shape.SoftBoom
            title: Translation.tr("Widget: Image converter")

            GroupedList {
                W.StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: Translation.tr("Drop images on the widget to convert them. Needs ffmpeg (and ImageMagick for PDF) on PATH.")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }
        }

        ContentSection {
            icon: "music_note"
            shape: W.MaterialShape.Shape.Burst
            title: Translation.tr("Widget: Media")

            GroupedList {
                ConfigSelectionArray {
                    text: Translation.tr("Size")
                    icon: "aspect_ratio"
                    currentValue: Config.options.background.widgets.media.sizeMode
                    onSelected: newValue => {
                        Config.options.background.widgets.media.sizeMode = newValue;
                    }
                    options: [
                        {
                            displayName: "1×1",
                            icon: "crop_square",
                            value: "1x1"
                        },
                        {
                            displayName: "1×2",
                            icon: "crop_landscape",
                            value: "1x2"
                        },
                        {
                            displayName: "2×2",
                            icon: "crop_square",
                            value: "2x2"
                        },
                        {
                            displayName: "1×3",
                            icon: "crop_landscape",
                            value: "1x3"
                        },
                    ]
                }
            }
        }

        ContentSection {
            icon: "timer"
            shape: W.MaterialShape.Shape.SoftBurst
            title: Translation.tr("Widget: Timers")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "swap_horiz"
                    text: Translation.tr("Stack vertically")
                    checked: Config.options.background.widgets.timers.vertical
                    onCheckedChanged: {
                        Config.options.background.widgets.timers.vertical = checked;
                    }
                }
            }
        }

        ContentSection {
            icon: "badge"
            shape: W.MaterialShape.Shape.Gem
            title: Translation.tr("Widget: User card")

            GroupedList {
                ConfigSelectionArray {
                    text: Translation.tr("Size")
                    icon: "aspect_ratio"
                    currentValue: Config.options.background.widgets.userCard.sizeMode
                    onSelected: newValue => {
                        Config.options.background.widgets.userCard.sizeMode = newValue;
                    }
                    options: [
                        {
                            displayName: "1×1",
                            icon: "crop_square",
                            value: "1x1"
                        },
                        {
                            displayName: "1×2",
                            icon: "crop_landscape",
                            value: "1x2"
                        },
                        {
                            displayName: "2×2",
                            icon: "crop_square",
                            value: "2x2"
                        },
                        {
                            displayName: "2×3",
                            icon: "crop_portrait",
                            value: "2x3"
                        },
                    ]
                }
            }
        }

        ContentSection {
            icon: "graphic_eq"
            shape: W.MaterialShape.Shape.Sunny
            title: Translation.tr("Widget: Visualizer")

            GroupedList {
                ConfigSelectionArray {
                    text: Translation.tr("Style")
                    icon: "bar_chart"
                    currentValue: Config.options.background.widgets.visualizer.style
                    onSelected: newValue => {
                        Config.options.background.widgets.visualizer.style = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Bars"),
                            icon: "bar_chart",
                            value: "bars"
                        },
                        {
                            displayName: Translation.tr("Mirror"),
                            icon: "flip",
                            value: "mirror"
                        },
                        {
                            displayName: Translation.tr("Aurora"),
                            icon: "gradient",
                            value: "aurora"
                        },
                        {
                            displayName: Translation.tr("Ring"),
                            icon: "data_usage",
                            value: "ring"
                        },
                        {
                            displayName: Translation.tr("Dots"),
                            icon: "grain",
                            value: "dots"
                        },
                    ]
                }
                ConfigSelectionArray {
                    text: Translation.tr("Color")
                    icon: "palette"
                    currentValue: Config.options.background.widgets.visualizer.colorSource
                    onSelected: newValue => {
                        Config.options.background.widgets.visualizer.colorSource = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Theme"),
                            icon: "palette",
                            value: "theme"
                        },
                        {
                            displayName: Translation.tr("Album cover"),
                            icon: "album",
                            value: "cover"
                        },
                    ]
                }
                ConfigSlider {
                    text: Translation.tr("Sensitivity")
                    buttonIcon: "tune"
                    usePercentTooltip: false
                    value: Config.options.background.widgets.visualizer.sensitivity * 100
                    from: 10
                    to: 300
                    stopIndicatorValues: [100]
                    onValueChanged: {
                        Config.options.background.widgets.visualizer.sensitivity = value / 100;
                    }
                }
                W.StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: Translation.tr("Only the Bars style is implemented on Windows so far; the others fall back to it.")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }
        }

        ContentSection {
            icon: "public"
            shape: W.MaterialShape.Shape.PuffyDiamond
            title: Translation.tr("Widget: World clock")

            GroupedList {
                ConfigSelectionArray {
                    text: Translation.tr("Size")
                    icon: "aspect_ratio"
                    currentValue: Config.options.background.widgets.worldClock.sizeMode
                    onSelected: newValue => {
                        Config.options.background.widgets.worldClock.sizeMode = newValue;
                    }
                    options: [
                        {
                            displayName: "2×2",
                            icon: "crop_square",
                            value: "2x2"
                        },
                        {
                            displayName: "4×1",
                            icon: "view_column",
                            value: "4x1"
                        },
                    ]
                }
                ConfigSwitch {
                    buttonIcon: "swap_horiz"
                    text: Translation.tr("Stack vertically")
                    checked: Config.options.background.widgets.worldClock.vertical
                    onCheckedChanged: {
                        Config.options.background.widgets.worldClock.vertical = checked;
                    }
                }
                ConfigSpinBox {
                    icon: "numbers"
                    text: Translation.tr("Clocks shown")
                    value: Config.options.background.widgets.worldClock.clockCount
                    from: 1
                    to: 4
                    stepSize: 1
                    onValueChanged: {
                        Config.options.background.widgets.worldClock.clockCount = value;
                    }
                }
                W.StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: Translation.tr("Pick the actual time zones from the widget's own settings flip (the gear icon on the widget).")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }
}

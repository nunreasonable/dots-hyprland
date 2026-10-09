import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "tune"
        title: Translation.tr("General")

        ConfigSwitch {
            buttonIcon: "fullscreen"
            text: Translation.tr("Hide when fullscreen")
            checked: Config.options.background.hideWhenFullscreen
            onCheckedChanged: {
                Config.options.background.hideWhenFullscreen = checked;
            }
            StyledToolTip {
                text: Translation.tr("Hides the wallpaper and its widgets while a window on that monitor is fullscreen.")
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            active: !Platform.isWindows
            visible: active
            sourceComponent: ConfigSlider {
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

    ContentSection {
        icon: "widgets"
        title: Translation.tr("Desktop widgets")

        ConfigRow {
            uniform: true
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
        }

        ConfigRow {
            uniform: true
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
        }

        ConfigSwitch {
            buttonIcon: "lock_person"
            text: Translation.tr("Show widgets on the lock screen")
            checked: Config.options.lock.showWidgets
            onCheckedChanged: {
                Config.options.lock.showWidgets = checked;
            }
        }

        ConfigSwitch {
            visible: !Platform.isWindows
            buttonIcon: "blur_on"
            text: Translation.tr("Blur widget backgrounds")
            checked: Config.options.background.widgets.blurWidgets
            onCheckedChanged: {
                Config.options.background.widgets.blurWidgets = checked;
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            active: !Platform.isWindows && Config.options.background.widgets.blurWidgets
            visible: active
            sourceComponent: ConfigSlider {
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

    ContentSection {
        visible: Platform.isWindows
        icon: "desktop_windows"
        title: Translation.tr("Windows desktop")

        ConfigSwitch {
            buttonIcon: "wallpaper"
            text: Translation.tr("Put the background behind the desktop icons")
            checked: Config.options.windowsPort.backgroundBehindIcons
            onCheckedChanged: {
                Config.options.windowsPort.backgroundBehindIcons = checked;
            }
            StyledToolTip {
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
            StyledToolTip {
                text: Translation.tr("Off: Windows draws the wallpaper, which ii keeps the same as the one you pick, and only ii's widgets go on the desktop. Changing the wallpaper in Windows' settings changes ii's too.\nOn: ii draws its own wallpaper over Windows' one, with parallax between workspaces.")
            }
        }
    }

    ContentSection {
        icon: "sync_alt"
        title: Translation.tr("Parallax")

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
            StyledToolTip {
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

    ContentSection {
        id: settingsClock
        icon: "clock_loader_40"
        title: Translation.tr("Widget: Clock")

        function stylePresent(styleName) {
            if (!Config.options.background.widgets.clock.showOnlyWhenLocked && Config.options.background.widgets.clock.style === styleName) {
                return true;
            }
            if (Config.options.background.widgets.clock.styleLocked === styleName) {
                return true;
            }
            return false;
        }

        readonly property bool digitalPresent: stylePresent("digital")
        readonly property bool cookiePresent: stylePresent("cookie")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.clock.enable
                onCheckedChanged: {
                    Config.options.background.widgets.clock.enable = checked;
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.clock.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.clock.placementStrategy = newValue;
                }
                options: [
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

        ConfigRow {
            ContentSubsection {
                visible: !Config.options.background.widgets.clock.showOnlyWhenLocked
                title: Translation.tr("Clock style")
                Layout.fillWidth: true
                ConfigSelectionArray {
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
            }

            ContentSubsection {
                title: Translation.tr("Clock style (locked)")
                Layout.fillWidth: false
                ConfigSelectionArray {
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
        }

        Loader {
            Layout.fillWidth: true
            Layout.topMargin: 4
            active: settingsClock.digitalPresent
            visible: active
            sourceComponent: ContentSubsection {
                title: Translation.tr("Digital clock settings")
                tooltip: Translation.tr("Font width and roundness settings are only available for some fonts like Google Sans Flex")

                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "vertical_distribute"
                        text: Translation.tr("Vertical")
                        checked: Config.options.background.widgets.clock.digital.vertical
                        onCheckedChanged: {
                            Config.options.background.widgets.clock.digital.vertical = checked;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "animation"
                        text: Translation.tr("Animate time change")
                        checked: Config.options.background.widgets.clock.digital.animateChange
                        onCheckedChanged: {
                            Config.options.background.widgets.clock.digital.animateChange = checked;
                        }
                    }
                }

                ConfigRow {
                    uniform: true

                    ConfigSwitch {
                        buttonIcon: "date_range"
                        text: Translation.tr("Show date")
                        checked: Config.options.background.widgets.clock.digital.showDate
                        onCheckedChanged: {
                            Config.options.background.widgets.clock.digital.showDate = checked;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "activity_zone"
                        text: Translation.tr("Use adaptive alignment")
                        checked: Config.options.background.widgets.clock.digital.adaptiveAlignment
                        onCheckedChanged: {
                            Config.options.background.widgets.clock.digital.adaptiveAlignment = checked;
                        }
                        StyledToolTip {
                            text: Translation.tr("Aligns the date and quote to left, center or right depending on its position on the screen.")
                        }
                    }
                }

                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Font family")
                    text: Config.options.background.widgets.clock.digital.font.family
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.background.widgets.clock.digital.font.family = text;
                    }
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

        Loader {
            Layout.fillWidth: true
            active: settingsClock.cookiePresent
            visible: active
            sourceComponent: ColumnLayout {
                spacing: 4

                ContentSubsection {
                    title: Translation.tr("Cookie clock settings")

                    ConfigSwitch {
                        buttonIcon: "wand_stars"
                        text: Translation.tr("Auto styling with Gemini")
                        checked: Config.options.background.widgets.clock.cookie.aiStyling
                        onCheckedChanged: {
                            Config.options.background.widgets.clock.cookie.aiStyling = checked;
                        }
                        StyledToolTip {
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
                        StyledToolTip {
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
                        StyledToolTip {
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
                            StyledToolTip {
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
                            StyledToolTip {
                                text: Translation.tr("Can't be turned on when using 'Numbers' dial style for aesthetic reasons")
                            }
                        }
                    }
                }

                ContentSubsection {
                    title: Translation.tr("Dial style")
                    ConfigSelectionArray {
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
                }

                ContentSubsection {
                    title: Translation.tr("Hour hand")
                    ConfigSelectionArray {
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
                }

                ContentSubsection {
                    title: Translation.tr("Minute hand")

                    ConfigSelectionArray {
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
                }

                ContentSubsection {
                    title: Translation.tr("Second hand")

                    ConfigSelectionArray {
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
                }

                ContentSubsection {
                    title: Translation.tr("Date style")

                    ConfigSelectionArray {
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

            ConfigSwitch {
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.clock.quote.enable
                onCheckedChanged: {
                    Config.options.background.widgets.clock.quote.enable = checked;
                }
            }
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Quote")
                text: Config.options.background.widgets.clock.quote.text
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.background.widgets.clock.quote.text = text;
                }
            }
        }
    }

    ContentSection {
        icon: "weather_mix"
        title: Translation.tr("Widget: Weather")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.weather.enable
                onCheckedChanged: {
                    Config.options.background.widgets.weather.enable = checked;
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.weather.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.weather.placementStrategy = newValue;
                }
                options: [
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
            }
        }
    }

    ContentSection {
        icon: "monitor_heart"
        title: Translation.tr("Widget: Resources")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.resources.enable
                onCheckedChanged: {
                    Config.options.background.widgets.resources.enable = checked;
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.resources.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.resources.placementStrategy = newValue;
                }
                options: [
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
            }
        }
    }


    ContentSection {
        icon: "calendar_month"
        title: Translation.tr("Widget: Calendar")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.calendar.enable
                onCheckedChanged: {
                    Config.options.background.widgets.calendar.enable = checked;
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.calendar.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.calendar.placementStrategy = newValue;
                }
                options: [
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
            }
        }

        ConfigSelectionArray {
            text: Translation.tr("Size")
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

    ContentSection {
        icon: "text_fields"
        title: Translation.tr("Widget: Custom text")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.customText.enable
                onCheckedChanged: {
                    Config.options.background.widgets.customText.enable = checked;
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.customText.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.customText.placementStrategy = newValue;
                }
                options: [
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
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Content")
            text: Config.options.background.widgets.customText.content
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.background.widgets.customText.content = text;
            }
        }

        ConfigRow {
            uniform: true
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Font family")
                text: Config.options.background.widgets.customText.fontFamily
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.background.widgets.customText.fontFamily = text;
                }
            }
            ConfigSelectionArray {
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

    ContentSection {
        icon: "sticky_note_2"
        title: Translation.tr("Widget: Custom image")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.customImage.enable
                onCheckedChanged: {
                    Config.options.background.widgets.customImage.enable = checked;
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.customImage.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.customImage.placementStrategy = newValue;
                }
                options: [
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
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Image path (or drop an image on the widget)")
            text: Config.options.background.widgets.customImage.path
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.background.widgets.customImage.path = text;
            }
        }

        ConfigSelectionArray {
            text: Translation.tr("Shape")
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

    ContentSection {
        icon: "image"
        title: Translation.tr("Widget: Image card")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.imageCard.enable
                onCheckedChanged: {
                    Config.options.background.widgets.imageCard.enable = checked;
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.imageCard.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.imageCard.placementStrategy = newValue;
                }
                options: [
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
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Image path (or drop an image on the widget)")
            text: Config.options.background.widgets.imageCard.path
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.background.widgets.imageCard.path = text;
            }
        }

        ConfigSelectionArray {
            text: Translation.tr("Size")
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

    ContentSection {
        icon: "sticky_note_2"
        title: Translation.tr("Widget: Sticker")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.sticker.enable
                onCheckedChanged: {
                    Config.options.background.widgets.sticker.enable = checked;
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.sticker.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.sticker.placementStrategy = newValue;
                }
                options: [
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
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Image path (or drop an image on the widget)")
            text: Config.options.background.widgets.sticker.path
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.background.widgets.sticker.path = text;
            }
        }

        ConfigRow {
            uniform: true
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
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Outline color (e.g. #ffffff)")
            text: Config.options.background.widgets.sticker.outlineColor
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.background.widgets.sticker.outlineColor = text;
            }
        }
    }

    ContentSection {
        icon: "transform"
        title: Translation.tr("Widget: Image converter")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.images.enable
                onCheckedChanged: {
                    Config.options.background.widgets.images.enable = checked;
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.images.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.images.placementStrategy = newValue;
                }
                options: [
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
            }
        }

        StyledToolTip {
            text: Translation.tr("Drop images on the widget to convert them. Needs ffmpeg (and ImageMagick for PDF) on PATH.")
        }
    }

    ContentSection {
        icon: "music_note"
        title: Translation.tr("Widget: Media")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.media.enable
                onCheckedChanged: {
                    Config.options.background.widgets.media.enable = checked;
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.media.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.media.placementStrategy = newValue;
                }
                options: [
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
            }
        }

        ConfigSelectionArray {
            text: Translation.tr("Size")
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

    ContentSection {
        icon: "sticky_note_2"
        title: Translation.tr("Widget: Notes")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.notes.enable
                onCheckedChanged: {
                    Config.options.background.widgets.notes.enable = checked;
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.notes.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.notes.placementStrategy = newValue;
                }
                options: [
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
            }
        }
    }

    ContentSection {
        icon: "timer"
        title: Translation.tr("Widget: Timers")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.timers.enable
                onCheckedChanged: {
                    Config.options.background.widgets.timers.enable = checked;
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.timers.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.timers.placementStrategy = newValue;
                }
                options: [
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
            }
        }

        ConfigSwitch {
            buttonIcon: "swap_horiz"
            text: Translation.tr("Stack vertically")
            checked: Config.options.background.widgets.timers.vertical
            onCheckedChanged: {
                Config.options.background.widgets.timers.vertical = checked;
            }
        }
    }

    ContentSection {
        icon: "checklist"
        title: Translation.tr("Widget: To-Do")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.todo.enable
                onCheckedChanged: {
                    Config.options.background.widgets.todo.enable = checked;
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.todo.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.todo.placementStrategy = newValue;
                }
                options: [
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
            }
        }
    }

    ContentSection {
        icon: "badge"
        title: Translation.tr("Widget: User card")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.userCard.enable
                onCheckedChanged: {
                    Config.options.background.widgets.userCard.enable = checked;
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.userCard.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.userCard.placementStrategy = newValue;
                }
                options: [
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
            }
        }

        ConfigSelectionArray {
            text: Translation.tr("Size")
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

    ContentSection {
        icon: "graphic_eq"
        title: Translation.tr("Widget: Visualizer")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.visualizer.enable
                onCheckedChanged: {
                    Config.options.background.widgets.visualizer.enable = checked;
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.visualizer.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.visualizer.placementStrategy = newValue;
                }
                options: [
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
            }
        }

        ConfigRow {
            uniform: true
            ConfigSelectionArray {
                text: Translation.tr("Style")
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
        }
        StyledToolTip {
            text: Translation.tr("Only the Bars style is implemented on Windows so far; the others fall back to it.")
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
    }

    ContentSection {
        icon: "public"
        title: Translation.tr("Widget: World clock")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.worldClock.enable
                onCheckedChanged: {
                    Config.options.background.widgets.worldClock.enable = checked;
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.worldClock.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.worldClock.placementStrategy = newValue;
                }
                options: [
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
            }
        }

        ConfigRow {
            uniform: true
            ConfigSelectionArray {
                text: Translation.tr("Size")
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
        StyledToolTip {
            text: Translation.tr("Pick the actual time zones from the widget's own settings flip (the gear icon on the widget).")
        }
    }
}

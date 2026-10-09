import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets as W
import qs.modules.settingsPc.widgets

ContentPage {
    id: page
    forceWidth: true

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            icon: "view_quilt"
            shape: W.MaterialShape.Shape.Cookie9Sided
            title: Translation.tr("Panel style")

            GroupedList {
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
        }

        ContentSection {
            icon: "motion_mode"
            shape: W.MaterialShape.Shape.Cookie6Sided
            title: Translation.tr("Transparency")
            hint: Translation.tr("The values below are ignored while Automatic is on")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.appearance.transparency.enable
                    onCheckedChanged: { Config.options.appearance.transparency.enable = checked }
                }
                ConfigSwitch {
                    buttonIcon: "auto_fix_high"
                    text: Translation.tr("Automatic")
                    checked: Config.options.appearance.transparency.automatic
                    onCheckedChanged: { Config.options.appearance.transparency.automatic = checked }
                    W.StyledToolTip {
                        text: Translation.tr("Derives transparency from your wallpaper instead of the sliders below")
                    }
                }
                ConfigSlider {
                    buttonIcon: "wallpaper"
                    text: Translation.tr("Background")
                    enabled: !Config.options.appearance.transparency.automatic
                    from: 0; to: 1
                    stopIndicatorValues: [0.11]
                    value: Config.options.appearance.transparency.backgroundTransparency
                    onValueChanged: {
                        Config.options.appearance.transparency.backgroundTransparency = value
                    }
                }
                ConfigSlider {
                    buttonIcon: "widgets"
                    text: Translation.tr("Panel content")
                    enabled: !Config.options.appearance.transparency.automatic
                    from: 0; to: 1
                    stopIndicatorValues: [0.57]
                    value: Config.options.appearance.transparency.contentTransparency
                    onValueChanged: {
                        Config.options.appearance.transparency.contentTransparency = value
                    }
                }
            }
        }

        ContentSection {
            icon: "splitscreen_left"
            shape: W.MaterialShape.Shape.Clover4Leaf
            title: Translation.tr("Left Sidebar")

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                uniformCellSizes: true

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: aiCol.implicitHeight + 24
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1

                    ColumnLayout {
                        id: aiCol
                        anchors { fill: parent; margins: 12 }
                        spacing: 8

                        W.MaterialSymbol {
                            text: "smart_toy"
                            iconSize: Appearance.font.pixelSize.huge
                            color: Appearance.colors.colPrimary
                        }
                        W.StyledText {
                            text: Translation.tr("AI")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        ConfigSelectionArray {
                            Layout.fillWidth: false
                            Layout.alignment: Qt.AlignRight
                            currentValue: Config.options.policies.ai
                            onSelected: newValue => { Config.options.policies.ai = newValue }
                            options: [
                                { displayName: Translation.tr("No"), icon: "close", value: 0 },
                                { displayName: Translation.tr("Yes"), icon: "check", value: 1 },
                                { displayName: Translation.tr("Local only"), icon: "sync_saved_locally", value: 2 }
                            ]
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: weebCol.implicitHeight + 24
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1

                    ColumnLayout {
                        id: weebCol
                        anchors { fill: parent; margins: 12 }
                        spacing: 8

                        W.MaterialSymbol {
                            text: "playing_cards"
                            iconSize: Appearance.font.pixelSize.huge
                            color: Appearance.colors.colPrimary
                        }
                        W.StyledText {
                            text: Translation.tr("Weeb")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        ConfigSelectionArray {
                            Layout.fillWidth: false
                            Layout.alignment: Qt.AlignRight
                            currentValue: Config.options.policies.weeb
                            onSelected: newValue => { Config.options.policies.weeb = newValue }
                            options: [
                                { displayName: Translation.tr("No"), icon: "close", value: 0 },
                                { displayName: Translation.tr("Yes"), icon: "check", value: 1 },
                                { displayName: Translation.tr("Closet"), icon: "ev_shadow", value: 2 }
                            ]
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 4
                implicitHeight: translatorCol.implicitHeight + 24
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: translatorCol
                    anchors { fill: parent; margins: 12 }
                    spacing: 8

                    ConfigSwitch {
                        buttonIcon: "translate"
                        text: Translation.tr("Enable translator")
                        checked: Config.options.sidebar.translator.enable
                        onCheckedChanged: { Config.options.sidebar.translator.enable = checked }
                    }
                }
            }
        }

        ContentSection {
            icon: "splitscreen_right"
            shape: W.MaterialShape.Shape.Slanted
            title: Translation.tr("Right Sidebar")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "memory"
                    text: Translation.tr("Keep right sidebar loaded")
                    checked: Config.options.sidebar.keepRightSidebarLoaded
                    onCheckedChanged: {
                        Config.options.sidebar.keepRightSidebarLoaded = checked;
                    }
                    W.StyledToolTip {
                        text: Translation.tr("When enabled keeps the content of the right sidebar loaded to reduce the delay when opening,\nat the cost of around 15MB of consistent RAM usage. Delay significance depends on your system's performance.\nUsing a custom kernel like linux-cachyos might help")
                    }
                }
                ConfigSwitch {
                    buttonIcon: "wallpaper"
                    text: Translation.tr("Show banner")
                    checked: Config.options.sidebar.banner
                    onCheckedChanged: {
                        Config.options.sidebar.banner = checked;
                    }
                    W.StyledToolTip {
                        text: Translation.tr("Shows a banner image at the top of the right sidebar.\nDrag an image onto it to set it, right-click to reset")
                    }
                }
                ConfigSwitch {
                    buttonIcon: "calendar_month"
                    text: Translation.tr("Show bottom group")
                    checked: Config.options.sidebar.bottomGroup
                    onCheckedChanged: {
                        Config.options.sidebar.bottomGroup = checked;
                    }
                    W.StyledToolTip {
                        text: Translation.tr("Calendar, to-do list and timer at the bottom of the right sidebar")
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Media player")
                GroupedList {
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
                    ConfigSwitch {
                        buttonIcon: "shapes"
                        text: Translation.tr("Shaped art")
                        enabled: Config.options.sidebar.mediaPlayer && Config.options.sidebar.media.enable
                        checked: Config.options.sidebar.media.shapeArt
                        onCheckedChanged: {
                            Config.options.sidebar.media.shapeArt = checked;
                        }
                    }
                    ConfigComboBox {
                        Layout.fillWidth: true
                        buttonIcon: "category"
                        text: Translation.tr("Art shape")
                        enabled: Config.options.sidebar.mediaPlayer && Config.options.sidebar.media.enable && Config.options.sidebar.media.shapeArt
                        fieldWidth: 200
                        fixedWidth: true
                        model: GlobalStates.centeredShapeOptions.map(shape => ({ displayName: shape, value: shape }))
                        currentValue: Config.options.sidebar.media.artShape
                        onSelected: newValue => { Config.options.sidebar.media.artShape = newValue }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Quick toggles")
                GroupedList {
                    ConfigSelectionArray {
                        text: Translation.tr("Style")
                        icon: "toggle_on"
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
            }

            ContentSubsection {
                title: Translation.tr("Sliders")
                GroupedList {
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
            }
        }

        ContentSection {
            icon: "screenshot_frame_2"
            shape: W.MaterialShape.Shape.Gem
            title: Translation.tr("Hot Corners")
            hint: Translation.tr("Allows you to open sidebars by clicking or hovering screen corners regardless of bar position")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.sidebar.cornerOpen.enable
                    onCheckedChanged: { Config.options.sidebar.cornerOpen.enable = checked }
                }
                ConfigSwitch {
                    buttonIcon: "highlight_mouse_cursor"
                    text: Translation.tr("Hover to trigger")
                    checked: Config.options.sidebar.cornerOpen.clickless
                    onCheckedChanged: { Config.options.sidebar.cornerOpen.clickless = checked }
                    W.StyledToolTip {
                        text: Translation.tr("When this is off you'll have to click")
                    }
                }
                ConfigSwitch {
                    enabled: !Config.options.sidebar.cornerOpen.clickless
                    buttonIcon: "ads_click"
                    text: Translation.tr("Force hover open at absolute corner")
                    checked: Config.options.sidebar.cornerOpen.clicklessCornerEnd
                    onCheckedChanged: { Config.options.sidebar.cornerOpen.clicklessCornerEnd = checked }
                    W.StyledToolTip {
                        text: Translation.tr("When the previous option is off and this is on,\nyou can still hover the corner's end to open sidebar,\nand the remaining area can be used for volume/brightness scroll")
                    }
                }
                ConfigSpinBox {
                    icon: "arrow_cool_down"
                    text: Translation.tr("Vertical offset")
                    value: Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset
                    from: 0; to: 20; stepSize: 1
                    onValueChanged: { Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset = value }
                    W.StyledToolTip {
                        text: Translation.tr("Why this is cool:\nFor non-0 values, it won't trigger when you reach the\nscreen corner along the horizontal edge, but it will when\nyou do along the vertical edge")
                    }
                }
                ConfigSwitch {
                    buttonIcon: "vertical_align_bottom"
                    text: Translation.tr("Place at bottom")
                    checked: Config.options.sidebar.cornerOpen.bottom
                    onCheckedChanged: { Config.options.sidebar.cornerOpen.bottom = checked }
                    W.StyledToolTip {
                        text: Translation.tr("Place the corners to trigger at the bottom")
                    }
                }
                ConfigSwitch {
                    buttonIcon: "unfold_more_double"
                    text: Translation.tr("Value scroll")
                    checked: Config.options.sidebar.cornerOpen.valueScroll
                    onCheckedChanged: { Config.options.sidebar.cornerOpen.valueScroll = checked }
                    W.StyledToolTip {
                        text: Translation.tr("Brightness and volume")
                    }
                }
                ConfigSwitch {
                    buttonIcon: "visibility"
                    text: Translation.tr("Visualize region")
                    checked: Config.options.sidebar.cornerOpen.visualize
                    onCheckedChanged: { Config.options.sidebar.cornerOpen.visualize = checked }
                }
                ConfigSpinBox {
                    icon: "arrow_range"
                    text: Translation.tr("Region width")
                    value: Config.options.sidebar.cornerOpen.cornerRegionWidth
                    from: 1; to: 300; stepSize: 1
                    onValueChanged: { Config.options.sidebar.cornerOpen.cornerRegionWidth = value }
                }
                ConfigSpinBox {
                    icon: "height"
                    text: Translation.tr("Region height")
                    value: Config.options.sidebar.cornerOpen.cornerRegionHeight
                    from: 1; to: 300; stepSize: 1
                    onValueChanged: { Config.options.sidebar.cornerOpen.cornerRegionHeight = value }
                }
                ConfigComboBox {
                    Layout.fillWidth: true
                    buttonIcon: "first_page"
                    text: Translation.tr("Bottom-left corner")
                    fieldWidth: 200
                    fixedWidth: true
                    model: GlobalStates.hotCornerOptions
                    currentValue: Config.options.sidebar.cornerOpen.bottomLeftAction
                    onSelected: newValue => { Config.options.sidebar.cornerOpen.bottomLeftAction = newValue }
                }
                ConfigComboBox {
                    Layout.fillWidth: true
                    buttonIcon: "last_page"
                    text: Translation.tr("Bottom-right corner")
                    fieldWidth: 200
                    fixedWidth: true
                    model: GlobalStates.hotCornerOptions
                    currentValue: Config.options.sidebar.cornerOpen.bottomRightAction
                    onSelected: newValue => { Config.options.sidebar.cornerOpen.bottomRightAction = newValue }
                }
            }
        }

        ContentSection {
            icon: "overview_key"
            shape: W.MaterialShape.Shape.Gem
            title: Translation.tr("Overview")

            GroupedList {
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
                    Layout.alignment: Qt.AlignHCenter
                    ConfigSelectionArray {
                        Layout.alignment: Qt.AlignHCenter
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
                    Layout.alignment: Qt.AlignHCenter
                    enabled: Config.options.overview.style !== "niri"
                    opacity: enabled ? 1 : 0.4
                    ConfigSelectionArray {
                        Layout.alignment: Qt.AlignHCenter
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
                        Layout.alignment: Qt.AlignHCenter
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
        }

        ContentSection {
            icon: "call_to_action"
            title: Translation.tr("Dock")
            shape: W.MaterialShape.Shape.Cookie6Sided

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.dock.enable
                    onCheckedChanged: { Config.options.dock.enable = checked }
                }
                ConfigSwitch {
                    buttonIcon: "highlight_mouse_cursor"
                    text: Translation.tr("Hover to reveal")
                    checked: Config.options.dock.hoverToReveal
                    onCheckedChanged: { Config.options.dock.hoverToReveal = checked }
                }
                ConfigSwitch {
                    buttonIcon: "keep"
                    text: Translation.tr("Pinned on startup")
                    checked: Config.options.dock.pinnedOnStartup
                    onCheckedChanged: { Config.options.dock.pinnedOnStartup = checked }
                }
                ConfigSwitch {
                    buttonIcon: "colors"
                    text: Translation.tr("Tint app icons")
                    checked: Config.options.dock.monochromeIcons
                    onCheckedChanged: { Config.options.dock.monochromeIcons = checked }
                }
            }

            ContentSubsection {
                title: Translation.tr("Appearance")
                GroupedList {
                    ConfigSelectionArray {
                        text: Translation.tr("Style")
                        icon: "dock_to_bottom"
                        currentValue: Config.options.dock.style
                        onSelected: newValue => { Config.options.dock.style = newValue }
                        options: [
                            { displayName: Translation.tr("Float"), icon: "call_to_action", value: "float" },
                            { displayName: Translation.tr("Hug"), icon: "dock_to_bottom", value: "hug" }
                        ]
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("Position")
                        icon: "dock_to_bottom"
                        currentValue: Config.options.dock.position
                        onSelected: newValue => { Config.options.dock.position = newValue }
                        options: [
                            { displayName: Translation.tr("Left"), icon: "dock_to_left", value: "left" },
                            { displayName: Translation.tr("Bottom"), icon: "dock_to_bottom", value: "bottom" },
                            { displayName: Translation.tr("Right"), icon: "dock_to_right", value: "right" }
                        ]
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
                    W.ColorSelectionArray {
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
                    W.ColorSelectionArray {
                        enabled: Config.options.dock.showBorder && Config.options.dock.style !== "hug"
                        icon: "format_paint"
                        text: Translation.tr("Border color")
                        options: ["layer0Border", "primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer", "layer1"]
                        currentValue: Config.options.dock.borderColor
                        onSelected: newValue => { Config.options.dock.borderColor = newValue }
                    }
                    ConfigSpinBox {
                        icon: "height"
                        text: Translation.tr("Height (px)")
                        value: Config.options.dock.height
                        from: 20
                        to: 200
                        stepSize: 1
                        onValueChanged: { Config.options.dock.height = value }
                    }
                    ConfigSpinBox {
                        icon: "swipe_up"
                        text: Translation.tr("Hover region height (px)")
                        value: Config.options.dock.hoverRegionHeight
                        from: 1
                        to: 50
                        stepSize: 1
                        onValueChanged: { Config.options.dock.hoverRegionHeight = value }
                        W.StyledToolTip {
                            text: Translation.tr("How tall the strip at the screen edge has to be hovered to reveal the dock")
                        }
                    }
                    ConfigTextArea {
                        id: dockIgnoredField
                        Layout.fillWidth: true
                        buttonIcon: "visibility_off"
                        fieldWidth: 300
                        text: Translation.tr("Hidden apps")
                        placeholderText: "explorer.exe, ^Shell_"
                        value: Config.options.dock.ignoredAppRegexes.join(", ")
                        onEditingFinished: {
                            const items = dockIgnoredField.value.split(",").map(s => s.trim()).filter(s => s.length > 0);
                            if (items.join(", ") !== Config.options.dock.ignoredAppRegexes.join(", "))
                                Config.options.dock.ignoredAppRegexes = items;
                        }
                        W.StyledToolTip {
                            text: Translation.tr("App IDs to hide from the dock, as regexes, comma-separated (e.g. explorer.exe, ^Shell_)")
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Icons")
                GroupedList {
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
            }

            ContentSubsection {
                title: Translation.tr("Buttons & Media")
                GroupedList {
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
        }

        ContentSection {
            visible: Platform.isWindows
            icon: "toolbar"
            shape: W.MaterialShape.Shape.Square
            title: Translation.tr("Windows taskbar")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "dock_to_bottom"
                    text: Translation.tr("Use the Windows taskbar instead of ii's bar")
                    checked: Config.options.windowsPort.nativeTaskbar
                    onCheckedChanged: {
                        Config.options.windowsPort.nativeTaskbar = checked;
                    }
                    W.StyledToolTip {
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
                    W.StyledToolTip {
                        text: Translation.tr("Keeps Windows from bringing the taskbar up when an app flashes or nothing else is focused.\nTurns on the taskbar's auto-hide while enabled.")
                    }
                }
            }
        }

        ContentSection {
            visible: Platform.isWindows
            icon: "dashboard"
            shape: W.MaterialShape.Shape.Cookie4Sided
            title: Translation.tr("Windows tiling")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "grid_view"
                    text: Translation.tr("Tile windows")
                    checked: Config.options.windowsPort.tiling.enable
                    onCheckedChanged: {
                        Config.options.windowsPort.tiling.enable = checked;
                    }
                    W.StyledToolTip {
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
                    W.StyledToolTip {
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
                    W.StyledToolTip {
                        text: Translation.tr("A split keeps the direction it was made with until Super+\\ flips it.\nOff: a split follows its area's shape instead.")
                    }
                }
            }

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

        Loader {
            Layout.fillWidth: true
            active: !Platform.isWindows
            visible: active
            sourceComponent: ContentSection {
                icon: "lock"
                title: Translation.tr("Lock screen")
                shape: W.MaterialShape.Shape.Pentagon

                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "water_drop"
                        text: Translation.tr("Use Hyprlock (instead of Quickshell)")
                        checked: Config.options.lock.useHyprlock
                        onCheckedChanged: { Config.options.lock.useHyprlock = checked }
                        W.StyledToolTip {
                            text: Translation.tr("If you want to somehow use fingerprint unlock...")
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "account_circle"
                        text: Translation.tr("Launch on startup")
                        checked: Config.options.lock.launchOnStartup
                        onCheckedChanged: { Config.options.lock.launchOnStartup = checked }
                    }
                }

                ContentSubsection {
                    title: Translation.tr("Security")
                    GroupedList {
                        ConfigSwitch {
                            buttonIcon: "settings_power"
                            text: Translation.tr("Require password to power off/restart")
                            checked: Config.options.lock.security.requirePasswordToPower
                            onCheckedChanged: { Config.options.lock.security.requirePasswordToPower = checked }
                            W.StyledToolTip {
                                text: Translation.tr("Remember that on most devices one can always hold the power button to force shutdown\nThis only makes it a tiny bit harder for accidents to happen")
                            }
                        }
                        ConfigSwitch {
                            buttonIcon: "key_vertical"
                            text: Translation.tr("Also unlock keyring")
                            checked: Config.options.lock.security.unlockKeyring
                            onCheckedChanged: { Config.options.lock.security.unlockKeyring = checked }
                            W.StyledToolTip {
                                text: Translation.tr("This is usually safe and needed for your browser and AI sidebar anyway\nMostly useful for those who use lock on startup instead of a display manager that does it (GDM, SDDM, etc.)")
                            }
                        }
                    }
                }

                ContentSubsection {
                    title: Translation.tr("Style: general")
                    GroupedList {
                        ConfigSwitch {
                            buttonIcon: "center_focus_weak"
                            text: Translation.tr("Center clock")
                            checked: Config.options.lock.centerClock
                            onCheckedChanged: { Config.options.lock.centerClock = checked }
                        }
                        ConfigSwitch {
                            buttonIcon: "info"
                            text: Translation.tr('Show "Locked" text')
                            checked: Config.options.lock.showLockedText
                            onCheckedChanged: { Config.options.lock.showLockedText = checked }
                        }
                        ConfigSwitch {
                            buttonIcon: "shapes"
                            text: Translation.tr("Use varying shapes for password characters")
                            checked: Config.options.lock.materialShapeChars
                            onCheckedChanged: { Config.options.lock.materialShapeChars = checked }
                        }
                    }
                }

                ContentSubsection {
                    title: Translation.tr("Style: Blurred")
                    GroupedList {
                        ConfigSwitch {
                            buttonIcon: "blur_on"
                            text: Translation.tr("Enable blur")
                            checked: Config.options.lock.blur.enable
                            onCheckedChanged: { Config.options.lock.blur.enable = checked }
                        }
                        ConfigSpinBox {
                            icon: "loupe"
                            text: Translation.tr("Extra wallpaper zoom (%)")
                            value: Config.options.lock.blur.extraZoom * 100
                            from: 1; to: 150; stepSize: 2
                            onValueChanged: { Config.options.lock.blur.extraZoom = value / 100 }
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "select_window"
            shape: W.MaterialShape.Shape.SoftBurst
            title: Translation.tr("Overlay")

            GroupedList {
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
                    W.StyledToolTip {
                        text: Translation.tr("How visible pinned, clickthrough overlay widgets (like the floating image) stay while the overlay menu is closed")
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Floating Image")
                GroupedList {
                    ConfigTextArea {
                        Layout.fillWidth: true
                        fieldWidth: 380
                        buttonIcon: "imagesmode"
                        text: Translation.tr("Image source")
                        value: Config.options.overlay.floatingImage.imageSource
                        onValueChanged: {
                            Config.options.overlay.floatingImage.imageSource = value;
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
                        W.StyledToolTip {
                            text: Translation.tr("Can also be changed by scrolling on the image itself")
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Crosshair")

                Rectangle {
                    id: crosshairCard
                    Layout.fillWidth: true
                    implicitHeight: crosshairCol.implicitHeight + 28
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1

                    ColumnLayout {
                        id: crosshairCol
                        anchors { fill: parent; margins: 14 }
                        spacing: 8

                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "point_scan"
                            text: Translation.tr("Crosshair code")
                            placeholderText: Translation.tr("Crosshair code (in Valorant's format)")
                            value: Config.options.crosshair.code
                            onValueChanged: {
                                Config.options.crosshair.code = value;
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            W.StyledText {
                                Layout.leftMargin: 8
                                Layout.fillWidth: true
                                text: Translation.tr("Press Super+G to open the overlay and pin the crosshair")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                wrapMode: Text.Wrap
                            }
                            W.RippleButtonWithIcon {
                                id: editorButton
                                Layout.rightMargin: 6
                                Layout.preferredHeight: 40
                                buttonRadius: Appearance.rounding.normal
                                materialIcon: "open_in_new"
                                mainText: Translation.tr("Open editor")
                                onClicked: {
                                    Qt.openUrlExternally(`https://www.vcrdb.net/builder?c=${Config.options.crosshair.code}`);
                                }
                                W.StyledToolTip {
                                    text: "www.vcrdb.net"
                                }
                            }
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "screenshot_frame_2"
            shape: W.MaterialShape.Shape.PuffyDiamond
            title: Translation.tr("Region selector (screen snipping/Google Lens)")

            ContentSubsection {
                title: Translation.tr("Hint target regions")
                GroupedList {
                    ConfigRow {
                        uniform: true
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
                            W.StyledToolTip {
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
                        W.StyledToolTip {
                            text: Translation.tr("Shows the app/window name on top of a hinted region")
                        }
                    }
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
                        icon: "screenshot_frame_2"
                        text: Translation.tr("Selection padding (px)")
                        value: Config.options.regionSelector.targetRegions.selectionPadding
                        from: 0
                        to: 50
                        stepSize: 1
                        onValueChanged: {
                            Config.options.regionSelector.targetRegions.selectionPadding = value;
                        }
                        W.StyledToolTip {
                            text: Translation.tr("Extra padding added around a hinted region when it's picked as the selection")
                        }
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    active: !Platform.isWindows
                    visible: active
                    sourceComponent: GroupedList {
                        ConfigSpinBox {
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
            }

            Loader {
                Layout.fillWidth: true
                active: !Platform.isWindows
                visible: active
                sourceComponent: ContentSubsection {
                    title: Translation.tr("Annotation")
                    GroupedList {
                        ConfigSwitch {
                            buttonIcon: "draw"
                            text: Translation.tr("Use Satty")
                            checked: Config.options.regionSelector.annotation.useSatty
                            onCheckedChanged: {
                                Config.options.regionSelector.annotation.useSatty = checked;
                            }
                            W.StyledToolTip {
                                text: Translation.tr("Needs satty installed. When off, uses swappy instead")
                            }
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Google Lens")

                GroupedList {
                    ConfigSelectionArray {
                        text: Translation.tr("Selection type")
                        icon: "ink_selection"
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
            }

            ContentSubsection {
                title: Translation.tr("Rectangular selection")
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "point_scan"
                        text: Translation.tr("Show aim lines")
                        checked: Config.options.regionSelector.rect.showAimLines
                        onCheckedChanged: {
                            Config.options.regionSelector.rect.showAimLines = checked;
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Circle selection")

                GroupedList {
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
        }

        ContentSection {
            icon: "voting_chip"
            shape: W.MaterialShape.Shape.Sunny
            title: Translation.tr("On-screen display")
            GroupedList {
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
        }

        ContentSection {
            icon: "keyboard"
            shape: W.MaterialShape.Shape.Flower
            title: Translation.tr("On-screen keyboard")

            GroupedList {
                ConfigSelectionArray {
                    text: Translation.tr("Layout")
                    icon: "keyboard_keys"
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
                ConfigSwitch {
                    buttonIcon: "keep"
                    text: Translation.tr("Pinned on startup")
                    checked: Config.options.osk.pinnedOnStartup
                    onCheckedChanged: {
                        Config.options.osk.pinnedOnStartup = checked;
                    }
                }
            }
        }

        ContentSection {
            icon: "keyboard_command_key"
            shape: W.MaterialShape.Shape.Cookie12Sided
            title: Translation.tr("Cheat sheet")

            ContentSubsection {
                title: Translation.tr("Super key symbol")
                tooltip: Translation.tr("You can also manually edit cheatsheet.superKey")
                GroupedList {
                    ConfigSelectionArray {
                        currentValue: Config.options.cheatsheet.superKey
                        onSelected: newValue => {
                            Config.options.cheatsheet.superKey = newValue;
                        }
                        options: ([
                          "󰖳", "", "󰨡", "", "󰌽", "󰣇", "", "", "",
                          "", "", "󱄛", "", "", "", "⌘", "󰀲", "󰟍", ""
                        ]).map(icon => { return {
                          displayName: icon,
                          value: icon
                          }
                        })
                    }
                }
            }

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "󰘵"
                    text: Translation.tr("Use macOS-like symbols for mods keys")
                    checked: Config.options.cheatsheet.useMacSymbol
                    onCheckedChanged: {
                        Config.options.cheatsheet.useMacSymbol = checked;
                    }
                    W.StyledToolTip {
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
                    W.StyledToolTip {
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
                    W.StyledToolTip {
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
                    W.StyledToolTip {
                        text: Translation.tr("Display modifiers and keys in multiple keycap (e.g., \"Ctrl + A\" instead of \"Ctrl A\" or \"󰘴 + A\" instead of \"󰘴 A\")")
                    }
                }
                ConfigSpinBox {
                    icon: "format_size"
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
                    icon: "text_fields"
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
        }

        ContentSection {
            icon: "swipe"
            shape: W.MaterialShape.Shape.Fan
            title: Translation.tr("Interactions")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "swipe"
                    text: Translation.tr("Faster touchpad/mouse scrolling")
                    checked: Config.options.interactions.scrolling.fasterTouchpadScroll
                    onCheckedChanged: {
                        Config.options.interactions.scrolling.fasterTouchpadScroll = checked;
                    }
                    W.StyledToolTip {
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
                    W.StyledToolTip {
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
            }

            ContentSubsection {
                title: Translation.tr("Inertial scrolling (touchpad)")
                tooltip: Translation.tr("Fling and bounce physics used for touchpad input once faster scrolling is enabled above.")

                GroupedList {
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
            }

            ContentSubsection {
                title: Translation.tr("Inertial scrolling (mouse wheel)")

                GroupedList {
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
            }

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "border_right"
                    text: Translation.tr("Dead pixel workaround")
                    checked: Config.options.interactions.deadPixelWorkaround.enable
                    onCheckedChanged: {
                        Config.options.interactions.deadPixelWorkaround.enable = checked;
                    }
                    W.StyledToolTip {
                        text: Translation.tr("Shifts the bar and screen corners 1px so a display that leaves out its edge pixel still gets full hover/click coverage")
                    }
                }
            }
        }

        ContentSection {
            icon: "music_note"
            shape: W.MaterialShape.Shape.Heart
            title: Translation.tr("Media")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "music_note"
                    text: Translation.tr("Filter duplicate players")
                    checked: Config.options.media.filterDuplicatePlayers
                    onCheckedChanged: {
                        Config.options.media.filterDuplicatePlayers = checked;
                    }
                    W.StyledToolTip {
                        text: Translation.tr("Hides a player that looks like a duplicate of another one (e.g. a browser's native player showing up alongside its tab-aggregated one)")
                    }
                }
            }
        }

        ContentSection {
            icon: "widgets"
            shape: W.MaterialShape.Shape.Boom
            title: Translation.tr("Waffle panel")

            ContentSubsection {
                title: Translation.tr("Tweaks")
                tooltip: Translation.tr("Some spots are a bit janky; turning these off makes them match for accuracy instead")

                GroupedList {
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
            }

            ContentSubsection {
                title: Translation.tr("Bar")
                GroupedList {
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
            }

            ContentSubsection {
                title: Translation.tr("Calendar")
                GroupedList {
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "language"
                        text: Translation.tr("Locale for the calendar, e.g. en-GB")
                        placeholderText: "en-GB"
                        value: Config.options.calendar.locale
                        onValueChanged: {
                            Config.options.calendar.locale = value;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "calendar_view_week"
                        text: Translation.tr("Short day-of-week labels")
                        checked: Config.options.waffles.calendar.force2CharDayOfWeek
                        onCheckedChanged: {
                            Config.options.waffles.calendar.force2CharDayOfWeek = checked;
                        }
                        W.StyledToolTip {
                            text: Translation.tr("Shortens the day of week to 2 characters (e.g. \"Mo\" instead of \"Monday\")")
                        }
                    }
                }
            }
        }

        ContentSection {
            shape: W.MaterialShape.Shape.Puffy
            icon: "wallpaper_slideshow"
            title: Translation.tr("Wallpaper selector")

            GroupedList {
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

                ConfigComboBox {
                    text: Translation.tr("Sort wallpapers by")
                    buttonIcon: "sort"
                    currentValue: Config.options.wallpaperSelector.sortMode
                    model: [
                        { displayName: Translation.tr("Newest first"), value: "time" },
                        { displayName: Translation.tr("Oldest first"), value: "time_rev" },
                        { displayName: Translation.tr("Name A-Z"), value: "name" },
                        { displayName: Translation.tr("Name Z-A"), value: "name_rev" },
                        { displayName: Translation.tr("Largest first"), value: "size" },
                        { displayName: Translation.tr("Smallest first"), value: "size_rev" },
                    ]
                    onSelected: newValue => {
                        Config.options.wallpaperSelector.sortMode = newValue;
                    }
                }

                ConfigTextArea {
                    id: userPathField
                    Layout.fillWidth: true
                    buttonIcon: "folder"
                    text: Translation.tr("Custom wallpaper folder")
                    placeholderText: Translation.tr("e.g., C:/Users/you/Pictures")
                    fieldWidth: 300
                    value: Config.options.wallpaperSelector.userPath ?? ""
                    onValueChanged: {
                        Config.options.wallpaperSelector.userPath = userPathField.value;
                    }
                }

                ConfigTextArea {
                    id: liveWallpapersPathField
                    visible: !Platform.isWindows
                    Layout.fillWidth: true
                    buttonIcon: "video_template"
                    text: Translation.tr("Live wallpaper folder")
                    description: Translation.tr("Not supported on Windows yet")
                    placeholderText: Translation.tr("e.g., C:/Users/you/Videos/Wallpapers")
                    fieldWidth: 300
                    value: Config.options.wallpaperSelector.liveWallpapersPath ?? ""
                    onValueChanged: {
                        Config.options.wallpaperSelector.liveWallpapersPath = liveWallpapersPathField.value;
                    }
                }

                ConfigTextArea {
                    id: wppFolderField
                    Layout.fillWidth: true
                    buttonIcon: "folder_special"
                    text: Translation.tr("Wpp folder")
                    fieldWidth: 300
                    value: Config.options.wallpaperSelector.wppFolder ?? ""
                    onValueChanged: {
                        Config.options.wallpaperSelector.wppFolder = wppFolderField.value;
                    }
                }

                ConfigTextArea {
                    id: wppSpicyFolderField
                    Layout.fillWidth: true
                    buttonIcon: "whatshot"
                    text: Translation.tr("Wpp (Spicy) folder")
                    description: Translation.tr("On Windows this folder is only reachable from an age-verified Microsoft account")
                    fieldWidth: 300
                    value: Config.options.wallpaperSelector.wppSpicyFolder ?? ""
                    onValueChanged: {
                        Config.options.wallpaperSelector.wppSpicyFolder = wppSpicyFolderField.value;
                    }
                }
            }
        }

        ContentSection {
            shape: W.MaterialShape.Shape.Puffy
            icon: "travel_explore"
            title: Translation.tr("Wallhaven")

            GroupedList {
                W.StyledText {
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

                    W.StyledText {
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

                ConfigComboBox {
                    text: Translation.tr("Default sort")
                    buttonIcon: "sort"
                    currentValue: Config.options.wallpaperSelector.wallhavenSorting
                    model: [
                        { displayName: Translation.tr("Relevance"), value: "relevance" },
                        { displayName: Translation.tr("Date Added"), value: "date_added" },
                        { displayName: Translation.tr("Top List"), value: "toplist" },
                        { displayName: Translation.tr("Random"), value: "random" },
                    ]
                    onSelected: newValue => {
                        Config.options.wallpaperSelector.wallhavenSorting = newValue;
                        WallhavenSearch.sorting = newValue;
                    }
                }

                ConfigSelectionArray {
                    text: Translation.tr("Order")
                    icon: "swap_vert"
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

                ConfigSelectionArray {
                    text: Translation.tr("Top list range")
                    icon: "date_range"
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

                W.NoticeBox {
                    Layout.fillWidth: true
                    visible: !SpicyStuff.allowed
                    materialIcon: SpicyStuff.checking ? "hourglass_top" : "lock"
                    text: SpicyStuff.restriction
                }

                ConfigSelectionArray {
                    text: Translation.tr("Aspect ratio")
                    icon: "aspect_ratio"
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

                ConfigTextArea {
                    Layout.fillWidth: true
                    buttonIcon: "search"
                    text: Translation.tr("Default search query")
                    fieldWidth: 300
                    value: Config.options.wallpaperSelector.wallhavenQuery ?? ""
                    onValueChanged: {
                        Config.options.wallpaperSelector.wallhavenQuery = value;
                    }
                }

                ConfigTextArea {
                    Layout.fillWidth: true
                    buttonIcon: "palette"
                    text: Translation.tr("Color filter")
                    description: Translation.tr("Comma-separated hex, e.g. cc0000,0066cc")
                    fieldWidth: 300
                    value: Config.options.wallpaperSelector.wallhavenColors ?? ""
                    onValueChanged: {
                        Config.options.wallpaperSelector.wallhavenColors = value;
                        WallhavenSearch.colors = value;
                    }
                }
            }
        }

        ContentSection {
            icon: "text_format"
            shape: W.MaterialShape.Shape.Arrow
            title: Translation.tr("Fonts")

            GroupedList {
                ConfigComboBox {
                    Layout.fillWidth: true
                    buttonIcon: "font_download"
                    text: Translation.tr("Main font")
                    description: Translation.tr("Used for general UI text")
                    fieldWidth: 260
                    fixedWidth: true
                    searchable: true
                    model: SettingsPages.fontOptions(Config.options.appearance.fonts.main)
                    currentValue: Config.options.appearance.fonts.main
                    onSelected: newValue => { Config.options.appearance.fonts.main = newValue }
                }
                ConfigComboBox {
                    Layout.fillWidth: true
                    buttonIcon: "123"
                    text: Translation.tr("Numbers font")
                    description: Translation.tr("Used for displaying numbers")
                    fieldWidth: 260
                    fixedWidth: true
                    searchable: true
                    model: SettingsPages.fontOptions(Config.options.appearance.fonts.numbers)
                    currentValue: Config.options.appearance.fonts.numbers
                    onSelected: newValue => { Config.options.appearance.fonts.numbers = newValue }
                }
                ConfigComboBox {
                    Layout.fillWidth: true
                    buttonIcon: "title"
                    text: Translation.tr("Title font")
                    description: Translation.tr("Used for headings and titles")
                    fieldWidth: 260
                    fixedWidth: true
                    searchable: true
                    model: SettingsPages.fontOptions(Config.options.appearance.fonts.title)
                    currentValue: Config.options.appearance.fonts.title
                    onSelected: newValue => { Config.options.appearance.fonts.title = newValue }
                }
                ConfigComboBox {
                    Layout.fillWidth: true
                    buttonIcon: "space_bar"
                    text: Translation.tr("Monospace font")
                    description: Translation.tr("Used for code and terminal")
                    fieldWidth: 260
                    fixedWidth: true
                    searchable: true
                    model: SettingsPages.fontOptions(Config.options.appearance.fonts.monospace)
                    currentValue: Config.options.appearance.fonts.monospace
                    onSelected: newValue => { Config.options.appearance.fonts.monospace = newValue }
                }
                ConfigComboBox {
                    Layout.fillWidth: true
                    buttonIcon: "emoticon"
                    text: Translation.tr("Nerd font icons")
                    description: Translation.tr("Font used for Nerd Font icons")
                    fieldWidth: 260
                    fixedWidth: true
                    searchable: true
                    model: SettingsPages.fontOptions(Config.options.appearance.fonts.iconNerd)
                    currentValue: Config.options.appearance.fonts.iconNerd
                    onSelected: newValue => { Config.options.appearance.fonts.iconNerd = newValue }
                }
                ConfigComboBox {
                    Layout.fillWidth: true
                    buttonIcon: "book_ribbon"
                    text: Translation.tr("Reading font")
                    description: Translation.tr("Used for reading large blocks of text")
                    fieldWidth: 260
                    fixedWidth: true
                    searchable: true
                    model: SettingsPages.fontOptions(Config.options.appearance.fonts.reading)
                    currentValue: Config.options.appearance.fonts.reading
                    onSelected: newValue => { Config.options.appearance.fonts.reading = newValue }
                }
                ConfigComboBox {
                    Layout.fillWidth: true
                    buttonIcon: "mood_heart"
                    text: Translation.tr("Expressive font")
                    description: Translation.tr("Used for decorative/expressive text")
                    fieldWidth: 260
                    fixedWidth: true
                    searchable: true
                    model: SettingsPages.fontOptions(Config.options.appearance.fonts.expressive)
                    currentValue: Config.options.appearance.fonts.expressive
                    onSelected: newValue => { Config.options.appearance.fonts.expressive = newValue }
                }
            }
        }

        ContentSection {
            icon: "colors"
            title: Translation.tr("Color generation")
            shape: W.MaterialShape.Shape.VerySunny

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "hardware"
                    text: Translation.tr("Shell & utilities")
                    checked: Config.options.appearance.wallpaperTheming.enableAppsAndShell
                    onCheckedChanged: { Config.options.appearance.wallpaperTheming.enableAppsAndShell = checked }
                }
                ConfigSwitch {
                    buttonIcon: "tv_options_input_settings"
                    text: Translation.tr("Qt apps")
                    checked: Config.options.appearance.wallpaperTheming.enableQtApps
                    onCheckedChanged: { Config.options.appearance.wallpaperTheming.enableQtApps = checked }
                    W.StyledToolTip {
                        text: Translation.tr("Shell & utilities theming must also be enabled")
                    }
                }
                ConfigSwitch {
                    buttonIcon: "terminal"
                    text: Translation.tr("Terminal")
                    checked: Config.options.appearance.wallpaperTheming.enableTerminal
                    onCheckedChanged: { Config.options.appearance.wallpaperTheming.enableTerminal = checked }
                    W.StyledToolTip {
                        text: Translation.tr("Shell & utilities theming must also be enabled")
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "dark_mode"
                        text: Translation.tr("Force dark mode in terminal")
                        checked: Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode
                        onCheckedChanged: { Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode = checked }
                        W.StyledToolTip {
                            text: Translation.tr("Ignored if terminal theming is not enabled")
                        }
                    }
                }
                ConfigSpinBox {
                    icon: "invert_colors"
                    text: Translation.tr("Terminal: Harmony (%)")
                    value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony * 100
                    from: 0; to: 100; stepSize: 10
                    onValueChanged: { Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony = value / 100 }
                }
                ConfigSpinBox {
                    icon: "gradient"
                    text: Translation.tr("Terminal: Harmonize threshold")
                    value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold
                    from: 0; to: 100; stepSize: 10
                    onValueChanged: { Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold = value }
                }
                ConfigSpinBox {
                    icon: "format_color_text"
                    text: Translation.tr("Terminal: Foreground boost (%)")
                    value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost * 100
                    from: 0; to: 100; stepSize: 10
                    onValueChanged: { Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost = value / 100 }
                }
            }
        }
    }
}

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

    readonly property color leftIconColor: {
        const name = Config.options.custom.iconColor || "onLayer0"
        return Appearance.colors[`col${name.charAt(0).toUpperCase()}${name.slice(1)}`] ?? Appearance.colors.colOnLayer0
    }

    readonly property var widgetSections: ({
        dynamicIsland: Translation.tr("Dynamic Island"),
        sysTray: Translation.tr("Tray"),
        leftSidebarButton: Translation.tr("Left sidebar button"),
        divisor: Translation.tr("Divider"),
        utilButtons: Translation.tr("Utility buttons"),
        workspaces: Translation.tr("Workspaces"),
        resources: Translation.tr("Resources"),
        media: Translation.tr("Media"),
        aiUsage: Translation.tr("AI Usage")
    })

    function openWidgetSettings(id) {
        const title = page.widgetSections[id]
        if (title) page.goTo(title, title)
    }

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
            icon: "splitscreen_add"
            shape: W.MaterialShape.Shape.Cookie6Sided
            title: Translation.tr("Bar layout")
            hint: Translation.tr("Right-click a widget to open its settings (not every widget has settings here)")
            hintIcon: "info"

            GroupedList {
                LayoutSection {
                    sectionTitle: Config.options.bar.vertical ? Translation.tr("Top") : Translation.tr("Left")
                    layout: Config.options.bar.layouts.leftLayout
                    availableWidgets: BarLayouts.availableFor("left")
                    getWidgetName: id => BarLayouts.name(id)
                    onLayoutEdited: list => { Config.options.bar.layouts.leftLayout = list; }
                    onWidgetContextRequested: id => page.openWidgetSettings(id)
                }

                LayoutSection {
                    sectionTitle: Translation.tr("Center")
                    layout: Config.options.bar.layouts.middleLayout
                    availableWidgets: BarLayouts.availableFor("middle")
                    getWidgetName: id => BarLayouts.name(id)
                    onLayoutEdited: list => { Config.options.bar.layouts.middleLayout = list; }
                    onWidgetContextRequested: id => page.openWidgetSettings(id)
                }

                LayoutSection {
                    sectionTitle: Config.options.bar.vertical ? Translation.tr("Bottom") : Translation.tr("Right")
                    layout: Config.options.bar.layouts.rightLayout
                    availableWidgets: BarLayouts.availableFor("right")
                    getWidgetName: id => BarLayouts.name(id)
                    onLayoutEdited: list => { Config.options.bar.layouts.rightLayout = list; }
                    onWidgetContextRequested: id => page.openWidgetSettings(id)
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    W.StyledText {
                        Layout.leftMargin: 8
                        Layout.fillWidth: true
                        text: BarLayouts.classic ? Translation.tr("The default layout is ii's original bar. Changing any widget switches to the configurable layout.") : Translation.tr("Configurable layout")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.Wrap
                    }
                    W.RippleButtonWithIcon {
                        Layout.preferredHeight: 40
                        enabled: !BarLayouts.classic
                        buttonRadius: Appearance.rounding.normal
                        materialIcon: "restart_alt"
                        mainText: Translation.tr("ii layout")
                        onClicked: {
                            Config.options.bar.layouts.leftLayout = BarLayouts.classicLeft;
                            Config.options.bar.layouts.middleLayout = BarLayouts.classicMiddle;
                            Config.options.bar.layouts.rightLayout = BarLayouts.classicRight;
                        }
                    }
                    W.RippleButtonWithIcon {
                        Layout.rightMargin: 6
                        Layout.preferredHeight: 40
                        buttonRadius: Appearance.rounding.normal
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
                W.ColorSelectionArray {
                    icon: "brush"
                    text: Translation.tr("Group color")
                    options: ["primaryContainer", "secondaryContainer", "tertiaryContainer", "layer1", "layer0"]
                    currentValue: Config.options.bar.groupColor
                    onSelected: newValue => { Config.options.bar.groupColor = newValue; }
                }
                RowLayout {
                    Layout.fillWidth: true
                    W.StyledText {
                        Layout.leftMargin: 8
                        Layout.fillWidth: true
                        text: Translation.tr("Right-click a widget on the bar to change its background, border, radius and padding (configurable layout only).")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.Wrap
                    }
                    W.RippleButtonWithIcon {
                        Layout.rightMargin: 6
                        Layout.preferredHeight: 40
                        enabled: (Config.options.bar.widgetStyles ?? []).length > 0
                        buttonRadius: Appearance.rounding.normal
                        materialIcon: "format_color_reset"
                        mainText: Translation.tr("Reset widget styles")
                        onClicked: { Config.options.bar.widgetStyles = []; }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Screen frame")

                GroupedList {
                    ConfigRow {
                        uniform: true
                        ConfigSwitch {
                            buttonIcon: "panorama_wide_angle"
                            text: Translation.tr("Show frame")
                            checked: Config.options.bar.showFrame
                            onCheckedChanged: { Config.options.bar.showFrame = checked; }
                        }
                        ConfigSwitch {
                            buttonIcon: "colors"
                            enabled: Config.options.bar.showFrame
                            text: Translation.tr("Follow frame color")
                            checked: Config.options.bar.followFrameColor
                            onCheckedChanged: { Config.options.bar.followFrameColor = checked; }
                            W.StyledToolTip {
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
                        onValueChanged: { Config.options.bar.frameThickness = value; }
                    }
                    W.ColorSelectionArray {
                        enabled: Config.options.bar.showFrame
                        opacity: enabled ? 1 : 0.5
                        icon: "imagesearch_roller"
                        text: Translation.tr("Frame color")
                        options: ["primaryContainer", "secondaryContainer", "tertiaryContainer", "layer0", "black"]
                        currentValue: Config.options.bar.frameColor
                        onSelected: newValue => { Config.options.bar.frameColor = newValue; }
                    }
                    ConfigSwitch {
                        buttonIcon: "expand"
                        enabled: Config.options.bar.showFrame
                        text: Translation.tr("Overlap windows when center-only")
                        checked: Config.options.bar.centerOnlyReserveFrame
                        onCheckedChanged: { Config.options.bar.centerOnlyReserveFrame = checked; }
                        W.StyledToolTip {
                            text: Translation.tr("When the left and right sides of the bar are empty, only the frame reserves space and windows go under the bar.")
                        }
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
            icon: "nest_wifi_pro"
            shape: W.MaterialShape.Shape.Cookie4Sided
            title: Translation.tr("Dynamic Island")
            visible: BarLayouts.isUsed("dynamicIsland")

            GroupedList {
                ConfigSelectionArray {
                    text: Translation.tr("Left widget")
                    icon: "right_panel_open"
                    currentValue: Config.options.bar.dynamicIsland.leftWidget
                    onSelected: newValue => { Config.options.bar.dynamicIsland.leftWidget = newValue; }
                    options: [
                        { displayName: "", icon: "block", value: "none" },
                        { displayName: Translation.tr("Clock and date"), icon: "schedule", value: "clockWidget" },
                        { displayName: Translation.tr("Weather"), icon: "partly_cloudy_day", value: "weatherBar" }
                    ]
                }
                ConfigSelectionArray {
                    text: Translation.tr("Right widget")
                    icon: "left_panel_open"
                    currentValue: Config.options.bar.dynamicIsland.rightWidget
                    onSelected: newValue => { Config.options.bar.dynamicIsland.rightWidget = newValue; }
                    options: [
                        { displayName: "", icon: "block", value: "none" },
                        { displayName: Translation.tr("System Icons"), icon: "settings", value: "systemIcons" },
                        { displayName: Translation.tr("Tray"), icon: "apps", value: "sysTray" },
                        { displayName: Translation.tr("Util Buttons"), icon: "widgets", value: "utilButtons" }
                    ]
                }
            }

            ContentSubsection {
                Layout.topMargin: 10
                title: Translation.tr("Media")
                GroupedList {
                    ConfigSelectionArray {
                        text: Translation.tr("Visualizer style")
                        icon: "graphic_eq"
                        currentValue: Config.options.bar.dynamicIsland.visualizerStyle
                        onSelected: newValue => { Config.options.bar.dynamicIsland.visualizerStyle = newValue; }
                        options: [
                            { displayName: "", icon: "block", value: "none" },
                            { displayName: Translation.tr("Dots"), icon: "steppers", value: "dots" },
                            { displayName: Translation.tr("Wave"), icon: "ssid_chart", value: "wave" }
                        ]
                    }
                    ConfigSwitch {
                        buttonIcon: "play_circle"
                        text: Translation.tr("Show media controls")
                        checked: Config.options.bar.dynamicIsland.showMediaControls
                        onCheckedChanged: { Config.options.bar.dynamicIsland.showMediaControls = checked; }
                    }
                }
            }
        }

        ContentSection {
            icon: "notifications"
            shape: W.MaterialShape.Shape.Bun
            title: Translation.tr("Notifications")

            GroupedList {
                ConfigRow {
                    uniform: true
                    Layout.alignment: Qt.AlignHCenter
                    ConfigSelectionArray {
                        Layout.alignment: Qt.AlignHCenter
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
                    Layout.alignment: Qt.AlignHCenter
                    ConfigSelectionArray {
                        Layout.alignment: Qt.AlignHCenter
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
                ConfigRow {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    spacing: 10

                    W.CustomIcon {
                        source: Config.options.custom.distroIcon || (Config.options.bar.topLeftIcon == "distro" ? SystemInfo.distroIcon : `${Config.options.bar.topLeftIcon}-symbolic`)
                        customFolder: Config.options.custom.distroIcon !== "" ? Config.options.custom.iconsPath : ""
                        colorize: Config.options.custom.colorizeIcon
                        color: page.leftIconColor
                        width: Appearance.font.pixelSize.larger
                        height: Appearance.font.pixelSize.larger
                    }
                    W.StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Icon")
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                    W.StyledText {
                        text: Config.options.custom.distroIcon !== "" ? Config.options.custom.distroIcon.replace("-symbolic", "") : Translation.tr("Top-left icon")
                        color: Appearance.colors.colSubtext
                    }
                    W.RippleButtonWithIcon {
                        Layout.preferredHeight: 36
                        enabled: Config.options.custom.distroIcon !== ""
                        buttonRadius: Appearance.rounding.normal
                        materialIcon: "restart_alt"
                        mainText: Translation.tr("Default")
                        onClicked: { Config.options.custom.distroIcon = ""; }
                    }
                }
                W.IconPickerGrid {
                    customFolder: Config.options.custom.iconsPath
                    currentValue: Config.options.custom.distroIcon
                    colorize: Config.options.custom.colorizeIcon
                    iconColor: page.leftIconColor
                    onSelected: name => { Config.options.custom.distroIcon = name; }
                }
                ConfigTextArea {
                    id: iconsPathField
                    Layout.fillWidth: true
                    buttonIcon: "folder_open"
                    text: Translation.tr("Custom icons folder")
                    placeholderText: Platform.isWindows ? Translation.tr("Leave empty to use the built-in icons, e.g. %USERPROFILE%\\Pictures\\icons") : Translation.tr("Leave empty to use the built-in icons, e.g. ~/Pictures/icons")
                    value: Config.options.custom.iconsPath
                    onValueChanged: iconsPathDebounce.restart()

                    Timer {
                        id: iconsPathDebounce
                        interval: 600
                        onTriggered: { Config.options.custom.iconsPath = iconsPathField.value; }
                    }
                }
                ConfigSwitch {
                    buttonIcon: "colors"
                    text: Translation.tr("Colorize icon")
                    checked: Config.options.custom.colorizeIcon
                    onCheckedChanged: { Config.options.custom.colorizeIcon = checked; }
                }
                W.ColorSelectionArray {
                    enabled: Config.options.custom.colorizeIcon
                    opacity: enabled ? 1 : 0.4
                    icon: "palette"
                    text: Translation.tr("Icon color")
                    options: ["onLayer0", "primary", "secondary", "tertiary", "onPrimaryContainer", "onSecondaryContainer", "onTertiaryContainer"]
                    currentValue: Config.options.custom.iconColor
                    onSelected: newValue => { Config.options.custom.iconColor = newValue; }
                }
            }
        }

        ContentSection {
            icon: "vertical_align_center"
            shape: W.MaterialShape.Shape.Diamond
            title: Translation.tr("Divider")
            visible: BarLayouts.isUsed("divisor")

            GroupedList {
                ConfigSelectionArray {
                    text: Translation.tr("Style")
                    icon: "style"
                    currentValue: Config.options.bar.divider.style
                    onSelected: newValue => { Config.options.bar.divider.style = newValue; }
                    options: [
                        { displayName: Translation.tr("Line"), icon: "more_vert", value: "rect" },
                        { displayName: Translation.tr("Dot"), icon: "fiber_manual_record", value: "dot" },
                        { displayName: Translation.tr("Space"), icon: "space_bar", value: "space" }
                    ]
                }
                ConfigSpinBox {
                    icon: "width"
                    enabled: Config.options.bar.divider.style === "space"
                    text: Translation.tr("Space width (px)")
                    value: Config.options.bar.divider.spacing
                    from: 4
                    to: 400
                    stepSize: 2
                    onValueChanged: { Config.options.bar.divider.spacing = value; }
                }
            }
        }

        ContentSection {
            icon: "buttons_alt"
            shape: W.MaterialShape.Shape.SoftBurst
            title: Translation.tr("Utility buttons")
            visible: BarLayouts.isUsed("utilButtons")

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
                    ConfigSwitch {
                        buttonIcon: "imagesmode"
                        text: Translation.tr("Wallpapers toggle")
                        checked: Config.options.bar.utilButtons.showWallpaperToggle
                        onCheckedChanged: { Config.options.bar.utilButtons.showWallpaperToggle = checked }
                    }
                }
            }
        }

        ContentSection {
            shape: W.MaterialShape.Shape.Cookie12Sided
            icon: "steppers"
            title: Translation.tr("Workspaces")
            visible: BarLayouts.isUsed("workspaces")
            GroupedList {
                ConfigSelectionArray {
                    text: Translation.tr("Style")
                    icon: "style"
                    currentValue: Config.options.bar.workspaces.style ?? "default"
                    onSelected: newValue => { Config.options.bar.workspaces.style = newValue; }
                    options: [
                        { displayName: Translation.tr("Default"), icon: "view_carousel", value: "default" },
                        { displayName: Translation.tr("GNOME"), icon: "more_horiz", value: "gnome" },
                        { displayName: Translation.tr("Dots"), icon: "hdr_weak", value: "dots" },
                        { displayName: Translation.tr("Ticks"), icon: "more_vert", value: "ticks" }
                    ]
                }
                ConfigSelectionArray {
                    enabled: (Config.options.bar.workspaces.style ?? "default") === "default"
                    opacity: enabled ? 1 : 0.5
                    text: Translation.tr("Indicator style")
                    icon: "page_control"
                    currentValue: Config.options.bar.workspaces.indicatorStyle ?? "dot"
                    onSelected: newValue => { Config.options.bar.workspaces.indicatorStyle = newValue; }
                    options: [
                        { displayName: Translation.tr("Dots"), icon: "radio_button_checked", value: "dot" },
                        { displayName: Translation.tr("Icons"), icon: "interests", value: "icon" }
                    ]
                }
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
            visible: BarLayouts.isUsed("resources")

            GroupedList {
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "memory"
                        text: Translation.tr("RAM")
                        checked: Config.options.bar.resources.alwaysShowRam
                        onCheckedChanged: { Config.options.bar.resources.alwaysShowRam = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "storage"
                        text: Translation.tr("Disk")
                        checked: Config.options.bar.resources.alwaysShowDisk
                        onCheckedChanged: { Config.options.bar.resources.alwaysShowDisk = checked }
                        W.StyledToolTip {
                            text: Platform.isWindows ? Translation.tr("Usage of the system drive") : Translation.tr("Usage of the root partition")
                        }
                    }
                }
                ConfigSwitch {
                    visible: !Platform.isWindows
                    buttonIcon: "thermostat"
                    text: Translation.tr("CPU temperature")
                    checked: Config.options.bar.resources.alwaysShowCpuTemp
                    onCheckedChanged: { Config.options.bar.resources.alwaysShowCpuTemp = checked }
                }
                ConfigSelectionArray {
                    text: Translation.tr("Style")
                    icon: "style"
                    currentValue: Config.options.bar.resources.style
                    onSelected: newValue => { Config.options.bar.resources.style = newValue; }
                    options: [
                        { displayName: Translation.tr("Filled"), icon: "incomplete_circle", value: "filled" },
                        { displayName: Translation.tr("Outline"), icon: "circles", value: "outline" },
                        { displayName: Translation.tr("Text"), icon: "text_fields", value: "text" }
                    ]
                }
                ConfigSwitch {
                    buttonIcon: "decimal_increase"
                    text: Translation.tr("Show percentage")
                    checked: Config.options.bar.resources.showValue
                    onCheckedChanged: { Config.options.bar.resources.showValue = checked; }
                }
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
            icon: "music_note"
            shape: W.MaterialShape.Shape.Sunny
            title: Translation.tr("Media")

            GroupedList {
                ConfigTextArea {
                    id: preferredPlayerField
                    Layout.fillWidth: true
                    buttonIcon: "play_circle"
                    text: Translation.tr("Preferred player")
                    placeholderText: Platform.isWindows ? Translation.tr("e.g. spotify, chrome") : Translation.tr("e.g. spotify, firefox")
                    value: Config.options.bar.media.preferredPlayer
                    onValueChanged: mediaDebounceTimer.restart()

                    Timer {
                        id: mediaDebounceTimer
                        interval: 600
                        onTriggered: { Config.options.bar.media.preferredPlayer = preferredPlayerField.value; }
                    }
                }
                ConfigSwitch {
                    buttonIcon: "keep"
                    text: Translation.tr("Pin media controls")
                    checked: Config.options.bar.media.alwaysVisible
                    onCheckedChanged: { Config.options.bar.media.alwaysVisible = checked; }
                    W.StyledToolTip {
                        text: Translation.tr("Media controls stay open when clicking elsewhere.")
                    }
                }
                ConfigSwitch {
                    buttonIcon: "lyrics"
                    text: Translation.tr("Show lyrics")
                    checked: Config.options.bar.media.showLyrics
                    onCheckedChanged: { Config.options.bar.media.showLyrics = checked; }
                    W.StyledToolTip {
                        text: Translation.tr("Synced lyrics in the media controls, fetched from lrclib.net.")
                    }
                }
                ConfigSwitch {
                    buttonIcon: "titlecase"
                    text: Translation.tr("Show only title")
                    checked: Config.options.bar.media.onlyTitle
                    onCheckedChanged: { Config.options.bar.media.onlyTitle = checked; }
                }
                ConfigSpinBox {
                    enabled: !BarLayouts.classic
                    icon: "width"
                    text: Translation.tr("Max media width")
                    value: Config.options.bar.media.maxWidth
                    from: 100
                    to: 500
                    stepSize: 10
                    onValueChanged: { Config.options.bar.media.maxWidth = value; }
                }
                ConfigSpinBox {
                    enabled: !BarLayouts.classic
                    icon: "width_normal"
                    text: Translation.tr("Min media width")
                    value: Config.options.bar.media.minWidth
                    from: 0
                    to: 500
                    stepSize: 10
                    onValueChanged: { Config.options.bar.media.minWidth = value; }
                }
            }
        }

        ContentSection {
            icon: "neurology"
            shape: W.MaterialShape.Shape.Clover4Leaf
            title: Translation.tr("AI Usage")
            visible: BarLayouts.isUsed("aiUsage")

            GroupedList {
                ConfigSpinBox {
                    icon: "token"
                    text: Translation.tr("Token limit per 5 hours")
                    value: Config.options.bar.aiUsage.tokenLimit
                    from: 10000
                    to: 100000000
                    stepSize: 100000
                    onValueChanged: { Config.options.bar.aiUsage.tokenLimit = value; }
                }
                ConfigSpinBox {
                    icon: "av_timer"
                    text: Translation.tr("Update interval (s)")
                    value: Config.options.bar.aiUsage.updateInterval
                    from: 10
                    to: 3600
                    stepSize: 10
                    onValueChanged: { Config.options.bar.aiUsage.updateInterval = value; }
                }
            }
        }

        ContentSection {
            icon: "cloud"
            shape: W.MaterialShape.Shape.Pill
            title: Translation.tr("Weather")
            visible: BarLayouts.classic
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
                    buttonIcon: "visibility"
                    text: Translation.tr("Enable")
                    checked: Config.options.bar.tooltips.enable
                    onCheckedChanged: { Config.options.bar.tooltips.enable = checked; }
                }
                ConfigSwitch {
                    enabled: Config.options.bar.tooltips.enable
                    buttonIcon: "ads_click"
                    text: Translation.tr("Click to show")
                    checked: Config.options.bar.tooltips.clickToShow
                    onCheckedChanged: { Config.options.bar.tooltips.clickToShow = checked; }
                }
                ConfigSelectionArray {
                    enabled: Config.options.bar.tooltips.enable
                    text: Translation.tr("Style")
                    icon: "tooltip"
                    currentValue: Config.options.bar.tooltips.style
                    onSelected: newValue => { Config.options.bar.tooltips.style = newValue; }
                    options: [
                        { displayName: Translation.tr("Default"), icon: "tooltip", value: "default" },
                        { displayName: Translation.tr("Morph"), icon: "join_inner", value: "morph" }
                    ]
                }
            }
        }
    }
}

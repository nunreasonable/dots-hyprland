import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets as W
import qs.modules.common.functions
import qs.modules.common.models.windows as WinModels
import qs.modules.settingsPc.widgets

ContentPage {
    id: page
    forceWidth: true
    bottomContentPadding: 15

    readonly property var autostartEntries: WindowsNative.autostart ? WindowsNative.autostart.entries : []
    readonly property var autostartAppOptions: {
        const apps = Array.from(DesktopEntries.applications.values);
        const mapped = apps.map(app => {
            const path = app.comment && app.comment.length > 0
                ? app.comment
                : (app.command && app.command.length > 0 ? "shell:AppsFolder\\" + app.command[0] : "");
            return {label: app.name, value: path};
        }).filter(o => o.value.length > 0 && o.label.length > 0);
        mapped.sort((a, b) => a.label.localeCompare(b.label));
        return mapped;
    }

    function addAutostartApp(path, name) {
        if (!path || path.length === 0) return;
        WindowsNative.autostart?.addFromPath(path, name ?? "", []);
    }

    FileDialog {
        id: autostartFileDialog
        title: Translation.tr("Choose an app")
        nameFilters: [Translation.tr("Programs (*.exe)"), Translation.tr("All files (*)")]
        onAccepted: page.addAutostartApp(FileUtils.trimFileProtocol(selectedFile.toString()), "")
    }

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            id: displaysSection
            icon: "monitor"
            shape: W.MaterialShape.Shape.Cookie6Sided
            title: Translation.tr("Displays")

            readonly property var current: displayConfig.monitors[displayCanvas.selectedIndex] ?? null
            readonly property bool active: displaysSection.current !== null && !displaysSection.current.disabled
            readonly property bool busy: displayConfig.busy

            WinModels.MonitorConfigOption {
                id: displayConfig
            }

            W.MonitorCanvas {
                id: displayCanvas
                Layout.fillWidth: true
                visible: displayConfig.monitors.length > 0
                monitorConfig: displayConfig
            }

            W.NoticeBox {
                Layout.fillWidth: true
                Layout.topMargin: 6
                visible: displayConfig.lastError.length > 0
                materialIcon: "error"
                text: Translation.tr("Windows didn't accept that display change.") + "\n" + displayConfig.lastError
            }

            ContentSubsection {
                Layout.topMargin: 10
                visible: displaysSection.current !== null
                title: displayConfig.title(displaysSection.current)

                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "desktop_windows"
                        text: Translation.tr("Enabled")
                        enabled: !displaysSection.busy && (displayConfig.activeCount > 1 || !displaysSection.active)
                        checked: displaysSection.active
                        onCheckedChanged: {
                            if (!displaysSection.current || checked === displaysSection.active)
                                return;
                            displayConfig.setEnabled(displaysSection.current, checked);
                            checked = Qt.binding(() => displaysSection.active);
                        }
                    }

                    ConfigSwitch {
                        buttonIcon: "star"
                        text: Translation.tr("Make this my main display")
                        enabled: !displaysSection.busy && displaysSection.active && displayConfig.activeCount > 1 && !(displaysSection.current?.primary ?? false)
                        checked: displaysSection.current?.primary ?? false
                        onCheckedChanged: {
                            if (!displaysSection.current || checked === (displaysSection.current.primary ?? false))
                                return;
                            if (checked)
                                displayConfig.setPrimary(displaysSection.current);
                            checked = Qt.binding(() => displaysSection.current?.primary ?? false);
                        }
                    }
                }

                GroupedList {
                    Layout.topMargin: 6
                    visible: displaysSection.active

                    ConfigComboBox {
                        Layout.fillWidth: true
                        buttonIcon: "aspect_ratio"
                        text: Translation.tr("Display resolution")
                        enabled: !displaysSection.busy
                        model: displayConfig.resolutionOptions(displaysSection.current)
                        currentValue: displayConfig.resolutionValue(displaysSection.current?.resolutionWidth, displaysSection.current?.resolutionHeight)
                        onSelected: newValue => displayConfig.setResolution(displaysSection.current, newValue)
                    }

                    ConfigComboBox {
                        Layout.fillWidth: true
                        buttonIcon: "speed"
                        text: Translation.tr("Refresh rate")
                        enabled: !displaysSection.busy && model.length > 1
                        model: displayConfig.refreshRateOptions(displaysSection.current)
                        currentValue: displaysSection.current?.refreshRate ?? 0
                        onSelected: newValue => displayConfig.setRefreshRate(displaysSection.current, newValue)
                    }

                    ConfigSelectionArray {
                        text: Translation.tr("Display orientation")
                        icon: "mobile_rotate"
                        enabled: !displaysSection.busy
                        currentValue: displaysSection.current?.rotation ?? 0
                        onSelected: newValue => displayConfig.setRotation(displaysSection.current, newValue)
                        options: [
                            { displayName: Translation.tr("Landscape"), icon: "screen_rotation_alt", value: 0 },
                            { displayName: Translation.tr("Portrait"), icon: "rotate_90_degrees_cw", value: 1 },
                            { displayName: Translation.tr("Landscape (flipped)"), icon: "screen_rotation", value: 2 },
                            { displayName: Translation.tr("Portrait (flipped)"), icon: "rotate_90_degrees_ccw", value: 3 }
                        ]
                    }
                }

                GroupedList {
                    Layout.topMargin: 6
                    visible: displaysSection.active && (displaysSection.current?.scaleSupported ?? false)

                    ConfigComboBox {
                        Layout.fillWidth: true
                        buttonIcon: "zoom_in"
                        text: Translation.tr("Scale")
                        enabled: !displaysSection.busy
                        model: displayConfig.scaleOptions(displaysSection.current)
                        currentValue: displaysSection.current?.scale ?? 100
                        onSelected: newValue => displayConfig.setScale(displaysSection.current, newValue)
                    }
                }
            }

            ContentSubsection {
                Layout.topMargin: 10
                visible: displaysSection.active && (displaysSection.current?.hdrSupported ?? false)
                title: Translation.tr("HDR & Color Management")

                W.NoticeBox {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 6
                    visible: displaysSection.current?.hdrLimited ?? false
                    text: Translation.tr("Windows is limiting HDR on this display right now, for example to save battery.")
                }

                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "hdr_on"
                        text: Translation.tr("Use HDR")
                        enabled: !displaysSection.busy
                        checked: displaysSection.current?.hdrEnabled ?? false
                        onCheckedChanged: {
                            if (!displaysSection.current || checked === (displaysSection.current.hdrEnabled ?? false))
                                return;
                            displayConfig.setHdr(displaysSection.current, checked);
                            checked = Qt.binding(() => displaysSection.current?.hdrEnabled ?? false);
                        }
                    }
                }

                GroupedList {
                    Layout.topMargin: 6
                    visible: (displaysSection.current?.hdrEnabled ?? false) && (displaysSection.current?.sdrBrightnessSupported ?? false)

                    ConfigSlider {
                        id: sdrBrightnessSlider
                        buttonIcon: "brightness_6"
                        text: Translation.tr("SDR content brightness")
                        textWidth: 180
                        from: 80
                        to: 480
                        stepSize: 4
                        usePercentTooltip: false
                        value: displaysSection.current?.sdrBrightness ?? 80
                        onMoved: sdrBrightnessTimer.restart()

                        Timer {
                            id: sdrBrightnessTimer
                            interval: 120
                            onTriggered: displayConfig.setSdrBrightness(displaysSection.current, sdrBrightnessSlider.value)
                        }
                    }
                }
            }

            W.NoticeBox {
                Layout.fillWidth: true
                Layout.topMargin: 10
                visible: displayConfig.available
                text: Translation.tr("Color profiles, Night light and HDR calibration are in Windows Settings.")

                Item {
                    Layout.fillWidth: true
                }
                W.RippleButtonWithIcon {
                    Layout.fillWidth: false
                    buttonRadius: Appearance.rounding.small
                    materialIcon: "open_in_new"
                    mainText: Translation.tr("Open Windows display settings")
                    onClicked: Qt.openUrlExternally("ms-settings:display")
                    colBackground: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer)
                    colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                    colRipple: Appearance.colors.colPrimaryContainerActive
                }
            }
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
                    ColumnLayout {
                        spacing: 6
                        RowLayout {
                            spacing: 10
                            Layout.leftMargin: 8
                            W.MaterialSymbol {
                                text: "keyboard_return"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                            W.StyledText {
                                text: Translation.tr("Repeat delay")
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                        }
                        ConfigSelectionArray {
                            Layout.fillWidth: true
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
                    ColumnLayout {
                        spacing: 6
                        enabled: WindowsNative.inputSettings?.touchpadEnabled ?? true
                        RowLayout {
                            spacing: 10
                            Layout.leftMargin: 8
                            W.MaterialSymbol {
                                text: "touch_app"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                            W.StyledText {
                                text: Translation.tr("Sensitivity")
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                        }
                        ConfigSelectionArray {
                            Layout.fillWidth: true
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
                        model: (WindowsNative.inputSettings?.cursorSchemeNames ?? []).map((name, i) => ({ displayName: WindowsNative.inputSettings?.cursorSchemeLabels[i] ?? name, value: name }))
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

            ContentSubsection {
                title: Translation.tr("Lock screen")

                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "lock_clock"
                        text: Translation.tr("Lock after inactivity")
                        checked: Config.options.windowsPort.idle.lock > 0
                        onCheckedChanged: {
                            if (checked && Config.options.windowsPort.idle.lock <= 0)
                                Config.options.windowsPort.idle.lock = 300;
                            else if (!checked && Config.options.windowsPort.idle.lock > 0)
                                Config.options.windowsPort.idle.lock = 0;
                        }
                    }
                    ConfigSpinBox {
                        icon: "timer"
                        enabled: Config.options.windowsPort.idle.lock > 0
                        text: Translation.tr("Lock after (minutes)")
                        value: Math.max(1, Math.round(Config.options.windowsPort.idle.lock / 60))
                        from: 1; to: 999; stepSize: 1
                        onValueChanged: {
                            if (Config.options.windowsPort.idle.lock > 0 && value * 60 !== Config.options.windowsPort.idle.lock)
                                Config.options.windowsPort.idle.lock = value * 60;
                        }
                    }
                }
                W.NoticeBox {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    visible: Config.options.windowsPort.idle.lock > 0 && (Idle.inhibit || WindowsGameMode.enabled)
                    text: Translation.tr("Paused right now: something is keeping the screen awake, or Game Mode is on.")
                }
                W.NoticeBox {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    text: Translation.tr("This locks the session with Windows' own lock screen. It's separate from the screen/sleep timeouts below, which Windows controls directly.")
                }
            }

            ContentSubsection {
                Layout.topMargin: 10
                title: Translation.tr("Screen and sleep")

                GroupedList {
                    ConfigSpinBox {
                        icon: "monitor"
                        text: Translation.tr("Turn off screen after (minutes), plugged in")
                        value: WindowsNative.idlePower?.screenOffAcMinutes ?? 0
                        from: 0; to: 999; stepSize: 1
                        onValueChanged: {
                            if (WindowsNative.idlePower && value !== WindowsNative.idlePower.screenOffAcMinutes)
                                WindowsNative.idlePower.screenOffAcMinutes = value;
                        }
                    }
                    ConfigSpinBox {
                        icon: "bedtime"
                        text: Translation.tr("Sleep after (minutes), plugged in")
                        value: WindowsNative.idlePower?.sleepAcMinutes ?? 0
                        from: 0; to: 999; stepSize: 1
                        onValueChanged: {
                            if (WindowsNative.idlePower && value !== WindowsNative.idlePower.sleepAcMinutes)
                                WindowsNative.idlePower.sleepAcMinutes = value;
                        }
                    }
                }
                GroupedList {
                    Layout.topMargin: 6
                    visible: WindowsNative.idlePower?.hasBattery ?? false
                    ConfigSpinBox {
                        icon: "battery_full"
                        text: Translation.tr("Turn off screen after (minutes), on battery")
                        value: WindowsNative.idlePower?.screenOffDcMinutes ?? 0
                        from: 0; to: 999; stepSize: 1
                        onValueChanged: {
                            if (WindowsNative.idlePower && value !== WindowsNative.idlePower.screenOffDcMinutes)
                                WindowsNative.idlePower.screenOffDcMinutes = value;
                        }
                    }
                    ConfigSpinBox {
                        icon: "battery_full"
                        text: Translation.tr("Sleep after (minutes), on battery")
                        value: WindowsNative.idlePower?.sleepDcMinutes ?? 0
                        from: 0; to: 999; stepSize: 1
                        onValueChanged: {
                            if (WindowsNative.idlePower && value !== WindowsNative.idlePower.sleepDcMinutes)
                                WindowsNative.idlePower.sleepDcMinutes = value;
                        }
                    }
                }
                W.NoticeBox {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    visible: !(WindowsNative.idlePower?.lastWriteOk ?? true)
                    text: Translation.tr("Windows did not accept the last change to this power plan.")
                }
                W.NoticeBox {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    text: Translation.tr("0 means never. These change your current Windows power plan directly.")
                }
            }
        }

        ContentSection {
            icon: "rocket_launch"
            shape: W.MaterialShape.Shape.Pentagon
            title: Translation.tr("Autostart")

            W.StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Apps that launch automatically when you sign in.")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledComboBoxSearch {
                    id: autostartAppPicker
                    Layout.fillWidth: true
                    textRole: "label"
                    model: page.autostartAppOptions
                    displayText: currentIndex >= 0 ? currentText : Translation.tr("Pick an app…")
                }

                W.RippleButton {
                    implicitWidth: 44
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.normal
                    enabled: autostartAppPicker.currentIndex >= 0
                    colBackground: Appearance.colors.colSecondaryContainer
                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                    colRipple: Appearance.colors.colSecondaryContainerActive
                    onClicked: {
                        const opt = page.autostartAppOptions[autostartAppPicker.currentIndex];
                        if (opt) page.addAutostartApp(opt.value, opt.label);
                        autostartAppPicker.currentIndex = -1;
                    }
                    contentItem: W.MaterialSymbol {
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "add"
                        iconSize: 20
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                    W.StyledToolTip {
                        text: Translation.tr("Add to startup")
                    }
                }

                W.RippleButton {
                    implicitWidth: 44
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.normal
                    colBackground: Appearance.colors.colLayer1
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colRipple: Appearance.colors.colLayer1Active
                    onClicked: autostartFileDialog.open()
                    contentItem: W.MaterialSymbol {
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "folder_open"
                        iconSize: 20
                        color: Appearance.colors.colOnLayer1
                    }
                    W.StyledToolTip {
                        text: Translation.tr("Browse for a file")
                    }
                }
            }

            W.StyledText {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: page.autostartEntries.length === 0
                text: Translation.tr("No startup apps found")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
            }

            Repeater {
                model: page.autostartEntries

                delegate: RowLayout {
                    id: autostartRow
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    spacing: 10

                    W.StyledSwitch {
                        checked: autostartRow.modelData.enabled
                        enabled: autostartRow.modelData.scope === "user"
                        onToggled: WindowsNative.autostart?.setEnabled(autostartRow.modelData.id, checked)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        RowLayout {
                            spacing: 6
                            W.StyledText {
                                text: autostartRow.modelData.name
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                            }
                            W.StyledText {
                                visible: autostartRow.modelData.isSelf
                                text: Translation.tr("(ii-windows)")
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smaller
                            }
                            W.StyledText {
                                visible: autostartRow.modelData.scope === "machine"
                                text: Translation.tr("(all users)")
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smaller
                            }
                        }
                        W.StyledText {
                            Layout.fillWidth: true
                            text: autostartRow.modelData.command
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideRight
                        }
                    }

                    W.RippleButton {
                        id: autostartRemoveButton
                        visible: autostartRow.modelData.removable
                        implicitWidth: 36
                        implicitHeight: 36
                        buttonRadius: 18
                        colBackground: "transparent"
                        colBackgroundHover: Qt.rgba(1, 1, 1, 0.12)
                        colRipple: Qt.rgba(1, 1, 1, 0.2)
                        onClicked: autostartRemovePopup.open()
                        contentItem: W.MaterialSymbol {
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: "delete"
                            iconSize: 20
                            color: Appearance.colors.colOnLayer1
                        }
                        W.StyledToolTip {
                            text: Translation.tr("Remove")
                        }

                        Popup {
                            id: autostartRemovePopup
                            x: autostartRemoveButton.width - implicitWidth
                            y: autostartRemoveButton.height + 4
                            padding: 14
                            modal: true
                            focus: true
                            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                            contentItem: ColumnLayout {
                                spacing: 10
                                W.StyledText {
                                    Layout.maximumWidth: 240
                                    wrapMode: Text.Wrap
                                    text: Translation.tr("Remove \"%1\" from startup?").arg(autostartRow.modelData.name)
                                }
                                RowLayout {
                                    Layout.alignment: Qt.AlignRight
                                    W.DialogButton {
                                        buttonText: Translation.tr("Cancel")
                                        onClicked: autostartRemovePopup.close()
                                    }
                                    W.DialogButton {
                                        buttonText: Translation.tr("Remove")
                                        onClicked: {
                                            WindowsNative.autostart?.removeEntry(autostartRow.modelData.id);
                                            autostartRemovePopup.close();
                                        }
                                    }
                                }
                            }
                            background: Rectangle {
                                radius: Appearance.rounding.normal
                                color: Appearance.m3colors.m3surfaceContainerHigh
                            }
                        }
                    }
                }
            }

            ContentSubsection {
                Layout.topMargin: 10
                title: Translation.tr("Start with ii")

                W.StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Apps ii itself opens when the shell starts, each on its own workspace.")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                }

                W.AutostartApps {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                }
            }
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

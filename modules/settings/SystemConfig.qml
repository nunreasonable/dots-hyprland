import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.models.windows as WinModels

ContentPage {
    forceWidth: true

    ContentSection {
        id: displaysSection
        icon: "monitor"
        title: Translation.tr("Displays")

        readonly property var current: displayConfig.monitors[displayCanvas.selectedIndex] ?? null
        readonly property bool active: displaysSection.current !== null && !displaysSection.current.disabled
        readonly property bool busy: displayConfig.busy

        WinModels.MonitorConfigOption {
            id: displayConfig
        }

        MonitorCanvas {
            id: displayCanvas
            Layout.fillWidth: true
            visible: displayConfig.monitors.length > 0
            monitorConfig: displayConfig
        }

        NoticeBox {
            Layout.fillWidth: true
            visible: displayConfig.lastError.length > 0
            materialIcon: "error"
            text: Translation.tr("Windows didn't accept that display change.") + "\n" + displayConfig.lastError
        }

        ContentSubsection {
            title: displayConfig.title(displaysSection.current)
            visible: displaysSection.current !== null

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
                visible: displaysSection.active && displayConfig.activeCount > 1
                buttonIcon: "star"
                text: Translation.tr("Make this my main display")
                enabled: !displaysSection.busy && !(displaysSection.current?.primary ?? false)
                checked: displaysSection.current?.primary ?? false
                onCheckedChanged: {
                    if (!displaysSection.current || checked === (displaysSection.current.primary ?? false))
                        return;
                    if (checked)
                        displayConfig.setPrimary(displaysSection.current);
                    checked = Qt.binding(() => displaysSection.current?.primary ?? false);
                }
            }

            ContentSubsection {
                visible: displaysSection.active
                title: Translation.tr("Display resolution")

                StyledComboBox {
                    enabled: !displaysSection.busy
                    textRole: "displayName"
                    model: displayConfig.resolutionOptions(displaysSection.current)
                    currentIndex: {
                        const value = displayConfig.resolutionValue(displaysSection.current?.resolutionWidth, displaysSection.current?.resolutionHeight);
                        return Math.max(0, model.findIndex(option => option.value === value));
                    }
                    onActivated: index => displayConfig.setResolution(displaysSection.current, model[index].value)
                }
            }

            ContentSubsection {
                visible: displaysSection.active
                title: Translation.tr("Refresh rate")

                StyledComboBox {
                    enabled: !displaysSection.busy && model.length > 1
                    textRole: "displayName"
                    model: displayConfig.refreshRateOptions(displaysSection.current)
                    currentIndex: Math.max(0, model.findIndex(option => option.value === displaysSection.current?.refreshRate))
                    onActivated: index => displayConfig.setRefreshRate(displaysSection.current, model[index].value)
                }
            }

            ContentSubsection {
                visible: displaysSection.active
                title: Translation.tr("Display orientation")

                ConfigSelectionArray {
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

            ContentSubsection {
                visible: displaysSection.active && (displaysSection.current?.scaleSupported ?? false)
                title: Translation.tr("Scale")

                StyledComboBox {
                    enabled: !displaysSection.busy
                    textRole: "displayName"
                    model: displayConfig.scaleOptions(displaysSection.current)
                    currentIndex: Math.max(0, model.findIndex(option => option.value === displaysSection.current?.scale))
                    onActivated: index => displayConfig.setScale(displaysSection.current, model[index].value)
                }
            }
        }

        ContentSubsection {
            visible: displaysSection.active && (displaysSection.current?.hdrSupported ?? false)
            title: Translation.tr("HDR & Color Management")

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

            NoticeBox {
                Layout.fillWidth: true
                visible: displaysSection.current?.hdrLimited ?? false
                text: Translation.tr("Windows is limiting HDR on this display right now, for example to save battery.")
            }

            ConfigSlider {
                id: sdrBrightnessSlider
                visible: (displaysSection.current?.hdrEnabled ?? false) && (displaysSection.current?.sdrBrightnessSupported ?? false)
                buttonIcon: "brightness_6"
                text: Translation.tr("SDR content brightness")
                textWidth: 180
                from: 80
                to: 480
                value: displaysSection.current?.sdrBrightness ?? 80
                onMoved: sdrBrightnessTimer.restart()

                Timer {
                    id: sdrBrightnessTimer
                    interval: 120
                    onTriggered: displayConfig.setSdrBrightness(displaysSection.current, sdrBrightnessSlider.value)
                }
            }
        }

        NoticeBox {
            Layout.fillWidth: true
            visible: displayConfig.available
            text: Translation.tr("Color profiles, Night light and HDR calibration are in Windows Settings.")

            Item {
                Layout.fillWidth: true
            }
            RippleButtonWithIcon {
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
        icon: "select_window"
        title: Translation.tr("Windows")
    }

    ContentSection {
        icon: "keyboard"
        title: Translation.tr("Input")

        ContentSubsection {
            title: Translation.tr("Keyboard")

            ContentSubsection {
                title: Translation.tr("Repeat delay")
                ConfigSelectionArray {
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

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                OptionalMaterialSymbol {
                    icon: "keyboard"
                    iconSize: Appearance.font.pixelSize.larger
                }
                StyledText {
                    text: Translation.tr("Keyboard layout")
                    color: Appearance.colors.colOnSecondaryContainer
                }
                StyledComboBox {
                    id: kbLayoutSelector
                    textRole: "displayName"
                    enabled: (WindowsNative.keyboard?.layoutCodes?.length ?? 0) > 0
                    model: (WindowsNative.keyboard?.layoutCodes ?? []).map(code => ({ displayName: code, value: code }))
                    currentIndex: {
                        const codes = WindowsNative.keyboard?.layoutCodes ?? [];
                        const idx = codes.indexOf(WindowsNative.keyboard?.currentLayoutCode ?? "");
                        return idx !== -1 ? idx : 0;
                    }
                    onActivated: index => {
                        const codes = WindowsNative.keyboard?.layoutCodes ?? [];
                        if (codes[index] && WindowsNative.keyboard) WindowsNative.keyboard.activateLayout(codes[index]);
                    }
                }
            }
            NoticeBox {
                Layout.fillWidth: true
                text: Translation.tr("To add or remove keyboard layouts, use Windows Settings > Time & Language > Language")
            }
        }

        ContentSubsection {
            title: Translation.tr("Mouse")

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

        ContentSubsection {
            title: Translation.tr("Touchpad")
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
            ContentSubsection {
                title: Translation.tr("Sensitivity")
                enabled: WindowsNative.inputSettings?.touchpadEnabled ?? true
                ConfigSelectionArray {
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
            title: Translation.tr("Cursor")

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                OptionalMaterialSymbol {
                    icon: "mouse"
                    iconSize: Appearance.font.pixelSize.larger
                }
                StyledText {
                    text: Translation.tr("Cursor scheme")
                    color: Appearance.colors.colOnSecondaryContainer
                }
                StyledComboBox {
                    id: cursorSchemeSelector
                    textRole: "displayName"
                    model: (WindowsNative.inputSettings?.cursorSchemeNames ?? []).map(name => ({ displayName: name, value: name }))
                    currentIndex: {
                        const names = WindowsNative.inputSettings?.cursorSchemeNames ?? [];
                        const idx = names.indexOf(WindowsNative.inputSettings?.cursorSchemeName ?? "");
                        return idx !== -1 ? idx : 0;
                    }
                    onActivated: index => {
                        const names = WindowsNative.inputSettings?.cursorSchemeNames ?? [];
                        if (names[index] && WindowsNative.inputSettings) WindowsNative.inputSettings.setCursorScheme(names[index]);
                    }
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

    ContentSection {
        icon: "bedtime"
        title: Translation.tr("Idle")
    }

    ContentSection {
        icon: "rocket_launch"
        title: Translation.tr("Autostart")
    }

    ContentSection {
        icon: "animation"
        title: Translation.tr("Animations")

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

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
            icon: "select_window"
            shape: W.MaterialShape.Shape.Gem
            title: Translation.tr("Windows")
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

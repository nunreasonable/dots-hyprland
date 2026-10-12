import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets as W
import qs.modules.common.functions
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

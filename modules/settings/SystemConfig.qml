import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    forceWidth: true

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
        onAccepted: addAutostartApp(FileUtils.trimFileProtocol(selectedFile.toString()), "")
    }

    ContentSection {
        icon: "monitor"
        title: Translation.tr("Displays")
    }

    ContentSection {
        id: windowsSection
        icon: "select_window"
        title: Translation.tr("Windows")

        readonly property bool dwmDecorations: parseInt(SystemInfo.windowsBuild) >= 22000
        readonly property var borderColorRoles: ["primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer", "layer0Border"]

        NoticeBox {
            Layout.fillWidth: true
            visible: !Config.options.windowsPort.tiling.enable
            text: Translation.tr("The layout options apply while tiling is on (Interface > Windows tiling).")
        }

        ContentSubsection {
            title: Translation.tr("Tiling Layout")
            ConfigSelectionArray {
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
            visible: Config.options.hyprland.general.layout !== "master"
            title: Translation.tr("Dwindle")

            ConfigSwitch {
                buttonIcon: "smart_toy"
                text: Translation.tr("Smart split (follow the cursor)")
                checked: Config.options.windowsPort.tiling.smartSplit
                onCheckedChanged: {
                    if (checked !== Config.options.windowsPort.tiling.smartSplit)
                        Config.options.windowsPort.tiling.smartSplit = checked;
                }
                StyledToolTip {
                    text: Translation.tr("A new window takes the side of the focused window the cursor is closest to, and splits keep their direction.")
                }
            }

            ContentSubsection {
                title: Translation.tr("Force split side")
                enabled: !Config.options.windowsPort.tiling.smartSplit
                ConfigSelectionArray {
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

        ContentSubsection {
            visible: Config.options.hyprland.general.layout === "master"
            title: Translation.tr("Master")

            ContentSubsection {
                title: Translation.tr("New windows become")
                ConfigSelectionArray {
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

            ContentSubsection {
                title: Translation.tr("Master position")
                ConfigSelectionArray {
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

        ContentSubsection {
            visible: windowsSection.dwmDecorations
            title: Translation.tr("Window borders")
            ConfigSelectionArray {
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
        }

        ContentSubsection {
            visible: windowsSection.dwmDecorations && Config.options.hyprland.general.borderSize > 0 && Config.options.hyprland.general.borderColor.enable
            title: Translation.tr("Border Color Management")

            ColorSelectionArray {
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
            ColorSelectionArray {
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

        ContentSubsection {
            visible: windowsSection.dwmDecorations
            title: Translation.tr("Window corners")
            ConfigSelectionArray {
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

        ContentSubsection {
            title: Translation.tr("Workspaces")

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
                StyledToolTip {
                    text: Translation.tr("After a workspace switch from a shortcut, the cursor jumps to the focused window. Not when the switch came from a click on the bar or the overview.")
                }
            }
        }
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
                        return idx;
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
                    model: (WindowsNative.inputSettings?.cursorSchemeNames ?? []).map((name, i) => ({ displayName: WindowsNative.inputSettings?.cursorSchemeLabels[i] ?? name, value: name }))
                    currentIndex: {
                        const names = WindowsNative.inputSettings?.cursorSchemeNames ?? [];
                        const idx = names.indexOf(WindowsNative.inputSettings?.cursorSchemeName ?? "");
                        return idx;
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

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Apps that launch automatically when you sign in.")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledComboBox {
                id: autostartAppPicker
                Layout.fillWidth: true
                textRole: "label"
                model: autostartAppOptions
                displayText: currentIndex >= 0 ? currentText : Translation.tr("Pick an app…")
            }

            RippleButton {
                implicitWidth: 44
                implicitHeight: 40
                buttonRadius: Appearance.rounding.normal
                enabled: autostartAppPicker.currentIndex >= 0
                colBackground: Appearance.colors.colSecondaryContainer
                colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                colRipple: Appearance.colors.colSecondaryContainerActive
                onClicked: {
                    const opt = autostartAppOptions[autostartAppPicker.currentIndex];
                    if (opt) addAutostartApp(opt.value, opt.label);
                    autostartAppPicker.currentIndex = -1;
                }
                contentItem: MaterialSymbol {
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "add"
                    iconSize: 20
                    color: Appearance.colors.colOnSecondaryContainer
                }
                StyledToolTip {
                    text: Translation.tr("Add to startup")
                }
            }

            RippleButton {
                implicitWidth: 44
                implicitHeight: 40
                buttonRadius: Appearance.rounding.normal
                colBackground: Appearance.colors.colLayer1
                colBackgroundHover: Appearance.colors.colLayer1Hover
                colRipple: Appearance.colors.colLayer1Active
                onClicked: autostartFileDialog.open()
                contentItem: MaterialSymbol {
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "folder_open"
                    iconSize: 20
                    color: Appearance.colors.colOnLayer1
                }
                StyledToolTip {
                    text: Translation.tr("Browse for a file")
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: autostartEntries.length === 0
            text: Translation.tr("No startup apps found")
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.small
        }

        Repeater {
            model: autostartEntries

            delegate: RowLayout {
                id: autostartRow
                required property var modelData
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 10

                StyledSwitch {
                    checked: autostartRow.modelData.enabled
                    enabled: autostartRow.modelData.scope === "user"
                    onToggled: WindowsNative.autostart?.setEnabled(autostartRow.modelData.id, checked)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    RowLayout {
                        spacing: 6
                        StyledText {
                            text: autostartRow.modelData.name
                            color: Appearance.colors.colOnLayer1
                            elide: Text.ElideRight
                        }
                        StyledText {
                            visible: autostartRow.modelData.isSelf
                            text: Translation.tr("(ii-windows)")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                        StyledText {
                            visible: autostartRow.modelData.scope === "machine"
                            text: Translation.tr("(all users)")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: autostartRow.modelData.command
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideRight
                    }
                }

                RippleButton {
                    id: autostartRemoveButton
                    visible: autostartRow.modelData.removable
                    implicitWidth: 36
                    implicitHeight: 36
                    buttonRadius: 18
                    colBackground: "transparent"
                    colBackgroundHover: Qt.rgba(1, 1, 1, 0.12)
                    colRipple: Qt.rgba(1, 1, 1, 0.2)
                    onClicked: autostartRemovePopup.open()
                    contentItem: MaterialSymbol {
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "delete"
                        iconSize: 20
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledToolTip {
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
                            StyledText {
                                Layout.maximumWidth: 240
                                wrapMode: Text.Wrap
                                text: Translation.tr("Remove \"%1\" from startup?").arg(autostartRow.modelData.name)
                            }
                            RowLayout {
                                Layout.alignment: Qt.AlignRight
                                DialogButton {
                                    buttonText: Translation.tr("Cancel")
                                    onClicked: autostartRemovePopup.close()
                                }
                                DialogButton {
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

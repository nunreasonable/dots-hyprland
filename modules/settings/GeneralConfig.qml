import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    Process {
        id: translationProc
        property string locale: ""
        command: [Directories.aiTranslationScriptPath, translationProc.locale]
    }

    ContentSection {
        icon: "palette"
        title: Translation.tr("Appearance")

        ConfigSwitch {
            buttonIcon: "format_color_fill"
            text: Translation.tr("Extra background tint")
            checked: Config.options.appearance.extraBackgroundTint
            onCheckedChanged: {
                Config.options.appearance.extraBackgroundTint = checked;
            }
            StyledToolTip {
                text: Translation.tr("Mixes a touch of the accent color into panel backgrounds instead of a flat tone")
            }
        }

        ContentSubsection {
            title: Translation.tr("Transparency")
            tooltip: Translation.tr("The values below are ignored while Automatic is on")

            ConfigSwitch {
                buttonIcon: "auto_fix_high"
                text: Translation.tr("Automatic")
                checked: Config.options.appearance.transparency.automatic
                onCheckedChanged: {
                    Config.options.appearance.transparency.automatic = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Derives transparency from your wallpaper instead of the sliders below")
                }
            }
            ConfigRow {
                uniform: true
                enabled: !Config.options.appearance.transparency.automatic
                ConfigSlider {
                    buttonIcon: "wallpaper"
                    text: Translation.tr("Background")
                    value: Config.options.appearance.transparency.backgroundTransparency
                    from: 0
                    to: 1
                    stopIndicatorValues: [0.11]
                    onValueChanged: {
                        Config.options.appearance.transparency.backgroundTransparency = value;
                    }
                }
                ConfigSlider {
                    buttonIcon: "widgets"
                    text: Translation.tr("Panel content")
                    value: Config.options.appearance.transparency.contentTransparency
                    from: 0
                    to: 1
                    stopIndicatorValues: [0.57]
                    onValueChanged: {
                        Config.options.appearance.transparency.contentTransparency = value;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Accent color override")
            tooltip: Translation.tr("Hex color like #a7c0ff. Leave empty to use a color extracted from the wallpaper")
            visible: Platform.isWindows

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Accent color (hex)")
                text: Config.options.appearance.palette.accentColor
                wrapMode: TextEdit.Wrap
                onEditingFinished: {
                    const value = text.trim();
                    if (value === Config.options.appearance.palette.accentColor)
                        return;
                    if (value === "")
                        Wallpapers.setAccentColor("clear");
                    else if (/^#?[0-9a-fA-F]{6}$/.test(value))
                        Wallpapers.setAccentColor(value);
                }
            }
        }
    }

    ContentSection {
        icon: "volume_up"
        title: Translation.tr("Audio")

        ConfigSwitch {
            buttonIcon: "hearing"
            text: Translation.tr("Earbang protection")
            checked: Config.options.audio.protection.enable
            onCheckedChanged: {
                Config.options.audio.protection.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Prevents abrupt increments and restricts volume limit")
            }
        }
        ConfigRow {
            enabled: Config.options.audio.protection.enable
            ConfigSpinBox {
                icon: "arrow_warm_up"
                text: Translation.tr("Max allowed increase")
                value: Config.options.audio.protection.maxAllowedIncrease
                from: 0
                to: 100
                stepSize: 2
                onValueChanged: {
                    Config.options.audio.protection.maxAllowedIncrease = value;
                }
            }
            ConfigSpinBox {
                icon: "vertical_align_top"
                text: Translation.tr("Volume limit")
                value: Config.options.audio.protection.maxAllowed
                from: 0
                to: 154 // pavucontrol allows up to 153%
                stepSize: 2
                onValueChanged: {
                    Config.options.audio.protection.maxAllowed = value;
                }
            }
        }
    }

    ContentSection {
        icon: "battery_android_full"
        title: Translation.tr("Battery")

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "warning"
                text: Translation.tr("Low warning")
                value: Config.options.battery.low
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.low = value;
                }
            }
            ConfigSpinBox {
                icon: "dangerous"
                text: Translation.tr("Critical warning")
                value: Config.options.battery.critical
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.critical = value;
                }
            }
        }
        ConfigRow {
            uniform: false
            Layout.fillWidth: false
            ConfigSwitch {
                buttonIcon: "pause"
                text: Translation.tr("Automatic suspend")
                checked: Config.options.battery.automaticSuspend
                onCheckedChanged: {
                    Config.options.battery.automaticSuspend = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Automatically suspends the system when battery is low")
                }
            }
            ConfigSpinBox {
                enabled: Config.options.battery.automaticSuspend
                text: Translation.tr("at")
                value: Config.options.battery.suspend
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.suspend = value;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "charger"
                text: Translation.tr("Full warning")
                value: Config.options.battery.full
                from: 0
                to: 101
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.full = value;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Bluetooth peripherals")
            tooltip: Translation.tr("Warns when a paired Bluetooth device's own battery is running low.")

            ConfigSwitch {
                buttonIcon: "notifications"
                text: Translation.tr("Notify on low peripheral battery")
                checked: Config.options.battery.peripheralNotify
                onCheckedChanged: {
                    Config.options.battery.peripheralNotify = checked;
                }
            }
            ConfigRow {
                uniform: true
                enabled: Config.options.battery.peripheralNotify
                ConfigSpinBox {
                    icon: "warning"
                    text: Translation.tr("Low warning")
                    value: Config.options.battery.peripheralLow
                    from: 0
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.options.battery.peripheralLow = value;
                    }
                }
                ConfigSpinBox {
                    icon: "dangerous"
                    text: Translation.tr("Critical warning")
                    value: Config.options.battery.peripheralCritical
                    from: 0
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.options.battery.peripheralCritical = value;
                    }
                }
            }
        }
    }

    Loader {
        Layout.fillWidth: true
        active: !Platform.isWindows
        visible: active
        sourceComponent: ContentSection {
            icon: "apps"
            title: Translation.tr("External apps")

            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Bluetooth settings")
                    text: Config.options.apps.bluetooth
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.apps.bluetooth = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Wi-Fi settings")
                    text: Config.options.apps.network
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.apps.network = text;
                    }
                }
            }
            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Ethernet settings")
                    text: Config.options.apps.networkEthernet
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.apps.networkEthernet = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Manage user accounts")
                    text: Config.options.apps.manageUser
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.apps.manageUser = text;
                    }
                }
            }
            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Task manager")
                    text: Config.options.apps.taskManager
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.apps.taskManager = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Terminal (for shell actions)")
                    text: Config.options.apps.terminal
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.apps.terminal = text;
                    }
                }
            }
            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("System update")
                    text: Config.options.apps.update
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.apps.update = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Volume mixer")
                    text: Config.options.apps.volumeMixer
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.apps.volumeMixer = text;
                    }
                }
            }
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Change password")
                text: Config.options.apps.changePassword
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.apps.changePassword = text;
                }
            }
        }
    }

    ContentSection {
        icon: "language"
        title: Translation.tr("Language")

        ContentSubsection {
            title: Translation.tr("Interface Language")
            tooltip: Translation.tr("Select the language for the user interface.\n\"Auto\" will use your system's locale.")

            StyledComboBox {
                id: languageSelector
                buttonIcon: "language"
                textRole: "displayName"

                model: [
                    {
                        displayName: Translation.tr("Auto (System)"),
                        value: "auto"
                    },
                    ...Translation.allAvailableLanguages.map(lang => {
                        return {
                            displayName: lang,
                            value: lang
                        };
                    })]

                currentIndex: {
                    const index = model.findIndex(item => item.value === Config.options.language.ui);
                    return index !== -1 ? index : 0;
                }

                onActivated: index => {
                    Config.options.language.ui = model[index].value;
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Generate translation with Gemini")
            tooltip: Translation.tr("You'll need to enter your Gemini API key first.\nType /key on the sidebar for instructions.")

            ConfigRow {
                MaterialTextArea {
                    id: localeInput
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Locale code, e.g. fr_FR, de_DE, zh_CN...")
                    text: Config.options.language.ui === "auto" ? Qt.locale().name : Config.options.language.ui
                }
                RippleButtonWithIcon {
                    id: generateTranslationBtn
                    Layout.fillHeight: true
                    nerdIcon: ""
                    enabled: !translationProc.running || (translationProc.locale !== localeInput.text.trim())
                    mainText: enabled ? Translation.tr("Generate\nTypically takes 2 minutes") : Translation.tr("Generating...\nDon't close this window!")
                    onClicked: {
                        if (Platform.isWindows) {
                            Notifications.sendDesktop(
                                Translation.tr("Generate translation with Gemini"),
                                Translation.tr("Not available on Windows yet"),
                                ["-a", "Shell"]
                            );
                            return;
                        }
                        translationProc.locale = localeInput.text.trim();
                        translationProc.running = false;
                        translationProc.running = true;
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "rule"
        title: Translation.tr("Policies")

        ConfigRow {

            // AI policy
            ColumnLayout {
                ContentSubsectionLabel {
                    text: Translation.tr("AI")
                }

                ConfigSelectionArray {
                    currentValue: Config.options.policies.ai
                    onSelected: newValue => {
                        Config.options.policies.ai = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Local only"),
                            icon: "sync_saved_locally",
                            value: 2
                        }
                    ]
                }
            }

            // Weeb policy
            ColumnLayout {

                ContentSubsectionLabel {
                    text: Translation.tr("Weeb")
                }

                ConfigSelectionArray {
                    currentValue: Config.options.policies.weeb
                    onSelected: newValue => {
                        Config.options.policies.weeb = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Closet"),
                            icon: "ev_shadow",
                            value: 2
                        }
                    ]
                }
            }
        }
    }

    ContentSection {
        icon: "notification_sound"
        title: Translation.tr("Sounds")
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "battery_android_full"
                text: Translation.tr("Battery")
                checked: Config.options.sounds.battery
                onCheckedChanged: {
                    Config.options.sounds.battery = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "av_timer"
                text: Translation.tr("Pomodoro")
                checked: Config.options.sounds.pomodoro
                onCheckedChanged: {
                    Config.options.sounds.pomodoro = checked;
                }
            }
        }
    }

    ContentSection {
        icon: "nest_clock_farsight_analog"
        title: Translation.tr("Time")

        ConfigSwitch {
            buttonIcon: "pace"
            text: Translation.tr("Second precision")
            checked: Config.options.time.secondPrecision
            onCheckedChanged: {
                Config.options.time.secondPrecision = checked;
            }
            StyledToolTip {
                text: Translation.tr("Enable if you want clocks to show seconds accurately")
            }
        }

        ContentSubsection {
            title: Translation.tr("Format")
            tooltip: ""

            ConfigSelectionArray {
                currentValue: Config.options.time.format
                onSelected: newValue => {
                    if (Platform.isWindows) {
                    } else if (newValue === "hh:mm") {
                        Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME12\\b/TIME/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                    } else {
                        Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME\\b/TIME12/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                    }

                    Config.options.time.format = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("24h"),
                        value: "hh:mm"
                    },
                    {
                        displayName: Translation.tr("12h am/pm"),
                        value: "h:mm ap"
                    },
                    {
                        displayName: Translation.tr("12h AM/PM"),
                        value: "h:mm AP"
                    },
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Date formats")
            tooltip: Translation.tr("Qt date format tokens, e.g. dd/MM/yyyy or ddd for the weekday name.\nSee doc.qt.io/qt-6/qtime.html#toString for the full list")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Short date")
                text: Config.options.time.shortDateFormat
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.time.shortDateFormat = text;
                }
            }
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Date with year")
                text: Config.options.time.dateWithYearFormat
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.time.dateWithYearFormat = text;
                }
            }
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Long date")
                text: Config.options.time.dateFormat
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.time.dateFormat = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Pomodoro")
            tooltip: Translation.tr("Focus and break durations, in minutes")

            ConfigRow {
                uniform: true
                ConfigSpinBox {
                    icon: "timer"
                    text: Translation.tr("Focus (min)")
                    value: Math.round(Config.options.time.pomodoro.focus / 60)
                    from: 5
                    to: 120
                    stepSize: 5
                    onValueChanged: {
                        Config.options.time.pomodoro.focus = value * 60;
                    }
                }
                ConfigSpinBox {
                    icon: "free_breakfast"
                    text: Translation.tr("Short break (min)")
                    value: Math.round(Config.options.time.pomodoro.breakTime / 60)
                    from: 1
                    to: 60
                    stepSize: 1
                    onValueChanged: {
                        Config.options.time.pomodoro.breakTime = value * 60;
                    }
                }
            }
            ConfigRow {
                uniform: true
                ConfigSpinBox {
                    icon: "self_improvement"
                    text: Translation.tr("Long break (min)")
                    value: Math.round(Config.options.time.pomodoro.longBreak / 60)
                    from: 1
                    to: 60
                    stepSize: 1
                    onValueChanged: {
                        Config.options.time.pomodoro.longBreak = value * 60;
                    }
                }
                ConfigSpinBox {
                    icon: "repeat"
                    text: Translation.tr("Cycles before long break")
                    value: Config.options.time.pomodoro.cyclesBeforeLongBreak
                    from: 1
                    to: 10
                    stepSize: 1
                    onValueChanged: {
                        Config.options.time.pomodoro.cyclesBeforeLongBreak = value;
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "bug_report"
        title: Translation.tr("Troubleshooting")

        ContentSubsection {
            title: Translation.tr("Race condition delay")
            tooltip: Translation.tr("Delay in milliseconds some UI code waits before refreshing to avoid a timing race.\nOnly raise it if menus or lists show stale content; higher values make them feel slower to update")

            ConfigSpinBox {
                icon: "hourglass_bottom"
                text: Translation.tr("Delay (ms)")
                value: Config.options.hacks.arbitraryRaceConditionDelay
                from: 0
                to: 500
                stepSize: 5
                onValueChanged: {
                    Config.options.hacks.arbitraryRaceConditionDelay = value;
                }
            }
        }
    }

    ContentSection {
        icon: "work_alert"
        title: Translation.tr("Work safety")

        ConfigSwitch {
            buttonIcon: "assignment"
            text: Translation.tr("Hide clipboard images copied from sussy sources")
            checked: Config.options.workSafety.enable.clipboard
            onCheckedChanged: {
                Config.options.workSafety.enable.clipboard = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "wallpaper"
            text: Translation.tr("Hide sussy/anime wallpapers")
            checked: Config.options.workSafety.enable.wallpaper
            onCheckedChanged: {
                Config.options.workSafety.enable.wallpaper = checked;
            }
        }
    }
}

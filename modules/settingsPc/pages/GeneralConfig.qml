import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets as W
import qs.modules.settingsPc.widgets

ContentPage {
    id: page
    forceWidth: true

    Process {
        id: translationProc
        property string locale: ""
        command: [Directories.aiTranslationScriptPath, translationProc.locale]
    }

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            icon: "palette"
            shape: W.MaterialShape.Shape.Pentagon
            title: Translation.tr("Appearance")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "format_color_fill"
                    text: Translation.tr("Extra background tint")
                    checked: Config.options.appearance.extraBackgroundTint
                    onCheckedChanged: {
                        Config.options.appearance.extraBackgroundTint = checked;
                    }
                    W.StyledToolTip {
                        text: Translation.tr("Mixes a touch of the accent color into panel backgrounds instead of a flat tone")
                    }
                }
            }

            ContentSubsection {
                visible: Platform.isWindows
                title: Translation.tr("Accent color override")
                tooltip: Translation.tr("Hex color like #a7c0ff. Leave empty to use a color extracted from the wallpaper")

                GroupedList {
                    ConfigTextArea {
                        id: accentColorField
                        Layout.fillWidth: true
                        buttonIcon: "colorize"
                        text: Translation.tr("Accent color (hex)")
                        placeholderText: "#a7c0ff"
                        value: Config.options.appearance.palette.accentColor
                        onEditingFinished: {
                            const value = accentColorField.value.trim();
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
        }

        ContentSection {
            icon: "nest_clock_farsight_analog"
            shape: W.MaterialShape.Shape.Bun
            title: Translation.tr("Time")

            Rectangle {
                id: previewCard
                Layout.fillWidth: true
                implicitHeight: 180
                radius: Appearance.rounding.normal
                clip: true
                color: Appearance.colors.colLayer1

                property date now: new Date()

                Timer {
                    interval: Config.options.time.secondPrecision ? 1000 : 15000
                    running: previewCard.visible
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: previewCard.now = new Date()
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16

                    ColumnLayout {
                        W.StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            font.family: Appearance.font.family.expressive
                            font.pixelSize: 42
                            font.letterSpacing: 1
                            font.features: { "tnum": 1 }
                            font.weight: Font.Medium
                            color: Appearance.colors.colPrimary
                            text: {
                                const fmt = Config.options.time.format;
                                if (Config.options.time.secondPrecision) {
                                    if (fmt === "hh:mm") return Qt.formatTime(previewCard.now, "hh:mm:ss");
                                    if (fmt === "h:mm ap") return Qt.formatTime(previewCard.now, "h:mm:ss ap");
                                    if (fmt === "h:mm AP") return Qt.formatTime(previewCard.now, "h:mm:ss AP");
                                }
                                return Qt.formatTime(previewCard.now, fmt);
                            }
                        }
                        W.StyledText {
                            Layout.fillWidth: true
                            text: DateTime.longDate
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: 32
                            font.weight: Font.Normal
                            opacity: 0.6
                            color: Appearance.colors.colPrimary
                            elide: Text.ElideRight
                        }
                    }

                    AndroidClock {
                        Layout.rightMargin: 6
                        Layout.preferredWidth: 130
                        Layout.preferredHeight: 130
                        backgroundColor: Appearance.colors.colPrimaryContainer
                        handColor:       Appearance.colors.colPrimary
                        centerDotColor:  Appearance.colors.colPrimary
                    }
                }
            }

            GroupedList {
                Layout.topMargin: -2
                ConfigSelectionArray {
                    text: Translation.tr("Format")
                    icon: "schedule"
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
                        { displayName: Translation.tr("24h"), value: "hh:mm" },
                        { displayName: Translation.tr("12h am/pm"), value: "h:mm ap" },
                        { displayName: Translation.tr("12h AM/PM"), value: "h:mm AP" }
                    ]
                }
                ConfigSwitch {
                    buttonIcon: "pace"
                    text: Translation.tr("Second precision")
                    checked: Config.options.time.secondPrecision
                    onCheckedChanged: {
                        Config.options.time.secondPrecision = checked;
                    }
                    W.StyledToolTip {
                        text: Translation.tr("Enable if you want clocks to show seconds accurately")
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Date formats")
                tooltip: Translation.tr("Qt date format tokens, e.g. dd/MM/yyyy or ddd for the weekday name.\nSee doc.qt.io/qt-6/qtime.html#toString for the full list")

                GroupedList {
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "today"
                        text: Translation.tr("Short date")
                        placeholderText: "dd/MM"
                        value: Config.options.time.shortDateFormat
                        onValueChanged: {
                            Config.options.time.shortDateFormat = value;
                        }
                    }
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "calendar_today"
                        text: Translation.tr("Date with year")
                        placeholderText: "dd/MM/yyyy"
                        value: Config.options.time.dateWithYearFormat
                        onValueChanged: {
                            Config.options.time.dateWithYearFormat = value;
                        }
                    }
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "calendar_month"
                        text: Translation.tr("Long date")
                        placeholderText: "ddd, dd/MM"
                        value: Config.options.time.dateFormat
                        onValueChanged: {
                            Config.options.time.dateFormat = value;
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Pomodoro")
                tooltip: Translation.tr("Focus and break durations, in minutes")

                GroupedList {
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
        }

        ContentSection {
            icon: "battery_android_full"
            shape: W.MaterialShape.Shape.SemiCircle
            title: Translation.tr("Battery")

            GroupedList {
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
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "pause"
                        text: Translation.tr("Automatic suspend")
                        checked: Config.options.battery.automaticSuspend
                        onCheckedChanged: {
                            Config.options.battery.automaticSuspend = checked;
                        }
                        W.StyledToolTip {
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
            }
        }

        ContentSection {
            icon: "volume_up"
            shape: W.MaterialShape.Shape.Circle
            title: Translation.tr("Audio")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "hearing"
                    text: Translation.tr("Earbang protection")
                    checked: Config.options.audio.protection.enable
                    onCheckedChanged: {
                        Config.options.audio.protection.enable = checked;
                    }
                    W.StyledToolTip {
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
                        to: 154
                        stepSize: 2
                        onValueChanged: {
                            Config.options.audio.protection.maxAllowed = value;
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "notification_sound"
            shape: W.MaterialShape.Shape.Clover8Leaf
            title: Translation.tr("Sounds")
            GroupedList {
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
            icon: "language"
            shape: W.MaterialShape.Shape.Gem
            title: Translation.tr("Language")
            hint: Translation.tr("Select the language for the user interface.\n\"Auto\" will use your system's locale.")

            GroupedList {
                ConfigComboBox {
                    Layout.fillWidth: true
                    buttonIcon: "language"
                    text: Translation.tr("Interface Language")
                    fieldWidth: 240
                    model: [
                        { displayName: Translation.tr("Auto (System)"), value: "auto" },
                        ...Translation.allAvailableLanguages.map(lang => ({ displayName: lang, value: lang }))
                    ]
                    currentValue: Config.options.language.ui
                    onSelected: newValue => {
                        Config.options.language.ui = newValue;
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Generate translation with Gemini")
                tooltip: Translation.tr("You'll need to enter your Gemini API key first.\nType /key on the sidebar for instructions.")

                GroupedList {
                    ColumnLayout {
                        id: translationCol
                        Layout.fillWidth: true
                        spacing: 8

                        ConfigTextArea {
                            id: localeField
                            Layout.fillWidth: true
                            buttonIcon: "translate"
                            text: Translation.tr("Locale code")
                            placeholderText: Translation.tr("e.g. fr_FR, de_DE, zh_CN...")
                            value: Config.options.language.ui === "auto" ? Qt.locale().name : Config.options.language.ui
                        }

                        W.RippleButtonWithIcon {
                            id: generateTranslationBtn
                            Layout.fillWidth: false
                            Layout.alignment: Qt.AlignRight
                            Layout.preferredHeight: 50
                            Layout.rightMargin: 8
                            nerdIcon: ""
                            enabled: !translationProc.running || (translationProc.locale !== localeField.value.trim())
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
                                translationProc.locale = localeField.value.trim();
                                translationProc.running = false;
                                translationProc.running = true;
                            }
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
                shape: W.MaterialShape.Shape.Cookie7Sided
                title: Translation.tr("External apps")

                GroupedList {
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "bluetooth"
                        fieldWidth: 300
                        text: Translation.tr("Bluetooth settings")
                        value: Config.options.apps.bluetooth
                        onValueChanged: {
                            Config.options.apps.bluetooth = value;
                        }
                    }
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "wifi"
                        fieldWidth: 300
                        text: Translation.tr("Wi-Fi settings")
                        value: Config.options.apps.network
                        onValueChanged: {
                            Config.options.apps.network = value;
                        }
                    }
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "settings_ethernet"
                        fieldWidth: 300
                        text: Translation.tr("Ethernet settings")
                        value: Config.options.apps.networkEthernet
                        onValueChanged: {
                            Config.options.apps.networkEthernet = value;
                        }
                    }
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "manage_accounts"
                        fieldWidth: 300
                        text: Translation.tr("Manage user accounts")
                        value: Config.options.apps.manageUser
                        onValueChanged: {
                            Config.options.apps.manageUser = value;
                        }
                    }
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "browse_activity"
                        fieldWidth: 300
                        text: Translation.tr("Task manager")
                        value: Config.options.apps.taskManager
                        onValueChanged: {
                            Config.options.apps.taskManager = value;
                        }
                    }
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "terminal"
                        fieldWidth: 300
                        text: Translation.tr("Terminal (for shell actions)")
                        value: Config.options.apps.terminal
                        onValueChanged: {
                            Config.options.apps.terminal = value;
                        }
                    }
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "system_update_alt"
                        fieldWidth: 300
                        text: Translation.tr("System update")
                        value: Config.options.apps.update
                        onValueChanged: {
                            Config.options.apps.update = value;
                        }
                    }
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "volume_up"
                        fieldWidth: 300
                        text: Translation.tr("Volume mixer")
                        value: Config.options.apps.volumeMixer
                        onValueChanged: {
                            Config.options.apps.volumeMixer = value;
                        }
                    }
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "password"
                        fieldWidth: 300
                        text: Translation.tr("Change password")
                        value: Config.options.apps.changePassword
                        onValueChanged: {
                            Config.options.apps.changePassword = value;
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "bug_report"
            shape: W.MaterialShape.Shape.Arch
            title: Translation.tr("Troubleshooting")

            ContentSubsection {
                title: Translation.tr("Race condition delay")
                tooltip: Translation.tr("Delay in milliseconds some UI code waits before refreshing to avoid a timing race.\nOnly raise it if menus or lists show stale content; higher values make them feel slower to update")

                GroupedList {
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
        }

        ContentSection {
            icon: "work_alert"
            shape: W.MaterialShape.Shape.PuffyDiamond
            title: Translation.tr("Work safety")
            GroupedList {
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
    }
}

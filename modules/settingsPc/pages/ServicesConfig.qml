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
            icon: "neurology"
            shape: W.MaterialShape.Shape.Ghostish
            title: Translation.tr("AI")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("System prompt")
                text: Config.options.ai.systemPrompt
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Qt.callLater(() => {
                        Config.options.ai.systemPrompt = text;
                    });
                }
            }

            ContentSubsection {
                title: Translation.tr("Tool calling")
                tooltip: Translation.tr("Controls what the assistant can do besides chatting.\n\"Functions\" lets it search the web and read/edit the shell config.\n\"Search\" only lets it search the web. \"None\" disables both.")

                GroupedList {
                    ConfigSelectionArray {
                        currentValue: Config.options.ai.tool
                        onSelected: newValue => {
                            Config.options.ai.tool = newValue;
                        }
                        options: [
                            {
                                displayName: Translation.tr("Search"),
                                icon: "search",
                                value: "search"
                            },
                            {
                                displayName: Translation.tr("Functions"),
                                icon: "functions",
                                value: "functions"
                            },
                            {
                                displayName: Translation.tr("None"),
                                icon: "block",
                                value: "none"
                            }
                        ]
                    }
                    ConfigSwitch {
                        buttonIcon: "text_fields"
                        text: Translation.tr("Fade in sidebar response text")
                        checked: Config.options.sidebar.ai.textFadeIn
                        onCheckedChanged: {
                            Config.options.sidebar.ai.textFadeIn = checked;
                        }
                        W.StyledToolTip {
                            text: Translation.tr("Animates new text in the assistant's replies as it streams in, instead of showing it immediately.")
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "cell_tower"
            shape: W.MaterialShape.Shape.PixelCircle
            title: Translation.tr("Networking")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("User agent (for services that require it)")
                text: Config.options.networking.userAgent
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.networking.userAgent = text;
                }
            }
        }

        ContentSection {
            icon: "music_cast"
            shape: W.MaterialShape.Shape.Oval
            title: Translation.tr("Music Recognition")

            GroupedList {
                ConfigSpinBox {
                    icon: "timer_off"
                    text: Translation.tr("Total duration timeout (s)")
                    value: Config.options.musicRecognition.timeout
                    from: 10
                    to: 100
                    stepSize: 2
                    onValueChanged: {
                        Config.options.musicRecognition.timeout = value;
                    }
                }
                ConfigSpinBox {
                    icon: "av_timer"
                    text: Translation.tr("Polling interval (s)")
                    value: Config.options.musicRecognition.interval
                    from: 2
                    to: 10
                    stepSize: 1
                    onValueChanged: {
                        Config.options.musicRecognition.interval = value;
                    }
                }
            }
        }

        ContentSection {
            icon: "memory"
            shape: W.MaterialShape.Shape.Burst
            title: Translation.tr("Resources")

            GroupedList {
                ConfigSpinBox {
                    icon: "av_timer"
                    text: Translation.tr("Polling interval (ms)")
                    value: Config.options.resources.updateInterval
                    from: 100
                    to: 10000
                    stepSize: 100
                    onValueChanged: {
                        Config.options.resources.updateInterval = value;
                    }
                }
                ConfigSpinBox {
                    icon: "history"
                    text: Translation.tr("History length (samples)")
                    value: Config.options.resources.historyLength
                    from: 10
                    to: 500
                    stepSize: 10
                    onValueChanged: {
                        Config.options.resources.historyLength = value;
                    }
                }
            }
        }

        ContentSection {
            icon: "file_open"
            shape: W.MaterialShape.Shape.Slanted
            title: Translation.tr("Save paths")

            GroupedList {
                ConfigTextArea {
                    Layout.fillWidth: true
                    fieldWidth: 250
                    buttonIcon: "video_file"
                    text: Translation.tr("Video Recording Path")
                    value: Config.options.screenRecord.savePath
                    onValueChanged: {
                        Config.options.screenRecord.savePath = value;
                    }
                }

                ConfigTextArea {
                    Layout.fillWidth: true
                    fieldWidth: 250
                    buttonIcon: "screenshot_monitor"
                    text: Translation.tr("Screenshot Path (leave empty to just copy)")
                    value: Config.options.screenSnip.savePath
                    onValueChanged: {
                        Config.options.screenSnip.savePath = value;
                    }
                }
            }
        }

        ContentSection {
            icon: "search"
            shape: W.MaterialShape.Shape.Cookie6Sided
            title: Translation.tr("Search")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "manage_search"
                    text: Translation.tr("Spotlight search: Super opens search only, Super+Tab opens workspaces")
                    checked: Config.options.search.spotlight
                    onCheckedChanged: {
                        Config.options.search.spotlight = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "spellcheck"
                    text: Translation.tr("Use Levenshtein distance-based algorithm instead of fuzzy")
                    checked: Config.options.search.sloppy
                    onCheckedChanged: {
                        Config.options.search.sloppy = checked;
                    }
                    W.StyledToolTip {
                        text: Translation.tr("Could be better if you make a ton of typos,\nbut results can be weird and might not work with acronyms\n(e.g. \"GIMP\" might not give you the paint program)")
                    }
                }
                ConfigSwitch {
                    buttonIcon: "bolt"
                    text: Translation.tr("Show command, math, and web search results without a prefix")
                    checked: Config.options.search.prefix.showDefaultActionsWithoutPrefix
                    onCheckedChanged: {
                        Config.options.search.prefix.showDefaultActionsWithoutPrefix = checked;
                    }
                    W.StyledToolTip {
                        text: Translation.tr("When off, these results only show once you type their prefix below (e.g. $, =, ?).")
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Prefixes")

                GroupedList {
                    ConfigRow {
                        uniform: true
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "bolt"
                            fieldWidth: 100
                            text: Translation.tr("Action")
                            value: Config.options.search.prefix.action
                            onValueChanged: {
                                Config.options.search.prefix.action = value;
                            }
                        }
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "apps"
                            fieldWidth: 100
                            text: Translation.tr("App")
                            value: Config.options.search.prefix.app
                            onValueChanged: {
                                Config.options.search.prefix.app = value;
                            }
                        }
                    }

                    ConfigRow {
                        uniform: true
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "content_paste"
                            fieldWidth: 100
                            text: Translation.tr("Clipboard")
                            value: Config.options.search.prefix.clipboard
                            onValueChanged: {
                                Config.options.search.prefix.clipboard = value;
                            }
                        }
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "mood"
                            fieldWidth: 100
                            text: Translation.tr("Emojis")
                            value: Config.options.search.prefix.emojis
                            onValueChanged: {
                                Config.options.search.prefix.emojis = value;
                            }
                        }
                    }

                    ConfigRow {
                        uniform: true
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "keyboard_command_key"
                            fieldWidth: 100
                            text: Translation.tr("Keybinds")
                            value: Config.options.search.prefix.keybinds
                            onValueChanged: {
                                Config.options.search.prefix.keybinds = value;
                            }
                        }
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "emoji_symbols"
                            fieldWidth: 100
                            text: Translation.tr("Symbols")
                            value: Config.options.search.prefix.symbols
                            onValueChanged: {
                                Config.options.search.prefix.symbols = value;
                            }
                        }
                    }

                    ConfigRow {
                        uniform: true
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "calculate"
                            fieldWidth: 100
                            text: Translation.tr("Math")
                            value: Config.options.search.prefix.math
                            onValueChanged: {
                                Config.options.search.prefix.math = value;
                            }
                        }
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "terminal"
                            fieldWidth: 100
                            text: Translation.tr("Shell command")
                            value: Config.options.search.prefix.shellCommand
                            onValueChanged: {
                                Config.options.search.prefix.shellCommand = value;
                            }
                        }
                    }

                    ConfigRow {
                        uniform: true
                        ConfigTextArea {
                            Layout.fillWidth: true
                            fieldWidth: 100
                            buttonIcon: "travel_explore"
                            text: Translation.tr("Web search")
                            value: Config.options.search.prefix.webSearch
                            onValueChanged: {
                                Config.options.search.prefix.webSearch = value;
                            }
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Web search")

                GroupedList {
                    ConfigTextArea {
                        Layout.fillWidth: true
                        fieldWidth: 320
                        buttonIcon: "travel_explore"
                        text: Translation.tr("Base URL")
                        value: Config.options.search.engineBaseUrl
                        onValueChanged: {
                            Config.options.search.engineBaseUrl = value;
                        }
                    }
                    ConfigTextArea {
                        id: excludedSitesField
                        Layout.fillWidth: true
                        fieldWidth: 320
                        buttonIcon: "block"
                        text: Translation.tr("Excluded sites")
                        placeholderText: Translation.tr("e.g. quora.com, facebook.com")
                        value: Config.options.search.excludedSites.join(", ")
                        onEditingFinished: {
                            const items = excludedSitesField.value.split(",").map(s => s.trim()).filter(s => s.length > 0);
                            if (items.join(", ") !== Config.options.search.excludedSites.join(", "))
                                Config.options.search.excludedSites = items;
                        }
                        W.StyledToolTip {
                            text: Translation.tr("Comma-separated list of domains hidden from web search suggestions.")
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Image search")
                tooltip: Translation.tr("Used when searching the web for a screenshot or selection (reverse image search).")

                GroupedList {
                    ConfigTextArea {
                        Layout.fillWidth: true
                        fieldWidth: 320
                        buttonIcon: "image_search"
                        text: Translation.tr("Base URL")
                        value: Config.options.search.imageSearch.imageSearchEngineBaseUrl
                        onValueChanged: {
                            Config.options.search.imageSearch.imageSearchEngineBaseUrl = value;
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Non-app results")
                tooltip: Translation.tr("Delay before showing calculator, web search, and other non-app results. Prevents lag while typing.")

                GroupedList {
                    ConfigSpinBox {
                        icon: "timer"
                        text: Translation.tr("Delay (ms)")
                        value: Config.options.search.nonAppResultDelay
                        from: 0
                        to: 500
                        stepSize: 10
                        onValueChanged: {
                            Config.options.search.nonAppResultDelay = value;
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "weather_mix"
            shape: W.MaterialShape.Shape.Pill
            title: Translation.tr("Weather")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "assistant_navigation"
                    text: Translation.tr("Enable GPS based location")
                    checked: Config.options.bar.weather.enableGPS
                    onCheckedChanged: {
                        Config.options.bar.weather.enableGPS = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "thermometer"
                    text: Translation.tr("Fahrenheit unit")
                    checked: Config.options.bar.weather.useUSCS
                    onCheckedChanged: {
                        Config.options.bar.weather.useUSCS = checked;
                    }
                    W.StyledToolTip {
                        text: Translation.tr("It may take a few seconds to update")
                    }
                }
                ConfigSpinBox {
                    icon: "av_timer"
                    text: Translation.tr("Polling interval (m)")
                    value: Config.options.bar.weather.fetchInterval
                    from: 5
                    to: 50
                    stepSize: 5
                    onValueChanged: {
                        Config.options.bar.weather.fetchInterval = value;
                    }
                }
                ConfigTextArea {
                    Layout.fillWidth: true
                    buttonIcon: "location_city"
                    text: Translation.tr("City name")
                    value: Config.options.bar.weather.city
                    onValueChanged: {
                        Config.options.bar.weather.city = value;
                    }
                }
            }
        }

        ContentSection {
            icon: "translate"
            shape: W.MaterialShape.Shape.Gem
            title: Translation.tr("Translator")

            ContentSubsection {
                title: Translation.tr("Languages")
                tooltip: Translation.tr("Language codes like \"en\", \"pt\" or \"ja\". \"auto\" detects the source language.")

                GroupedList {
                    ConfigRow {
                        uniform: true
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "input"
                            fieldWidth: 100
                            text: Translation.tr("Source language")
                            value: Config.options.language.translator.sourceLanguage
                            onValueChanged: {
                                Config.options.language.translator.sourceLanguage = value;
                            }
                        }
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "output"
                            fieldWidth: 100
                            text: Translation.tr("Target language")
                            value: Config.options.language.translator.targetLanguage
                            onValueChanged: {
                                Config.options.language.translator.targetLanguage = value;
                            }
                        }
                    }
                    ConfigSpinBox {
                        icon: "av_timer"
                        text: Translation.tr("Request delay (ms)")
                        value: Config.options.sidebar.translator.delay
                        from: 0
                        to: 2000
                        stepSize: 50
                        onValueChanged: {
                            Config.options.sidebar.translator.delay = value;
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "bedtime"
            shape: W.MaterialShape.Shape.SemiCircle
            title: Translation.tr("Night light")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "schedule"
                    text: Translation.tr("Automatic")
                    checked: Config.options.light.night.automatic
                    onCheckedChanged: {
                        Config.options.light.night.automatic = checked;
                    }
                    W.StyledToolTip {
                        text: Translation.tr("Switches the warm color filter on and off automatically between the times below.")
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Schedule")
                tooltip: Translation.tr("Format: \"HH:mm\", 24-hour time")

                GroupedList {
                    ConfigRow {
                        uniform: true
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "wb_twilight"
                            fieldWidth: 100
                            text: Translation.tr("From")
                            placeholderText: "19:00"
                            value: Config.options.light.night.from
                            onValueChanged: {
                                Config.options.light.night.from = value;
                            }
                        }
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "wb_sunny"
                            fieldWidth: 100
                            text: Translation.tr("To")
                            placeholderText: "06:30"
                            value: Config.options.light.night.to
                            onValueChanged: {
                                Config.options.light.night.to = value;
                            }
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Color temperature")
                tooltip: Translation.tr("In Kelvin. Lower values look warmer/more orange.")

                GroupedList {
                    ConfigSpinBox {
                        icon: "thermostat"
                        text: Translation.tr("Temperature (K)")
                        value: Config.options.light.night.colorTemperature
                        from: 1200
                        to: 6500
                        stepSize: 100
                        onValueChanged: {
                            Config.options.light.night.colorTemperature = value;
                        }
                    }
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.topMargin: 4
                active: !Platform.isWindows
                visible: active
                sourceComponent: GroupedList {
                    ConfigSwitch {
                        buttonIcon: "flash_off"
                        text: Translation.tr("Anti-flashbang (experimental)")
                        checked: Config.options.light.antiFlashbang.enable
                        onCheckedChanged: {
                            Config.options.light.antiFlashbang.enable = checked;
                        }
                        W.StyledToolTip {
                            text: Translation.tr("Balances brightness based on screen content to avoid sudden brightness spikes.")
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "photo_library"
            shape: W.MaterialShape.Shape.Flower
            title: Translation.tr("Booru")

            GroupedList {
                ConfigSpinBox {
                    icon: "numbers"
                    text: Translation.tr("Images per request")
                    value: Config.options.sidebar.booru.limit
                    from: 1
                    to: 100
                    stepSize: 1
                    onValueChanged: {
                        Config.options.sidebar.booru.limit = value;
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Zerochan")
                tooltip: Translation.tr("Required by Zerochan's API to avoid being rate-limited or banned for anonymous requests.")

                GroupedList {
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "person"
                        text: Translation.tr("Zerochan username")
                        value: Config.options.sidebar.booru.zerochan.username
                        onValueChanged: {
                            Config.options.sidebar.booru.zerochan.username = value;
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
                icon: "volume_up"
                shape: W.MaterialShape.Shape.Clover8Leaf
                title: Translation.tr("Sounds")

                GroupedList {
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "music_note"
                        text: Translation.tr("Sound theme name (in /usr/share/sounds)")
                        value: Config.options.sounds.theme
                        onValueChanged: {
                            Config.options.sounds.theme = value;
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
                icon: "deployed_code_update"
                shape: W.MaterialShape.Shape.Cookie9Sided
                title: Translation.tr("Update thresholds")

                GroupedList {
                    ConfigSpinBox {
                        icon: "update"
                        text: Translation.tr("Advise update threshold (packages)")
                        value: Config.options.updates.adviseUpdateThreshold
                        from: 0
                        to: 1000
                        stepSize: 5
                        onValueChanged: {
                            Config.options.updates.adviseUpdateThreshold = value;
                        }
                    }
                    ConfigSpinBox {
                        icon: "update"
                        text: Translation.tr("Strongly advise threshold (packages)")
                        value: Config.options.updates.stronglyAdviseUpdateThreshold
                        from: 0
                        to: 2000
                        stepSize: 10
                        onValueChanged: {
                            Config.options.updates.stronglyAdviseUpdateThreshold = value;
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
                icon: "block"
                shape: W.MaterialShape.Shape.Diamond
                title: Translation.tr("Conflict killer")

                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "inbox_customize"
                        text: Translation.tr("Automatically kill conflicting tray daemons")
                        checked: Config.options.conflictKiller.autoKillTrays
                        onCheckedChanged: {
                            Config.options.conflictKiller.autoKillTrays = checked;
                        }
                        W.StyledToolTip {
                            text: Translation.tr("Silently kills kded6 when it conflicts with the shell's own system tray, instead of asking every time.")
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "notifications_off"
                        text: Translation.tr("Automatically kill conflicting notification daemons")
                        checked: Config.options.conflictKiller.autoKillNotificationDaemons
                        onCheckedChanged: {
                            Config.options.conflictKiller.autoKillNotificationDaemons = checked;
                        }
                        W.StyledToolTip {
                            text: Translation.tr("Silently kills mako/dunst when they conflict with the shell's own notifications, instead of asking every time.")
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "shield"
            shape: W.MaterialShape.Shape.PuffyDiamond
            title: Translation.tr("Work safety triggers")

            GroupedList {
                ConfigTextArea {
                    id: networkKeywordsField
                    Layout.fillWidth: true
                    fieldWidth: 260
                    buttonIcon: "wifi"
                    text: Translation.tr("Suspicious network names")
                    placeholderText: Translation.tr("e.g. airport, cafe, guest")
                    value: Config.options.workSafety.triggerCondition.networkNameKeywords.join(", ")
                    onEditingFinished: {
                        const items = networkKeywordsField.value.split(",").map(s => s.trim()).filter(s => s.length > 0);
                        if (items.join(", ") !== Config.options.workSafety.triggerCondition.networkNameKeywords.join(", "))
                            Config.options.workSafety.triggerCondition.networkNameKeywords = items;
                    }
                    W.StyledToolTip {
                        text: Translation.tr("Comma-separated keywords. If the current network name contains one, the \"Work safety\" hiding (in General settings) can trigger.")
                    }
                }
                ConfigTextArea {
                    id: fileKeywordsField
                    Layout.fillWidth: true
                    fieldWidth: 260
                    buttonIcon: "wallpaper"
                    text: Translation.tr("Suspicious wallpaper keywords")
                    placeholderText: Translation.tr("e.g. anime, booru, hentai")
                    value: Config.options.workSafety.triggerCondition.fileKeywords.join(", ")
                    onEditingFinished: {
                        const items = fileKeywordsField.value.split(",").map(s => s.trim()).filter(s => s.length > 0);
                        if (items.join(", ") !== Config.options.workSafety.triggerCondition.fileKeywords.join(", "))
                            Config.options.workSafety.triggerCondition.fileKeywords = items;
                    }
                    W.StyledToolTip {
                        text: Translation.tr("Comma-separated keywords. If the wallpaper file name contains one (together with a suspicious network), it gets hidden.")
                    }
                }
                ConfigTextArea {
                    id: linkKeywordsField
                    Layout.fillWidth: true
                    fieldWidth: 260
                    buttonIcon: "link_off"
                    text: Translation.tr("Unsafe link keywords")
                    placeholderText: Translation.tr("e.g. hentai, porn, rule34")
                    value: Config.options.workSafety.triggerCondition.linkKeywords.join(", ")
                    onEditingFinished: {
                        const items = linkKeywordsField.value.split(",").map(s => s.trim()).filter(s => s.length > 0);
                        if (items.join(", ") !== Config.options.workSafety.triggerCondition.linkKeywords.join(", "))
                            Config.options.workSafety.triggerCondition.linkKeywords = items;
                    }
                    W.StyledToolTip {
                        text: Translation.tr("Comma-separated keywords used to flag unsafe links in search results.")
                    }
                }
            }
        }
    }
}

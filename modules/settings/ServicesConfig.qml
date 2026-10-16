import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    function webappIconSource(icon) {
        if (!icon || icon.length === 0) return "";
        if (Platform.isWindows) return "file:///" + icon.replace(/\\/g, "/");
        return icon.startsWith("/") ? "file://" + icon : "";
    }

    ContentSection {
        icon: "web_asset"
        title: Translation.tr("Web apps")

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Creates a Start menu shortcut that opens a site like an app.")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        MaterialTextArea {
            id: webappUrlInput
            Layout.fillWidth: true
            placeholderText: Translation.tr("example.com (one per line)")
            wrapMode: TextEdit.Wrap
        }

        StyledText {
            Layout.fillWidth: true
            visible: Webapps.error !== ""
            text: Translation.tr("Could not create: %1").arg(Webapps.error)
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colError
            wrapMode: Text.Wrap
        }

        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 44
            buttonRadius: Appearance.rounding.normal
            enabled: webappUrlInput.text.trim() !== "" && !Webapps.busy
            colBackground: Appearance.colors.colSecondaryContainer
            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
            colRipple: Appearance.colors.colSecondaryContainerActive
            onClicked: {
                Webapps.create(webappUrlInput.text);
                webappUrlInput.text = "";
            }
            contentItem: RowLayout {
                spacing: 8
                Item { Layout.fillWidth: true }
                MaterialSymbol {
                    text: "add"
                    iconSize: 20
                    fill: 1
                    color: Appearance.colors.colOnSecondaryContainer
                }
                StyledText {
                    text: Translation.tr("Create webapp")
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnSecondaryContainer
                }
                Item { Layout.fillWidth: true }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: Webapps.items.length === 0
            text: Translation.tr("No webapps yet")
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.small
        }

        Repeater {
            model: Webapps.items

            delegate: RowLayout {
                id: webappRow
                required property var modelData
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 10

                Image {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    source: webappIconSource(webappRow.modelData.icon)
                    sourceSize: Qt.size(56, 56)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: webappRow.modelData.name
                        color: Appearance.colors.colOnLayer1
                        elide: Text.ElideRight
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: webappRow.modelData.url
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideRight
                    }
                }

                RippleButton {
                    implicitWidth: 36
                    implicitHeight: 36
                    buttonRadius: 18
                    colBackground: "transparent"
                    colBackgroundHover: Qt.rgba(1, 1, 1, 0.12)
                    colRipple: Qt.rgba(1, 1, 1, 0.2)
                    onClicked: Webapps.open(webappRow.modelData.id)
                    contentItem: MaterialSymbol {
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "open_in_new"
                        iconSize: 20
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledToolTip {
                        text: Translation.tr("Open")
                    }
                }

                RippleButton {
                    implicitWidth: 36
                    implicitHeight: 36
                    buttonRadius: 18
                    colBackground: "transparent"
                    colBackgroundHover: Qt.rgba(1, 1, 1, 0.12)
                    colRipple: Qt.rgba(1, 1, 1, 0.2)
                    onClicked: Webapps.remove(webappRow.modelData.id)
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
                }
            }
        }
    }

    ContentSection {
        icon: "neurology"
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
        }

        ConfigSwitch {
            text: Translation.tr("Fade in sidebar response text")
            checked: Config.options.sidebar.ai.textFadeIn
            onCheckedChanged: {
                Config.options.sidebar.ai.textFadeIn = checked;
            }
            StyledToolTip {
                text: Translation.tr("Animates new text in the assistant's replies as it streams in, instead of showing it immediately.")
            }
        }

        ContentSubsection {
            title: Translation.tr("vLLM endpoint")
            tooltip: Translation.tr("Address of a local OpenAI-compatible server (e.g. vLLM). Models it's currently running show up in the model picker automatically.")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Base URL")
                text: Config.options.ai.vllmEndpoint
                wrapMode: TextEdit.Wrap
                onEditingFinished: {
                    if (text !== Config.options.ai.vllmEndpoint) {
                        Config.options.ai.vllmEndpoint = text;
                        Ai.refreshLocalModels();
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "music_cast"
        title: Translation.tr("Music Recognition")

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

    ContentSection {
        icon: "cell_tower"
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
        icon: "memory"
        title: Translation.tr("Resources")

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

    ContentSection {
        icon: "file_open"
        title: Translation.tr("Save paths")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Video Recording Path")
            text: Config.options.screenRecord.savePath
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.screenRecord.savePath = text;
            }
        }
        
        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Screenshot Path (leave empty to just copy)")
            text: Config.options.screenSnip.savePath
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.screenSnip.savePath = text;
            }
        }
    }

    ContentSection {
        id: screenRecordSection
        icon: "screen_record"
        title: Translation.tr("Screen recording")

        property int accessCheck: 0
        readonly property bool windowActive: Window.active
        readonly property string microphoneBlocked: {
            screenRecordSection.accessCheck;
            const recorder = Platform.isWindows && WindowsNative.ready ? WindowsNative.screenRecorder : null;
            return recorder ? recorder.microphoneBlockedReason() : "";
        }
        onWindowActiveChanged: if (windowActive) accessCheck++

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "volume_up"
                text: Translation.tr("Record system audio")
                checked: Config.options.screenRecord.systemAudio
                onCheckedChanged: {
                    Config.options.screenRecord.systemAudio = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Adds what your speakers or headphones play")
                }
            }
            ConfigSwitch {
                buttonIcon: "mic"
                text: Translation.tr("Record microphone")
                checked: Config.options.screenRecord.microphone
                onCheckedChanged: {
                    Config.options.screenRecord.microphone = checked;
                    screenRecordSection.accessCheck++;
                }
                StyledToolTip {
                    text: Translation.tr("Adds the default microphone, mixed with the system audio")
                }
            }
        }

        NoticeBox {
            Layout.fillWidth: true
            visible: Platform.isWindows && Config.options.screenRecord.microphone && screenRecordSection.microphoneBlocked !== ""
            materialIcon: "mic_off"
            text: Translation.tr("Windows' privacy settings are blocking the microphone for desktop apps, so recordings won't include it.")

            Item {
                Layout.fillWidth: true
            }
            RippleButtonWithIcon {
                Layout.fillWidth: false
                buttonRadius: Appearance.rounding.small
                materialIcon: "open_in_new"
                mainText: Translation.tr("Open privacy settings")
                onClicked: Qt.openUrlExternally("ms-settings:privacy-microphone")
            }
        }
    }

    ContentSection {
        icon: "search"
        title: Translation.tr("Search")

        ConfigSwitch {
            text: Translation.tr("Spotlight search: Super opens search only, Super+Tab opens workspaces")
            checked: Config.options.search.spotlight
            onCheckedChanged: {
                Config.options.search.spotlight = checked;
            }
        }

        ConfigSwitch {
            text: Translation.tr("Use Levenshtein distance-based algorithm instead of fuzzy")
            checked: Config.options.search.sloppy
            onCheckedChanged: {
                Config.options.search.sloppy = checked;
            }
            StyledToolTip {
                text: Translation.tr("Could be better if you make a ton of typos,\nbut results can be weird and might not work with acronyms\n(e.g. \"GIMP\" might not give you the paint program)")
            }
        }

        ConfigSwitch {
            text: Translation.tr("Show command, math, and web search results without a prefix")
            checked: Config.options.search.prefix.showDefaultActionsWithoutPrefix
            onCheckedChanged: {
                Config.options.search.prefix.showDefaultActionsWithoutPrefix = checked;
            }
            StyledToolTip {
                text: Translation.tr("When off, these results only show once you type their prefix below (e.g. $, =, ?).")
            }
        }

        ConfigSwitch {
            text: Translation.tr("Show clipboard preview popups")
            checked: Config.options.search.clipboardPreviewPopup
            onCheckedChanged: {
                Config.options.search.clipboardPreviewPopup = checked;
            }
            StyledToolTip {
                text: Translation.tr("Shows a bigger preview of the selected clipboard entry next to the search box, instead of the inline thumbnail.")
            }
        }

        ContentSubsection {
            title: Translation.tr("Prefixes")
            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Action")
                    text: Config.options.search.prefix.action
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.action = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("App")
                    text: Config.options.search.prefix.app
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.app = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Clipboard")
                    text: Config.options.search.prefix.clipboard
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.clipboard = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Emojis")
                    text: Config.options.search.prefix.emojis
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.emojis = text;
                    }
                }
            }

            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Keybinds")
                    text: Config.options.search.prefix.keybinds
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.keybinds = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Symbols")
                    text: Config.options.search.prefix.symbols
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.symbols = text;
                    }
                }
            }

            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Math")
                    text: Config.options.search.prefix.math
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.math = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Shell command")
                    text: Config.options.search.prefix.shellCommand
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.shellCommand = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Web search")
                    text: Config.options.search.prefix.webSearch
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.webSearch = text;
                    }
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Web search")
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Base URL")
                text: Config.options.search.engineBaseUrl
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.search.engineBaseUrl = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Image search")
            tooltip: Translation.tr("Used when searching the web for a screenshot or selection (reverse image search).")
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Base URL")
                text: Config.options.search.imageSearch.imageSearchEngineBaseUrl
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.search.imageSearch.imageSearchEngineBaseUrl = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Excluded sites")
            tooltip: Translation.tr("Comma-separated list of domains hidden from web search suggestions.")
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("e.g. quora.com, facebook.com")
                text: Config.options.search.excludedSites.join(", ")
                wrapMode: TextEdit.Wrap
                onEditingFinished: {
                    const items = text.split(",").map(s => s.trim()).filter(s => s.length > 0);
                    if (items.join(", ") !== Config.options.search.excludedSites.join(", "))
                        Config.options.search.excludedSites = items;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Non-app results")
            tooltip: Translation.tr("Delay before showing calculator, web search, and other non-app results. Prevents lag while typing.")
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

    // There's no update indicator in ii for now so we shouldn't show this yet
    // ContentSection {
    //     icon: "deployed_code_update"
    //     title: Translation.tr("System updates (Arch only)")

    //     ConfigSwitch {
    //         text: Translation.tr("Enable update checks")
    //         checked: Config.options.updates.enableCheck
    //         onCheckedChanged: {
    //             Config.options.updates.enableCheck = checked;
    //         }
    //     }

    //     ConfigSpinBox {
    //         icon: "av_timer"
    //         text: Translation.tr("Check interval (mins)")
    //         value: Config.options.updates.checkInterval
    //         from: 60
    //         to: 1440
    //         stepSize: 60
    //         onValueChanged: {
    //             Config.options.updates.checkInterval = value;
    //         }
    //     }
    // }

    ContentSection {
        visible: Platform.isWindows
        icon: "deployed_code_update"
        title: Translation.tr("App updates")

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Uses winget to count installed apps with available updates.")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        ConfigSwitch {
            buttonIcon: "apps"
            text: Translation.tr("Count apps with available updates")
            checked: Config.options.updates.enableCheck
            onCheckedChanged: {
                if (checked !== Config.options.updates.enableCheck)
                    Config.options.updates.enableCheck = checked;
            }
        }
    }

    ContentSection {
        icon: "weather_mix"
        title: Translation.tr("Weather")

        WeatherMapPreview {
            Layout.fillWidth: true
        }

        ConfigRow {
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
                StyledToolTip {
                    text: Translation.tr("It may take a few seconds to update")
                }
            }
        }
        
        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("City name")
            text: Config.options.bar.weather.city
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.bar.weather.city = text;
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
    }

    ContentSection {
        icon: "translate"
        title: Translation.tr("Translator")

        ContentSubsection {
            title: Translation.tr("Languages")
            tooltip: Translation.tr("Language codes like \"en\", \"pt\" or \"ja\". \"auto\" detects the source language.")
            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Source language")
                    text: Config.options.language.translator.sourceLanguage
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.language.translator.sourceLanguage = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Target language")
                    text: Config.options.language.translator.targetLanguage
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.language.translator.targetLanguage = text;
                    }
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

    ContentSection {
        icon: "bedtime"
        title: Translation.tr("Night light")

        ConfigSwitch {
            text: Translation.tr("Automatic")
            checked: Config.options.light.night.automatic
            onCheckedChanged: {
                Config.options.light.night.automatic = checked;
            }
            StyledToolTip {
                text: Translation.tr("Switches the warm color filter on and off automatically between the times below.")
            }
        }

        ContentSubsection {
            title: Translation.tr("Schedule")
            tooltip: Translation.tr("Format: \"HH:mm\", 24-hour time")
            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("From")
                    text: Config.options.light.night.from
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.light.night.from = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("To")
                    text: Config.options.light.night.to
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.light.night.to = text;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Color temperature")
            tooltip: Translation.tr("In Kelvin. Lower values look warmer/more orange.")
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

        Loader {
            Layout.fillWidth: true
            active: !Platform.isWindows
            visible: active
            sourceComponent: ConfigSwitch {
                text: Translation.tr("Anti-flashbang (experimental)")
                checked: Config.options.light.antiFlashbang.enable
                onCheckedChanged: {
                    Config.options.light.antiFlashbang.enable = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Balances brightness based on screen content to avoid sudden brightness spikes.")
                }
            }
        }
    }

    ContentSection {
        icon: "photo_library"
        title: Translation.tr("Booru")

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

        ContentSubsection {
            title: Translation.tr("Zerochan")
            tooltip: Translation.tr("Required by Zerochan's API to avoid being rate-limited or banned for anonymous requests.")
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Zerochan username")
                text: Config.options.sidebar.booru.zerochan.username
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.sidebar.booru.zerochan.username = text;
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
            title: Translation.tr("Sounds")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Sound theme name (in /usr/share/sounds)")
                text: Config.options.sounds.theme
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.sounds.theme = text;
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
            title: Translation.tr("Update thresholds")

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

    Loader {
        Layout.fillWidth: true
        active: !Platform.isWindows
        visible: active
        sourceComponent: ContentSection {
            icon: "block"
            title: Translation.tr("Conflict killer")

            ConfigSwitch {
                text: Translation.tr("Automatically kill conflicting tray daemons")
                checked: Config.options.conflictKiller.autoKillTrays
                onCheckedChanged: {
                    Config.options.conflictKiller.autoKillTrays = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Silently kills kded6 when it conflicts with the shell's own system tray, instead of asking every time.")
                }
            }
            ConfigSwitch {
                text: Translation.tr("Automatically kill conflicting notification daemons")
                checked: Config.options.conflictKiller.autoKillNotificationDaemons
                onCheckedChanged: {
                    Config.options.conflictKiller.autoKillNotificationDaemons = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Silently kills mako/dunst when they conflict with the shell's own notifications, instead of asking every time.")
                }
            }
        }
    }

    ContentSection {
        icon: "shield"
        title: Translation.tr("Work safety triggers")

        ContentSubsection {
            title: Translation.tr("Suspicious network names")
            tooltip: Translation.tr("Comma-separated keywords. If the current network name contains one, the \"Work safety\" hiding (in General settings) can trigger.")
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("e.g. airport, cafe, guest")
                text: Config.options.workSafety.triggerCondition.networkNameKeywords.join(", ")
                wrapMode: TextEdit.Wrap
                onEditingFinished: {
                    const items = text.split(",").map(s => s.trim()).filter(s => s.length > 0);
                    if (items.join(", ") !== Config.options.workSafety.triggerCondition.networkNameKeywords.join(", "))
                        Config.options.workSafety.triggerCondition.networkNameKeywords = items;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Suspicious wallpaper keywords")
            tooltip: Translation.tr("Comma-separated keywords. If the wallpaper file name contains one (together with a suspicious network), it gets hidden.")
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("e.g. anime, booru, hentai")
                text: Config.options.workSafety.triggerCondition.fileKeywords.join(", ")
                wrapMode: TextEdit.Wrap
                onEditingFinished: {
                    const items = text.split(",").map(s => s.trim()).filter(s => s.length > 0);
                    if (items.join(", ") !== Config.options.workSafety.triggerCondition.fileKeywords.join(", "))
                        Config.options.workSafety.triggerCondition.fileKeywords = items;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Unsafe link keywords")
            tooltip: Translation.tr("Comma-separated keywords used to flag unsafe links in search results.")
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("e.g. hentai, porn, rule34")
                text: Config.options.workSafety.triggerCondition.linkKeywords.join(", ")
                wrapMode: TextEdit.Wrap
                onEditingFinished: {
                    const items = text.split(",").map(s => s.trim()).filter(s => s.length > 0);
                    if (items.join(", ") !== Config.options.workSafety.triggerCondition.linkKeywords.join(", "))
                        Config.options.workSafety.triggerCondition.linkKeywords = items;
                }
            }
        }
    }
}

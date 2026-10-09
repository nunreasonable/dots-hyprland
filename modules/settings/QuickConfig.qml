import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    forceWidth: true

    component SmallLightDarkPreferenceButton: RippleButton {
        id: smallLightDarkPreferenceButton
        required property bool dark
        property color colText: toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
        padding: 5
        Layout.fillWidth: true
        toggled: Appearance.m3colors.darkmode === dark
        colBackground: Appearance.colors.colLayer2
        onClicked: {
            Wallpapers.setMode(dark);
        }
        contentItem: Item {
            anchors.centerIn: parent
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    iconSize: 30
                    text: dark ? "dark_mode" : "light_mode"
                    color: smallLightDarkPreferenceButton.colText
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: dark ? Translation.tr("Dark") : Translation.tr("Light")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: smallLightDarkPreferenceButton.colText
                }
            }
        }
    }

    // Wallpaper selection
    ContentSection {
        icon: "format_paint"
        title: Translation.tr("Wallpaper & Colors")
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true

            Item {
                implicitWidth: 340
                implicitHeight: 200
                
                StyledImage {
                    id: wallpaperPreview
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: Config.options.background.wallpaperPath
                    sourceSize: Qt.size(Math.ceil(340 * Screen.devicePixelRatio), Math.ceil(200 * Screen.devicePixelRatio))
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: wallpaperPreview.width
                            height: wallpaperPreview.height
                            radius: Appearance.rounding.normal
                        }
                    }
                }
            }

            ColumnLayout {
                RippleButtonWithIcon {
                    enabled: !RandomWallpaper.running
                    visible: Config.options.policies.weeb === 1
                    Layout.fillWidth: true
                    buttonRadius: Appearance.rounding.small
                    materialIcon: "ifl"
                    mainText: RandomWallpaper.running ? Translation.tr("Be patient...") : Translation.tr("Random: Konachan")
                    onClicked: {
                        RandomWallpaper.fetch("konachan");
                    }
                    StyledToolTip {
                        text: SpicyStuff.konachan
                            ? Translation.tr("Random Anime wallpaper from Konachan, Spicy Stuff included\nImage is saved to ~/Pictures/Wallpapers")
                            : Translation.tr("Random SFW Anime wallpaper from Konachan\nImage is saved to ~/Pictures/Wallpapers")
                    }
                }
                RippleButtonWithIcon {
                    enabled: !RandomWallpaper.running
                    visible: Config.options.policies.weeb === 1
                    Layout.fillWidth: true
                    buttonRadius: Appearance.rounding.small
                    materialIcon: "ifl"
                    mainText: RandomWallpaper.running ? Translation.tr("Be patient...") : Translation.tr("Random: osu! seasonal")
                    onClicked: {
                        RandomWallpaper.fetch("osu");
                    }
                    StyledToolTip {
                        text: Translation.tr("Random osu! seasonal background\nImage is saved to ~/Pictures/Wallpapers")
                    }
                }
                RippleButtonWithIcon {
                    Layout.fillWidth: true
                    materialIcon: "wallpaper"
                    StyledToolTip {
                        text: Translation.tr("Pick wallpaper image on your system")
                    }
                    onClicked: {
                        Wallpapers.openPicker();
                    }
                    mainContentComponent: Component {
                        RowLayout {
                            spacing: 10
                            StyledText {
                                font.pixelSize: Appearance.font.pixelSize.small
                                text: Translation.tr("Choose file")
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                            RowLayout {
                                spacing: 3
                                KeyboardKey {
                                    key: "Ctrl"
                                }
                                KeyboardKey {
                                    key: Config.options.cheatsheet.superKey ?? "󰖳"
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: "+"
                                }
                                KeyboardKey {
                                    key: "T"
                                }
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    uniformCellSizes: true

                    SmallLightDarkPreferenceButton {
                        Layout.fillHeight: true
                        dark: false
                    }
                    SmallLightDarkPreferenceButton {
                        Layout.fillHeight: true
                        dark: true
                    }
                }
            }
        }

        ConfigSelectionArray {
            currentValue: Config.options.appearance.palette.type
            onSelected: newValue => {
                Config.options.appearance.palette.type = newValue;
                Wallpapers.reapplyPalette();
            }
            options: [
                {
                    "value": "auto",
                    "displayName": Translation.tr("Auto")
                },
                {
                    "value": "scheme-content",
                    "displayName": Translation.tr("Content")
                },
                {
                    "value": "scheme-expressive",
                    "displayName": Translation.tr("Expressive")
                },
                {
                    "value": "scheme-fidelity",
                    "displayName": Translation.tr("Fidelity")
                },
                {
                    "value": "scheme-fruit-salad",
                    "displayName": Translation.tr("Fruit Salad")
                },
                {
                    "value": "scheme-monochrome",
                    "displayName": Translation.tr("Monochrome")
                },
                {
                    "value": "scheme-neutral",
                    "displayName": Translation.tr("Neutral")
                },
                {
                    "value": "scheme-rainbow",
                    "displayName": Translation.tr("Rainbow")
                },
                {
                    "value": "scheme-tonal-spot",
                    "displayName": Translation.tr("Tonal Spot")
                }
            ]
        }

        ContentSubsection {
            title: Translation.tr("Named color scheme")
            tooltip: Translation.tr("Pick a fixed palette instead of colors extracted from the wallpaper.")
            visible: Platform.isWindows

            StyledComboBox {
                id: namedSchemeSelector
                buttonIcon: "palette"
                textRole: "displayName"
                model: ColorSchemes.schemeOptions()
                currentIndex: {
                    const index = model.findIndex(item => item.value === Config.options.appearance.palette.namedScheme);
                    return index !== -1 ? index : 0;
                }
                onActivated: index => {
                    Config.options.appearance.palette.namedScheme = model[index].value;
                    Config.options.appearance.palette.namedSchemePrimary = "";
                    Config.options.appearance.palette.namedSchemeSecondary = "";
                    Wallpapers.reapplyPalette();
                }
            }

            ConfigRow {
                uniform: true
                visible: Config.options.appearance.palette.namedScheme !== ""
                StyledComboBox {
                    id: namedSchemePrimarySelector
                    buttonIcon: "colors"
                    textRole: "displayName"
                    model: ColorSchemes.accentOptions(Appearance.m3colors.darkmode)
                    currentIndex: {
                        const index = model.findIndex(item => item.value === Config.options.appearance.palette.namedSchemePrimary);
                        return index !== -1 ? index : 0;
                    }
                    onActivated: index => {
                        Config.options.appearance.palette.namedSchemePrimary = model[index].value;
                        Wallpapers.reapplyPalette();
                    }
                }
                StyledComboBox {
                    id: namedSchemeSecondarySelector
                    buttonIcon: "colors"
                    textRole: "displayName"
                    model: ColorSchemes.accentOptions(Appearance.m3colors.darkmode)
                    currentIndex: {
                        const index = model.findIndex(item => item.value === Config.options.appearance.palette.namedSchemeSecondary);
                        return index !== -1 ? index : 0;
                    }
                    onActivated: index => {
                        Config.options.appearance.palette.namedSchemeSecondary = model[index].value;
                        Wallpapers.reapplyPalette();
                    }
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "ev_shadow"
            text: Translation.tr("Transparency")
            checked: Config.options.appearance.transparency.enable
            onCheckedChanged: {
                Config.options.appearance.transparency.enable = checked;
            }
        }

        ContentSubsection {
            visible: Config.options.policies.weeb === 1
            title: Translation.tr("Random Konachan wallpaper")

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "local_fire_department"
                    text: Translation.tr("Spicy Stuff")
                    enabled: SpicyStuff.allowed
                    checked: Config.options.background.konachanSpicy && SpicyStuff.allowed
                    onCheckedChanged: {
                        if (SpicyStuff.allowed)
                            Config.options.background.konachanSpicy = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Lets Konachan pick wallpapers of any rating, not only safe ones")
                    }
                }
                ConfigSwitch {
                    buttonIcon: "favorite"
                    text: Translation.tr("Only yuri")
                    checked: Config.options.background.konachanOnlyYuri
                    onCheckedChanged: {
                        Config.options.background.konachanOnlyYuri = checked;
                    }
                }
            }

            NoticeBox {
                Layout.fillWidth: true
                visible: !SpicyStuff.allowed
                materialIcon: SpicyStuff.checking ? "hourglass_top" : "lock"
                text: SpicyStuff.restriction
            }

            MaterialTextArea {
                Layout.fillWidth: true
                enabled: SpicyStuff.konachan
                placeholderText: SpicyStuff.konachan
                    ? Translation.tr("Extra tags, separated by spaces (up to %1)").arg(SpicyStuff.maxExtraTags)
                    : Translation.tr("Extra tags (turn on Spicy Stuff first)")
                text: Config.options.background.konachanExtraTags
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.background.konachanExtraTags = text;
                }
            }
        }
    }

    ContentSection {
        icon: "style"
        title: Translation.tr("Style")

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Visual style")
                tooltip: Translation.tr("Switching the style resets the bar layout and buttons, workspace numbers, quick sliders and settings layout to that style's defaults")

                ConfigSelectionArray {
                    currentValue: Config.options.appearance.visualStyle
                    onSelected: newValue => {
                        Config.options.appearance.visualStyle = newValue;
                    }
                    options: [
                        {
                            displayName: "illogical-impulse",
                            icon: "auto_awesome",
                            value: "ii"
                        },
                        {
                            displayName: "end4-pC",
                            icon: "dashboard_customize",
                            value: "end4pc"
                        }
                    ]
                }
            }
            ContentSubsection {
                title: Translation.tr("Settings layout")

                ConfigSelectionArray {
                    currentValue: Config.options.appearance.settingsLayout
                    onSelected: newValue => {
                        Config.options.appearance.settingsLayout = newValue;
                    }
                    options: [
                        {
                            displayName: "illogical-impulse",
                            icon: "view_sidebar",
                            value: "ii"
                        },
                        {
                            displayName: "end4-pC",
                            icon: "web_asset",
                            value: "end4pc"
                        }
                    ]
                }
            }
        }
    }

    ContentSection {
        icon: "screenshot_monitor"
        title: Translation.tr("Bar & screen")

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Bar position")
                ConfigSelectionArray {
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Top"),
                            icon: "arrow_upward",
                            value: 0 // bottom: false, vertical: false
                        },
                        {
                            displayName: Translation.tr("Left"),
                            icon: "arrow_back",
                            value: 2 // bottom: false, vertical: true
                        },
                        {
                            displayName: Translation.tr("Bottom"),
                            icon: "arrow_downward",
                            value: 1 // bottom: true, vertical: false
                        },
                        {
                            displayName: Translation.tr("Right"),
                            icon: "arrow_forward",
                            value: 3 // bottom: true, vertical: true
                        }
                    ]
                }
            }
            ContentSubsection {
                title: Translation.tr("Bar style")

                ConfigSelectionArray {
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => {
                        Config.options.bar.cornerStyle = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Hug"),
                            icon: "line_curve",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Float"),
                            icon: "page_header",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Rect"),
                            icon: "toolbar",
                            value: 2
                        }
                    ]
                }
            }
        }

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Screen round corner")

                ConfigSelectionArray {
                    currentValue: Config.options.appearance.fakeScreenRounding
                    onSelected: newValue => {
                        Config.options.appearance.fakeScreenRounding = newValue;
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
                            displayName: Translation.tr("When not fullscreen"),
                            icon: "fullscreen_exit",
                            value: 2
                        }
                    ]
                }
            }
            
        }
    }

    NoticeBox {
        Layout.fillWidth: true
        text: Translation.tr('Almost every option is in this app. The few left in the config file are lists that ii edits for you (pinned apps, quick toggles) and extra AI models: open it with the "Config file" button on the top-left corner or at %1.').arg(Directories.shellConfigPath)

        Item {
            Layout.fillWidth: true
        }
        RippleButtonWithIcon {
            id: copyPathButton
            property bool justCopied: false
            Layout.fillWidth: false
            buttonRadius: Appearance.rounding.small
            materialIcon: justCopied ? "check" : "content_copy"
            mainText: justCopied ? Translation.tr("Path copied") : Translation.tr("Copy path")
            onClicked: {
                copyPathButton.justCopied = true
                Quickshell.clipboardText = FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse/config.json`);
                revertTextTimer.restart();
            }
            colBackground: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer)
            colBackgroundHover: Appearance.colors.colPrimaryContainerHover
            colRipple: Appearance.colors.colPrimaryContainerActive

            Timer {
                id: revertTextTimer
                interval: 1500
                onTriggered: {
                    copyPathButton.justCopied = false
                }
            }
        }
    }
}

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
* Popup dialog for configuring Wallhaven search filters.
* Used within the wallpaper selector when Wallhaven mode is active.
*/
WindowDialog {
    id: root
    backgroundWidth: 620

    property bool dirty: false

    property bool ready: false
    Component.onCompleted: Qt.callLater(() => root.ready = true)

    readonly property real cellWidth: (root.backgroundWidth - 2 * Appearance.rounding.large - 16) / 2

    WindowDialogTitle {
        text: Translation.tr("Wallhaven Settings")
    }

    WindowDialogSeparator {}

    readonly property bool isToplist: WallhavenSearch.sorting === "toplist"

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 16
        rowSpacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: root.cellWidth
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: Translation.tr("Sort by")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                StyledComboBox {
                    id: sortingCombo
                    Layout.fillWidth: true
                    textRole: "displayName"
                    model: [
                        {
                            value: "date_added",
                            displayName: Translation.tr("Date Added")
                        },
                        {
                            value: "relevance",
                            displayName: Translation.tr("Relevance")
                        },
                        {
                            value: "random",
                            displayName: Translation.tr("Random")
                        },
                        {
                            value: "views",
                            displayName: Translation.tr("Views")
                        },
                        {
                            value: "favorites",
                            displayName: Translation.tr("Favorites")
                        },
                        {
                            value: "toplist",
                            displayName: Translation.tr("Top List")
                        },
                        {
                            value: "hot",
                            displayName: Translation.tr("Hot")
                        },
                    ]
                    currentIndex: model.findIndex(m => m.value === WallhavenSearch.sorting)
                    onCurrentIndexChanged: {
                        if (!root.ready || currentIndex < 0)
                            return;
                        const value = model[currentIndex].value;
                        if (value === WallhavenSearch.sorting)
                            return;
                        WallhavenSearch.sorting = value;
                        root.dirty = true;
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: root.isToplist

                StyledText {
                    text: Translation.tr("Top Range")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                StyledComboBox {
                    Layout.fillWidth: true
                    textRole: "displayName"
                    model: [
                        {
                            value: "1d",
                            displayName: Translation.tr("1 Day")
                        },
                        {
                            value: "3d",
                            displayName: Translation.tr("3 Days")
                        },
                        {
                            value: "1w",
                            displayName: Translation.tr("1 Week")
                        },
                        {
                            value: "1m",
                            displayName: Translation.tr("1 Month")
                        },
                        {
                            value: "3m",
                            displayName: Translation.tr("3 Months")
                        },
                        {
                            value: "6m",
                            displayName: Translation.tr("6 Months")
                        },
                        {
                            value: "1y",
                            displayName: Translation.tr("1 Year")
                        },
                    ]
                    currentIndex: model.findIndex(m => m.value === WallhavenSearch.topRange)
                    onCurrentIndexChanged: {
                        if (!root.ready || currentIndex < 0)
                            return;
                        const value = model[currentIndex].value;
                        if (value === WallhavenSearch.topRange)
                            return;
                        WallhavenSearch.topRange = value;
                        root.dirty = true;
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: WallhavenSearch.sorting !== "random"

                StyledText {
                    text: Translation.tr("Order")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                StyledComboBox {
                    Layout.fillWidth: true
                    textRole: "displayName"
                    model: [
                        {
                            value: "desc",
                            displayName: Translation.tr("Descending")
                        },
                        {
                            value: "asc",
                            displayName: Translation.tr("Ascending")
                        },
                    ]
                    currentIndex: model.findIndex(m => m.value === WallhavenSearch.order)
                    onCurrentIndexChanged: {
                        if (!root.ready || currentIndex < 0)
                            return;
                        const value = model[currentIndex].value;
                        if (value === WallhavenSearch.order)
                            return;
                        WallhavenSearch.order = value;
                        root.dirty = true;
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: Translation.tr("Ratio")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                StyledComboBox {
                    Layout.fillWidth: true
                    textRole: "displayName"
                    model: [
                        {
                            value: "",
                            displayName: Translation.tr("Any")
                        },
                        {
                            value: "16x9",
                            displayName: "16x9"
                        },
                        {
                            value: "16x10",
                            displayName: "16x10"
                        },
                        {
                            value: "21x9",
                            displayName: "21x9"
                        },
                        {
                            value: "32x9",
                            displayName: "32x9"
                        },
                        {
                            value: "9x16",
                            displayName: "9x16"
                        },
                        {
                            value: "10x16",
                            displayName: "10x16"
                        },
                        {
                            value: "1x1",
                            displayName: "1x1"
                        },
                        {
                            value: "3x2",
                            displayName: "3x2"
                        },
                        {
                            value: "4x3",
                            displayName: "4x3"
                        },
                        {
                            value: "5x4",
                            displayName: "5x4"
                        },
                    ]
                    currentIndex: Math.max(0, model.findIndex(m => m.value === WallhavenSearch.ratios))
                    onCurrentIndexChanged: {
                        if (!root.ready || currentIndex < 0)
                            return;
                        const value = model[currentIndex].value;
                        if (value === WallhavenSearch.ratios)
                            return;
                        WallhavenSearch.ratios = value;
                        root.dirty = true;
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: root.cellWidth
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: Translation.tr("Categories")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 6

                    RippleButton {
                        implicitHeight: 32
                        buttonRadius: height / 2
                        leftPadding: 14
                        rightPadding: 14
                        toggled: WallhavenSearch.categories.charAt(0) === "1"
                        colBackgroundToggled: Appearance.colors.colPrimary
                        onClicked: {
                            var cats = WallhavenSearch.categories;
                            WallhavenSearch.categories = (cats.charAt(0) === "1" ? "0" : "1") + cats.charAt(
                                        1) + cats.charAt(2);
                            root.dirty = true;
                        }
                        contentItem: StyledText {
                            text: Translation.tr("General")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: parent.toggled ? Appearance.colors.colOnPrimary :
                                                    Appearance.colors.colOnLayer1
                        }
                    }

                    RippleButton {
                        implicitHeight: 32
                        buttonRadius: height / 2
                        leftPadding: 14
                        rightPadding: 14
                        toggled: WallhavenSearch.categories.charAt(1) === "1"
                        colBackgroundToggled: Appearance.colors.colPrimary
                        onClicked: {
                            var cats = WallhavenSearch.categories;
                            WallhavenSearch.categories = cats.charAt(0) + (cats.charAt(1) === "1" ? "0" : "1")
                                    + cats.charAt(2);
                            root.dirty = true;
                        }
                        contentItem: StyledText {
                            text: Translation.tr("Anime")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: parent.toggled ? Appearance.colors.colOnPrimary :
                                                    Appearance.colors.colOnLayer1
                        }
                    }

                    RippleButton {
                        implicitHeight: 32
                        buttonRadius: height / 2
                        leftPadding: 14
                        rightPadding: 14
                        toggled: WallhavenSearch.categories.charAt(2) === "1"
                        colBackgroundToggled: Appearance.colors.colPrimary
                        onClicked: {
                            var cats = WallhavenSearch.categories;
                            WallhavenSearch.categories = cats.charAt(0) + cats.charAt(1) + (cats.charAt(2)
                                                                                            === "1" ? "0" :
                                                                                                      "1");
                            root.dirty = true;
                        }
                        contentItem: StyledText {
                            text: Translation.tr("People")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: parent.toggled ? Appearance.colors.colOnPrimary :
                                                    Appearance.colors.colOnLayer1
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: Translation.tr("Purity")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 6

                    RippleButton {
                        implicitHeight: 32
                        buttonRadius: height / 2
                        leftPadding: 14
                        rightPadding: 14
                        toggled: WallhavenSearch.purity.charAt(0) === "1"
                        colBackgroundToggled: Appearance.colors.colPrimary
                        onClicked: {
                            var p = WallhavenSearch.purity;
                            WallhavenSearch.purity = (p.charAt(0) === "1" ? "0" : "1") + p.charAt(1) + p.charAt(
                                        2);
                            root.dirty = true;
                        }
                        contentItem: StyledText {
                            text: "SFW"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: parent.toggled ? Appearance.colors.colOnPrimary :
                                                    Appearance.colors.colOnLayer1
                        }
                    }

                    RippleButton {
                        implicitHeight: 32
                        buttonRadius: height / 2
                        leftPadding: 14
                        rightPadding: 14
                        toggled: WallhavenSearch.purity.charAt(1) === "1"
                        colBackgroundToggled: Appearance.colors.colPrimary
                        onClicked: {
                            var p = WallhavenSearch.purity;
                            WallhavenSearch.purity = p.charAt(0) + (p.charAt(1) === "1" ? "0" : "1")
                                    + p.charAt(2);
                            root.dirty = true;
                        }
                        contentItem: StyledText {
                            text: Translation.tr("Sketchy")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: parent.toggled ? Appearance.colors.colOnPrimary :
                                                    Appearance.colors.colOnLayer1
                        }
                    }

                    RippleButton {
                        visible: WallhavenSearch.apiKey.length > 0
                        implicitHeight: 32
                        buttonRadius: height / 2
                        leftPadding: 14
                        rightPadding: 14
                        toggled: WallhavenSearch.purity.charAt(2) === "1"
                        colBackgroundToggled: Appearance.m3colors.m3error
                        onClicked: {
                            var p = WallhavenSearch.purity;
                            WallhavenSearch.purity = p.charAt(0) + p.charAt(1) + (p.charAt(2) === "1" ? "0" :
                                                                                                        "1");
                            root.dirty = true;
                        }
                        contentItem: StyledText {
                            text: Translation.tr("Spicy")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: parent.toggled ? Appearance.colors.colOnPrimary :
                                                    Appearance.colors.colOnLayer1
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: Translation.tr("API Key")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                TextField {
                    id: apiKeyField
                    Layout.fillWidth: true
                    echoMode: TextInput.Password
                    placeholderText: Translation.tr("Optional — needed for Spicy results")
                    placeholderTextColor: Appearance.colors.colSubtext
                    color: Appearance.colors.colOnLayer1
                    text: WallhavenSearch.apiKey
                    font {
                        family: Appearance.font.family.main
                        pixelSize: Appearance.font.pixelSize.small
                        hintingPreference: Font.PreferFullHinting
                    }
                    renderType: Text.NativeRendering
                    background: Rectangle {
                        color: Appearance.colors.colLayer1
                        radius: Appearance.rounding.small
                        border.width: 1
                        border.color: apiKeyField.activeFocus ? Appearance.colors.colPrimary :
                                                                Appearance.colors.colLayer0Border
                    }
                    onEditingFinished: {
                        WallhavenSearch.apiKey = text;
                        WallhavenSearch.saveToConfig();
                    }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        StyledText {
            text: Translation.tr("Colors")
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
        }

        CustomColorSelectionArray {
            currentValue: WallhavenSearch.colors
            options: [{ value: "", displayName: Translation.tr("All colors"), color: "transparent", rainbow: true }].concat([
                { hex: "cc0000", name: Translation.tr("Red"), q: "660000,990000,cc0000,cc3333" },
                { hex: "ff6600", name: Translation.tr("Orange"), q: "ffcc33,ff9900,ff6600" },
                { hex: "cccc33", name: Translation.tr("Yellow"), q: "666600,999900,cccc33,ffff00" },
                { hex: "669900", name: Translation.tr("Green"), q: "77cc33,669900,336600" },
                { hex: "66cccc", name: Translation.tr("Cyan"), q: "66cccc,0099cc" },
                { hex: "0066cc", name: Translation.tr("Blue"), q: "0066cc,0099cc,333399" },
                { hex: "663399", name: Translation.tr("Purple"), q: "ea4c88,993399,663399,333399" },
                { hex: "996633", name: Translation.tr("Brown"), q: "cc6633,996633,663300" },
                { hex: "999999", name: Translation.tr("Grayscale"), q: "000000,999999,cccccc,ffffff,424153" },
            ].map(g => ({ value: g.q, displayName: g.name, color: "#" + g.hex })))
            onSelected: newValue => {
                if (newValue === "" && WallhavenSearch.colors === "")
                    return;
                WallhavenSearch.setColor(newValue);
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

DashboardCard {
    id: root

    readonly property var styles: VisualStyle.styles

    function styleInfo(id) {
        switch (id) {
        case "ii": return { name: "illogical-impulse", icon: "auto_awesome" };
        case "end4pc": return { name: "end4-pC", icon: "dashboard_customize" };
        case "nabyscape": return { name: "NabyScape", icon: "toolbar" };
        case "sekaipop": return { name: "SekaiPop", icon: "interests" };
        default: return { name: id, icon: "palette" };
        }
    }

    readonly property var sekaiThemes: [
        { displayName: Translation.tr("Mint"), value: "mint" },
        { displayName: Translation.tr("Indigo"), value: "indigo" },
        { displayName: Translation.tr("Lime"), value: "lime" },
        { displayName: Translation.tr("Rose"), value: "rose" },
        { displayName: Translation.tr("Amber"), value: "amber" },
        { displayName: Translation.tr("Violet"), value: "violet" },
        { displayName: Translation.tr("Monochrome"), value: "mono" },
        { displayName: Translation.tr("Wallpaper"), value: "wallpaper" }
    ]

    readonly property bool sekaipopSelected: Config.options.appearance.visualStyle === "sekaipop"
    readonly property real sekaiRowTarget: sekaipopSelected ? 48 : 0
    property real sekaiRowHeight: sekaiRowTarget

    Behavior on sekaiRowHeight {
        SpringAnimation { spring: 3.2; damping: 0.28 }
    }

    tint: Appearance.colors.colLayer1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            MaterialShapeWrappedMaterialSymbol {
                shape: MaterialShape.Shape.Gem
                text: "palette"
                iconSize: 26
                fill: 1
                padding: 11
                color: Appearance.colors.colPrimary
                colSymbol: Appearance.colors.colOnPrimary
            }

            ColumnLayout {
                spacing: 0

                StyledText {
                    text: Translation.tr("Visual style")
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    text: root.styleInfo(Config.options.appearance.visualStyle).name
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            rowSpacing: 10
            columnSpacing: 10

            Repeater {
                model: root.styles

                delegate: RippleButton {
                    id: option
                    required property string modelData

                    readonly property var info: root.styleInfo(modelData)
                    readonly property bool selected: Config.options.appearance.visualStyle === modelData

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 1
                    buttonRadius: Appearance.rounding.large
                    colBackground: selected ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                    colBackgroundHover: selected ? Appearance.colors.colPrimaryHover : Appearance.colors.colSecondaryContainerHover
                    colRipple: selected ? Appearance.colors.colPrimaryActive : Appearance.colors.colSecondaryContainerActive
                    downAction: () => {
                        const value = option.modelData;
                        Qt.callLater(() => { Config.options.appearance.visualStyle = value; });
                    }

                    contentItem: ColumnLayout {
                        spacing: 6

                        Item { Layout.fillHeight: true }

                        MaterialShapeWrappedMaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            shape: MaterialShape.Shape.Clover4Leaf
                            text: option.info.icon
                            iconSize: 26
                            fill: 1
                            padding: 12
                            color: option.selected ? Appearance.colors.colOnPrimary : Appearance.colors.colPrimary
                            colSymbol: option.selected ? Appearance.colors.colPrimary : Appearance.colors.colOnPrimary
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: option.info.name
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.DemiBold
                            color: option.selected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(0, root.sekaiRowHeight)
            clip: true

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                spacing: 4

                StyledText {
                    text: Translation.tr("SekaiPop theme")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: root.sekaiThemes

                        delegate: RippleButton {
                            required property var modelData
                            readonly property bool picked: Config.options.appearance.sekaipop.theme === modelData.value

                            implicitWidth: label.implicitWidth + 24
                            implicitHeight: 28
                            buttonRadius: 14
                            colBackground: picked ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                            colBackgroundHover: picked ? Appearance.colors.colPrimaryHover : Appearance.colors.colSecondaryContainerHover
                            colRipple: picked ? Appearance.colors.colPrimaryActive : Appearance.colors.colSecondaryContainerActive
                            downAction: () => {
                                const value = modelData.value;
                                Qt.callLater(() => { Config.options.appearance.sekaipop.theme = value; });
                            }
                            contentItem: StyledText {
                                id: label
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: modelData.displayName
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: picked ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                            }
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

DashboardCard {
    id: root

    readonly property var options: [
        { value: 0, name: Translation.tr("Top"), icon: "arrow_upward" },
        { value: 2, name: Translation.tr("Left"), icon: "arrow_back" },
        { value: 1, name: Translation.tr("Bottom"), icon: "arrow_downward" },
        { value: 3, name: Translation.tr("Right"), icon: "arrow_forward" }
    ]
    readonly property int current: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)

    tint: Appearance.colors.colSecondaryContainer

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            MaterialShapeWrappedMaterialSymbol {
                shape: MaterialShape.Shape.Pentagon
                text: "toast"
                iconSize: 26
                fill: 1
                padding: 11
                color: Appearance.colors.colSecondary
                colSymbol: Appearance.colors.colOnSecondary
            }

            ColumnLayout {
                spacing: 0

                StyledText {
                    text: Translation.tr("Bar position")
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnSecondaryContainer
                }
                StyledText {
                    text: Translation.tr("Where the bar lives")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSecondaryContainer
                    opacity: 0.75
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            BarPositionPreview {
                anchors.centerIn: parent
                vertical: Config.options.bar.vertical
                atBottom: Config.options.bar.bottom
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: root.options

                delegate: RippleButton {
                    id: option
                    required property var modelData

                    readonly property bool selected: root.current === modelData.value

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: 40
                    buttonRadius: 20
                    colBackground: selected ? Appearance.colors.colSecondary : Qt.rgba(1, 1, 1, 0.12)
                    colBackgroundHover: selected ? Appearance.colors.colSecondary : Qt.rgba(1, 1, 1, 0.22)
                    colRipple: Qt.rgba(1, 1, 1, 0.3)
                    downAction: () => {
                        const value = modelData.value;
                        Qt.callLater(() => {
                            Config.options.bar.bottom = (value & 1) !== 0;
                            Config.options.bar.vertical = (value & 2) !== 0;
                        });
                    }

                    contentItem: RowLayout {
                        spacing: 4
                        Item { Layout.fillWidth: true }
                        MaterialSymbol {
                            text: option.modelData.icon
                            iconSize: 16
                            color: option.selected ? Appearance.colors.colOnSecondary : Appearance.colors.colOnSecondaryContainer
                        }
                        StyledText {
                            text: option.modelData.name
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.Medium
                            color: option.selected ? Appearance.colors.colOnSecondary : Appearance.colors.colOnSecondaryContainer
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

DashboardCard {
    id: root

    property var control: null
    property string title: ""
    property string icon: "tune"
    property var tileShape: MaterialShape.Shape.Pentagon

    readonly property var currentValue: control ? control.get() : null

    tint: Appearance.colors.colTertiaryContainer

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            MaterialShapeWrappedMaterialSymbol {
                shape: root.tileShape
                text: root.icon
                iconSize: 24
                fill: 1
                padding: 10
                color: Appearance.colors.colTertiary
                colSymbol: Appearance.colors.colOnTertiary
            }

            StyledText {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnTertiaryContainer
                elide: Text.ElideRight
            }

            RippleButton {
                visible: root.control?.reset !== undefined
                enabled: root.control?.canReset?.() ?? true
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: 18
                colBackground: Qt.rgba(1, 1, 1, 0.12)
                colBackgroundHover: Qt.rgba(1, 1, 1, 0.22)
                colRipple: Qt.rgba(1, 1, 1, 0.3)
                opacity: enabled ? 1 : 0.4
                downAction: () => Qt.callLater(() => root.control.reset())

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    text: "restart_alt"
                    iconSize: 20
                    color: Appearance.colors.colOnTertiaryContainer
                }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: root.control?.options ?? []

                delegate: RippleButton {
                    id: option
                    required property var modelData

                    readonly property bool selected: root.currentValue === modelData.value

                    Layout.fillWidth: true
                    Layout.preferredWidth: implicitWidth
                    implicitHeight: 44
                    horizontalPadding: 20
                    buttonRadius: 22
                    colBackground: selected ? Appearance.colors.colTertiary : Qt.rgba(1, 1, 1, 0.12)
                    colBackgroundHover: selected ? Appearance.colors.colTertiary : Qt.rgba(1, 1, 1, 0.22)
                    colRipple: Qt.rgba(1, 1, 1, 0.3)
                    downAction: () => {
                        const value = modelData.value;
                        Qt.callLater(() => root.control.set(value));
                    }

                    contentItem: Item {
                        id: optionContent
                        implicitWidth: optionRow.implicitWidth
                        implicitHeight: optionRow.implicitHeight

                        RowLayout {
                            id: optionRow
                            anchors.centerIn: parent
                            width: Math.min(implicitWidth, optionContent.width)
                            spacing: 6

                            MaterialSymbol {
                                visible: text !== "" && optionContent.width >= optionLabel.implicitWidth + 24
                                text: option.modelData.icon ?? ""
                                iconSize: 18
                                fill: option.selected ? 1 : 0
                                color: option.selected ? Appearance.colors.colOnTertiary : Appearance.colors.colOnTertiaryContainer
                            }
                            StyledText {
                                id: optionLabel
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                text: option.modelData.displayName
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium
                                color: option.selected ? Appearance.colors.colOnTertiary : Appearance.colors.colOnTertiaryContainer
                            }
                        }
                    }
                }
            }
        }
    }
}

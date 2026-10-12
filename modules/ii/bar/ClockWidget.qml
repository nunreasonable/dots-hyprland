import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

BarWidgetSwitcher {
    id: root
    property color contentColor: Appearance.colors.colOnLayer1
    property bool contentColorOverridden: false
    property bool borderless: Config.options.bar.borderless
    property bool showDate: Config.options.time.showDate && Config.options.bar.verbose
    property bool classic: false
    readonly property string dateTimeString: DateTime.time
    readonly property bool hasAmPm: root.dateTimeString.toLowerCase().includes("am") || root.dateTimeString.toLowerCase().includes("pm")

    horizontalExtraPadding: root.classic ? 0 : 12
    rowDefault: root.classic ? classicRow : layoutRow
    rowMaterial: root.classic ? classicRow : materialRow
    colDefault: columnContent
    colMaterial: materialColumn

    Component {
        id: classicRow
        RowLayout {
            spacing: 4

            StyledText {
                font.pixelSize: Appearance.font.pixelSize.large
                color: root.contentColor
                text: DateTime.time
            }

            StyledText {
                visible: root.showDate
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.contentColor
                text: "•"
            }

            StyledText {
                visible: root.showDate
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.contentColor
                text: DateTime.longDate
            }
        }
    }

    Component {
        id: layoutRow
        RowLayout {
            spacing: 4

            StyledText {
                visible: root.showDate
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.contentColor
                text: DateTime.longDate
            }

            StyledText {
                visible: root.showDate
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.contentColor
                text: "•"
            }

            StyledText {
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.contentColor
                text: DateTime.time
                font.letterSpacing: -0.4
                font.features: {
                    "tnum": 1
                }
            }
        }
    }

    Component {
        id: materialRow
        RowLayout {
            id: pill
            readonly property var timeParts: DateTime.time.split(/[: ]/)
            readonly property string ampm: pill.timeParts.find(part => /^(am|pm)$/i.test(part)) ?? ""
            readonly property string time: pill.timeParts.filter(part => !/^(am|pm)$/i.test(part)).join(":")
            spacing: 4

            StyledText {
                visible: root.showDate
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnPrimaryContainer
                text: DateTime.longDate
                Layout.alignment: Qt.AlignVCenter
                leftPadding: 5
            }

            Rectangle {
                implicitWidth: timeText.implicitWidth + 16
                implicitHeight: 24
                radius: Appearance.rounding.full
                color: Appearance.colors.colPrimary

                StyledText {
                    id: timeText
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    color: Appearance.colors.colOnPrimary
                    font.weight: Font.Bold
                    text: pill.time
                    font.features: {
                        "tnum": 1
                    }
                    font.letterSpacing: -0.4
                }
            }

            Rectangle {
                visible: pill.ampm !== ""
                z: 1
                implicitWidth: ampmText.implicitWidth + 8
                implicitHeight: 24
                radius: Appearance.rounding.full
                color: Appearance.colors.colTertiaryContainer
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: -10

                StyledText {
                    id: ampmText
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colPrimary
                    text: pill.ampm
                }
            }
        }
    }

    Component {
        id: columnContent
        ColumnLayout {
            spacing: root.hasAmPm ? 1 : 0

            Column {
                Layout.alignment: Qt.AlignHCenter
                spacing: -4

                Repeater {
                    model: root.dateTimeString.split(/[: ]/)
                    delegate: StyledText {
                        required property string modelData
                        width: implicitWidth
                        horizontalAlignment: Text.AlignHCenter
                        font.letterSpacing: -0.9
                        font.features: {
                            "tnum": 1
                        }
                        font.pixelSize: modelData.match(/am|pm/i) ? Appearance.font.pixelSize.smaller : Appearance.font.pixelSize.large
                        color: root.contentColor
                        text: modelData.padStart(2, "0")
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 5
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: root.contentColor
                text: DateTime.shortDate
            }
        }
    }

    Component {
        id: materialColumn
        ColumnLayout {
            spacing: 2

            Column {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
                spacing: -4

                Repeater {
                    model: root.dateTimeString.split(/[: ]/)
                    delegate: StyledText {
                        required property string modelData
                        width: implicitWidth
                        horizontalAlignment: Text.AlignHCenter
                        font.letterSpacing: -0.2
                        font.features: {
                            "tnum": 1
                        }
                        font.pixelSize: modelData.match(/am|pm/i) ? Appearance.font.pixelSize.smallest - 2 : Appearance.font.pixelSize.small
                        color: Appearance.colors.colPrimary
                        text: modelData.padStart(2, "0")
                    }
                }
            }

            Rectangle {
                implicitWidth: 25
                implicitHeight: 25
                radius: Appearance.rounding.full
                color: Appearance.colors.colPrimary
                Layout.alignment: Qt.AlignHCenter

                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: 0
                    text: "calendar_clock"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnPrimary
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow

        ClockWidgetPopup {
            hoverTarget: mouseArea
        }
    }
}

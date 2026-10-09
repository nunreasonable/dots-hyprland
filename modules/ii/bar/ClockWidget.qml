import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property color contentColor: Appearance.colors.colOnLayer1
    property bool contentColorOverridden: false
    property bool borderless: Config.options.bar.borderless
    property bool showDate: Config.options.bar.verbose
    property bool classic: false
    property bool vertical: false
    readonly property string dateTimeString: DateTime.time
    readonly property bool hasAmPm: root.dateTimeString.toLowerCase().includes("am") || root.dateTimeString.toLowerCase().includes("pm")

    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : contentLoader.implicitWidth + (root.classic ? 0 : 12)
    implicitHeight: root.vertical ? contentLoader.implicitHeight : Appearance.sizes.barHeight

    Loader {
        id: contentLoader
        anchors.centerIn: parent
        sourceComponent: root.vertical ? columnContent : root.classic ? classicRow : layoutRow
    }

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

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow

        ClockWidgetPopup {
            hoverTarget: mouseArea
        }
    }
}

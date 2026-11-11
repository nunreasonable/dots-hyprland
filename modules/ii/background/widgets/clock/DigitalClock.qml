pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: clockColumn
    spacing: 4

    property bool isVertical: Config.options.background.widgets.clock.digital.vertical
    property color colText: Appearance.colors.colOnSecondaryContainer
    property var textHorizontalAlignment: Text.AlignHCenter

    // Time
    Row {
        id: sekaiKeys
        visible: SekaiTheme.active
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: 8
        spacing: timeTextTop.font.pixelSize * 0.06
        readonly property real keySize: timeTextTop.font.pixelSize * 0.62

        Repeater {
            model: timeTextTop.text.length

            Item {
                id: key
                required property int index
                readonly property string character: timeTextTop.text.charAt(key.index)
                readonly property bool isKey: /[0-9A-Za-z]/.test(key.character)
                width: key.isKey ? sekaiKeys.keySize : sekaiKeys.keySize * 0.42
                height: sekaiKeys.keySize * 1.3

                SekaiBlock {
                    visible: key.isKey
                    anchors.fill: parent
                    cornerRadius: sekaiKeys.keySize * 0.28
                    ringWidth: Math.max(3, sekaiKeys.keySize * 0.07)
                    fillColor: SekaiTheme.fill
                }

                Text {
                    id: keyText
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: key.isKey ? -SekaiTheme.shadowOffset / 2 : 0
                    text: key.character
                    color: key.isKey ? SekaiTheme.text : clockColumn.colText
                    font {
                        pixelSize: sekaiKeys.keySize * 0.82
                        weight: Font.Black
                        family: timeTextTop.font.family
                    }
                    onTextChanged: if (key.isKey) keyPop.restart()
                }

                SekaiPopAnimation {
                    id: keyPop
                    target: key
                }
            }
        }
    }

    ClockText {
        id: timeTextTop
        visible: !SekaiTheme.active
        text: clockColumn.isVertical ? DateTime.time.split(":")[0].padStart(2, "0") : DateTime.time
        color: clockColumn.colText
        horizontalAlignment: Text.AlignHCenter
        font {
            pixelSize: Config.options.background.widgets.clock.digital.font.size
            weight: Config.options.background.widgets.clock.digital.font.weight
            family: Config.options.background.widgets.clock.digital.font.family
            variableAxes: ({
                    "wdth": Config.options.background.widgets.clock.digital.font.width,
                    "ROND": Config.options.background.widgets.clock.digital.font.roundness
                })
        }
    }

    Loader {
        Layout.topMargin: -40
        Layout.fillWidth: true
        active: clockColumn.isVertical
        visible: active
        sourceComponent: ClockText {
            id: timeTextBottom
            text: DateTime.time.split(":")[1].split(" ")[0].padStart(2, "0")
            color: clockColumn.colText
            horizontalAlignment: clockColumn.textHorizontalAlignment
            font {
                pixelSize: timeTextTop.font.pixelSize
                weight: timeTextTop.font.weight
                family: timeTextTop.font.family
                variableAxes: timeTextTop.font.variableAxes
            }
        }
    }

    // Date
    ClockText {
        visible: Config.options.background.widgets.clock.digital.showDate
        Layout.topMargin: SekaiTheme.active ? 4 : -20
        Layout.fillWidth: true
        text: DateTime.longDate
        color: clockColumn.colText
        horizontalAlignment: clockColumn.textHorizontalAlignment
    }

    // Quote
    ClockText {
        visible: Config.options.background.widgets.clock.quote.enable && Config.options.background.widgets.clock.quote.text.length > 0
        font.pixelSize: Appearance.font.pixelSize.normal
        text: Config.options.background.widgets.clock.quote.text
        animateChange: false
        color: clockColumn.colText
        horizontalAlignment: clockColumn.textHorizontalAlignment
    }
}

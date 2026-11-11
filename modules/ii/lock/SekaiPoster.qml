import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

SekaiBlock {
    id: root

    readonly property date today: DateTime.clock.date
    readonly property int firstWeekday: (new Date(root.today.getFullYear(), root.today.getMonth(), 1).getDay() + 6) % 7
    readonly property int daysInMonth: new Date(root.today.getFullYear(), root.today.getMonth() + 1, 0).getDate()

    width: 300
    height: column.implicitHeight + 40 + SekaiTheme.shadowOffset
    cornerRadius: 28
    ringWidth: 6

    ColumnLayout {
        id: column
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 20
        }
        spacing: 2

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 34
            radius: 17
            color: SekaiTheme.outline
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: SekaiTheme.accentA }
                GradientStop { position: 1; color: SekaiTheme.accentB }
            }

            StyledText {
                anchors.centerIn: parent
                text: Qt.locale().toString(root.today, "dddd").toUpperCase()
                color: SekaiTheme.textOnAccent
                font.pixelSize: 15
                font.weight: Font.Black
                font.letterSpacing: 2
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.today.getDate()
            color: SekaiTheme.text
            font.pixelSize: 120
            font.weight: Font.Black
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: -16
            text: Qt.locale().toString(root.today, "MMMM yyyy")
            color: SekaiTheme.text
            opacity: 0.8
            font.pixelSize: 18
            font.weight: Font.Bold
        }

        Grid {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
            columns: 7
            spacing: 4

            Repeater {
                model: 7
                StyledText {
                    required property int index
                    width: 32
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().dayName((index + 1) % 7, Locale.NarrowFormat)
                    color: SekaiTheme.text
                    opacity: 0.55
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }
            }

            Repeater {
                model: root.firstWeekday + root.daysInMonth

                Item {
                    id: cell
                    required property int index
                    readonly property int day: cell.index - root.firstWeekday + 1
                    readonly property bool isToday: cell.day === root.today.getDate()
                    width: 32
                    height: 30

                    Rectangle {
                        visible: cell.isToday
                        anchors.centerIn: parent
                        width: 30
                        height: 28
                        radius: 14
                        color: SekaiTheme.accentA
                        border.width: 2
                        border.color: SekaiTheme.outline
                    }

                    StyledText {
                        visible: cell.day > 0
                        anchors.centerIn: parent
                        text: cell.day
                        color: cell.isToday ? SekaiTheme.textOnAccent : SekaiTheme.text
                        font.pixelSize: 13
                        font.weight: cell.isToday ? Font.Black : Font.DemiBold
                    }
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property color colText: Appearance.colors.colOnSecondaryContainer
    readonly property color accentTop: Appearance.colors.colPrimary
    readonly property color accentBottom: ColorUtils.transparentize(ColorUtils.mix(root.accentTop, "black", 0.5), 0.45)

    readonly property var currentDate: DateTime.clock.date
    readonly property string dayNumber: root.currentDate.getDate().toString().padStart(2, "0")
    readonly property string monthName: root.currentDate.toLocaleDateString(Qt.locale(), "MMMM").toUpperCase()
    readonly property string weekdaySpaced: root.currentDate.toLocaleDateString(Qt.locale(), "dddd").toUpperCase().split("").join(" ")

    implicitWidth: mainRow.implicitWidth
    implicitHeight: mainRow.implicitHeight

    RowLayout {
        id: mainRow
        spacing: 16

        Item {
            id: weekdayItem
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: weekdayText.implicitHeight
            implicitHeight: weekdayText.implicitWidth

            Text {
                id: weekdayText
                anchors.centerIn: parent
                rotation: -90
                text: root.weekdaySpaced
                color: root.colText
                style: Text.Raised
                styleColor: Appearance.colors.colShadow
                renderType: Text.CurveRendering
                font {
                    family: Appearance.font.family.main
                    pixelSize: Appearance.font.pixelSize.small
                    weight: 600
                    letterSpacing: 2
                }
            }
        }

        ColumnLayout {
            id: dateColumn
            spacing: 0

            Item {
                id: digitsItem
                implicitWidth: digitsText.implicitWidth
                implicitHeight: digitsText.implicitHeight

                Text {
                    id: digitsText
                    visible: false
                    text: root.dayNumber
                    renderType: Text.CurveRendering
                    font {
                        family: Appearance.font.family.title
                        pixelSize: 190
                        weight: 1000
                        variableAxes: ({
                                "wght": 1000,
                                "wdth": 68
                            })
                    }
                }

                Rectangle {
                    id: digitsGradient
                    visible: false
                    anchors.fill: digitsText
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop {
                            position: 0.0
                            color: root.accentTop
                        }
                        GradientStop {
                            position: 1.0
                            color: root.accentBottom
                        }
                    }
                }

                OpacityMask {
                    anchors.fill: digitsText
                    source: digitsGradient
                    maskSource: digitsText
                }
            }

            StyledText {
                id: monthText
                Layout.topMargin: -digitsText.implicitHeight * 0.32
                text: root.monthName
                color: root.colText
                style: Text.Raised
                styleColor: Appearance.colors.colShadow
                font {
                    family: Appearance.font.family.main
                    pixelSize: 36
                    weight: 900
                    letterSpacing: 1
                }
            }

            StyledText {
                id: timeText
                Layout.topMargin: 10
                text: DateTime.time
                color: root.colText
                style: Text.Raised
                styleColor: Appearance.colors.colShadow
                font {
                    family: Appearance.font.family.main
                    pixelSize: 26
                    weight: 500
                }
            }

            Rectangle {
                Layout.topMargin: 4
                implicitWidth: Math.max(24, timeText.implicitWidth * 0.55)
                implicitHeight: 2
                color: root.colText
                opacity: 0.8
            }
        }
    }
}

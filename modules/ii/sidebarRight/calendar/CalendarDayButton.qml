import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

RippleButton {
    id: button
    property string day
    property int isToday
    property bool bold
    property var eventDotColors: []

    Layout.fillWidth: false
    Layout.fillHeight: false
    implicitWidth: 38;
    implicitHeight: 38;

    toggled: (isToday == 1)
    buttonRadius: Appearance.rounding.small

    contentItem: Item {
        anchors.fill: parent
        StyledText {
            anchors.fill: parent
            text: day
            horizontalAlignment: Text.AlignHCenter
            font.weight: bold ? Font.DemiBold : Font.Normal
            color: (isToday == 1) ? Appearance.m3colors.m3onPrimary :
                (isToday == 0) ? Appearance.colors.colOnLayer1 :
                Appearance.colors.colOutlineVariant

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }

        Row {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 3
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2
            visible: button.eventDotColors.length > 0

            Repeater {
                model: button.eventDotColors
                delegate: Rectangle {
                    required property var modelData
                    width: 4
                    height: 4
                    radius: 2
                    color: modelData
                }
            }
        }
    }
}


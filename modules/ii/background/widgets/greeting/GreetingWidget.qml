import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root
    configEntryName: "greeting"

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    readonly property string displayName: Config.options.background.widgets.greeting.name !== "" ? Config.options.background.widgets.greeting.name : SystemInfo.username
    readonly property string nameSpan: "<font color=\"" + Appearance.colors.colPrimary.toString() + "\">" + root.displayName + "</font>"

    readonly property var greeting: Greetings.pick(root.nameSpan, DateTime.clock.date, "widget")
    readonly property string greetingLine: root.greeting.title

    readonly property string wishLine: root.greeting.subtitle

    WidgetCard {
        id: card
        implicitWidth: 320
        implicitHeight: contentColumn.implicitHeight + 32
        widget: root

        ColumnLayout {
            id: contentColumn
            anchors {
                fill: parent
                margins: 16
            }
            spacing: 4

            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: root.greetingLine
                color: Appearance.colors.colOnPrimaryContainer
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Bold
            }

            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: root.wishLine
                color: Appearance.colors.colOnPrimaryContainer
                opacity: 0.75
                font.pixelSize: Appearance.font.pixelSize.small
            }
        }
    }
}

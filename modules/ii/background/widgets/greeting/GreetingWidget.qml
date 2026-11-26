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

    function periodFor(hour) {
        if (hour >= 5 && hour < 12)
            return "morning";
        if (hour >= 12 && hour < 18)
            return "afternoon";
        if (hour >= 18 && hour < 22)
            return "evening";
        return "night";
    }

    readonly property string period: root.periodFor(DateTime.hour24)
    readonly property string displayName: Config.options.background.widgets.greeting.name !== "" ? Config.options.background.widgets.greeting.name : SystemInfo.username
    readonly property string nameSpan: "<font color=\"" + Appearance.colors.colPrimary.toString() + "\">" + root.displayName + "</font>"

    readonly property string greetingLine: {
        if (root.period === "morning")
            return Translation.tr("Good morning, %1.").arg(root.nameSpan);
        if (root.period === "afternoon")
            return Translation.tr("Good afternoon, %1.").arg(root.nameSpan);
        if (root.period === "evening")
            return Translation.tr("Good evening, %1.").arg(root.nameSpan);
        return Translation.tr("Good night, %1.").arg(root.nameSpan);
    }

    readonly property string wishLine: {
        if (root.period === "morning")
            return Translation.tr("I wish you a pleasant morning.");
        if (root.period === "afternoon")
            return Translation.tr("I wish you a pleasant afternoon.");
        if (root.period === "evening")
            return Translation.tr("I wish you a pleasant evening.");
        return Translation.tr("I wish you a peaceful night.");
    }

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

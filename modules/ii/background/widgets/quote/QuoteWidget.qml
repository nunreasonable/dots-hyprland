import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.background.widgets
import "Quotes.js" as Quotes

AbstractBackgroundWidget {
    id: root
    configEntryName: "quote"

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    property int currentIndex: Math.floor(Math.random() * Quotes.quotes.length)
    readonly property var currentQuote: Quotes.quotes[root.currentIndex] ?? Quotes.quotes[0]

    function nextQuote() {
        if (Quotes.quotes.length <= 1)
            return;
        let next = root.currentIndex;
        while (next === root.currentIndex) {
            next = Math.floor(Math.random() * Quotes.quotes.length);
        }
        root.currentIndex = next;
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
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                MaterialSymbol {
                    text: "format_quote"
                    iconSize: Appearance.font.pixelSize.huge
                    color: Appearance.colors.colPrimary
                }

                Item {
                    Layout.fillWidth: true
                }

                RippleButtonWithIcon {
                    materialIcon: "refresh"
                    mainText: Translation.tr("Next quote")
                    buttonRadius: Appearance.rounding.small
                    onClicked: root.nextQuote()
                }
            }

            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: "“" + Translation.tr(root.currentQuote.text) + "”"
                color: Appearance.colors.colOnPrimaryContainer
                font.pixelSize: Appearance.font.pixelSize.normal
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: "— " + Translation.tr(root.currentQuote.author)
                color: Appearance.colors.colPrimary
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
            }
        }
    }
}

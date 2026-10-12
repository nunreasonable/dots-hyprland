import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets as W
import qs.modules.settingsPc.widgets

ContentPage {
    id: page
    forceWidth: true
    bottomContentPadding: 15

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            icon: "monitor"
            shape: W.MaterialShape.Shape.Cookie6Sided
            title: Translation.tr("Displays")
        }

        ContentSection {
            icon: "select_window"
            shape: W.MaterialShape.Shape.Gem
            title: Translation.tr("Windows")
        }

        ContentSection {
            icon: "keyboard"
            shape: W.MaterialShape.Shape.Puffy
            title: Translation.tr("Input")
        }

        ContentSection {
            icon: "bedtime"
            shape: W.MaterialShape.Shape.Sunny
            title: Translation.tr("Idle")
        }

        ContentSection {
            icon: "rocket_launch"
            shape: W.MaterialShape.Shape.Pentagon
            title: Translation.tr("Autostart")
        }

        ContentSection {
            icon: "animation"
            shape: W.MaterialShape.Shape.SoftBurst
            title: Translation.tr("Animations")
        }
    }
}

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "monitor"
        title: Translation.tr("Displays")
    }

    ContentSection {
        icon: "select_window"
        title: Translation.tr("Windows")
    }

    ContentSection {
        icon: "keyboard"
        title: Translation.tr("Input")
    }

    ContentSection {
        icon: "bedtime"
        title: Translation.tr("Idle")
    }

    ContentSection {
        icon: "rocket_launch"
        title: Translation.tr("Autostart")
    }

    ContentSection {
        icon: "animation"
        title: Translation.tr("Animations")
    }
}

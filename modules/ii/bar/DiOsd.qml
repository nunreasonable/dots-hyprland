import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

RowLayout {
    id: diOsdRoot
    required property Item di
    anchors {
        fill: parent
        leftMargin: 4
        rightMargin: 10
    }
    spacing: 6

    readonly property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    readonly property var brightnessMonitor: Brightness.getMonitorForScreen(diOsdRoot.focusedScreen)

    MaterialShapeWrappedMaterialSymbol {
        Layout.alignment: Qt.AlignVCenter
        wrappedShape: MaterialShape.Shape.Cookie12Sided
        color: Appearance.colors.colPrimary
        colSymbol: Appearance.colors.colOnPrimary
        text: diOsdRoot.di.iconForProviderId("osd")
        iconSize: 16
        fill: 1
        padding: 4
    }

    Item {
        Layout.fillWidth: true
    }

    StyledText {
        Layout.alignment: Qt.AlignVCenter
        text: {
            switch (GlobalStates.osdIndicatorType) {
            case "brightness":
                return `${Math.round((diOsdRoot.brightnessMonitor?.brightness ?? 0.5) * 100)}`;
            case "gamma":
                return `${Math.round(Hyprsunset.gamma ?? 50)}`;
            default:
                return `${Math.round((Audio.sink?.audio?.volume ?? 0) * 100)}`;
            }
        }
        font.pixelSize: Appearance.font.pixelSize.small
        font.features: {
            "tnum": 1
        }
        color: Appearance.colors.colOnLayer0
    }
}

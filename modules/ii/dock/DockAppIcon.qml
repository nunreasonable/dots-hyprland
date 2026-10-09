import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

Item {
    id: root

    property string iconSource: ""
    property int windowCount: 0
    property bool active: false
    property real iconSize: DockStyle.iconSize
    property bool monochrome: Config.options.dock.monochromeIcons
    readonly property real dotWidth: 10
    readonly property real dotHeight: 4

    Loader {
        id: iconImageLoader
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        sourceComponent: IconImage {
            source: root.iconSource
            implicitSize: root.iconSize
        }
    }

    Loader {
        active: root.monochrome
        anchors.fill: iconImageLoader
        sourceComponent: Item {
            Desaturate {
                id: desaturatedIcon
                visible: false
                anchors.fill: parent
                source: iconImageLoader
                desaturation: 0.8
            }
            ColorOverlay {
                anchors.fill: desaturatedIcon
                source: desaturatedIcon
                color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.9)
            }
        }
    }

    RowLayout {
        visible: !DockStyle.vertical
        spacing: 3
        anchors {
            top: iconImageLoader.bottom
            topMargin: 2
            horizontalCenter: parent.horizontalCenter
        }
        Repeater {
            model: Math.min(root.windowCount, 3)
            delegate: Rectangle {
                required property int index
                radius: Appearance.rounding.full
                implicitWidth: root.windowCount <= 3 ? root.dotWidth : root.dotHeight
                implicitHeight: root.dotHeight
                color: root.active ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.4)
            }
        }
    }

    ColumnLayout {
        visible: DockStyle.vertical
        spacing: 3
        anchors {
            left: DockStyle.position === "left" ? iconImageLoader.right : undefined
            right: DockStyle.position === "right" ? iconImageLoader.left : undefined
            leftMargin: 4
            rightMargin: 4
            verticalCenter: parent.verticalCenter
        }
        Repeater {
            model: Math.min(root.windowCount, 3)
            delegate: Rectangle {
                required property int index
                radius: Appearance.rounding.full
                implicitWidth: root.dotHeight
                implicitHeight: root.windowCount <= 3 ? root.dotWidth : root.dotHeight
                color: root.active ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.4)
            }
        }
    }
}

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.bar as Bar
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root

    property var screen: root.QsWindow.window?.screen
    readonly property bool trayHasItems: SystemTray.items.values.length > 0
    readonly property var effectiveLeftLayout: root.filterTray(BarLayouts.leftLayout)
    readonly property var effectiveMiddleLayout: root.filterTray(BarLayouts.middleLayout).filter(name => name !== "dynamicIsland")
    readonly property var effectiveRightLayout: root.filterTray(BarLayouts.rightLayout)
    readonly property bool centerOnly: root.effectiveLeftLayout.length === 0 && root.effectiveRightLayout.length === 0
    readonly property color barColor: Config.options.bar.followFrameColor ? Appearance.getColorFromName(Config.options.bar.frameColor) : Appearance.colors.colLayer0
    readonly property real groupSpacing: Config.options.bar.borderless ? -4 : 2
    readonly property real sideMargin: Config.options.bar.cornerStyle === 1 ? 4 : 10
    readonly property real fitNeeded: middleSection.height + 2 * Math.max(topSection.height, bottomSection.height) + 2 * root.sideMargin
    readonly property real fitScale: (Platform.isWindows && root.fitNeeded > 0 && contentContainer.height > 0) ? Math.max(0.5, Math.min(1, contentContainer.height / root.fitNeeded)) : 1

    function filterTray(layout) {
        if (root.trayHasItems)
            return layout;
        return layout.filter(name => name !== "sysTray");
    }

    function widgetUrl(name) {
        const file = BarLayouts.file(name);
        return file === "" ? "" : Qt.resolvedUrl("../bar/" + file);
    }

    function mirroredFor(layout, index) {
        return layout.slice(0, index).filter(name => name === "visualizer").length % 2 === 1;
    }

    Binding {
        target: GlobalStates
        property: "barCenterOnly"
        value: root.centerOnly
        restoreMode: Binding.RestoreBinding
    }

    component LayoutGroup: Bar.BarWidgetGroup {
        id: group
        required property string modelData
        required property int index
        property var sectionLayout: []

        Layout.fillWidth: true
        vertical: true
        currentIndex: group.index
        widgetName: group.modelData
        totalCount: group.sectionLayout.length
        paintBackground: group.modelData !== "divisor"

        Loader {
            Layout.fillWidth: true
            source: root.widgetUrl(group.modelData)
            onLoaded: {
                if (item && "vertical" in item)
                    item.vertical = true;
                if (item && item.hasOwnProperty("mirrored"))
                    item.mirrored = root.mirroredFor(group.sectionLayout, group.index);
            }
        }
    }

    Loader {
        active: Config.options.bar.showBackground && Config.options.bar.cornerStyle === 1 && Config.options.bar.floatStyleShadow && !root.centerOnly
        anchors.fill: barBackground
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined
            target: barBackground
        }
    }

    Rectangle {
        id: barBackground
        anchors {
            fill: parent
            margins: Config.options.bar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0
        }
        color: (!root.centerOnly && Config.options.bar.showBackground) ? root.barColor : "transparent"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: (!root.centerOnly && Config.options.bar.cornerStyle === 1) ? 1 : 0
        border.color: Appearance.colors.colLayer0Border
    }

    Rectangle {
        id: centerPill
        visible: root.centerOnly && Config.options.bar.showBackground
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        height: (middleColumn.implicitHeight + 7) * root.fitScale
        width: parent.width - (Config.options.bar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut * 2 : 0)
        color: root.barColor
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
        border.color: Appearance.colors.colLayer0Border
        bottomRightRadius: Config.options.bar.cornerStyle === 0 && !Config.options.bar.bottom ? Appearance.rounding.screenRounding : radius
        topRightRadius: Config.options.bar.cornerStyle === 0 && !Config.options.bar.bottom ? Appearance.rounding.screenRounding : radius
        bottomLeftRadius: Config.options.bar.cornerStyle === 0 && Config.options.bar.bottom ? Appearance.rounding.screenRounding : radius
        topLeftRadius: Config.options.bar.cornerStyle === 0 && Config.options.bar.bottom ? Appearance.rounding.screenRounding : radius
    }

    Item {
        id: contentContainer
        anchors.fill: barBackground

        Item {
            id: topSection
            anchors {
                top: parent.top
                topMargin: root.sideMargin
                left: parent.left
                right: parent.right
            }
            height: topColumn.implicitHeight
            transform: Scale {
                origin.x: topSection.width / 2
                origin.y: 0
                xScale: root.fitScale
                yScale: root.fitScale
            }

            ColumnLayout {
                id: topColumn
                anchors.fill: parent
                spacing: root.groupSpacing

                Repeater {
                    model: root.effectiveLeftLayout
                    delegate: LayoutGroup {
                        sectionLayout: root.effectiveLeftLayout
                    }
                }
            }
        }

        Item {
            id: middleSection
            anchors.centerIn: parent
            width: parent.width
            height: middleColumn.implicitHeight
            transform: Scale {
                origin.x: middleSection.width / 2
                origin.y: middleSection.height / 2
                xScale: root.fitScale
                yScale: root.fitScale
            }

            ColumnLayout {
                id: middleColumn
                anchors.fill: parent
                spacing: root.groupSpacing

                Repeater {
                    model: root.effectiveMiddleLayout
                    delegate: LayoutGroup {
                        sectionLayout: root.effectiveMiddleLayout
                    }
                }
            }
        }

        Item {
            id: bottomSection
            anchors {
                bottom: parent.bottom
                bottomMargin: root.sideMargin
                left: parent.left
                right: parent.right
            }
            height: bottomColumn.implicitHeight
            transform: Scale {
                origin.x: bottomSection.width / 2
                origin.y: bottomSection.height
                xScale: root.fitScale
                yScale: root.fitScale
            }

            ColumnLayout {
                id: bottomColumn
                anchors.fill: parent
                spacing: root.groupSpacing

                Repeater {
                    model: root.effectiveRightLayout
                    delegate: LayoutGroup {
                        sectionLayout: root.effectiveRightLayout
                    }
                }
            }
        }
    }
}

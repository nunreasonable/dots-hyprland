import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root

    property var screen: root.QsWindow.window?.screen
    readonly property bool trayHasItems: SystemTray.items.values.length > 0
    readonly property var effectiveLeftLayout: root.filterTray(BarLayouts.leftLayout)
    readonly property var effectiveMiddleLayout: root.filterTray(BarLayouts.middleLayout)
    readonly property var effectiveRightLayout: root.filterTray(BarLayouts.rightLayout)
    readonly property bool centerOnly: BarLayouts.centerOnly
    readonly property color barColor: Config.options.bar.followFrameColor ? Appearance.getColorFromName(Config.options.bar.frameColor) : Appearance.colors.colLayer0
    readonly property real groupSpacing: Config.options.bar.borderless ? -7 : 2
    readonly property real sideMargin: Config.options.bar.cornerStyle === 1 ? 4 : 8
    readonly property real fitNeeded: absoluteCenter.width + 2 * Math.max(leftSection.width, rightSection.width) + 2 * root.sideMargin
    readonly property real fitScale: (Platform.isWindows && root.fitNeeded > 0 && contentContainer.width > 0) ? Math.max(0.5, Math.min(1, contentContainer.width / root.fitNeeded)) : 1

    function filterTray(layout) {
        if (root.trayHasItems)
            return layout;
        return layout.filter(name => name !== "sysTray");
    }

    function widgetUrl(name) {
        const file = BarLayouts.file(name);
        return file === "" ? "" : Qt.resolvedUrl(file);
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

    component LayoutGroup: BarWidgetGroup {
        id: group
        required property string modelData
        required property int index
        property var sectionLayout: []

        Layout.fillHeight: true
        currentIndex: group.index
        widgetName: group.modelData
        totalCount: group.sectionLayout.length
        paintBackground: group.modelData !== "dynamicIsland" && group.modelData !== "divisor"

        Loader {
            Layout.fillHeight: true
            source: root.widgetUrl(group.modelData)
            onLoaded: {
                if (item && (group.modelData === "visualizer" || group.modelData === "dynamicIsland"))
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
        border.width: (!root.centerOnly && Config.options.bar.showBackground && Config.options.bar.cornerStyle === 1) ? 1 : 0
        border.color: Appearance.colors.colLayer0Border
    }

    RoundCorner {
        id: leftPillCorner
        visible: root.centerOnly && Config.options.bar.showBackground && Config.options.bar.cornerStyle === 0
        x: centerPill.x - implicitSize
        y: Config.options.bar.bottom ? parent.height - implicitSize : 0
        implicitSize: Appearance.rounding.screenRounding
        color: root.barColor
        corner: Config.options.bar.bottom ? RoundCorner.CornerEnum.BottomRight : RoundCorner.CornerEnum.TopRight
    }

    Rectangle {
        id: centerPill
        visible: root.centerOnly && Config.options.bar.showBackground
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        width: (GlobalStates.dynamicIslandEnabled ? (Config.options.bar.cornerStyle === 1 ? middleRow.implicitWidth + 8 : middleRow.implicitWidth - 4) : middleRow.implicitWidth + 10) * root.fitScale
        height: GlobalStates.dynamicIslandEnabled ? parent.height : parent.height - (Config.options.bar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut * 2 : 0)
        color: root.barColor
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
        border.color: Appearance.colors.colLayer0Border
        bottomLeftRadius: Config.options.bar.cornerStyle === 0 && !Config.options.bar.bottom ? Appearance.rounding.screenRounding : radius
        bottomRightRadius: Config.options.bar.cornerStyle === 0 && !Config.options.bar.bottom ? Appearance.rounding.screenRounding : radius
        topLeftRadius: Config.options.bar.cornerStyle === 0 && Config.options.bar.bottom ? Appearance.rounding.screenRounding : radius
        topRightRadius: Config.options.bar.cornerStyle === 0 && Config.options.bar.bottom ? Appearance.rounding.screenRounding : radius
    }

    RoundCorner {
        id: rightPillCorner
        visible: root.centerOnly && Config.options.bar.showBackground && Config.options.bar.cornerStyle === 0
        x: centerPill.x + centerPill.width
        y: Config.options.bar.bottom ? parent.height - implicitSize : 0
        implicitSize: Appearance.rounding.screenRounding
        color: root.barColor
        corner: Config.options.bar.bottom ? RoundCorner.CornerEnum.BottomLeft : RoundCorner.CornerEnum.TopLeft
    }

    Item {
        id: contentContainer
        anchors.fill: barBackground

        Item {
            id: leftSection
            anchors {
                left: parent.left
                leftMargin: root.sideMargin
                top: parent.top
                bottom: parent.bottom
            }
            width: leftRow.implicitWidth
            transform: Scale {
                origin.x: 0
                origin.y: leftSection.height / 2
                xScale: root.fitScale
                yScale: root.fitScale
            }

            RowLayout {
                id: leftRow
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
            id: absoluteCenter
            anchors.centerIn: parent
            width: middleRow.implicitWidth
            height: parent.height
            transform: Scale {
                origin.x: absoluteCenter.width / 2
                origin.y: absoluteCenter.height / 2
                xScale: root.fitScale
                yScale: root.fitScale
            }

            Loader {
                id: diLeftWidget
                anchors {
                    right: absoluteCenter.left
                    rightMargin: 8
                    verticalCenter: absoluteCenter.verticalCenter
                }
                active: GlobalStates.dynamicIslandEnabled && root.widgetUrl(Config.options.bar.dynamicIsland.leftWidget) !== ""
                source: active ? root.widgetUrl(Config.options.bar.dynamicIsland.leftWidget) : ""
            }

            Loader {
                id: diRightWidget
                anchors {
                    left: absoluteCenter.right
                    leftMargin: 8
                    verticalCenter: absoluteCenter.verticalCenter
                }
                active: GlobalStates.dynamicIslandEnabled && root.widgetUrl(Config.options.bar.dynamicIsland.rightWidget) !== ""
                source: active ? root.widgetUrl(Config.options.bar.dynamicIsland.rightWidget) : ""
            }

            RowLayout {
                id: middleRow
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
            id: rightSection
            anchors {
                right: parent.right
                rightMargin: root.sideMargin
                top: parent.top
                bottom: parent.bottom
            }
            width: rightRow.implicitWidth
            transform: Scale {
                origin.x: rightSection.width
                origin.y: rightSection.height / 2
                xScale: root.fitScale
                yScale: root.fitScale
            }

            RowLayout {
                id: rightRow
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

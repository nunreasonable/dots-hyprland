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
    readonly property bool centerOnly: BarLayouts.centerOnly
    readonly property color barColor: Config.options.bar.followFrameColor ? Appearance.getColorFromName(Config.options.bar.frameColor) : Appearance.colors.colLayer0

    readonly property int cornerStyle: Config.options.bar.cornerStyle
    readonly property bool isMaterial: root.cornerStyle === 3 || root.cornerStyle === 4
    readonly property bool isMaterialHug: root.cornerStyle === 4
    readonly property bool isSplitHug: root.cornerStyle === 6
    readonly property bool isPanel: root.cornerStyle === 5
    readonly property bool hasTabs: root.isMaterialHug || root.isSplitHug
    readonly property bool useTabWrapper: root.isMaterial || root.isSplitHug
    readonly property real tabRadius: Appearance.rounding.screenRounding
    readonly property bool atRight: Config.options.bar.bottom
    readonly property real wrapperSpacing: root.isSplitHug ? (Config.options.bar.borderless ? -4 : 2) : 3

    readonly property real groupSpacing: Config.options.bar.borderless ? -4 : root.isPanel ? 4 : 2
    readonly property real sideMargin: root.hasTabs ? 0 : root.useTabWrapper ? Appearance.sizes.hyprlandGapsOut : (root.cornerStyle === 1 || root.isPanel) ? 4 : 10
    readonly property real fitNeeded: middleSection.height + 2 * Math.max(topSection.height, bottomSection.height) + 2 * root.sideMargin
    readonly property real fitScale: (Platform.isWindows && root.fitNeeded > 0 && contentContainer.height > 0) ? Math.max(0.5, Math.min(1, contentContainer.height / root.fitNeeded)) : 1

    readonly property bool pillMask: root.useTabWrapper && !Config.options.bar.autoHide.enable
    readonly property rect leftMaskRect: root.wrapperRect(topSection, topWrapper.item, -1)
    readonly property rect centerMaskRect: root.wrapperRect(middleSection, middleWrapper.item, 0)
    readonly property rect rightMaskRect: root.wrapperRect(bottomSection, bottomWrapper.item, 1)

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

    function paintsMaterialPill(name) {
        if (!root.isMaterial)
            return false;
        return !["workspaces", "divisor", "powerButton", "media", "docktoPanel", "leftSidebarButton", "dynamicIsland", "avatar"].includes(name);
    }

    function materialPillColor(name) {
        switch (name) {
        case "media":
        case "sysTray":
            return Appearance.colors.colSecondaryContainer;
        case "resources":
            return Appearance.colors.colTertiaryContainer;
        case "systemIcons":
            return Appearance.colors.colPrimary;
        default:
            return Appearance.colors.colPrimaryContainer;
        }
    }

    function scaleOriginX(width) {
        if (!root.hasTabs)
            return width / 2;
        return root.atRight ? width : 0;
    }

    function wrapperRect(section, wrapper, edge) {
        if (!root.useTabWrapper || !wrapper || !wrapper.shown)
            return Qt.rect(0, 0, 0, 0);
        const s = root.fitScale;
        const ox = root.scaleOriginX(section.width);
        const oy = edge === -1 ? 0 : edge === 1 ? section.height : section.height / 2;
        return Qt.rect(contentContainer.x + section.x + ox + (wrapper.pillX - ox) * s, contentContainer.y + section.y + oy + (wrapper.pillY - oy) * s, wrapper.pillWidth * s, wrapper.pillHeight * s);
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
        paintMaterialPill: root.paintsMaterialPill(group.modelData)
        bgColor: root.materialPillColor(group.modelData)

        Loader {
            Layout.fillWidth: true
            source: root.widgetUrl(group.modelData)
            onLoaded: {
                if (item && "vertical" in item)
                    item.vertical = true;
                if (item && (group.modelData === "visualizer" || group.modelData === "dynamicIsland"))
                    item.mirrored = root.mirroredFor(group.sectionLayout, group.index);
            }
        }
    }

    component WrapperSection: Item {
        id: section
        property var sectionLayout: []
        property int edge: 0
        readonly property bool shown: section.sectionLayout.length > 0
        readonly property real reach: root.hasTabs ? root.tabRadius : 0
        readonly property real tabCorners: root.hasTabs ? (section.edge === 0 ? 2 : 1) : 0
        readonly property real pillHeight: wrapperColumn.implicitHeight + (root.hasTabs ? 16 : 10)
        readonly property real pillWidth: root.hasTabs ? section.width / root.fitScale : section.width
        readonly property real pillX: (root.hasTabs && root.atRight) ? section.width - section.pillWidth : 0
        readonly property real pillY: section.edge === -1 ? 0 : section.edge === 1 ? section.height - section.pillHeight : (section.height - section.pillHeight) / 2

        height: section.shown ? section.pillHeight + section.tabCorners * root.tabRadius : 0

        RoundCorner {
            visible: section.shown && root.hasTabs && section.edge !== -1
            x: root.atRight ? section.width - implicitSize : 0
            y: section.pillY - implicitSize
            implicitSize: root.tabRadius
            color: root.barColor
            corner: root.atRight ? RoundCorner.CornerEnum.BottomRight : RoundCorner.CornerEnum.BottomLeft
        }

        RoundCorner {
            visible: section.shown && root.hasTabs && section.edge !== 1
            x: root.atRight ? section.width - implicitSize : 0
            y: section.pillY + section.pillHeight
            implicitSize: root.tabRadius
            color: root.barColor
            corner: root.atRight ? RoundCorner.CornerEnum.TopRight : RoundCorner.CornerEnum.TopLeft
        }

        Rectangle {
            id: pill
            readonly property real reachTop: section.edge === -1 ? section.reach : 0
            readonly property real reachBottom: section.edge === 1 ? section.reach : 0
            readonly property real reachLeft: root.atRight ? 0 : section.reach
            visible: section.shown
            x: section.pillX - pill.reachLeft
            y: section.pillY - pill.reachTop
            width: section.pillWidth + section.reach
            height: section.pillHeight + pill.reachTop + pill.reachBottom
            radius: root.hasTabs ? root.tabRadius : Appearance.rounding.full
            color: root.barColor

            ColumnLayout {
                id: wrapperColumn
                x: pill.reachLeft + (section.pillWidth - implicitWidth) / 2
                y: pill.reachTop + (section.pillHeight - implicitHeight) / 2
                spacing: root.wrapperSpacing

                Repeater {
                    model: section.sectionLayout
                    delegate: LayoutGroup {
                        sectionLayout: section.sectionLayout
                    }
                }
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
        color: (!root.centerOnly && Config.options.bar.showBackground && !root.useTabWrapper) ? root.barColor : "transparent"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: (!root.centerOnly && Config.options.bar.showBackground && Config.options.bar.cornerStyle === 1) ? 1 : 0
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
            height: root.useTabWrapper ? topWrapper.height : topColumn.implicitHeight
            transform: Scale {
                origin.x: root.scaleOriginX(topSection.width)
                origin.y: 0
                xScale: root.fitScale
                yScale: root.fitScale
            }

            ColumnLayout {
                id: topColumn
                visible: !root.useTabWrapper
                anchors.fill: parent
                spacing: root.groupSpacing

                Repeater {
                    model: root.useTabWrapper ? [] : root.effectiveLeftLayout
                    delegate: LayoutGroup {
                        sectionLayout: root.effectiveLeftLayout
                    }
                }
            }

            Loader {
                id: topWrapper
                active: root.useTabWrapper
                anchors.left: parent.left
                anchors.right: parent.right
                sourceComponent: WrapperSection {
                    edge: -1
                    sectionLayout: root.effectiveLeftLayout
                }
            }
        }

        Item {
            id: middleSection
            anchors.centerIn: parent
            width: parent.width
            height: root.useTabWrapper ? middleWrapper.height : middleColumn.implicitHeight
            transform: Scale {
                origin.x: root.scaleOriginX(middleSection.width)
                origin.y: middleSection.height / 2
                xScale: root.fitScale
                yScale: root.fitScale
            }

            ColumnLayout {
                id: middleColumn
                visible: !root.useTabWrapper
                anchors.fill: parent
                spacing: root.groupSpacing

                Repeater {
                    model: root.useTabWrapper ? [] : root.effectiveMiddleLayout
                    delegate: LayoutGroup {
                        sectionLayout: root.effectiveMiddleLayout
                    }
                }
            }

            Loader {
                id: middleWrapper
                active: root.useTabWrapper
                anchors.left: parent.left
                anchors.right: parent.right
                sourceComponent: WrapperSection {
                    edge: 0
                    sectionLayout: root.effectiveMiddleLayout
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
            height: root.useTabWrapper ? bottomWrapper.height : bottomColumn.implicitHeight
            transform: Scale {
                origin.x: root.scaleOriginX(bottomSection.width)
                origin.y: bottomSection.height
                xScale: root.fitScale
                yScale: root.fitScale
            }

            ColumnLayout {
                id: bottomColumn
                visible: !root.useTabWrapper
                anchors.fill: parent
                spacing: root.groupSpacing

                Repeater {
                    model: root.useTabWrapper ? [] : root.effectiveRightLayout
                    delegate: LayoutGroup {
                        sectionLayout: root.effectiveRightLayout
                    }
                }
            }

            Loader {
                id: bottomWrapper
                active: root.useTabWrapper
                anchors.left: parent.left
                anchors.right: parent.right
                sourceComponent: WrapperSection {
                    edge: 1
                    sectionLayout: root.effectiveRightLayout
                }
            }
        }
    }
}

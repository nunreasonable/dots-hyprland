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

    readonly property int cornerStyle: Config.options.bar.cornerStyle
    readonly property bool isMaterial: root.cornerStyle === 3 || root.cornerStyle === 4
    readonly property bool isMaterialHug: root.cornerStyle === 4
    readonly property bool isSplitHug: root.cornerStyle === 6
    readonly property bool isPanel: root.cornerStyle === 5
    readonly property bool hasTabs: root.isMaterialHug || root.isSplitHug
    readonly property bool useTabWrapper: root.isMaterial || root.isSplitHug
    readonly property real tabRadius: Appearance.rounding.screenRounding
    readonly property bool atBottom: Config.options.bar.bottom
    readonly property real wrapperSpacing: root.isSplitHug ? (Config.options.bar.borderless ? -7 : 2) : 3

    readonly property real groupSpacing: Config.options.bar.borderless ? -7 : root.isPanel ? 4 : 2
    readonly property real sideMargin: root.hasTabs ? 0 : root.useTabWrapper ? Appearance.sizes.hyprlandGapsOut : (root.cornerStyle === 1 || root.isPanel) ? 4 : 8
    readonly property real fitNeeded: absoluteCenter.width + 2 * Math.max(leftSection.width, rightSection.width) + 2 * root.sideMargin
    readonly property real fitScale: (Platform.isWindows && root.fitNeeded > 0 && contentContainer.width > 0) ? Math.max(0.5, Math.min(1, contentContainer.width / root.fitNeeded)) : 1

    readonly property bool pillMask: root.useTabWrapper && !Config.options.bar.autoHide.enable
    readonly property rect leftMaskRect: root.wrapperRect(leftSection, leftWrapper.item, -1)
    readonly property rect centerMaskRect: root.centerRect()
    readonly property rect rightMaskRect: root.wrapperRect(rightSection, rightWrapper.item, 1)

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

    function paintsMaterialPill(name) {
        if (!root.isMaterial)
            return false;
        return !["workspaces", "divisor", "powerButton", "docktoPanel", "leftSidebarButton", "activeWindow", "dynamicIsland", "avatar"].includes(name);
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

    function scaleOriginY(height) {
        if (!root.hasTabs)
            return height / 2;
        return root.atBottom ? height : 0;
    }

    function wrapperRect(section, wrapper, edge) {
        if (!root.useTabWrapper || !wrapper || !wrapper.shown)
            return Qt.rect(0, 0, 0, 0);
        const s = root.fitScale;
        const ox = edge === -1 ? 0 : edge === 1 ? section.width : section.width / 2;
        const oy = root.scaleOriginY(section.height);
        const vy = root.hasTabs ? (root.atBottom ? section.height - wrapper.pillHeight : 0) : (section.height - wrapper.pillHeight) / 2;
        return Qt.rect(contentContainer.x + section.x + ox + (wrapper.pillX - ox) * s, contentContainer.y + section.y + oy + (vy - oy) * s, wrapper.pillWidth * s, wrapper.pillHeight * s);
    }

    function centerRect() {
        const r = root.wrapperRect(absoluteCenter, centerWrapper.item, 0);
        if (r.width <= 0)
            return r;
        const s = root.fitScale;
        const mid = contentContainer.x + absoluteCenter.x + absoluteCenter.width / 2;
        let left = r.x;
        let right = r.x + r.width;
        if (diLeftWidget.item)
            left = Math.min(left, mid - (absoluteCenter.width / 2 + diLeftWidget.anchors.rightMargin + diLeftWidget.width) * s);
        if (diRightWidget.item)
            right = Math.max(right, mid + (absoluteCenter.width / 2 + diRightWidget.anchors.leftMargin + diRightWidget.width) * s);
        if (!diLeftWidget.item && !diRightWidget.item)
            return r;
        return Qt.rect(left, contentContainer.y + absoluteCenter.y, right - left, absoluteCenter.height);
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
        visible: widgetLoader.item?.hasContent ?? true
        currentIndex: group.index
        widgetName: group.modelData
        totalCount: group.sectionLayout.length
        paintBackground: group.modelData !== "dynamicIsland" && group.modelData !== "divisor"
        paintMaterialPill: root.paintsMaterialPill(group.modelData)
        bgColor: root.materialPillColor(group.modelData)

        Loader {
            id: widgetLoader
            Layout.fillHeight: true
            source: root.widgetUrl(group.modelData)
            onLoaded: {
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
        readonly property real pillWidth: wrapperRow.implicitWidth + (root.hasTabs ? 16 : 10)
        readonly property real pillHeight: root.hasTabs ? section.height / root.fitScale : wrapperRow.implicitHeight
        readonly property real pillX: section.edge === -1 ? 0 : section.edge === 1 ? section.width - section.pillWidth : (section.width - section.pillWidth) / 2
        readonly property real pillY: root.hasTabs ? (root.atBottom ? section.height - section.pillHeight : 0) : (section.height - section.pillHeight) / 2

        width: section.shown ? section.pillWidth + section.tabCorners * root.tabRadius : 0

        RoundCorner {
            visible: section.shown && root.hasTabs && section.edge !== -1
            x: section.pillX - implicitSize
            y: root.atBottom ? section.height - implicitSize : 0
            implicitSize: root.tabRadius
            color: root.barColor
            corner: root.atBottom ? RoundCorner.CornerEnum.BottomRight : RoundCorner.CornerEnum.TopRight
        }

        RoundCorner {
            visible: section.shown && root.hasTabs && section.edge !== 1
            x: section.pillX + section.pillWidth
            y: root.atBottom ? section.height - implicitSize : 0
            implicitSize: root.tabRadius
            color: root.barColor
            corner: root.atBottom ? RoundCorner.CornerEnum.BottomLeft : RoundCorner.CornerEnum.TopLeft
        }

        Rectangle {
            id: pill
            readonly property real reachStart: section.edge === -1 ? section.reach : 0
            readonly property real reachEnd: section.edge === 1 ? section.reach : 0
            readonly property real reachTop: root.atBottom ? 0 : section.reach
            visible: section.shown
            x: section.pillX - pill.reachStart
            y: section.pillY - pill.reachTop
            width: section.pillWidth + pill.reachStart + pill.reachEnd
            height: section.pillHeight + section.reach
            radius: root.hasTabs ? root.tabRadius : Appearance.rounding.full
            color: root.barColor

            RowLayout {
                id: wrapperRow
                x: pill.reachStart + (section.pillWidth - implicitWidth) / 2
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
        visible: root.centerOnly && Config.options.bar.showBackground && !root.useTabWrapper
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
            width: root.useTabWrapper ? leftWrapper.width : leftRow.implicitWidth
            transform: Scale {
                origin.x: 0
                origin.y: root.scaleOriginY(leftSection.height)
                xScale: root.fitScale
                yScale: root.fitScale
            }

            RowLayout {
                id: leftRow
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
                id: leftWrapper
                active: root.useTabWrapper
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                sourceComponent: WrapperSection {
                    edge: -1
                    sectionLayout: root.effectiveLeftLayout
                }
            }
        }

        Item {
            id: absoluteCenter
            anchors.centerIn: parent
            width: root.useTabWrapper ? centerWrapper.width : middleRow.implicitWidth
            height: parent.height
            transform: Scale {
                origin.x: absoluteCenter.width / 2
                origin.y: root.scaleOriginY(absoluteCenter.height)
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
                id: centerWrapper
                active: root.useTabWrapper
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                sourceComponent: WrapperSection {
                    edge: 0
                    sectionLayout: root.effectiveMiddleLayout
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
            width: root.useTabWrapper ? rightWrapper.width : rightRow.implicitWidth
            transform: Scale {
                origin.x: rightSection.width
                origin.y: root.scaleOriginY(rightSection.height)
                xScale: root.fitScale
                yScale: root.fitScale
            }

            RowLayout {
                id: rightRow
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
                id: rightWrapper
                active: root.useTabWrapper
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                sourceComponent: WrapperSection {
                    edge: 1
                    sectionLayout: root.effectiveRightLayout
                }
            }
        }
    }
}

import qs.modules.ii.bar.weather
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item { // Bar content region
    id: root

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    readonly property real thresholdShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width) ? 1 : 0
    property real useShortenedForm: Platform.isWindows ? fitForm : thresholdShortenedForm
    readonly property int centerSideModuleWidth: (useShortenedForm == 2) ? Appearance.sizes.barCenterSideModuleWidthHellaShortened : (useShortenedForm == 1) ? Appearance.sizes.barCenterSideModuleWidthShortened : Appearance.sizes.barCenterSideModuleWidth

    property int fitForm: 0
    property real fitScale: 1
    property real fitLastAvailableWidth: -1
    property real fitBlockedWidth: -1
    property int fitBlockedForm: -1
    property bool fitProbingDeescalate: false

    function fitNeededWidth() {
        return middleSection.implicitWidth + 2 * Math.max(leftSectionRowLayout.implicitWidth, rightSectionRowLayout.implicitWidth);
    }

    function fitEvaluate() {
        const avail = root.width;
        if (avail <= 0)
            return;

        if (Math.abs(avail - root.fitLastAvailableWidth) > 0.5) {
            root.fitLastAvailableWidth = avail;
            root.fitBlockedWidth = -1;
            root.fitBlockedForm = -1;
            root.fitProbingDeescalate = false;
            root.fitForm = 0;
            root.fitScale = 1;
            return;
        }

        const needed = fitNeededWidth();
        const margin = 20;

        if (needed > avail) {
            if (root.fitProbingDeescalate) {
                root.fitBlockedForm = root.fitForm;
                root.fitBlockedWidth = avail;
                root.fitProbingDeescalate = false;
                root.fitForm = Math.min(2, root.fitForm + 1);
                return;
            }
            if (root.fitForm < 2) {
                root.fitForm += 1;
                return;
            }
            root.fitScale = Math.max(0.01, Math.min(1, avail / needed));
            return;
        }

        root.fitProbingDeescalate = false;
        if (root.fitScale !== 1)
            root.fitScale = 1;

        const reblocked = (root.fitForm - 1 === root.fitBlockedForm) && (avail <= root.fitBlockedWidth + margin);
        if (root.fitForm > 0 && needed <= avail - margin && !reblocked) {
            root.fitForm -= 1;
            root.fitProbingDeescalate = true;
        }
    }

    onWidthChanged: if (Platform.isWindows)
        root.fitEvaluate()

    Timer {
        running: Platform.isWindows
        interval: 200
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fitEvaluate()
    }

    component VerticalBarSeparator: Rectangle {
        Layout.topMargin: Appearance.sizes.baseBarHeight / 3
        Layout.bottomMargin: Appearance.sizes.baseBarHeight / 3
        Layout.fillHeight: true
        implicitWidth: 1
        color: Appearance.colors.colOutlineVariant
    }

    // Background shadow
    Loader {
        active: Config.options.bar.showBackground && Config.options.bar.cornerStyle === 1 && Config.options.bar.floatStyleShadow
        anchors.fill: barBackground
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined // The loader's anchors act on this, and this should not have any anchor
            target: barBackground
        }
    }
    // Background
    Rectangle {
        id: barBackground
        anchors {
            fill: parent
            margins: Config.options.bar.cornerStyle === 1 ? (Appearance.sizes.hyprlandGapsOut) : 0 // idk why but +1 is needed
        }
        color: Config.options.bar.showBackground ? Appearance.colors.colLayer0 : "transparent"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
        border.color: Appearance.colors.colLayer0Border
    }

    Item {
        id: fitScaler
        anchors.fill: parent
        scale: root.fitScale
        transformOrigin: Item.Center

        Behavior on scale {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        FocusedScrollMouseArea { // Left side | scroll to change brightness
            id: barLeftSideMouseArea

            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                right: middleSection.left
            }
            implicitWidth: leftSectionRowLayout.implicitWidth
            implicitHeight: Appearance.sizes.baseBarHeight

            onScrollDown: Brightness.decreaseBrightness()
            onScrollUp: Brightness.increaseBrightness()
            onMovedAway: GlobalStates.osdBrightnessOpen = false
            onPressed: event => {
                if (event.button === Qt.LeftButton)
                    GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
            }

            // Visual content
            ScrollHint {
                reveal: barLeftSideMouseArea.hovered
                icon: Hyprsunset.gamma === 100 ? "light_mode" : "wb_twilight"
                tooltipText: Translation.tr("Scroll to change brightness")
                side: "left"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            RowLayout {
                id: leftSectionRowLayout
                anchors.fill: parent
                spacing: 0

                LeftSidebarButton { // Left sidebar button
                    id: leftSidebarButton
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: Appearance.rounding.screenRounding
                    colBackground: barLeftSideMouseArea.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
                }

                ActiveWindow {
                    Layout.leftMargin: 10 + (leftSidebarButton.visible ? 0 : Appearance.rounding.screenRounding)
                    Layout.rightMargin: Appearance.rounding.screenRounding
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.useShortenedForm === 0
                }
            }
        }

        Row { // Middle section
            id: middleSection
            anchors {
                top: parent.top
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            spacing: 4

            BarGroup {
                id: leftCenterGroup
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: root.centerSideModuleWidth

                Resources {
                    alwaysShowAllResources: root.useShortenedForm === 2
                    Layout.fillWidth: root.useShortenedForm === 2
                }

                Media {
                    visible: root.useShortenedForm < 2
                    Layout.fillWidth: true
                }
            }

            VerticalBarSeparator {
                visible: Config.options?.bar.borderless
            }

            BarGroup {
                id: middleCenterGroup
                anchors.verticalCenter: parent.verticalCenter
                padding: workspacesWidget.widgetPadding

                Workspaces {
                    id: workspacesWidget
                    Layout.fillHeight: true
                    MouseArea {
                        // Right-click to toggle overview
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton

                        onPressed: event => {
                            if (event.button === Qt.RightButton) {
                                GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                            }
                        }
                    }
                }
            }

            VerticalBarSeparator {
                visible: Config.options?.bar.borderless
            }

            MouseArea {
                id: rightCenterGroup
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: root.centerSideModuleWidth
                implicitHeight: rightCenterGroupContent.implicitHeight

                onPressed: {
                    GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
                }

                BarGroup {
                    id: rightCenterGroupContent
                    anchors.fill: parent

                    ClockWidget {
                        showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                    }

                    UtilButtons {
                        visible: (Config.options.bar.verbose && root.useShortenedForm === 0)
                        Layout.alignment: Qt.AlignVCenter
                    }

                    BatteryIndicator {
                        visible: (root.useShortenedForm < 2 && Battery.available)
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }

        FocusedScrollMouseArea { // Right side | scroll to change volume
            id: barRightSideMouseArea

            anchors {
                top: parent.top
                bottom: parent.bottom
                left: middleSection.right
                right: parent.right
            }
            implicitWidth: rightSectionRowLayout.implicitWidth
            implicitHeight: Appearance.sizes.baseBarHeight

            onScrollDown: Audio.decrementVolume()
            onScrollUp: Audio.incrementVolume()
            onMovedAway: GlobalStates.osdVolumeOpen = false
            onPressed: event => {
                if (event.button === Qt.LeftButton) {
                    GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
                }
            }

            // Visual content
            ScrollHint {
                reveal: barRightSideMouseArea.hovered
                icon: "volume_up"
                tooltipText: Translation.tr("Scroll to change volume")
                side: "right"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }

            RowLayout {
                id: rightSectionRowLayout
                anchors.fill: parent
                spacing: 5
                layoutDirection: Qt.RightToLeft

                RippleButton { // Right sidebar button
                    id: rightSidebarButton

                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    Layout.rightMargin: Appearance.rounding.screenRounding
                    Layout.fillWidth: false

                    implicitWidth: indicatorsRowLayout.implicitWidth + 10 * 2
                    implicitHeight: indicatorsRowLayout.implicitHeight + 5 * 2

                    buttonRadius: Appearance.rounding.full
                    colBackground: barRightSideMouseArea.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colRipple: Appearance.colors.colLayer1Active
                    colBackgroundToggled: Appearance.colors.colSecondaryContainer
                    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                    colRippleToggled: Appearance.colors.colSecondaryContainerActive
                    toggled: GlobalStates.sidebarRightOpen
                    property color colText: toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0

                    Behavior on colText {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }

                    onPressed: {
                        GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
                    }

                    RowLayout {
                        id: indicatorsRowLayout
                        anchors.centerIn: parent
                        property real realSpacing: 15
                        spacing: 0

                        Revealer {
                            reveal: Audio.sink?.audio?.muted ?? false
                            Layout.fillHeight: true
                            Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                            Behavior on Layout.rightMargin {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            MaterialSymbol {
                                text: "volume_off"
                                iconSize: Appearance.font.pixelSize.larger
                                color: rightSidebarButton.colText
                            }
                        }
                        Revealer {
                            reveal: Audio.source?.audio?.muted ?? false
                            Layout.fillHeight: true
                            Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                            Behavior on Layout.rightMargin {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            MaterialSymbol {
                                text: "mic_off"
                                iconSize: Appearance.font.pixelSize.larger
                                color: rightSidebarButton.colText
                            }
                        }
                        HyprlandXkbIndicator {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.rightMargin: indicatorsRowLayout.realSpacing
                            color: rightSidebarButton.colText
                        }
                        Revealer {
                            reveal: Notifications.silent || Notifications.unread > 0
                            Layout.fillHeight: true
                            Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                            implicitHeight: reveal ? notificationUnreadCount.implicitHeight : 0
                            implicitWidth: reveal ? notificationUnreadCount.implicitWidth : 0
                            Behavior on Layout.rightMargin {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            NotificationUnreadCount {
                                id: notificationUnreadCount
                            }
                        }
                        MaterialSymbol {
                            text: Network.materialSymbol
                            iconSize: Appearance.font.pixelSize.larger
                            color: rightSidebarButton.colText
                        }
                        MaterialSymbol {
                            Layout.leftMargin: indicatorsRowLayout.realSpacing
                            visible: BluetoothStatus.available
                            text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                            iconSize: Appearance.font.pixelSize.larger
                            color: rightSidebarButton.colText
                        }
                    }
                }

                SysTray {
                    visible: root.useShortenedForm === 0
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    invertSide: Config?.options.bar.bottom
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                // Weather
                Loader {
                    Layout.leftMargin: 4
                    active: Config.options.bar.weather.enable

                    sourceComponent: BarGroup {
                        WeatherBar {}
                    }
                }
            }
        }
    }
}

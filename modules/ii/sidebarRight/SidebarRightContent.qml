import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.settings
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland

import qs.modules.ii.sidebarRight.quickToggles
import qs.modules.ii.sidebarRight.quickToggles.classicStyle

import qs.modules.ii.sidebarRight.bluetoothDevices
import qs.modules.ii.sidebarRight.media
import qs.modules.ii.sidebarRight.nightLight
import qs.modules.ii.sidebarRight.volumeMixer
import qs.modules.ii.sidebarRight.vpn
import qs.modules.ii.sidebarRight.wifiNetworks

Item {
    id: root
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 10
    property string settingsQmlPath: Quickshell.shellPath("settings.qml")
    property bool showAudioOutputDialog: false
    property bool showAudioInputDialog: false
    property bool showBluetoothDialog: false
    property bool showNightLightDialog: false
    property bool showWifiDialog: false
    property bool showVpnDialog: false

    function takeBluetoothRequest() {
        if (!GlobalStates.bluetoothDialogRequested)
            return;
        GlobalStates.bluetoothDialogRequested = false;
        if (Bluetooth.defaultAdapter)
            root.showBluetoothDialog = true;
    }

    Component.onCompleted: root.takeBluetoothRequest()
    property bool editMode: false
    property string editTab: Config.options.sidebar.quickToggles.style === "android" ? "toggles" : "layout"
    readonly property var editTabs: Config.options.sidebar.quickToggles.style === "android"
        ? [
            { id: "toggles", name: Translation.tr("Toggles"), icon: "toggle_on" },
            { id: "layout", name: Translation.tr("Layout"), icon: "dashboard_customize" }
        ]
        : [{ id: "layout", name: Translation.tr("Layout"), icon: "dashboard_customize" }]

    readonly property var activePlayer: MprisController.activePlayer

    Connections {
        target: Vpn
        function onDialogRequested() {
            root.showVpnDialog = true;
        }
    }

    Connections {
        target: GlobalStates
        function onBluetoothDialogRequestedChanged() {
            root.takeBluetoothRequest();
        }
        function onSidebarRightOpenChanged() {
            if (!GlobalStates.sidebarRightOpen) {
                root.editMode = false;
                root.showWifiDialog = false;
                root.showVpnDialog = false;
                root.showBluetoothDialog = false;
                root.showAudioOutputDialog = false;
                root.showAudioInputDialog = false;
            }
        }
    }

    implicitHeight: sidebarRightBackground.implicitHeight
    implicitWidth: sidebarRightBackground.implicitWidth

    StyledRectangularShadow {
        target: sidebarRightBackground
    }
    Rectangle {
        id: sidebarRightBackground

        anchors.fill: parent
        implicitHeight: parent.height - Appearance.sizes.hyprlandGapsOut * 2
        implicitWidth: sidebarWidth - Appearance.sizes.hyprlandGapsOut * 2
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1

        ReorderableColumn {
            id: sectionColumn
            anchors.fill: parent
            anchors.margins: sidebarPadding
            itemSpacing: sidebarPadding
            order: root.sectionOrder
            editMode: root.editMode && root.editTab === "layout"
            fillKey: "notifications"
            fillMinHeight: 0
            fillHideBelow: 60
            onReordered: newOrder => Config.options.sidebar.sectionOrder = newOrder
            componentForKey: key => root.sectionComponents[key] ?? null
            isKeyActive: key => root.sectionActive(key)
        }
    }

    readonly property var sectionComponents: ({
        "banner": bannerSection,
        "sliders": slidersSection,
        "quickToggles": quickTogglesSection,
        "media": mediaSection,
        "notifications": notificationsSection,
        "bottom": bottomSection
    })

    function sectionActive(key) {
        const sidebar = Config.options.sidebar;
        switch (key) {
        case "sliders":
            return sidebar.quickSliders.enable && (sidebar.quickSliders.showMic || sidebar.quickSliders.showVolume || sidebar.quickSliders.showBrightness);
        case "media":
            return sidebar.mediaPlayer && sidebar.media.enable && root.activePlayer !== null;
        case "bottom":
            return sidebar.bottomGroup;
        default:
            return true;
        }
    }

    readonly property var defaultSectionOrder: ["banner", "sliders", "quickToggles", "media", "notifications", "bottom"]
    readonly property var sectionOrder: {
        const saved = Array.from(Config.options.sidebar.sectionOrder).filter(key => root.defaultSectionOrder.includes(key));
        const unique = saved.filter((key, i) => saved.indexOf(key) === i);
        return unique.concat(root.defaultSectionOrder.filter(key => !unique.includes(key)));
    }

    Component {
        id: bannerSection
        Loader {
            sourceComponent: Config.options.sidebar.banner ? bannerComponent : normalComponent
        }
    }

    Component {
        id: bannerComponent
        Item {
            implicitHeight: 160

            Rectangle {
                id: bannerRect
                readonly property real inset: 5
                anchors.fill: parent
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                Rectangle {
                    id: wallpaperRect
                    property bool panning: false
                    property real dragDX: 0
                    property real dragDY: 0
                    readonly property real aspect: bannerImage.implicitHeight > 0 ? bannerImage.implicitWidth / bannerImage.implicitHeight : 1
                    readonly property real coverWidth: aspect > width / height ? height * aspect : width
                    readonly property real coverHeight: aspect > width / height ? height : width / aspect
                    readonly property real overflowX: Math.max(0, coverWidth - width)
                    readonly property real overflowY: Math.max(0, coverHeight - height)
                    readonly property real focusX: overflowX > 0 ? Math.max(0, Math.min(1, Config.options.sidebar.bannerFocusX - dragDX / overflowX)) : 0.5
                    readonly property real focusY: overflowY > 0 ? Math.max(0, Math.min(1, Config.options.sidebar.bannerFocusY - dragDY / overflowY)) : 0.5

                    anchors.fill: parent
                    anchors.margins: bannerRect.inset
                    radius: Math.max(0, bannerRect.radius - bannerRect.inset)
                    color: "transparent"

                    Item {
                        anchors.fill: parent
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: wallpaperRect.width
                                height: wallpaperRect.height
                                radius: wallpaperRect.radius
                            }
                        }

                        StyledImage {
                            id: bannerImage
                            x: -wallpaperRect.overflowX * wallpaperRect.focusX
                            y: -wallpaperRect.overflowY * wallpaperRect.focusY
                            width: wallpaperRect.coverWidth
                            height: wallpaperRect.coverHeight
                            fillMode: Image.PreserveAspectCrop
                            source: Config.options.sidebar.bannerImage !== ""
                                ? Config.options.sidebar.bannerImage
                                : Config.options.background.wallpaperPath
                            cache: false
                            antialiasing: true
                            sourceSize.width: wallpaperRect.width * 2
                            sourceSize.height: wallpaperRect.height * 2
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.8)
                        border.width: 2
                        border.color: Appearance.colors.colPrimary
                        opacity: wallpaperRect.panning ? 1 : 0
                        visible: opacity > 0

                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "open_with"
                            iconSize: 28
                            color: Appearance.colors.colPrimary
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Appearance.colors.colPrimary
                        opacity: dropArea.containsDrag ? 0.25 : 0
                        visible: opacity > 0
                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }

                    DropArea {
                        id: dropArea
                        anchors.fill: parent
                        keys: ["text/uri-list"]
                        onEntered: drag => drag.accept(Qt.CopyAction)
                        onDropped: drop => {
                            if (!drop.hasUrls || drop.urls.length === 0) return;
                            const cleanPath = drop.urls[0].toString().replace(/^file:\/\//, "");
                            const ext = cleanPath.split(".").pop().toLowerCase();
                            const accepted = ["png", "jpg", "jpeg", "webp", "bmp", "gif"];
                            if (accepted.indexOf(ext) !== -1) {
                                Config.options.sidebar.bannerImage = cleanPath;
                                Config.options.sidebar.bannerFocusX = 0.5;
                                Config.options.sidebar.bannerFocusY = 0.5;
                            }
                        }
                    }

                    MouseArea {
                        property real lastX: 0
                        property real lastY: 0
                        anchors.fill: parent
                        cursorShape: wallpaperRect.panning ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onPressed: mouse => {
                            lastX = mouse.x;
                            lastY = mouse.y;
                        }
                        onPressAndHold: mouse => {
                            if (mouse.button === Qt.LeftButton) wallpaperRect.panning = true;
                        }
                        onPositionChanged: mouse => {
                            if (!wallpaperRect.panning) return;
                            wallpaperRect.dragDX += mouse.x - lastX;
                            wallpaperRect.dragDY += mouse.y - lastY;
                            lastX = mouse.x;
                            lastY = mouse.y;
                        }
                        onReleased: {
                            if (!wallpaperRect.panning) return;
                            Config.options.sidebar.bannerFocusX = wallpaperRect.focusX;
                            Config.options.sidebar.bannerFocusY = wallpaperRect.focusY;
                            wallpaperRect.dragDX = 0;
                            wallpaperRect.dragDY = 0;
                            wallpaperRect.panning = false;
                        }
                        onCanceled: {
                            wallpaperRect.dragDX = 0;
                            wallpaperRect.dragDY = 0;
                            wallpaperRect.panning = false;
                        }
                        onClicked: event => {
                            if (event.button === Qt.RightButton) {
                                Config.options.sidebar.bannerImage = "";
                                Config.options.sidebar.bannerFocusX = 0.5;
                                Config.options.sidebar.bannerFocusY = 0.5;
                            }
                        }
                        StyledToolTip {
                            text: Translation.tr("Drag an image here to set it as the banner\nRight-click to reset")
                        }
                    }
                }

                Row {
                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        leftMargin: bannerRect.inset + 8
                        bottomMargin: 8
                    }
                    spacing: 8

                    UserAvatar {
                        width: 40
                        height: 40
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        StyledText {
                            text: SystemInfo.username
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: Translation.tr("Up %1").arg(DateTime.uptime)
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnLayer1
                            opacity: 0.6
                        }
                    }
                }

                ButtonGroup {
                    anchors {
                        right: parent.right
                        bottom: parent.bottom
                        margins: 4
                    }
                    color: "transparent"
                    padding: 4

                    QuickToggleButton {
                        toggled: root.editMode
                        buttonIcon: "edit"
                        onClicked: root.editMode = !root.editMode
                        StyledToolTip {
                            text: Translation.tr("Edit sidebar")
                        }
                    }
                    QuickToggleButton {
                        toggled: false
                        buttonIcon: "restart_alt"
                        onClicked: {
                            if (!Platform.isWindows) Quickshell.execDetached(["hyprctl", "reload"]);
                            Quickshell.reload(true);
                        }
                        StyledToolTip {
                            text: Translation.tr("Reload Hyprland & Quickshell")
                        }
                    }
                    QuickToggleButton {
                        toggled: false
                        buttonIcon: "settings"
                        onClicked: {
                            GlobalStates.sidebarRightOpen = false;
                            if (Platform.isWindows)
                                SettingsApp.open();
                            else
                                Quickshell.execDetached(["qs", "-p", root.settingsQmlPath]);
                        }
                        StyledToolTip {
                            text: Translation.tr("Settings")
                        }
                    }
                    QuickToggleButton {
                        toggled: false
                        buttonIcon: "power_settings_new"
                        onClicked: {
                            GlobalStates.sessionOpen = true;
                        }
                        StyledToolTip {
                            text: Translation.tr("Session")
                        }
                    }
                }
            }
        }
    }

    Component {
        id: normalComponent
        SystemButtonRow {}
    }

    Component {
        id: slidersSection
        Loader {
            active: root.sectionActive("sliders")
            sourceComponent: QuickSliders {}
        }
    }

    Component {
        id: quickTogglesSection
        Item {
            id: quickTogglesItem
            implicitHeight: (classicImpl.item?.implicitHeight ?? 0) + (androidImpl.item?.implicitHeight ?? 0)

            LoaderedQuickPanelImplementation {
                id: classicImpl
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                styleName: "classic"
                sourceComponent: ClassicQuickPanel {}
            }

            LoaderedQuickPanelImplementation {
                id: androidImpl
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: classicImpl.bottom
                styleName: "android"
                sourceComponent: AndroidQuickPanel {
                    editMode: root.editMode && root.editTab === "toggles"
                }
            }
        }
    }

    Component {
        id: mediaSection
        Loader {
            active: root.sectionActive("media") && GlobalStates.sidebarRightOpen
            sourceComponent: SidebarMediaCard {
                player: root.activePlayer
            }
        }
    }

    Component {
        id: notificationsSection
        CenterWidgetGroup {}
    }

    Component {
        id: bottomSection
        Loader {
            active: root.sectionActive("bottom")
            sourceComponent: BottomWidgetGroup {}
        }
    }

    Toolbar {
        id: editToolbar
        z: 60
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.editMode ? 22 : -height - 30
        opacity: root.editMode ? 1 : 0

        Behavior on anchors.bottomMargin {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        ToolbarTabBar {
            id: editTabBar
            tabButtonList: root.editTabs
            currentIndex: Math.max(0, root.editTabs.findIndex(tab => tab.id === root.editTab))
            onCurrentIndexChanged: root.editTab = root.editTabs[Math.max(0, currentIndex)]?.id ?? "layout"
        }

        IconToolbarButton {
            text: "check"
            onClicked: root.editMode = false
        }
    }

    ToggleDialog {
        shownPropertyString: "showAudioOutputDialog"
        dialog: VolumeDialog {
            isSink: true
        }
    }

    ToggleDialog {
        shownPropertyString: "showAudioInputDialog"
        dialog: VolumeDialog {
            isSink: false
        }
    }

    ToggleDialog {
        shownPropertyString: "showBluetoothDialog"
        dialog: BluetoothDialog {}
        onShownChanged: {
            if (!Bluetooth.defaultAdapter) return;
            if (!shown) {
                Bluetooth.defaultAdapter.discovering = false;
            } else {
                Bluetooth.defaultAdapter.enabled = true;
                Bluetooth.defaultAdapter.discovering = true;
            }
        }
    }

    ToggleDialog {
        shownPropertyString: "showNightLightDialog"
        dialog: NightLightDialog {}
    }

    ToggleDialog {
        shownPropertyString: "showWifiDialog"
        dialog: WifiDialog {}
        onShownChanged: {
            if (!shown) return;
            Network.enableWifi();
            Network.rescanWifi();
        }
    }

    ToggleDialog {
        shownPropertyString: "showVpnDialog"
        dialog: VpnDialog {}
        onShownChanged: if (shown) Vpn.refresh()
    }

    component ToggleDialog: Loader {
        id: toggleDialogLoader
        required property string shownPropertyString
        property alias dialog: toggleDialogLoader.sourceComponent
        readonly property bool shown: root[shownPropertyString]
        anchors.fill: parent

        onShownChanged: if (shown) toggleDialogLoader.active = true;
        active: shown
        onActiveChanged: {
            if (active) {
                item.show = true;
                item.forceActiveFocus();
            }
        }
        Connections {
            target: toggleDialogLoader.item
            function onDismiss() {
                toggleDialogLoader.item.show = false
                root[toggleDialogLoader.shownPropertyString] = false;
            }
            function onVisibleChanged() {
                if (!toggleDialogLoader.item.visible && !root[toggleDialogLoader.shownPropertyString]) toggleDialogLoader.active = false;
            }
        }
    }

    component LoaderedQuickPanelImplementation: Loader {
        id: quickPanelImplLoader
        required property string styleName
        Layout.alignment: item?.Layout.alignment ?? Qt.AlignHCenter
        Layout.fillWidth: item?.Layout.fillWidth ?? false
        visible: active
        active: Config.options.sidebar.quickToggles.style === styleName
        Connections {
            target: quickPanelImplLoader.item
            function onOpenAudioOutputDialog() {
                root.showAudioOutputDialog = true;
            }
            function onOpenAudioInputDialog() {
                root.showAudioInputDialog = true;
            }
            function onOpenBluetoothDialog() {
                root.showBluetoothDialog = true;
            }
            function onOpenNightLightDialog() {
                root.showNightLightDialog = true;
            }
            function onOpenWifiDialog() {
                root.showWifiDialog = true;
            }
            function onOpenVpnDialog() {
                root.showVpnDialog = true;
            }
        }
    }

    component SystemButtonRow: Item {
        implicitHeight: Math.max(uptimeContainer.implicitHeight, systemButtonsRow.implicitHeight)

        Rectangle {
            id: uptimeContainer
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
            }
            color: Appearance.colors.colLayer1
            radius: height / 2
            implicitWidth: uptimeRow.implicitWidth + 24
            implicitHeight: uptimeRow.implicitHeight + 8

            Row {
                id: uptimeRow
                anchors.centerIn: parent
                spacing: 8
                CustomIcon {
                    id: distroIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 25
                    height: 25
                    source: SystemInfo.distroIcon
                    colorize: true
                    color: Appearance.colors.colOnLayer0
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer0
                    text: Translation.tr("Up %1").arg(DateTime.uptime)
                    textFormat: Text.PlainText
                }
            }
        }

        ButtonGroup {
            id: systemButtonsRow
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }
            color: Appearance.colors.colLayer1
            padding: 4

            QuickToggleButton {
                toggled: root.editMode
                buttonIcon: "edit"
                onClicked: root.editMode = !root.editMode
                StyledToolTip {
                    text: Translation.tr("Edit sidebar")
                }
            }
            QuickToggleButton {
                toggled: false
                buttonIcon: "restart_alt"
                onClicked: {
                    if (!Platform.isWindows) Quickshell.execDetached(["hyprctl", "reload"])
                    Quickshell.reload(true);
                }
                StyledToolTip {
                    text: Translation.tr("Reload Hyprland & Quickshell")
                }
            }
            QuickToggleButton {
                toggled: false
                buttonIcon: "settings"
                onClicked: {
                    GlobalStates.sidebarRightOpen = false;
                    if (Platform.isWindows)
                        SettingsApp.open();
                    else
                        Quickshell.execDetached(["qs", "-p", root.settingsQmlPath]);
                }
                StyledToolTip {
                    text: Translation.tr("Settings")
                }
            }
            QuickToggleButton {
                toggled: false
                buttonIcon: "power_settings_new"
                onClicked: {
                    GlobalStates.sessionOpen = true;
                }
                StyledToolTip {
                    text: Translation.tr("Session")
                }
            }
        }
    }
}

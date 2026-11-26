import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.cheatsheet
import "../cheatsheet/CheatsheetSystemFormat.js" as Fmt
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    readonly property bool open: GlobalStates.welcomeScreenOpen

    function hide() {
        GlobalStates.welcomeScreenOpen = false;
    }

    readonly property var components: Platform.isWindows ? [
        { name: "illogical-impulse (ii)", role: Translation.tr("Shell"), icon: "dashboard" },
        { name: "Quickshell for Windows", role: Translation.tr("UI framework"), icon: "widgets" },
        { name: "matugen", role: Translation.tr("Wallpaper colors"), icon: "palette" },
        { name: "VirtualDesktopAccessor", role: Translation.tr("Virtual desktops"), icon: "workspaces" }
    ] : [
        { name: "Hyprland", role: Translation.tr("Compositor"), icon: "view_quilt" },
        { name: "Quickshell", role: Translation.tr("UI framework"), icon: "widgets" },
        { name: "illogical-impulse (ii)", role: Translation.tr("Shell"), icon: "dashboard" },
        { name: "matugen", role: Translation.tr("Wallpaper colors"), icon: "palette" }
    ]

    readonly property var credits: Platform.isWindows ? [
        ["end-4", Translation.tr("illogical-impulse (ii), the shell this screen belongs to")],
        ["Quickshell for Windows", Translation.tr("A native Windows backend for Quickshell, the UI toolkit running every panel")],
        ["InioX", Translation.tr("matugen, the Material You colors taken from your wallpaper")]
    ] : [
        ["end-4", Translation.tr("illogical-impulse (ii), the shell this screen belongs to")],
        ["outfoxxed", Translation.tr("Quickshell, the UI toolkit running every panel")],
        ["InioX", Translation.tr("matugen, the Material You colors taken from your wallpaper")]
    ]

    readonly property var tips: [
        { icon: "wallpaper", text: Translation.tr("Pick a wallpaper and the whole shell follows its colors (Ctrl+Super+T).") },
        { icon: "settings", text: Translation.tr("Fonts, bar layout, transparency and more live in Settings (Super+I).") },
        { icon: "travel_explore", text: Translation.tr("Open Spotlight and search for \"Welcome\" to come back to this screen anytime.") }
    ].concat(Platform.isWindows ? [
        { icon: "keyboard", text: Translation.tr("Or just press Shift+Super+H.") }
    ] : [])

    readonly property var shortcutDescriptions: [
        "Shell: Toggle welcome screen",
        "Shell: Toggle cheatsheet",
        "Shell: Toggle left sidebar",
        "Shell: Toggle right sidebar",
        "Shell: Change wallpaper",
        "Utilities: Clipboard history >> clipboard",
        "Utilities: Screen snip",
        "App: Settings app"
    ]
    readonly property var shortcutEntries: root.shortcutDescriptions
        .map(d => HyprlandKeybinds.keybinds.find(b => b.description === d))
        .filter(b => !!b)

    function modNames(modmask) {
        const names = [];
        if (modmask & 4) names.push("Ctrl");
        if (modmask & 64) names.push("Super");
        if (modmask & 1) names.push("Shift");
        if (modmask & 8) names.push("Alt");
        return names;
    }
    readonly property var keySubstitutions: ({
        "Slash": "/",
        "Period": ".",
        "Return": "Enter"
    })
    function keyLabel(key) {
        return root.keySubstitutions[key] ?? key;
    }
    function shortcutLabel(description) {
        return description.replace(/^[^:]*:\s*/, "").replace(/\s*>>.*$/, "");
    }

    IpcHandler {
        target: "welcomeScreen"

        function toggle(): void {
            GlobalStates.welcomeScreenOpen = !GlobalStates.welcomeScreenOpen;
        }

        function open(): void {
            GlobalStates.welcomeScreenOpen = true;
        }

        function close(): void {
            GlobalStates.welcomeScreenOpen = false;
        }
    }

    Loader {
        id: welcomeLoader
        active: root.open

        sourceComponent: PanelWindow {
            id: win
            visible: root.open

            anchors {
                top: !Platform.isWindows
                bottom: !Platform.isWindows
                left: !Platform.isWindows
                right: !Platform.isWindows
            }
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: card.width + Appearance.sizes.elevationMargin * 2
            implicitHeight: card.height + Appearance.sizes.elevationMargin * 2
            WlrLayershell.namespace: "quickshell:welcomeScreen"
            WlrLayershell.keyboardFocus: Platform.isWindows ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            color: "transparent"

            mask: Region {
                item: card
            }

            function hide() {
                root.hide();
            }

            Component.onCompleted: {
                if (win.visible)
                    GlobalFocusGrab.addDismissable(win);
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(win);
            }
            onVisibleChanged: {
                if (win.visible)
                    GlobalFocusGrab.addDismissable(win);
                else
                    GlobalFocusGrab.removeDismissable(win);
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    win.hide();
                }
            }

            StyledRectangularShadow {
                target: card
                visible: !SekaiTheme.active
            }

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: Math.min((win.screen?.width ?? 1280) - 160, 760)
                height: Math.min((win.screen?.height ?? 900) - 160, 680)
                radius: Appearance.rounding.windowRounding
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                SekaiShadow {
                    radius: card.radius
                }
                SekaiFrame {
                    radius: card.radius
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        win.hide();
                    }
                }

                RippleButton {
                    id: closeButton
                    focus: win.visible
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.full
                    anchors {
                        top: parent.top
                        right: parent.right
                        topMargin: 16
                        rightMargin: 16
                    }

                    onClicked: win.hide()

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.title
                        text: "close"
                    }

                    StyledToolTip {
                        text: Translation.tr("Close")
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.rightMargin: 48
                        spacing: 14

                        UserAvatar {
                            implicitWidth: 48
                            implicitHeight: 48
                        }

                        ColumnLayout {
                            spacing: 0
                            readonly property var greeting: Greetings.pick(Config.options.background.widgets.greeting.name || SystemInfo.username || "", new Date(), Math.random().toString())
                            StyledText {
                                text: parent.greeting.title
                                font.pixelSize: Appearance.font.pixelSize.title
                                font.family: Appearance.font.family.title
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer0
                            }
                            StyledText {
                                text: parent.greeting.subtitle
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ContentPage {
                            anchors.fill: parent
                            baseWidth: 640
                            forceWidth: true

                            ContentSection {
                                icon: "monitoring"
                                title: Translation.tr("Right now")

                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    CheatsheetSystemHeaderChip {
                                        icon: "computer"
                                        text: Fmt.dash(SystemInfo.hostname)
                                    }
                                    CheatsheetSystemHeaderChip {
                                        icon: "desktop_windows"
                                        text: Fmt.dash(SystemInfo.distroName)
                                    }
                                    CheatsheetSystemHeaderChip {
                                        icon: "schedule"
                                        text: Translation.tr("Up %1").arg(DateTime.uptime)
                                    }
                                }

                                CheatsheetSystemUsageBar {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 6
                                    icon: "memory"
                                    label: Translation.tr("CPU")
                                    valueText: ResourceUsage.maxAvailableCpuString
                                    percentText: Fmt.percentString(ResourceUsage.cpuUsage)
                                    ratio: ResourceUsage.cpuUsage
                                }
                                CheatsheetSystemUsageBar {
                                    Layout.fillWidth: true
                                    icon: "memory_alt"
                                    label: Translation.tr("Memory")
                                    valueText: ResourceUsage.kbToGbString(ResourceUsage.memoryUsed) + " / " + ResourceUsage.kbToGbString(ResourceUsage.memoryTotal)
                                    percentText: Fmt.percentString(ResourceUsage.memoryUsedPercentage)
                                    ratio: ResourceUsage.memoryUsedPercentage
                                    barColor: Appearance.colors.colTertiary
                                }
                            }

                            ContentSection {
                                icon: "layers"
                                title: Translation.tr("Under the hood")

                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 10
                                    Repeater {
                                        model: root.components
                                        Rectangle {
                                            id: componentCard
                                            required property var modelData
                                            implicitWidth: 230
                                            implicitHeight: 52
                                            radius: Appearance.rounding.small
                                            color: Appearance.colors.colLayer1

                                            RowLayout {
                                                anchors {
                                                    fill: parent
                                                    leftMargin: 14
                                                    rightMargin: 14
                                                }
                                                spacing: 12
                                                MaterialSymbol {
                                                    text: componentCard.modelData.icon
                                                    iconSize: 22
                                                    color: Appearance.colors.colPrimary
                                                }
                                                ColumnLayout {
                                                    spacing: 0
                                                    StyledText {
                                                        text: componentCard.modelData.name
                                                        font.weight: Font.Medium
                                                        font.pixelSize: Appearance.font.pixelSize.small
                                                    }
                                                    StyledText {
                                                        text: componentCard.modelData.role
                                                        color: Appearance.colors.colSubtext
                                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            ContentSection {
                                icon: "keyboard"
                                title: Translation.tr("Shortcuts")

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Repeater {
                                        model: root.shortcutEntries
                                        RowLayout {
                                            id: shortcutRow
                                            required property var modelData
                                            Layout.fillWidth: true
                                            spacing: 8
                                            Row {
                                                spacing: 4
                                                Repeater {
                                                    model: root.modNames(shortcutRow.modelData.modmask)
                                                    KeyboardKey {
                                                        required property string modelData
                                                        key: modelData
                                                    }
                                                }
                                                KeyboardKey {
                                                    key: root.keyLabel(shortcutRow.modelData.key)
                                                }
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                text: root.shortcutLabel(shortcutRow.modelData.description)
                                                color: Appearance.colors.colSubtext
                                                font.pixelSize: Appearance.font.pixelSize.small
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }

                            ContentSection {
                                icon: "tips_and_updates"
                                title: Translation.tr("Tips")

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Repeater {
                                        model: root.tips
                                        RowLayout {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            spacing: 12
                                            MaterialSymbol {
                                                text: modelData.icon
                                                iconSize: 20
                                                color: Appearance.colors.colPrimary
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                text: modelData.text
                                                font.pixelSize: Appearance.font.pixelSize.small
                                                wrapMode: Text.WordWrap
                                            }
                                        }
                                    }
                                }
                            }

                            ContentSection {
                                icon: "favorite"
                                title: Translation.tr("Credits")

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Repeater {
                                        model: root.credits
                                        RowLayout {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            spacing: 12
                                            StyledText {
                                                Layout.preferredWidth: 170
                                                text: modelData[0]
                                                font.weight: Font.Medium
                                                font.pixelSize: Appearance.font.pixelSize.small
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                text: modelData[1]
                                                color: Appearance.colors.colSubtext
                                                font.pixelSize: Appearance.font.pixelSize.small
                                                wrapMode: Text.WordWrap
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

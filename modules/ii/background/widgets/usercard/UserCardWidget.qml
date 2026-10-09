import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.ii.background.widgets
import qs.modules.settings
import qs.modules.settingsPc.widgets as SettingsPcWidgets

AbstractBackgroundWidget {
    id: root
    configEntryName: "userCard"
    hoverEnabled: true

    readonly property real snapWidth1: 132
    readonly property real snapWidth2: 276
    readonly property real snapWidth3: 276
    readonly property real snapWidth4: 420

    readonly property real snapHeight1: 120
    readonly property real snapHeight2: 120
    readonly property real snapHeight3: 252

    property string sizeMode: root.configEntry.sizeMode ?? "2x2"

    property real widgetWidth: {
        switch (root.sizeMode) {
        case "1x1":
            return snapWidth1;
        case "1x2":
            return snapWidth2;
        case "2x3":
            return snapWidth4;
        default:
            return snapWidth3;
        }
    }
    property real widgetHeight: {
        switch (root.sizeMode) {
        case "1x1":
            return snapHeight1;
        case "1x2":
            return snapHeight2;
        default:
            return snapHeight3;
        }
    }

    readonly property real heightToggleFraction: 0.3
    readonly property real heightToggleDelta: (root.snapHeight3 - root.snapHeight2) * root.heightToggleFraction
    readonly property real wideThreshold: (root.snapWidth3 + root.snapWidth4) / 2

    function modeForDrag(dx, dy, startWidth) {
        const mid = (root.snapWidth1 + root.snapWidth2) / 2;
        const newWidth = startWidth + dx;

        if (newWidth < mid)
            return "1x1";

        if (root.sizeMode === "1x1") {
            return dy > root.heightToggleDelta ? "2x2" : "1x2";
        }

        if (dy > root.heightToggleDelta) {
            return newWidth > root.wideThreshold ? "2x3" : "2x2";
        }
        if (dy < -root.heightToggleDelta)
            return "1x2";

        if (root.sizeMode === "2x2" || root.sizeMode === "2x3") {
            return newWidth > root.wideThreshold ? "2x3" : "2x2";
        }
        return root.sizeMode;
    }

    property int avatarSize: 64
    property string username: SystemInfo.username

    function weatherQuip() {
        const desc = (Weather.data?.description ?? "").toLowerCase();
        if (desc === "")
            return null;
        if (desc.includes("rain"))
            return {
                text: Translation.tr("• raining, grab a coffee"),
                icon: "coffee"
            };
        if (desc.includes("clear"))
            return {
                text: Translation.tr("• good day to touch grass"),
                icon: "eco"
            };
        if (desc.includes("cloud"))
            return {
                text: Translation.tr("• a bit cloudy today"),
                icon: "cloud"
            };
        if (desc.includes("snow"))
            return {
                text: Translation.tr("• snowing"),
                icon: "ac_unit"
            };
        return {
            text: "• " + Weather.data?.description,
            icon: "thermostat"
        };
    }
    property var currentQuip: weatherQuip()

    function greetingFor(hour) {
        if (hour < 12)
            return Translation.tr("Good Morning");
        if (hour < 18)
            return Translation.tr("Good Afternoon");
        return Translation.tr("Good Evening");
    }

    readonly property string greetingText: greetingFor(DateTime.hour24)
    readonly property string todayString: Translation.tr("Today • ") + DateTime.clock.date.toLocaleDateString(Qt.locale(), "dddd d MMM")

    // Uptime split into days / hours / minutes for the 2x3 stats row
    readonly property int uptimeDays: Math.floor(DateTime.uptimeSeconds / 86400)
    readonly property int uptimeHours: Math.floor((DateTime.uptimeSeconds % 86400) / 3600)
    readonly property int uptimeMinutes: Math.floor((DateTime.uptimeSeconds % 3600) / 60)

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    Behavior on widgetWidth {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }
    Behavior on widgetHeight {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    component CardIconButton: Rectangle {
        property string icon: ""
        property bool filled: false
        implicitWidth: 40
        implicitHeight: 40
        radius: width / 2
        color: filled ? Appearance.colors.colOnPrimaryContainer : "transparent"
        border.width: filled ? 0 : 1
        border.color: Appearance.colors.colOnPrimaryContainer

        signal clicked

        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: Appearance.font.pixelSize.normal
            text: parent.icon
            color: filled ? Appearance.colors.colPrimaryContainer : Appearance.colors.colOnPrimaryContainer
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    WidgetCard {
        id: card
        implicitWidth: root.widgetWidth
        implicitHeight: root.widgetHeight
        widget: root

        Loader {
            anchors.fill: parent
            sourceComponent: {
                if (root.sizeMode === "1x1")
                    return oneByOneContent;
                if (root.sizeMode === "1x2")
                    return oneByTwoContent;
                if (root.sizeMode === "2x3")
                    return twoByThreeContent;
                return twoByTwoContent;
            }
        }

        // 1x1
        Component {
            id: oneByOneContent
            SettingsPcWidgets.UserAvatar {
                anchors.fill: parent
                radius: Appearance.rounding?.verylarge ?? 30
                iconSize: 40
            }
        }

        // 1x2
        Component {
            id: oneByTwoContent
            RowLayout {
                anchors {
                    fill: parent
                    margins: 10
                }
                spacing: 12

                SettingsPcWidgets.UserAvatar {
                    Layout.preferredWidth: parent.height
                    Layout.preferredHeight: parent.height
                    iconSize: 28
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 2

                    Item {
                        Layout.fillHeight: true
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Hi, %1!").arg(root.username)
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnPrimaryContainer
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.greetingText
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnPrimaryContainer
                        opacity: 0.8
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.todayString
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnPrimaryContainer
                        opacity: 0.6
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // 2x2
        Component {
            id: twoByTwoContent
            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 16
                }
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    SettingsPcWidgets.UserAvatar {
                        Layout.preferredWidth: root.avatarSize
                        Layout.preferredHeight: root.avatarSize
                        iconSize: 30
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        StyledText {
                            Layout.fillWidth: true
                            text: root.username
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnPrimaryContainer
                            elide: Text.ElideRight
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: Translation.tr("Up • %1").arg(DateTime.uptime)
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnPrimaryContainer
                            opacity: 0.6
                            elide: Text.ElideRight
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: root.currentQuip !== null

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignTop
                        iconSize: Appearance.font.pixelSize.normal
                        text: root.currentQuip?.icon ?? ""
                        color: Appearance.colors.colOnPrimaryContainer
                        opacity: 0.85
                    }

                    StyledText {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnPrimaryContainer
                        opacity: 0.85
                        text: root.currentQuip?.text ?? ""
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colOnPrimaryContainer

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol {
                                iconSize: Appearance.font.pixelSize.normal
                                text: "lock"
                                color: Appearance.colors.colPrimaryContainer
                            }
                            StyledText {
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colPrimaryContainer
                                text: GlobalStates.screenLocked ? Translation.tr("Locked") : Translation.tr("Lock")
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: GlobalStates.screenLocked = true
                        }
                    }

                    CardIconButton {
                        icon: "settings"
                        onClicked: SettingsApp.open()
                    }

                    CardIconButton {
                        icon: "power_settings_new"
                        onClicked: GlobalStates.sessionOpen = true
                    }
                }
            }
        }

        // 2x3
        Component {
            id: twoByThreeContent
            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 16
                }
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    SettingsPcWidgets.UserAvatar {
                        Layout.preferredWidth: root.avatarSize
                        Layout.preferredHeight: root.avatarSize
                        iconSize: 30
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        StyledText {
                            Layout.fillWidth: true
                            text: root.username
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnPrimaryContainer
                            elide: Text.ElideRight
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: root.greetingText
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnPrimaryContainer
                            opacity: 0.7
                            elide: Text.ElideRight
                        }
                    }

                    CardIconButton {
                        icon: "settings"
                        onClicked: SettingsApp.open()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 10

                    ColumnLayout {
                        spacing: 0
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.uptimeDays
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Translation.tr("days")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnPrimaryContainer
                            opacity: 0.6
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.uptimeHours
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Translation.tr("hours")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnPrimaryContainer
                            opacity: 0.6
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.uptimeMinutes
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Translation.tr("min")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnPrimaryContainer
                            opacity: 0.6
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colOnPrimaryContainer

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol {
                                iconSize: Appearance.font.pixelSize.normal
                                text: "lock"
                                color: Appearance.colors.colPrimaryContainer
                            }
                            StyledText {
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colPrimaryContainer
                                text: GlobalStates.screenLocked ? Translation.tr("Locked") : Translation.tr("Lock")
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: GlobalStates.screenLocked = true
                        }
                    }

                    CardIconButton {
                        icon: "power_settings_new"
                        onClicked: GlobalStates.sessionOpen = true
                    }
                }
            }
        }

        ResizeHandler {
            anchorItem: card
            hoverActive: root.containsMouse
            locked: Config.options.background.widgetsLocked
            currentWidth: root.widgetWidth
            resizeMode: "diagonal"
            onResizedXY: (dx, dy, startWidth) => {
                root.sizeMode = root.modeForDrag(dx, dy, startWidth);
            }
            onResizeFinished: {
                root.configEntry.sizeMode = root.sizeMode;
            }
        }
    }
}

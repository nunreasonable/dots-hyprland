import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property color contentColor: Appearance.colors.colOnSecondaryContainer
    property bool contentColorOverridden: false
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    property bool classic: false
    property bool vertical: false
    readonly property bool showCpuTemp: Config.options.bar.resources.alwaysShowCpuTemp && ResourceUsage.cpuTempAvailable
    readonly property bool showDisk: Config.options.bar.resources.alwaysShowDisk
    readonly property var optional: (root.showCpuTemp ? ["temp"] : []).concat(root.showDisk ? ["disk"] : [])
    readonly property var order: root.classic ? ["ram", "swap", "cpu"].concat(root.optional) : ["ram", "cpu"].concat(root.optional, ["swap"])
    readonly property real horizontalPadding: root.classic ? 4 : 6

    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : rowLayout.implicitWidth + root.horizontalPadding * 2
    implicitHeight: root.vertical ? columnLayout.implicitHeight : Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    property bool cpuTempRegistered: false
    property bool diskRegistered: false

    function syncConsumers(alive) {
        const wantTemp = alive && root.showCpuTemp;
        if (wantTemp !== root.cpuTempRegistered) {
            ResourceUsage.cpuTempConsumers += wantTemp ? 1 : -1;
            root.cpuTempRegistered = wantTemp;
        }
        const wantDisk = alive && root.showDisk;
        if (wantDisk !== root.diskRegistered) {
            ResourceUsage.diskConsumers += wantDisk ? 1 : -1;
            root.diskRegistered = wantDisk;
        }
    }

    onShowCpuTempChanged: root.syncConsumers(true)
    onShowDiskChanged: root.syncConsumers(true)
    Component.onCompleted: root.syncConsumers(true)
    Component.onDestruction: root.syncConsumers(false)

    function iconFor(key) {
        switch (key) {
        case "ram":
            return "memory";
        case "swap":
            return "swap_horiz";
        case "cpu":
            return "planner_review";
        case "temp":
            return "thermostat";
        default:
            return "hard_drive";
        }
    }

    function labelFor(key) {
        switch (key) {
        case "ram":
            return "RAM";
        case "swap":
            return "SWP";
        case "cpu":
            return "CPU";
        case "temp":
            return "TMP";
        default:
            return "DSK";
        }
    }

    function percentageFor(key) {
        switch (key) {
        case "ram":
            return ResourceUsage.memoryUsedPercentage;
        case "swap":
            return ResourceUsage.swapUsedPercentage;
        case "cpu":
            return ResourceUsage.cpuUsage;
        case "temp":
            return ResourceUsage.cpuTemp / 100;
        default:
            return ResourceUsage.diskUsedPercentage;
        }
    }

    function thresholdFor(key) {
        switch (key) {
        case "ram":
            return Config.options.bar.resources.memoryWarningThreshold;
        case "swap":
            return Config.options.bar.resources.swapWarningThreshold;
        case "cpu":
            return Config.options.bar.resources.cpuWarningThreshold;
        default:
            return 100;
        }
    }

    function shownFor(key) {
        switch (key) {
        case "ram":
            return Config.options.bar.resources.alwaysShowRam;
        case "swap":
            if (!root.classic)
                return Config.options.bar.resources.alwaysShowSwap;
            return (Config.options.bar.resources.alwaysShowSwap && ResourceUsage.swapUsedPercentage > 0) || (MprisController.activePlayer?.trackTitle == null) || root.alwaysShowAllResources;
        case "cpu":
            if (!root.classic)
                return Config.options.bar.resources.alwaysShowCpu;
            return Config.options.bar.resources.alwaysShowCpu || !(MprisController.activePlayer?.trackTitle?.length > 0) || root.alwaysShowAllResources;
        case "temp":
            return root.showCpuTemp;
        default:
            return root.showDisk;
        }
    }

    RowLayout {
        id: rowLayout
        visible: !root.vertical
        spacing: 0
        anchors {
            fill: root.classic ? parent : undefined
            centerIn: root.classic ? undefined : parent
            leftMargin: root.classic ? root.horizontalPadding : 0
            rightMargin: root.classic ? root.horizontalPadding : 0
        }

        Repeater {
            model: root.vertical ? [] : root.order
            delegate: Resource {
                required property string modelData
                required property int index
                contentColor: root.contentColor
                contentColorOverridden: root.contentColorOverridden
                iconName: root.iconFor(modelData)
                label: root.labelFor(modelData)
                percentage: root.percentageFor(modelData)
                warningThreshold: root.thresholdFor(modelData)
                shown: root.shownFor(modelData)
                Layout.leftMargin: (index > 0 && shown) ? 6 : 0
            }
        }
    }

    ColumnLayout {
        id: columnLayout
        visible: root.vertical
        anchors.centerIn: parent
        spacing: 7

        Repeater {
            model: root.vertical ? root.order : []
            delegate: Resource {
                required property string modelData
                Layout.alignment: Qt.AlignHCenter
                vertical: true
                contentColor: root.contentColor
                contentColorOverridden: root.contentColorOverridden
                iconName: root.iconFor(modelData)
                label: root.labelFor(modelData)
                percentage: root.percentageFor(modelData)
                warningThreshold: root.thresholdFor(modelData)
                shown: root.shownFor(modelData)
            }
        }
    }

    ResourcesPopup {
        hoverTarget: root
    }
}

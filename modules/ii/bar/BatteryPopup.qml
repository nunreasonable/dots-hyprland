import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    readonly property bool healthKnown: Battery.health > 0

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 10

        StyledPopupHeaderRow {
            icon: "battery_android_full"
            label: Translation.tr("Battery")
        }

        StyledPopupValueRow {
            visible: {
                let timeValue = Battery.isCharging ? Battery.timeToFull : Battery.timeToEmpty;
                let power = Battery.energyRate;
                return !(Battery.chargeState == 4 || timeValue <= 0 || power <= 0.01);
            }
            icon: "schedule"
            label: Battery.isCharging ? Translation.tr("Time to full:") : Translation.tr("Time to empty:")
            value: {
                function formatTime(seconds) {
                    var h = Math.floor(seconds / 3600);
                    var m = Math.floor((seconds % 3600) / 60);
                    if (h > 0)
                        return `${h}h, ${m}m`;
                    else
                        return `${m}m`;
                }
                if (Battery.isCharging)
                    return formatTime(Battery.timeToFull);
                else
                    return formatTime(Battery.timeToEmpty);
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            ResourceCard {
                label: Translation.tr("Health")
                iconText: "heart_check"
                iconShape: MaterialShape.Shape.Clover4Leaf
                value: root.healthKnown ? Battery.health / 100 : 0
                valueText: root.healthKnown ? "" : "—"
                sublabel: Battery.chargeCycles > 0 ? `${Battery.chargeCycles} ${Translation.tr("cycles")}` : Translation.tr("N/A")
                sublabelColor: Appearance.colors.colOnSurfaceVariant
                cardWidth: 160
            }

            ResourceCard {
                label: Battery.isCharging ? Translation.tr("Charge rate") : Translation.tr("Draw")
                iconText: "bolt"
                iconShape: MaterialShape.Shape.Pentagon
                value: Math.min(Battery.energyRate / 60, 1.0)
                valueText: Battery.chargeState == 4 ? "0 W" : `${Battery.energyRate.toFixed(1)} W`
                sublabel: Battery.chargeState == 4
                    ? Translation.tr("Full")
                    : Battery.isCharging ? Translation.tr("Plugged in") : Translation.tr("On battery")
                sublabelColor: Appearance.colors.colOnSurfaceVariant
                cardWidth: 160
            }
        }
    }
}

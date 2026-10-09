pragma Singleton
import qs
import qs.modules.common
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var fallbackTimezones: [
        "Pacific/Auckland", "Pacific/Fiji", "Pacific/Guam", "Pacific/Honolulu",
        "Pacific/Pago_Pago", "Pacific/Apia", "Pacific/Tahiti",
        "Australia/Sydney", "Australia/Melbourne", "Australia/Brisbane",
        "Australia/Adelaide", "Australia/Darwin", "Australia/Perth",
        "Asia/Tokyo", "Asia/Seoul", "Asia/Shanghai", "Asia/Hong_Kong",
        "Asia/Taipei", "Asia/Singapore", "Asia/Kuala_Lumpur", "Asia/Manila",
        "Asia/Makassar", "Asia/Jakarta", "Asia/Bangkok", "Asia/Ho_Chi_Minh",
        "Asia/Yangon", "Asia/Dhaka", "Asia/Kathmandu", "Asia/Kolkata",
        "Asia/Karachi", "Asia/Tashkent", "Asia/Kabul", "Asia/Dubai",
        "Asia/Muscat", "Asia/Tehran", "Asia/Baghdad", "Asia/Riyadh",
        "Asia/Kuwait", "Asia/Qatar", "Asia/Jerusalem", "Asia/Beirut",
        "Asia/Damascus", "Asia/Nicosia",
        "Europe/Moscow", "Europe/Istanbul", "Europe/Athens", "Europe/Bucharest",
        "Europe/Helsinki", "Europe/Kiev", "Europe/Minsk", "Europe/Warsaw",
        "Europe/Vienna", "Europe/Prague", "Europe/Budapest", "Europe/Berlin",
        "Europe/Paris", "Europe/Brussels", "Europe/Amsterdam", "Europe/Zurich",
        "Europe/Madrid", "Europe/Rome", "Europe/London", "Europe/Dublin",
        "Europe/Lisbon", "Atlantic/Reykjavik", "Atlantic/Azores",
        "Africa/Cairo", "Africa/Johannesburg", "Africa/Nairobi", "Africa/Addis_Ababa",
        "Africa/Khartoum", "Africa/Lagos", "Africa/Kinshasa", "Africa/Algiers",
        "Africa/Casablanca", "Africa/Tunis", "Africa/Accra", "Africa/Dakar",
        "America/Sao_Paulo", "America/Rio_Branco", "America/Buenos_Aires",
        "America/Cordoba", "America/Santiago", "America/Asuncion", "America/Montevideo",
        "America/La_Paz", "America/Cuiaba", "America/Lima", "America/Bogota",
        "America/Guayaquil", "America/Caracas",
        "America/Panama", "America/Costa_Rica", "America/El_Salvador",
        "America/Guatemala", "America/Managua", "America/Tegucigalpa",
        "America/Havana", "America/Santo_Domingo", "America/Puerto_Rico",
        "America/Jamaica",
        "America/Mexico_City", "America/Monterrey", "America/Tijuana",
        "America/New_York", "America/Detroit", "America/Chicago",
        "America/Denver", "America/Phoenix", "America/Los_Angeles",
        "America/Anchorage", "America/Vancouver", "America/Edmonton",
        "America/Winnipeg", "America/Toronto", "America/Halifax", "America/St_Johns"
    ]

    readonly property var timezoneList: {
        if (typeof Intl !== "undefined" && typeof Intl.supportedValuesOf === "function") {
            try {
                const zones = Intl.supportedValuesOf("timeZone");
                if (zones && zones.length > 0)
                    return zones;
            } catch (e) {}
        }
        return root.fallbackTimezones;
    }

    function labelFor(tz) {
        const parts = tz.split("/");
        const city = (parts[parts.length - 1] ?? tz).replace(/_/g, " ");
        const region = parts[0] ?? "";
        return region ? `${city} (${region})` : city;
    }

    readonly property var comboModel: root.timezoneList.map(tz => ({
                label: root.labelFor(tz),
                tz: tz,
                icon: ""
            }))

    property list<string> timezones: Config.options?.background?.widgets?.worldClock?.timezones ?? ["Australia/Sydney", "Asia/Tokyo", "Europe/London", "America/New_York"]

    function setTimezone(index, tz) {
        let updated = root.timezones.slice();
        updated[index] = tz;
        root.timezones = updated;
        Config.options.background.widgets.worldClock.timezones = updated;
    }

    readonly property bool active: Config.options?.background?.widgets?.worldClock?.enable ?? false

    readonly property string ampmToken: {
        const fmt = Config.options?.time.format ?? "HH:mm";
        if (fmt.includes("AP"))
            return "AP";
        if (fmt.includes("ap"))
            return "ap";
        return "";
    }
    readonly property bool use24h: root.ampmToken === ""

    property var now: new Date()
    Timer {
        interval: 1000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    readonly property var zoneAliases: ({
            "America/Miami": "America/New_York",
            "America/Houston": "America/Chicago"
        })

    function effectiveZone(tz) {
        return root.zoneAliases[tz] ?? tz;
    }

    function offsetMinutesFor(tz) {
        try {
            const eff = root.effectiveZone(tz);
            const utc = new Date(root.now.toLocaleString("en-US", {
                timeZone: "UTC"
            }));
            const zoned = new Date(root.now.toLocaleString("en-US", {
                timeZone: eff
            }));
            const minutes = Math.round((zoned.getTime() - utc.getTime()) / 60000);
            return isNaN(minutes) ? null : minutes;
        } catch (e) {
            return null;
        }
    }

    function pad(n) {
        return n < 10 ? "0" + n : "" + n;
    }

    function cityDate(index) {
        const offsetMin = root.offsetMinutesFor(root.timezones[index]);
        if (offsetMin === null || offsetMin === undefined)
            return null;
        return new Date(root.now.getTime() + offsetMin * 60000);
    }

    function timeStringFor(index) {
        const cd = root.cityDate(index);
        if (!cd)
            return "--:--";
        let h = cd.getUTCHours();
        let m = cd.getUTCMinutes();
        if (root.use24h) {
            return pad(h) + ":" + pad(m);
        }
        let h12 = h % 12;
        if (h12 === 0)
            h12 = 12;
        const base = pad(h12) + ":" + pad(m);
        if (root.ampmToken === "AP")
            return base + " " + (h >= 12 ? "PM" : "AM");
        return base + " " + (h >= 12 ? "pm" : "am");
    }

    function offsetLabelFor(index) {
        const offsetMin = root.offsetMinutesFor(root.timezones[index]);
        if (offsetMin === null || offsetMin === undefined)
            return "UTC?";
        const sign = offsetMin >= 0 ? "+" : "-";
        const abs = Math.abs(offsetMin);
        const h = Math.floor(abs / 60);
        const m = abs % 60;
        return "UTC" + sign + h + (m > 0 ? ":" + pad(m) : "");
    }

    function isDaytimeFor(index) {
        const cd = root.cityDate(index);
        if (!cd)
            return true;
        const h = cd.getUTCHours();
        return h >= 6 && h < 18;
    }

    readonly property var entries: root.timezones.map((tz, i) => ({
                tz: tz,
                name: root.labelFor(tz).split(" (")[0],
                time: root.timeStringFor(i),
                offset: root.offsetLabelFor(i),
                isDay: root.isDaytimeFor(i)
            }))
}

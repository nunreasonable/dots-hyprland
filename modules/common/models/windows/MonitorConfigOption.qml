pragma ComponentBehavior: Bound
import QtQml
import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import "../"

NestableObject {
    id: root

    readonly property QtObject backend: WindowsNative.displays
    readonly property bool available: root.backend !== null
    readonly property bool busy: root.backend?.busy ?? false
    readonly property string lastError: root.backend?.lastError ?? ""
    readonly property int activeCount: root.monitors.filter(m => !m.disabled).length
    property var monitors: []

    signal failed(string message)

    function rebuild() {
        const list = root.backend?.displays ?? [];
        let right = 0;
        let top = 0;
        let first = true;
        for (const display of list) {
            if (!display.active)
                continue;
            right = first ? display.x + display.width : Math.max(right, display.x + display.width);
            top = first ? display.y : Math.min(top, display.y);
            first = false;
        }

        let nextX = right + 320;
        root.monitors = list.map(display => {
            const monitor = Object.assign({}, display, {
                name: display.id,
                friendlyName: display.name,
                label: String(display.number),
                disabled: !display.active
            });
            if (!display.active) {
                monitor.width = display.preferredWidth > 0 ? display.preferredWidth : 1920;
                monitor.height = display.preferredHeight > 0 ? display.preferredHeight : 1080;
                monitor.x = nextX;
                monitor.y = top;
                nextX += monitor.width + 320;
            }
            return monitor;
        });
    }

    function logicalWidth(monitor) {
        return monitor?.width ?? 0;
    }

    function logicalHeight(monitor) {
        return monitor?.height ?? 0;
    }

    function previewLayout(index, x, y) {
        const monitor = root.monitors[index];
        if (!monitor || !root.backend)
            return {};
        return root.backend.previewPosition(monitor.id, x, y);
    }

    function commitPosition(index, x, y) {
        const monitor = root.monitors[index];
        if (!monitor || !root.backend)
            return false;
        return root.backend.setPosition(monitor.id, x, y);
    }

    function connectorLabel(code) {
        switch (code) {
        case "hdmi": return "HDMI";
        case "displayport": return "DisplayPort";
        case "usbc": return "USB-C";
        case "dvi": return "DVI";
        case "vga": return "VGA";
        case "internal": return Translation.tr("Built-in");
        case "virtual": return Translation.tr("Virtual");
        case "indirect": return Translation.tr("Virtual");
        case "miracast": return Translation.tr("Wireless");
        default: return (code ?? "").toUpperCase();
        }
    }

    function title(monitor) {
        if (!monitor)
            return "";
        return [Translation.tr("Display %1").arg(monitor.number), monitor.friendlyName, root.connectorLabel(monitor.connector)]
            .filter(part => part && part.length > 0)
            .join(" · ");
    }

    function resolutionValue(width, height) {
        return `${width}x${height}`;
    }

    function resolutionOptions(monitor) {
        if (!monitor)
            return [];
        const options = (monitor.modes ?? []).map(mode => ({
            displayName: `${mode.width} × ${mode.height}` + ((mode.width === monitor.preferredWidth && mode.height === monitor.preferredHeight) ? ` (${Translation.tr("Recommended")})` : ""),
            value: root.resolutionValue(mode.width, mode.height)
        }));
        const current = root.resolutionValue(monitor.resolutionWidth, monitor.resolutionHeight);
        if (!options.some(option => option.value === current))
            options.unshift({ displayName: `${monitor.resolutionWidth} × ${monitor.resolutionHeight}`, value: current });
        return options;
    }

    function ratesFor(monitor, width, height) {
        const mode = (monitor?.modes ?? []).find(m => m.width === width && m.height === height);
        return mode?.rates ?? [];
    }

    function refreshRateOptions(monitor) {
        if (!monitor)
            return [];
        const rates = root.ratesFor(monitor, monitor.resolutionWidth, monitor.resolutionHeight).filter(rate => rate > 1);
        if (monitor.refreshRate > 1 && !rates.includes(monitor.refreshRate))
            rates.unshift(monitor.refreshRate);
        if (monitor.refreshRate <= 1)
            return [{ displayName: Translation.tr("Default"), value: monitor.refreshRate }].concat(rates.map(rate => ({ displayName: `${rate} Hz`, value: rate })));
        return rates.map(rate => ({
            displayName: (rate === monitor.refreshRate && Math.abs(monitor.refreshRateExact - rate) >= 0.01) ? `${monitor.refreshRateExact.toFixed(2)} Hz` : `${rate} Hz`,
            value: rate
        }));
    }

    function scaleOptions(monitor) {
        return (monitor?.scales ?? []).map(scale => ({
            displayName: `${scale}%` + (scale === monitor.scaleRecommended ? ` (${Translation.tr("Recommended")})` : ""),
            value: scale
        }));
    }

    function setResolution(monitor, value) {
        const parts = `${value}`.split("x").map(part => parseInt(part));
        if (!monitor || !root.backend || parts.length !== 2 || isNaN(parts[0]) || isNaN(parts[1]))
            return false;
        const rates = root.ratesFor(monitor, parts[0], parts[1]);
        const rate = rates.includes(monitor.refreshRate) ? monitor.refreshRate : (rates[0] ?? 0);
        return root.backend.setMode(monitor.id, parts[0], parts[1], rate);
    }

    function setRefreshRate(monitor, rate) {
        if (!monitor || !root.backend)
            return false;
        return root.backend.setMode(monitor.id, monitor.resolutionWidth, monitor.resolutionHeight, rate);
    }

    function setRotation(monitor, rotation) {
        return monitor && root.backend ? root.backend.setRotation(monitor.id, rotation) : false;
    }

    function setEnabled(monitor, enabled) {
        return monitor && root.backend ? root.backend.setEnabled(monitor.id, enabled) : false;
    }

    function setPrimary(monitor) {
        return monitor && root.backend ? root.backend.setPrimary(monitor.id) : false;
    }

    function setScale(monitor, scale) {
        return monitor && root.backend ? root.backend.setScale(monitor.id, scale) : false;
    }

    function setHdr(monitor, enabled) {
        return monitor && root.backend ? root.backend.setHdrEnabled(monitor.id, enabled) : false;
    }

    function setSdrBrightness(monitor, nits) {
        return monitor && root.backend ? root.backend.setSdrBrightness(monitor.id, Math.round(nits)) : false;
    }

    Connections {
        target: root.backend

        function onDisplaysChanged() {
            root.rebuild();
        }

        function onChangeFailed(message) {
            root.failed(message);
        }
    }

    function attach() {
        if (!root.backend)
            return;
        DisplayConfirmation.load();
        root.backend.refresh();
        root.rebuild();
    }

    onBackendChanged: root.attach()
    Component.onCompleted: root.attach()
}

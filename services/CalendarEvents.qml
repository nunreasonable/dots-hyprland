pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property bool available: Platform.isWindows && WindowsNative.ready && WindowsNative.calendarEvents !== null
    readonly property QtObject backend: root.available ? WindowsNative.calendarEvents : null

    readonly property bool enabled: Config.options.calendar.events.enable
    readonly property int refreshMinutes: Config.options.calendar.events.refreshMinutes
    readonly property var configSources: Config.options.calendar.events.sources
    readonly property var secretUrls: KeyringStorage.keyringData?.calendarEvents?.sources ?? {}

    property bool opened: false

    readonly property bool loading: root.backend ? root.backend.loading : false
    readonly property int revision: root.backend ? root.backend.revision : 0
    readonly property var status: root.backend ? root.backend.status : ({})

    readonly property var colorPalette: [
        Appearance.m3colors.term1,
        Appearance.m3colors.term2,
        Appearance.m3colors.term3,
        Appearance.m3colors.term4,
        Appearance.m3colors.term5,
        Appearance.m3colors.term6,
    ]

    function sourceConfig(id) {
        return root.configSources.find(s => s.id === id) ?? null;
    }

    function statusFor(id) {
        return root.status?.[id] ?? null;
    }

    function colorFor(id) {
        const cfg = root.sourceConfig(id);
        if (cfg && cfg.color && cfg.color.length > 0) return cfg.color;
        const idx = Math.max(0, root.configSources.findIndex(s => s.id === id));
        return root.colorPalette[idx % root.colorPalette.length];
    }

    function nameFor(id) {
        const cfg = root.sourceConfig(id);
        return root.statusFor(id)?.name || cfg?.name || id;
    }

    function markOpened() {
        if (root.opened) return;
        root.opened = true;
        if (!root.available) return;
        if (!KeyringStorage.loaded) KeyringStorage.fetchKeyringData();
        root.syncBackend();
    }

    function syncBackend() {
        if (!root.backend || !root.opened) return;
        root.backend.cacheDir = Directories.calendarEventsCache;
        root.backend.refreshMinutes = root.refreshMinutes;
        const merged = [];
        for (const cfg of root.configSources) {
            const url = root.secretUrls[cfg.id] ?? "";
            if (url.length === 0) continue;
            merged.push({ id: cfg.id, url: url, enabled: cfg.enabled !== false });
        }
        root.backend.sources = merged;
        root.backend.active = root.enabled && merged.some(s => s.enabled);
    }

    function refresh() {
        root.backend?.refresh();
    }

    function eventsForDay(date) {
        if (!root.backend) return [];
        const from = new Date(date.getFullYear(), date.getMonth(), date.getDate());
        const to = new Date(from.getFullYear(), from.getMonth(), from.getDate() + 1);
        return root.backend.eventsBetween(from, to);
    }

    function upcoming(days, max) {
        if (!root.backend) return [];
        const from = new Date();
        const to = new Date(from.getFullYear(), from.getMonth(), from.getDate() + Math.max(1, days ?? 14));
        const events = root.backend.eventsBetween(from, to);
        return max ? events.slice(0, max) : events;
    }

    function dayMarkers(year, month1to12) {
        if (!root.backend) return [];
        return root.backend.daysWithEvents(year, month1to12);
    }

    function generateId() {
        return "cal_" + Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
    }

    function addSource(name, url) {
        KeyringStorage.fetchKeyringData();
        const id = root.generateId();
        const list = root.configSources.slice();
        list.push({ id: id, name: (name && name.length > 0) ? name : id, color: "", enabled: true });
        Config.options.calendar.events.sources = list;
        KeyringStorage.setNestedField(["calendarEvents", "sources", id], url);
        root.syncBackend();
        return id;
    }

    function removeSource(id) {
        KeyringStorage.fetchKeyringData();
        Config.options.calendar.events.sources = root.configSources.filter(s => s.id !== id);
        KeyringStorage.setNestedField(["calendarEvents", "sources", id], "");
        root.syncBackend();
    }

    function setSourceEnabled(id, sourceEnabled) {
        Config.options.calendar.events.sources = root.configSources.map(
            s => s.id === id ? Object.assign({}, s, { enabled: sourceEnabled }) : s);
        root.syncBackend();
    }

    function renameSource(id, name) {
        Config.options.calendar.events.sources = root.configSources.map(
            s => s.id === id ? Object.assign({}, s, { name: name }) : s);
    }

    function setSourceColor(id, color) {
        Config.options.calendar.events.sources = root.configSources.map(
            s => s.id === id ? Object.assign({}, s, { color: color }) : s);
    }

    onEnabledChanged: root.syncBackend()
    onConfigSourcesChanged: {
        if (root.available && root.opened) KeyringStorage.fetchKeyringData();
        root.syncBackend();
    }
    onRefreshMinutesChanged: {
        if (root.backend && root.opened) root.backend.refreshMinutes = root.refreshMinutes;
    }

    Connections {
        target: KeyringStorage
        function onDataChanged() { root.syncBackend() }
        function onLoadedChanged() { root.syncBackend() }
    }
}

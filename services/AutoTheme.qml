pragma Singleton

import qs.modules.common
import qs.services
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string mode: Config.options?.appearance?.autoTheme?.mode ?? "off"
    readonly property bool followingWindows: Platform.isWindows && root.mode === "followWindows"
    readonly property bool scheduling: root.mode === "schedule"

    function load() {
        root._syncToMode();
    }

    function _syncToMode() {
        scheduleTimer.stop();
        if (root.followingWindows) {
            root._followWindowsNow();
        } else if (root.scheduling) {
            root._evaluateSchedule();
        }
    }

    onModeChanged: root._syncToMode()

    Connections {
        target: Platform.isWindows ? WindowsNative.wallpaper : null
        function onSystemDarkModeChanged() {
            if (root.followingWindows) root._followWindowsNow();
        }
    }

    Connections {
        target: Platform.isWindows ? WindowsNative : null
        function onReadyChanged() { root._syncToMode(); }
    }

    function _followWindowsNow() {
        const wn = WindowsNative.wallpaper;
        if (!wn) return;
        if (wn.systemDarkMode === Appearance.m3colors.darkmode) return;
        Wallpapers.applyAutomaticMode(wn.systemDarkMode, false);
    }

    function _parseMinutes(value, fallbackMinutes) {
        const parts = (value ?? "").split(":");
        const hour = Number(parts[0]);
        const minute = Number(parts[1]);
        if (Number.isInteger(hour) && Number.isInteger(minute)
            && hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
            return hour * 60 + minute;
        }
        return fallbackMinutes;
    }

    readonly property int lightMinutes: root._parseMinutes(Config.options?.appearance?.autoTheme?.scheduleLightTime, 7 * 60)
    readonly property int darkMinutes: root._parseMinutes(Config.options?.appearance?.autoTheme?.scheduleDarkTime, 19 * 60)
    onLightMinutesChanged: root._syncToMode()
    onDarkMinutesChanged: root._syncToMode()

    function _shouldBeDarkAt(minutesSinceMidnight) {
        if (root.darkMinutes === root.lightMinutes) return false;
        if (root.darkMinutes < root.lightMinutes) {
            return minutesSinceMidnight >= root.darkMinutes && minutesSinceMidnight < root.lightMinutes;
        }
        return minutesSinceMidnight >= root.darkMinutes || minutesSinceMidnight < root.lightMinutes;
    }

    function _nextBoundaryDate(from) {
        const dayStart = new Date(from.getFullYear(), from.getMonth(), from.getDate());
        let best = null;
        for (let dayOffset = 0; dayOffset <= 1; dayOffset++) {
            for (const minutes of [root.lightMinutes, root.darkMinutes]) {
                const candidate = new Date(dayStart.getTime());
                candidate.setDate(candidate.getDate() + dayOffset);
                candidate.setHours(Math.floor(minutes / 60), minutes % 60, 0, 0);
                if (candidate.getTime() > from.getTime() && (!best || candidate.getTime() < best.getTime())) {
                    best = candidate;
                }
            }
        }
        return best;
    }

    function _armScheduleTimer() {
        scheduleTimer.stop();
        if (!root.scheduling) return;
        const now = new Date();
        const next = root._nextBoundaryDate(now);
        if (!next) return;
        scheduleTimer.interval = Math.max(1000, next.getTime() - now.getTime());
        scheduleTimer.start();
    }

    function _evaluateSchedule() {
        if (!root.scheduling) return;
        const now = new Date();
        const dark = root._shouldBeDarkAt(now.getHours() * 60 + now.getMinutes());
        if (dark !== Appearance.m3colors.darkmode) {
            Wallpapers.applyAutomaticMode(dark, true);
        }
        root._armScheduleTimer();
    }

    Timer {
        id: scheduleTimer
        repeat: false
        running: false
        onTriggered: root._evaluateSchedule()
    }
}

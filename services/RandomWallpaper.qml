pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    readonly property bool running: proc.running
    property string lastError: ""
    property bool fellBack: false
    readonly property var notifyArgs: ["-a", "ii-windows", "-i", "illogical-impulse"]

    function describeError(raw) {
        const line = String(raw ?? "").split(/\r?\n/).find(l => l.startsWith("IIW-ERROR:")) ?? "";
        if (line.startsWith("IIW-ERROR:challenge:")) {
            const site = line.endsWith(":osu") ? "osu!" : "Konachan";
            return Translation.tr("%1 is showing a browser check to your network right now, so ii can't get a wallpaper from it. Try again later.").arg(site);
        }
        const detail = line.length > 0 ? line.slice("IIW-ERROR:".length) : String(raw ?? "").split(/\r?\n/)[0];
        return Translation.tr("Couldn't get a random wallpaper: %1").arg(detail.slice(0, 200));
    }

    function command(source) {
        if (!Platform.isWindows)
            return ["bash", "-c", FileUtils.trimFileProtocol(`${Directories.scriptPath}/colors/random/random_${source}_wall.sh`)];
        const command = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
            FileUtils.trimFileProtocol(`${Directories.scriptPath}/colors/random/random_wall.ps1`),
            "-Source", source];
        const userAgent = Config.options.networking.userAgent ?? "";
        if (userAgent.length > 0) command.push("-UserAgent", userAgent);
        const current = Config.options.background.wallpaperPath ?? "";
        if (current.length > 0) command.push("-Current", current);
        if (source !== "konachan") return command;
        if (SpicyStuff.konachan) command.push("-Spicy");
        if (Config.options.background.konachanOnlyYuri) command.push("-OnlyYuri");
        const extra = SpicyStuff.extraTags();
        if (extra.length > 0) command.push(`-ExtraTags:${extra.join(" ")}`);
        return command;
    }

    function fetch(source) {
        if (proc.running) return;
        proc.output = "";
        root.lastError = "";
        root.fellBack = false;
        proc.command = root.command(source);
        proc.running = true;
    }

    Process {
        id: proc
        property string output: ""
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (line === "IIW-NOTE:konachan-fallback") root.fellBack = true;
                else if (line.length > 0) proc.output = line;
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) root.lastError = text.trim();
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                const message = Platform.isWindows ? root.describeError(root.lastError) : root.lastError.split(/\r?\n/)[0];
                console.warn("[RandomWallpaper] Fetch failed:", message);
                if (Platform.isWindows) Notifications.sendDesktop(Translation.tr("Random wallpaper"), message, root.notifyArgs);
                return;
            }
            if (Platform.isWindows && proc.output) Wallpapers.apply(proc.output);
            if (root.fellBack)
                Notifications.sendDesktop(Translation.tr("Random wallpaper"), Translation.tr("konachan.com is showing a browser check right now, so this wallpaper came from konachan.net, which only has safe images."), root.notifyArgs);
        }
    }
}

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
        if (extra.length > 0) command.push("-ExtraTags", extra.join(" "));
        return command;
    }

    function fetch(source) {
        if (proc.running) return;
        proc.output = "";
        root.lastError = "";
        proc.command = root.command(source);
        proc.running = true;
    }

    Process {
        id: proc
        property string output: ""
        stdout: SplitParser {
            onRead: data => {
                if (data.trim().length > 0) proc.output = data.trim();
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) root.lastError = text.trim();
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("[RandomWallpaper] Fetch failed:", root.lastError);
                return;
            }
            if (Platform.isWindows && proc.output) Wallpapers.apply(proc.output);
        }
    }
}

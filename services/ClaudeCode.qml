pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false
    property var sessions: []
    property bool loaded: false
    property bool cliFound: true
    property double now: Date.now()
    readonly property bool loading: sessionsProc.running
    readonly property string homeDir: (Platform.isWindows ? Quickshell.env("USERPROFILE") : Quickshell.env("HOME")) ?? ""

    readonly property var sessionsById: {
        const map = {};
        for (const session of root.sessions)
            map[session.id] = session;
        return map;
    }

    readonly property var folders: {
        const seen = {};
        const list = [];
        for (const path of [...root.sessions.map(session => session.cwd), root.homeDir]) {
            if (!path)
                continue;
            const key = root.folderKey(path);
            if (seen[key])
                continue;
            seen[key] = true;
            list.push(path);
        }
        return list;
    }

    Timer {
        interval: 15000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    function refresh() {
        root.now = Date.now();
        root.checkCli();
        if (!sessionsProc.running)
            sessionsProc.running = true;
    }

    Process {
        id: sessionsProc
        command: Platform.isWindows ? ["powershell", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", FileUtils.trimFileProtocol(Quickshell.shellPath("scripts/ai/claude-sessions.ps1"))] : ["python3", Quickshell.shellPath("scripts/ai/claude-sessions.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.sessions = JSON.parse(text.trim()).sessions ?? [];
                } catch (e) {}
                root.now = Date.now();
            }
        }
        onRunningChanged: {
            if (!sessionsProc.running)
                root.loaded = true;
        }
    }

    Process {
        id: cliProc
        command: ["bash", "-c", "command -v claude >/dev/null || [ -x \"$HOME/.local/bin/claude\" ]"]
        onExited: exitCode => root.cliFound = exitCode === 0
    }

    function checkCli() {
        if (Platform.isWindows)
            root.cliFound = root.claudeExecutable() !== "";
        else if (!cliProc.running)
            cliProc.running = true;
    }

    function claudeExecutable() {
        const fs = WindowsNative.fsUtils;
        const found = fs?.findExecutable("claude") ?? "";
        if (found !== "")
            return found.replace(/\//g, "\\");
        const local = `${root.homeDir}\\.local\\bin\\claude.exe`;
        return fs?.classify(local) === "file" ? local : "";
    }

    function windowsTerminal() {
        const fs = WindowsNative.fsUtils;
        const found = fs?.findExecutable("wt.exe") ?? "";
        if (found !== "")
            return found.replace(/\//g, "\\");
        const alias = `${(Quickshell.env("LOCALAPPDATA") ?? "")}\\Microsoft\\WindowsApps\\wt.exe`;
        return fs?.classify(alias) === "file" ? alias : "";
    }

    function launch(folder, args) {
        let dir = folder || root.homeDir;
        if (!Platform.isWindows) {
            Quickshell.execDetached(["bash", "-c", `cd -- "$1" 2>/dev/null; shift; c=$(command -v claude || printf %s "$HOME/.local/bin/claude"); ${Config.options.apps.terminal} -e "$c" "$@"`, "claude", dir, ...args]);
            return;
        }
        if (!(WindowsNative.fsUtils?.isAccessibleDir(dir) ?? false))
            dir = root.homeDir;
        const exe = root.claudeExecutable() || "claude";
        const wt = root.windowsTerminal();
        if (wt !== "") {
            Quickshell.execDetached([wt, "-d", dir.replace(/;/g, "\\;"), exe.replace(/;/g, "\\;"), ...args]);
            return;
        }
        Quickshell.execDetached({
            "command": ["powershell.exe", "-NoProfile", "-NonInteractive", "-Command", `Start-Process powershell.exe -ArgumentList '-NoExit','-Command','Set-Location -LiteralPath $env:IIW_CLAUDE_DIR; & $env:IIW_CLAUDE_EXE ${args.join(" ")}'`],
            "environment": {
                "IIW_CLAUDE_DIR": dir,
                "IIW_CLAUDE_EXE": exe
            }
        });
    }

    function resume(session) {
        if (!session || !/^[A-Za-z0-9_-]+$/.test(session.id))
            return;
        root.launch(session.cwd, ["--resume", session.id]);
    }

    function start(folder) {
        root.launch(folder, []);
    }

    function openFolder(folder) {
        Qt.openUrlExternally(FileUtils.folderUrl(folder || root.homeDir));
    }

    function folderKey(path) {
        const key = path.replace(/\\/g, "/").replace(/\/+$/, "");
        return Platform.isWindows ? key.toLowerCase() : key;
    }

    function folderName(path) {
        return (path ?? "").replace(/[\\/]+$/, "").split(/[\\/]/).pop() || path || "";
    }

    function modelName(id) {
        const match = /^claude-([a-z]+)-(\d+)(?:-(\d+))?/.exec(id ?? "");
        if (!match)
            return id || "—";
        const family = match[1].charAt(0).toUpperCase() + match[1].slice(1);
        const version = match[3] && match[3].length <= 2 ? `${match[2]}.${match[3]}` : match[2];
        return `${family} ${version}`;
    }

    function effortName(effort) {
        switch (effort) {
        case "low":
            return Translation.tr("Low effort");
        case "medium":
            return Translation.tr("Medium effort");
        case "high":
            return Translation.tr("High effort");
        case "xhigh":
            return Translation.tr("Extra high effort");
        case "max":
            return Translation.tr("Max effort");
        }
        return effort ?? "";
    }

    function contextWindow(session) {
        return (session?.contextTokens ?? 0) > 200000 || (session?.model ?? "").includes("[1m]") ? 1000000 : 200000;
    }

    function tokensText(value) {
        if (value >= 1000000) {
            const millions = value / 1000000;
            return `${Number.isInteger(millions) ? millions : millions.toFixed(1)}M`;
        }
        if (value >= 1000)
            return `${Math.round(value / 1000)}k`;
        return `${value}`;
    }

    function costText(value) {
        return `$${Number(value).toLocaleString(Qt.locale(), "f", 2)}`;
    }

    function relativeTime(seconds) {
        const diff = Math.max(0, Math.floor(root.now / 1000 - seconds));
        if (diff < 60)
            return Translation.tr("just now");
        if (diff < 3600)
            return Translation.tr("%1 min ago").arg(Math.floor(diff / 60));
        if (diff < 86400)
            return Translation.tr("%1 h ago").arg(Math.floor(diff / 3600));
        if (diff < 172800)
            return Translation.tr("yesterday");
        if (diff < 604800)
            return Translation.tr("%1 days ago").arg(Math.floor(diff / 86400));
        return Qt.locale().toString(new Date(seconds * 1000), "d MMM yyyy");
    }
}

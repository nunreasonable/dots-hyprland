pragma Singleton
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int consumers: 0
    property var sessions: []
    property int tokens: 0
    property int resetsAt: 0
    readonly property int tokenLimit: Config.options.bar.aiUsage.tokenLimit
    readonly property real percentage: root.tokenLimit > 0 ? Math.min(root.tokens / root.tokenLimit, 1) : 0
    readonly property int activeSessions: root.sessions.length

    function refresh() {
        if (!usageProc.running)
            usageProc.running = true;
    }

    Timer {
        interval: Math.max(10, Config.options.bar.aiUsage.updateInterval) * 1000
        repeat: true
        running: Config.ready && root.consumers > 0
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: usageProc
        command: Platform.isWindows ? ["powershell", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", FileUtils.trimFileProtocol(Quickshell.shellPath("scripts/ai/claude-usage.ps1"))] : ["python3", Quickshell.shellPath("scripts/ai/claude-usage.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text.trim());
                    root.sessions = data.sessions ?? [];
                    root.tokens = data.tokens ?? 0;
                    root.resetsAt = data.resetsAt ?? 0;
                } catch (e) {}
            }
        }
    }
}

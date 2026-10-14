pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    property bool active: false
    readonly property bool enabled: Config.options.cheatsheet.aiUsage.enable
    readonly property int refreshSeconds: Math.max(30, Config.options.cheatsheet.aiUsage.refreshSeconds)
    readonly property int localScanSeconds: 600

    readonly property string homeDir: (Platform.isWindows ? Quickshell.env("USERPROFILE") : Quickshell.env("HOME")) ?? ""
    readonly property string claudeDir: Quickshell.env("CLAUDE_CONFIG_DIR") || `${root.homeDir}/.claude`
    readonly property string codexDir: Quickshell.env("CODEX_HOME") || `${root.homeDir}/.codex`
    readonly property string localScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/ai/claude-local-usage.${Platform.isWindows ? "ps1" : "py"}`)

    property var claude: ({ "state": "idle" })
    property var codex: ({ "state": "idle" })
    property var claudeLocal: null
    property double lastLocalScan: 0
    property double now: Date.now()
    property double lastClaudeAttempt: 0
    property double lastCodexAttempt: 0
    readonly property int attemptToleranceSeconds: 5

    function recentlyAttempted(timestamp) {
        if (timestamp <= 0)
            return false;
        return (Date.now() - timestamp) < (root.refreshSeconds - root.attemptToleranceSeconds) * 1000;
    }

    Timer {
        interval: root.refreshSeconds * 1000
        running: root.active && root.enabled
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        interval: 30000
        running: root.active && root.enabled
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = Date.now()
    }

    function refresh() {
        root.now = Date.now();
        root.refreshClaude();
        root.refreshCodex();
        if (Date.now() - root.lastLocalScan >= root.localScanSeconds * 1000)
            root.scanLocal();
    }

    Component {
        id: readerComponent
        FileView {
            blockLoading: true
            printErrors: false
        }
    }

    function readJson(path) {
        const reader = readerComponent.createObject(root, {
            "path": path
        });
        let parsed = null;
        try {
            const text = reader.text();
            parsed = text && text.length > 0 ? JSON.parse(text) : null;
        } catch (e) {
            parsed = null;
        }
        reader.destroy();
        return parsed;
    }

    function request(url, headers, done) {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        for (const name in headers)
            xhr.setRequestHeader(name, headers[name]);
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            let body = null;
            try {
                body = xhr.responseText ? JSON.parse(xhr.responseText) : null;
            } catch (e) {
                body = null;
            }
            done(xhr.status, body);
        };
        xhr.send();
    }

    function keep(previous, next) {
        return Object.assign({}, previous, next);
    }

    function claudePlanName(type, tier) {
        const base = {
            "pro": "Pro",
            "max": "Max",
            "team": "Team",
            "enterprise": "Enterprise"
        }[type] ?? (type ? type.charAt(0).toUpperCase() + type.slice(1) : "");
        const multiplier = /max_(\d+x)/.exec(tier ?? "");
        return multiplier ? `${base} ${multiplier[1]}` : base;
    }

    function claudeWindow(raw) {
        if (!raw || typeof raw.utilization !== "number")
            return null;
        return {
            "percent": raw.utilization,
            "resetsAt": raw.resets_at ? Date.parse(raw.resets_at) : 0
        };
    }

    function claudeProductName(key) {
        const known = {
            "seven_day_opus": "Opus",
            "seven_day_sonnet": "Sonnet",
            "seven_day_cowork": "Cowork",
            "seven_day_oauth_apps": Translation.tr("Other apps")
        };
        if (known[key])
            return known[key];
        const rest = key.replace(/^seven_day_/, "").replace(/_/g, " ");
        return rest.charAt(0).toUpperCase() + rest.slice(1);
    }

    function refreshClaude() {
        if (root.recentlyAttempted(root.lastClaudeAttempt))
            return;
        root.lastClaudeAttempt = Date.now();
        const credentials = root.readJson(`${root.claudeDir}/.credentials.json`);
        const oauth = credentials?.claudeAiOauth;
        if (!oauth || !oauth.accessToken) {
            root.claude = {
                "state": "signedOut"
            };
            return;
        }
        const plan = root.claudePlanName(oauth.subscriptionType, oauth.rateLimitTier);
        if (typeof oauth.expiresAt === "number" && oauth.expiresAt < Date.now()) {
            root.claude = root.keep(root.claude, {
                "state": "expired",
                "plan": plan
            });
            return;
        }
        root.request("https://api.anthropic.com/api/oauth/usage", {
            "Authorization": `Bearer ${oauth.accessToken}`,
            "anthropic-beta": "oauth-2025-04-20",
            "Accept": "application/json"
        }, (status, body) => {
            if (status === 200 && body) {
                const products = Object.keys(body).filter(key => key.startsWith("seven_day_")).map(key => {
                    const window = root.claudeWindow(body[key]);
                    return window ? Object.assign({
                        "name": root.claudeProductName(key)
                    }, window) : null;
                }).filter(entry => entry !== null);
                const extra = body.extra_usage;
                root.claude = {
                    "state": "ok",
                    "plan": plan,
                    "session": root.claudeWindow(body.five_hour),
                    "week": root.claudeWindow(body.seven_day),
                    "products": products,
                    "extra": extra && extra.is_enabled ? {
                        "used": (extra.used_credits ?? 0) / 100,
                        "limit": (extra.monthly_limit ?? 0) / 100,
                        "percent": extra.utilization ?? 0
                    } : null,
                    "updatedAt": Date.now()
                };
            } else if (status === 401 || status === 403) {
                root.claude = root.keep(root.claude, {
                    "state": "expired",
                    "plan": plan
                });
            } else {
                root.claude = root.keep(root.claude, {
                    "state": root.claude.session ? "stale" : "error",
                    "plan": plan,
                    "error": status === 429 ? Translation.tr("Too many requests, trying again soon") : status === 0 ? Translation.tr("No connection") : Translation.tr("Error %1").arg(status)
                });
            }
        });
    }

    function codexWindowName(seconds) {
        if (seconds === 18000)
            return Translation.tr("5-hour");
        if (seconds === 604800)
            return Translation.tr("Weekly");
        if (seconds >= 86400)
            return Translation.tr("%1 days").arg(Math.round(seconds / 86400));
        return Translation.tr("%1 hours").arg(Math.round(seconds / 3600));
    }

    function codexWindow(raw) {
        if (!raw || typeof raw.used_percent !== "number")
            return null;
        return {
            "percent": raw.used_percent,
            "resetsAt": raw.reset_at ? raw.reset_at * 1000 : 0,
            "name": root.codexWindowName(raw.limit_window_seconds ?? 0)
        };
    }

    function refreshCodex() {
        if (root.recentlyAttempted(root.lastCodexAttempt))
            return;
        root.lastCodexAttempt = Date.now();
        const auth = root.readJson(`${root.codexDir}/auth.json`);
        if (!auth) {
            root.codex = {
                "state": "signedOut"
            };
            return;
        }
        const tokens = auth.tokens;
        if (!tokens || !tokens.access_token) {
            root.codex = {
                "state": auth.OPENAI_API_KEY ? "apiKey" : "signedOut"
            };
            return;
        }
        const headers = {
            "Authorization": `Bearer ${tokens.access_token}`,
            "Accept": "application/json"
        };
        if (tokens.account_id)
            headers["chatgpt-account-id"] = tokens.account_id;
        root.request("https://chatgpt.com/backend-api/wham/usage", headers, (status, body) => {
            if (status === 200 && body) {
                const limits = body.rate_limit ?? {};
                const credits = body.credits;
                const plan = body.plan_type ?? "";
                root.codex = {
                    "state": "ok",
                    "plan": plan ? plan.charAt(0).toUpperCase() + plan.slice(1) : "",
                    "primary": root.codexWindow(limits.primary_window),
                    "secondary": root.codexWindow(limits.secondary_window),
                    "credits": credits && (credits.has_credits || credits.unlimited) ? {
                        "unlimited": credits.unlimited === true,
                        "balance": Number(credits.balance ?? 0)
                    } : null,
                    "updatedAt": Date.now()
                };
            } else if (status === 401 || status === 403) {
                root.codex = root.keep(root.codex, {
                    "state": "expired"
                });
            } else {
                root.codex = root.keep(root.codex, {
                    "state": root.codex.primary ? "stale" : "error",
                    "error": status === 429 ? Translation.tr("Too many requests, trying again soon") : status === 0 ? Translation.tr("No connection") : Translation.tr("Error %1").arg(status)
                });
            }
        });
    }

    function scanLocal() {
        if (localProc.running)
            return;
        const weekStart = root.claude.week?.resetsAt ? root.claude.week.resetsAt - 7 * 86400000 : 0;
        const since = weekStart > 0 && weekStart < Date.now() ? weekStart : Date.now() - 7 * 86400000;
        root.lastLocalScan = Date.now();
        const sinceArg = String(Math.floor(since / 1000));
        localProc.command = Platform.isWindows
            ? ["powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", root.localScriptPath, sinceArg]
            : ["python3", root.localScriptPath, sinceArg];
        localProc.running = true;
    }

    Process {
        id: localProc
        stdout: StdioCollector {
            id: localCollector
            onStreamFinished: {
                try {
                    const data = JSON.parse(localCollector.text);
                    const models = Object.keys(data.models ?? {}).map(name => {
                        const m = data.models[name];
                        return {
                            "name": name,
                            "total": m.input + m.output + m.cacheWrite + m.cacheRead,
                            "output": m.output,
                            "messages": m.messages
                        };
                    }).sort((a, b) => b.total - a.total);
                    root.claudeLocal = {
                        "since": data.since * 1000,
                        "models": models,
                        "total": models.reduce((sum, m) => sum + m.total, 0)
                    };
                } catch (e) {
                    root.claudeLocal = null;
                }
            }
        }
    }
}

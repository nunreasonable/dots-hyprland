pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    property bool loadAsync: false

    readonly property var claude: AiLimits.claude
    readonly property var codex: AiLimits.codex
    readonly property var claudeLocal: AiLimits.claudeLocal
    readonly property double now: AiLimits.now

    readonly property int cardSpacing: 16
    readonly property int minCardWidth: 360
    readonly property real layoutWidth: root.width - 2 * Appearance.rounding.small
    readonly property int cardColumns: root.layoutWidth >= root.minCardWidth * 2 + root.cardSpacing ? 2 : 1
    readonly property real cardWidth: (root.layoutWidth - (root.cardColumns - 1) * root.cardSpacing) / root.cardColumns
    readonly property int gaugeSize: Math.max(64, Math.min(104, Math.floor((root.cardWidth - 32) / 3) - 24))

    implicitWidth: (QsWindow?.window?.screen.width ?? 1280) * 0.7
    implicitHeight: (QsWindow?.window?.screen.height ?? 800) * 0.7

    function percentText(value) {
        return typeof value === "number" ? `${Math.round(value)}%` : "—";
    }

    function ringColor(value) {
        return value >= 90 ? Appearance.colors.colError : Appearance.colors.colPrimary;
    }

    function durationText(ms) {
        const minutes = Math.max(1, Math.round(ms / 60000));
        const days = Math.floor(minutes / 1440);
        const hours = Math.floor((minutes % 1440) / 60);
        const mins = minutes % 60;
        if (days > 0)
            return hours > 0 ? Translation.tr("%1d %2h").arg(days).arg(hours) : Translation.tr("%1d").arg(days);
        if (hours > 0)
            return mins > 0 ? Translation.tr("%1h %2m").arg(hours).arg(mins) : Translation.tr("%1h").arg(hours);
        return Translation.tr("%1m").arg(mins);
    }

    function resetText(ms) {
        if (!ms)
            return "";
        const left = ms - root.now;
        if (left <= 0)
            return Translation.tr("resetting now");
        if (left < 86400000)
            return Translation.tr("resets in %1").arg(root.durationText(left));
        return Translation.tr("resets %1").arg(Qt.locale().toString(new Date(ms), "ddd HH:mm"));
    }

    function tokensText(value) {
        if (value >= 1e9)
            return `${(value / 1e9).toFixed(2)}B`;
        if (value >= 1e6)
            return `${(value / 1e6).toFixed(1)}M`;
        if (value >= 1e3)
            return `${(value / 1e3).toFixed(1)}K`;
        return `${value}`;
    }

    function moneyText(value) {
        const number = Number(value);
        return Number.isInteger(number) ? `$${number}` : `$${number.toFixed(2)}`;
    }

    function updatedText(provider) {
        if (!provider?.updatedAt)
            return "";
        const ago = root.now - provider.updatedAt;
        return ago < 60000 ? Translation.tr("Updated just now") : Translation.tr("Updated %1 ago").arg(root.durationText(ago));
    }

    function modelName(id) {
        const match = /^claude-([a-z]+)-(\d+)(?:-(\d+))?/.exec(id);
        if (!match)
            return id;
        const family = match[1].charAt(0).toUpperCase() + match[1].slice(1);
        const version = match[3] && match[3].length <= 2 ? `${match[2]}.${match[3]}` : match[2];
        return `${family} ${version}`;
    }

    function refreshText() {
        const seconds = AiLimits.refreshSeconds;
        if (seconds === 60)
            return Translation.tr("refreshes every minute");
        if (seconds % 60 === 0)
            return Translation.tr("refreshes every %1 minutes").arg(seconds / 60);
        return Translation.tr("refreshes every %1 seconds").arg(seconds);
    }

    component Notice: RowLayout {
        id: notice
        property string icon: "info"
        property string text: ""
        property bool warning: false
        Layout.fillWidth: true
        spacing: 10

        MaterialSymbol {
            Layout.alignment: Qt.AlignTop
            text: notice.icon
            iconSize: Appearance.font.pixelSize.larger
            color: notice.warning ? Appearance.colors.colError : Appearance.colors.colSubtext
        }
        StyledText {
            Layout.fillWidth: true
            text: notice.text
            wrapMode: Text.Wrap
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
        }
    }

    component SectionLabel: StyledText {
        Layout.fillWidth: true
        Layout.topMargin: 4
        font.pixelSize: Appearance.font.pixelSize.small
        font.weight: Font.Medium
        color: Appearance.colors.colOnLayer1
    }

    Loader {
        id: contentLoader
        property bool wasLoaded: false
        anchors.fill: parent
        active: !Platform.isWindows || root.SwipeView.isCurrentItem || root.loadAsync || contentLoader.wasLoaded
        asynchronous: root.loadAsync
        onLoaded: contentLoader.wasLoaded = true

        sourceComponent: Item {
            StyledFlickable {
                id: flickable
                anchors.fill: parent
                anchors.margins: Appearance.rounding.small
                clip: true
                contentWidth: width
                contentHeight: mainColumn.implicitHeight

                ColumnLayout {
                    id: mainColumn
                    width: flickable.width
                    spacing: 16

                    GridLayout {
                        Layout.fillWidth: true
                        columns: root.cardColumns
                        columnSpacing: root.cardSpacing
                        rowSpacing: root.cardSpacing

                        CheatsheetSystemCard {
                            id: claudeCard
                            readonly property string status: root.claude.state ?? "idle"
                            readonly property bool hasData: !!(root.claude.session || root.claude.week)
                            Layout.preferredWidth: 1
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignTop
                            icon: "asterisk"
                            label: "Claude"
                            title: root.claude.plan || (claudeCard.status === "signedOut" ? Translation.tr("Not signed in") : "—")
                            subtitle: root.updatedText(root.claude)

                            RowLayout {
                                visible: claudeCard.hasData
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 12

                                CheatsheetSystemGauge {
                                    visible: !!root.claude.session
                                    ringSize: root.gaugeSize
                                    value: (root.claude.session?.percent ?? 0) / 100
                                    ringColor: root.ringColor(root.claude.session?.percent ?? 0)
                                    bigText: root.percentText(root.claude.session?.percent)
                                    smallText: Translation.tr("session")
                                    caption: root.resetText(root.claude.session?.resetsAt)
                                }
                                CheatsheetSystemGauge {
                                    visible: !!root.claude.week
                                    ringSize: root.gaugeSize
                                    value: (root.claude.week?.percent ?? 0) / 100
                                    ringColor: root.ringColor(root.claude.week?.percent ?? 0)
                                    bigText: root.percentText(root.claude.week?.percent)
                                    smallText: Translation.tr("week")
                                    caption: root.resetText(root.claude.week?.resetsAt)
                                }
                                CheatsheetSystemGauge {
                                    visible: !!root.claude.extra
                                    ringSize: root.gaugeSize
                                    value: (root.claude.extra?.percent ?? 0) / 100
                                    ringColor: root.ringColor(root.claude.extra?.percent ?? 0)
                                    bigText: root.percentText(root.claude.extra?.percent)
                                    smallText: Translation.tr("extra")
                                    caption: root.claude.extra ? `${root.moneyText(root.claude.extra.used)} / ${root.moneyText(root.claude.extra.limit)}` : ""
                                }
                            }

                            Notice {
                                visible: claudeCard.status === "signedOut"
                                icon: "login"
                                text: Translation.tr("Sign in to Claude Code to see your plan limits: run claude in a terminal and type /login.")
                            }
                            Notice {
                                visible: claudeCard.status === "expired"
                                icon: "schedule"
                                text: Translation.tr("The Claude Code login expired. Open Claude Code once and it renews itself.")
                            }
                            Notice {
                                visible: claudeCard.status === "error" || claudeCard.status === "stale"
                                icon: "cloud_off"
                                warning: claudeCard.status === "error"
                                text: Translation.tr("Couldn't update the limits: %1").arg(root.claude.error ?? "")
                            }
                            Notice {
                                visible: claudeCard.status === "idle"
                                icon: "hourglass_top"
                                text: Translation.tr("Loading…")
                            }

                            SectionLabel {
                                visible: (root.claude.products ?? []).length > 0
                                text: Translation.tr("This week by model")
                            }
                            Repeater {
                                model: root.claude.products ?? []
                                delegate: CheatsheetSystemUsageBar {
                                    required property var modelData
                                    label: modelData.name
                                    valueText: root.resetText(modelData.resetsAt)
                                    percentText: root.percentText(modelData.percent)
                                    ratio: modelData.percent / 100
                                    barColor: root.ringColor(modelData.percent)
                                }
                            }

                            SectionLabel {
                                visible: (root.claudeLocal?.models ?? []).length > 0
                                text: Translation.tr("On this PC since %1").arg(Qt.locale().toString(new Date(root.claudeLocal?.since ?? 0), "ddd d MMM"))
                            }
                            Repeater {
                                model: root.claudeLocal?.models ?? []
                                delegate: CheatsheetSystemUsageBar {
                                    required property var modelData
                                    icon: "token"
                                    label: root.modelName(modelData.name)
                                    valueText: (modelData.messages === 1 ? Translation.tr("1 message · %1 out") : Translation.tr("%1 messages · %2 out").arg(modelData.messages)).arg(root.tokensText(modelData.output))
                                    percentText: root.tokensText(modelData.total)
                                    ratio: root.claudeLocal.models[0].total > 0 ? modelData.total / root.claudeLocal.models[0].total : 0
                                    barColor: Appearance.colors.colSecondary
                                }
                            }
                        }

                        CheatsheetSystemCard {
                            id: codexCard
                            readonly property string status: root.codex.state ?? "idle"
                            readonly property bool hasData: !!(root.codex.primary || root.codex.secondary)
                            Layout.preferredWidth: 1
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignTop
                            icon: "terminal"
                            label: "Codex"
                            title: root.codex.plan || (codexCard.status === "signedOut" ? Translation.tr("Not signed in") : codexCard.status === "apiKey" ? Translation.tr("API key") : "—")
                            subtitle: root.updatedText(root.codex)

                            RowLayout {
                                visible: codexCard.hasData
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 12

                                CheatsheetSystemGauge {
                                    visible: !!root.codex.primary
                                    ringSize: root.gaugeSize
                                    value: (root.codex.primary?.percent ?? 0) / 100
                                    ringColor: root.ringColor(root.codex.primary?.percent ?? 0)
                                    bigText: root.percentText(root.codex.primary?.percent)
                                    smallText: root.codex.primary?.name ?? ""
                                    caption: root.resetText(root.codex.primary?.resetsAt)
                                }
                                CheatsheetSystemGauge {
                                    visible: !!root.codex.secondary
                                    ringSize: root.gaugeSize
                                    value: (root.codex.secondary?.percent ?? 0) / 100
                                    ringColor: root.ringColor(root.codex.secondary?.percent ?? 0)
                                    bigText: root.percentText(root.codex.secondary?.percent)
                                    smallText: root.codex.secondary?.name ?? ""
                                    caption: root.resetText(root.codex.secondary?.resetsAt)
                                }
                            }

                            CheatsheetSystemStatChip {
                                visible: !!root.codex.credits
                                icon: "toll"
                                text: root.codex.credits?.unlimited ? Translation.tr("Unlimited credits") : Translation.tr("%1 credits left").arg(root.codex.credits?.balance ?? 0)
                            }

                            Notice {
                                visible: codexCard.status === "signedOut"
                                icon: "login"
                                text: Translation.tr("Sign in to Codex to see your plan limits: run codex in a terminal and sign in with ChatGPT.")
                            }
                            Notice {
                                visible: codexCard.status === "apiKey"
                                icon: "key"
                                text: Translation.tr("Codex is using an API key. Plan limits only exist when you sign in with ChatGPT.")
                            }
                            Notice {
                                visible: codexCard.status === "expired"
                                icon: "schedule"
                                text: Translation.tr("The Codex login expired. Open Codex once and it renews itself.")
                            }
                            Notice {
                                visible: codexCard.status === "error" || codexCard.status === "stale"
                                icon: "cloud_off"
                                warning: codexCard.status === "error"
                                text: Translation.tr("Couldn't update the limits: %1").arg(root.codex.error ?? "")
                            }
                            Notice {
                                visible: codexCard.status === "idle"
                                icon: "hourglass_top"
                                text: Translation.tr("Loading…")
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        text: Translation.tr("Data from the local Claude Code and Codex logins · %1 · turn off in Settings › Interface › Cheat sheet").arg(root.refreshText())
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }
}

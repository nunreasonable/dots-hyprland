pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    property var entriesByPage: ({})

    readonly property var labelledTypes: [
        "ConfigSwitch", "ConfigSpinBox", "ConfigTextArea", "ConfigSelectionArray",
        "ConfigComboBox", "ConfigSlider", "ConfigSelectionShapeArray", "ConfigRow",
        "ColorSelectionArray", "ContentSubsection"
    ]

    function hiddenByGate(line) {
        const gate = line.match(/^\s*(?:visible|active):\s*(!?)Platform\.isWindows\s*$/);
        if (!gate) return false;
        return (gate[1] === "!") === Platform.isWindows;
    }

    function parsePage(source) {
        const typeOpen = /^\s*(?:sourceComponent:\s*)?([A-Z][\w.]*)\s*\{/;
        const labelProp = /^\s*(title|text):\s*Translation\.tr\(\s*(?:"((?:[^"\\]|\\.)*)"|'((?:[^'\\]|\\.)*)')\s*\)/;
        const entries = [];
        const stack = [];
        let section = "";
        let subsection = "";
        for (const line of source.split("\n")) {
            if (stack.length > 0 && root.hiddenByGate(line)) stack[stack.length - 1].hidden = true;
            const hidden = stack.some(entry => entry.hidden);
            const prop = line.match(labelProp);
            const type = stack.length > 0 ? stack[stack.length - 1].type : null;
            if (prop && type && !hidden) {
                const label = (prop[2] ?? prop[3]).replace(/\\(["'])/g, "$1");
                if (type === "ContentSection" && prop[1] === "title") {
                    section = label;
                    subsection = "";
                    entries.push({ kind: "section", section: label, subsection: "", label: label });
                } else if (root.labelledTypes.includes(type)) {
                    entries.push({ kind: "option", section: section, subsection: type === "ContentSubsection" ? "" : subsection, label: label });
                    if (type === "ContentSubsection") subsection = label;
                }
            }
            const opens = (line.match(/\{/g) || []).length;
            const closes = (line.match(/\}/g) || []).length;
            for (let i = 0; i < closes; i++) stack.pop();
            const typeMatch = line.match(typeOpen);
            for (let i = 0; i < opens; i++) stack.push({ type: i === 0 && typeMatch ? typeMatch[1].split(".").pop() : null, hidden: false });
        }
        return entries;
    }

    function indexPage(pageId, source) {
        const next = Object.assign({}, root.entriesByPage);
        next[pageId] = root.parsePage(source);
        root.entriesByPage = next;
    }

    function search(query, limit) {
        const tokens = query.toLowerCase().trim().split(/\s+/).filter(t => t.length > 0);
        if (tokens.length === 0) return [];

        const results = [];
        for (const page of SettingsPages.pages) {
            const pageName = page.name.toLowerCase();
            const pageScore = root.scoreText(pageName, tokens);
            if (pageScore > 0) {
                results.push({
                    pageId: page.id, pageName: page.name, icon: page.icon,
                    kind: "page", section: "", label: page.name, score: pageScore + 50
                });
            }
            for (const entry of (root.entriesByPage[page.id] ?? [])) {
                const label = Translation.tr(entry.label);
                const section = Translation.tr(entry.section);
                const haystack = (label + " " + entry.label + " " + section + " " + pageName).toLowerCase();
                if (!tokens.every(t => haystack.includes(t))) continue;
                const labelScore = Math.max(
                    root.scoreText(label.toLowerCase(), tokens),
                    root.scoreText(entry.label.toLowerCase(), tokens)
                );
                results.push({
                    pageId: page.id, pageName: page.name, icon: page.icon,
                    kind: entry.kind, section: section, label: label, rawLabel: entry.label, rawSection: entry.section, subsection: Translation.tr(entry.subsection ?? ""), rawSubsection: entry.subsection ?? "",
                    score: labelScore + (entry.kind === "section" ? 10 : 0)
                });
            }
        }
        results.sort((a, b) => b.score - a.score);
        return results.slice(0, limit);
    }

    function scoreText(text, tokens) {
        let score = 0;
        for (const token of tokens) {
            const at = text.indexOf(token);
            if (at < 0) continue;
            if (text === token) score += 100;
            else if (at === 0) score += 60;
            else if (text[at - 1] === " ") score += 40;
            else score += 20;
        }
        return score;
    }

    Instantiator {
        model: SettingsPages.files
        delegate: FileView {
            required property int index
            required property string modelData
            path: FileUtils.trimFileProtocol(Quickshell.shellPath(SettingsPages.pagesDir + modelData))
            onLoaded: root.indexPage(SettingsPages.ids[index], text())
        }
    }
}

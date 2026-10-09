pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var allSymbols: []

    FileView {
        id: symbolsFile
        path: `${Directories.assetsPath}/material_symbols_rounded.json`
        watchChanges: false
        onLoaded: {
            try {
                root.allSymbols = JSON.parse(symbolsFile.text());
            } catch (e) {
                console.warn("MaterialSymbolsSearch: failed to parse JSON -", e);
                root.allSymbols = [];
            }
        }
    }

    function fuzzyQuery(query) {
        if (!query || query.length === 0)
            return root.allSymbols.slice(0, 30).map(sym => root._format(sym));

        const q = query.toLowerCase();
        const scored = [];

        for (const sym of root.allSymbols) {
            const nameLower = sym.name.toLowerCase();

            if (nameLower === q) {
                scored.push({
                    score: 100,
                    sym
                });
                continue;
            }
            if (nameLower.startsWith(q)) {
                scored.push({
                    score: 80,
                    sym
                });
                continue;
            }
            if (nameLower.includes(q)) {
                scored.push({
                    score: 60,
                    sym
                });
                continue;
            }
            let tagScore = 0;
            for (const tag of sym.tags) {
                const tl = tag.toLowerCase();
                if (tl === q) {
                    tagScore = Math.max(tagScore, 50);
                    break;
                }
                if (tl.startsWith(q)) {
                    tagScore = Math.max(tagScore, 35);
                } else if (tl.includes(q)) {
                    tagScore = Math.max(tagScore, 20);
                }
            }
            if (tagScore === 0) {
                let qi = 0;
                for (let i = 0; i < nameLower.length && qi < q.length; i++) {
                    if (nameLower[i] === q[qi])
                        qi++;
                }
                if (qi === q.length)
                    tagScore = Math.max(tagScore, 10);
            }

            if (tagScore > 0)
                scored.push({
                    score: tagScore,
                    sym
                });
        }

        scored.sort((a, b) => b.score - a.score);
        const limit = q.length <= 2 ? 50 : 200;
        return scored.slice(0, limit).map(s => root._format(s.sym));
    }

    function _format(sym) {
        return sym.name + "\t" + sym.tags.join(", ");
    }
}

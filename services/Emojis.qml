pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Emojis.
 */
Singleton {
    id: root
    property string emojiScriptPath: Platform.isWindows ? Quickshell.shellPath("defaults/windows/fuzzel-emoji.sh") : `${Directories.config}/hypr/hyprland/scripts/fuzzel-emoji.sh`
	property string lineBeforeData: "### DATA ###"
    property list<var> list
    property bool searched: false
    readonly property var preparedEntries: root.searched ? list.map(a => ({
        name: Fuzzy.prepare(`${a}`),
        entry: a
    })) : []
    function matchTier(entry: string, needle: string): int {
        const name = entry.slice(entry.indexOf(" ") + 1).toLowerCase();
        if (name === needle || name.startsWith(needle + " ")) return 0;
        if ((" " + name + " ").includes(" " + needle + " ")) return 1;
        if ((" " + name).includes(" " + needle)) return 2;
        return 3;
    }

    function fuzzyQuery(search: string): var {
        root.searched = true;
        const needle = search.trim().toLowerCase();
        return Fuzzy.go(search, root.preparedEntries, {
            all: true,
            key: "name"
        }).map((r, i) => ({
            entry: r.obj.entry,
            tier: root.matchTier(r.obj.entry, needle),
            index: i
        })).sort((a, b) => a.tier - b.tier || a.index - b.index).map(r => r.entry);
    }

    function load() {
        emojiFileView.reload()
    }

    function updateEmojis(fileContent) {
        const lines = fileContent.split("\n")
        const dataIndex = lines.indexOf(root.lineBeforeData)
        if (dataIndex === -1) {
            console.warn("No data section found in emoji script file.")
            return
        }
        const emojis = lines.slice(dataIndex + 1).filter(line => line.trim() !== "")
            .filter(line => !Platform.isWindows || !/^\uD83C[\uDDE6-\uDDFF]|\uDB40[\uDC20-\uDC7F]/.test(line))
        root.list = emojis.map(line => line.trim())
    }

    FileView { 
        id: emojiFileView
        path: Qt.resolvedUrl(root.emojiScriptPath)
        onLoadedChanged: {
            const fileContent = emojiFileView.text()
            root.updateEmojis(fileContent)
        }
    }
}

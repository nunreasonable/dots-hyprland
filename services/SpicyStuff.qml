pragma Singleton

import QtQuick
import Quickshell
import qs.modules.common

Singleton {
    id: root

    readonly property QtObject gate: WindowsNative.accountAge
    readonly property bool gated: Platform.isWindows
    readonly property bool checking: root.gated && !(root.gate?.ready ?? false)
    readonly property bool canConfirmAge: root.gated && (root.gate?.canConfirmAge ?? false)
    readonly property bool ageConfirmed: Config.options.policies.spicyAgeConfirmed ?? false
    readonly property bool needsAgeConfirmation: root.canConfirmAge && !root.ageConfirmed
    readonly property bool allowed: !root.gated || (root.gate?.spicyAllowed ?? false) || (root.canConfirmAge && root.ageConfirmed)
    readonly property string restriction: {
        if (root.allowed) return "";
        if (!root.gate) return Translation.tr("Spicy Stuff can't be checked from this window. Open it from ii's settings.");
        return Translation.tr(root.gate.spicyRestriction);
    }

    readonly property bool konachan: Config.options.background.konachanSpicy && root.allowed
    readonly property int maxExtraTags: Config.options.background.konachanOnlyYuri ? 1 : 2

    function extraTags() {
        if (!root.konachan) return [];
        return (Config.options.background.konachanExtraTags ?? "").trim().split(/\s+/)
            .filter(tag => tag.length > 0 && !/^(order|limit|page):/i.test(tag))
            .slice(0, root.maxExtraTags);
    }

    function refresh() {
        root.gate?.refresh();
    }

    function confirmAge() {
        if (root.canConfirmAge)
            Config.options.policies.spicyAgeConfirmed = true;
    }
}

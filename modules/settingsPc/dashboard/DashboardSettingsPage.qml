import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    required property Item pager
    property int staggerMs: 45
    readonly property string query: pager.searchQuery ?? ""

    readonly property real rowHeight: 140
    readonly property real headerHeight: 36
    readonly property real gap: 12

    readonly property var shapePool: [
        MaterialShape.Shape.Cookie6Sided, MaterialShape.Shape.Gem, MaterialShape.Shape.Pentagon,
        MaterialShape.Shape.Flower, MaterialShape.Shape.Puffy, MaterialShape.Shape.Clover8Leaf, MaterialShape.Shape.Sunny
    ]

    DashboardSettingsCatalog {
        id: catalog
    }

    readonly property string group: GlobalStates.dashboardGroup

    readonly property var groupDefs: {
        const c = Appearance.colors;
        const mix = (a, b) => ColorUtils.mix(a, b, 0.5);
        const list = [
            { name: Translation.tr("General"), icon: "browse", container: mix(c.colPrimaryContainer, c.colTertiaryContainer), onContainer: mix(c.colOnPrimaryContainer, c.colOnTertiaryContainer), accent: mix(c.colPrimary, c.colTertiary), onAccent: mix(c.colOnPrimary, c.colOnTertiary) },
            { name: Translation.tr("Interface"), icon: "bottom_app_bar", container: c.colPrimaryContainer, onContainer: c.colOnPrimaryContainer, accent: c.colPrimary, onAccent: c.colOnPrimary },
            { name: Translation.tr("Bar"), icon: "toast", rotation: 180, container: c.colSecondaryContainer, onContainer: c.colOnSecondaryContainer, accent: c.colSecondary, onAccent: c.colOnSecondary },
            { name: Translation.tr("Desktop"), icon: "texture", container: c.colTertiaryContainer, onContainer: c.colOnTertiaryContainer, accent: c.colTertiary, onAccent: c.colOnTertiary },
            { name: Translation.tr("System"), icon: "computer", os: "windows", container: mix(c.colPrimaryContainer, c.colSecondaryContainer), onContainer: mix(c.colOnPrimaryContainer, c.colOnSecondaryContainer), accent: mix(c.colPrimary, c.colSecondary), onAccent: mix(c.colOnPrimary, c.colOnSecondary) },
            { name: Translation.tr("Services"), icon: "settings", container: mix(c.colSecondaryContainer, c.colTertiaryContainer), onContainer: mix(c.colOnSecondaryContainer, c.colOnTertiaryContainer), accent: mix(c.colSecondary, c.colTertiary), onAccent: mix(c.colOnSecondary, c.colOnTertiary) },
            { name: Translation.tr("Profile"), icon: "account_circle", container: Appearance.m3colors.m3surfaceContainerHigh, onContainer: Appearance.m3colors.m3onSurface, accent: c.colPrimary, onAccent: c.colOnPrimary }
        ];
        return list.filter(g => root.osAllowed(g.os));
    }

    readonly property var matchedGroups: {
        const set = {};
        if (tokens.length > 0)
            matches(tokens).forEach(e => {
                set[e.group] = true;
            });
        return set;
    }

    readonly property var railGroups: [Object.assign({ id: "", count: 0 }, {
            name: Translation.tr("All"), icon: "apps",
            container: Appearance.m3colors.m3surfaceContainerHighest, onContainer: Appearance.m3colors.m3onSurface,
            accent: Appearance.m3colors.m3onSurface, onAccent: Appearance.m3colors.m3surface
        })].concat(groupDefs.map(g => Object.assign({ id: g.name, count: allEntries.filter(e => e.kind === "card" && e.group === g.name && isVisibleEntry(e)).length }, g)))

    readonly property var railDimmed: {
        const dim = {};
        if (tokens.length > 0)
            railGroups.forEach(g => {
                if (g.id !== "")
                    dim[g.id] = !matchedGroups[g.id];
            });
        return dim;
    }

    readonly property var groupSections: {
        if (group === "" || tokens.length > 0)
            return [];
        const list = [];
        catalog.sections.forEach((section, si) => {
            if ((section.page ?? "") === group && isVisibleEntry({ requires: section.requires ?? "", when: section.when, os: section.os }))
                list.push({ index: si, title: section.title });
        });
        return list;
    }

    function osAllowed(os) {
        return !os || (os === "windows") === Platform.isWindows;
    }

    function spanOf(entry) {
        return entry.w ? [entry.w, 1] : baseSpan(entry.type);
    }

    function baseSpan(type) {
        if (type === "style" || type === "visualstyle")
            return [2, 2];
        if (type === "schemes" || type === "barpos")
            return [2, 2];
        if (type === "weathermap")
            return [4, 2];
        if (type === "webapps")
            return [4, 3];
        if (type === "collagelayouts")
            return [4, 2];
        if (type === "timepreview")
            return [3, 2];
        if (type === "widgets")
            return [4, 3];
        if (type === "shape")
            return [2, 2];
        if (type === "barlayout")
            return [4, 3];
        if (type === "palette")
            return [4, 1];
        if (type === "iconpicker")
            return [2, 2];
        if (type === "toggle" || type === "spin")
            return [1, 1];
        return [2, 1];
    }

    readonly property var heroEntries: catalog.heroes

    readonly property var allEntries: {
        const list = [];
        heroEntries.forEach(e => list.push(Object.assign({ kind: "card", hero: true, group: e.section }, e)));
        catalog.sections.forEach((section, si) => {
            list.push({ id: "section:" + si, kind: "header", requires: section.requires ?? "", when: section.when, os: section.os, title: section.title, icon: section.icon, page: section.page ?? "", group: section.page ?? "", section: section.title, sectionIndex: si, count: section.cards.length });
            section.cards.forEach((card, ci) => list.push(Object.assign({
                kind: "card", ordered: section.ordered ?? false, requires: section.requires ?? "", group: section.page ?? "", section: section.title, sectionIndex: si, kw: ""
            }, card, {
                id: "card:" + si + ":" + ci + ":" + (card.key ?? card.pageId ?? ""),
                when: card.when ?? section.when,
                os: card.os ?? section.os,
                section: section.title,
                pageSection: card.type === "page" ? (card.section ?? "") : ""
            })));
        });
        const heroGroups = {};
        heroEntries.forEach(e => {
            heroGroups[e.section] = (heroGroups[e.section] ?? 0) + 1;
        });
        Object.keys(heroGroups).forEach(name => list.push({
            id: "hsection:" + name, kind: "header", searchOnly: true, requires: "",
            title: name, icon: name === Translation.tr("Desktop") ? "texture" : name === Translation.tr("Bar") ? "toast" : name === Translation.tr("System") ? "computer" : name === Translation.tr("General") ? "browse" : "bottom_app_bar",
            page: name, group: name, section: name, count: heroGroups[name]
        }));
        return list.map(e => Object.assign(e, {
            shape: shapePool[Math.floor(Math.random() * shapePool.length)],
            travelX: (Math.random() - 0.5) * 500,
            travelY: (Math.random() - 0.5) * 400
        }));
    }

    readonly property var usedWidgets: {
        const layouts = Config.options.bar.layouts;
        return Array.from(layouts.leftLayout).concat(Array.from(layouts.middleLayout), Array.from(layouts.rightLayout));
    }

    function isVisibleEntry(e) {
        if (!osAllowed(e.os))
            return false;
        if (typeof e.when === "function" && !e.when())
            return false;
        return !e.requires || usedWidgets.includes(e.requires);
    }

    function normalized(text) {
        return String(text ?? "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/[_\-.:/]+/g, " ");
    }

    function scoreToken(key, token) {
        const index = key.indexOf(token);
        if (index >= 0) {
            const wordStart = index === 0 || key.charAt(index - 1) === " ";
            return 200 + (wordStart ? 60 : 0) - Math.min(index, 40) + Math.min(token.length, 12);
        }
        if (token.length < 3)
            return -1;
        let position = 0;
        let gaps = 0;
        let last = -1;
        for (let i = 0; i < token.length; i++) {
            const found = key.indexOf(token.charAt(i), position);
            if (found < 0)
                return -1;
            if (last >= 0)
                gaps += found - last - 1;
            last = found;
            position = found + 1;
        }
        return Math.max(1, 100 - gaps * 3 - token.length);
    }

    function scoreItem(key, tokens) {
        let total = 0;
        for (const token of tokens) {
            const score = scoreToken(key, token);
            if (score < 0)
                return -1;
            total += score;
        }
        return total;
    }

    function matches(tokens) {
        const scored = [];
        allEntries.forEach(e => {
            if (e.kind !== "card" || (e.hero && e.type === "toggle" && !e.searchable) || !isVisibleEntry(e))
                return;
            const key = normalized([e.title, e.section, e.kw, e.key ?? ""].join(" "));
            const score = scoreItem(key, tokens);
            if (score < 0)
                return;
            const sectionScore = scoreItem(normalized(e.section ?? ""), tokens);
            scored.push({ entry: e, score: sectionScore >= 0 ? score + 1000 : score });
        });
        scored.sort((a, b) => b.score - a.score);
        return scored.map(s => s.entry);
    }

    function isEnableCard(card) {
        return card.type === "toggle" && !card.keepOrder && card.title === Translation.tr("Enable");
    }

    function packSequential(cards, capacity) {
        const placed = [];
        let remaining = capacity;
        let rowStart = 0;
        cards.forEach(card => {
            const span = Math.min(spanOf(card)[0], capacity);
            if (span > remaining) {
                let leftover = remaining;
                let i = placed.length - 1;
                while (leftover > 0 && i >= rowStart) {
                    placed[i].w += 1;
                    leftover--;
                    i = i === rowStart ? placed.length - 1 : i - 1;
                }
                remaining = capacity;
                rowStart = placed.length;
            }
            placed.push({ entry: card, w: span, h: spanOf(card)[1] });
            remaining -= span;
            if (remaining === 0) {
                remaining = capacity;
                rowStart = placed.length;
            }
        });
        let leftover = remaining === capacity ? 0 : remaining;
        let i = placed.length - 1;
        while (leftover > 0 && i >= rowStart) {
            placed[i].w += 1;
            leftover--;
            i = i === rowStart ? placed.length - 1 : i - 1;
        }
        return placed;
    }

    function packRows(allCards, capacity) {
        if (allCards.length > 0 && allCards[0].ordered)
            return packSequential(allCards, capacity);
        const enables = allCards.filter(c => isEnableCard(c));
        const cards = allCards.filter(c => !isEnableCard(c));
        const fulls = cards.filter(c => spanOf(c)[0] === 4);
        const wides = cards.filter(c => spanOf(c)[0] === 2);
        const allSmalls = cards.filter(c => spanOf(c)[0] === 1);
        const tall = cards.filter(c => spanOf(c)[0] === 3);
        const side = tall.length > 0 ? allSmalls.slice(0, 2) : [];
        const smalls = allSmalls.slice(side.length);
        const placed = [];
        enables.forEach(card => placed.push({ entry: card, w: 1, h: 1 }));
        tall.forEach(card => placed.push({ entry: card, w: 3, h: spanOf(card)[1] }));
        side.forEach(card => placed.push({ entry: card, w: 1, h: 1 }));
        let remaining = capacity;
        let rowStart = placed.length;
        const ghosts = wides.length === 0 ? enables.map(() => ({ ghost: true })) : [];
        fulls.concat(ghosts, wides, smalls).forEach(card => {
            const span = card.ghost ? 1 : spanOf(card)[0];
            if (span > remaining) {
                remaining = capacity;
                rowStart = placed.length;
            }
            if (!card.ghost)
                placed.push({ entry: card, w: span, h: spanOf(card)[1] });
            remaining -= span;
            if (remaining === 0) {
                remaining = capacity;
                rowStart = placed.length;
            }
        });
        let leftover = remaining === capacity ? 0 : remaining;
        let i = placed.length - 1;
        while (leftover > 0 && i >= rowStart) {
            placed[i].w += 1;
            leftover--;
            i = i === rowStart ? placed.length - 1 : i - 1;
        }
        return placed;
    }

    function computeLayout(tokens) {
        const items = [];
        if (tokens.length > 0) {
            const groups = {};
            const order = [];
            matches(tokens).forEach(e => {
                const groupId = e.sectionIndex !== undefined ? "section:" + e.sectionIndex : "hsection:" + e.section;
                if (!groups[groupId]) {
                    groups[groupId] = [];
                    order.push(groupId);
                }
                groups[groupId].push(e);
            });
            order.forEach(groupId => {
                const header = allEntries.find(e => e.id === groupId);
                if (header)
                    items.push({ entry: header, w: 4, h: 1, header: true });
                packRows(groups[groupId], 4).forEach(p => items.push(p));
            });
        } else {
            let i = 0;
            while (i < allEntries.length) {
                const e = allEntries[i];
                if (e.searchOnly || !isVisibleEntry(e) || (group !== "" && e.group !== group)) {
                    i++;
                    continue;
                }
                if (e.kind === "header") {
                    const cards = [];
                    i++;
                    while (i < allEntries.length && allEntries[i].kind === "card") {
                        if (isVisibleEntry(allEntries[i]))
                            cards.push(allEntries[i]);
                        i++;
                    }
                    if (cards.length === 0)
                        continue;
                    items.push({ entry: e, w: 4, h: 1, header: true });
                    packRows(cards, 4).forEach(p => items.push(p));
                } else {
                    const s = spanOf(e);
                    items.push({ entry: e, w: s[0], h: s[1] });
                    i++;
                }
            }
        }

        const occ = [];
        const rowH = [];
        const map = {};
        let floor = 0;

        function ensure(r) {
            while (occ.length <= r) {
                occ.push([false, false, false, false]);
                rowH.push(rowHeight);
            }
        }

        function fits(r, c, w, h) {
            for (let dr = 0; dr < h; dr++) {
                ensure(r + dr);
                for (let dc = 0; dc < w; dc++)
                    if (occ[r + dr][c + dc])
                        return false;
            }
            return true;
        }

        items.forEach(it => {
            if (it.header) {
                const r = occ.length;
                ensure(r);
                occ[r] = [true, true, true, true];
                rowH[r] = headerHeight;
                map[it.entry.id] = { col: 0, row: r, w: 4, h: 1, header: true };
                floor = r + 1;
                return;
            }
            let r = floor;
            for (;; r++) {
                let found = -1;
                for (let c = 0; c + it.w <= 4; c++) {
                    if (fits(r, c, it.w, it.h)) {
                        found = c;
                        break;
                    }
                }
                if (found >= 0) {
                    for (let dr = 0; dr < it.h; dr++)
                        for (let dc = 0; dc < it.w; dc++)
                            occ[r + dr][found + dc] = true;
                    map[it.entry.id] = { col: found, row: r, w: it.w, h: it.h };
                    break;
                }
            }
        });

        function free(r, c, w, h) {
            for (let dr = 0; dr < h; dr++)
                for (let dc = 0; dc < w; dc++)
                    if (r + dr >= occ.length || c + dc < 0 || c + dc > 3 || occ[r + dr][c + dc])
                        return false;
            return true;
        }

        function mark(r, c, w, h) {
            for (let dr = 0; dr < h; dr++)
                for (let dc = 0; dc < w; dc++)
                    occ[r + dr][c + dc] = true;
        }

        Object.keys(map).forEach(id => {
            const p = map[id];
            if (p.header)
                return;
            while (free(p.row, p.col + p.w, 1, p.h)) {
                mark(p.row, p.col + p.w, 1, p.h);
                p.w++;
            }
            while (free(p.row, p.col - 1, 1, p.h)) {
                mark(p.row, p.col - 1, 1, p.h);
                p.col--;
                p.w++;
            }
            while (free(p.row + p.h, p.col, p.w, 1)) {
                mark(p.row + p.h, p.col, p.w, 1);
                p.h++;
            }
        });

        const rowY = [];
        let y = 0;
        rowH.forEach(h => {
            rowY.push(y);
            y += h + gap;
        });
        Object.keys(map).forEach(id => {
            const p = map[id];
            let height = 0;
            for (let dr = 0; dr < p.h; dr++)
                height += rowH[p.row + dr] + (dr > 0 ? gap : 0);
            p.y = rowY[p.row];
            p.height = height;
        });
        return { map: map, total: Math.max(0, y - gap), count: items.filter(i => !i.header).length };
    }

    readonly property var tokens: normalized(query).split(/\s+/).filter(t => t.length > 0)
    readonly property var layoutResult: computeLayout(tokens)
    readonly property var layoutMap: layoutResult.map

    onTokensChanged: {
        flick.contentY = 0;
        if (tokens.length > 0)
            closeClassic();
    }
    onGroupChanged: {
        flick.contentY = 0;
        closeClassic();
    }

    readonly property int activeSection: {
        if (groupSections.length === 0)
            return -1;
        const top = flick.contentY + 8;
        const atEnd = flick.contentHeight > flick.height && flick.contentY >= flick.contentHeight - flick.height - 2;
        if (atEnd)
            return groupSections[groupSections.length - 1].index;
        let best = groupSections[0].index;
        groupSections.forEach(sec => {
            const place = layoutMap["section:" + sec.index];
            if (place && place.y <= top)
                best = sec.index;
        });
        return best;
    }

    property string pendingSection: ""

    function openSection(groupName, sectionTitle) {
        GlobalStates.dashboardGroup = groupName;
        root.pendingSection = sectionTitle;
        pendingScrollTimer.restart();
    }

    Timer {
        id: pendingScrollTimer
        interval: 280
        onTriggered: {
            const index = catalog.sections.findIndex(section => (section.page ?? "") === root.group && section.title === root.pendingSection);
            if (index >= 0)
                root.scrollToSection(index);
            root.pendingSection = "";
        }
    }

    function scrollToSection(index) {
        const place = layoutMap["section:" + index];
        if (place)
            flick.contentY = Math.max(0, Math.min(place.y, Math.max(0, flick.contentHeight - flick.height)));
    }

    function scrollBy(delta) {
        if (root.classicOpen) {
            const page = classicLoader.item;
            if (page && page.contentY !== undefined)
                page.contentY = Math.max(0, Math.min(Math.max(0, (page.contentHeight ?? 0) - page.height), page.contentY + delta));
            return;
        }
        flick.contentY = Math.max(0, Math.min(Math.max(0, flick.contentHeight - flick.height), flick.contentY + delta));
    }

    property var classicTarget: null
    readonly property bool classicOpen: classicTarget !== null
    readonly property var classicPage: classicTarget ? SettingsPages.byId(classicTarget.page) : null

    function openClassic(target) {
        if (!target || !SettingsPages.byId(target.page))
            return;
        root.classicTarget = {
            page: target.page,
            section: target.section ?? "",
            subsection: target.subsection ?? "",
            label: target.label ?? ""
        };
        if (classicLoader.item)
            root.jumpClassic();
    }

    function jumpClassic() {
        const target = root.classicTarget;
        const page = classicLoader.item;
        if (!target || !page || typeof page.goTo !== "function")
            return;
        if (target.label === "" && target.section === "")
            return;
        Qt.callLater(() => page.goTo(Translation.tr(target.label), Translation.tr(target.section), Translation.tr(target.subsection)));
    }

    function closeClassic() {
        root.classicTarget = null;
        root.pager.forceActiveFocus();
    }

    DashboardGroupRail {
        id: rail
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 70
        groups: root.railGroups
        current: root.group
        dimmed: root.railDimmed
        onPicked: id => {
            GlobalStates.dashboardGroup = id;
            root.closeClassic();
        }
    }

    Flickable {
        id: chipsRow
        anchors.left: rail.right
        anchors.leftMargin: 16
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.groupSections.length > 0 ? 40 : 0
        opacity: root.groupSections.length > 0 && !root.classicOpen ? 1 : 0
        visible: opacity > 0
        clip: true
        contentWidth: chipsLayout.implicitWidth
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds

        WheelHandler {
            enabled: chipsRow.contentWidth > chipsRow.width
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                const delta = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y) ? event.angleDelta.x : event.angleDelta.y;
                chipsRow.contentX = Math.max(0, Math.min(chipsRow.contentWidth - chipsRow.width, chipsRow.contentX - delta));
            }
        }

        Behavior on height {
            NumberAnimation { duration: 220 / Math.max(0.5, Config.options.settings.animationSpeed ?? 1); easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: 180 }
        }

        RowLayout {
            id: chipsLayout
            height: 34
            spacing: 8

            Repeater {
                model: root.groupSections

                delegate: RippleButton {
                    id: chip
                    required property var modelData
                    readonly property bool selected: root.activeSection === modelData.index
                    implicitHeight: 34
                    implicitWidth: chipRow.implicitWidth + 28
                    buttonRadius: 8
                    toggled: selected
                    colBackground: "transparent"
                    colBackgroundToggled: Appearance.colors.colSecondaryContainer
                    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                    colRippleToggled: Appearance.colors.colSecondaryContainerActive
                    onClicked: root.scrollToSection(chip.modelData.index)

                    Rectangle {
                        anchors.fill: parent
                        radius: chip.buttonRadius
                        color: "transparent"
                        border.width: chip.selected ? 0 : 1
                        border.color: Appearance.colors.colOutlineVariant
                    }

                    contentItem: Item {
                        RowLayout {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialSymbol {
                                visible: chip.selected
                                text: "check"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnSecondaryContainer
                            }

                            StyledText {
                                text: chip.modelData.title
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium
                                color: chip.selected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurfaceVariant
                            }
                        }
                    }
                }
            }
        }
    }

    StyledFlickable {
        id: flick
        anchors.left: rail.right
        anchors.leftMargin: 16
        anchors.right: parent.right
        anchors.top: chipsRow.bottom
        anchors.topMargin: root.groupSections.length > 0 ? 8 : 0
        anchors.bottom: parent.bottom
        visible: !root.classicOpen
        clip: true
        contentWidth: width
        contentHeight: root.layoutResult.total
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: canvas
            width: flick.width
            height: root.layoutResult.total

            Repeater {
                model: root.allEntries

                delegate: Loader {
                    id: slot
                    required property int index
                    required property var modelData

                    readonly property var place: root.layoutMap[modelData.id] ?? null
                    property var lastPlace: null
                    property bool ready: false
                    readonly property var shown: place ?? lastPlace
                    readonly property real colW: (canvas.width - root.gap * 3) / 4
                    readonly property bool inView: place !== null && place.y + place.height > flick.contentY - 240 && place.y < flick.contentY + flick.height + 240
                    readonly property var control: modelData.kind === "card" ? catalog.controlFor(modelData) : null

                    onPlaceChanged: {
                        if (place)
                            lastPlace = place;
                    }
                    Component.onCompleted: Qt.callLater(() => {
                        ready = true;
                    })

                    x: shown ? shown.col * (colW + root.gap) : 0
                    y: shown ? shown.y : 0
                    width: shown ? shown.w * colW + (shown.w - 1) * root.gap : 0
                    height: shown ? shown.height : 0
                    opacity: place ? 1 : 0
                    scale: place ? 1 : 0.6
                    visible: opacity > 0.01

                    Behavior on x {
                        enabled: slot.ready
                        SpringAnimation { spring: 3.2; damping: 0.28 }
                    }
                    Behavior on y {
                        enabled: slot.ready
                        SpringAnimation { spring: 3.2; damping: 0.28 }
                    }
                    Behavior on width {
                        enabled: slot.ready
                        SpringAnimation { spring: 3.2; damping: 0.28 }
                    }
                    Behavior on height {
                        enabled: slot.ready
                        SpringAnimation { spring: 3.2; damping: 0.28 }
                    }
                    Behavior on opacity {
                        enabled: slot.ready
                        NumberAnimation { duration: 180 }
                    }
                    Behavior on scale {
                        enabled: slot.ready
                        SpringAnimation { spring: 3.2; damping: 0.3 }
                    }

                    active: place !== null && (modelData.kind === "header" || inView)
                    sourceComponent: modelData.kind === "header" ? headerComponent
                        : modelData.type === "style" ? styleComponent
                        : modelData.type === "visualstyle" ? visualStyleComponent
                        : modelData.type === "schemes" ? schemesComponent
                        : modelData.type === "barpos" ? barposComponent
                        : modelData.type === "toggle" ? toggleComponent
                        : modelData.type === "reset" ? resetComponent
                        : modelData.type === "action" ? actionComponent
                        : modelData.type === "page" ? pageComponent
                        : modelData.type === "slider" ? sliderComponent
                        : modelData.type === "spin" ? spinComponent
                        : modelData.type === "combo" ? comboComponent
                        : modelData.type === "text" ? textComponent
                        : modelData.type === "swatch" ? swatchComponent
                        : modelData.type === "shape" ? shapeComponent
                        : modelData.type === "barlayout" ? barLayoutComponent
                        : modelData.type === "palette" ? paletteComponent
                        : modelData.type === "duration" ? durationComponent
                        : modelData.type === "iconpicker" ? iconPickerComponent
                        : modelData.type === "timepreview" ? timePreviewComponent
                        : modelData.type === "collagelayouts" ? collageLayoutsComponent
                        : modelData.type === "weathermap" ? weatherMapComponent
                        : modelData.type === "webapps" ? webappsComponent
                        : modelData.type === "widgets" ? widgetsComponent
                        : selectComponent

                    Component {
                        id: headerComponent

                        RowLayout {
                            anchors.fill: parent
                            spacing: 10

                            Rectangle {
                                radius: height / 2
                                color: Appearance.colors.colPrimaryContainer
                                implicitHeight: 32
                                implicitWidth: headerChip.implicitWidth + 22

                                RowLayout {
                                    id: headerChip
                                    anchors.centerIn: parent
                                    spacing: 8

                                    MaterialSymbol {
                                        text: slot.modelData.icon
                                        iconSize: 18
                                        fill: 1
                                        color: Appearance.colors.colOnPrimaryContainer
                                    }
                                    StyledText {
                                        text: slot.modelData.title
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        font.weight: Font.DemiBold
                                        color: Appearance.colors.colOnPrimaryContainer
                                    }
                                }
                            }

                            StyledText {
                                text: slot.modelData.count
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 2
                                radius: 1
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: Appearance.colors.colPrimary }
                                    GradientStop { position: 0.35; color: Appearance.colors.colOutlineVariant }
                                    GradientStop { position: 1; color: "transparent" }
                                }
                            }

                            StyledText {
                                visible: slot.modelData.page !== ""
                                text: slot.modelData.page.toUpperCase()
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.Bold
                                font.letterSpacing: 1.5
                                color: Appearance.colors.colSubtext
                                opacity: 0.7
                            }
                        }
                    }

                    Component {
                        id: styleComponent
                        DashboardStyleCard {
                            anchors.fill: parent
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: visualStyleComponent
                        DashboardVisualStyleCard {
                            anchors.fill: parent
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: schemesComponent
                        DashboardSchemeCard {
                            anchors.fill: parent
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: barposComponent
                        DashboardBarPositionCard {
                            anchors.fill: parent
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: toggleComponent
                        DashboardToggleCard {
                            anchors.fill: parent
                            actionIcon: slot.modelData.action?.icon ?? ""
                            actionTip: slot.modelData.action?.tip ?? ""
                            onActionTriggered: root.openSection(slot.modelData.action.group, slot.modelData.action.section)
                            control: slot.control
                            title: slot.modelData.title
                            icon: slot.modelData.icon
                            tileShape: slot.modelData.shape
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: resetComponent
                        DashboardResetCard {
                            anchors.fill: parent
                            control: slot.control
                            title: slot.modelData.title
                            icon: slot.modelData.icon
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: actionComponent
                        DashboardActionCard {
                            anchors.fill: parent
                            control: slot.control
                            title: slot.modelData.title
                            icon: slot.modelData.icon
                            tileShape: slot.modelData.shape
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: pageComponent
                        DashboardPageCard {
                            anchors.fill: parent
                            title: slot.modelData.title
                            icon: slot.modelData.icon
                            subtitle: slot.modelData.subtitle ?? Translation.tr("More options")
                            tileShape: slot.modelData.shape
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                            onOpened: root.openClassic({
                                page: slot.modelData.pageId,
                                section: slot.modelData.pageSection ?? "",
                                subsection: slot.modelData.subsection ?? "",
                                label: slot.modelData.label ?? ""
                            })
                        }
                    }

                    Component {
                        id: sliderComponent
                        DashboardSliderCard {
                            anchors.fill: parent
                            control: slot.control
                            title: slot.modelData.title
                            icon: slot.modelData.icon
                            tileShape: slot.modelData.shape
                            showPercent: slot.modelData.percent !== false
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: spinComponent
                        DashboardSpinCard {
                            anchors.fill: parent
                            control: slot.control
                            title: slot.modelData.title
                            icon: slot.modelData.icon
                            tileShape: slot.modelData.shape
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: comboComponent
                        DashboardComboCard {
                            anchors.fill: parent
                            control: slot.control
                            title: slot.modelData.title
                            icon: slot.modelData.icon
                            tileShape: slot.modelData.shape
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: textComponent
                        DashboardTextCard {
                            anchors.fill: parent
                            placeholder: slot.modelData.placeholder ?? ""
                            control: slot.control
                            title: slot.modelData.title
                            icon: slot.modelData.icon
                            tileShape: slot.modelData.shape
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: widgetsComponent
                        DashboardWidgetsCard {
                            anchors.fill: parent
                            title: slot.modelData.title
                            icon: slot.modelData.icon
                            tileShape: slot.modelData.shape
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: timePreviewComponent
                        DashboardTimeCard {
                            anchors.fill: parent
                            title: slot.modelData.title
                            icon: slot.modelData.icon
                            tileShape: slot.modelData.shape
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: collageLayoutsComponent
                        DashboardCollageLayoutsCard {
                            anchors.fill: parent
                            title: slot.modelData.title
                            icon: slot.modelData.icon
                            tileShape: slot.modelData.shape
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: webappsComponent
                        DashboardWebappsCard {
                            anchors.fill: parent
                            title: slot.modelData.title
                            icon: slot.modelData.icon
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: weatherMapComponent
                        DashboardWeatherMapCard {
                            anchors.fill: parent
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: swatchComponent
                        DashboardSwatchCard {
                            anchors.fill: parent
                            control: slot.control
                            title: slot.modelData.title
                            icon: slot.modelData.icon
                            tileShape: slot.modelData.shape
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: shapeComponent
                        DashboardShapeCard {
                            anchors.fill: parent
                            control: slot.control
                            title: slot.modelData.title
                            icon: slot.modelData.icon
                            tileShape: slot.modelData.shape
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: barLayoutComponent
                        DashboardBarLayoutCard {
                            anchors.fill: parent
                            title: slot.modelData.title
                            icon: slot.modelData.icon
                            tileShape: slot.modelData.shape
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: paletteComponent
                        DashboardPaletteCard {
                            anchors.fill: parent
                            control: slot.control
                            title: slot.modelData.title
                            icon: slot.modelData.icon
                            tileShape: slot.modelData.shape
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: durationComponent
                        DashboardDurationCard {
                            anchors.fill: parent
                            control: slot.control
                            title: slot.modelData.title
                            icon: slot.modelData.icon
                            tileShape: slot.modelData.shape
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: iconPickerComponent
                        DashboardIconCard {
                            anchors.fill: parent
                            title: slot.modelData.title
                            icon: slot.modelData.icon
                            tileShape: slot.modelData.shape
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }

                    Component {
                        id: selectComponent
                        DashboardSelectCard {
                            anchors.fill: parent
                            control: slot.control
                            title: slot.modelData.title
                            icon: slot.modelData.icon
                            tileShape: slot.modelData.shape
                            pager: root.pager
                            staggerMs: root.staggerMs
                            animIndex: slot.index % 6
                            travelX: slot.modelData.travelX
                            travelY: slot.modelData.travelY
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: classicView
        anchors.left: rail.right
        anchors.leftMargin: 16
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        radius: Appearance.rounding.large
        color: Appearance.colors.colLayer1
        opacity: root.classicOpen ? 1 : 0
        scale: root.classicOpen ? 1 : 0.97
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            onWheel: wheel => wheel.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                RippleButton {
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: 20
                    colBackground: Appearance.colors.colLayer2
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    onClicked: root.closeClassic()
                    contentItem: Item {
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "arrow_back"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colOnLayer2
                        }
                    }
                    StyledToolTip {
                        text: Translation.tr("Back")
                    }
                }

                MaterialSymbol {
                    text: root.classicPage?.icon ?? "settings"
                    iconSize: Appearance.font.pixelSize.larger
                    fill: 1
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.classicTarget && root.classicTarget.section !== "" ? Translation.tr(root.classicTarget.section) : (root.classicPage?.name ?? "")
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                }

                StyledText {
                    visible: root.classicTarget !== null && root.classicTarget.section !== ""
                    text: (root.classicPage?.name ?? "").toUpperCase()
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    color: Appearance.colors.colSubtext
                    opacity: 0.7
                }
            }

            Loader {
                id: classicLoader
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                active: root.classicOpen
                source: root.classicPage?.component ?? ""
                onLoaded: root.jumpClassic()
            }
        }
    }
}

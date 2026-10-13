pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    readonly property string userPath: `${Directories.shellConfig}/keybinds.json`
    readonly property string defaultPath: Quickshell.shellPath("defaults/windows/keybinds.json")
    readonly property bool open: GlobalStates.keybindsEditorOpen

    property var doc: null
    property bool usingUserFile: false
    property string loadError: ""
    property string filter: ""
    property int editingIndex: -1
    property bool editCtrl: false
    property bool editAlt: false
    property bool editShift: false
    property bool editSuper: false
    property string editKey: ""
    property bool recording: false
    property bool resetArmed: false

    readonly property var modifierNames: ({
        "ctrl": "Ctrl",
        "control": "Ctrl",
        "alt": "Alt",
        "shift": "Shift",
        "super": "Super",
        "win": "Super",
        "meta": "Super",
        "mod4": "Super"
    })
    readonly property var keyLabels: ({
        "Super": Config.options.cheatsheet.superKey || "\ue8e5",
        "Slash": "/",
        "Period": ".",
        "Comma": ",",
        "Minus": "-",
        "Equal": "=",
        "Plus": "+",
        "Semicolon": ";",
        "Apostrophe": "'",
        "BracketLeft": "[",
        "BracketRight": "]",
        "Backslash": "\\",
        "Grave": "`",
        "Return": "Enter"
    })

    function exists(path) {
        return WindowsNative.fsUtils?.classify(path) === "file";
    }

    function load() {
        root.editingIndex = -1;
        root.recording = false;
        root.loadError = "";
        root.usingUserFile = root.exists(root.userPath);
        const reader = readerComponent.createObject(root, {
            "path": root.usingUserFile ? root.userPath : root.defaultPath
        });
        let parsed = null;
        try {
            parsed = JSON.parse(reader.text());
        } catch (e) {
            parsed = null;
        }
        reader.destroy();
        if (!parsed || !Array.isArray(parsed.binds)) {
            root.doc = null;
            root.loadError = Translation.tr("Your keybinds file has an error, so it can't be edited here. Fix it in the file or reset it to the defaults.");
        } else {
            root.doc = parsed;
        }
        root.rebuild();
    }

    function normalizeKeys(keys) {
        const mods = [];
        let key = "";
        for (const part of (keys ?? "").split("+")) {
            const token = part.trim();
            const mod = root.modifierNames[token.toLowerCase()];
            if (mod) {
                if (!mods.includes(mod)) mods.push(mod);
            } else {
                key = token.toLowerCase();
            }
        }
        mods.sort();
        return `${mods.join("+")}|${key}`;
    }

    function splitKeys(keys) {
        const parts = [];
        for (const part of (keys ?? "").split("+")) {
            const token = part.trim();
            const mod = root.modifierNames[token.toLowerCase()];
            parts.push(mod ?? token);
        }
        const order = ["Ctrl", "Super", "Shift", "Alt"];
        const mods = parts.filter(p => order.includes(p)).sort((a, b) => order.indexOf(a) - order.indexOf(b));
        return [...mods, ...parts.filter(p => !order.includes(p))];
    }

    function isLone(keys) {
        const parts = (keys ?? "").split("+").map(p => p.trim());
        return parts.length === 1 && root.modifierNames[parts[0].toLowerCase()] !== undefined;
    }

    function humanize(name) {
        const words = (name ?? "").replace(/([a-z0-9])([A-Z])/g, "$1 $2").toLowerCase();
        return words.charAt(0).toUpperCase() + words.slice(1);
    }

    function actionLabel(bind) {
        switch (bind.action) {
        case "global":
            return root.humanize(bind.name);
        case "dispatch":
            return bind.dispatch ?? "";
        case "exec":
            return bind.command ?? "";
        case "ipc":
            return `${bind.target ?? ""} ${bind.function ?? ""}`;
        case "key":
            return bind.key ?? "";
        default:
            return bind.action ?? "";
        }
    }

    function sourceOf(bind) {
        return (bind.disabled && typeof bind.disabled === "object") ? bind.disabled : bind;
    }

    function rebuild() {
        entryModel.clear();
        if (!root.doc) return;
        const binds = root.doc.binds;
        const counts = {};
        for (const bind of binds) {
            if (bind.disabled || bind.action === "native") continue;
            const id = `${root.normalizeKeys(bind.keys)}|${bind.onRelease ? 1 : 0}`;
            counts[id] = (counts[id] ?? 0) + 1;
        }
        const needle = root.filter.trim().toLowerCase();
        const otherSection = Translation.tr("Other");
        const sectionOrder = [];
        const grouped = {};
        for (let i = 0; i < binds.length; i++) {
            const bind = binds[i];
            const enabled = !(bind.disabled && typeof bind.disabled === "object");
            const source = root.sourceOf(bind);
            if (enabled && source.action === "native") continue;
            const description = source.description ?? "";
            const colon = description.indexOf(":");
            const section = colon > 0 ? description.slice(0, colon).trim() : otherSection;
            const label = colon > 0 ? description.slice(colon + 1).trim() : (description || root.actionLabel(source));
            const keys = source.keys ?? "";
            if (needle.length > 0 && !`${section} ${label} ${keys}`.toLowerCase().includes(needle)) continue;
            const id = `${root.normalizeKeys(keys)}|${source.onRelease ? 1 : 0}`;
            if (!grouped[section]) {
                grouped[section] = [];
                sectionOrder.push(section);
            }
            grouped[section].push({
                "bindIndex": i,
                "keys": keys,
                "bindEnabled": enabled,
                "section": section,
                "label": label,
                "lone": root.isLone(keys),
                "conflict": enabled && (counts[id] ?? 0) > 1
            });
        }
        const ordered = sectionOrder.filter(name => name !== otherSection);
        if (grouped[otherSection]) ordered.push(otherSection);
        for (const name of ordered) {
            for (const entry of grouped[name]) entryModel.append(entry);
        }
    }

    function serialize(document) {
        const names = Object.keys(document);
        const lines = ["{"];
        names.forEach((name, i) => {
            const comma = i < names.length - 1 ? "," : "";
            const value = document[name];
            if (Array.isArray(value)) {
                lines.push(`  ${JSON.stringify(name)}: [`);
                value.forEach((item, j) => lines.push(`    ${JSON.stringify(item)}${j < value.length - 1 ? "," : ""}`));
                lines.push(`  ]${comma}`);
            } else {
                lines.push(`  ${JSON.stringify(name)}: ${JSON.stringify(value)}${comma}`);
            }
        });
        lines.push("}");
        return lines.join("\n") + "\n";
    }

    function save(openAfter) {
        if (!root.doc) return;
        const writer = writerComponent.createObject(root, {
            "path": root.userPath,
            "openAfter": openAfter === true
        });
        writer.setText(root.serialize(root.doc));
        root.usingUserFile = true;
    }

    function commit() {
        root.rebuild();
        saveTimer.restart();
    }

    function setBindEnabled(index, enabled) {
        const binds = root.doc.binds;
        const bind = binds[index];
        if (enabled && bind.disabled && typeof bind.disabled === "object") {
            binds[index] = bind.disabled;
        } else if (!enabled && !(bind.disabled && typeof bind.disabled === "object")) {
            binds[index] = {
                "keys": bind.keys,
                "action": "native",
                "disabled": bind
            };
        }
        root.commit();
    }

    function startEdit(index) {
        const source = root.sourceOf(root.doc.binds[index]);
        const parts = root.splitKeys(source.keys);
        root.editCtrl = parts.includes("Ctrl");
        root.editAlt = parts.includes("Alt");
        root.editShift = parts.includes("Shift");
        root.editSuper = parts.includes("Super");
        root.editKey = parts.filter(p => !["Ctrl", "Alt", "Shift", "Super"].includes(p))[0] ?? "";
        root.recording = false;
        root.editingIndex = index;
    }

    function cancelEdit() {
        root.recording = false;
        root.editingIndex = -1;
    }

    function applyEdit() {
        if (root.editingIndex < 0 || root.editKey.length === 0) return;
        const parts = [];
        if (root.editCtrl) parts.push("Ctrl");
        if (root.editAlt) parts.push("Alt");
        if (root.editShift) parts.push("Shift");
        if (root.editSuper) parts.push("Super");
        parts.push(root.editKey);
        const keys = parts.join("+");
        const bind = root.doc.binds[root.editingIndex];
        if (bind.disabled && typeof bind.disabled === "object") {
            bind.disabled.keys = keys;
            bind.keys = keys;
        } else {
            bind.keys = keys;
        }
        root.editingIndex = -1;
        root.recording = false;
        root.commit();
    }

    function keyNameFromEvent(event) {
        const k = event.key;
        if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(k);
        if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k);
        if (k >= Qt.Key_F1 && k <= Qt.Key_F24) return `F${k - Qt.Key_F1 + 1}`;
        const named = {
            [Qt.Key_Space]: "Space",
            [Qt.Key_Return]: "Return",
            [Qt.Key_Enter]: "Return",
            [Qt.Key_Tab]: "Tab",
            [Qt.Key_Backspace]: "Backspace",
            [Qt.Key_Delete]: "Delete",
            [Qt.Key_Insert]: "Insert",
            [Qt.Key_Home]: "Home",
            [Qt.Key_End]: "End",
            [Qt.Key_PageUp]: "PageUp",
            [Qt.Key_PageDown]: "PageDown",
            [Qt.Key_Left]: "Left",
            [Qt.Key_Right]: "Right",
            [Qt.Key_Up]: "Up",
            [Qt.Key_Down]: "Down",
            [Qt.Key_Print]: "Print",
            [Qt.Key_Pause]: "Pause",
            [Qt.Key_Slash]: "Slash",
            [Qt.Key_Period]: "Period",
            [Qt.Key_Comma]: "Comma",
            [Qt.Key_Minus]: "Minus",
            [Qt.Key_Equal]: "Equal",
            [Qt.Key_Semicolon]: "Semicolon",
            [Qt.Key_Apostrophe]: "Apostrophe",
            [Qt.Key_BracketLeft]: "BracketLeft",
            [Qt.Key_BracketRight]: "BracketRight",
            [Qt.Key_Backslash]: "Backslash",
            [Qt.Key_QuoteLeft]: "Grave"
        };
        return named[k] ?? "";
    }

    function recordKey(event) {
        if ([Qt.Key_Control, Qt.Key_Shift, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R].includes(event.key)) return;
        if (event.key === Qt.Key_Escape) {
            root.recording = false;
            return;
        }
        const name = root.keyNameFromEvent(event);
        if (name.length === 0) return;
        if (event.modifiers & Qt.ControlModifier) root.editCtrl = true;
        if (event.modifiers & Qt.AltModifier) root.editAlt = true;
        if (event.modifiers & Qt.ShiftModifier) root.editShift = true;
        root.editKey = name;
        root.recording = false;
    }

    function resetToDefaults() {
        if (!root.resetArmed) {
            root.resetArmed = true;
            resetDisarmTimer.restart();
            return;
        }
        root.resetArmed = false;
        saveTimer.stop();
        if (root.exists(root.userPath))
            WindowsNative.fsUtils?.removeFile(root.userPath);
        root.load();
    }

    function openFile() {
        if (!root.exists(root.userPath)) {
            root.save(true);
            return;
        }
        saveTimer.stop();
        if (root.doc) root.save(true);
        else root.openFileNow();
    }

    function openFileNow() {
        if (!Qt.openUrlExternally(`file:///${root.userPath}`))
            Quickshell.execDetached(["notepad.exe", root.userPath.replace(/\//g, "\\")]);
    }

    onOpenChanged: if (root.open) root.load()
    onFilterChanged: root.rebuild()

    ListModel {
        id: entryModel
    }

    Component {
        id: readerComponent
        FileView {
            blockLoading: true
            printErrors: false
        }
    }

    Component {
        id: writerComponent
        FileView {
            property bool openAfter: false
            preload: false
            printErrors: false
            onSaved: {
                if (openAfter) root.openFileNow();
                destroy();
            }
            onSaveFailed: destroy()
        }
    }

    Timer {
        id: saveTimer
        interval: 400
        onTriggered: root.save(false)
    }

    Timer {
        id: resetDisarmTimer
        interval: 3000
        onTriggered: root.resetArmed = false
    }

    Loader {
        id: editorLoader
        active: root.open

        sourceComponent: PanelWindow {
            id: editorWindow
            visible: root.open
            exclusiveZone: 0
            implicitWidth: editorBackground.width + Appearance.sizes.elevationMargin * 2
            implicitHeight: editorBackground.height + Appearance.sizes.elevationMargin * 2
            WlrLayershell.namespace: "quickshell:keybindsEditor"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            mask: Region {
                item: editorBackground
            }

            function hide() {
                if (saveTimer.running) {
                    saveTimer.stop();
                    root.save(false);
                }
                GlobalStates.keybindsEditorOpen = false;
            }

            StyledRectangularShadow {
                target: editorBackground
            }

            Rectangle {
                id: editorBackground
                anchors.centerIn: parent
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                radius: Appearance.rounding.windowRounding
                implicitWidth: Math.min(820, (editorWindow.screen?.width ?? 1200) * 0.8)
                implicitHeight: Math.min(760, (editorWindow.screen?.height ?? 900) * 0.8)
                focus: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape && !root.recording) {
                        if (root.editingIndex >= 0) root.cancelEdit();
                        else editorWindow.hide();
                        event.accepted = true;
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        MaterialSymbol {
                            text: "keyboard"
                            iconSize: Appearance.font.pixelSize.huge
                            color: Appearance.colors.colOnLayer0
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText {
                                text: Translation.tr("Keybinds")
                                font.pixelSize: Appearance.font.pixelSize.title
                                color: Appearance.colors.colOnLayer0
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: Translation.tr("Turn a shortcut off to give it back to Windows. Changes apply right away.")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                                wrapMode: Text.Wrap
                            }
                        }

                        RippleButtonWithIcon {
                            materialIcon: "description"
                            mainText: Translation.tr("Open file")
                            onClicked: root.openFile()
                        }

                        RippleButtonWithIcon {
                            materialIcon: root.resetArmed ? "warning" : "restart_alt"
                            mainText: root.resetArmed ? Translation.tr("Click again to reset") : Translation.tr("Reset to defaults")
                            enabled: root.usingUserFile
                            onClicked: root.resetToDefaults()
                        }

                        RippleButton {
                            implicitWidth: 40
                            implicitHeight: 40
                            buttonRadius: Appearance.rounding.full
                            onClicked: editorWindow.hide()
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: Appearance.font.pixelSize.title
                                text: "close"
                            }
                        }
                    }

                    MaterialTextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("Search")
                        text: root.filter
                        onTextChanged: root.filter = text
                    }

                    Rectangle {
                        visible: root.loadError.length > 0
                        Layout.fillWidth: true
                        implicitHeight: errorText.implicitHeight + 24
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colErrorContainer
                        StyledText {
                            id: errorText
                            anchors.fill: parent
                            anchors.margins: 12
                            text: root.loadError
                            wrapMode: Text.Wrap
                            color: Appearance.colors.colOnErrorContainer
                        }
                    }

                    ListView {
                        id: bindList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 2
                        model: entryModel
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: StyledScrollBar {}

                        section.property: "section"
                        section.delegate: StyledText {
                            required property string section
                            width: bindList.width
                            topPadding: 12
                            bottomPadding: 4
                            text: section
                            font.pixelSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colPrimary
                        }

                        delegate: Rectangle {
                            id: row
                            required property int bindIndex
                            required property string keys
                            required property bool bindEnabled
                            required property string label
                            required property bool lone
                            required property bool conflict
                            readonly property bool editing: root.editingIndex === row.bindIndex

                            width: bindList.width - 12
                            implicitHeight: rowLayout.implicitHeight + 16
                            radius: Appearance.rounding.small
                            color: row.editing ? Appearance.colors.colLayer2 : (rowHover.hovered ? Appearance.colors.colLayer1 : "transparent")

                            HoverHandler {
                                id: rowHover
                            }

                            RowLayout {
                                id: rowLayout
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 10
                                    rightMargin: 6
                                }
                                spacing: 10

                                StyledText {
                                    Layout.fillWidth: true
                                    text: row.label
                                    elide: Text.ElideRight
                                    color: row.bindEnabled ? Appearance.colors.colOnLayer0 : Appearance.colors.colSubtext
                                }

                                Item {
                                    id: conflictIcon
                                    readonly property bool hovered: conflictHover.hovered
                                    visible: row.conflict && !row.editing
                                    implicitWidth: conflictSymbol.implicitWidth
                                    implicitHeight: conflictSymbol.implicitHeight

                                    HoverHandler {
                                        id: conflictHover
                                    }

                                    MaterialSymbol {
                                        id: conflictSymbol
                                        anchors.centerIn: parent
                                        text: "warning"
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: Appearance.colors.colError
                                    }

                                    StyledToolTip {
                                        extraVisibleCondition: conflictIcon.visible
                                        text: Translation.tr("Another shortcut uses the same keys")
                                    }
                                }

                                Row {
                                    visible: !row.editing
                                    spacing: 4
                                    opacity: row.bindEnabled ? 1 : 0.45
                                    Repeater {
                                        model: root.splitKeys(row.keys)
                                        delegate: KeyboardKey {
                                            required property var modelData
                                            key: root.keyLabels[modelData] ?? modelData
                                            pixelSize: Appearance.font.pixelSize.smaller
                                        }
                                    }
                                }

                                RowLayout {
                                    visible: row.editing
                                    spacing: 4

                                    Repeater {
                                        model: [
                                            {
                                                "name": "Ctrl",
                                                "label": "Ctrl"
                                            },
                                            {
                                                "name": "Alt",
                                                "label": "Alt"
                                            },
                                            {
                                                "name": "Shift",
                                                "label": "Shift"
                                            },
                                            {
                                                "name": "Super",
                                                "label": "Win"
                                            }
                                        ]
                                        delegate: GroupButton {
                                            required property var modelData
                                            Layout.fillWidth: false
                                            readonly property bool active: modelData.name === "Ctrl" ? root.editCtrl : modelData.name === "Alt" ? root.editAlt : modelData.name === "Shift" ? root.editShift : root.editSuper
                                            toggled: active
                                            buttonText: modelData.label
                                            horizontalPadding: 10
                                            verticalPadding: 4
                                            colBackground: Appearance.colors.colLayer1
                                            colBackgroundToggled: Appearance.colors.colPrimary
                                            onClicked: {
                                                if (modelData.name === "Ctrl") root.editCtrl = !root.editCtrl;
                                                else if (modelData.name === "Alt") root.editAlt = !root.editAlt;
                                                else if (modelData.name === "Shift") root.editShift = !root.editShift;
                                                else root.editSuper = !root.editSuper;
                                            }
                                        }
                                    }

                                    RippleButton {
                                        id: recorder
                                        implicitHeight: 32
                                        implicitWidth: Math.max(110, recorderText.implicitWidth + 24)
                                        buttonRadius: Appearance.rounding.small
                                        colBackground: root.recording ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1
                                        focus: root.recording && row.editing
                                        onClicked: {
                                            root.recording = true;
                                            recorder.forceActiveFocus();
                                        }
                                        Keys.onPressed: event => {
                                            if (!root.recording) return;
                                            root.recordKey(event);
                                            event.accepted = true;
                                        }
                                        contentItem: StyledText {
                                            id: recorderText
                                            anchors.centerIn: parent
                                            horizontalAlignment: Text.AlignHCenter
                                            text: root.recording ? Translation.tr("Press a key") : (root.editKey.length > 0 ? (root.keyLabels[root.editKey] ?? root.editKey) : Translation.tr("Pick a key"))
                                            color: root.recording ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                                        }
                                    }

                                    RippleButton {
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        buttonRadius: Appearance.rounding.full
                                        enabled: root.editKey.length > 0
                                        onClicked: root.applyEdit()
                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            horizontalAlignment: Text.AlignHCenter
                                            text: "check"
                                            iconSize: Appearance.font.pixelSize.larger
                                        }
                                        StyledToolTip {
                                            text: Translation.tr("Save")
                                        }
                                    }

                                    RippleButton {
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        buttonRadius: Appearance.rounding.full
                                        onClicked: root.cancelEdit()
                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            horizontalAlignment: Text.AlignHCenter
                                            text: "close"
                                            iconSize: Appearance.font.pixelSize.larger
                                        }
                                        StyledToolTip {
                                            text: Translation.tr("Cancel")
                                        }
                                    }
                                }

                                RippleButton {
                                    visible: !row.editing && !row.lone && row.bindEnabled
                                    implicitWidth: 32
                                    implicitHeight: 32
                                    buttonRadius: Appearance.rounding.full
                                    onClicked: root.startEdit(row.bindIndex)
                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "edit"
                                        iconSize: Appearance.font.pixelSize.larger
                                    }
                                    StyledToolTip {
                                        text: Translation.tr("Change keys")
                                    }
                                }

                                StyledSwitch {
                                    visible: !row.editing
                                    checked: row.bindEnabled
                                    onClicked: root.setBindEnabled(row.bindIndex, checked)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "keybindsEditor"

        function open(): void {
            GlobalStates.keybindsEditorOpen = true;
        }

        function close(): void {
            GlobalStates.keybindsEditorOpen = false;
        }

        function toggle(): void {
            GlobalStates.keybindsEditorOpen = !GlobalStates.keybindsEditorOpen;
        }
    }
}

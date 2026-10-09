import qs
import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool vertical: false
    property int currentIndex: 0
    property int totalCount: 0
    property bool paintBackground: true
    property string widgetName: ""
    property string morphEdge: ""
    property bool morphStartFlat: false
    property bool morphEndFlat: false
    readonly property alias box: background
    readonly property bool flatTL: (morphEdge === "top" || morphEdge === "left") && morphStartFlat
    readonly property bool flatTR: (morphEdge === "top" && morphEndFlat) || (morphEdge === "right" && morphStartFlat)
    readonly property bool flatBL: (morphEdge === "bottom" && morphStartFlat) || (morphEdge === "left" && morphEndFlat)
    readonly property bool flatBR: (morphEdge === "bottom" || morphEdge === "right") && morphEndFlat

    readonly property string borderlessMode: Config.options.bar.borderless ? "transparent" : "pills"
    readonly property bool styleEditable: root.paintBackground && root.widgetName !== ""
    property var stylePreview: ({})
    readonly property var style: {
        const entry = (Config.options.bar.widgetStyles ?? []).find(e => e.mode === root.borderlessMode && e.widget === root.widgetName);
        return Object.assign({}, entry ?? {}, root.stylePreview);
    }

    function previewStyle(key, value) {
        root.stylePreview = Object.assign({}, root.stylePreview, {
            [key]: value
        });
    }

    function commitPreview() {
        const preview = root.stylePreview;
        root.stylePreview = ({});
        for (const key in preview)
            root.setStyle(key, preview[key]);
    }

    readonly property bool rightClickFree: !["weatherBar", "bluetooth", "workspaces", "sysTray", "media"].includes(root.widgetName)

    readonly property Item loadedWidget: gridLayout.children[0]?.item ?? null
    readonly property bool hasContentOverride: root.style.color !== undefined && root.style.color !== "transparent"
    readonly property color contentColor: {
        const name = root.style.color ?? "";
        const special = {
            surfaceContainer: "onSurface",
            onError: "error",
            onLayer0: "layer0"
        };
        const onName = special[name] ?? `on${name.charAt(0).toUpperCase()}${name.slice(1)}`;
        return root.resolveColorName(onName) ?? Appearance.colors.colOnLayer1;
    }

    Binding {
        target: root.loadedWidget && "contentColor" in root.loadedWidget ? root.loadedWidget : null
        property: "contentColor"
        value: root.contentColor
        when: root.hasContentOverride
    }

    Binding {
        target: root.loadedWidget && "contentColorOverridden" in root.loadedWidget ? root.loadedWidget : null
        property: "contentColorOverridden"
        value: true
        when: root.hasContentOverride
    }

    Connections {
        target: root.loadedWidget
        ignoreUnknownSignals: true
        function onStyleEditorRequested() {
            root.toggleStyleEditor();
        }
    }

    function toggleStyleEditor() {
        if (!root.styleEditable)
            return;
        if (stylePopupLoader.item)
            stylePopupLoader.item.close();
        else
            stylePopupLoader.active = true;
    }

    function resolveColorName(name) {
        if (name === undefined)
            return undefined;
        if (name === "transparent")
            return "transparent";
        return Appearance.colors[`col${name.charAt(0).toUpperCase()}${name.slice(1)}`] ?? undefined;
    }

    function setStyle(key, value) {
        const styles = (Config.options.bar.widgetStyles ?? []).map(e => Object.assign({}, e));
        let entry = styles.find(e => e.mode === root.borderlessMode && e.widget === root.widgetName);
        if (!entry) {
            entry = {
                mode: root.borderlessMode,
                widget: root.widgetName
            };
            styles.push(entry);
        }
        if (value === undefined)
            delete entry[key];
        else
            entry[key] = value;
        Config.options.bar.widgetStyles = styles.filter(e => Object.keys(e).length > 2);
    }

    function resetStyle() {
        Config.options.bar.widgetStyles = (Config.options.bar.widgetStyles ?? []).filter(e => !(e.mode === root.borderlessMode && e.widget === root.widgetName));
    }

    readonly property color resolvedGroupColor: {
        const name = Config.options.bar.groupColor ?? "layer1";
        const key = `col${name.charAt(0).toUpperCase()}${name.slice(1)}`;
        return Appearance.colors[key] ?? Appearance.colors.colLayer1;
    }

    readonly property real currentRadius: background.topLeftRadius
    readonly property real currentBorderWidth: background.border.width

    property real padding: root.style.padding ?? 5

    readonly property real fullRadius: (root.vertical ? width : height) / 2
    readonly property real midRadius: Appearance.rounding.unsharpenmore
    readonly property real startRadius: (root.totalCount <= 1 || root.currentIndex === 0) ? root.fullRadius : root.midRadius
    readonly property real endRadius: (root.totalCount <= 1 || root.currentIndex === root.totalCount - 1) ? root.fullRadius : root.midRadius

    implicitWidth: root.vertical ? Appearance.sizes.baseVerticalBarWidth : (gridLayout.implicitWidth + root.padding * 2)
    implicitHeight: root.vertical ? (gridLayout.implicitHeight + root.padding * 2) : Appearance.sizes.baseBarHeight

    default property alias items: gridLayout.children

    Rectangle {
        id: background
        anchors {
            fill: parent
            topMargin: root.vertical ? 0 : 4
            bottomMargin: root.vertical ? 0 : 4
            leftMargin: root.vertical ? 4 : 0
            rightMargin: root.vertical ? 4 : 0
        }
        color: root.morphEdge !== "" ? Appearance.m3colors.m3surfaceContainer : !root.paintBackground ? "transparent" : root.resolveColorName(root.style.color) !== undefined ? root.resolveColorName(root.style.color) : Config.options.bar.borderless ? "transparent" : root.resolvedGroupColor

        border.width: root.morphEdge !== "" ? 0 : (root.style.borderWidth ?? 0)
        border.color: root.resolveColorName(root.style.borderColor) ?? Appearance.colors.colLayer0Border

        topLeftRadius: root.flatTL ? 0 : root.style.radius ?? root.startRadius
        bottomLeftRadius: root.flatBL ? 0 : root.style.radius ?? (root.vertical ? root.endRadius : root.startRadius)
        topRightRadius: root.flatTR ? 0 : root.style.radius ?? (root.vertical ? root.startRadius : root.endRadius)
        bottomRightRadius: root.flatBR ? 0 : root.style.radius ?? root.endRadius

        Behavior on color {
            enabled: root.morphEdge === ""
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    GridLayout {
        id: gridLayout
        columns: root.vertical ? 1 : -1
        anchors.centerIn: parent
        columnSpacing: 0
        rowSpacing: 0
    }

    Item {
        anchors.fill: parent
        z: 1
        TapHandler {
            enabled: root.styleEditable && root.rightClickFree
            acceptedButtons: Qt.RightButton
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: root.toggleStyleEditor()
            onLongPressed: root.toggleStyleEditor()
        }
    }

    Loader {
        id: stylePopupLoader
        active: false
        sourceComponent: BarGroupStylePopup {
            group: root
            onDismissed: stylePopupLoader.active = false
        }
    }
}

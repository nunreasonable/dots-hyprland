import QtQuick
import qs.modules.common

// Mainel's "PaneGroup": paints one pane rectangle behind every child of `target`,
// radius distributed by position - the four corners of the group's own silhouette
// (first/last row x first/last column) get `radiusOuter`, everything else gets
// `radiusInner`. `target` stays a normal Row/Grid/GridLayout that already places its
// children (a `Repeater` declared among them is fine - it is excluded automatically,
// along with anything else that isn't a plain sized Item); this only paints the
// backdrop, in reading order (row-major).
Item {
    id: root

    required property Item target
    property int rows: 1
    property int columns: Math.max(1, root.cells.length)
    property real radiusOuter: StyleTheme.surface.radiusOuter ?? 18
    property real radiusInner: StyleTheme.surface.radiusInner ?? 3
    property color fill: StyleTheme.surface.fill ?? Appearance.colors.colLayer1
    property var accentIndices: []
    property Gradient accentGradient: MainelTheme.jadeGradient
    property color accentColor: StyleTheme.palette.accent ?? Appearance.colors.colPrimary

    // `target.children` also lists a directly-declared `Repeater` once it has
    // instantiated delegates (it stays in the list, sized 0x0, alongside the
    // delegates it reparented onto `target`) - a plain `count`/`model` duck-type
    // check is enough to tell it apart from a real pane placeholder.
    readonly property var cells: {
        const list = [];
        if (root.target) {
            const kids = root.target.children;
            for (let i = 0; i < kids.length; ++i) {
                const kid = kids[i];
                if (kid && kid.count === undefined)
                    list.push(kid);
            }
        }
        return list;
    }

    x: root.target ? root.target.x : 0
    y: root.target ? root.target.y : 0
    width: root.target ? root.target.width : 0
    height: root.target ? root.target.height : 0
    z: -1

    Repeater {
        model: root.cells.length

        delegate: Rectangle {
            id: cell
            required property int index
            readonly property Item src: root.cells[cell.index]
            readonly property int cols: Math.max(1, root.columns)
            readonly property int rowCount: Math.max(1, root.rows)
            readonly property int row: Math.floor(cell.index / cell.cols)
            readonly property int col: cell.index % cell.cols
            readonly property bool accent: root.accentIndices.indexOf(cell.index) !== -1

            x: cell.src ? cell.src.x : 0
            y: cell.src ? cell.src.y : 0
            width: cell.src ? cell.src.width : 0
            height: cell.src ? cell.src.height : 0
            antialiasing: true

            color: cell.accent && !root.accentGradient ? root.accentColor : (cell.accent ? "transparent" : root.fill)
            gradient: cell.accent ? root.accentGradient : null

            topLeftRadius: (cell.row === 0 && cell.col === 0) ? root.radiusOuter : root.radiusInner
            topRightRadius: (cell.row === 0 && cell.col === cell.cols - 1) ? root.radiusOuter : root.radiusInner
            bottomLeftRadius: (cell.row === cell.rowCount - 1 && cell.col === 0) ? root.radiusOuter : root.radiusInner
            bottomRightRadius: (cell.row === cell.rowCount - 1 && cell.col === cell.cols - 1) ? root.radiusOuter : root.radiusInner

            Behavior on color {
                enabled: Appearance.animationsEnabled
                ColorAnimation { duration: 120 * Appearance.animationScale }
            }
        }
    }
}

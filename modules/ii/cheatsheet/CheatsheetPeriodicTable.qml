import "periodic_table.js" as PTable
import qs.modules.common
import QtQuick
import QtQuick.Controls

Item {
    id: root
    readonly property var elements: PTable.elements
    readonly property var series: PTable.series
    property real spacing: 6
    property real seriesGap: 20
    property bool loadAsync: false
    readonly property real tileSize: 70
    readonly property real cellStride: root.tileSize + root.spacing
    readonly property int columnCount: Math.max(0, ...root.elements.map(row => row.length), ...root.series.map(row => row.length))
    readonly property real seriesTop: root.elements.length * root.cellStride + root.seriesGap + root.spacing
    readonly property var tiles: {
        const result = [];
        const add = (rows, top) => rows.forEach((row, rowIndex) => row.forEach((element, columnIndex) => {
            if (element.type !== "empty")
                result.push({
                    element: element,
                    x: columnIndex * root.cellStride,
                    y: top + rowIndex * root.cellStride
                });
        }));
        add(root.elements, 0);
        add(root.series, root.seriesTop);
        return result;
    }
    implicitWidth: mainLayout.implicitWidth
    implicitHeight: mainLayout.implicitHeight

    Item {
        id: mainLayout
        anchors.centerIn: parent
        implicitWidth: root.columnCount * root.cellStride - root.spacing
        implicitHeight: (root.elements.length + root.series.length) * root.cellStride + root.seriesGap
        width: implicitWidth
        height: implicitHeight
        scale: Math.min(1, root.width / Math.max(1, mainLayout.implicitWidth), root.height / Math.max(1, mainLayout.implicitHeight))

        Loader {
            id: tilesLoader
            property bool wasLoaded: false
            anchors.fill: parent
            active: !Platform.isWindows || root.SwipeView.isCurrentItem || root.loadAsync || tilesLoader.wasLoaded
            asynchronous: root.loadAsync
            onLoaded: tilesLoader.wasLoaded = true

            sourceComponent: Item {
                Repeater {
                    model: root.tiles
                    delegate: ElementTile {
                        required property var modelData
                        element: modelData.element
                        x: modelData.x
                        y: modelData.y
                    }
                }
            }
        }
    }
}

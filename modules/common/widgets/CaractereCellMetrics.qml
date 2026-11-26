import QtQuick
import qs.modules.common

QtObject {
    id: root

    property string family: Appearance.font.family.main
    property int basePixelSize: 11

    property FontMetrics _fm: FontMetrics {
        font.family: root.family
        font.pixelSize: root.basePixelSize
    }

    readonly property real cellWidth: Math.max(1, Math.round(root._fm.advanceWidth("0")))
    readonly property real cellHeight: Math.max(1, Math.round(root._fm.height))

    function cols(px) {
        return Math.max(0, Math.round(px / root.cellWidth));
    }

    function rows(px) {
        return Math.max(0, Math.round(px / root.cellHeight));
    }

    function snapToCols(px) {
        return root.cols(px) * root.cellWidth;
    }

    function snapToRows(px) {
        return root.rows(px) * root.cellHeight;
    }
}

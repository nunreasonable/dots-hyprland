import QtQuick
import qs.services

QtObject {
    readonly property var multipleAllowed: BarLayouts.multipleAllowed

    readonly property var all: BarLayouts.supportedWidgets.map(w => ({ id: w.id, name: w.name, icon: w.icon }))

    function byId(id) {
        return all.find(w => w.id === id) ?? { id: id, name: BarLayouts.name(id), icon: "widgets" };
    }
}

import qs.modules.common
import qs.modules.common.widgets as W
import QtQuick
import QtQuick.Layouts

ContentSubsection {
    id: root

    property string sectionTitle
    property var layout: []
    property var getWidgetName: id => id
    property var availableWidgets: []
    signal layoutEdited(var list)
    signal widgetContextRequested(string widgetId)

    title: root.sectionTitle
    Layout.fillWidth: true
    Layout.leftMargin: 8
    Layout.topMargin: -4

    W.BarLayoutChips {
        Layout.fillWidth: true
        layout: root.layout
        getWidgetName: root.getWidgetName
        availableWidgets: root.availableWidgets
        onLayoutEdited: list => root.layoutEdited(list)
        onWidgetContextRequested: widgetId => root.widgetContextRequested(widgetId)
    }
}

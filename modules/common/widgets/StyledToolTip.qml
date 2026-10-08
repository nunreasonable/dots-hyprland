import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ToolTip {
    id: root
    property bool extraVisibleCondition: true
    property bool alternativeVisibleCondition: false

    readonly property bool internalVisibleCondition: (extraVisibleCondition && (parent.hovered === undefined || parent?.hovered)) || alternativeVisibleCondition
    verticalPadding: 5
    horizontalPadding: 10
    background: null
    font {
        family: Appearance.font.family.main
        variableAxes: Appearance.font.variableAxes.main
        pixelSize: Appearance?.font.pixelSize.smaller ?? 14
        hintingPreference: Font.PreferNoHinting // Prevent shaky text
    }

    delay: 0
    visible: internalVisibleCondition

    contentItem: null
    property Item styledContentItem: null
    property Component styledContentComponent: StyledToolTipContent {
        font: root.font
        text: root.text
        shown: false
        horizontalPadding: root.horizontalPadding
        verticalPadding: root.verticalPadding
        Component.onCompleted: shown = Qt.binding(() => root.internalVisibleCondition)
    }

    onAboutToShow: {
        if (root.styledContentItem)
            return;
        root.styledContentItem = root.styledContentComponent.createObject(root.parent);
        root.contentItem = root.styledContentItem;
    }
}

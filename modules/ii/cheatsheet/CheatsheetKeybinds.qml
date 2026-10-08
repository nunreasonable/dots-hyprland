pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    property real padding: 4
    property bool loadAsync: false
    implicitWidth: QsWindow?.window?.screen.width * 0.7 ?? 0
    implicitHeight: QsWindow?.window?.screen.height * 0.7 ?? 0

    Loader {
        id: contentLoader
        property bool wasLoaded: false
        anchors.fill: parent
        active: !Platform.isWindows || root.SwipeView.isCurrentItem || root.loadAsync || contentLoader.wasLoaded
        asynchronous: root.loadAsync
        onLoaded: contentLoader.wasLoaded = true

        sourceComponent: Item {
            StyledFlickable {
                id: flickable
                clip: true
                anchors.fill: parent
                anchors.margins: Appearance.rounding.small
                contentHeight: height
                contentWidth: flow.implicitWidth
                Flow {
                    id: flow
                    height: flickable.height
                    flow: Flow.TopToBottom
                    spacing: 10
                    Repeater {
                        model: [...HyprlandKeybinds.keybindCategories, ""]
                        delegate: CheatsheetKeybindsCategory {
                            required property var modelData
                            categoryName: modelData
                        }
                    }
                }
            }

            ScrollEdgeFade {
                target: flickable
                vertical: false
                color: Appearance.colors.colLayer0Base
            }
        }
    }
}

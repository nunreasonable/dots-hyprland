import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ListView {
    id: root
    required property var directory
    property var breadcrumbDirectory: ""
    Component.onCompleted: breadcrumbDirectory = directory;
    onDirectoryChanged: {
        if (breadcrumbDirectory.startsWith(directory)) return;
        breadcrumbDirectory = directory
    }

    signal navigateToDirectory(string path)

    orientation: ListView.Horizontal
    clip: true
    spacing: 2

    readonly property var parts: Platform.isWindows ? breadcrumbDirectory.split("/").filter((part, i) => i === 0 || part !== "") : breadcrumbDirectory.split("/")
    model: parts
    delegate: SelectionGroupButton {
        id: folderButton
        required property var modelData
        required property int index
        buttonText: index === 0 ? (Platform.isWindows ? `${modelData}\\` : "/") : modelData
        toggled: {
            if (Platform.isWindows) return index === directory.split("/").filter(part => part !== "").length - 1;
            if (directory.trim() === "/") return index === 0;
            return index === directory.split("/").length - 1
        }
        leftmost: index === 0
        rightmost: index === root.parts.length - 1

        onClicked: {
            root.navigateToDirectory(root.parts.slice(0, index + 1).join("/"))
        }
    }
}

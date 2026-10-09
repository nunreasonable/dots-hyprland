pragma Singleton

import QtQuick
import Quickshell
import qs.services

Singleton {
    id: root

    readonly property string pagesDir: "modules/settingsPc/pages/"
    readonly property list<string> ids: ["quick", "general", "bar", "desktop", "interface", "services", "about"]
    readonly property list<string> files: ["QuickConfig.qml", "GeneralConfig.qml", "BarConfig.qml", "BackgroundConfig.qml", "InterfaceConfig.qml", "ServicesConfig.qml", "About.qml"]
    readonly property list<url> sources: root.files.map(file => Qt.resolvedUrl("../" + root.pagesDir + file))
    property list<string> collapsedSections: []
    readonly property list<string> fontFamilies: Qt.fontFamilies().filter(name => !name.startsWith("@"))

    readonly property var pages: {
        const list = [
            { id: "quick",     name: Translation.tr("Quick"),     icon: "instant_mix",    file: "QuickConfig.qml" },
            { id: "general",   name: Translation.tr("General"),   icon: "browse",         file: "GeneralConfig.qml" },
            { id: "bar",       name: Translation.tr("Bar"),       icon: "toast",          iconRotation: 180, file: "BarConfig.qml" },
            { id: "desktop",   name: Translation.tr("Desktop"),   icon: "texture",        file: "BackgroundConfig.qml" },
            { id: "interface", name: Translation.tr("Interface"), icon: "bottom_app_bar", file: "InterfaceConfig.qml" },
            { id: "services",  name: Translation.tr("Services"),  icon: "settings",       file: "ServicesConfig.qml" },
            { id: "about",     name: Translation.tr("About"),     icon: "info",           file: "About.qml" },
        ];
        return list.map(page => Object.assign({}, page, {
            component: Qt.resolvedUrl("../" + root.pagesDir + page.file),
            path: root.pagesDir + page.file
        }));
    }

    function fontOptions(current) {
        const options = root.fontFamilies.map(name => ({ displayName: name, value: name }));
        if (current && !root.fontFamilies.includes(current))
            options.unshift({ displayName: current, value: current });
        return options;
    }

    function byId(id) {
        return root.pages.find(page => page.id === id) ?? null;
    }

    function indexOf(id) {
        return root.pages.findIndex(page => page.id === id);
    }
}

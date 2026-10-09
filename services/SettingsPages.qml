pragma Singleton

import QtQuick
import Quickshell
import qs.services

Singleton {
    id: root

    readonly property string pagesDir: "modules/settingsPc/pages/"
    readonly property list<string> ids: ["quick", "general", "bar", "desktop", "interface", "services", "profile", "about"]
    readonly property list<string> files: ["QuickConfig.qml", "GeneralConfig.qml", "BarConfig.qml", "BackgroundConfig.qml", "InterfaceConfig.qml", "ServicesConfig.qml", "Profile.qml", "About.qml"]
    readonly property list<url> sources: root.files.map(file => Qt.resolvedUrl("../" + root.pagesDir + file))
    readonly property var fontCache: ({
            families: null
        })

    readonly property var pages: {
        const list = [
            { id: "quick",     name: Translation.tr("Quick"),     icon: "instant_mix",    file: "QuickConfig.qml" },
            { id: "general",   name: Translation.tr("General"),   icon: "browse",         file: "GeneralConfig.qml" },
            { id: "bar",       name: Translation.tr("Bar"),       icon: "toast",          iconRotation: 180, file: "BarConfig.qml" },
            { id: "desktop",   name: Translation.tr("Desktop"),   icon: "texture",        file: "BackgroundConfig.qml" },
            { id: "interface", name: Translation.tr("Interface"), icon: "bottom_app_bar", file: "InterfaceConfig.qml" },
            { id: "services",  name: Translation.tr("Services"),  icon: "settings",       file: "ServicesConfig.qml" },
            { id: "profile",   name: Translation.tr("Profile"),   icon: "account_circle", file: "Profile.qml" },
            { id: "about",     name: Translation.tr("About"),     icon: "info",           file: "About.qml" },
        ];
        return list.map(page => Object.assign({}, page, {
            component: Qt.resolvedUrl("../" + root.pagesDir + page.file),
            path: root.pagesDir + page.file
        }));
    }

    function fontFamilies() {
        if (root.fontCache.families === null)
            root.fontCache.families = Qt.fontFamilies().filter(name => !name.startsWith("@"));
        return root.fontCache.families;
    }

    function fontOptions(current) {
        const families = root.fontFamilies();
        const options = families.map(name => ({ displayName: name, value: name }));
        if (current && !families.includes(current))
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

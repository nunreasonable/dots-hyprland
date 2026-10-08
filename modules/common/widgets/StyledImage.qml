import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Image {
    asynchronous: true
    retainWhileLoading: true
    visible: opacity > 0
    opacity: (status === Image.Ready) ? 1 : 0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }

    property list<string> fallbacks: []
    property int currentFallbackIndex: 0

    onStatusChanged: {
        if (status === Image.Error && currentFallbackIndex < fallbacks.length) {
            source = fallbacks[currentFallbackIndex];
            currentFallbackIndex += 1;
        }
    }

    sourceSize: {
        const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
        if (!Platform.isWindows)
            return Qt.size(width * dpr, height * dpr);
        const fromProvider = String(source).startsWith("image://");
        if (width <= 0 && height <= 0)
            return fromProvider ? Qt.size(0, 0) : Qt.size(128, 128);
        return fromProvider ? Qt.size(width, height) : Qt.size(width * dpr, height * dpr);
    }
}

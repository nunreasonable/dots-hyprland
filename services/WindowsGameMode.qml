pragma Singleton
import qs.modules.common
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property bool enabled: Config.options.windowsPort.gameMode.enable

    function toggle() {
        const gameMode = Config.options.windowsPort.gameMode;
        if (!gameMode.enable) {
            gameMode.prevTransparencyEnable = Config.options.appearance.transparency.enable;
            gameMode.prevTilingGapsIn = Config.options.windowsPort.tiling.gapsIn;
            gameMode.prevTilingGapsOut = Config.options.windowsPort.tiling.gapsOut;

            Config.options.appearance.transparency.enable = false;
            if (Config.options.windowsPort.tiling.enable) {
                Config.options.windowsPort.tiling.gapsIn = 0;
                Config.options.windowsPort.tiling.gapsOut = 0;
            }
            gameMode.enable = true;
        } else {
            Config.options.appearance.transparency.enable = gameMode.prevTransparencyEnable;
            Config.options.windowsPort.tiling.gapsIn = gameMode.prevTilingGapsIn;
            Config.options.windowsPort.tiling.gapsOut = gameMode.prevTilingGapsOut;
            gameMode.enable = false;
        }
    }
}

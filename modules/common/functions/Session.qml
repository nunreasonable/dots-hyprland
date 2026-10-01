pragma Singleton
import Quickshell
import qs.services
import qs.modules.common

Singleton {
    id: root

    function closeAllWindows() {
        HyprlandData.windowList.map(w => w.pid).forEach(pid => {
            Quickshell.execDetached(["kill", pid]);
        });
    }

    function changePassword() {
        if (Platform.isWindows) return; // apps.changePassword is a Linux terminal command
        Quickshell.execDetached(["bash", "-c", `${Config.options.apps.changePassword}`]);
    }

    function lock() {
        if (Platform.isWindows) {
            WindowsNative.session.lock();
            return;
        }
        Quickshell.execDetached(["loginctl", "lock-session"]);
    }

    function suspend() {
        if (Platform.isWindows) {
            WindowsNative.session.suspend();
            return;
        }
        Quickshell.execDetached(["bash", "-c", "systemctl suspend || loginctl suspend"]);
    }

    function logout() {
        closeAllWindows();
        if (Platform.isWindows) {
            WindowsNative.session.logout();
            return;
        }
        Quickshell.execDetached(["pkill", "-i", "Hyprland"]);
    }

    function launchTaskManager() {
        if (Platform.isWindows) return; // apps.taskManager is a Linux terminal command
        Quickshell.execDetached(["bash", "-c", `${Config.options.apps.taskManager}`]);
    }

    function hibernate() {
        if (Platform.isWindows) {
            WindowsNative.session.hibernate();
            return;
        }
        Quickshell.execDetached(["bash", "-c", `systemctl hibernate || loginctl hibernate`]);
    }

    function poweroff() {
        closeAllWindows();
        if (Platform.isWindows) {
            WindowsNative.session.shutdown();
            return;
        }
        Quickshell.execDetached(["bash", "-c", `systemctl poweroff || loginctl poweroff`]);
    }

    function reboot() {
        closeAllWindows();
        if (Platform.isWindows) {
            WindowsNative.session.reboot();
            return;
        }
        Quickshell.execDetached(["bash", "-c", `reboot || loginctl reboot`]);
    }

    function rebootToFirmware() {
        closeAllWindows();
        if (Platform.isWindows) {
            WindowsNative.session.rebootToFirmware();
            return;
        }
        Quickshell.execDetached(["bash", "-c", `systemctl reboot --firmware-setup || loginctl reboot --firmware-setup`]);
    }
}

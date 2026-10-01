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
            Quickshell.execDetached(["rundll32.exe", "user32.dll,LockWorkStation"]);
            return;
        }
        Quickshell.execDetached(["loginctl", "lock-session"]);
    }

    function suspend() {
        if (Platform.isWindows) {
            // Hibernates instead of sleeping if hibernation is enabled on the machine
            Quickshell.execDetached(["rundll32.exe", "powrprof.dll,SetSuspendState", "0,1,0"]);
            return;
        }
        Quickshell.execDetached(["bash", "-c", "systemctl suspend || loginctl suspend"]);
    }

    function logout() {
        closeAllWindows();
        if (Platform.isWindows) {
            Quickshell.execDetached(["shutdown", "/l"]);
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
            Quickshell.execDetached(["shutdown", "/h"]);
            return;
        }
        Quickshell.execDetached(["bash", "-c", `systemctl hibernate || loginctl hibernate`]);
    }

    function poweroff() {
        closeAllWindows();
        if (Platform.isWindows) {
            Quickshell.execDetached(["shutdown", "/s", "/t", "0"]);
            return;
        }
        Quickshell.execDetached(["bash", "-c", `systemctl poweroff || loginctl poweroff`]);
    }

    function reboot() {
        closeAllWindows();
        if (Platform.isWindows) {
            Quickshell.execDetached(["shutdown", "/r", "/t", "0"]);
            return;
        }
        Quickshell.execDetached(["bash", "-c", `reboot || loginctl reboot`]);
    }

    function rebootToFirmware() {
        closeAllWindows();
        if (Platform.isWindows) {
            Quickshell.execDetached(["shutdown", "/r", "/fw", "/t", "0"]);
            return;
        }
        Quickshell.execDetached(["bash", "-c", `systemctl reboot --firmware-setup || loginctl reboot --firmware-setup`]);
    }
}

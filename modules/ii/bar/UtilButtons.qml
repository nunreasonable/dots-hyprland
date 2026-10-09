import qs
import qs.services
import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Item {
    id: root
    property color contentColor: Appearance.colors.colOnLayer2
    property bool contentColorOverridden: false
    property bool borderless: Config.options.bar.borderless
    property bool classic: false
    property bool vertical: false
    readonly property bool recording: Platform.isWindows && ScreenshotAction.windowsNativeRecording
    property int recordingSeconds: 0

    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth - 14 : root.classic ? rowLayout.implicitWidth + rowLayout.columnSpacing * 2 : rowLayout.implicitWidth + 4
    implicitHeight: root.vertical ? rowLayout.implicitHeight + 4 : root.classic ? rowLayout.implicitHeight : Appearance.sizes.barHeight

    onRecordingChanged: root.recordingSeconds = 0

    Timer {
        interval: 1000
        repeat: true
        running: root.recording && !root.classic
        onTriggered: root.recordingSeconds++
    }

    GridLayout {
        id: rowLayout

        columns: root.vertical ? 1 : -1
        columnSpacing: 4
        rowSpacing: 4
        anchors.centerIn: parent

        Loader {
            active: Config.options.bar.utilButtons.showScreenSnip
            visible: Config.options.bar.utilButtons.showScreenSnip
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "screenshot"]);
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 1
                    text: "screenshot_region"
                    iconSize: Appearance.font.pixelSize.large
                    color: root.contentColor
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showScreenRecord
            visible: Config.options.bar.utilButtons.showScreenRecord
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: {
                    if (!Platform.isWindows) {
                        Quickshell.execDetached([Directories.recordScriptPath]);
                    } else if (ScreenshotAction.windowsNativeRecording) {
                        ScreenshotAction.stopWindowsRecording();
                    } else {
                        Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "record"]);
                    }
                }
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 1
                    text: ScreenshotAction.windowsNativeRecording ? "stop_circle" : "videocam"
                    iconSize: Appearance.font.pixelSize.large
                    color: root.contentColor
                }
            }
        }

        Revealer {
            reveal: root.recording && !root.classic && !root.vertical && !GlobalStates.dynamicIslandActive
            Layout.alignment: Qt.AlignVCenter
            StyledText {
                text: `${Math.floor(root.recordingSeconds / 60).toString().padStart(2, "0")}:${(root.recordingSeconds % 60).toString().padStart(2, "0")}`
                font.pixelSize: Appearance.font.pixelSize.small
                font.features: {
                    "tnum": 1
                }
                color: root.contentColor
                rightPadding: 4
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showColorPicker
            visible: Config.options.bar.utilButtons.showColorPicker
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: {
                    if (Platform.isWindows) {
                        GlobalStates.colorPickerOpen = true;
                        return;
                    }
                    Quickshell.execDetached(["hyprpicker", "-a"]);
                }
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 1
                    text: "colorize"
                    iconSize: Appearance.font.pixelSize.large
                    color: root.contentColor
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showKeyboardToggle
            visible: Config.options.bar.utilButtons.showKeyboardToggle
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: GlobalStates.oskOpen = !GlobalStates.oskOpen
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 0
                    text: "keyboard"
                    iconSize: Appearance.font.pixelSize.large
                    color: root.contentColor
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showWallpaperToggle
            visible: Config.options.bar.utilButtons.showWallpaperToggle
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: GlobalStates.wallpaperSelectorOpen = !GlobalStates.wallpaperSelectorOpen
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 0
                    text: "imagesmode"
                    iconSize: Appearance.font.pixelSize.large
                    color: root.contentColor
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showMicToggle
            visible: Config.options.bar.utilButtons.showMicToggle
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: Audio.toggleMicMute()
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 0
                    text: Pipewire.defaultAudioSource?.audio?.muted ? "mic_off" : "mic"
                    iconSize: Appearance.font.pixelSize.large
                    color: root.contentColor
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showDarkModeToggle
            visible: Config.options.bar.utilButtons.showDarkModeToggle
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: event => {
                    Wallpapers.setMode(!Appearance.m3colors.darkmode);
                }
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 0
                    text: Appearance.m3colors.darkmode ? "light_mode" : "dark_mode"
                    iconSize: Appearance.font.pixelSize.large
                    color: root.contentColor
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showPerformanceProfileToggle
            visible: Config.options.bar.utilButtons.showPerformanceProfileToggle
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: event => {
                    if (PowerProfiles.hasPerformanceProfile) {
                        switch(PowerProfiles.profile) {
                            case PowerProfile.PowerSaver: PowerProfiles.profile = PowerProfile.Balanced
                            break;
                            case PowerProfile.Balanced: PowerProfiles.profile = PowerProfile.Performance
                            break;
                            case PowerProfile.Performance: PowerProfiles.profile = PowerProfile.PowerSaver
                            break;
                        }
                    } else {
                        PowerProfiles.profile = PowerProfiles.profile == PowerProfile.Balanced ? PowerProfile.PowerSaver : PowerProfile.Balanced
                    }
                }
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 0
                    text: switch(PowerProfiles.profile) {
                        case PowerProfile.PowerSaver: return "energy_savings_leaf"
                        case PowerProfile.Balanced: return "airwave"
                        case PowerProfile.Performance: return "local_fire_department"
                    }
                    iconSize: Appearance.font.pixelSize.large
                    color: root.contentColor
                }
            }
        }
    }
}

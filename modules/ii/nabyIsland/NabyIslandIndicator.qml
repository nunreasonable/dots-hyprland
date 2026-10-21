import qs
import qs.services
import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.widgets
import QtQuick
import Quickshell

Item {
    id: root

    property string kind: ""
    property real recordingSince: 0
    property int textSize: 14

    signal activated

    readonly property bool recording: root.kind === "recording"
    readonly property bool live: root.visible && (QsWindow.window?.visible ?? false)
    readonly property bool running: {
        switch (root.kind) {
        case "recording":
            return true;
        case "pomodoro":
            return TimerService.pomodoroRunning;
        case "countdown":
            return TimerService.countdownRunning;
        case "stopwatch":
            return TimerService.stopwatchRunning;
        default:
            return false;
        }
    }
    property real now: Date.now()

    function format(seconds) {
        const total = Math.max(0, Math.floor(seconds));
        const hours = Math.floor(total / 3600);
        const minutes = Math.floor((total % 3600) / 60).toString().padStart(2, "0");
        const secs = (total % 60).toString().padStart(2, "0");
        return hours > 0 ? `${hours}:${minutes}:${secs}` : `${minutes}:${secs}`;
    }

    readonly property string text: {
        switch (root.kind) {
        case "recording":
            return root.format((root.now - root.recordingSince) / 1000);
        case "pomodoro":
            return root.format(TimerService.pomodoroSecondsLeft);
        case "countdown":
            return root.format(TimerService.countdownSecondsLeft);
        case "stopwatch":
            return root.format(TimerService.stopwatchTime / 100);
        default:
            return "";
        }
    }
    readonly property string icon: {
        switch (root.kind) {
        case "recording":
            return "stop_circle";
        case "pomodoro":
            return TimerService.pomodoroBreak ? "coffee" : "visibility";
        case "countdown":
            return "hourglass_top";
        default:
            return "timer";
        }
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Timer {
        running: root.recording && root.live
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = Date.now()
    }

    StopwatchConsumer {
        active: root.kind === "stopwatch" && root.live
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5

        MaterialSymbol {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            iconSize: root.textSize + 3
            fill: 1
            color: root.recording ? "#ff5c5c" : "#ffffff"
            opacity: root.running ? 1 : 0.5

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                visible: root.recording
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (Platform.isWindows)
                        ScreenshotAction.stopWindowsRecording();
                }
            }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: "#ffffff"
            opacity: root.running ? 1 : 0.6
            font.pixelSize: root.textSize
            font.weight: Font.DemiBold
            font.variableAxes: ({ "wght": 650 })
            font.features: ({ "tnum": 1 })
        }
    }

    MouseArea {
        anchors.fill: row
        anchors.margins: -6
        visible: !root.recording
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}

pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.utils
import QtQuick
import Quickshell

Item {
    id: root

    readonly property var modes: [
        { id: "pomodoro", name: Translation.tr("Pomodoro") },
        { id: "timer", name: Translation.tr("Timer") },
        { id: "stopwatch", name: Translation.tr("Stopwatch") },
    ]
    readonly property string mode: root.modes.some(m => m.id === Persistent.states.nabyIsland.focusMode) ? Persistent.states.nabyIsland.focusMode : "pomodoro"

    implicitHeight: modeRow.height + 12 + 196

    function twoDigits(n) {
        return Math.floor(n).toString().padStart(2, "0");
    }

    component PrimaryButton: NabyIslandButton {
        id: primaryButton
        property string label: ""
        width: Math.max(128, primaryLabel.implicitWidth + 36)
        height: 38
        highlighted: true

        StyledText {
            id: primaryLabel
            anchors.centerIn: parent
            text: primaryButton.label
            color: "#000000"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            font.variableAxes: ({ "wght": 600 })
        }
    }

    component RoundIconButton: NabyIslandButton {
        id: roundButton
        property string iconName: ""
        width: 38
        height: 38
        colNormal: Qt.rgba(1, 1, 1, 0.08)
        colHover: Qt.rgba(1, 1, 1, 0.16)

        MaterialSymbol {
            anchors.centerIn: parent
            text: roundButton.iconName
            iconSize: 20
            color: "#ffffff"
        }
    }

    component ChipButton: NabyIslandButton {
        id: chip
        property string label: ""
        width: chipLabel.implicitWidth + 24
        height: 28
        colNormal: Qt.rgba(1, 1, 1, 0.08)
        colHover: Qt.rgba(1, 1, 1, 0.16)

        StyledText {
            id: chipLabel
            anchors.centerIn: parent
            text: chip.label
            color: "#ffffff"
            font.pixelSize: 12
        }
    }

    component BigTime: StyledText {
        color: "#ffffff"
        font.pixelSize: 54
        font.weight: Font.DemiBold
        font.variableAxes: ({ "wght": 600 })
        font.features: ({ "tnum": 1 })
    }

    component ProgressLine: Rectangle {
        id: line
        property real progress: 0
        height: 3
        radius: 1.5
        color: Qt.rgba(1, 1, 1, 0.16)

        Rectangle {
            width: line.width * Math.max(0, Math.min(1, line.progress))
            height: parent.height
            radius: parent.radius
            color: "#ffffff"

            Behavior on width {
                NumberAnimation {
                    duration: 200
                }
            }
        }
    }

    NabyIslandSubTabs {
        id: modeRow
        anchors.horizontalCenter: parent.horizontalCenter
        model: root.modes
        current: root.mode
        onSelected: id => Persistent.states.nabyIsland.focusMode = id
    }

    Loader {
        id: modeLoader
        anchors.top: modeRow.bottom
        anchors.topMargin: 12
        width: parent.width
        height: 196
        sourceComponent: root.mode === "timer" ? timerView : root.mode === "stopwatch" ? stopwatchView : pomodoroView
    }

    Component {
        id: pomodoroView

        Item {
            id: pomodoroItem
            readonly property bool running: TimerService.pomodoroRunning
            readonly property bool fresh: !running && TimerService.pomodoroSecondsLeft >= TimerService.pomodoroLapDuration
            readonly property string phase: TimerService.pomodoroLongBreak ? Translation.tr("Long break") : TimerService.pomodoroBreak ? Translation.tr("Break") : Translation.tr("Focus")

            StyledText {
                id: phaseLabel
                x: 0
                y: 0
                text: pomodoroItem.phase
                color: "#ffffff"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.variableAxes: ({ "wght": 600 })
            }

            StyledText {
                anchors.right: parent.right
                anchors.verticalCenter: phaseLabel.verticalCenter
                text: Translation.tr("Cycle %1 of %2").arg(TimerService.pomodoroCycle + 1).arg(TimerService.cyclesBeforeLongBreak)
                color: "#ffffff"
                opacity: 0.55
                font.pixelSize: 12
            }

            BigTime {
                id: pomodoroTime
                anchors.horizontalCenter: parent.horizontalCenter
                y: 22
                text: TimerService.formatSeconds(TimerService.pomodoroSecondsLeft)
            }

            ProgressLine {
                id: pomodoroProgress
                anchors.top: pomodoroTime.bottom
                anchors.topMargin: 6
                width: parent.width
                progress: TimerService.pomodoroLapDuration > 0 ? 1 - TimerService.pomodoroSecondsLeft / TimerService.pomodoroLapDuration : 0
            }

            StyledText {
                anchors.top: pomodoroProgress.bottom
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                text: Translation.tr("%1 min focus · %2 min break").arg(Math.round(TimerService.focusTime / 60)).arg(Math.round(TimerService.breakTime / 60))
                color: "#ffffff"
                opacity: 0.55
                font.pixelSize: 12
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                spacing: 10

                PrimaryButton {
                    label: pomodoroItem.running ? Translation.tr("Pause") : !pomodoroItem.fresh ? Translation.tr("Continue") : TimerService.pomodoroBreak ? Translation.tr("Start break") : Translation.tr("Start focus")
                    onClicked: TimerService.togglePomodoro()
                }

                RoundIconButton {
                    iconName: "restart_alt"
                    enabled: !pomodoroItem.fresh || TimerService.pomodoroCycle > 0 || TimerService.pomodoroBreak
                    onClicked: TimerService.resetPomodoro()
                }
            }
        }
    }

    Component {
        id: timerView

        Item {
            id: timerItem
            readonly property bool running: TimerService.countdownRunning
            readonly property bool empty: TimerService.countdownDuration <= 0
            readonly property bool fresh: !running && TimerService.countdownSecondsLeft >= TimerService.countdownDuration

            StyledText {
                id: timerLabel
                x: 0
                y: 0
                text: Translation.tr("Timer")
                color: "#ffffff"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.variableAxes: ({ "wght": 600 })
            }

            StyledText {
                anchors.right: parent.right
                anchors.verticalCenter: timerLabel.verticalCenter
                text: timerItem.running ? Translation.tr("Running") : timerItem.empty ? Translation.tr("Ready") : timerItem.fresh ? Translation.tr("Ready") : Translation.tr("Paused")
                color: "#ffffff"
                opacity: 0.55
                font.pixelSize: 12
            }

            BigTime {
                id: countdownTime
                anchors.horizontalCenter: parent.horizontalCenter
                y: 22
                text: TimerService.formatSeconds(TimerService.countdownSecondsLeft)
            }

            ProgressLine {
                id: countdownProgress
                anchors.top: countdownTime.bottom
                anchors.topMargin: 6
                width: parent.width
                progress: TimerService.countdownDuration > 0 ? 1 - TimerService.countdownSecondsLeft / TimerService.countdownDuration : 0
            }

            Row {
                anchors.top: countdownProgress.bottom
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Repeater {
                    model: [1, 5, 10]

                    ChipButton {
                        required property int modelData
                        label: Translation.tr("+%1 min").arg(modelData)
                        onClicked: TimerService.addCountdownMinutes(modelData)
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                spacing: 10

                PrimaryButton {
                    label: timerItem.running ? Translation.tr("Pause") : !timerItem.fresh ? Translation.tr("Continue") : Translation.tr("Start timer")
                    enabled: !timerItem.empty
                    onClicked: TimerService.toggleCountdown()
                }

                RoundIconButton {
                    iconName: "restart_alt"
                    enabled: !timerItem.empty
                    onClicked: TimerService.resetCountdown()
                }
            }
        }
    }

    Component {
        id: stopwatchView

        Item {
            id: stopwatchItem
            readonly property bool running: TimerService.stopwatchRunning
            readonly property int time: TimerService.stopwatchTime
            readonly property var laps: TimerService.stopwatchLaps
            readonly property bool windowVisible: QsWindow.window?.visible ?? false

            StopwatchConsumer {
                active: stopwatchItem.visible && stopwatchItem.windowVisible
                centiseconds: true
            }

            Component.onCompleted: TimerService.refreshStopwatch()

            StyledText {
                id: stopwatchLabel
                x: 0
                y: 0
                text: Translation.tr("Stopwatch")
                color: "#ffffff"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.variableAxes: ({ "wght": 600 })
            }

            StyledText {
                anchors.right: parent.right
                anchors.verticalCenter: stopwatchLabel.verticalCenter
                visible: stopwatchItem.laps.length > 0
                text: Translation.tr("Lap %1 · %2").arg(stopwatchItem.laps.length).arg((() => {
                    const last = stopwatchItem.laps[stopwatchItem.laps.length - 1] ?? 0;
                    const previous = stopwatchItem.laps[stopwatchItem.laps.length - 2] ?? 0;
                    const lap = last - previous;
                    return `${root.twoDigits(lap / 6000)}:${root.twoDigits(lap / 100 % 60)}.${root.twoDigits(lap % 100)}`;
                })())
                color: "#ffffff"
                opacity: 0.55
                font.pixelSize: 12
            }

            Row {
                id: stopwatchTime
                anchors.horizontalCenter: parent.horizontalCenter
                y: 22

                BigTime {
                    id: stopwatchMain
                    text: `${root.twoDigits(stopwatchItem.time / 6000)}:${root.twoDigits(stopwatchItem.time / 100 % 60)}`
                }

                BigTime {
                    anchors.baseline: stopwatchMain.baseline
                    text: `.${root.twoDigits(stopwatchItem.time % 100)}`
                    font.pixelSize: 26
                    opacity: 0.55
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                spacing: 10

                PrimaryButton {
                    label: stopwatchItem.running ? Translation.tr("Pause") : stopwatchItem.time > 0 ? Translation.tr("Continue") : Translation.tr("Start stopwatch")
                    onClicked: TimerService.toggleStopwatch()
                }

                RoundIconButton {
                    iconName: "flag"
                    enabled: stopwatchItem.running
                    onClicked: TimerService.stopwatchRecordLap()
                }

                RoundIconButton {
                    iconName: "restart_alt"
                    enabled: stopwatchItem.time > 0 || stopwatchItem.running
                    onClicked: TimerService.stopwatchReset()
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "../sidebarRight/calendar/calendar_layout.js" as CalendarLayout
import QtQuick

Item {
    id: root

    property int monthShift: 0
    readonly property var viewingDate: CalendarLayout.getDateInXMonthsTime(root.monthShift)
    readonly property var calendarLayout: CalendarLayout.getCalendarLayout(root.viewingDate, root.monthShift === 0)
    property var selectedDate: new Date()
    readonly property bool eventsShown: CalendarEvents.available
    readonly property string timeFormat: Config.options?.time.format ?? "hh:mm"
    readonly property var eventMarkers: {
        CalendarEvents.revision;
        if (!CalendarEvents.available)
            return [];
        return CalendarEvents.dayMarkers(root.viewingDate.getFullYear(), root.viewingDate.getMonth() + 1);
    }
    readonly property var selectedDayEvents: {
        CalendarEvents.revision;
        if (!CalendarEvents.available)
            return [];
        return CalendarEvents.eventsForDay(root.selectedDate);
    }
    readonly property real cellWidth: Math.floor(root.width / 7)
    readonly property real cellHeight: 26

    implicitHeight: grid.y + grid.height + (root.eventsShown ? 10 + eventsColumn.implicitHeight : 0)

    Component.onCompleted: {
        if (CalendarEvents.available)
            CalendarEvents.markOpened();
    }

    function sameDay(a, b) {
        return a && b && a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    function cellDate(row, cell) {
        const shift = cell.today === -1 ? (row < 2 ? -1 : 1) : 0;
        return new Date(root.viewingDate.getFullYear(), root.viewingDate.getMonth() + shift, cell.day);
    }

    function dotColors(cell) {
        if (cell.today < 0 || !CalendarEvents.available)
            return [];
        const entry = root.eventMarkers.find(m => m.day === cell.day);
        if (!entry)
            return [];
        return entry.sourceIds.slice(0, 3).map(id => CalendarEvents.colorFor(id));
    }

    function selectCell(row, cell) {
        const date = root.cellDate(row, cell);
        if (cell.today === -1)
            root.monthShift += row < 2 ? -1 : 1;
        root.selectedDate = date;
    }

    function goToday() {
        root.monthShift = 0;
        root.selectedDate = new Date();
    }

    function eventTimeText(event) {
        if (event.allDay)
            return Translation.tr("All day");
        const start = Qt.locale().toString(event.start, root.timeFormat);
        const end = Qt.locale().toString(event.end, root.timeFormat);
        return start === end ? start : `${start} – ${end}`;
    }

    component SmallIconButton: NabyIslandButton {
        id: smallButton
        property string iconName: ""
        width: 30
        height: 30

        MaterialSymbol {
            anchors.centerIn: parent
            text: smallButton.iconName
            iconSize: 20
            color: "#ffffff"
        }
    }

    NabyIslandButton {
        id: monthButton
        x: -8
        y: 0
        height: 32
        width: monthLabel.implicitWidth + 16
        radius: 10
        onClicked: root.goToday()

        StyledText {
            id: monthLabel
            anchors.centerIn: parent
            text: root.viewingDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
            color: "#ffffff"
            font.pixelSize: 17
            font.weight: Font.DemiBold
            font.variableAxes: ({ "wght": 600 })
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: -6
        anchors.verticalCenter: monthButton.verticalCenter
        spacing: 2

        NabyIslandButton {
            visible: root.monthShift !== 0 || !root.sameDay(root.selectedDate, new Date())
            anchors.verticalCenter: parent.verticalCenter
            width: todayLabel.implicitWidth + 20
            height: 28
            radius: 10
            colNormal: Qt.rgba(1, 1, 1, 0.08)
            colHover: Qt.rgba(1, 1, 1, 0.16)
            onClicked: root.goToday()

            StyledText {
                id: todayLabel
                anchors.centerIn: parent
                text: Translation.tr("Today")
                color: "#ffffff"
                font.pixelSize: 12
            }
        }

        SmallIconButton {
            iconName: "chevron_left"
            onClicked: root.monthShift--
        }

        SmallIconButton {
            iconName: "chevron_right"
            onClicked: root.monthShift++
        }
    }

    Row {
        id: weekDays
        anchors.top: monthButton.bottom
        anchors.topMargin: 8
        x: (root.width - root.cellWidth * 7) / 2

        Repeater {
            model: 7

            StyledText {
                required property int index
                width: root.cellWidth
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale().dayName((index + 1) % 7, Locale.ShortFormat)
                color: "#ffffff"
                opacity: 0.5
                font.pixelSize: 11
            }
        }
    }

    Column {
        id: grid
        anchors.top: weekDays.bottom
        anchors.topMargin: 6
        x: weekDays.x

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                const step = event.angleDelta.y > 0 ? -1 : event.angleDelta.y < 0 ? 1 : 0;
                root.monthShift += step;
            }
        }

        Repeater {
            model: 6

            Row {
                id: weekRow
                required property int index

                Repeater {
                    model: 7

                    Item {
                        id: dayCell
                        required property int index
                        readonly property var cell: root.calendarLayout[weekRow.index][dayCell.index]
                        readonly property bool isToday: dayCell.cell.today === 1
                        readonly property bool isSelected: !dayCell.isToday && dayCell.cell.today === 0 && root.sameDay(root.selectedDate, root.cellDate(weekRow.index, dayCell.cell))
                        readonly property var dots: root.dotColors(dayCell.cell)
                        width: root.cellWidth
                        height: root.cellHeight

                        NabyIslandButton {
                            anchors.centerIn: parent
                            width: Math.min(parent.width - 6, 40)
                            height: parent.height - 2
                            radius: 9
                            highlighted: dayCell.isToday
                            colNormal: dayCell.isSelected ? Qt.rgba(1, 1, 1, 0.16) : "transparent"
                            onClicked: root.selectCell(weekRow.index, dayCell.cell)

                            StyledText {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: dayCell.dots.length > 0 ? -2 : 0
                                text: dayCell.cell.day
                                color: dayCell.isToday ? "#000000" : "#ffffff"
                                opacity: dayCell.cell.today === -1 ? 0.3 : 1
                                font.pixelSize: 12
                                font.weight: dayCell.isToday ? Font.DemiBold : Font.Normal
                            }

                            Row {
                                visible: dayCell.dots.length > 0
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                spacing: 2

                                Repeater {
                                    model: dayCell.dots

                                    Rectangle {
                                        required property color modelData
                                        width: 4
                                        height: 4
                                        radius: 2
                                        color: modelData
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Column {
        id: eventsColumn
        visible: root.eventsShown
        anchors.top: grid.bottom
        anchors.topMargin: 10
        width: parent.width
        spacing: 4

        StyledText {
            text: Qt.locale().toString(root.selectedDate, "dddd, d MMMM")
            color: "#ffffff"
            opacity: 0.6
            font.pixelSize: 12
        }

        StyledText {
            visible: root.selectedDayEvents.length === 0
            text: Translation.tr("No events")
            color: "#ffffff"
            opacity: 0.4
            font.pixelSize: 12
        }

        Repeater {
            model: root.selectedDayEvents.slice(0, 3)

            Item {
                id: eventRow
                required property var modelData
                width: eventsColumn.width
                height: 20

                Rectangle {
                    id: eventDot
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6
                    height: 6
                    radius: 3
                    color: CalendarEvents.colorFor(eventRow.modelData.sourceId)
                }

                StyledText {
                    anchors.left: eventDot.right
                    anchors.leftMargin: 8
                    anchors.right: eventTime.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: eventRow.modelData.title
                    color: "#ffffff"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                }

                StyledText {
                    id: eventTime
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.eventTimeText(eventRow.modelData)
                    color: "#ffffff"
                    opacity: 0.55
                    font.pixelSize: 11
                }
            }
        }

        StyledText {
            visible: root.selectedDayEvents.length > 3
            text: Translation.tr("+%1 more").arg(root.selectedDayEvents.length - 3)
            color: "#ffffff"
            opacity: 0.5
            font.pixelSize: 11
        }
    }
}

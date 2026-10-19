import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "calendar_layout.js" as CalendarLayout
import QtQuick
import QtQuick.Layouts

Item {
    // Layout.topMargin: 10
    anchors.topMargin: 10
    property int monthShift: 0
    property var viewingDate: CalendarLayout.getDateInXMonthsTime(monthShift)
    property var calendarLayout: CalendarLayout.getCalendarLayout(viewingDate, monthShift === 0)
    property var selectedDate: null
    readonly property bool agendaMode: CalendarEvents.available && selectedDate !== null
    readonly property real cellSize: 38
    readonly property real gridSpacing: 5
    readonly property real gridWidth: cellSize * 7 + gridSpacing * 6
    readonly property real gridHeight: cellSize * 7 + gridSpacing * 6
    readonly property string timeFormat: Config.options?.time.format ?? "hh:mm"
    property var eventMarkers: {
        const _r = CalendarEvents.revision;
        if (!CalendarEvents.available) return [];
        return CalendarEvents.dayMarkers(viewingDate.getFullYear(), viewingDate.getMonth() + 1);
    }
    property var selectedDayEvents: {
        const _r = CalendarEvents.revision;
        return selectedDate ? CalendarEvents.eventsForDay(selectedDate) : [];
    }
    width: calendarColumn.width
    implicitHeight: calendarColumn.height + 10 * 2

    function dotColorsFor(day, today) {
        if (today < 0 || !CalendarEvents.available) return [];
        const entry = eventMarkers.find(m => m.day === day);
        if (!entry) return [];
        return entry.sourceIds.slice(0, 3).map(id => CalendarEvents.colorFor(id));
    }

    function selectDay(day, today) {
        if (today < 0 || !CalendarEvents.available) return;
        selectedDate = new Date(viewingDate.getFullYear(), viewingDate.getMonth(), day);
    }

    function shiftDay(days) {
        const next = new Date(selectedDate.getFullYear(), selectedDate.getMonth(), selectedDate.getDate() + days);
        const now = new Date();
        monthShift = (next.getFullYear() - now.getFullYear()) * 12 + next.getMonth() - now.getMonth();
        selectedDate = next;
    }

    function eventTimeText(event) {
        if (event.allDay) return Translation.tr("All day");
        const start = Qt.locale().toString(event.start, timeFormat);
        const end = Qt.locale().toString(event.end, timeFormat);
        return start === end ? start : `${start} – ${end}`;
    }

    Component.onCompleted: {
        if (CalendarEvents.available) CalendarEvents.markOpened();
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape && agendaMode) {
            selectedDate = null;
            event.accepted = true;
        } else if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp)
            && event.modifiers === Qt.NoModifier) {
            const step = event.key === Qt.Key_PageDown ? 1 : -1;
            if (agendaMode) shiftDay(step);
            else monthShift += step;
            event.accepted = true;
        }
    }
    MouseArea {
        anchors.fill: parent
        onWheel: (event) => {
            const step = event.angleDelta.y > 0 ? -1 : event.angleDelta.y < 0 ? 1 : 0;
            if (step === 0) return;
            if (agendaMode) shiftDay(step);
            else monthShift += step;
        }
    }

    ColumnLayout {
        id: calendarColumn
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 5

        // Calendar header
        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            CalendarHeaderButton {
                clip: true
                buttonText: agendaMode
                    ? Qt.locale().toString(selectedDate, "dddd, d MMMM")
                    : `${monthShift != 0 ? "• " : ""}${viewingDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")}`
                tooltipText: agendaMode ? Translation.tr("Back to the month")
                    : (monthShift === 0) ? "" : Translation.tr("Jump to current month")
                downAction: () => {
                    if (agendaMode) selectedDate = null;
                    else monthShift = 0;
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: false
            }
            CalendarHeaderButton {
                forceCircle: true
                downAction: () => {
                    if (agendaMode) shiftDay(-1);
                    else monthShift--;
                }
                contentItem: MaterialSymbol {
                    text: "chevron_left"
                    iconSize: Appearance.font.pixelSize.larger
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer1
                }
            }
            CalendarHeaderButton {
                forceCircle: true
                downAction: () => {
                    if (agendaMode) shiftDay(1);
                    else monthShift++;
                }
                contentItem: MaterialSymbol {
                    text: "chevron_right"
                    iconSize: Appearance.font.pixelSize.larger
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        // Week days row
        RowLayout {
            id: weekDaysRow
            visible: !agendaMode
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: false
            spacing: 5
            Repeater {
                model: CalendarLayout.weekDays
                delegate: CalendarDayButton {
                    day: Translation.tr(modelData.day)
                    isToday: modelData.today
                    bold: true
                    enabled: false
                }
            }
        }

        // Real week rows
        Repeater {
            id: calendarRows
            // model: calendarLayout
            model: 6
            delegate: RowLayout {
                visible: !agendaMode
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: false
                spacing: 5
                Repeater {
                    model: Array(7).fill(modelData)
                    delegate: CalendarDayButton {
                        day: calendarLayout[modelData][index].day
                        isToday: calendarLayout[modelData][index].today
                        eventDotColors: dotColorsFor(calendarLayout[modelData][index].day, calendarLayout[modelData][index].today)
                        onClicked: selectDay(calendarLayout[modelData][index].day, calendarLayout[modelData][index].today)
                    }
                }
            }
        }

        Item {
            visible: agendaMode
            Layout.preferredWidth: gridWidth
            Layout.preferredHeight: gridHeight

            StyledText {
                anchors.centerIn: parent
                visible: selectedDayEvents.length === 0
                text: Translation.tr("No events")
                color: Appearance.colors.colSubtext
            }

            StyledListView {
                id: agendaList
                anchors.fill: parent
                clip: true
                spacing: 4
                model: agendaMode ? selectedDayEvents : []
                delegate: Rectangle {
                    required property var modelData
                    width: agendaList.width
                    implicitHeight: agendaRow.implicitHeight + 12
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer2

                    RowLayout {
                        id: agendaRow
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        Rectangle {
                            Layout.fillHeight: true
                            Layout.preferredWidth: 4
                            radius: 2
                            color: CalendarEvents.colorFor(modelData.sourceId)
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                color: Appearance.colors.colOnLayer2
                                text: modelData.title
                            }
                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                text: modelData.location
                                    ? `${eventTimeText(modelData)} · ${modelData.location}`
                                    : eventTimeText(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}

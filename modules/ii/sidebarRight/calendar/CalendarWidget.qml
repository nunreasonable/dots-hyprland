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
        if (today < 0) return;
        const clicked = new Date(viewingDate.getFullYear(), viewingDate.getMonth(), day);
        selectedDate = (selectedDate && selectedDate.getTime() === clicked.getTime()) ? null : clicked;
    }

    Component.onCompleted: {
        if (CalendarEvents.available) CalendarEvents.markOpened();
    }

    Keys.onPressed: (event) => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp)
            && event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageDown) {
                monthShift++;
            } else if (event.key === Qt.Key_PageUp) {
                monthShift--;
            }
            event.accepted = true;
        }
    }
    MouseArea {
        anchors.fill: parent
        onWheel: (event) => {
            if (event.angleDelta.y > 0) {
                monthShift--;
            } else if (event.angleDelta.y < 0) {
                monthShift++;
            }
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
                buttonText: `${monthShift != 0 ? "• " : ""}${viewingDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")}`
                tooltipText: (monthShift === 0) ? "" : Translation.tr("Jump to current month")
                downAction: () => {
                    monthShift = 0;
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: false
            }
            CalendarHeaderButton {
                forceCircle: true
                downAction: () => {
                    monthShift--;
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
                    monthShift++;
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
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: false
                spacing: 5
                Repeater {
                    model: Array(7).fill(modelData)
                    delegate: CalendarDayButton {
                        day: calendarLayout[modelData][index].day
                        isToday: calendarLayout[modelData][index].today
                        selected: selectedDate !== null
                            && calendarLayout[modelData][index].today >= 0
                            && selectedDate.getDate() === calendarLayout[modelData][index].day
                            && selectedDate.getMonth() === viewingDate.getMonth()
                            && selectedDate.getFullYear() === viewingDate.getFullYear()
                        eventDotColors: dotColorsFor(calendarLayout[modelData][index].day, calendarLayout[modelData][index].today)
                        onClicked: selectDay(calendarLayout[modelData][index].day, calendarLayout[modelData][index].today)
                    }
                }
            }
        }

        Column {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.maximumHeight: 90
            clip: true
            spacing: 2
            visible: CalendarEvents.available && selectedDate !== null

            StyledText {
                text: selectedDate ? Qt.locale().toString(selectedDate, "dddd, MMMM d") : ""
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
            }

            StyledText {
                visible: selectedDayEvents.length === 0
                text: Translation.tr("No events")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
            }

            Repeater {
                model: selectedDayEvents
                delegate: RowLayout {
                    required property var modelData
                    width: calendarColumn.width
                    spacing: 6

                    Rectangle {
                        Layout.preferredWidth: 6
                        Layout.preferredHeight: 6
                        radius: 3
                        color: CalendarEvents.colorFor(modelData.sourceId)
                    }
                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnLayer1
                        text: modelData.allDay
                            ? Translation.tr("All day · %1").arg(modelData.title)
                            : `${Qt.locale().toString(modelData.start, Config.options?.time.format ?? "hh:mm")} · ${modelData.title}`
                    }
                }
            }
        }
    }
}
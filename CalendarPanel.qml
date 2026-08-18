import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "scripts/lunar_converter.js" as LunarConverter
import "scripts/event_store.js" as EventStore

Item {
    id: panel
    implicitWidth: 420
    implicitHeight: 620

    // Shell injection
    property var shell
    property var manifest
    property var pluginRegistry

    // Navigation state
    property var currentDate: new Date()
    property int selectedDay: currentDate.getDate()
    property int displayedMonth: currentDate.getMonth() // 0-based
    property int displayedYear: currentDate.getFullYear()
    property real timeZoneOffset: 7.0 // UTC+7

    // User activities
    property var userEvents: []
    property var dayEvents: []

    // Current selected day details
    property var selectedLunarInfo: ({})
    property var selectedMoonInfo: ({})

    onSelectedDayChanged: {
        root.updateSelectedDayInfo();
        if (calendarGrid) calendarGrid.rebuildGrid();
    }

    function open(payloadJson) {
        currentDate = new Date();
        displayedMonth = currentDate.getMonth();
        displayedYear = currentDate.getFullYear();
        root.selectedDay = currentDate.getDate();
        updateSelectedDayInfo();
        calendarGrid.rebuildGrid();
        this.visible = true;
    }

    function close() {
        this.visible = false;
    }

    function updateSelectedDayInfo() {
        selectedLunarInfo = LunarConverter.convertSolarToLunar(root.selectedDay, displayedMonth + 1, displayedYear, timeZoneOffset);
        selectedMoonInfo = LunarConverter.getMoonPhase(root.selectedDay, displayedMonth + 1, displayedYear);
        dayEvents = EventStore.getEventsForDay(userEvents, root.selectedDay, displayedMonth + 1, displayedYear, selectedLunarInfo.lunarDay, selectedLunarInfo.lunarMonth);
    }

    function navigateMonth(delta) {
        var newMonth = displayedMonth + delta;
        var newYear = displayedYear;
        if (newMonth < 0) {
            newMonth = 11;
            newYear--;
        } else if (newMonth > 11) {
            newMonth = 0;
            newYear++;
        }
        displayedMonth = newMonth;
        displayedYear = newYear;

        // Clamp selected day if needed
        var maxDays = new Date(displayedYear, displayedMonth + 1, 0).getDate();
        if (root.selectedDay > maxDays) root.selectedDay = maxDays;

        updateSelectedDayInfo();
        calendarGrid.rebuildGrid();
    }

    function resetToToday() {
        currentDate = new Date();
        displayedMonth = currentDate.getMonth();
        displayedYear = currentDate.getFullYear();
        root.selectedDay = currentDate.getDate();
        updateSelectedDayInfo();
        calendarGrid.rebuildGrid();
    }

    function addActivity(title, isLunar, timeStr) {
        if (!title.trim()) return;
        var newEv = {
            id: "ev_" + Date.now(),
            title: title.trim(),
            type: isLunar ? "lunar" : "gregorian",
            day: isLunar ? selectedLunarInfo.lunarDay : root.selectedDay,
            month: isLunar ? selectedLunarInfo.lunarMonth : (displayedMonth + 1),
            year: isLunar ? null : displayedYear,
            notify: true,
            time: timeStr || "09:00"
        };
        var updated = userEvents.slice();
        updated.push(newEv);
        userEvents = updated;
        updateSelectedDayInfo();
        calendarGrid.rebuildGrid();
    }

    function deleteActivity(eventId) {
        var updated = userEvents.filter(function(e) { return e.id !== eventId; });
        userEvents = updated;
        updateSelectedDayInfo();
        calendarGrid.rebuildGrid();
    }

    Component.onCompleted: {
        updateSelectedDayInfo();
    }

    Rectangle {
        anchors.fill: parent
        color: "#0f172a"
        radius: 12
        border.color: "#1e293b"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // Panel Header & Navigation
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    text: "◄"
                    implicitWidth: 32
                    implicitHeight: 32
                    onClicked: panel.navigateMonth(-1)
                }

                Text {
                    id: monthYearHeader
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: {
                        var months = ["Tháng 1", "Tháng 2", "Tháng 3", "Tháng 4", "Tháng 5", "Tháng 6", "Tháng 7", "Tháng 8", "Tháng 9", "Tháng 10", "Tháng 11", "Tháng 12"];
                        return months[displayedMonth] + " " + displayedYear;
                    }
                    font.pixelSize: 17
                    font.bold: true
                    color: "#f8fafc"
                }

                Button {
                    text: "►"
                    implicitWidth: 32
                    implicitHeight: 32
                    onClicked: panel.navigateMonth(1)
                }

                Button {
                    text: "T"
                    implicitWidth: 32
                    implicitHeight: 32
                    ToolTip.visible: hovered
                    ToolTip.text: "Về Hôm Nay"
                    onClicked: panel.resetToToday()
                }
            }

            // Can Chi & Lunar Header Banner
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                color: "#1e293b"
                radius: 6

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        text: "Năm " + (selectedLunarInfo.canChiYear || "")
                        font.pixelSize: 12
                        font.bold: true
                        color: "#38bdf8"
                    }

                    Text { text: "•"; color: "#475569"; font.pixelSize: 10 }

                    Text {
                        text: "Tháng " + (selectedLunarInfo.canChiMonth || "")
                        font.pixelSize: 12
                        color: "#cbd5e1"
                    }

                    Text { text: "•"; color: "#475569"; font.pixelSize: 10 }

                    Text {
                        text: selectedLunarInfo.solarTerm || ""
                        font.pixelSize: 11
                        font.italic: true
                        color: "#fbbf24"
                    }
                }
            }

            // Weekday Column Titles
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font.pixelSize: 12
                        font.bold: true
                        color: index === 6 ? "#f43f5e" : "#64748b"
                    }
                }
            }

            // Month Grid
            GridLayout {
                id: calendarGrid
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 4
                columnSpacing: 4

                function rebuildGrid() {
                    gridModel.clear();
                    var firstDayIndex = new Date(displayedYear, displayedMonth, 1).getDay();
                    // Convert Sunday (0) to 6 for Mon-Sun layout
                    var offset = (firstDayIndex === 0) ? 6 : firstDayIndex - 1;
                    var totalDays = new Date(displayedYear, displayedMonth + 1, 0).getDate();

                    // Blank cells before first day
                    for (var b = 0; b < offset; b++) {
                        gridModel.append({ day: 0, isCurrentMonth: false, lunarDayText: "", isSelected: false, isToday: false, isSpecial: false });
                    }

                    var today = new Date();
                    for (var d = 1; d <= totalDays; d++) {
                        var lInfo = LunarConverter.convertSolarToLunar(d, displayedMonth + 1, displayedYear, timeZoneOffset);
                        var isTod = (d === today.getDate() && displayedMonth === today.getMonth() && displayedYear === today.getFullYear());
                        var isSel = (d === root.selectedDay);
                        var isSpec = (lInfo.lunarDay === 1 || lInfo.lunarDay === 15);
                        var dayEvents = EventStore.getEventsForDay([], d, displayedMonth + 1, displayedYear, lInfo.lunarDay, lInfo.lunarMonth);
                        var eventText = EventStore.getEventPreview(dayEvents);

                        var lText = lInfo.lunarDay === 1 ? (lInfo.lunarDay + "/" + lInfo.lunarMonth) : lInfo.lunarDay.toString();

                        gridModel.append({
                            day: d,
                            isCurrentMonth: true,
                            lunarDayText: lText,
                            eventText: eventText,
                            isSelected: isSel,
                            isToday: isTod,
                            isSpecial: isSpec
                        });
                    }
                }

                ListModel { id: gridModel }

                Repeater {
                    model: gridModel
                    delegate: Rectangle {
                        implicitWidth: 50
                        implicitHeight: 56
                        radius: 6
                        // Keep leading blank cells in the GridLayout so dates
                        // retain their correct weekday column. Invisible
                        // children are skipped by Qt positioners.
                        visible: true
                        color: model.isCurrentMonth
                            ? (model.isSelected ? "#2563eb" : (model.isToday ? "#1e3a8a" : (cellMouse.containsMouse ? "#334155" : "#1e293b")))
                            : "transparent"
                        border.color: model.isSpecial ? "#f59e0b" : "transparent"
                        border.width: model.isSpecial ? 1 : 0

                        Column {
                            anchors.centerIn: parent
                            spacing: 1

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.day ? modelData.day.toString() : ""
                                font.pixelSize: 13
                                font.bold: model.isToday || model.isSelected
                                color: model.isSelected ? "#ffffff" : (model.isToday ? "#60a5fa" : "#f1f5f9")
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: model.lunarDayText || ""
                                font.pixelSize: 9
                                font.bold: model.isSpecial
                                color: model.isSpecial ? "#fbbf24" : (model.isSelected ? "#93c5fd" : "#94a3b8")
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width - 4
                                text: model.eventText || ""
                                visible: Boolean(model.eventText)
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: 8
                                font.bold: true
                                color: model.isSelected ? "#fde68a" : "#f97316"
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: cellMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton
                            preventStealing: true
                        onPressed: {
                            if (modelData.day > 0) {
                                    root.selectedDay = modelData.day;
                                }
                            }
                        }
                    }
                }
            }

            // Selected Day Details Header
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                color: "#1e293b"
                radius: 8

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Text {
                        text: selectedMoonInfo.phaseIcon || "🌕"
                        font.pixelSize: 22
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: selectedDay + "/" + (displayedMonth + 1) + "/" + displayedYear + " — Âm Lịch: " + selectedLunarInfo.lunarDay + "/" + selectedLunarInfo.lunarMonth + "/" + selectedLunarInfo.lunarYear
                            font.pixelSize: 12
                            font.bold: true
                            color: "#f8fafc"
                        }

                        Text {
                            text: "Ngày " + (selectedLunarInfo.canChiDay || "") + " • Phase: " + (selectedMoonInfo.phaseName || "") + " (" + (selectedMoonInfo.illumination || 0) + "%)"
                            font.pixelSize: 10
                            color: "#94a3b8"
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: eventBanner.implicitHeight + 12
                color: dayEvents.length ? "#2b1b0f" : "#111827"
                radius: 8
                border.color: dayEvents.length ? "#f97316" : "#334155"
                border.width: 1

                Text {
                    id: eventBanner
                    anchors.fill: parent
                    anchors.margins: 6
                    text: dayEvents.length ? ("Sự kiện: " + EventStore.getEventSummary(dayEvents)) : "Không có sự kiện cho ngày này"
                    font.pixelSize: 11
                    font.bold: true
                    color: dayEvents.length ? "#fdba74" : "#94a3b8"
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // Activities / Events List
            Text {
                text: "Hoạt Động / Sự Kiện (" + dayEvents.length + ")"
                font.pixelSize: 13
                font.bold: true
                color: "#e2e8f0"
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: dayEvents

                delegate: Rectangle {
                    width: ListView.view.width
                    implicitHeight: 36
                    color: "#1e293b"
                    radius: 6

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        Rectangle {
                            implicitWidth: 8
                            implicitHeight: 8
                            radius: 4
                            color: modelData.type === "lunar" ? "#e11d48" : "#3b82f6"
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.title
                            font.pixelSize: 12
                            color: "#f1f5f9"
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.time || ""
                            font.pixelSize: 10
                            color: "#64748b"
                        }

                        Button {
                            text: "✕"
                            implicitWidth: 24
                            implicitHeight: 24
                            onClicked: panel.deleteActivity(modelData.id)
                        }
                    }
                }
            }

            // Add Activity Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                TextField {
                    id: newActivityInput
                    Layout.fillWidth: true
                    placeholderText: "Thêm hoạt động..."
                    font.pixelSize: 12
                }

                CheckBox {
                    id: lunarTypeCheck
                    text: "Âm lịch"
                    font.pixelSize: 11
                }

                Button {
                    text: "Thêm"
                    implicitHeight: 32
                    onClicked: {
                        panel.addActivity(newActivityInput.text, lunarTypeCheck.checked, "09:00");
                        newActivityInput.text = "";
                    }
                }
            }
        }
    }
}

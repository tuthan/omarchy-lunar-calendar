import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui
import "scripts/lunar_converter.js" as LunarConverter
import "scripts/event_store.js" as EventStore

Panel {
  id: panelRoot
  moduleName: "omarchy-lunar-calendar"
  ipcTarget: "omarchy-lunar-calendar"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || panelRoot

  property date today: new Date()
  property int selectedDay: today.getDate()
  property int viewYear: today.getFullYear()
  property int viewMonth: today.getMonth()
  property real timeZoneOffset: 7.0

  property var userEvents: []
  property var dayEvents: []
  property var selectedLunarInfo: ({})
  property var selectedMoonInfo: ({})

  onSelectedDayChanged: {
    panelRoot.updateSelectedDayInfo()
  }

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  function open() {
    refresh()
    panelRoot.controller.show()
  }

  function close() {
    panelRoot.controller.hide()
  }

  function toggle() {
    if (panelRoot.opened) panelRoot.close()
    else panelRoot.open()
  }

  function switchPanel(direction) {
    if (panelRoot.bar && typeof panelRoot.bar.switchPanelFrom === "function")
      return panelRoot.bar.switchPanelFrom(panelRoot.barIdentity, direction)
    return false
  }

  function refresh() {
    panelRoot.today = new Date()
    viewMonth = today.getMonth()
    viewYear = today.getFullYear()
    panelRoot.selectedDay = today.getDate()
    updateSelectedDayInfo()
  }

  function updateSelectedDayInfo() {
    selectedLunarInfo = LunarConverter.convertSolarToLunar(panelRoot.selectedDay, viewMonth + 1, viewYear, timeZoneOffset)
    selectedMoonInfo = LunarConverter.getMoonPhase(panelRoot.selectedDay, viewMonth + 1, viewYear)
    dayEvents = EventStore.getEventsForDay(userEvents, panelRoot.selectedDay, viewMonth + 1, viewYear, selectedLunarInfo.lunarDay, selectedLunarInfo.lunarMonth)
  }

  function moveMonth(delta) {
    var m = viewMonth + delta
    var y = viewYear
    if (m < 0) { m = 11; y-- }
    else if (m > 11) { m = 0; y++ }
    viewMonth = m
    viewYear = y
    var maxDays = new Date(viewYear, viewMonth + 1, 0).getDate()
    if (panelRoot.selectedDay > maxDays) panelRoot.selectedDay = maxDays
    updateSelectedDayInfo()
  }

  function goToToday() {
    today = new Date()
    viewMonth = today.getMonth()
    viewYear = today.getFullYear()
    panelRoot.selectedDay = today.getDate()
    updateSelectedDayInfo()
  }

  Component.onCompleted: updateSelectedDayInfo()

  KeyboardPanel {
    id: panel
    anchorItem: panelRoot.anchorItem
    owner: panelRoot.barIdentity
    bar: panelRoot.bar
    open: panelRoot.opened
    centerOnBar: false
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(440))
    contentHeight: panel.fittedContentHeight(calendarColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (dx !== 0) panelRoot.moveMonth(dx)
      }
      onActivateRequested: panelRoot.goToToday()
      onCloseRequested: panelRoot.close()
      onTabRequested: function(direction) { panelRoot.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "[") panelRoot.moveMonth(-1)
        else if (t === "]") panelRoot.moveMonth(1)
        else if (t === "t" || t === "T") panelRoot.goToToday()
      }

      Flickable {
        id: calendarScroll
        anchors.fill: parent
        contentWidth: calendarColumn.width
        contentHeight: calendarColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: calendarColumn
          width: Math.max(calendarScroll.width, 360)
          spacing: Style.space(8)

          // --- Hero Header ---
          Item {
            width: parent.width
            height: heroRow.height

            Row {
              id: heroRow
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: Style.space(16)

              Text {
                anchors.baseline: heroDate.baseline
                text: panelRoot.selectedMoonInfo.phaseIcon || "🌕"
                font.pixelSize: 36
              }

              Text {
                id: heroDate
                anchors.verticalCenter: parent.verticalCenter
                text: {
                  var months = ["Tháng 1", "Tháng 2", "Tháng 3", "Tháng 4", "Tháng 5", "Tháng 6", "Tháng 7", "Tháng 8", "Tháng 9", "Tháng 10", "Tháng 11", "Tháng 12"]
                  return months[panelRoot.viewMonth] + " " + panelRoot.viewYear
                }
                color: panelRoot.contentForeground
                font.family: panelRoot.contentFontFamily
                font.pixelSize: 28
                font.bold: true
              }
            }
          }

          // --- Can Chi & Solar Term ---
          Item {
            width: parent.width
            height: canChiRow.height + Style.space(8)

            Row {
              id: canChiRow
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: Style.space(10)

              Text {
                text: "Năm " + (panelRoot.selectedLunarInfo.canChiYear || "")
                font.family: panelRoot.contentFontFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: true
                color: Style.selectedStateColor(panelRoot.contentForeground, Color.accent)
              }
              Text { text: "·"; color: Qt.darker(panelRoot.contentForeground, 1.8); font.pixelSize: Style.font.bodySmall }
              Text {
                text: "Tháng " + (panelRoot.selectedLunarInfo.canChiMonth || "")
                font.family: panelRoot.contentFontFamily
                font.pixelSize: Style.font.bodySmall
                color: panelRoot.contentForeground
              }
              Text { text: "·"; color: Qt.darker(panelRoot.contentForeground, 1.8); font.pixelSize: Style.font.bodySmall }
              Text {
                text: panelRoot.selectedLunarInfo.solarTerm || ""
                font.family: panelRoot.contentFontFamily
                font.pixelSize: Style.font.caption
                font.italic: true
                color: "#fbbf24"
              }
            }
          }

          // --- Day-of-week header ---
          Row {
            spacing: Style.space(2)
            Repeater {
              model: ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
              Text {
                width: Math.floor((calendarColumn.width - Style.space(12)) / 7)
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                font.family: panelRoot.contentFontFamily
                font.pixelSize: Style.font.caption
                font.letterSpacing: 1
                font.bold: true
                color: index === 6 ? "#f43f5e" : Qt.darker(panelRoot.contentForeground, 1.5)
              }
            }
          }

          // --- Month Grid ---
          Grid {
            columns: 7
            rowSpacing: Style.space(3)
            columnSpacing: Style.space(2)

            Repeater {
              model: {
                var list = []
                var firstDay = new Date(panelRoot.viewYear, panelRoot.viewMonth, 1).getDay()
                var offset = (firstDay === 0) ? 6 : firstDay - 1
                var totalDays = new Date(panelRoot.viewYear, panelRoot.viewMonth + 1, 0).getDate()

                for (var b = 0; b < offset; b++) {
                  list.push({ day: 0, inMonth: false, lunarText: "", isSel: false, isTod: false, isSpec: false })
                }
                for (var d = 1; d <= totalDays; d++) {
                  var lInfo = LunarConverter.convertSolarToLunar(d, panelRoot.viewMonth + 1, panelRoot.viewYear, panelRoot.timeZoneOffset)
                  var isTod = (d === panelRoot.today.getDate() && panelRoot.viewMonth === panelRoot.today.getMonth() && panelRoot.viewYear === panelRoot.today.getFullYear())
                  var isSel = (d === panelRoot.selectedDay)
                  var isSpec = (lInfo.lunarDay === 1 || lInfo.lunarDay === 15)
                  var dayEvents = EventStore.getEventsForDay([], d, panelRoot.viewMonth + 1, panelRoot.viewYear, lInfo.lunarDay, lInfo.lunarMonth)
                  var eventText = EventStore.getEventPreview(dayEvents)
                  var lText = lInfo.lunarDay === 1 ? (lInfo.lunarDay + "/" + lInfo.lunarMonth) : String(lInfo.lunarDay)
                  list.push({ day: d, inMonth: true, lunarText: lText, eventText: eventText, isSel: isSel, isTod: isTod, isSpec: isSpec })
                }
                return list
              }

              delegate: Rectangle {
                width: Math.floor((calendarColumn.width - Style.space(12)) / 7)
                height: Style.space(54)
                radius: Style.cornerRadius
                visible: modelData.inMonth
                color: modelData.isSel
                  ? Style.selectedStateColor(panelRoot.contentForeground, Color.accent)
                  : (gridMouse.containsMouse
                    ? Style.hoverFillFor(panelRoot.contentForeground, Color.accent)
                    : "transparent")
                border.width: modelData.isTod ? Style.spacing.hairline : (modelData.isSpec ? 1 : 0)
                border.color: modelData.isTod
                  ? Style.normalBorderFor(panelRoot.contentForeground, Color.accent)
                  : (modelData.isSpec ? "#f59e0b" : "transparent")

                Column {
                  anchors.centerIn: parent
                  spacing: 1

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.day > 0 ? String(modelData.day) : ""
                    font.family: panelRoot.contentFontFamily
                    font.pixelSize: Style.font.body
                    font.bold: Boolean(modelData.isTod || modelData.isSel)
                    color: modelData.isSel ? Color.popups.background : panelRoot.contentForeground
                  }

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.lunarText || ""
                    font.family: panelRoot.contentFontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: Boolean(modelData.isSpec)
                    color: modelData.isSpec ? "#fbbf24" : Qt.darker(panelRoot.contentForeground, 1.5)
                  }

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - Style.space(4)
                    text: modelData.eventText || ""
                    visible: Boolean(modelData.eventText)
                    horizontalAlignment: Text.AlignHCenter
                    font.family: panelRoot.contentFontFamily
                    font.pixelSize: 8
                    font.bold: true
                    color: modelData.isSel ? "#fde68a" : "#f97316"
                    elide: Text.ElideRight
                  }
                }

                MouseArea {
                  id: gridMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  acceptedButtons: Qt.LeftButton
                  preventStealing: true
                  onPressed: {
                    if (modelData.day > 0) {
                      panelRoot.selectedDay = modelData.day
                    }
                  }
                }
              }
            }
          }

          // --- Month Nav ---
          Item {
            width: parent.width
            height: monthNav.height

            Item {
              id: monthNav
              anchors.horizontalCenter: parent.horizontalCenter
              width: calendarColumn.width
              height: monthLabel.implicitHeight + Style.space(10)

              Text {
                id: monthLabel
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: Style.space(200)
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDate(new Date(panelRoot.viewYear, panelRoot.viewMonth, 1), "MMMM yyyy").toUpperCase()
                color: Qt.darker(panelRoot.contentForeground, 1.4)
                font.family: panelRoot.contentFontFamily
                font.pixelSize: Style.font.body
                font.letterSpacing: 1
              }

              PanelActionButton {
                anchors.left: parent.left
                anchors.leftMargin: -Style.space(8)
                anchors.verticalCenter: parent.verticalCenter
                iconText: "󰅁"
                tooltipText: "Tháng trước"
                foreground: panelRoot.contentForeground
                fontFamily: panelRoot.contentFontFamily
                onClicked: panelRoot.moveMonth(-1)
              }

              PanelActionButton {
                anchors.right: parent.right
                anchors.rightMargin: -Style.space(8)
                anchors.verticalCenter: parent.verticalCenter
                iconText: "󰅂"
                tooltipText: "Tháng sau"
                foreground: panelRoot.contentForeground
                fontFamily: panelRoot.contentFontFamily
                onClicked: panelRoot.moveMonth(1)
              }
            }
          }

          PanelSeparator { foreground: panelRoot.contentForeground }

          // --- Selected Day Details ---
          Item {
            width: parent.width
            height: detailRow.height

            Row {
              id: detailRow
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: Style.space(10)

              Text {
                text: panelRoot.selectedMoonInfo.phaseIcon || "🌕"
                font.pixelSize: 22
                anchors.verticalCenter: parent.verticalCenter
              }

              Column {
                spacing: 2

                Text {
                  text: panelRoot.selectedDay + "/" + (panelRoot.viewMonth + 1) + "/" + panelRoot.viewYear + " — Âm: " + panelRoot.selectedLunarInfo.lunarDay + "/" + panelRoot.selectedLunarInfo.lunarMonth + "/" + panelRoot.selectedLunarInfo.lunarYear
                  font.family: panelRoot.contentFontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                  color: panelRoot.contentForeground
                }

                Text {
                  text: "Ngày " + (panelRoot.selectedLunarInfo.canChiDay || "") + " · " + (panelRoot.selectedMoonInfo.phaseName || "") + " (" + (panelRoot.selectedMoonInfo.illumination || 0) + "%)"
                  font.family: panelRoot.contentFontFamily
                  font.pixelSize: Style.font.caption
                  color: Qt.darker(panelRoot.contentForeground, 1.4)
                }
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: eventBannerText.implicitHeight + Style.space(12)
            radius: Style.cornerRadius
            color: panelRoot.dayEvents.length ? "#2b1b0f" : "#111827"
            border.color: panelRoot.dayEvents.length ? "#f97316" : "#334155"
            border.width: 1

            Text {
              id: eventBannerText
              anchors.fill: parent
              anchors.margins: Style.space(6)
              verticalAlignment: Text.AlignVCenter
              horizontalAlignment: Text.AlignLeft
              wrapMode: Text.WordWrap
              font.family: panelRoot.contentFontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
              color: panelRoot.dayEvents.length ? "#fdba74" : "#94a3b8"
              text: panelRoot.dayEvents.length ? ("Sự kiện: " + EventStore.getEventSummary(panelRoot.dayEvents)) : "Không có sự kiện cho ngày này"
            }
          }

          // --- Activities Section ---
          PanelSectionHeader {
            text: "SỰ KIỆN (" + panelRoot.dayEvents.length + ")"
            foreground: panelRoot.contentForeground
            fontFamily: panelRoot.contentFontFamily
          }

          Column {
            width: parent.width
            spacing: Style.space(4)

            Repeater {
              model: panelRoot.dayEvents
              delegate: CursorSurface {
                width: parent.width
                implicitHeight: Style.space(36)
                foreground: panelRoot.contentForeground

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: Style.spacing.rowPaddingX
                  anchors.rightMargin: Style.spacing.rowPaddingX
                  spacing: Style.space(8)

                  Rectangle {
                    width: 8; height: 8; radius: 4
                    color: modelData.type === "lunar" ? "#e11d48" : "#3b82f6"
                  }

                  Text {
                    Layout.fillWidth: true
                    text: modelData.title
                    font.family: panelRoot.contentFontFamily
                    font.pixelSize: Style.font.bodySmall
                    color: panelRoot.contentForeground
                    elide: Text.ElideRight
                  }

                  Text {
                    text: modelData.time || ""
                    font.family: panelRoot.contentFontFamily
                    font.pixelSize: Style.font.caption
                    color: Qt.darker(panelRoot.contentForeground, 1.5)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

.pragma library

/**
 * Event & Activity Storage Manager for Omarchy Lunar Calendar Plugin
 * Handles local event persistence and alarm trigger calculations for both
 * Gregorian dates and recurring Lunar dates (e.g., Mùng 1, Rằm, Tết).
 */

var DEFAULT_LUNAR_HOLIDAYS = [
  { id: "tet", title: "Tết Nguyên Đán (Mùng 1)", type: "lunar", day: 1, month: 1, category: "holiday", notify: true, time: "08:00" },
  { id: "tet2", title: "Tết Nguyên Đán (Mùng 2)", type: "lunar", day: 2, month: 1, category: "holiday", notify: false, time: "08:00" },
  { id: "tet3", title: "Tết Nguyên Đán (Mùng 3)", type: "lunar", day: 3, month: 1, category: "holiday", notify: false, time: "08:00" },
  { id: "tetthieunhi", title: "Tết Trung Thu (Rằm tháng 8)", type: "lunar", day: 15, month: 8, category: "holiday", notify: true, time: "09:00" },
  { id: "vulan", title: "Lễ Vu Lan (Rằm tháng 7)", type: "lunar", day: 15, month: 7, category: "holiday", notify: true, time: "09:00" },
  { id: "thanggiang", title: "Tết Nguyên Tiêu (Rằm tháng 1)", type: "lunar", day: 15, month: 1, category: "holiday", notify: true, time: "09:00" },
  { id: "doango", title: "Tết Đoan Ngọ (mùng 5 tháng 5)", type: "lunar", day: 5, month: 5, category: "holiday", notify: true, time: "08:00" }
];

function getEventsForDay(eventsList, solarDay, solarMonth, solarYear, lunarDay, lunarMonth) {
  if (!eventsList) eventsList = [];
  var results = [];

  var allEvents = DEFAULT_LUNAR_HOLIDAYS.concat(eventsList);

  for (var i = 0; i < allEvents.length; i++) {
    var ev = allEvents[i];
    if (ev.type === "gregorian") {
      if (ev.day === solarDay && ev.month === solarMonth && (!ev.year || ev.year === solarYear)) {
        results.push(ev);
      }
    } else if (ev.type === "lunar") {
      if (ev.day === lunarDay && ev.month === lunarMonth) {
        results.push(ev);
      }
    } else if (ev.type === "lunar_monthly") {
      if (ev.day === lunarDay) {
        results.push(ev);
      }
    }
  }

  return results;
}

function getDisplayTitle(title) {
  if (!title) return "";
  return String(title).replace(/\s*\([^)]*\)\s*$/, "").trim();
}

function getPrimaryEvent(eventsList) {
  if (!eventsList || !eventsList.length) return null;

  var fallback = eventsList[0];
  for (var i = 0; i < eventsList.length; i++) {
    if (eventsList[i] && eventsList[i].type === "lunar") {
      return eventsList[i];
    }
  }

  return fallback;
}

function getEventPreview(eventsList) {
  var ev = getPrimaryEvent(eventsList);
  if (!ev) return "";
  return getDisplayTitle(ev.title);
}

function getEventSummary(eventsList) {
  if (!eventsList || !eventsList.length) return "";

  var titles = [];
  for (var i = 0; i < eventsList.length; i++) {
    var title = getDisplayTitle(eventsList[i] && eventsList[i].title);
    if (title && titles.indexOf(title) === -1) {
      titles.push(title);
    }
  }

  return titles.slice(0, 3).join(" • ");
}

function getLunarDayBadge(lunarDay, isLeap) {
  if (lunarDay === 1) {
    return { text: "Mùng 1", highlight: true, badgeColor: "#e74c3c" };
  } else if (lunarDay === 15) {
    return { text: "Rằm", highlight: true, badgeColor: "#f39c12" };
  }
  return null;
}

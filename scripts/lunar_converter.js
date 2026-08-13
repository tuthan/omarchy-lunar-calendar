.pragma library

/**
 * Lunar Calendar & Moon Phase Calculation Engine
 * High-precision astronomical engine based on Ho Ngoc Duc's East Asian Lunar Calendar algorithm.
 * Supports UTC+7 (Vietnam) and UTC+8 (China) standard timezones.
 */

var CAN = ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"];
var CHI = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"];

var SOLAR_TERMS = [
  "Xuân phân", "Thanh minh", "Cốc vũ", "Lập hạ", "Tiểu mãn", "Mang chủng",
  "Hạ chí", "Tiểu thử", "Đại thử", "Lập thu", "Xử thử", "Bạch lộ",
  "Thu phân", "Hàn lộ", "Sương giáng", "Lập đông", "Tiểu tuyết", "Đại tuyết",
  "Đông chí", "Tiểu hàn", "Đại hàn", "Lập xuân", "Vũ thủy", "Kinh trập"
];

function julianDayFromDate(d, m, y) {
  var a = Math.floor((14 - m) / 12);
  var y1 = y + 4800 - a;
  var m1 = m + 12 * a - 3;
  return d + Math.floor((153 * m1 + 2) / 5) + 365 * y1 + Math.floor(y1 / 4) - Math.floor(y1 / 100) + Math.floor(y1 / 400) - 32045;
}

function dateFromJulianDay(jd) {
  var a = jd + 32044;
  var b = Math.floor((4 * a + 3) / 146097);
  var c = a - Math.floor((146097 * b) / 4);
  var d = Math.floor((4 * c + 3) / 1461);
  var e = c - Math.floor((1461 * d) / 4);
  var m = Math.floor((5 * e + 2) / 153);
  var day = e - Math.floor((153 * m + 2) / 5) + 1;
  var month = m + 3 - 12 * Math.floor(m / 10);
  var year = 100 * b + d - 4800 + Math.floor(m / 10);
  return { day: day, month: month, year: year };
}

function getNewMoonDay(k, timeZone) {
  var T = k / 1236.85;
  var T2 = T * T;
  var T3 = T2 * T;
  var dr = Math.PI / 180;
  
  var Jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * T2 - 0.000000155 * T3;
  Jd1 = Jd1 + 0.00033 * Math.sin((166.56 + 132.87 * T - 0.009173 * T2) * dr);

  var M = 359.2242 + 29.10535608 * k - 0.0000333 * T2 - 0.00000347 * T3;
  var Mpr = 306.0253 + 385.81691806 * k + 0.0107306 * T2 + 0.00001236 * T3;
  var F = 21.2964 + 390.67050646 * k - 0.0016528 * T2 - 0.00000239 * T3;

  var C1 = (0.1734 - 0.000393 * T) * Math.sin(M * dr) + 0.0021 * Math.sin(2 * M * dr);
  C1 = C1 - 0.4068 * Math.sin(Mpr * dr) + 0.0161 * Math.sin(2 * Mpr * dr);
  C1 = C1 - 0.0004 * Math.sin(3 * Mpr * dr);
  C1 = C1 + 0.0104 * Math.sin(2 * F * dr) - 0.0051 * Math.sin((M + Mpr) * dr);
  C1 = C1 - 0.0074 * Math.sin((M - Mpr) * dr) + 0.0004 * Math.sin((2 * F + M) * dr);
  C1 = C1 - 0.0004 * Math.sin((2 * F - M) * dr) - 0.0006 * Math.sin((2 * F + Mpr) * dr);
  C1 = C1 + 0.0010 * Math.sin((2 * F - Mpr) * dr) + 0.0005 * Math.sin((M + 2 * Mpr) * dr);

  var JdNew = Jd1 + C1;
  return Math.floor(JdNew + 0.5 + timeZone / 24.0);
}

function sunLongitude(jdn) {
  var T = (jdn - 2451545.0) / 36525.0;
  var T2 = T * T;
  var dr = Math.PI / 180;

  var L0 = 280.46645 + 36000.76983 * T + 0.0003032 * T2;
  var M = 357.52910 + 35999.05030 * T - 0.0001559 * T2 - 0.00000048 * T * T2;

  var C = (1.914600 - 0.004817 * T - 0.000014 * T2) * Math.sin(M * dr);
  C += (0.019993 - 0.000101 * T) * Math.sin(2 * M * dr);
  C += 0.000290 * Math.sin(3 * M * dr);

  var sunLong = L0 + C;
  sunLong = sunLong % 360;
  if (sunLong < 0) sunLong += 360;

  return sunLong;
}

function getSunLongitude(jdn, timeZone) {
  return Math.floor(sunLongitude(jdn - 0.5 - timeZone / 24.0) / 30);
}

function getLunarMonth11(year, timeZone) {
  var off = julianDayFromDate(31, 12, year) - 2415021;
  var k = Math.floor(off / 29.53058868);
  var nm = Math.floor(getNewMoonDay(k, timeZone));
  var sunLong = getSunLongitude(nm, timeZone);
  if (sunLong >= 9) { // 9 is 270 degrees (Winter Solstice)
    nm = Math.floor(getNewMoonDay(k - 1, timeZone));
  }
  return nm;
}

function getLeapMonthOffset(a11, timeZone) {
  var k = Math.floor(0.5 + (a11 - 2415021.076998695) / 29.530588853);
  var last = 0;
  var i = 1;
  var arc = getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone);

  do {
    last = arc;
    i++;
    arc = getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone);
  } while (arc !== last && i < 14);

  return i - 1;
}

function convertSolarToLunar(day, month, year, timeZone) {
  if (timeZone === undefined || timeZone === null) {
    timeZone = 7.0; // Default UTC+7
  }

  var dayNumber = julianDayFromDate(day, month, year);
  var k = Math.floor((dayNumber - 2415021.07699) / 29.53058868);
  var N1 = getNewMoonDay(k + 1, timeZone);
  if (N1 > dayNumber) {
    N1 = getNewMoonDay(k, timeZone);
  }

  var lunarDay = dayNumber - N1 + 1;

  var a11 = getLunarMonth11(year - 1, timeZone);
  var b11 = getLunarMonth11(year, timeZone);

  var lunarYear = year;
  if (N1 >= b11) {
    a11 = b11;
    b11 = getLunarMonth11(year + 1, timeZone);
    lunarYear = year + 1;
  } else if (N1 < a11) {
    b11 = a11;
    a11 = getLunarMonth11(year - 2, timeZone);
    lunarYear = year - 1;
  }

  var diff = Math.floor((N1 - a11) / 29);
  var isLeap = false;
  var lunarMonth = diff + 11;
  if (b11 - a11 > 365) {
    var leapMonthDiff = getLeapMonthOffset(a11, timeZone);
    if (diff >= leapMonthDiff) {
      lunarMonth = diff + 10;
      if (diff === leapMonthDiff) {
        isLeap = true;
      }
    }
  }

  if (lunarMonth > 12) lunarMonth -= 12;
  if (lunarMonth >= 11 && diff < 4) lunarYear -= 1;

  // Can Chi Calculations
  var stemYear = CAN[(lunarYear + 6) % 10];
  var branchYear = CHI[(lunarYear + 8) % 12];
  var canChiYear = stemYear + " " + branchYear;

  var stemMonth = CAN[(lunarYear * 12 + lunarMonth + 3) % 10];
  var branchMonth = CHI[(lunarMonth + 1) % 12];
  var canChiMonth = stemMonth + " " + branchMonth;

  var stemDay = CAN[(dayNumber + 9) % 10];
  var branchDay = CHI[(dayNumber + 1) % 12];
  var canChiDay = stemDay + " " + branchDay;

  // Solar Term
  var solarTermIdx = Math.floor(sunLongitude(dayNumber - 0.5 - timeZone / 24.0) / 15);
  var solarTermName = SOLAR_TERMS[solarTermIdx];

  return {
    lunarDay: lunarDay,
    lunarMonth: lunarMonth,
    lunarYear: lunarYear,
    isLeap: isLeap,
    canChiYear: canChiYear,
    canChiMonth: canChiMonth,
    canChiDay: canChiDay,
    solarTerm: solarTermName,
    isFirstDay: lunarDay === 1,
    isFullMoon: lunarDay === 15
  };
}

function getMoonPhase(day, month, year) {
  var jd = julianDayFromDate(day, month, year);
  var synodic = 29.53058867;
  var refJd = 2451549.26;
  var daysSinceRef = jd - refJd;
  var newMoons = daysSinceRef / synodic;
  var cycle = newMoons - Math.floor(newMoons);
  var age = cycle * synodic;

  var illumination = Math.round((1 - Math.cos(cycle * 2 * Math.PI)) / 2 * 100);

  var phaseName = "";
  var phaseIcon = "🌑";

  if (age < 1.84566) {
    phaseName = "New Moon";
    phaseIcon = "🌑";
  } else if (age < 5.53699) {
    phaseName = "Waxing Crescent";
    phaseIcon = "🌒";
  } else if (age < 9.22831) {
    phaseName = "First Quarter";
    phaseIcon = "🌓";
  } else if (age < 12.91963) {
    phaseName = "Waxing Gibbous";
    phaseIcon = "🌔";
  } else if (age < 16.61096) {
    phaseName = "Full Moon";
    phaseIcon = "🌕";
  } else if (age < 20.30228) {
    phaseName = "Waning Gibbous";
    phaseIcon = "🌖";
  } else if (age < 23.99361) {
    phaseName = "Third Quarter";
    phaseIcon = "🌗";
  } else if (age < 27.68493) {
    phaseName = "Waning Crescent";
    phaseIcon = "🌘";
  } else {
    phaseName = "New Moon";
    phaseIcon = "🌑";
  }

  return {
    age: Math.round(age * 10) / 10,
    illumination: illumination,
    phaseName: phaseName,
    phaseIcon: phaseIcon
  };
}

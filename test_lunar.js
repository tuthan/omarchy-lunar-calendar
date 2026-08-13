const lunar = require('./scripts/lunar_converter.js');

console.log("--- Testing Lunar Conversion & Moon Phase Engine ---");

// Test today: August 13, 2026
const resToday = lunar.convertSolarToLunar(13, 8, 2026, 7.0);
console.log("Gregorian: 13/08/2026");
console.log("Lunar Result:", resToday);

const moonToday = lunar.getMoonPhase(13, 8, 2026);
console.log("Moon Phase:", moonToday);

// Test Lunar New Year 2026 (Feb 17, 2026)
const resTet2026 = lunar.convertSolarToLunar(17, 2, 2026, 7.0);
console.log("\nGregorian: 17/02/2026 (Tet Bính Ngọ 2026)");
console.log("Lunar Result:", resTet2026);
if (resTet2026.lunarDay === 1 && resTet2026.lunarMonth === 1) {
  console.log("✅ Lunar New Year Test PASSED!");
} else {
  console.log("❌ Lunar New Year Test FAILED!");
}

// Test Mid-Autumn Festival (15th of 8th Lunar Month)
const resRram8 = lunar.convertSolarToLunar(25, 9, 2026, 7.0);
console.log("\nGregorian: 25/09/2026");
console.log("Lunar Result:", resRram8);

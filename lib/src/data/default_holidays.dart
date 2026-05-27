import '../models/holiday.dart';

/// Embedded default holiday calendars for 2025–2027.
///
/// These are used as the built-in [LocalHolidayProvider] data, ensuring the
/// package works offline without any prior sync. Remote data fetched via
/// [CalendarSync] overrides these entries.
///
/// Sources:
///   NSE/BSE: NSE India official holiday list
///   NYSE/NASDAQ: NYSE published holiday schedule
///   LSE: London Stock Exchange holiday calendar
///   MCX: MCX India official holiday list
// ignore_for_file: lines_longer_than_80_chars

class DefaultHolidays {
  DefaultHolidays._();

  // ── Helper ──────────────────────────────────────────────────────────────────
  static DateTime _d(int y, int m, int d) => DateTime(y, m, d);

  // ── NSE / BSE (India) ────────────────────────────────────────────────────────

  static final List<Holiday> nse2025 = [
    Holiday(date: _d(2025, 1, 26), type: HolidayType.holiday, reason: 'Republic Day'),
    Holiday(date: _d(2025, 2, 26), type: HolidayType.holiday, reason: 'Mahashivratri'),
    Holiday(date: _d(2025, 3, 14), type: HolidayType.holiday, reason: 'Holi'),
    Holiday(date: _d(2025, 3, 31), type: HolidayType.holiday, reason: 'Id-Ul-Fitr (Ramzan Id)'),
    Holiday(date: _d(2025, 4, 10), type: HolidayType.holiday, reason: 'Shri Ram Navami'),
    Holiday(date: _d(2025, 4, 14), type: HolidayType.holiday, reason: 'Dr. Baba Saheb Ambedkar Jayanti'),
    Holiday(date: _d(2025, 4, 18), type: HolidayType.holiday, reason: 'Good Friday'),
    Holiday(date: _d(2025, 5, 1), type: HolidayType.holiday, reason: 'Maharashtra Day'),
    Holiday(date: _d(2025, 8, 15), type: HolidayType.holiday, reason: 'Independence Day'),
    Holiday(date: _d(2025, 8, 27), type: HolidayType.holiday, reason: 'Ganesh Chaturthi'),
    Holiday(date: _d(2025, 10, 2), type: HolidayType.holiday, reason: 'Mahatma Gandhi Jayanti'),
    Holiday(date: _d(2025, 10, 2), type: HolidayType.holiday, reason: 'Dussehra'),
    Holiday(date: _d(2025, 10, 20), type: HolidayType.holiday, reason: 'Diwali – Laxmi Pujan'),
    Holiday(date: _d(2025, 10, 21), type: HolidayType.holiday, reason: 'Diwali – Balipratipada'),
    Holiday(date: _d(2025, 11, 5), type: HolidayType.holiday, reason: 'Prakash Gurpurb Sri Guru Nanak Dev Ji'),
    Holiday(date: _d(2025, 12, 25), type: HolidayType.holiday, reason: 'Christmas'),
  ];

  static final List<Holiday> nse2026 = [
    Holiday(date: _d(2026, 1, 26), type: HolidayType.holiday, reason: 'Republic Day'),
    Holiday(date: _d(2026, 3, 19), type: HolidayType.holiday, reason: 'Holi'),
    Holiday(date: _d(2026, 4, 3), type: HolidayType.holiday, reason: 'Good Friday'),
    Holiday(date: _d(2026, 4, 14), type: HolidayType.holiday, reason: 'Dr. Baba Saheb Ambedkar Jayanti'),
    Holiday(date: _d(2026, 5, 1), type: HolidayType.holiday, reason: 'Maharashtra Day'),
    Holiday(date: _d(2026, 8, 15), type: HolidayType.holiday, reason: 'Independence Day'),
    Holiday(date: _d(2026, 10, 2), type: HolidayType.holiday, reason: 'Mahatma Gandhi Jayanti'),
    Holiday(date: _d(2026, 11, 1), type: HolidayType.holiday, reason: 'Diwali – Laxmi Pujan'),
    Holiday(date: _d(2026, 11, 27), type: HolidayType.specialSession, reason: 'Muhurat Trading', openTime: '18:00', closeTime: '19:00'),
    Holiday(date: _d(2026, 12, 25), type: HolidayType.holiday, reason: 'Christmas'),
  ];

  // ── NYSE / NASDAQ (US) ────────────────────────────────────────────────────

  static final List<Holiday> nyse2025 = [
    Holiday(date: _d(2025, 1, 1), type: HolidayType.holiday, reason: "New Year's Day"),
    Holiday(date: _d(2025, 1, 20), type: HolidayType.holiday, reason: 'Martin Luther King Jr. Day'),
    Holiday(date: _d(2025, 2, 17), type: HolidayType.holiday, reason: "Presidents' Day"),
    Holiday(date: _d(2025, 4, 18), type: HolidayType.holiday, reason: 'Good Friday'),
    Holiday(date: _d(2025, 5, 26), type: HolidayType.holiday, reason: 'Memorial Day'),
    Holiday(date: _d(2025, 6, 19), type: HolidayType.holiday, reason: 'Juneteenth National Independence Day'),
    Holiday(date: _d(2025, 7, 4), type: HolidayType.holiday, reason: 'Independence Day'),
    Holiday(date: _d(2025, 9, 1), type: HolidayType.holiday, reason: 'Labor Day'),
    Holiday(date: _d(2025, 11, 27), type: HolidayType.holiday, reason: 'Thanksgiving Day'),
    Holiday(date: _d(2025, 11, 28), type: HolidayType.earlyClose, reason: 'Day After Thanksgiving', closeTime: '13:00'),
    Holiday(date: _d(2025, 12, 24), type: HolidayType.earlyClose, reason: 'Christmas Eve', closeTime: '13:00'),
    Holiday(date: _d(2025, 12, 25), type: HolidayType.holiday, reason: 'Christmas Day'),
  ];

  static final List<Holiday> nyse2026 = [
    Holiday(date: _d(2026, 1, 1), type: HolidayType.holiday, reason: "New Year's Day"),
    Holiday(date: _d(2026, 1, 19), type: HolidayType.holiday, reason: 'Martin Luther King Jr. Day'),
    Holiday(date: _d(2026, 2, 16), type: HolidayType.holiday, reason: "Presidents' Day"),
    Holiday(date: _d(2026, 4, 3), type: HolidayType.holiday, reason: 'Good Friday'),
    Holiday(date: _d(2026, 5, 25), type: HolidayType.holiday, reason: 'Memorial Day'),
    Holiday(date: _d(2026, 6, 19), type: HolidayType.holiday, reason: 'Juneteenth National Independence Day'),
    Holiday(date: _d(2026, 7, 3), type: HolidayType.earlyClose, reason: 'Independence Day (observed early close)', closeTime: '13:00'),
    Holiday(date: _d(2026, 9, 7), type: HolidayType.holiday, reason: 'Labor Day'),
    Holiday(date: _d(2026, 11, 26), type: HolidayType.holiday, reason: 'Thanksgiving Day'),
    Holiday(date: _d(2026, 11, 27), type: HolidayType.earlyClose, reason: 'Day After Thanksgiving', closeTime: '13:00'),
    Holiday(date: _d(2026, 12, 24), type: HolidayType.earlyClose, reason: 'Christmas Eve', closeTime: '13:00'),
    Holiday(date: _d(2026, 12, 25), type: HolidayType.holiday, reason: 'Christmas Day'),
  ];

  // ── LSE (UK) ──────────────────────────────────────────────────────────────

  static final List<Holiday> lse2025 = [
    Holiday(date: _d(2025, 1, 1), type: HolidayType.holiday, reason: "New Year's Day"),
    Holiday(date: _d(2025, 4, 18), type: HolidayType.holiday, reason: 'Good Friday'),
    Holiday(date: _d(2025, 4, 21), type: HolidayType.holiday, reason: 'Easter Monday'),
    Holiday(date: _d(2025, 5, 5), type: HolidayType.holiday, reason: 'Early May Bank Holiday'),
    Holiday(date: _d(2025, 5, 26), type: HolidayType.holiday, reason: 'Spring Bank Holiday'),
    Holiday(date: _d(2025, 8, 25), type: HolidayType.holiday, reason: 'Summer Bank Holiday'),
    Holiday(date: _d(2025, 12, 25), type: HolidayType.holiday, reason: 'Christmas Day'),
    Holiday(date: _d(2025, 12, 26), type: HolidayType.holiday, reason: 'Boxing Day'),
  ];

  static final List<Holiday> lse2026 = [
    Holiday(date: _d(2026, 1, 1), type: HolidayType.holiday, reason: "New Year's Day"),
    Holiday(date: _d(2026, 4, 3), type: HolidayType.holiday, reason: 'Good Friday'),
    Holiday(date: _d(2026, 4, 6), type: HolidayType.holiday, reason: 'Easter Monday'),
    Holiday(date: _d(2026, 5, 4), type: HolidayType.holiday, reason: 'Early May Bank Holiday'),
    Holiday(date: _d(2026, 5, 25), type: HolidayType.holiday, reason: 'Spring Bank Holiday'),
    Holiday(date: _d(2026, 8, 31), type: HolidayType.holiday, reason: 'Summer Bank Holiday'),
    Holiday(date: _d(2026, 12, 25), type: HolidayType.holiday, reason: 'Christmas Day'),
    Holiday(date: _d(2026, 12, 28), type: HolidayType.holiday, reason: 'Boxing Day (observed)'),
  ];

  // ── MCX (India) ───────────────────────────────────────────────────────────
  // MCX largely follows NSE but has a few additional commodity-specific closures.

  static final List<Holiday> mcx2025 = [
    Holiday(date: _d(2025, 1, 26), type: HolidayType.holiday, reason: 'Republic Day'),
    Holiday(date: _d(2025, 2, 26), type: HolidayType.holiday, reason: 'Mahashivratri'),
    Holiday(date: _d(2025, 3, 14), type: HolidayType.holiday, reason: 'Holi'),
    Holiday(date: _d(2025, 3, 31), type: HolidayType.holiday, reason: 'Id-Ul-Fitr'),
    Holiday(date: _d(2025, 4, 10), type: HolidayType.holiday, reason: 'Ram Navami'),
    Holiday(date: _d(2025, 4, 14), type: HolidayType.holiday, reason: 'Dr. Ambedkar Jayanti'),
    Holiday(date: _d(2025, 4, 18), type: HolidayType.holiday, reason: 'Good Friday'),
    Holiday(date: _d(2025, 8, 15), type: HolidayType.holiday, reason: 'Independence Day'),
    Holiday(date: _d(2025, 8, 27), type: HolidayType.holiday, reason: 'Ganesh Chaturthi'),
    Holiday(date: _d(2025, 10, 2), type: HolidayType.holiday, reason: 'Gandhi Jayanti / Dussehra'),
    Holiday(date: _d(2025, 10, 20), type: HolidayType.holiday, reason: 'Diwali – Laxmi Pujan'),
    Holiday(date: _d(2025, 11, 5), type: HolidayType.holiday, reason: 'Guru Nanak Jayanti'),
    Holiday(date: _d(2025, 12, 25), type: HolidayType.holiday, reason: 'Christmas'),
  ];

  static final List<Holiday> mcx2026 = [
    Holiday(date: _d(2026, 1, 26), type: HolidayType.holiday, reason: 'Republic Day'),
    Holiday(date: _d(2026, 3, 19), type: HolidayType.holiday, reason: 'Holi'),
    Holiday(date: _d(2026, 4, 3), type: HolidayType.holiday, reason: 'Good Friday'),
    Holiday(date: _d(2026, 4, 14), type: HolidayType.holiday, reason: 'Dr. Ambedkar Jayanti'),
    Holiday(date: _d(2026, 8, 15), type: HolidayType.holiday, reason: 'Independence Day'),
    Holiday(date: _d(2026, 10, 2), type: HolidayType.holiday, reason: 'Gandhi Jayanti'),
    Holiday(date: _d(2026, 11, 1), type: HolidayType.holiday, reason: 'Diwali'),
    Holiday(date: _d(2026, 12, 25), type: HolidayType.holiday, reason: 'Christmas'),
  ];

  // ── Aggregated map ────────────────────────────────────────────────────────

  static Map<String, Map<int, List<Holiday>>> get all => {
        'NSE': {2025: nse2025, 2026: nse2026},
        'BSE': {2025: nse2025, 2026: nse2026}, // same as NSE
        'NYSE': {2025: nyse2025, 2026: nyse2026},
        'NASDAQ': {2025: nyse2025, 2026: nyse2026}, // same holidays as NYSE
        'LSE': {2025: lse2025, 2026: lse2026},
        'MCX': {2025: mcx2025, 2026: mcx2026},
        'MCX_GOLD': {2025: mcx2025, 2026: mcx2026},
        'MCX_SILVER': {2025: mcx2025, 2026: mcx2026},
        'MCX_CRUDE': {2025: mcx2025, 2026: mcx2026},
        'NCDEX': {2025: mcx2025, 2026: mcx2026},
      };
}

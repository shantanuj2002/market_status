import 'package:flutter_test/flutter_test.dart';
import 'package:market_status/market_status.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Creates a UTC DateTime from an exchange-local string.
/// e.g. utc('2026-01-15 10:00', 'Asia/Kolkata') → UTC 04:30
///
/// Uses an explicit UTC base so the result is machine-timezone-independent.
DateTime utc(String localIso, String timezone) {
  final parts = localIso.replaceAll('-', ' ').replaceAll(':', ' ').split(' ');
  // Build as a "naive-UTC" reference first
  final naiveUtc = DateTime.utc(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
    int.parse(parts[3]),
    int.parse(parts[4]),
  );
  final offset = _offsets[timezone] ?? Duration.zero;
  // Subtract the timezone offset to arrive at true UTC
  return naiveUtc.subtract(offset);
}

const _offsets = {
  'Asia/Kolkata': Duration(hours: 5, minutes: 30),
  'America/New_York': Duration(hours: 5), // EST; use -4 for EDT below
  'America/New_York_EDT': Duration(hours: 4),
  'Europe/London': Duration.zero, // GMT; BST = +1
  'Europe/London_BST': Duration(hours: -1),
  'Asia/Tokyo': Duration(hours: -9),
  'Asia/Shanghai': Duration(hours: -8),
  'Asia/Hong_Kong': Duration(hours: -8),
  'Asia/Singapore': Duration(hours: -8),
  'Australia/Sydney': Duration(hours: -11), // AEDT
};

/// Configures MarketStatus with a fixed time and fixed timezones (no network).
void configureFixed({
  required DateTime utcTime,
  String deviceTz = 'Asia/Kolkata',
  String? ipTz,
  TimezoneMode timezoneMode = TimezoneMode.deviceOnly,
  Map<String, Map<int, List<Holiday>>>? extraHolidays,
}) {
  final merged = <String, Map<int, List<Holiday>>>{};
  DefaultHolidays.all.forEach((code, byYear) {
    merged[code] = Map<int, List<Holiday>>.from(byYear);
  });
  if (extraHolidays != null) {
    extraHolidays.forEach((code, byYear) {
      final existing = merged.putIfAbsent(code, () => {});
      byYear.forEach((year, list) {
        existing[year] = list;
      });
    });
  }

  MarketStatus.configure(
    timezoneMode: timezoneMode,
    timeProvider: FixedTimeProvider(utcTime),
    deviceTimezoneProvider: FixedTimezoneProvider(deviceTz),
    // ipTimezoneProvider only matters when timezoneMode == deviceWithIpVerification
    ipTimezoneProvider:
        ipTz != null ? FixedTimezoneProvider(ipTz) : null,
    holidayProvider: CompositeHolidayProvider([
      LocalHolidayProvider(merged),
    ]),
  );
}

void main() {
  // Reset engine before each test to avoid cross-test contamination
  setUp(() => MarketStatus.reset());

  // ─────────────────────────────────────────────────────────────────────────
  // 1. NSE — India stock exchange
  // ─────────────────────────────────────────────────────────────────────────

  group('NSE', () {
    test('is OPEN during regular hours (Mon 10:00 IST)', () async {
      configureFixed(utcTime: utc('2026-01-19 10:00', 'Asia/Kolkata'));
      final state = await MarketStatus.market(Markets.nse);

      expect(state.isOpen, isTrue);
      expect(state.isHoliday, isFalse);
      expect(state.currentSession, SessionType.regular);
      expect(state.marketCode, 'NSE');
      expect(state.exchangeTimezone, 'Asia/Kolkata');
      expect(state.timeToClose, isNotNull);
      expect(state.timeToClose!.inMinutes, isPositive);
    });

    test('is CLOSED before market open (Mon 08:00 IST)', () async {
      configureFixed(utcTime: utc('2026-01-19 08:00', 'Asia/Kolkata'));
      final state = await MarketStatus.market(Markets.nse);

      expect(state.isOpen, isFalse);
      expect(state.nextOpen, isNotNull);
    });

    test('is CLOSED after market close (Mon 16:00 IST)', () async {
      configureFixed(utcTime: utc('2026-01-19 16:00', 'Asia/Kolkata'));
      final state = await MarketStatus.market(Markets.nse);

      expect(state.isOpen, isFalse);
    });

    test('is CLOSED on Saturday', () async {
      // 2026-01-17 is a Saturday
      configureFixed(utcTime: utc('2026-01-17 10:00', 'Asia/Kolkata'));
      final state = await MarketStatus.market(Markets.nse);

      expect(state.isOpen, isFalse);
    });

    test('is CLOSED on Sunday', () async {
      configureFixed(utcTime: utc('2026-01-18 10:00', 'Asia/Kolkata'));
      final state = await MarketStatus.market(Markets.nse);

      expect(state.isOpen, isFalse);
    });

    test('is CLOSED on Republic Day (2026-01-26)', () async {
      configureFixed(utcTime: utc('2026-01-26 10:00', 'Asia/Kolkata'));
      final state = await MarketStatus.market(Markets.nse);

      expect(state.isOpen, isFalse);
      expect(state.isHoliday, isTrue);
      expect(state.holidayReason, contains('Republic Day'));
    });

    test('nextOpen skips to next trading day when checked on holiday', () async {
      // Republic Day 2026 (Monday) → next trading day is Tuesday 2026-01-27
      configureFixed(utcTime: utc('2026-01-26 10:00', 'Asia/Kolkata'));
      final state = await MarketStatus.market(Markets.nse);

      expect(state.nextOpen, isNotNull);
      expect(state.nextOpen!.isAfter(DateTime.utc(2026, 1, 26)), isTrue);
    });

    test('timeToOpen is positive when closed before session', () async {
      configureFixed(utcTime: utc('2026-01-19 08:00', 'Asia/Kolkata'));
      final state = await MarketStatus.market(Markets.nse);

      expect(state.timeToOpen, isNotNull);
      expect(state.timeToOpen!.inMinutes, isPositive);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. BSE — same hours as NSE
  // ─────────────────────────────────────────────────────────────────────────

  group('BSE', () {
    test('mirrors NSE session hours', () async {
      configureFixed(utcTime: utc('2026-01-19 11:00', 'Asia/Kolkata'));
      final nse = await MarketStatus.market(Markets.nse);
      final bse = await MarketStatus.market(Markets.bse);

      expect(bse.isOpen, equals(nse.isOpen));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 3. NYSE / NASDAQ
  // ─────────────────────────────────────────────────────────────────────────

  group('NYSE', () {
    test('is OPEN during regular hours (Wed 11:00 EST)', () async {
      // EST = UTC-5, 11:00 EST = 16:00 UTC
      configureFixed(
        utcTime: DateTime.utc(2026, 1, 21, 16, 0),
        deviceTz: 'America/New_York',
      );
      final state = await MarketStatus.market(Markets.nyse);

      expect(state.isOpen, isTrue);
      expect(state.currentSession, SessionType.regular);
    });

    test('is CLOSED on Thanksgiving 2026 (2026-11-26)', () async {
      configureFixed(
        utcTime: DateTime.utc(2026, 11, 26, 15, 0),
        deviceTz: 'America/New_York',
      );
      final state = await MarketStatus.market(Markets.nyse);

      expect(state.isHoliday, isTrue);
      expect(state.holidayReason, contains('Thanksgiving'));
    });

    test('has early close on Day After Thanksgiving 2026', () async {
      // 2026-11-27 early close at 13:00 EST (18:00 UTC)
      // Test at 12:00 EST (17:00 UTC) — should be open
      configureFixed(
        utcTime: DateTime.utc(2026, 11, 27, 17, 0),
        deviceTz: 'America/New_York',
      );
      final state = await MarketStatus.market(Markets.nyse);

      expect(state.isOpen, isTrue);
      // Close time should be 13:00 EST = 18:00 UTC
      expect(state.nextClose, isNotNull);
      expect(state.nextClose!.hour, equals(18));
    });

    test('is CLOSED on Christmas 2026', () async {
      configureFixed(
        utcTime: DateTime.utc(2026, 12, 25, 15, 0),
        deviceTz: 'America/New_York',
      );
      final state = await MarketStatus.market(Markets.nyse);

      expect(state.isHoliday, isTrue);
    });
  });

  group('NASDAQ', () {
    test('supports pre-market session (06:00 EST)', () async {
      // 06:00 EST = 11:00 UTC (EST = UTC-5)
      configureFixed(
        utcTime: DateTime.utc(2026, 1, 21, 11, 0),
        deviceTz: 'America/New_York',
      );
      final state = await MarketStatus.market(Markets.nasdaq);

      expect(state.isOpen, isTrue);
      expect(state.currentSession, SessionType.preMarket);
    });

    test('is in regular session at 10:00 EST', () async {
      configureFixed(
        utcTime: DateTime.utc(2026, 1, 21, 15, 0), // 10:00 EST
        deviceTz: 'America/New_York',
      );
      final state = await MarketStatus.market(Markets.nasdaq);

      expect(state.isOpen, isTrue);
      expect(state.currentSession, SessionType.regular);
    });

    test('is in after-hours at 17:00 EST', () async {
      configureFixed(
        utcTime: DateTime.utc(2026, 1, 21, 22, 0), // 17:00 EST
        deviceTz: 'America/New_York',
      );
      final state = await MarketStatus.market(Markets.nasdaq);

      expect(state.isOpen, isTrue);
      expect(state.currentSession, SessionType.afterHours);
    });

    test('is CLOSED at 21:00 EST (after after-hours)', () async {
      configureFixed(
        utcTime: DateTime.utc(2026, 1, 22, 2, 0), // 21:00 EST
        deviceTz: 'America/New_York',
      );
      final state = await MarketStatus.market(Markets.nasdaq);

      expect(state.isOpen, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 4. LSE — UK market with DST
  // ─────────────────────────────────────────────────────────────────────────

  group('LSE', () {
    test('is OPEN at 10:00 GMT (winter)', () async {
      // Jan = GMT = UTC+0, 10:00 GMT = 10:00 UTC
      configureFixed(
        utcTime: DateTime.utc(2026, 1, 21, 10, 0),
        deviceTz: 'Europe/London',
      );
      final state = await MarketStatus.market(Markets.lse);

      expect(state.isOpen, isTrue);
    });

    test('is OPEN at 10:00 BST (summer, UTC+1)', () async {
      // July = BST = UTC+1, 10:00 BST = 09:00 UTC
      configureFixed(
        utcTime: DateTime.utc(2026, 7, 15, 9, 0),
        deviceTz: 'Europe/London',
      );
      final state = await MarketStatus.market(Markets.lse);

      expect(state.isOpen, isTrue);
    });

    test('is CLOSED on Good Friday 2026', () async {
      configureFixed(
        utcTime: DateTime.utc(2026, 4, 3, 10, 0),
        deviceTz: 'Europe/London',
      );
      final state = await MarketStatus.market(Markets.lse);

      expect(state.isHoliday, isTrue);
    });

    test('is CLOSED on Boxing Day 2026', () async {
      configureFixed(
        utcTime: DateTime.utc(2026, 12, 28, 10, 0),
        deviceTz: 'Europe/London',
      );
      final state = await MarketStatus.market(Markets.lse);

      expect(state.isHoliday, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 5. JPX — Japan with lunch break
  // ─────────────────────────────────────────────────────────────────────────

  group('JPX (Japan)', () {
    test('is OPEN in morning session (10:00 JST)', () async {
      // JST = UTC+9, 10:00 JST = 01:00 UTC
      configureFixed(
        utcTime: DateTime.utc(2026, 1, 21, 1, 0),
        deviceTz: 'Asia/Tokyo',
      );
      final state = await MarketStatus.market(Markets.jpx);

      expect(state.isOpen, isTrue);
      expect(state.currentSession, SessionType.morning);
    });

    test('is CLOSED during lunch break (12:00 JST)', () async {
      configureFixed(
        utcTime: DateTime.utc(2026, 1, 21, 3, 0), // 12:00 JST
        deviceTz: 'Asia/Tokyo',
      );
      final state = await MarketStatus.market(Markets.jpx);

      expect(state.isOpen, isFalse);
    });

    test('is OPEN in afternoon session (13:30 JST)', () async {
      configureFixed(
        utcTime: DateTime.utc(2026, 1, 21, 4, 30), // 13:30 JST
        deviceTz: 'Asia/Tokyo',
      );
      final state = await MarketStatus.market(Markets.jpx);

      expect(state.isOpen, isTrue);
      expect(state.currentSession, SessionType.afternoon);
    });

    test('is CLOSED after close (16:00 JST)', () async {
      configureFixed(
        utcTime: DateTime.utc(2026, 1, 21, 7, 0), // 16:00 JST
        deviceTz: 'Asia/Tokyo',
      );
      final state = await MarketStatus.market(Markets.jpx);

      expect(state.isOpen, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 6. China SSE/SZSE — lunch break
  // ─────────────────────────────────────────────────────────────────────────

  group('SSE (China)', () {
    test('is OPEN in morning session (10:00 CST)', () async {
      // CST = UTC+8, 10:00 CST = 02:00 UTC
      configureFixed(
        utcTime: DateTime.utc(2026, 1, 21, 2, 0),
        deviceTz: 'Asia/Shanghai',
      );
      final state = await MarketStatus.market(Markets.sse);

      expect(state.isOpen, isTrue);
      expect(state.currentSession, SessionType.morning);
    });

    test('is CLOSED during lunch break (12:00 CST)', () async {
      configureFixed(
        utcTime: DateTime.utc(2026, 1, 21, 4, 0), // 12:00 CST
        deviceTz: 'Asia/Shanghai',
      );
      final state = await MarketStatus.market(Markets.sse);

      expect(state.isOpen, isFalse);
    });

    test('is OPEN in afternoon session (14:00 CST)', () async {
      configureFixed(
        utcTime: DateTime.utc(2026, 1, 21, 6, 0), // 14:00 CST
        deviceTz: 'Asia/Shanghai',
      );
      final state = await MarketStatus.market(Markets.sse);

      expect(state.isOpen, isTrue);
      expect(state.currentSession, SessionType.afternoon);
    });

    test('is CLOSED after close (15:30 CST)', () async {
      configureFixed(
        utcTime: DateTime.utc(2026, 1, 21, 7, 30), // 15:30 CST
        deviceTz: 'Asia/Shanghai',
      );
      final state = await MarketStatus.market(Markets.sse);

      expect(state.isOpen, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 7. MCX — India commodity
  // ─────────────────────────────────────────────────────────────────────────

  group('MCX', () {
    test('is OPEN during morning session (10:00 IST)', () async {
      configureFixed(utcTime: utc('2026-01-19 10:00', 'Asia/Kolkata'));
      final state = await MarketStatus.market(Markets.mcx);

      expect(state.isOpen, isTrue);
    });

    test('is OPEN during evening session (19:00 IST)', () async {
      configureFixed(utcTime: utc('2026-01-19 19:00', 'Asia/Kolkata'));
      final state = await MarketStatus.market(Markets.mcx);

      expect(state.isOpen, isTrue);
    });

    test('is CLOSED after 23:30 IST', () async {
      configureFixed(utcTime: utc('2026-01-19 23:45', 'Asia/Kolkata'));
      final state = await MarketStatus.market(Markets.mcx);

      expect(state.isOpen, isFalse);
    });

    test('is CLOSED on Republic Day 2026', () async {
      configureFixed(utcTime: utc('2026-01-26 10:00', 'Asia/Kolkata'));
      final state = await MarketStatus.market(Markets.mcx);

      expect(state.isHoliday, isTrue);
    });
  });

  group('MCX Gold', () {
    test('is OPEN at 10:00 IST on trading day', () async {
      configureFixed(utcTime: utc('2026-01-19 10:00', 'Asia/Kolkata'));
      final state = await MarketStatus.market(Markets.mcxGold);

      expect(state.isOpen, isTrue);
      expect(state.marketCode, 'MCX_GOLD');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 8. COMEX / NYMEX
  // ─────────────────────────────────────────────────────────────────────────

  group('COMEX Gold', () {
    test('is OPEN at 10:00 EST', () async {
      // 10:00 EST = 15:00 UTC
      configureFixed(
        utcTime: DateTime.utc(2026, 1, 21, 15, 0),
        deviceTz: 'America/New_York',
      );
      final state = await MarketStatus.market(Markets.comexGold);

      expect(state.isOpen, isTrue);
      expect(state.marketCode, 'COMEX_GOLD');
    });
  });

  group('NYMEX Crude Oil', () {
    test('is OPEN at 10:00 EST', () async {
      configureFixed(
        utcTime: DateTime.utc(2026, 1, 21, 15, 0),
        deviceTz: 'America/New_York',
      );
      final state = await MarketStatus.market(Markets.nymexCrudeOil);

      expect(state.isOpen, isTrue);
      expect(state.marketCode, 'NYMEX_CRUDE');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 9. Crypto — always open
  // ─────────────────────────────────────────────────────────────────────────

  group('Crypto', () {
    test('is always OPEN — weekday', () async {
      configureFixed(utcTime: DateTime.utc(2026, 1, 21, 10, 0));
      final state = await MarketStatus.market(Markets.crypto);

      expect(state.isOpen, isTrue);
      expect(state.isHoliday, isFalse);
      expect(state.timeToClose, isNull); // 24×7 has no close
    });

    test('is always OPEN — Sunday midnight', () async {
      configureFixed(utcTime: DateTime.utc(2026, 1, 18, 0, 0));
      final state = await MarketStatus.market(Markets.crypto);

      expect(state.isOpen, isTrue);
    });

    test('is always OPEN — Christmas Day', () async {
      configureFixed(utcTime: DateTime.utc(2026, 12, 25, 12, 0));
      final state = await MarketStatus.market(Markets.crypto);

      expect(state.isOpen, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 10. Timezone mismatch detection
  // ─────────────────────────────────────────────────────────────────────────

  group('Timezone mismatch', () {
    test('deviceOnly mode — timezoneMismatch is always false', () async {
      configureFixed(
        utcTime: utc('2026-01-19 10:00', 'Asia/Kolkata'),
        deviceTz: 'Asia/Kolkata',
        ipTz: 'Asia/Dubai', // supplied but should be ignored
        timezoneMode: TimezoneMode.deviceOnly,
      );
      final state = await MarketStatus.market(Markets.nse);

      expect(state.timezoneMismatch, isFalse);
      expect(state.ipTimezone, isNull);
      expect(state.userTimezone, 'Asia/Kolkata');
    });

    test('deviceOnly mode — ipTimezone is null even if provider is supplied', () async {
      configureFixed(
        utcTime: utc('2026-01-19 10:00', 'Asia/Kolkata'),
        deviceTz: 'Asia/Kolkata',
        ipTz: 'America/New_York',
        timezoneMode: TimezoneMode.deviceOnly,
      );
      final state = await MarketStatus.market(Markets.nse);

      expect(state.ipTimezone, isNull);
      expect(state.timezoneMismatch, isFalse);
    });

    test('deviceWithIpVerification — detects mismatch: device=Asia/Kolkata, ip=Asia/Dubai', () async {
      configureFixed(
        utcTime: utc('2026-01-19 10:00', 'Asia/Kolkata'),
        deviceTz: 'Asia/Kolkata',
        ipTz: 'Asia/Dubai',
        timezoneMode: TimezoneMode.deviceWithIpVerification,
      );
      final state = await MarketStatus.market(Markets.nse);

      expect(state.timezoneMismatch, isTrue);
      expect(state.userTimezone, 'Asia/Kolkata');
      expect(state.ipTimezone, 'Asia/Dubai');
    });

    test('deviceWithIpVerification — no mismatch when device and ip match', () async {
      configureFixed(
        utcTime: utc('2026-01-19 10:00', 'Asia/Kolkata'),
        deviceTz: 'Asia/Kolkata',
        ipTz: 'Asia/Kolkata',
        timezoneMode: TimezoneMode.deviceWithIpVerification,
      );
      final state = await MarketStatus.market(Markets.nse);

      expect(state.timezoneMismatch, isFalse);
      expect(state.ipTimezone, 'Asia/Kolkata');
    });

    test('user in Dubai checking NSE — correct market state regardless of mode', () async {
      // Dubai user (UTC+4). NSE is open 09:15–15:30 IST.
      // 10:00 IST = 04:30 UTC = 08:30 Dubai time
      configureFixed(
        utcTime: utc('2026-01-19 10:00', 'Asia/Kolkata'),
        deviceTz: 'Asia/Dubai',
        timezoneMode: TimezoneMode.deviceOnly,
      );
      final state = await MarketStatus.market(Markets.nse);

      // Market state is computed in exchange timezone — always correct
      expect(state.isOpen, isTrue);
      expect(state.exchangeTimezone, 'Asia/Kolkata');
      expect(state.userTimezone, 'Asia/Dubai');
      expect(state.timezoneMismatch, isFalse); // deviceOnly never flags
    });

    test('user in London checking NSE', () async {
      configureFixed(
        utcTime: utc('2026-01-19 10:00', 'Asia/Kolkata'),
        deviceTz: 'Europe/London',
        timezoneMode: TimezoneMode.deviceOnly,
      );
      final state = await MarketStatus.market(Markets.nse);

      expect(state.isOpen, isTrue);
      expect(state.userTimezone, 'Europe/London');
      expect(state.exchangeTimezone, 'Asia/Kolkata');
    });

    test('deviceWithIpVerification — wrong device timezone flagged', () async {
      configureFixed(
        utcTime: utc('2026-01-19 10:00', 'Asia/Kolkata'),
        deviceTz: 'America/New_York', // device set incorrectly
        ipTz: 'Asia/Kolkata',         // IP reveals actual location
        timezoneMode: TimezoneMode.deviceWithIpVerification,
      );
      final state = await MarketStatus.market(Markets.nse);

      expect(state.timezoneMismatch, isTrue);
      expect(state.userTimezone, 'America/New_York');
      expect(state.ipTimezone, 'Asia/Kolkata');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 11. DST transitions
  // ─────────────────────────────────────────────────────────────────────────

  group('DST transitions', () {
    test('NYSE open at 09:30 EDT (summer, UTC-4)', () async {
      // July (EDT = UTC-4): 09:30 EDT = 13:30 UTC
      configureFixed(
        utcTime: DateTime.utc(2026, 7, 15, 13, 30),
        deviceTz: 'America/New_York',
      );
      final state = await MarketStatus.market(Markets.nyse);

      expect(state.isOpen, isTrue);
    });

    test('NYSE open at 09:30 EST (winter, UTC-5)', () async {
      // Jan (EST = UTC-5): 09:30 EST = 14:30 UTC
      configureFixed(
        utcTime: DateTime.utc(2026, 1, 21, 14, 30),
        deviceTz: 'America/New_York',
      );
      final state = await MarketStatus.market(Markets.nyse);

      expect(state.isOpen, isTrue);
    });

    test('LSE open at 08:00 BST (summer, UTC+1)', () async {
      // June (BST = UTC+1): 08:00 BST = 07:00 UTC
      configureFixed(
        utcTime: DateTime.utc(2026, 6, 15, 7, 0),
        deviceTz: 'Europe/London',
      );
      final state = await MarketStatus.market(Markets.lse);

      expect(state.isOpen, isTrue);
    });

    test('LSE closed at 07:59 BST (just before open)', () async {
      configureFixed(
        utcTime: DateTime.utc(2026, 6, 15, 6, 59),
        deviceTz: 'Europe/London',
      );
      final state = await MarketStatus.market(Markets.lse);

      expect(state.isOpen, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 12. Emergency closure
  // ─────────────────────────────────────────────────────────────────────────

  group('Emergency closure', () {
    test('NSE closed on emergency closure day', () async {
      final emergencyHolidays = <String, Map<int, List<Holiday>>>{
        'NSE': {
          2026: <Holiday>[
            ...DefaultHolidays.nse2026,
            Holiday(
              date: DateTime(2026, 3, 10),
              type: HolidayType.emergencyClosure,
              reason: 'Emergency: extreme weather',
            ),
          ],
        },
      };

      configureFixed(
        utcTime: utc('2026-03-10 10:00', 'Asia/Kolkata'),
        extraHolidays: emergencyHolidays,
      );
      final state = await MarketStatus.market(Markets.nse);

      expect(state.isOpen, isFalse);
      expect(state.isHoliday, isTrue);
      expect(state.holidayReason, contains('Emergency'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 13. Early close sessions
  // ─────────────────────────────────────────────────────────────────────────

  group('Early close', () {
    test('NYSE closes early at 13:00 on Day After Thanksgiving 2025', () async {
      // 2025-11-28, before 13:00 EST (18:00 UTC) — should be OPEN
      configureFixed(
        utcTime: DateTime.utc(2025, 11, 28, 17, 0), // 12:00 EST
        deviceTz: 'America/New_York',
      );
      final state = await MarketStatus.market(Markets.nyse);

      expect(state.isOpen, isTrue);
      // close should be at 13:00 EST = 18:00 UTC
      expect(state.nextClose, isNotNull);
    });

    test('NYSE closed after early close time on Day After Thanksgiving', () async {
      // 13:30 EST = 18:30 UTC — after early close
      configureFixed(
        utcTime: DateTime.utc(2025, 11, 28, 18, 30),
        deviceTz: 'America/New_York',
      );
      final state = await MarketStatus.market(Markets.nyse);

      expect(state.isOpen, isFalse);
    });

    test('NSE Muhurat trading 2026 — early close after override time', () async {
      // 2026-11-27 is Muhurat Trading — specialSession 18:00–19:00 IST.
      // At 10:00 IST (normal hours) — market should be CLOSED
      // because on a specialSession day only the special window is valid.
      configureFixed(
        utcTime: utc('2026-11-27 10:00', 'Asia/Kolkata'),
      );
      final state = await MarketStatus.market(Markets.nse);

      // Normal business hours are replaced entirely by the special window
      expect(state.isOpen, isFalse);
      expect(state.isSpecialSession, isFalse);
      // nextOpen should point to the special session open (18:00 IST)
      expect(state.nextOpen, isNotNull);
    });

    test('NSE Muhurat trading — OPEN inside 18:00–19:00 IST window', () async {
      // 18:30 IST = 13:00 UTC
      configureFixed(
        utcTime: utc('2026-11-27 18:30', 'Asia/Kolkata'),
      );
      final state = await MarketStatus.market(Markets.nse);

      expect(state.isOpen, isTrue);
      expect(state.isSpecialSession, isTrue);
      expect(state.specialSessionReason, contains('Muhurat'));
      expect(state.currentSession, SessionType.special);
      expect(state.timeToClose, isNotNull);
      expect(state.timeToClose!.inMinutes, lessThanOrEqualTo(30));
    });

    test('NSE Muhurat trading — CLOSED after 19:00 IST', () async {
      // 19:30 IST = 14:00 UTC
      configureFixed(
        utcTime: utc('2026-11-27 19:30', 'Asia/Kolkata'),
      );
      final state = await MarketStatus.market(Markets.nse);

      expect(state.isOpen, isFalse);
      expect(state.isSpecialSession, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 14. Delayed opening
  // ─────────────────────────────────────────────────────────────────────────

  group('Delayed open', () {
    test('NSE delayed open: nextOpen reflects delayed time', () async {
      final delayedHolidays = <String, Map<int, List<Holiday>>>{
        'NSE': {
          2026: <Holiday>[
            Holiday(
              date: DateTime(2026, 2, 10),
              type: HolidayType.delayedOpen,
              reason: 'Technical issue',
              openTime: '11:00',
            ),
          ],
        },
      };

      // 09:30 IST — normal time but delayed to 11:00
      // At 09:30 (before normal 09:15), session engine says "closed",
      // and the holiday engine provides delayed open override for nextOpen.
      configureFixed(
        utcTime: utc('2026-02-10 09:30', 'Asia/Kolkata'),
        extraHolidays: delayedHolidays,
      );
      final state = await MarketStatus.market(Markets.nse);

      // The delayed open should push nextOpen into 11:00 IST window
      // (market is closed and next open is set)
      expect(state.isOpen, isFalse);
      expect(state.isHoliday, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 15. Batch / multi-market API
  // ─────────────────────────────────────────────────────────────────────────

  group('MarketStatus.all()', () {
    test('returns states for all requested markets', () async {
      configureFixed(utcTime: utc('2026-01-19 10:00', 'Asia/Kolkata'));
      final states = await MarketStatus.all([
        Markets.nse,
        Markets.nyse,
        Markets.nasdaq,
        Markets.mcx,
        Markets.crypto,
      ]);

      expect(states.length, equals(5));
      expect(states.map((s) => s.marketCode).toSet(),
          containsAll(['NSE', 'NYSE', 'NASDAQ', 'MCX', 'CRYPTO']));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 16. Search
  // ─────────────────────────────────────────────────────────────────────────

  group('MarketStatus.search()', () {
    test('finds gold markets', () {
      final results = MarketStatus.search('gold');
      final codes = results.map((d) => d.code).toList();

      expect(codes, containsAll(['MCX_GOLD', 'COMEX_GOLD']));
    });

    test('finds crude oil markets', () {
      final results = MarketStatus.search('crude');
      final codes = results.map((d) => d.code).toList();

      expect(codes, containsAll(['MCX_CRUDE', 'NYMEX_CRUDE']));
    });

    test('finds by exchange code', () {
      final results = MarketStatus.search('NSE');
      expect(results.any((d) => d.code == 'NSE'), isTrue);
    });

    test('returns empty for unknown query', () {
      final results = MarketStatus.search('zzz_unknown_market_xyz');
      expect(results, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 17. Categories
  // ─────────────────────────────────────────────────────────────────────────

  group('MarketStatus.categories()', () {
    test('returns all 4 market types', () {
      final cats = MarketStatus.categories();

      expect(cats, containsAll([
        MarketType.stockExchange,
        MarketType.commodityExchange,
        MarketType.futuresExchange,
        MarketType.cryptoExchange,
      ]));
    });
  });

  group('MarketStatus.marketsByCategory()', () {
    test('stock exchanges include NSE, NYSE, LSE', () {
      final stocks = MarketStatus.marketsByCategory(MarketType.stockExchange);
      final codes = stocks.map((d) => d.code).toList();

      expect(codes, containsAll(['NSE', 'NYSE', 'LSE']));
    });

    test('crypto exchanges are all 24×7', () {
      final cryptos =
          MarketStatus.marketsByCategory(MarketType.cryptoExchange);

      for (final d in cryptos) {
        expect(d.is24x7, isTrue,
            reason: '${d.code} should be 24×7');
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 18. Market models / serialisation
  // ─────────────────────────────────────────────────────────────────────────

  group('Model serialisation', () {
    test('TradingSession round-trips via JSON', () {
      const session = TradingSession(
        name: 'Regular',
        type: SessionType.regular,
        openTime: '09:15',
        closeTime: '15:30',
      );
      final json = session.toJson();
      final restored = TradingSession.fromJson(json);

      expect(restored.name, session.name);
      expect(restored.openTime, session.openTime);
      expect(restored.closeTime, session.closeTime);
      expect(restored.type, session.type);
    });

    test('Holiday round-trips via JSON', () {
      final holiday = Holiday(
        date: DateTime(2026, 1, 26),
        type: HolidayType.holiday,
        reason: 'Republic Day',
      );
      final json = holiday.toJson();
      final restored = Holiday.fromJson(json);

      expect(restored.reason, holiday.reason);
      expect(restored.type, holiday.type);
      expect(restored.date, holiday.date);
    });

    test('Holiday earlyClose parses close time', () {
      final json = {
        'date': '2026-11-27',
        'type': 'early_close',
        'reason': 'Diwali Muhurat',
        'close': '18:15',
      };
      final h = Holiday.fromJson(json);

      expect(h.type, HolidayType.earlyClose);
      expect(h.closeTime, '18:15');
    });

    test('MarketDefinition round-trips via JSON', () {
      final def = MarketRegistry.definitionFor(Markets.nse);
      final json = def.toJson();
      final restored = MarketDefinition.fromJson(json);

      expect(restored.code, def.code);
      expect(restored.timezone, def.timezone);
      expect(restored.sessions.length, def.sessions.length);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 19. Registry
  // ─────────────────────────────────────────────────────────────────────────

  group('MarketRegistry', () {
    test('all Markets enum values have a definition', () {
      for (final m in Markets.values) {
        expect(
          () => MarketRegistry.definitionFor(m),
          returnsNormally,
          reason: '$m should have a built-in definition',
        );
      }
    });

    test('clearOverrides reverts to built-in definition', () {
      final original = MarketRegistry.definitionFor(Markets.nse);
      final overridden = MarketDefinition(
        code: 'NSE',
        name: 'Overridden NSE',
        type: MarketType.stockExchange,
        timezone: 'Asia/Kolkata',
        sessions: original.sessions,
      );

      MarketRegistry.applyOverride(Markets.nse, overridden);
      expect(MarketRegistry.definitionFor(Markets.nse).name, 'Overridden NSE');

      MarketRegistry.clearOverrides();
      expect(MarketRegistry.definitionFor(Markets.nse).name, original.name);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 20. Streaming
  // ─────────────────────────────────────────────────────────────────────────

  group('MarketStatus.watch()', () {
    test('emits at least one state', () async {
      configureFixed(utcTime: utc('2026-01-19 10:00', 'Asia/Kolkata'));

      final state = await MarketStatus.watch(
        Markets.nse,
        interval: const Duration(milliseconds: 100),
      ).first;

      expect(state.marketCode, 'NSE');
      expect(state.isOpen, isTrue);
    });
  });
}

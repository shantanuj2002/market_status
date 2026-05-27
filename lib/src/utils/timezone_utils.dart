import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Utility helpers for timezone-aware date/time operations.
///
/// Wraps the `timezone` package to avoid scattering `tz.*` calls throughout
/// the codebase.
class TimezoneUtils {
  TimezoneUtils._();

  static bool _initialized = false;

  /// Must be called once before using any timezone functionality.
  /// Safe to call multiple times.
  static void init() {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    _initialized = true;
  }

  /// Converts a UTC [DateTime] to the given IANA [timezone].
  ///
  /// Returns the local time in that timezone, with the [DateTime] set to the
  /// correct offset. Treats the timezone as UTC if the identifier is unknown.
  static DateTime toLocalTime(DateTime utc, String timezone) {
    init();
    try {
      final location = tz.getLocation(timezone);
      final tzDateTime = tz.TZDateTime.from(utc, location);
      // Return a plain DateTime in local representation (no TZDateTime leaking)
      return DateTime(
        tzDateTime.year,
        tzDateTime.month,
        tzDateTime.day,
        tzDateTime.hour,
        tzDateTime.minute,
        tzDateTime.second,
        tzDateTime.millisecond,
      );
    } catch (_) {
      // Unknown timezone — fall back to UTC
      return utc;
    }
  }

  /// Returns the UTC offset Duration for an IANA timezone at a given [utc] moment.
  /// Correctly accounts for DST transitions.
  static Duration utcOffset(String timezone, DateTime utc) {
    init();
    try {
      final location = tz.getLocation(timezone);
      final tzDateTime = tz.TZDateTime.from(utc, location);
      return Duration(seconds: tzDateTime.timeZoneOffset.inSeconds);
    } catch (_) {
      return Duration.zero;
    }
  }

  /// Returns true if [a] and [b] are the same calendar day in UTC.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Returns true if [a] and [b] are the same calendar day in the given timezone.
  static bool isSameDayInZone(DateTime utcA, DateTime utcB, String timezone) {
    final localA = toLocalTime(utcA, timezone);
    final localB = toLocalTime(utcB, timezone);
    return isSameDay(localA, localB);
  }

  /// Adds [days] calendar days to [date] in the context of [timezone],
  /// correctly handling DST transitions.
  static DateTime addDaysInZone(DateTime utcDate, int days, String timezone) {
    init();
    try {
      final location = tz.getLocation(timezone);
      final local = tz.TZDateTime.from(utcDate, location);
      final shifted = tz.TZDateTime(
        location,
        local.year,
        local.month,
        local.day + days,
        local.hour,
        local.minute,
      );
      return shifted.toUtc();
    } catch (_) {
      return utcDate.add(Duration(days: days));
    }
  }

  /// Builds a UTC DateTime from a local date + time string ("HH:MM") in [timezone].
  static DateTime localTimeToUtc(
      DateTime localDate, String hhmm, String timezone) {
    init();
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    try {
      final location = tz.getLocation(timezone);
      final local = tz.TZDateTime(
        location,
        localDate.year,
        localDate.month,
        localDate.day,
        h,
        m,
      );
      return local.toUtc();
    } catch (_) {
      return DateTime.utc(localDate.year, localDate.month, localDate.day, h, m);
    }
  }
}

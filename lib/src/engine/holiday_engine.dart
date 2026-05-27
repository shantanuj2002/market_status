import '../models/holiday.dart';
import '../providers/holiday_provider.dart';
import '../utils/timezone_utils.dart';

/// Result from the holiday engine for a specific market day.
class HolidayResult {
  /// Whether the day is a full closure / holiday.
  final bool isHoliday;

  /// The [Holiday] entry that applies today (if any).
  final Holiday? holiday;

  /// Overridden close time (e.g. early close), or null if normal.
  final String? overrideCloseTime;

  /// Overridden open time (e.g. delayed open), or null if normal.
  final String? overrideOpenTime;

  const HolidayResult({
    required this.isHoliday,
    this.holiday,
    this.overrideCloseTime,
    this.overrideOpenTime,
  });

  static const HolidayResult normal = HolidayResult(isHoliday: false);
}

/// Looks up holiday / special-day data and determines whether the market
/// is affected on a given exchange-local date.
class HolidayEngine {
  final HolidayProvider _provider;

  const HolidayEngine(this._provider);

  /// Checks whether [utcNow] maps to a holiday or special day for [marketCode]
  /// in [exchangeTimezone].
  Future<HolidayResult> check(
      String marketCode, String exchangeTimezone, DateTime utcNow) async {
    final localDate = TimezoneUtils.toLocalTime(utcNow, exchangeTimezone);
    final holidays = await _provider.getHolidays(marketCode, localDate.year);

    for (final h in holidays) {
      if (h.matchesDate(localDate)) {
        switch (h.type) {
          case HolidayType.holiday:
          case HolidayType.emergencyClosure:
            return HolidayResult(
              isHoliday: true,
              holiday: h,
            );
          case HolidayType.earlyClose:
            return HolidayResult(
              isHoliday: false,
              holiday: h,
              overrideCloseTime: h.closeTime,
            );
          case HolidayType.delayedOpen:
            return HolidayResult(
              isHoliday: false,
              holiday: h,
              overrideOpenTime: h.openTime,
            );
          case HolidayType.specialSession:
            return HolidayResult(
              isHoliday: false,
              holiday: h,
              overrideOpenTime: h.openTime,
              overrideCloseTime: h.closeTime,
            );
        }
      }
    }
    return HolidayResult.normal;
  }
}

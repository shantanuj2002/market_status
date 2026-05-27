/// Types of special calendar entries.
enum HolidayType {
  /// Full-day market closure (public holiday, exchange holiday).
  holiday,

  /// Market closes earlier than normal — see [Holiday.closeTime].
  earlyClose,

  /// Market opens later than normal — see [Holiday.openTime].
  delayedOpen,

  /// Exchange-declared emergency closure (mid-day or full day).
  emergencyClosure,

  /// Special trading session with non-standard hours.
  specialSession,
}

/// A calendar entry describing a holiday or special trading day.
class Holiday {
  /// Calendar date, e.g. `2026-01-26`.
  final DateTime date;

  /// Entry type.
  final HolidayType type;

  /// Human-readable reason, e.g. `"Republic Day"`.
  final String reason;

  /// Overridden close time for [HolidayType.earlyClose], `"HH:MM"`.
  final String? closeTime;

  /// Overridden open time for [HolidayType.delayedOpen], `"HH:MM"`.
  final String? openTime;

  const Holiday({
    required this.date,
    required this.type,
    required this.reason,
    this.closeTime,
    this.openTime,
  });

  /// Returns true if [date] matches [other] by year-month-day only.
  bool matchesDate(DateTime other) =>
      date.year == other.year &&
      date.month == other.month &&
      date.day == other.day;

  Map<String, dynamic> toJson() => {
        'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'type': type.name,
        'reason': reason,
        if (closeTime != null) 'close': closeTime,
        if (openTime != null) 'open': openTime,
      };

  factory Holiday.fromJson(Map<String, dynamic> json) {
    final dateParts = (json['date'] as String).split('-');
    final date = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );

    HolidayType type = HolidayType.holiday;
    final typeStr = json['type'] as String? ?? 'holiday';
    // Support both holiday-list format ("holiday") and special-day format
    if (typeStr == 'early_close' || typeStr == 'earlyClose') {
      type = HolidayType.earlyClose;
    } else if (typeStr == 'delayed_open' || typeStr == 'delayedOpen') {
      type = HolidayType.delayedOpen;
    } else if (typeStr == 'emergency_closure' || typeStr == 'emergencyClosure') {
      type = HolidayType.emergencyClosure;
    } else if (typeStr == 'special_session' || typeStr == 'specialSession') {
      type = HolidayType.specialSession;
    }

    return Holiday(
      date: date,
      type: type,
      reason: json['reason'] as String? ?? '',
      closeTime: json['close'] as String?,
      openTime: json['open'] as String?,
    );
  }

  @override
  String toString() => 'Holiday(${toJson()['date']}, ${type.name}, $reason)';
}

import 'session_type.dart';

/// A single continuous trading window within a trading day.
///
/// Times are expressed in the exchange's local timezone as
/// `HH:MM` 24-hour strings (e.g. `"09:15"`, `"15:30"`).
class TradingSession {
  /// Human-readable name, e.g. "Regular", "Pre-Market", "Morning".
  final String name;

  /// Session category used for programmatic classification.
  final SessionType type;

  /// Session open time in exchange-local 24-hour format `"HH:MM"`.
  final String openTime;

  /// Session close time in exchange-local 24-hour format `"HH:MM"`.
  final String closeTime;

  const TradingSession({
    required this.name,
    required this.type,
    required this.openTime,
    required this.closeTime,
  });

  /// Parse minutes-since-midnight from an `"HH:MM"` string.
  static int parseMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int get openMinutes => parseMinutes(openTime);
  int get closeMinutes => parseMinutes(closeTime);

  /// Returns true if the given [minuteOfDay] (minutes since midnight in the
  /// exchange's timezone) falls within this session, inclusive of open,
  /// exclusive of close.
  bool containsMinute(int minuteOfDay) {
    return minuteOfDay >= openMinutes && minuteOfDay < closeMinutes;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.name,
        'openTime': openTime,
        'closeTime': closeTime,
      };

  factory TradingSession.fromJson(Map<String, dynamic> json) => TradingSession(
        name: json['name'] as String,
        type: SessionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => SessionType.regular,
        ),
        openTime: json['openTime'] as String,
        closeTime: json['closeTime'] as String,
      );

  @override
  String toString() =>
      'TradingSession($name, $openTime–$closeTime, ${type.name})';
}

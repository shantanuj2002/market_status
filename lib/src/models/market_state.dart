import 'market_type.dart';
import 'session_type.dart';

/// The complete real-time state of a market at a given moment.
///
/// Returned by [MarketStatusApi.market] and emitted by [MarketStatusApi.watch].
class MarketState {
  // ── Identity ────────────────────────────────────────────────────────────────

  /// Short market code, e.g. `"NSE"`, `"COMEX_GOLD"`.
  final String marketCode;

  /// Display name, e.g. `"National Stock Exchange of India"`.
  final String marketName;

  /// Market category.
  final MarketType marketType;

  // ── Status ──────────────────────────────────────────────────────────────────

  /// Whether the market is currently accepting orders.
  final bool isOpen;

  /// Whether today is an exchange holiday.
  final bool isHoliday;

  /// Reason for today being a holiday / closure (if applicable).
  final String? holidayReason;

  /// Whether the market is currently in a special session
  /// (e.g. Muhurat trading, half-day special session).
  final bool isSpecialSession;

  /// Name/reason of the special session, e.g. `"Muhurat Trading"`.
  /// Non-null only when [isSpecialSession] is true.
  final String? specialSessionReason;

  // ── Timing ──────────────────────────────────────────────────────────────────

  /// Time remaining until the current session closes.
  /// `null` when the market is closed.
  final Duration? timeToClose;

  /// Time until the next session opens.
  /// `null` when the market is currently open.
  final Duration? timeToOpen;

  /// The next UTC [DateTime] at which the market will open.
  final DateTime? nextOpen;

  /// The next UTC [DateTime] at which the market will close.
  final DateTime? nextClose;

  // ── Session ─────────────────────────────────────────────────────────────────

  /// The session the market is currently in (null when closed).
  final SessionType? currentSession;

  /// The next session that will open (null for 24×7 markets).
  final SessionType? nextSession;

  // ── Timezone ─────────────────────────────────────────────────────────────────

  /// IANA timezone of the exchange, e.g. `"Asia/Kolkata"`.
  final String exchangeTimezone;

  /// IANA timezone of the user's device.
  final String userTimezone;

  /// True when device timezone and IP-resolved timezone differ.
  final bool timezoneMismatch;

  /// IP-resolved timezone (may be null if not yet resolved).
  final String? ipTimezone;

  // ── Snapshot time ────────────────────────────────────────────────────────────

  /// The exchange-local [DateTime] at which this state was computed.
  final DateTime exchangeTime;

  /// The UTC [DateTime] at which this state was computed.
  final DateTime utcTime;

  const MarketState({
    required this.marketCode,
    required this.marketName,
    required this.marketType,
    required this.isOpen,
    required this.isHoliday,
    this.holidayReason,
    this.isSpecialSession = false,
    this.specialSessionReason,
    this.timeToClose,
    this.timeToOpen,
    this.nextOpen,
    this.nextClose,
    this.currentSession,
    this.nextSession,
    required this.exchangeTimezone,
    required this.userTimezone,
    this.timezoneMismatch = false,
    this.ipTimezone,
    required this.exchangeTime,
    required this.utcTime,
  });

  @override
  String toString() {
    final status = isOpen ? 'OPEN' : 'CLOSED';
    return 'MarketState($marketCode $status, holiday=$isHoliday, '
        'ttc=$timeToClose, tto=$timeToOpen)';
  }
}

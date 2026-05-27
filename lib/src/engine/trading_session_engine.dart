import '../models/market_definition.dart';
import '../models/trading_session.dart';
import '../models/session_type.dart';
import '../utils/timezone_utils.dart';

/// Result from the session engine for a given moment.
class SessionResult {
  /// The active session, or null if the market is between sessions / closed.
  final TradingSession? activeSession;

  /// The next upcoming session (on the same or a future trading day).
  final TradingSession? nextSession;

  /// UTC time when the active session closes (null if closed).
  final DateTime? sessionCloseUtc;

  /// UTC time when the next session opens (null if 24×7 always-open).
  final DateTime? nextOpenUtc;

  const SessionResult({
    this.activeSession,
    this.nextSession,
    this.sessionCloseUtc,
    this.nextOpenUtc,
  });

  bool get isOpen => activeSession != null;
}

/// Determines which trading session is active at a given UTC time
/// for a given [MarketDefinition], respecting the exchange's timezone.
class TradingSessionEngine {
  const TradingSessionEngine();

  /// Evaluates session status for [market] at [utcNow].
  ///
  /// Returns a [SessionResult] with the current session (if any) and the next
  /// upcoming open time.
  SessionResult evaluate(MarketDefinition market, DateTime utcNow) {
    // 24×7 markets are always open
    if (market.is24x7) {
      return SessionResult(
        activeSession: market.sessions.first,
        nextSession: null,
        sessionCloseUtc: null,
        nextOpenUtc: null,
      );
    }

    final localNow = TimezoneUtils.toLocalTime(utcNow, market.timezone);
    final minuteOfDay = localNow.hour * 60 + localNow.minute;
    final weekday = localNow.weekday; // 1=Mon, 7=Sun

    // Check if today is a trading day
    if (!market.tradingDays.contains(weekday)) {
      return _closedResult(market, utcNow, localNow);
    }

    // Find active session
    for (final session in market.sessions) {
      // Handle normal (non-wrapping) sessions
      if (session.openMinutes < session.closeMinutes) {
        if (session.containsMinute(minuteOfDay)) {
          final closeUtc = TimezoneUtils.localTimeToUtc(
              localNow, session.closeTime, market.timezone);
          final nextSession = _nextSessionAfter(market, session, utcNow, localNow);
          return SessionResult(
            activeSession: session,
            nextSession: nextSession?.session,
            sessionCloseUtc: closeUtc,
            nextOpenUtc: nextSession?.openUtc,
          );
        }
      } else {
        // Wrapping session (e.g. 18:00 → 17:15 next day — Globex)
        // Active if minute >= open OR minute < close
        if (minuteOfDay >= session.openMinutes ||
            minuteOfDay < session.closeMinutes) {
          DateTime closeUtc;
          if (minuteOfDay >= session.openMinutes) {
            // We're in the evening portion — close is tomorrow
            final tomorrow = localNow.add(const Duration(days: 1));
            closeUtc = TimezoneUtils.localTimeToUtc(
                tomorrow, session.closeTime, market.timezone);
          } else {
            closeUtc = TimezoneUtils.localTimeToUtc(
                localNow, session.closeTime, market.timezone);
          }
          return SessionResult(
            activeSession: session,
            nextSession: null,
            sessionCloseUtc: closeUtc,
            nextOpenUtc: null,
          );
        }
      }
    }

    // Not in any session — find next open
    return _closedResult(market, utcNow, localNow);
  }

  SessionResult _closedResult(
      MarketDefinition market, DateTime utcNow, DateTime localNow) {
    final next = _nextOpenSession(market, utcNow, localNow);
    return SessionResult(
      activeSession: null,
      nextSession: next?.session,
      sessionCloseUtc: null,
      nextOpenUtc: next?.openUtc,
    );
  }

  _SessionOpen? _nextOpenSession(
      MarketDefinition market, DateTime utcNow, DateTime localNow) {
    final minuteOfDay = localNow.hour * 60 + localNow.minute;

    // Try sessions later today (same day)
    if (market.tradingDays.contains(localNow.weekday)) {
      for (final session in market.sessions) {
        if (session.openMinutes > minuteOfDay) {
          final openUtc = TimezoneUtils.localTimeToUtc(
              localNow, session.openTime, market.timezone);
          return _SessionOpen(session, openUtc);
        }
      }
    }

    // Walk forward up to 7 days to find the next trading day
    for (var d = 1; d <= 7; d++) {
      final futureLocal = TimezoneUtils.addDaysInZone(utcNow, d, market.timezone);
      final futureLocalDt = TimezoneUtils.toLocalTime(futureLocal, market.timezone);
      if (market.tradingDays.contains(futureLocalDt.weekday)) {
        final firstSession = market.sessions.first;
        final openUtc = TimezoneUtils.localTimeToUtc(
            futureLocalDt, firstSession.openTime, market.timezone);
        return _SessionOpen(firstSession, openUtc);
      }
    }
    return null;
  }

  _SessionOpen? _nextSessionAfter(
      MarketDefinition market,
      TradingSession current,
      DateTime utcNow,
      DateTime localNow) {
    final currentIndex = market.sessions.indexOf(current);

    // Any sessions later in the same day?
    for (var i = currentIndex + 1; i < market.sessions.length; i++) {
      final s = market.sessions[i];
      final openUtc =
          TimezoneUtils.localTimeToUtc(localNow, s.openTime, market.timezone);
      return _SessionOpen(s, openUtc);
    }

    // Next trading day
    return _nextOpenSession(market, utcNow, localNow);
  }
}

class _SessionOpen {
  final TradingSession session;
  final DateTime openUtc;
  const _SessionOpen(this.session, this.openUtc);
}

import 'dart:async';
import '../models/market_definition.dart';
import '../models/market_state.dart';
import '../models/session_type.dart';
import '../models/timezone_mode.dart';
import '../models/trading_session.dart';
import '../models/holiday.dart';
import '../providers/time_provider.dart';
import '../providers/timezone_provider.dart';
import '../providers/holiday_provider.dart';
import '../utils/timezone_utils.dart';
import 'trading_session_engine.dart';
import 'holiday_engine.dart';

/// Core computation engine.
///
/// Combines [TradingSessionEngine], [HolidayEngine], and timezone providers
/// to produce a [MarketState] for any [MarketDefinition] at any point in time.
class MarketEngine {
  final TimeProvider _timeProvider;
  final TimezoneProvider _deviceTimezoneProvider;
  final TimezoneProvider? _ipTimezoneProvider;
  final TimezoneMode _timezoneMode;

  final TradingSessionEngine _sessionEngine;
  late final HolidayEngine _holidayEngine;

  // Cache IP timezone to avoid repeated network calls per session
  String? _cachedIpTimezone;
  DateTime? _ipTimezoneCachedAt;
  static const _ipCacheDuration = Duration(minutes: 30);

  MarketEngine({
    required TimeProvider timeProvider,
    required TimezoneProvider deviceTimezoneProvider,
    /// Only required when [timezoneMode] is [TimezoneMode.deviceWithIpVerification].
    TimezoneProvider? ipTimezoneProvider,
    required HolidayProvider holidayProvider,
    TimezoneMode timezoneMode = TimezoneMode.deviceOnly,
  })  : _timeProvider = timeProvider,
        _deviceTimezoneProvider = deviceTimezoneProvider,
        _ipTimezoneProvider = ipTimezoneProvider,
        _timezoneMode = timezoneMode,
        _sessionEngine = const TradingSessionEngine() {
    _holidayEngine = HolidayEngine(holidayProvider);
  }

  /// Computes the full [MarketState] for [market] at the current moment.
  Future<MarketState> compute(MarketDefinition market) async {
    TimezoneUtils.init();

    final utcNow = await _timeProvider.nowUtc();
    final deviceTz = await _deviceTimezoneProvider.getTimezone() ?? 'UTC';

    // IP timezone is only resolved when the developer explicitly opts in.
    // In deviceOnly mode: no network call, no mismatch flag, ipTimezone = null.
    String? ipTz;
    bool timezoneMismatch = false;

    if (_timezoneMode == TimezoneMode.deviceWithIpVerification) {
      ipTz = await _resolveIpTimezone();
      timezoneMismatch = ipTz != null && ipTz != deviceTz;
    }

    final localExchangeTime =
        TimezoneUtils.toLocalTime(utcNow, market.timezone);

    // ── Holiday check ───────────────────────────────────────────────────────
    final holidayResult =
        await _holidayEngine.check(market.code, market.timezone, utcNow);

    if (holidayResult.isHoliday) {
      // Find next open after the holiday
      final nextOpenUtc =
          await _findNextOpenAfterHoliday(market, utcNow);
      return MarketState(
        marketCode: market.code,
        marketName: market.name,
        marketType: market.type,
        isOpen: false,
        isHoliday: true,
        holidayReason: holidayResult.holiday?.reason,
        isSpecialSession: false,
        timeToClose: null,
        timeToOpen: nextOpenUtc != null
            ? nextOpenUtc.difference(utcNow)
            : null,
        nextOpen: nextOpenUtc,
        nextClose: null,
        currentSession: null,
        nextSession: null,
        exchangeTimezone: market.timezone,
        userTimezone: deviceTz,
        timezoneMismatch: timezoneMismatch,
        ipTimezone: ipTz,
        exchangeTime: localExchangeTime,
        utcTime: utcNow,
      );
    }

    // ── Session evaluation ──────────────────────────────────────────────────
    var sessionResult = _sessionEngine.evaluate(market, utcNow);

    // ── Apply special-day overrides ─────────────────────────────────────────
    //
    // specialSession (e.g. Muhurat trading 18:00–19:00):
    //   Completely replaces normal session logic. The special window is the
    //   ONLY valid session for this day, regardless of normal hours.
    //
    // earlyClose:
    //   Trims the close time of the active session.
    //
    // delayedOpen:
    //   Market stays closed until the overridden open time, even if normal
    //   hours have already started.

    if (holidayResult.holiday?.type == HolidayType.specialSession &&
        holidayResult.overrideOpenTime != null &&
        holidayResult.overrideCloseTime != null) {
      sessionResult = _applySpecialSession(
        market,
        holidayResult.overrideOpenTime!,
        holidayResult.overrideCloseTime!,
        utcNow,
      );
    } else {
      if (holidayResult.overrideCloseTime != null && sessionResult.isOpen) {
        sessionResult = _applyEarlyClose(
            market, sessionResult, holidayResult.overrideCloseTime!, utcNow);
      }
      if (holidayResult.overrideOpenTime != null) {
        sessionResult = _applyDelayedOpen(
            market, sessionResult, holidayResult.overrideOpenTime!, utcNow);
      }
    }

    // ── Build and return MarketState ────────────────────────────────────────
    final isSpecial = holidayResult.holiday?.type == HolidayType.specialSession;
    final isOpen = sessionResult.isOpen;
    final nextOpenUtc = sessionResult.nextOpenUtc;
    final nextCloseUtc = sessionResult.sessionCloseUtc;

    return MarketState(
      marketCode: market.code,
      marketName: market.name,
      marketType: market.type,
      isOpen: isOpen,
      isHoliday: false,
      holidayReason: null,
      isSpecialSession: isOpen && isSpecial,
      specialSessionReason: (isOpen && isSpecial)
          ? holidayResult.holiday?.reason
          : null,
      timeToClose:
          isOpen && nextCloseUtc != null ? nextCloseUtc.difference(utcNow) : null,
      timeToOpen:
          !isOpen && nextOpenUtc != null ? nextOpenUtc.difference(utcNow) : null,
      nextOpen: isOpen ? null : nextOpenUtc,
      nextClose: isOpen ? nextCloseUtc : null,
      currentSession: sessionResult.activeSession?.type,
      nextSession: sessionResult.nextSession?.type,
      exchangeTimezone: market.timezone,
      userTimezone: deviceTz,
      timezoneMismatch: timezoneMismatch,
      ipTimezone: ipTz,
      exchangeTime: localExchangeTime,
      utcTime: utcNow,
    );
  }

  /// Returns a [Stream] that emits an updated [MarketState] every [interval].
  Stream<MarketState> watch(
    MarketDefinition market, {
    Duration interval = const Duration(seconds: 30),
  }) {
    late StreamController<MarketState> controller;
    Timer? timer;

    Future<void> emit() async {
      try {
        final state = await compute(market);
        if (!controller.isClosed) {
          controller.add(state);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    controller = StreamController<MarketState>(
      onListen: () async {
        await emit();
        timer = Timer.periodic(interval, (_) => emit());
      },
      onCancel: () {
        timer?.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<String?> _resolveIpTimezone() async {
    // Guard: should only be called in deviceWithIpVerification mode,
    // but defensive-check here too.
    if (_timezoneMode == TimezoneMode.deviceOnly ||
        _ipTimezoneProvider == null) {
      return null;
    }
    final now = DateTime.now();
    if (_cachedIpTimezone != null &&
        _ipTimezoneCachedAt != null &&
        now.difference(_ipTimezoneCachedAt!) < _ipCacheDuration) {
      return _cachedIpTimezone;
    }
    final tz = await _ipTimezoneProvider!.getTimezone();
    if (tz != null) {
      _cachedIpTimezone = tz;
      _ipTimezoneCachedAt = now;
    }
    return tz;
  }

  /// Walks forward in time (up to 14 days) to find the next market open,
  /// skipping holiday and non-trading days.
  Future<DateTime?> _findNextOpenAfterHoliday(
      MarketDefinition market, DateTime utcNow) async {
    for (var d = 1; d <= 14; d++) {
      final candidate =
          TimezoneUtils.addDaysInZone(utcNow, d, market.timezone);
      final candidateLocal =
          TimezoneUtils.toLocalTime(candidate, market.timezone);

      if (!market.tradingDays.contains(candidateLocal.weekday)) continue;

      final hResult = await _holidayEngine.check(
          market.code, market.timezone, candidate);
      if (hResult.isHoliday) continue;

      // Use the override open time if it's a delayed open
      final openTime = hResult.overrideOpenTime ??
          market.sessions.first.openTime;
      return TimezoneUtils.localTimeToUtc(
          candidateLocal, openTime, market.timezone);
    }
    return null;
  }

  SessionResult _applyEarlyClose(
      MarketDefinition market,
      SessionResult original,
      String earlyCloseTime,
      DateTime utcNow) {
    final localNow = TimezoneUtils.toLocalTime(utcNow, market.timezone);
    final earlyCloseUtc =
        TimezoneUtils.localTimeToUtc(localNow, earlyCloseTime, market.timezone);
    // If we're already past the early close time, market is closed
    if (utcNow.isAfter(earlyCloseUtc)) {
      return SessionResult(
        activeSession: null,
        nextSession: null,
        sessionCloseUtc: null,
        nextOpenUtc: null,
      );
    }
    return SessionResult(
      activeSession: original.activeSession,
      nextSession: original.nextSession,
      sessionCloseUtc: earlyCloseUtc,
      nextOpenUtc: original.nextOpenUtc,
    );
  }

  SessionResult _applyDelayedOpen(
      MarketDefinition market,
      SessionResult original,
      String delayedOpenTime,
      DateTime utcNow) {
    final localNow = TimezoneUtils.toLocalTime(utcNow, market.timezone);
    final delayedOpenUtc =
        TimezoneUtils.localTimeToUtc(localNow, delayedOpenTime, market.timezone);

    // If current time is before the delayed open, market should be closed
    if (utcNow.isBefore(delayedOpenUtc)) {
      return SessionResult(
        activeSession: null,
        nextSession: original.nextSession,
        sessionCloseUtc: null,
        nextOpenUtc: delayedOpenUtc,
      );
    }
    // After delayed open time — pass through original result
    return original;
  }
}

  /// Handles a special session like Muhurat trading — a completely independent
  /// time window that replaces normal session logic for the day.
  ///
  /// Examples:
  ///   - Muhurat: NSE/BSE open 18:00–19:00 IST on Diwali
  ///   - Half-day special: some exchange trades 09:00–12:00 instead of normal hours
  ///
  /// The engine ignores normal session hours entirely and only honours the
  /// [openTime]–[closeTime] window for this day.
  SessionResult _applySpecialSession(
    MarketDefinition market,
    String openTime,
    String closeTime,
    DateTime utcNow,
  ) {
    final localNow = TimezoneUtils.toLocalTime(utcNow, market.timezone);
    final openUtc  = TimezoneUtils.localTimeToUtc(localNow, openTime,  market.timezone);
    final closeUtc = TimezoneUtils.localTimeToUtc(localNow, closeTime, market.timezone);

    // Inside the special window
    if (!utcNow.isBefore(openUtc) && utcNow.isBefore(closeUtc)) {
      final specialSession = TradingSession(
        name:      'Special Session',
        type:      SessionType.special,
        openTime:  openTime,
        closeTime: closeTime,
      );
      return SessionResult(
        activeSession:    specialSession,
        nextSession:      null,
        sessionCloseUtc:  closeUtc,
        nextOpenUtc:      null,
      );
    }

    // Before the special window opens
    if (utcNow.isBefore(openUtc)) {
      return SessionResult(
        activeSession: null,
        nextSession:   null,
        sessionCloseUtc: null,
        nextOpenUtc:   openUtc,
      );
    }

    // After the special window has closed — market is done for the day
    return const SessionResult(
      activeSession:   null,
      nextSession:     null,
      sessionCloseUtc: null,
      nextOpenUtc:     null,
    );
  }

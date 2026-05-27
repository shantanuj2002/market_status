import 'dart:async';
import 'models/market_state.dart';
import 'models/market_definition.dart';
import 'models/market_type.dart';
import 'models/timezone_mode.dart';
import 'markets/markets.dart';
import 'providers/time_provider.dart';
import 'providers/timezone_provider.dart';
import 'providers/holiday_provider.dart';
import 'engine/market_engine.dart';
import 'sync/calendar_sync.dart';
import 'data/default_holidays.dart';

/// Primary entry point for the market_status package.
///
/// ## Quick start — device-only (default, no network for timezone)
///
/// ```dart
/// final state = await MarketStatus.market(Markets.nse);
/// print(state.isOpen);
/// print(state.timeToClose);
/// print(state.nextOpen);
/// ```
///
/// ## Opt-in: IP timezone verification (detects VPN / wrong device clock)
///
/// ```dart
/// MarketStatus.configure(
///   timezoneMode: TimezoneMode.deviceWithIpVerification,
/// );
///
/// final state = await MarketStatus.market(Markets.nse);
/// if (state.timezoneMismatch) {
///   print('Device: ${state.userTimezone}, IP: ${state.ipTimezone}');
/// }
/// ```
class MarketStatus {
  MarketStatus._();

  // ── Singleton engine ────────────────────────────────────────────────────────

  static MarketEngine? _engine;
  static CachedHolidayProvider? _cachedHolidayProvider;

  /// Configures the package-level engine.
  ///
  /// Call this once at app startup before any [market] / [all] / [watch] calls.
  /// All parameters are optional — omit any to keep the default.
  ///
  /// ### Timezone modes
  ///
  /// ```dart
  /// // Default — device clock only, zero network calls for timezone
  /// MarketStatus.configure(
  ///   timezoneMode: TimezoneMode.deviceOnly,
  /// );
  ///
  /// // Opt-in — verify device timezone against IP geolocation
  /// MarketStatus.configure(
  ///   timezoneMode: TimezoneMode.deviceWithIpVerification,
  /// );
  /// ```
  ///
  /// ### Custom providers (useful for testing)
  ///
  /// ```dart
  /// MarketStatus.configure(
  ///   timeProvider: FixedTimeProvider(DateTime.utc(2026, 1, 19, 4, 30)),
  ///   deviceTimezoneProvider: FixedTimezoneProvider('Asia/Kolkata'),
  ///   holidayProvider: LocalHolidayProvider(DefaultHolidays.all),
  /// );
  /// ```
  static void configure({
    TimezoneMode timezoneMode = TimezoneMode.deviceOnly,
    TimeProvider? timeProvider,
    TimezoneProvider? deviceTimezoneProvider,
    /// Only used when [timezoneMode] is [TimezoneMode.deviceWithIpVerification].
    /// Defaults to [IpTimezoneProvider] (ipinfo.io) when not supplied.
    TimezoneProvider? ipTimezoneProvider,
    HolidayProvider? holidayProvider,
  }) {
    _engine = MarketEngine(
      timezoneMode: timezoneMode,
      timeProvider: timeProvider ?? const DeviceTimeProvider(),
      deviceTimezoneProvider:
          deviceTimezoneProvider ?? const DeviceTimezoneProvider(),
      ipTimezoneProvider: timezoneMode == TimezoneMode.deviceWithIpVerification
          ? (ipTimezoneProvider ?? IpTimezoneProvider())
          : null,
      holidayProvider: holidayProvider ?? _defaultHolidayProvider(),
    );
  }

  static MarketEngine get _defaultEngine {
    // Default: deviceOnly — no IP network call, no mismatch detection.
    // Developer must explicitly opt in to deviceWithIpVerification.
    _engine ??= MarketEngine(
      timezoneMode: TimezoneMode.deviceOnly,
      timeProvider: const DeviceTimeProvider(),
      deviceTimezoneProvider: const DeviceTimezoneProvider(),
      ipTimezoneProvider: null,
      holidayProvider: _defaultHolidayProvider(),
    );
    return _engine!;
  }

  /// Default holiday provider chain:
  ///   1. CachedHolidayProvider  — data downloaded by syncCalendars()
  ///   2. LocalHolidayProvider   — embedded 2025–2027 defaults (always available)
  static HolidayProvider _defaultHolidayProvider() {
    _cachedHolidayProvider = CachedHolidayProvider();
    return CompositeHolidayProvider([
      _cachedHolidayProvider!,
      LocalHolidayProvider(DefaultHolidays.all),
    ]);
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Initialises the package at app startup.
  ///
  /// Loads any previously-cached market definitions from [SharedPreferences]
  /// so updated trading hours are active immediately — even offline.
  ///
  /// Call this **before** the first [market] / [all] / [watch] call,
  /// then call [syncCalendars] to fetch any updates.
  ///
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///
  ///   // Load cached definitions instantly (no network)
  ///   await MarketStatus.init();
  ///
  ///   runApp(MyApp());
  ///
  ///   // Sync in background after first frame
  ///   WidgetsBinding.instance.addPostFrameCallback((_) {
  ///     MarketStatus.syncCalendars(markets: [Markets.nse, Markets.nyse]);
  ///   });
  /// }
  /// ```
  static Future<void> init() async {
    await CalendarSync.applyCachedDefinitions();
  }

  /// Returns the current [MarketState] for the given [market].
  ///
  /// ```dart
  /// final state = await MarketStatus.market(Markets.nse);
  /// ```
  static Future<MarketState> market(Markets market) {
    final definition = MarketRegistry.definitionFor(market);
    return _defaultEngine.compute(definition);
  }

  /// Returns the current [MarketState] for a market looked up by its string code.
  ///
  /// Works for both built-in markets and new exchanges added via the data repo
  /// before they receive a [Markets] enum entry.
  ///
  /// ```dart
  /// // Built-in market by code
  /// final state = await MarketStatus.marketByCode('NSE');
  ///
  /// // New exchange synced from the data repo (not yet in the enum)
  /// final state = await MarketStatus.marketByCode('CBOE');
  /// ```
  ///
  /// Returns null if the code is not found.
  static Future<MarketState?> marketByCode(String code) async {
    final definition = MarketRegistry.definitionByCode(code);
    if (definition == null) return null;
    return _defaultEngine.compute(definition);
  }

  /// Returns the current [MarketState] for a [MarketDefinition] directly.
  ///
  /// Useful when you supply a custom exchange not in the built-in registry.
  static Future<MarketState> marketByDefinition(MarketDefinition definition) {
    return _defaultEngine.compute(definition);
  }

  /// Returns [MarketState] for all given [markets] concurrently.
  ///
  /// ```dart
  /// final states = await MarketStatus.all([Markets.nse, Markets.nyse, Markets.mcx]);
  /// ```
  static Future<List<MarketState>> all(List<Markets> markets) {
    return Future.wait(markets.map(market));
  }

  /// Returns a [Stream] that emits an updated [MarketState] every [interval].
  ///
  /// ```dart
  /// MarketStatus.watch(Markets.nse).listen((state) {
  ///   print(state.isOpen);
  /// });
  /// ```
  static Stream<MarketState> watch(
    Markets market, {
    Duration interval = const Duration(seconds: 30),
  }) {
    final definition = MarketRegistry.definitionFor(market);
    return _defaultEngine.watch(definition, interval: interval);
  }

  /// Searches built-in market definitions by name or code.
  ///
  /// ```dart
  /// final results = MarketStatus.search('gold');
  /// // Returns: [MCX Gold, COMEX Gold, ...]
  /// ```
  static List<MarketDefinition> search(String query) {
    return MarketRegistry.search(query);
  }

  /// Returns all available market categories.
  ///
  /// ```dart
  /// final cats = MarketStatus.categories();
  /// // [MarketType.stockExchange, MarketType.commodityExchange, ...]
  /// ```
  static List<MarketType> categories() => MarketType.values;

  /// Returns all markets belonging to a given [MarketType].
  static List<MarketDefinition> marketsByCategory(MarketType type) {
    return MarketRegistry.all.values
        .where((d) => d.type == type)
        .toList();
  }

  /// Syncs remote holiday + special-day calendars from the GitHub data repo.
  ///
  /// Call once at app start. ETags ensure no re-download if nothing changed.
  ///
  /// **Only sync the exchanges your app actually uses:**
  ///
  /// ```dart
  /// // Indian stock app — only needs NSE + BSE
  /// await MarketStatus.syncCalendars(
  ///   markets: [Markets.nse, Markets.bse],
  /// );
  ///
  /// // Multi-market app
  /// await MarketStatus.syncCalendars(
  ///   markets: [Markets.nse, Markets.nyse, Markets.nasdaq, Markets.mcx],
  /// );
  ///
  /// // Sync everything (only if your app shows all exchanges)
  /// await MarketStatus.syncCalendars();
  /// ```
  static Future<SyncResult> syncCalendars({
    List<Markets>? markets,
    List<int>? years,
  }) async {
    final result = await CalendarSync.syncCalendars(
      markets: markets,
      years: years,
    );
    // Invalidate in-memory holiday cache so subsequent calls pick up fresh data
    _cachedHolidayProvider?.clearMemCache();
    return result;
  }

  /// Returns when calendars were last synced, or null.
  static Future<DateTime?> lastSyncedAt() => CalendarSync.lastSyncedAt();

  /// Resets the engine to defaults (clears any [configure] overrides).
  static void reset() {
    _engine = null;
    _cachedHolidayProvider = null;
    MarketRegistry.clearOverrides();
  }
}

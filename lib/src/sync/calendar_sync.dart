import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/market_definition.dart';
import '../markets/markets.dart';

/// Handles remote synchronisation of market definitions AND holiday calendars
/// from the centralized GitHub data repository.
///
/// Downloads three categories of data per market:
///   1. **Market definition** (`markets/<code>.json`) — trading hours, sessions,
///      timezone, trading days. Lets you update open/close times without a
///      package release.
///   2. **Holidays** (`holidays/<code>/<year>.json`) — full-day closures.
///   3. **Special days** (`special_days/<code>.json`) — early closes, delayed
///      opens, emergency closures.
///
/// All files are cached in [SharedPreferences] with ETag support — unchanged
/// files cost zero bandwidth.
///
/// ---
///
/// ## Two-repo model
///
/// ```
/// github.com/market-status-dart/market_status        ← Dart package (code)
/// github.com/market-status-dart/market-status-data   ← JSON data only
/// ```
///
/// ## Data repository structure
///
/// ```
/// market-status-data/
/// │
/// ├── markets/
/// │   ├── nse.json        ← trading hours, sessions, timezone, trading days
/// │   ├── bse.json
/// │   ├── nyse.json
/// │   ├── nasdaq.json
/// │   ├── lse.json
/// │   └── ... (one file per market, lowercase code)
/// │
/// ├── holidays/
/// │   ├── nse/
/// │   │   ├── 2025.json
/// │   │   ├── 2026.json
/// │   │   └── 2027.json
/// │   └── ... (one folder per market)
/// │
/// └── special_days/
///     ├── nse.json
///     └── ... (one file per market)
/// ```
///
/// ---
///
/// ## Market definition JSON  (`markets/<code>.json`)
///
/// ```json
/// {
///   "code": "NSE",
///   "name": "National Stock Exchange of India",
///   "type": "stockExchange",
///   "timezone": "Asia/Kolkata",
///   "sessions": [
///     { "name": "Regular", "type": "regular", "openTime": "09:15", "closeTime": "15:30" }
///   ],
///   "tradingDays": [1, 2, 3, 4, 5],
///   "supportsPreMarket": false,
///   "supportsAfterHours": false,
///   "is24x7": false,
///   "description": "India's largest stock exchange."
/// }
/// ```
///
/// Edit `markets/nse.json` and merge the PR — all apps pick up the new hours
/// on next sync. No package release needed.
///
/// Add a brand-new `markets/cboe.json` — apps can access it immediately via
/// [MarketStatus.marketByCode] before it gets an enum entry.
///
/// ---
///
/// ## Holiday JSON  (`holidays/<code>/<year>.json`)
///
/// ```json
/// [
///   { "date": "2026-01-26", "type": "holiday",   "reason": "Republic Day" },
///   { "date": "2026-08-15", "type": "holiday",   "reason": "Independence Day" }
/// ]
/// ```
///
/// ## Special-days JSON  (`special_days/<code>.json`)
///
/// ```json
/// [
///   { "date": "2026-11-27", "type": "early_close",      "reason": "Muhurat Trading", "close": "18:15" },
///   { "date": "2026-03-10", "type": "delayed_open",      "reason": "Tech issue",      "open":  "11:00" },
///   { "date": "2026-06-01", "type": "emergency_closure", "reason": "Extreme weather"                   }
/// ]
/// ```
class CalendarSync {
  // ── URL configuration ──────────────────────────────────────────────────────

  /// Official centralized data repository. Do not change this in production.
  static const String _officialBaseUrl =
      'https://raw.githubusercontent.com/market-status-dart/market-status-data/main';

  /// Override only for tests or private forks. Leave null for the official repo.
  static String? overrideBaseUrl;

  static String get _effectiveBaseUrl => overrideBaseUrl ?? _officialBaseUrl;

  // ── SharedPreferences key prefixes ─────────────────────────────────────────
  static const String _calKeyPrefix = 'mkt_cal_';  // holiday files
  static const String _defKeyPrefix = 'mkt_def_';  // market definition files
  static const String _etagPrefix   = 'mkt_etag_';
  static const String _lastSyncKey  = 'mkt_last_sync';

  static final http.Client _client = http.Client();

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Downloads market definitions, holidays, and special-day calendars for
  /// the given [markets] and caches them in [SharedPreferences].
  ///
  /// - Safe to call on every app start — ETags prevent redundant downloads.
  /// - Downloaded market definitions are immediately applied as live overrides
  ///   in [MarketRegistry] so updated trading hours take effect right away.
  ///
  /// ```dart
  /// await MarketStatus.syncCalendars(
  ///   markets: [Markets.nse, Markets.bse, Markets.nyse],
  /// );
  /// ```
  static Future<SyncResult> syncCalendars({
    List<Markets>? markets,
    List<int>? years,
    http.Client? client,
  }) async {
    final effectiveClient = client ?? _client;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final effectiveYears = years ?? [now.year, now.year + 1];
    final effectiveMarkets = markets ?? Markets.values.toList();

    final codes = effectiveMarkets
        .map((m) => MarketRegistry.definitionFor(m).code.toLowerCase())
        .toSet()
        .toList()
      ..sort();

    int synced  = 0;
    int skipped = 0;
    final errors = <String>[];

    // ── 1. Market definitions: markets/<code>.json ───────────────────────────
    for (final code in codes) {
      final result = await _fetchAndCache(
        url:      '$_effectiveBaseUrl/markets/$code.json',
        cacheKey: '$_defKeyPrefix$code',
        etagKey:  '${_etagPrefix}def_$code',
        prefs:    prefs,
        client:   effectiveClient,
      );

      if (result.status == _FetchStatus.synced) {
        synced++;
        final def = _parseDefinition(result.body);
        if (def != null) MarketRegistry.applyDefinitionByCode(def);
      } else if (result.status == _FetchStatus.skipped) {
        skipped++;
        // Still apply from cache — might have been fetched in a previous launch
        final cached = prefs.getString('$_defKeyPrefix$code');
        final def = _parseDefinition(cached);
        if (def != null) MarketRegistry.applyDefinitionByCode(def);
      } else if (result.status == _FetchStatus.error) {
        errors.add('markets/$code');
      }
      // 404 = exchange not in data repo yet — built-in definition stays active
    }

    // ── 2. Holiday files: holidays/<code>/<year>.json ────────────────────────
    for (final code in codes) {
      for (final year in effectiveYears) {
        final result = await _fetchAndCache(
          url:      '$_effectiveBaseUrl/holidays/$code/$year.json',
          cacheKey: '${_calKeyPrefix}${code}_$year',
          etagKey:  '${_etagPrefix}cal_${code}_$year',
          prefs:    prefs,
          client:   effectiveClient,
        );
        if (result.status == _FetchStatus.synced)  synced++;
        if (result.status == _FetchStatus.skipped) skipped++;
        if (result.status == _FetchStatus.error)   errors.add('holidays/$code/$year');
        // 404 = no holiday file for this year — fine
      }
    }

    // ── 3. Special-days files: special_days/<code>.json ──────────────────────
    for (final code in codes) {
      final result = await _fetchAndCache(
        url:      '$_effectiveBaseUrl/special_days/$code.json',
        cacheKey: '${_calKeyPrefix}special_$code',
        etagKey:  '${_etagPrefix}special_$code',
        prefs:    prefs,
        client:   effectiveClient,
      );
      if (result.status == _FetchStatus.synced)  synced++;
      if (result.status == _FetchStatus.skipped) skipped++;
      // 404 is normal — not every exchange has special days
    }

    await prefs.setString(_lastSyncKey, now.toIso8601String());

    return SyncResult(
      markets:  effectiveMarkets,
      synced:   synced,
      skipped:  skipped,
      errors:   errors,
      syncedAt: now,
    );
  }

  /// Loads previously-cached market definitions from [SharedPreferences] and
  /// applies them to [MarketRegistry] without making any network calls.
  ///
  /// Call at cold start before [syncCalendars] so cached trading hours are
  /// active immediately — even if the device is offline.
  ///
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await CalendarSync.applyCachedDefinitions(); // instant, no network
  ///   runApp(MyApp());
  ///   // sync in background / after first frame
  /// }
  /// ```
  static Future<void> applyCachedDefinitions() async {
    final prefs = await SharedPreferences.getInstance();
    final defKeys = prefs.getKeys()
        .where((k) => k.startsWith(_defKeyPrefix))
        .toList();

    for (final key in defKeys) {
      final def = _parseDefinition(prefs.getString(key));
      if (def != null) MarketRegistry.applyDefinitionByCode(def);
    }
  }

  // ── Cache inspection helpers ───────────────────────────────────────────────

  /// Returns the cached market definition JSON for [code], or null.
  static Future<String?> getCachedDefinition(String code) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_defKeyPrefix${code.toLowerCase()}');
  }

  /// Returns the cached holiday JSON for [market] / [year], or null.
  static Future<String?> getCachedCalendar(Markets market, int year) async {
    final code = MarketRegistry.definitionFor(market).code.toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_calKeyPrefix}${code}_$year');
  }

  /// Returns the cached special-days JSON for [market], or null.
  static Future<String?> getCachedSpecialDays(Markets market) async {
    final code = MarketRegistry.definitionFor(market).code.toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_calKeyPrefix}special_$code');
  }

  /// Returns when calendars were last successfully synced, or null.
  static Future<DateTime?> lastSyncedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSyncKey);
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  /// Clears ALL cached data (definitions + holidays + special days).
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys()
        .where((k) =>
            k.startsWith(_calKeyPrefix) ||
            k.startsWith(_defKeyPrefix) ||
            k.startsWith(_etagPrefix))
        .toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// Clears cached data for specific [markets] only.
  static Future<void> clearCacheFor(List<Markets> markets) async {
    final prefs = await SharedPreferences.getInstance();
    for (final m in markets) {
      final code = MarketRegistry.definitionFor(m).code.toLowerCase();
      final keys = prefs.getKeys()
          .where((k) =>
              k.startsWith('${_calKeyPrefix}${code}_') ||
              k.startsWith('${_etagPrefix}cal_${code}_') ||
              k == '${_calKeyPrefix}special_$code' ||
              k == '${_etagPrefix}special_$code' ||
              k == '$_defKeyPrefix$code' ||
              k == '${_etagPrefix}def_$code')
          .toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static MarketDefinition? _parseDefinition(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      return MarketDefinition.fromJson(
          jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<_FetchResult> _fetchAndCache({
    required String url,
    required String cacheKey,
    required String etagKey,
    required SharedPreferences prefs,
    required http.Client client,
  }) async {
    try {
      final headers = <String, String>{};
      final cachedEtag = prefs.getString(etagKey);
      if (cachedEtag != null) headers['If-None-Match'] = cachedEtag;

      final response = await client
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      switch (response.statusCode) {
        case 304:
          return const _FetchResult(_FetchStatus.skipped, null);

        case 200:
          jsonDecode(response.body); // validate JSON before persisting
          await prefs.setString(cacheKey, response.body);
          final etag = response.headers['etag'];
          if (etag != null) await prefs.setString(etagKey, etag);
          return _FetchResult(_FetchStatus.synced, response.body);

        case 404:
          return const _FetchResult(_FetchStatus.notFound, null);

        default:
          return const _FetchResult(_FetchStatus.error, null);
      }
    } catch (_) {
      return const _FetchResult(_FetchStatus.error, null);
    }
  }
}

// ── Internal types ─────────────────────────────────────────────────────────

enum _FetchStatus { synced, skipped, notFound, error }

class _FetchResult {
  final _FetchStatus status;
  final String? body;
  const _FetchResult(this.status, this.body);
}

// ─────────────────────────────────────────────────────────────────────────────

/// Result returned by [CalendarSync.syncCalendars].
class SyncResult {
  /// Markets included in this sync request.
  final List<Markets> markets;

  /// Number of files successfully downloaded and cached.
  final int synced;

  /// Number of files unchanged since last sync (HTTP 304).
  final int skipped;

  /// Labels of files that failed (e.g. `"markets/nse"`, `"holidays/nse/2026"`).
  final List<String> errors;

  /// When this sync completed.
  final DateTime syncedAt;

  const SyncResult({
    required this.markets,
    required this.synced,
    required this.skipped,
    required this.errors,
    required this.syncedAt,
  });

  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() =>
      'SyncResult(markets=${markets.length}, synced=$synced, '
      'skipped=$skipped, errors=${errors.length})';
}

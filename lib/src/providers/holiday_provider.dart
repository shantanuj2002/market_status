import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/holiday.dart';

/// Abstract interface for supplying holiday/special-day data for a market.
abstract class HolidayProvider {
  const HolidayProvider();

  /// Returns all holidays/special-days for [marketCode] in [year].
  /// Returns an empty list when no data is available.
  Future<List<Holiday>> getHolidays(String marketCode, int year);
}

// ─────────────────────────────────────────────────────────────────────────────
// LocalHolidayProvider
// ─────────────────────────────────────────────────────────────────────────────

/// Returns hardcoded, in-process holiday data.
///
/// Used for the embedded 2025-2027 defaults bundled with the package.
/// Always works offline with zero latency.
class LocalHolidayProvider implements HolidayProvider {
  final Map<String, Map<int, List<Holiday>>> _data;

  const LocalHolidayProvider(this._data);

  @override
  Future<List<Holiday>> getHolidays(String marketCode, int year) async {
    final byYear = _data[marketCode.toUpperCase()];
    if (byYear == null) return [];
    return byYear[year] ?? [];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CachedHolidayProvider
// ─────────────────────────────────────────────────────────────────────────────

/// Reads holiday data that was previously downloaded and stored in
/// [SharedPreferences] by [CalendarSync.syncCalendars].
///
/// This is the bridge between the sync layer and the holiday engine.
/// Place this first in a [CompositeHolidayProvider] chain so that
/// remotely-synced data takes precedence over embedded defaults.
///
/// ```
/// CompositeHolidayProvider([
///   CachedHolidayProvider(),          // remote data (if synced)
///   LocalHolidayProvider(defaults),   // embedded fallback
/// ])
/// ```
class CachedHolidayProvider implements HolidayProvider {
  /// Key prefix must match what [CalendarSync] uses when saving.
  static const String _prefKeyPrefix = 'mkt_cal_';

  // In-process memory cache to avoid repeated SharedPreferences reads
  // within the same app session.
  final Map<String, Map<int, List<Holiday>>> _memCache = {};

  @override
  Future<List<Holiday>> getHolidays(String marketCode, int year) async {
    final code = marketCode.toUpperCase();

    // 1. Try in-process memory cache first
    if (_memCache[code] != null && _memCache[code]![year] != null) {
      return _memCache[code]![year]!;
    }

    // 2. Read from SharedPreferences (written by CalendarSync)
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefKeyPrefix${marketCode.toLowerCase()}_$year';
      final raw = prefs.getString(key);
      if (raw == null) return [];

      final jsonList = jsonDecode(raw) as List;
      final holidays = jsonList
          .map((e) => Holiday.fromJson(e as Map<String, dynamic>))
          .toList();

      // Populate memory cache
      _memCache.putIfAbsent(code, () => {})[year] = holidays;
      return holidays;
    } catch (_) {
      return [];
    }
  }

  /// Clears the in-process memory cache.
  /// Call after [CalendarSync.syncCalendars] to pick up fresh data immediately.
  void clearMemCache() => _memCache.clear();
}

// ─────────────────────────────────────────────────────────────────────────────
// RemoteHolidayProvider
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches holidays directly from the GitHub raw URL at query time.
///
/// Unlike [CachedHolidayProvider] (which reads pre-synced data), this hits
/// the network on every cache miss. Useful for low-latency single-market
/// lookups without running a full sync upfront.
///
/// Falls back to an empty list on any network or parse error.
class RemoteHolidayProvider implements HolidayProvider {
  final String _baseUrl;
  final http.Client _client;

  /// Cache: marketCode → year → holidays (in-process only)
  final Map<String, Map<int, List<Holiday>>> _cache = {};

  /// ETag per request URL for conditional GET support.
  final Map<String, String> _etags = {};

  RemoteHolidayProvider({
    String baseUrl =
        'https://raw.githubusercontent.com/your-org/market-status-data/main',
    http.Client? client,
  })  : _baseUrl = baseUrl,
        _client = client ?? http.Client();

  @override
  Future<List<Holiday>> getHolidays(String marketCode, int year) async {
    final url = '$_baseUrl/holidays/${marketCode.toLowerCase()}/$year.json';

    // Return cached version immediately; refresh in background via ETag
    if (_cache[marketCode] != null && _cache[marketCode]![year] != null) {
      _conditionalFetch(url, marketCode, year);
      return _cache[marketCode]![year]!;
    }

    try {
      return await _fetchAndParse(url, marketCode, year);
    } catch (_) {
      return [];
    }
  }

  Future<List<Holiday>> _fetchAndParse(
      String url, String marketCode, int year) async {
    final headers = <String, String>{};
    final etag = _etags[url];
    if (etag != null) headers['If-None-Match'] = etag;

    final response = await _client
        .get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 304) {
      return _cache[marketCode]?[year] ?? [];
    }

    if (response.statusCode == 200) {
      final newEtag = response.headers['etag'];
      if (newEtag != null) _etags[url] = newEtag;

      final jsonList = jsonDecode(response.body) as List;
      final holidays = jsonList
          .map((e) => Holiday.fromJson(e as Map<String, dynamic>))
          .toList();

      _cache.putIfAbsent(marketCode, () => {})[year] = holidays;
      return holidays;
    }

    return _cache[marketCode]?[year] ?? [];
  }

  void _conditionalFetch(String url, String marketCode, int year) {
    _fetchAndParse(url, marketCode, year).catchError((_) => <Holiday>[]);
  }

  /// Clears in-memory cache (forces a fresh network fetch on next call).
  void clearCache() {
    _cache.clear();
    _etags.clear();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CompositeHolidayProvider
// ─────────────────────────────────────────────────────────────────────────────

/// Chains multiple [HolidayProvider]s — first non-empty result wins.
///
/// Recommended order:
/// ```dart
/// CompositeHolidayProvider([
///   CachedHolidayProvider(),          // 1. remotely synced data (highest priority)
///   LocalHolidayProvider(defaults),   // 2. embedded fallback
/// ])
/// ```
class CompositeHolidayProvider implements HolidayProvider {
  final List<HolidayProvider> _providers;

  const CompositeHolidayProvider(this._providers);

  @override
  Future<List<Holiday>> getHolidays(String marketCode, int year) async {
    for (final provider in _providers) {
      final holidays = await provider.getHolidays(marketCode, year);
      if (holidays.isNotEmpty) return holidays;
    }
    return [];
  }
}

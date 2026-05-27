import '../models/market_definition.dart';
import 'definitions/stock_exchanges.dart';
import 'definitions/commodity_exchanges.dart';
import 'definitions/crypto_markets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Markets identifier enum
// ─────────────────────────────────────────────────────────────────────────────

/// Strongly-typed identifiers for all built-in markets.
///
/// Pass any value to [MarketStatusApi.market] or [MarketStatusApi.all].
///
/// ```dart
/// final state = await MarketStatus.market(Markets.nse);
/// final state = await MarketStatus.market(Markets.comexGold);
/// ```
enum Markets {
  // Stock Exchanges
  nse,
  bse,
  nyse,
  nasdaq,
  lse,
  jpx,
  hkex,
  sse,
  szse,
  sgx,
  asx,
  tsx,
  euronext,

  // Indian Commodity
  mcx,
  mcxGold,
  mcxSilver,
  mcxCrudeOil,
  ncdex,

  // US Futures / Commodity
  comex,
  comexGold,
  comexSilver,
  comexCopper,
  nymex,
  nymexCrudeOil,
  nymexNaturalGas,

  // International Commodity
  ice,
  lme,
  shfe,
  dce,
  czce,

  // Crypto
  crypto,
  binance,
  coinbase,
  kraken,
}

// ─────────────────────────────────────────────────────────────────────────────
// Market Registry
// ─────────────────────────────────────────────────────────────────────────────

/// Central registry mapping each [Markets] identifier to its [MarketDefinition].
///
/// Remote definitions fetched via [CalendarSync] are merged on top at runtime.
class MarketRegistry {
  MarketRegistry._();

  static final Map<Markets, MarketDefinition> _builtIn = {
    // Stock Exchanges
    Markets.nse: nseDefinition,
    Markets.bse: bseDefinition,
    Markets.nyse: nyseDefinition,
    Markets.nasdaq: nasdaqDefinition,
    Markets.lse: lseDefinition,
    Markets.jpx: jpxDefinition,
    Markets.hkex: hkexDefinition,
    Markets.sse: sseDefinition,
    Markets.szse: szseDefinition,
    Markets.sgx: sgxDefinition,
    Markets.asx: asxDefinition,
    Markets.tsx: tsxDefinition,
    Markets.euronext: euronextDefinition,

    // Indian Commodity
    Markets.mcx: mcxDefinition,
    Markets.mcxGold: mcxGoldDefinition,
    Markets.mcxSilver: mcxSilverDefinition,
    Markets.mcxCrudeOil: mcxCrudeOilDefinition,
    Markets.ncdex: ncdexDefinition,

    // US Futures / Commodity
    Markets.comex: comexDefinition,
    Markets.comexGold: comexGoldDefinition,
    Markets.comexSilver: comexSilverDefinition,
    Markets.comexCopper: comexCopperDefinition,
    Markets.nymex: nymexDefinition,
    Markets.nymexCrudeOil: nymexCrudeOilDefinition,
    Markets.nymexNaturalGas: nymexNaturalGasDefinition,

    // International Commodity
    Markets.ice: iceDefinition,
    Markets.lme: lmeDefinition,
    Markets.shfe: shfeDefinition,
    Markets.dce: dceDefinition,
    Markets.czce: czceDefinition,

    // Crypto
    Markets.crypto: cryptoDefinition,
    Markets.binance: binanceDefinition,
    Markets.coinbase: coinbaseDefinition,
    Markets.kraken: krakenDefinition,
  };

  /// Runtime overrides applied by [CalendarSync.syncCalendars].
  static final Map<Markets, MarketDefinition> _overrides = {};

  /// Returns the effective [MarketDefinition] for [market].
  static MarketDefinition definitionFor(Markets market) {
    return _overrides[market] ?? _builtIn[market]!;
  }

  /// Applies a remote-fetched definition override by [Markets] enum key.
  static void applyOverride(Markets market, MarketDefinition definition) {
    _overrides[market] = definition;
  }

  /// Applies a remote-fetched definition override by market code string.
  ///
  /// Used by [CalendarSync] when applying downloaded `markets/<code>.json`
  /// files. Matches against the enum via code comparison so that:
  /// - Known markets (e.g. NSE) override their built-in definition.
  /// - Unknown markets (new exchanges not yet in the enum) are stored in
  ///   [_dynamicMarkets] and accessible via [definitionByCode].
  static void applyDefinitionByCode(MarketDefinition definition) {
    // Try to find the matching Markets enum value by code
    final match = _builtIn.entries
        .where((e) =>
            e.value.code.toLowerCase() == definition.code.toLowerCase())
        .map((e) => e.key)
        .firstOrNull;

    if (match != null) {
      _overrides[match] = definition;
    } else {
      // New exchange not in the enum — store in dynamic map
      _dynamicMarkets[definition.code.toUpperCase()] = definition;
    }
  }

  /// Dynamic market definitions downloaded from the data repo that don't
  /// correspond to any built-in [Markets] enum value yet.
  static final Map<String, MarketDefinition> _dynamicMarkets = {};

  /// Returns a definition by its string code, checking all sources.
  /// Useful for new exchanges added via the data repo before they get an enum entry.
  ///
  /// Returns null if the code is not found.
  static MarketDefinition? definitionByCode(String code) {
    final upper = code.toUpperCase();
    // Check overrides first, then built-ins, then dynamic
    for (final entry in _overrides.entries) {
      if (entry.value.code.toUpperCase() == upper) return entry.value;
    }
    for (final entry in _builtIn.entries) {
      if (entry.value.code.toUpperCase() == upper) return entry.value;
    }
    return _dynamicMarkets[upper];
  }

  /// Clears runtime overrides (reverts to built-in definitions).
  static void clearOverrides() {
    _overrides.clear();
    _dynamicMarkets.clear();
  }

  /// Returns all market definitions (overrides + built-ins + dynamic).
  static Map<Markets, MarketDefinition> get all => {
        ..._builtIn,
        ..._overrides,
      };

  /// Returns all market definitions including dynamic ones from remote sync.
  static List<MarketDefinition> get allIncludingDynamic => [
        ...all.values,
        ..._dynamicMarkets.values,
      ];

  /// Searches markets by name or code — case-insensitive substring match.
  /// Includes dynamic markets added via remote sync.
  static List<MarketDefinition> search(String query) {
    final q = query.toLowerCase();
    return allIncludingDynamic
        .where((d) =>
            d.name.toLowerCase().contains(q) ||
            d.code.toLowerCase().contains(q))
        .toList();
  }
}

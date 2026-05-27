# market_status

A production-grade Flutter package for real-time global financial market status.

Know instantly whether any stock exchange, commodity exchange, futures market, or crypto market is open — from anywhere in the world, with correct DST handling, holiday awareness, special session support (Muhurat trading etc.), and live calendar updates from GitHub.

[![pub.dev](https://img.shields.io/pub/v/market_status.svg)](https://pub.dev/packages/market_status)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Contents

- [What it does](#what-it-does)
- [Installation](#installation)
- [Quick start](#quick-start)
- [All features with examples](#all-features-with-examples)
  - [Single market status](#1-single-market-status)
  - [Multiple markets at once](#2-multiple-markets-at-once)
  - [Streaming live updates](#3-streaming-live-updates)
  - [Timezone modes](#4-timezone-modes)
  - [Calendar sync](#5-calendar-sync)
  - [Search](#6-search)
  - [Categories](#7-categories)
  - [Custom providers](#8-custom-providers)
  - [Testing](#9-testing)
- [Supported markets](#supported-markets)
- [MarketState reference](#marketstate-reference)
- [Special day types explained](#special-day-types-explained)
- [How the two repos work](#how-the-two-repos-work)
- [Architecture](#architecture)
- [Contributing](#contributing)

---

## What it does

```dart
final state = await MarketStatus.market(Markets.nse);

print(state.isOpen);               // true
print(state.timeToClose);          // 2:15:00 (Duration)
print(state.currentSession);       // SessionType.regular
print(state.isHoliday);            // false
print(state.isSpecialSession);     // false (true during Muhurat etc.)
print(state.specialSessionReason); // null (or "Muhurat Trading")
print(state.exchangeTimezone);     // Asia/Kolkata
```

Works for **34 built-in markets** across stocks, commodities, futures, and crypto.  
Trading hours and holiday calendars update from GitHub without requiring a package release.

---

## Installation

```yaml
dependencies:
  market_status: ^1.0.0
```

```sh
flutter pub get
```

---

## Quick start

```dart
import 'package:market_status/market_status.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Step 1 — load any previously-cached definitions instantly (no network)
  await MarketStatus.init();

  runApp(MyApp());

  // Step 2 — sync in the background after the first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    MarketStatus.syncCalendars(
      markets: [Markets.nse, Markets.bse], // only what your app uses
    );
  });
}
```

```dart
// Check a market
final state = await MarketStatus.market(Markets.nse);

if (state.isSpecialSession) {
  print('Special: ${state.specialSessionReason}');   // "Muhurat Trading"
  print('Closes in: ${state.timeToClose}');
} else if (state.isOpen) {
  print('NSE is OPEN — closes in ${state.timeToClose}');
} else if (state.isHoliday) {
  print('Holiday: ${state.holidayReason}');
  print('Next open: ${state.nextOpen}');
} else {
  print('NSE is CLOSED — opens in ${state.timeToOpen}');
}
```

---

## All features with examples

### 1. Single market status

```dart
// Stock exchange
final nse  = await MarketStatus.market(Markets.nse);
final nyse = await MarketStatus.market(Markets.nyse);
final jpx  = await MarketStatus.market(Markets.jpx);  // Tokyo — has lunch break
final sse  = await MarketStatus.market(Markets.sse);  // Shanghai — has lunch break

// NASDAQ — 3 sessions (pre-market, regular, after-hours)
final nasdaq = await MarketStatus.market(Markets.nasdaq);

// Commodity / futures
final mcxGold    = await MarketStatus.market(Markets.mcxGold);
final nymexCrude = await MarketStatus.market(Markets.nymexCrudeOil);

// Crypto — always open 24×7
final crypto = await MarketStatus.market(Markets.crypto);
print(crypto.isOpen);      // always true
print(crypto.timeToClose); // always null

// Market not yet in the enum but already in the data repo
final cboe = await MarketStatus.marketByCode('CBOE');
```

**Reading the result:**

```dart
final state = await MarketStatus.market(Markets.nasdaq);

state.isOpen              // bool   — currently trading?
state.isHoliday           // bool   — full-day holiday / closure?
state.holidayReason       // String? — "Thanksgiving", "Republic Day", ...
state.isSpecialSession    // bool   — special window active (e.g. Muhurat)?
state.specialSessionReason // String? — "Muhurat Trading", "Half-day session"

state.timeToClose         // Duration? — null when market is closed
state.timeToOpen          // Duration? — null when market is open
state.nextOpen            // DateTime? UTC
state.nextClose           // DateTime? UTC

state.currentSession      // SessionType? — regular | preMarket | afterHours
                          //              | morning | afternoon | special
state.nextSession         // SessionType?

state.marketCode          // "NASDAQ"
state.marketName          // "NASDAQ Stock Market"
state.marketType          // MarketType.stockExchange
state.exchangeTimezone    // "America/New_York"
state.exchangeTime        // DateTime — current time at the exchange
state.utcTime             // DateTime — snapshot time in UTC
```

---

### 2. Multiple markets at once

Fetches all states concurrently.

```dart
final states = await MarketStatus.all([
  Markets.nse,
  Markets.nyse,
  Markets.nasdaq,
  Markets.lse,
  Markets.mcxGold,
  Markets.crypto,
]);

for (final s in states) {
  String label;
  if (s.isSpecialSession) {
    label = '� SPECIAL (${s.specialSessionReason})';
  } else if (s.isOpen) {
    label = '🟢 OPEN';
  } else if (s.isHoliday) {
    label = '🔴 HOLIDAY (${s.holidayReason})';
  } else {
    label = '⚫ CLOSED';
  }
  print('${s.marketCode.padRight(12)} $label');
}
```

---

### 3. Streaming live updates

```dart
// Emits a fresh MarketState every 30 seconds by default
final subscription = MarketStatus.watch(Markets.nse).listen((state) {
  setState(() {
    _isOpen = state.isOpen;
    _label  = state.isSpecialSession
        ? 'Muhurat closes in ${_fmt(state.timeToClose)}'
        : state.isOpen
            ? 'NSE closes in ${_fmt(state.timeToClose)}'
            : 'NSE opens in ${_fmt(state.timeToOpen)}';
  });
});

// Custom interval
MarketStatus.watch(Markets.nyse, interval: const Duration(minutes: 1))
    .listen((state) { ... });

subscription.cancel(); // when done
```

---

### 4. Timezone modes

Default is device-only — zero network calls for timezone.

```dart
// Default — no network, timezoneMismatch always false
final state = await MarketStatus.market(Markets.nse);
```

Opt in to IP verification to catch VPN users or wrong device clocks:

```dart
MarketStatus.configure(
  timezoneMode: TimezoneMode.deviceWithIpVerification,
);

final state = await MarketStatus.market(Markets.nse);
if (state.timezoneMismatch) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Timezone mismatch'),
      content: Text(
        'Device: ${state.userTimezone}\n'
        'Location: ${state.ipTimezone}',
      ),
    ),
  );
}
```

| Mode | Network for timezone | `timezoneMismatch` | `ipTimezone` |
|---|---|---|---|
| `TimezoneMode.deviceOnly` (default) | Never | Always `false` | Always `null` |
| `TimezoneMode.deviceWithIpVerification` | Once per 30 min | `true` when different | IANA string |

---

### 5. Calendar sync

The package fetches **three types of data** per market from the centralized data repository:

| File | Path | What it updates |
|---|---|---|
| Market definition | `markets/<code>.json` | Trading hours, sessions, timezone |
| Holidays | `holidays/<code>/<year>.json` | Full-day closures |
| Special days | `special_days/<code>.json` | Muhurat, early close, delayed open, emergency |

```dart
// Sync only the markets your app uses
final result = await MarketStatus.syncCalendars(
  markets: [Markets.nse, Markets.bse, Markets.mcxGold],
);

print('Downloaded: ${result.synced}');
print('Unchanged:  ${result.skipped}');  // ETag matched — zero bytes transferred
if (result.hasErrors) print('Errors: ${result.errors}');

// Check when last synced
final last = await MarketStatus.lastSyncedAt();
print(last); // 2026-05-27 09:14:32.000Z
```

**Sync behaviour:**

- First launch with internet → downloads and caches in `SharedPreferences`
- Every subsequent launch → ETag check → `304 Not Modified` → zero bytes if unchanged
- Offline → uses last-cached data automatically
- Never synced → falls back to embedded defaults (2025–2026 built into the package)

**Load cached definitions at cold start (no network):**

```dart
// In main() — apply previously-downloaded trading hours before first frame
await MarketStatus.init();
// Then sync updates in background
```

---

### 6. Search

```dart
final results = MarketStatus.search('gold');
// → MCX Gold, COMEX Gold

final results = MarketStatus.search('crude');
// → MCX Crude Oil, NYMEX WTI Crude Oil

// Works for new exchanges added via the data repo too
final results = MarketStatus.search('cboe');
```

---

### 7. Categories

```dart
final types = MarketStatus.categories();
// [stockExchange, commodityExchange, futuresExchange, cryptoExchange]

final stocks = MarketStatus.marketsByCategory(MarketType.stockExchange);
// NSE, BSE, NYSE, NASDAQ, LSE, JPX, ...

final cryptos = MarketStatus.marketsByCategory(MarketType.cryptoExchange);
print(cryptos.every((m) => m.is24x7)); // true
```

---

### 8. Custom providers

**Custom HolidayProvider:**

```dart
class MyHolidayProvider implements HolidayProvider {
  @override
  Future<List<Holiday>> getHolidays(String marketCode, int year) async {
    final response = await http.get(
      Uri.parse('https://my-api.com/holidays/$marketCode/$year'),
    );
    return (jsonDecode(response.body) as List)
        .map((e) => Holiday.fromJson(e))
        .toList();
  }
}

MarketStatus.configure(holidayProvider: MyHolidayProvider());
```

**Chain multiple providers — remote first, local fallback:**

```dart
MarketStatus.configure(
  holidayProvider: CompositeHolidayProvider([
    CachedHolidayProvider(),                    // synced from GitHub (highest priority)
    MyHolidayProvider(),                        // your own source
    LocalHolidayProvider(DefaultHolidays.all),  // built-in defaults (fallback)
  ]),
);
```

**Custom TimeProvider — server-authoritative time:**

```dart
class ServerTimeProvider implements TimeProvider {
  @override
  Future<DateTime> nowUtc() async {
    final res = await http.get(Uri.parse('https://worldtimeapi.org/api/timezone/UTC'));
    return DateTime.parse(jsonDecode(res.body)['utc_datetime'] as String);
  }
}

MarketStatus.configure(timeProvider: ServerTimeProvider());
```

---

### 9. Testing

```dart
void main() {
  setUp(() => MarketStatus.reset());

  test('NSE open at 10:00 IST', () async {
    MarketStatus.configure(
      timeProvider: FixedTimeProvider(DateTime.utc(2026, 1, 19, 4, 30)), // 10:00 IST
      deviceTimezoneProvider: FixedTimezoneProvider('Asia/Kolkata'),
      holidayProvider: LocalHolidayProvider(DefaultHolidays.all),
    );
    final state = await MarketStatus.market(Markets.nse);
    expect(state.isOpen, isTrue);
    expect(state.currentSession, SessionType.regular);
  });

  test('NSE closed on Republic Day', () async {
    MarketStatus.configure(
      timeProvider: FixedTimeProvider(DateTime.utc(2026, 1, 26, 4, 30)),
      deviceTimezoneProvider: FixedTimezoneProvider('Asia/Kolkata'),
      holidayProvider: LocalHolidayProvider(DefaultHolidays.all),
    );
    final state = await MarketStatus.market(Markets.nse);
    expect(state.isHoliday, isTrue);
    expect(state.holidayReason, contains('Republic Day'));
  });

  test('NSE Muhurat trading — open at 18:30 IST on Diwali', () async {
    // 18:30 IST = 13:00 UTC
    MarketStatus.configure(
      timeProvider: FixedTimeProvider(DateTime.utc(2026, 11, 27, 13, 0)),
      deviceTimezoneProvider: FixedTimezoneProvider('Asia/Kolkata'),
      holidayProvider: LocalHolidayProvider(DefaultHolidays.all),
    );
    final state = await MarketStatus.market(Markets.nse);
    expect(state.isOpen, isTrue);
    expect(state.isSpecialSession, isTrue);
    expect(state.specialSessionReason, contains('Muhurat'));
    expect(state.currentSession, SessionType.special);
  });
}
```

---

## Supported markets

### Stock exchanges (13)

| Identifier | Exchange | Country | Timezone | Sessions |
|---|---|---|---|---|
| `Markets.nse` | National Stock Exchange of India | 🇮🇳 | Asia/Kolkata | 09:15 – 15:30 |
| `Markets.bse` | BSE (Bombay Stock Exchange) | 🇮🇳 | Asia/Kolkata | 09:15 – 15:30 |
| `Markets.nyse` | New York Stock Exchange | 🇺🇸 | America/New_York | 09:30 – 16:00 |
| `Markets.nasdaq` | NASDAQ | 🇺🇸 | America/New_York | 04:00–09:30 · 09:30–16:00 · 16:00–20:00 |
| `Markets.lse` | London Stock Exchange | 🇬🇧 | Europe/London | 08:00 – 16:30 |
| `Markets.jpx` | Tokyo Stock Exchange | 🇯🇵 | Asia/Tokyo | 09:00–11:30 · 12:30–15:30 |
| `Markets.hkex` | Hong Kong Exchange | 🇭🇰 | Asia/Hong_Kong | 09:30–12:00 · 13:00–16:00 |
| `Markets.sse` | Shanghai Stock Exchange | 🇨🇳 | Asia/Shanghai | 09:30–11:30 · 13:00–15:00 |
| `Markets.szse` | Shenzhen Stock Exchange | 🇨🇳 | Asia/Shanghai | 09:30–11:30 · 13:00–15:00 |
| `Markets.sgx` | Singapore Exchange | 🇸🇬 | Asia/Singapore | 09:00 – 17:00 |
| `Markets.asx` | Australian Securities Exchange | 🇦🇺 | Australia/Sydney | 10:00 – 16:00 |
| `Markets.tsx` | Toronto Stock Exchange | 🇨🇦 | America/Toronto | 09:30 – 16:00 |
| `Markets.euronext` | Euronext (Pan-European) | 🇪🇺 | Europe/Paris | 09:00 – 17:30 |

### Commodity exchanges (9)

| Identifier | Exchange | Country | Timezone |
|---|---|---|---|
| `Markets.mcx` | Multi Commodity Exchange India | 🇮🇳 | Asia/Kolkata |
| `Markets.mcxGold` | MCX Gold | 🇮🇳 | Asia/Kolkata |
| `Markets.mcxSilver` | MCX Silver | 🇮🇳 | Asia/Kolkata |
| `Markets.mcxCrudeOil` | MCX Crude Oil | 🇮🇳 | Asia/Kolkata |
| `Markets.ncdex` | NCDEX (India Agri) | 🇮🇳 | Asia/Kolkata |
| `Markets.lme` | London Metal Exchange | 🇬🇧 | Europe/London |
| `Markets.shfe` | Shanghai Futures Exchange | 🇨🇳 | Asia/Shanghai |
| `Markets.dce` | Dalian Commodity Exchange | 🇨🇳 | Asia/Shanghai |
| `Markets.czce` | Zhengzhou Commodity Exchange | 🇨🇳 | Asia/Shanghai |

### Futures exchanges (8)

| Identifier | Exchange | Country | Timezone |
|---|---|---|---|
| `Markets.comex` | COMEX (CME Group) | 🇺🇸 | America/New_York |
| `Markets.comexGold` | COMEX Gold | 🇺🇸 | America/New_York |
| `Markets.comexSilver` | COMEX Silver | 🇺🇸 | America/New_York |
| `Markets.comexCopper` | COMEX Copper | 🇺🇸 | America/New_York |
| `Markets.nymex` | NYMEX (CME Group) | 🇺🇸 | America/New_York |
| `Markets.nymexCrudeOil` | NYMEX WTI Crude Oil | 🇺🇸 | America/New_York |
| `Markets.nymexNaturalGas` | NYMEX Natural Gas | 🇺🇸 | America/New_York |
| `Markets.ice` | ICE Futures Europe | 🇬🇧 | Europe/London |

### Crypto exchanges (4) — always open 24×7

| Identifier | Exchange |
|---|---|
| `Markets.crypto` | Generic crypto market |
| `Markets.binance` | Binance |
| `Markets.coinbase` | Coinbase Advanced Trade |
| `Markets.kraken` | Kraken |

---

## MarketState reference

```
MarketState
│
├── Identity
│   ├── marketCode            String        "NSE"
│   ├── marketName            String        "National Stock Exchange of India"
│   └── marketType            MarketType    stockExchange | commodityExchange | ...
│
├── Status
│   ├── isOpen                bool          currently accepting orders?
│   ├── isHoliday             bool          full-day holiday or emergency closure?
│   ├── holidayReason         String?       "Republic Day", "Christmas", ...
│   ├── isSpecialSession      bool          special window active? (Muhurat etc.)
│   └── specialSessionReason  String?       "Muhurat Trading", "Half-day session"
│
├── Timing
│   ├── timeToClose           Duration?     null when market is closed
│   ├── timeToOpen            Duration?     null when market is open
│   ├── nextOpen              DateTime?     UTC
│   └── nextClose             DateTime?     UTC
│
├── Session
│   ├── currentSession        SessionType?  regular | preMarket | afterHours
│   │                                       morning | afternoon | special
│   └── nextSession           SessionType?
│
└── Timezone
    ├── exchangeTimezone      String        "Asia/Kolkata"
    ├── userTimezone          String        device OS timezone
    ├── timezoneMismatch      bool          device tz ≠ IP tz (opt-in)
    ├── ipTimezone            String?       IP-resolved tz (opt-in only)
    ├── exchangeTime          DateTime      current time at the exchange
    └── utcTime               DateTime      snapshot time in UTC
```

---

## Special day types explained

All four types live in `special_days/<code>.json` in the data repo.

### `holiday` — full-day closure

Market does not open at all. Normal hours are completely ignored.

```json
{ "date": "2026-01-26", "type": "holiday", "reason": "Republic Day" }
```

### `early_close` — closes earlier than normal

Market opens at the normal time but closes early. Only `close` is required.

```json
{ "date": "2026-11-27", "type": "early_close", "reason": "Day After Thanksgiving", "close": "13:00" }
```

Result: `isOpen=true` until 13:00, `timeToClose` reflects the early close time.

### `delayed_open` — opens later than normal

Market opens late but closes at the normal time. Only `open` is required.

```json
{ "date": "2026-03-10", "type": "delayed_open", "reason": "Technical issue", "open": "11:00" }
```

Result: `isOpen=false` and `timeToOpen` counts down to 11:00 even if normal open has passed.

### `emergency_closure` — unexpected full-day closure

Same effect as `holiday` — market stays closed. Used for weather events, circuit breakers, unexpected shutdowns.

```json
{ "date": "2026-06-01", "type": "emergency_closure", "reason": "Extreme weather" }
```

### `special_session` — non-standard independent window

**This completely replaces normal hours for the day.** The market is only open during the specified `open`–`close` window. Normal session hours are ignored entirely.

Both `open` and `close` are required.

```json
{ "date": "2026-11-27", "type": "special_session", "reason": "Muhurat Trading", "open": "18:00", "close": "19:00" }
```

**Muhurat trading example (NSE/BSE on Diwali):**

| Time (IST) | isOpen | isSpecialSession | currentSession |
|---|---|---|---|
| 10:00 | `false` | `false` | `null` — normal hours replaced |
| 17:30 | `false` | `false` | `null` — before special window |
| 18:30 | `true`  | `true`  | `SessionType.special` |
| 19:30 | `false` | `false` | `null` — window ended |

```dart
final state = await MarketStatus.market(Markets.nse); // at 18:30 IST on Diwali

state.isOpen               // true
state.isSpecialSession     // true
state.specialSessionReason // "Muhurat Trading"
state.currentSession       // SessionType.special
state.timeToClose          // ~29 minutes
```

---

## How the two repos work

```
github.com/market-status-dart/market_status        ← Dart package (code)
github.com/market-status-dart/market-status-data   ← JSON data only
```

### Why separate repos?

| | Package repo | Data repo |
|---|---|---|
| Contains | Dart/Flutter code | JSON files only |
| Who contributes | Flutter developers | Anyone — finance people, traders |
| How often changes | Rarely (features/bugs) | Frequently (holidays, hours changes) |
| Release needed to ship a fix | Yes — `pub publish` | **No** — merge JSON PR, done |

### Data repo structure

```
market-status-data/
│
├── markets/                  ← trading hours & session definitions
│   ├── nse.json
│   ├── nyse.json
│   └── ...
│
├── holidays/                 ← full-day closures
│   ├── nse/
│   │   ├── 2025.json
│   │   ├── 2026.json
│   │   └── 2027.json
│   ├── nyse/
│   │   └── 2026.json
│   └── ...
│
└── special_days/             ← Muhurat, early close, delayed open, emergency
    ├── nse.json
    ├── nyse.json
    └── ...
```

### Market definition JSON (`markets/<code>.json`)

Updating this file changes trading hours for all users on next sync — no package release.

```json
{
  "code": "NSE",
  "name": "National Stock Exchange of India",
  "type": "stockExchange",
  "timezone": "Asia/Kolkata",
  "sessions": [
    { "name": "Regular", "type": "regular", "openTime": "09:15", "closeTime": "15:30" }
  ],
  "tradingDays": [1, 2, 3, 4, 5],
  "supportsPreMarket": false,
  "supportsAfterHours": false,
  "is24x7": false
}
```

### Adding a brand-new exchange (no package release needed)

1. Add `markets/cboe.json` to the data repo
2. Add `holidays/cboe/2026.json`
3. Merge the PR
4. Any app that calls `syncCalendars()` can immediately use:

```dart
final state = await MarketStatus.marketByCode('CBOE');
```

Add `Markets.cboe` to the enum later in a normal package release for the typed API.

### How a change reaches users

```
Contributor edits holidays/nse/2026.json → opens PR
          ↓
Maintainer reviews + merges
          ↓
User opens app → MarketStatus.init() loads cached data
              → syncCalendars() fetches new JSON (HTTP 200)
              → SharedPreferences updated
          ↓
MarketState reflects the change ✅  (no app store update, no pub.dev release)
```

---

## Architecture

```
lib/
├── market_status.dart              ← public barrel export
└── src/
    ├── market_status_api.dart      ← MarketStatus (the one class you use)
    │
    ├── models/
    │   ├── market_type.dart        ← enum MarketType
    │   ├── session_type.dart       ← enum SessionType (includes `special`)
    │   ├── timezone_mode.dart      ← enum TimezoneMode
    │   ├── trading_session.dart    ← TradingSession (open/close strings)
    │   ├── market_definition.dart  ← MarketDefinition (exchange metadata)
    │   ├── market_state.dart       ← MarketState (real-time result)
    │   └── holiday.dart            ← Holiday + HolidayType
    │
    ├── markets/
    │   ├── markets.dart            ← Markets enum + MarketRegistry
    │   └── definitions/
    │       ├── stock_exchanges.dart
    │       ├── commodity_exchanges.dart
    │       └── crypto_markets.dart
    │
    ├── providers/
    │   ├── time_provider.dart
    │   ├── timezone_provider.dart
    │   └── holiday_provider.dart   ← Local · Cached · Remote · Composite
    │
    ├── engine/
    │   ├── trading_session_engine.dart
    │   ├── holiday_engine.dart
    │   └── market_engine.dart      ← orchestrates session + holiday + timezone
    │
    ├── sync/
    │   └── calendar_sync.dart      ← fetches markets/ + holidays/ + special_days/
    │
    ├── data/
    │   └── default_holidays.dart   ← embedded 2025–2026 (offline fallback)
    │
    └── utils/
        └── timezone_utils.dart     ← DST-aware UTC ↔ local time
```

---

## Contributing

### Fix or add holidays (no Dart needed)

1. Go to `github.com/market-status-dart/market-status-data`
2. Edit `holidays/<exchange>/<year>.json` or `special_days/<exchange>.json`
3. Open a PR with a link to the official source
4. Once merged, all apps pick it up on next `syncCalendars()` call

### Update trading hours

Edit `markets/<exchange>.json` in the data repo. Same PR process. No package release needed.

### Add a new exchange (code side)

1. Add a `MarketDefinition` constant in `lib/src/markets/definitions/`
2. Add the identifier to the `Markets` enum in `lib/src/markets/markets.dart`
3. Register it in `MarketRegistry._builtIn`
4. Write tests in `test/market_status_test.dart`
5. Open a PR on `github.com/market-status-dart/market_status`

### Run tests

```sh
flutter test
```

72 tests across 20 groups — covers DST, lunch breaks, holidays, early close, delayed open, emergency closures, Muhurat/special sessions, timezone mismatch, streaming, search, and serialisation.

---

## License

MIT — see [LICENSE](LICENSE).

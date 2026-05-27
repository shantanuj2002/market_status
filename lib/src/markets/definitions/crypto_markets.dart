import '../../models/market_definition.dart';
import '../../models/market_type.dart';
import '../../models/trading_session.dart';
import '../../models/session_type.dart';

/// A single always-open session spanning the full 24-hour day.
const _alwaysOpenSession = TradingSession(
  name: 'Always Open',
  type: SessionType.regular,
  openTime: '00:00',
  closeTime: '23:59',
);

const _cryptoTradingDays = [1, 2, 3, 4, 5, 6, 7];

/// Generic 24×7 crypto market.
///
/// Use [Markets.crypto] for a generic crypto entry, or define per-exchange
/// variants as needed.
const cryptoDefinition = MarketDefinition(
  code: 'CRYPTO',
  name: 'Cryptocurrency Market (24×7)',
  type: MarketType.cryptoExchange,
  timezone: 'UTC',
  sessions: [_alwaysOpenSession],
  tradingDays: _cryptoTradingDays,
  is24x7: true,
  description: 'Cryptocurrency markets — always open, 24 hours a day, '
      '7 days a week, 365 days a year.',
);

const binanceDefinition = MarketDefinition(
  code: 'BINANCE',
  name: 'Binance Exchange',
  type: MarketType.cryptoExchange,
  timezone: 'UTC',
  sessions: [_alwaysOpenSession],
  tradingDays: _cryptoTradingDays,
  is24x7: true,
  description: 'World\'s largest cryptocurrency exchange by volume.',
);

const coinbaseDefinition = MarketDefinition(
  code: 'COINBASE',
  name: 'Coinbase Pro / Advanced Trade',
  type: MarketType.cryptoExchange,
  timezone: 'UTC',
  sessions: [_alwaysOpenSession],
  tradingDays: _cryptoTradingDays,
  is24x7: true,
  description: 'US-based regulated cryptocurrency exchange.',
);

const krakenDefinition = MarketDefinition(
  code: 'KRAKEN',
  name: 'Kraken Exchange',
  type: MarketType.cryptoExchange,
  timezone: 'UTC',
  sessions: [_alwaysOpenSession],
  tradingDays: _cryptoTradingDays,
  is24x7: true,
  description: 'San Francisco-based cryptocurrency exchange.',
);

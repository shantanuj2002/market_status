import '../../models/market_definition.dart';
import '../../models/market_type.dart';
import '../../models/trading_session.dart';
import '../../models/session_type.dart';

// ─────────────────────────────────────────────────────────────────────────────
// India
// ─────────────────────────────────────────────────────────────────────────────

const nseDefinition = MarketDefinition(
  code: 'NSE',
  name: 'National Stock Exchange of India',
  type: MarketType.stockExchange,
  timezone: 'Asia/Kolkata',
  sessions: [
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '09:15',
      closeTime: '15:30',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'India\'s largest stock exchange by trading volume.',
);

const bseDefinition = MarketDefinition(
  code: 'BSE',
  name: 'BSE Limited (Bombay Stock Exchange)',
  type: MarketType.stockExchange,
  timezone: 'Asia/Kolkata',
  sessions: [
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '09:15',
      closeTime: '15:30',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'Asia\'s oldest stock exchange, Mumbai, India.',
);

// ─────────────────────────────────────────────────────────────────────────────
// United States
// ─────────────────────────────────────────────────────────────────────────────

const nyseDefinition = MarketDefinition(
  code: 'NYSE',
  name: 'New York Stock Exchange',
  type: MarketType.stockExchange,
  timezone: 'America/New_York',
  sessions: [
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '09:30',
      closeTime: '16:00',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'World\'s largest stock exchange by market capitalisation.',
);

const nasdaqDefinition = MarketDefinition(
  code: 'NASDAQ',
  name: 'NASDAQ Stock Market',
  type: MarketType.stockExchange,
  timezone: 'America/New_York',
  sessions: [
    TradingSession(
      name: 'Pre-Market',
      type: SessionType.preMarket,
      openTime: '04:00',
      closeTime: '09:30',
    ),
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '09:30',
      closeTime: '16:00',
    ),
    TradingSession(
      name: 'After-Hours',
      type: SessionType.afterHours,
      openTime: '16:00',
      closeTime: '20:00',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  supportsPreMarket: true,
  supportsAfterHours: true,
  description: 'US electronic stock exchange, home of major tech stocks.',
);

// ─────────────────────────────────────────────────────────────────────────────
// United Kingdom
// ─────────────────────────────────────────────────────────────────────────────

const lseDefinition = MarketDefinition(
  code: 'LSE',
  name: 'London Stock Exchange',
  type: MarketType.stockExchange,
  timezone: 'Europe/London',
  sessions: [
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '08:00',
      closeTime: '16:30',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'One of the world\'s oldest stock exchanges, London, UK.',
);

// ─────────────────────────────────────────────────────────────────────────────
// Japan
// ─────────────────────────────────────────────────────────────────────────────

const jpxDefinition = MarketDefinition(
  code: 'JPX',
  name: 'Japan Exchange Group (Tokyo Stock Exchange)',
  type: MarketType.stockExchange,
  timezone: 'Asia/Tokyo',
  sessions: [
    TradingSession(
      name: 'Morning',
      type: SessionType.morning,
      openTime: '09:00',
      closeTime: '11:30',
    ),
    TradingSession(
      name: 'Afternoon',
      type: SessionType.afternoon,
      openTime: '12:30',
      closeTime: '15:30',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'Tokyo Stock Exchange — operates with a lunch break.',
);

// ─────────────────────────────────────────────────────────────────────────────
// Hong Kong
// ─────────────────────────────────────────────────────────────────────────────

const hkexDefinition = MarketDefinition(
  code: 'HKEX',
  name: 'Hong Kong Exchanges and Clearing',
  type: MarketType.stockExchange,
  timezone: 'Asia/Hong_Kong',
  sessions: [
    TradingSession(
      name: 'Morning',
      type: SessionType.morning,
      openTime: '09:30',
      closeTime: '12:00',
    ),
    TradingSession(
      name: 'Afternoon',
      type: SessionType.afternoon,
      openTime: '13:00',
      closeTime: '16:00',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'Hong Kong Stock Exchange with midday break.',
);

// ─────────────────────────────────────────────────────────────────────────────
// China
// ─────────────────────────────────────────────────────────────────────────────

const sseDefinition = MarketDefinition(
  code: 'SSE',
  name: 'Shanghai Stock Exchange',
  type: MarketType.stockExchange,
  timezone: 'Asia/Shanghai',
  sessions: [
    TradingSession(
      name: 'Morning',
      type: SessionType.morning,
      openTime: '09:30',
      closeTime: '11:30',
    ),
    TradingSession(
      name: 'Afternoon',
      type: SessionType.afternoon,
      openTime: '13:00',
      closeTime: '15:00',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'Shanghai Stock Exchange — operates with a lunch break.',
);

const szseDefinition = MarketDefinition(
  code: 'SZSE',
  name: 'Shenzhen Stock Exchange',
  type: MarketType.stockExchange,
  timezone: 'Asia/Shanghai',
  sessions: [
    TradingSession(
      name: 'Morning',
      type: SessionType.morning,
      openTime: '09:30',
      closeTime: '11:30',
    ),
    TradingSession(
      name: 'Afternoon',
      type: SessionType.afternoon,
      openTime: '13:00',
      closeTime: '15:00',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'Shenzhen Stock Exchange — operates with a lunch break.',
);

// ─────────────────────────────────────────────────────────────────────────────
// Singapore
// ─────────────────────────────────────────────────────────────────────────────

const sgxDefinition = MarketDefinition(
  code: 'SGX',
  name: 'Singapore Exchange',
  type: MarketType.stockExchange,
  timezone: 'Asia/Singapore',
  sessions: [
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '09:00',
      closeTime: '17:00',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'Singapore Exchange — Asia\'s leading global exchange.',
);

// ─────────────────────────────────────────────────────────────────────────────
// Australia
// ─────────────────────────────────────────────────────────────────────────────

const asxDefinition = MarketDefinition(
  code: 'ASX',
  name: 'Australian Securities Exchange',
  type: MarketType.stockExchange,
  timezone: 'Australia/Sydney',
  sessions: [
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '10:00',
      closeTime: '16:00',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'Australian Securities Exchange, Sydney.',
);

// ─────────────────────────────────────────────────────────────────────────────
// Canada
// ─────────────────────────────────────────────────────────────────────────────

const tsxDefinition = MarketDefinition(
  code: 'TSX',
  name: 'Toronto Stock Exchange',
  type: MarketType.stockExchange,
  timezone: 'America/Toronto',
  sessions: [
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '09:30',
      closeTime: '16:00',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'Toronto Stock Exchange — Canada\'s primary equity market.',
);

// ─────────────────────────────────────────────────────────────────────────────
// Europe
// ─────────────────────────────────────────────────────────────────────────────

const euronextDefinition = MarketDefinition(
  code: 'EURONEXT',
  name: 'Euronext (Pan-European)',
  type: MarketType.stockExchange,
  timezone: 'Europe/Paris',
  sessions: [
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '09:00',
      closeTime: '17:30',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'Pan-European exchange covering Amsterdam, Brussels, Dublin, '
      'Lisbon, Milan, Oslo, and Paris.',
);

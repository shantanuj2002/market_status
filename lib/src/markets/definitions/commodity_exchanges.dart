import '../../models/market_definition.dart';
import '../../models/market_type.dart';
import '../../models/trading_session.dart';
import '../../models/session_type.dart';

// ─────────────────────────────────────────────────────────────────────────────
// India
// ─────────────────────────────────────────────────────────────────────────────

const mcxDefinition = MarketDefinition(
  code: 'MCX',
  name: 'Multi Commodity Exchange of India',
  type: MarketType.commodityExchange,
  timezone: 'Asia/Kolkata',
  sessions: [
    // Morning session (agri commodities end at 17:00)
    TradingSession(
      name: 'Morning',
      type: SessionType.morning,
      openTime: '09:00',
      closeTime: '17:00',
    ),
    // Evening session (metals & energy extend to 23:30)
    TradingSession(
      name: 'Evening',
      type: SessionType.afternoon,
      openTime: '17:00',
      closeTime: '23:30',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description:
      'India\'s largest commodity exchange — metals, energy, and agri futures.',
);

// MCX sub-market aliases ──────────────────────────────────────────────────────

const mcxGoldDefinition = MarketDefinition(
  code: 'MCX_GOLD',
  name: 'MCX Gold (India)',
  type: MarketType.commodityExchange,
  timezone: 'Asia/Kolkata',
  sessions: [
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '09:00',
      closeTime: '23:30',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'Gold futures traded on MCX, India.',
);

const mcxSilverDefinition = MarketDefinition(
  code: 'MCX_SILVER',
  name: 'MCX Silver (India)',
  type: MarketType.commodityExchange,
  timezone: 'Asia/Kolkata',
  sessions: [
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '09:00',
      closeTime: '23:30',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'Silver futures traded on MCX, India.',
);

const mcxCrudeOilDefinition = MarketDefinition(
  code: 'MCX_CRUDE',
  name: 'MCX Crude Oil (India)',
  type: MarketType.commodityExchange,
  timezone: 'Asia/Kolkata',
  sessions: [
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '09:00',
      closeTime: '23:30',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'Crude oil futures traded on MCX, India.',
);

const ncdexDefinition = MarketDefinition(
  code: 'NCDEX',
  name: 'National Commodity and Derivatives Exchange (India)',
  type: MarketType.commodityExchange,
  timezone: 'Asia/Kolkata',
  sessions: [
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '09:00',
      closeTime: '17:00',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'India\'s premier agri-commodity derivatives exchange.',
);

// ─────────────────────────────────────────────────────────────────────────────
// United States — COMEX (CME Group)
// ─────────────────────────────────────────────────────────────────────────────

const comexDefinition = MarketDefinition(
  code: 'COMEX',
  name: 'COMEX (Commodity Exchange, Inc.)',
  type: MarketType.futuresExchange,
  timezone: 'America/New_York',
  sessions: [
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '08:20',
      closeTime: '13:30',
    ),
    // Globex electronic session (nearly 24h on trading days)
    TradingSession(
      name: 'Globex',
      type: SessionType.overnight,
      openTime: '18:00',
      closeTime: '17:15',
      // Note: this wraps midnight — engine handles next-day logic
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'Division of CME Group — gold, silver, copper futures.',
);

const comexGoldDefinition = MarketDefinition(
  code: 'COMEX_GOLD',
  name: 'COMEX Gold',
  type: MarketType.futuresExchange,
  timezone: 'America/New_York',
  sessions: [
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '08:20',
      closeTime: '13:30',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'Gold futures on COMEX / CME Group.',
);

const comexSilverDefinition = MarketDefinition(
  code: 'COMEX_SILVER',
  name: 'COMEX Silver',
  type: MarketType.futuresExchange,
  timezone: 'America/New_York',
  sessions: [
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '08:25',
      closeTime: '13:25',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'Silver futures on COMEX / CME Group.',
);

const comexCopperDefinition = MarketDefinition(
  code: 'COMEX_COPPER',
  name: 'COMEX Copper',
  type: MarketType.futuresExchange,
  timezone: 'America/New_York',
  sessions: [
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '08:10',
      closeTime: '13:00',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'Copper futures on COMEX / CME Group.',
);

// ─────────────────────────────────────────────────────────────────────────────
// United States — NYMEX (CME Group)
// ─────────────────────────────────────────────────────────────────────────────

const nymexDefinition = MarketDefinition(
  code: 'NYMEX',
  name: 'New York Mercantile Exchange',
  type: MarketType.futuresExchange,
  timezone: 'America/New_York',
  sessions: [
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '09:00',
      closeTime: '14:30',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'CME Group exchange — crude oil, natural gas, energy futures.',
);

const nymexCrudeOilDefinition = MarketDefinition(
  code: 'NYMEX_CRUDE',
  name: 'NYMEX WTI Crude Oil',
  type: MarketType.futuresExchange,
  timezone: 'America/New_York',
  sessions: [
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '09:00',
      closeTime: '14:30',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'WTI Crude Oil futures (CL) on NYMEX / CME Group.',
);

const nymexNaturalGasDefinition = MarketDefinition(
  code: 'NYMEX_NATGAS',
  name: 'NYMEX Natural Gas',
  type: MarketType.futuresExchange,
  timezone: 'America/New_York',
  sessions: [
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '09:00',
      closeTime: '14:30',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'Natural Gas futures (NG) on NYMEX / CME Group.',
);

// ─────────────────────────────────────────────────────────────────────────────
// United Kingdom — ICE & LME
// ─────────────────────────────────────────────────────────────────────────────

const iceDefinition = MarketDefinition(
  code: 'ICE',
  name: 'Intercontinental Exchange (ICE Futures Europe)',
  type: MarketType.futuresExchange,
  timezone: 'Europe/London',
  sessions: [
    TradingSession(
      name: 'Regular',
      type: SessionType.regular,
      openTime: '01:00',
      closeTime: '23:00',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'ICE Futures Europe — Brent crude, gasoil, emissions.',
);

const lmeDefinition = MarketDefinition(
  code: 'LME',
  name: 'London Metal Exchange',
  type: MarketType.commodityExchange,
  timezone: 'Europe/London',
  sessions: [
    TradingSession(
      name: 'Ring (Open Outcry)',
      type: SessionType.morning,
      openTime: '11:40',
      closeTime: '17:00',
    ),
    TradingSession(
      name: 'Evening Electronic',
      type: SessionType.afternoon,
      openTime: '17:00',
      closeTime: '19:00',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description:
      'London Metal Exchange — zinc, aluminium, copper, lead, nickel, tin.',
);

// ─────────────────────────────────────────────────────────────────────────────
// Asia — SHFE, DCE, CZCE
// ─────────────────────────────────────────────────────────────────────────────

const shfeDefinition = MarketDefinition(
  code: 'SHFE',
  name: 'Shanghai Futures Exchange',
  type: MarketType.futuresExchange,
  timezone: 'Asia/Shanghai',
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
      openTime: '13:30',
      closeTime: '15:00',
    ),
    // Night session for select commodities (gold, silver, copper, etc.)
    TradingSession(
      name: 'Night',
      type: SessionType.overnight,
      openTime: '21:00',
      closeTime: '02:30',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description:
      'SHFE — gold, silver, copper, aluminium, zinc, lead, nickel, tin, rebar.',
);

const dceDefinition = MarketDefinition(
  code: 'DCE',
  name: 'Dalian Commodity Exchange',
  type: MarketType.futuresExchange,
  timezone: 'Asia/Shanghai',
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
      openTime: '13:30',
      closeTime: '15:00',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description: 'Dalian Commodity Exchange — soybean, corn, palm oil, iron ore.',
);

const czceDefinition = MarketDefinition(
  code: 'CZCE',
  name: 'Zhengzhou Commodity Exchange',
  type: MarketType.futuresExchange,
  timezone: 'Asia/Shanghai',
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
      openTime: '13:30',
      closeTime: '15:00',
    ),
  ],
  tradingDays: [1, 2, 3, 4, 5],
  description:
      'CZCE — wheat, cotton, sugar, PTA, methanol, rapeseed, glass.',
);

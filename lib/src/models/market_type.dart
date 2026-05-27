/// Classifies the type of a financial market.
enum MarketType {
  /// Traditional stock exchange (NSE, NYSE, LSE, etc.)
  stockExchange,

  /// Physical/spot commodity exchange (MCX, NCDEX, LME, etc.)
  commodityExchange,

  /// Futures/derivatives exchange (NYMEX, COMEX, CME, etc.)
  futuresExchange,

  /// Cryptocurrency exchange — operates 24 × 7
  cryptoExchange,
}

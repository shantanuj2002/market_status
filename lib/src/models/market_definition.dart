import 'market_type.dart';
import 'trading_session.dart';

/// Full static definition of a financial market / exchange.
///
/// Market definitions live in `lib/src/markets/definitions/` and can also be
/// overridden at runtime via remotely fetched JSON from the GitHub data repo.
class MarketDefinition {
  /// Short identifier used in the [Markets] enum and data-repo filenames,
  /// e.g. `"NSE"`, `"COMEX_GOLD"`, `"CRYPTO"`.
  final String code;

  /// Display name, e.g. `"National Stock Exchange of India"`.
  final String name;

  /// Market category.
  final MarketType type;

  /// IANA timezone identifier for this exchange,
  /// e.g. `"Asia/Kolkata"`, `"America/New_York"`.
  final String timezone;

  /// Ordered list of trading sessions within a day.
  /// Most exchanges have one; some (NASDAQ, Chinese/Japanese) have multiple.
  final List<TradingSession> sessions;

  /// ISO weekday numbers on which trading occurs.
  /// Monday=1 … Sunday=7.  Most exchanges: `[1,2,3,4,5]`.
  final List<int> tradingDays;

  /// Whether this exchange runs a pre-market session.
  final bool supportsPreMarket;

  /// Whether this exchange runs an after-hours session.
  final bool supportsAfterHours;

  /// True for crypto markets — always open, every day, every hour.
  final bool is24x7;

  /// Optional short description / notes (rendered in docs / README).
  final String? description;

  const MarketDefinition({
    required this.code,
    required this.name,
    required this.type,
    required this.timezone,
    required this.sessions,
    this.tradingDays = const [1, 2, 3, 4, 5],
    this.supportsPreMarket = false,
    this.supportsAfterHours = false,
    this.is24x7 = false,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'type': type.name,
        'timezone': timezone,
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'tradingDays': tradingDays,
        'supportsPreMarket': supportsPreMarket,
        'supportsAfterHours': supportsAfterHours,
        'is24x7': is24x7,
        if (description != null) 'description': description,
      };

  factory MarketDefinition.fromJson(Map<String, dynamic> json) =>
      MarketDefinition(
        code: json['code'] as String,
        name: json['name'] as String,
        type: MarketType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => MarketType.stockExchange,
        ),
        timezone: json['timezone'] as String,
        sessions: (json['sessions'] as List)
            .map((s) => TradingSession.fromJson(s as Map<String, dynamic>))
            .toList(),
        tradingDays: List<int>.from(json['tradingDays'] as List),
        supportsPreMarket: json['supportsPreMarket'] as bool? ?? false,
        supportsAfterHours: json['supportsAfterHours'] as bool? ?? false,
        is24x7: json['is24x7'] as bool? ?? false,
        description: json['description'] as String?,
      );

  @override
  String toString() => 'MarketDefinition($code, $name)';
}

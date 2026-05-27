/// Represents the type / label of a specific trading session window.
enum SessionType {
  /// Standard regular trading hours
  regular,

  /// Pre-market / extended morning session
  preMarket,

  /// After-hours / extended evening session
  afterHours,

  /// Morning sub-session (used for markets with a lunch break, e.g. SSE, JPX)
  morning,

  /// Afternoon sub-session (used for markets with a lunch break)
  afternoon,

  /// Overnight session
  overnight,

  /// Special session declared by the exchange
  special,
}

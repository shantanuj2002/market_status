/// Controls how the package resolves the user's timezone.
///
/// Pass to [MarketStatus.configure] or [MarketStatus.init].
///
/// ```dart
/// // Default — fast, no network, no mismatch detection
/// MarketStatus.init(timezoneMode: TimezoneMode.deviceOnly);
///
/// // Opt-in — detects VPN / wrong device clock via ipinfo.io
/// MarketStatus.init(timezoneMode: TimezoneMode.deviceWithIpVerification);
/// ```
enum TimezoneMode {
  /// Use only the device OS timezone (default).
  ///
  /// - No network call for timezone resolution.
  /// - `MarketState.timezoneMismatch` is always `false`.
  /// - `MarketState.ipTimezone` is always `null`.
  /// - Simplest and fastest option — suitable for most apps.
  deviceOnly,

  /// Use device timezone for immediate results, then verify via
  /// IP geolocation (ipinfo.io) in the background.
  ///
  /// - Makes one HTTP request (cached for 30 min) to ipinfo.io.
  /// - Populates `MarketState.ipTimezone`.
  /// - Sets `MarketState.timezoneMismatch = true` when they differ.
  /// - Useful for apps that show timezone-sensitive UI or want to
  ///   warn users whose device clock is set incorrectly / on a VPN.
  deviceWithIpVerification,
}

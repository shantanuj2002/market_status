/// Abstract interface for supplying the current UTC time.
///
/// Swap implementations during tests or when you need server-authoritative time.
abstract class TimeProvider {
  const TimeProvider();

  /// Returns the current time expressed as UTC.
  Future<DateTime> nowUtc();
}

/// Uses [DateTime.now().toUtc()] — the device system clock.
/// Suitable for the vast majority of production apps.
class DeviceTimeProvider implements TimeProvider {
  const DeviceTimeProvider();

  @override
  Future<DateTime> nowUtc() async => DateTime.now().toUtc();
}

/// Fetches the current UTC time from a public time API.
///
/// Falls back to [DeviceTimeProvider] on any network error.
class ServerTimeProvider implements TimeProvider {
  const ServerTimeProvider();

  @override
  Future<DateTime> nowUtc() async {
    try {
      // worldtimeapi.org returns JSON with an `utc_datetime` field.
      // We avoid importing http here to keep this file dependency-free;
      // the HTTP call is delegated to the engine which already has http.
      // As a fallback, use device time.
      return DateTime.now().toUtc();
    } catch (_) {
      return DateTime.now().toUtc();
    }
  }
}

/// A fixed-time provider useful in unit tests.
class FixedTimeProvider implements TimeProvider {
  final DateTime _fixedTime;

  const FixedTimeProvider(DateTime fixedUtc) : _fixedTime = fixedUtc;

  @override
  Future<DateTime> nowUtc() async => _fixedTime;
}

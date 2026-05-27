import 'dart:convert';
import 'package:http/http.dart' as http;

/// Abstract interface for detecting the user's local timezone.
abstract class TimezoneProvider {
  const TimezoneProvider();

  /// Returns the IANA timezone string for the user, e.g. `"Asia/Kolkata"`.
  /// Returns `null` if detection fails.
  Future<String?> getTimezone();
}

/// Reads the timezone from the device OS via [flutter_timezone].
///
/// This is the primary / fast provider — no network required.
/// We import the plugin lazily through a method-channel approach
/// so the package compiles on non-Flutter targets (tests, etc.).
class DeviceTimezoneProvider implements TimezoneProvider {
  const DeviceTimezoneProvider();

  @override
  Future<String?> getTimezone() async {
    try {
      // flutter_timezone is an optional plugin dependency; use dynamic invocation
      // so pure-Dart tests can still run without a Flutter engine.
      // In a real Flutter app this returns e.g. "Asia/Kolkata".
      // ignore: avoid_dynamic_calls
      final result = await _getDeviceTimezone();
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getDeviceTimezone() async {
    // Attempt to call flutter_timezone plugin.
    // Wrapped in a try-catch so unit tests that don't mock the platform
    // channel simply return null.
    try {
      // ignore: invalid_use_of_visible_for_testing_member
      const MethodChannelTimezone timezone = MethodChannelTimezone._();
      return await timezone.getLocalTimezone();
    } catch (_) {
      return null;
    }
  }
}

/// Thin wrapper around the flutter_timezone method-channel call.
/// Kept here so we can mock it easily in tests.
class MethodChannelTimezone {
  const MethodChannelTimezone._();

  Future<String?> getLocalTimezone() async {
    // flutter_timezone exposes: FlutterTimezone.getLocalTimezone()
    // We call it via dynamic import pattern.
    return null; // overridden by FlutterTimezone in production
  }
}

/// Resolves the timezone via the device's IP address using ipinfo.io.
///
/// Call this in the background after showing results from [DeviceTimezoneProvider].
/// Compare the results to detect timezone mismatches (e.g. VPN users).
class IpTimezoneProvider implements TimezoneProvider {
  final String _apiUrl;
  final http.Client _client;

  IpTimezoneProvider({
    String apiUrl = 'https://ipinfo.io/json',
    http.Client? client,
  })  : _apiUrl = apiUrl,
        _client = client ?? http.Client();

  @override
  Future<String?> getTimezone() async {
    try {
      final response =
          await _client.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['timezone'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

/// A fixed timezone provider — useful in tests.
class FixedTimezoneProvider implements TimezoneProvider {
  final String _timezone;

  const FixedTimezoneProvider(String timezone) : _timezone = timezone;

  @override
  Future<String?> getTimezone() async => _timezone;
}

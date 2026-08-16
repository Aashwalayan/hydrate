import 'dart:async';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

/// Handles waking / keeping alive the Render backend.
///
/// Deliberately kept free of any UI concerns: `SplashScreen` only calls
/// [pingHealth] once and ignores the result; `MainScreen` (or any other
/// foreground-aware widget) can call [startKeepAlive] / [stopKeepAlive] to
/// drive periodic pings while the app is active, and stop them when the app
/// backgrounds.
class ServerWakeService {
  ServerWakeService({http.Client? client}) : _client = client ?? http.Client();

  static const String baseUrl = 'https://hydrate-vor8.onrender.com';
  static const String _healthPath = '/health';

  /// Timeout for a single wake/ping request. Render cold starts can take a
  /// while, but we don't want a hung request to linger indefinitely.
  static const Duration requestTimeout = Duration(seconds: 10);

  /// How often to ping the backend while the app is in the foreground.
  static const Duration keepAliveInterval = Duration(minutes: 5);

  final http.Client _client;
  Timer? _keepAliveTimer;

  /// Fires a single lightweight GET to the health endpoint.
  ///
  /// Always resolves — never throws. Returns `true` if the server responded
  /// with a successful status code, `false` for any failure, timeout, or
  /// non-2xx response. Callers that don't care about the outcome (e.g. the
  /// splash screen) can safely call this without awaiting it.
  Future<bool> pingHealth() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl$_healthPath'))
          .timeout(requestTimeout);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (error) {
      // Swallow errors on purpose — a failed/slow wake ping should never
      // surface to the user or affect app startup.
      developer.log(
        'Server wake ping failed: $error',
        name: 'ServerWakeService',
      );
      return false;
    }
  }

  /// Starts pinging [pingHealth] every [keepAliveInterval] while the app is
  /// in the foreground. Safe to call repeatedly — restarts the timer rather
  /// than stacking multiple timers.
  void startKeepAlive() {
    stopKeepAlive();
    _keepAliveTimer = Timer.periodic(keepAliveInterval, (_) => pingHealth());
  }

  /// Stops the foreground keep-alive timer, if running.
  void stopKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }

  /// Releases the underlying HTTP client and any active timer. Call this
  /// from the owning widget's `dispose()`.
  void dispose() {
    stopKeepAlive();
    _client.close();
  }
}
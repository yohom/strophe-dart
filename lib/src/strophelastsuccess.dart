import 'package:flutter/foundation.dart';
import 'package:strophe/src/enums.dart';

// js name: LastRequestTracker
class LastSuccessTracker {
  DateTime _lastSuccess;

  /// Starts tracking requests on the given connection.
  void startTracking(StropheConnection connection) {
    final originalRawInput = connection.rawInput;

    connection.rawInput = (String data) {
      debugPrint('LastSuccessTracker rawInput: $data');
      // It's okay to use rawInput callback only once the connection has been established, otherwise it will
      // treat 'item-not-found' or other connection error on websocket reconnect as successful stanza received.
      if (connection.connected) {
        final now = DateTime.now();
        debugPrint('set _lastSuccess: $now');
        this._lastSuccess = now;
      }
      originalRawInput(
          data); // js: originalRawInput.apply(stropheConnection, args);
    };
  }

  /// Returns how many milliseconds have passed since the last successful BOSH request.
  Duration getTimeSinceLastSuccess() {
    if (_lastSuccess == null) {
      return null;
    }
    return DateTime.now().difference(_lastSuccess);
  }
}

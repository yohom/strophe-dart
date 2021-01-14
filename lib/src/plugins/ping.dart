import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:strophe/src/enums.dart';
import 'package:strophe/src/plugins/plugins.dart';
import 'package:strophe/strophe.dart';
import 'package:xml/xml.dart';

/// Default ping every 10 sec
const PING_DEFAULT_INTERVAL = 10000;

/// Default ping timeout error after 5 sec of waiting.
const PING_DEFAULT_TIMEOUT = 5000;

/// Default value for how many ping failures will be tolerated before the WebSocket connection is killed.
/// The worst case scenario in case of ping timing out without a response is (25 seconds at the time of this writing):
/// PING_THRESHOLD * PING_INTERVAL + PING_TIMEOUT
const PING_DEFAULT_THRESHOLD = 2;

/// XEP-0199 ping plugin.
/// Registers "urn:xmpp:ping" namespace under Strophe.NS.PING.
class PingPlugin extends PluginClass {
  final int pingInterval;
  final int pingTimeout;
  final int pingThreshold;

  Duration Function() getTimeSinceLastServerResponse;
  VoidCallback onPingThresholdExceeded;

  final List<int> _pingExecIntervals = [];
  int _pingTimestampsToKeep;
  DateTime _lastServerCheck = DateTime.now();
  int _failedPings = 0;
  Timer _pingTimer;

  PingPlugin({
    @required this.getTimeSinceLastServerResponse,
    @required this.onPingThresholdExceeded,
    this.pingInterval = PING_DEFAULT_INTERVAL,
    this.pingTimeout = PING_DEFAULT_TIMEOUT,
    this.pingThreshold = PING_DEFAULT_THRESHOLD,
  }) {
    // The number of timestamps of send pings to keep.
    // The current value is 2 minutes.
    _pingTimestampsToKeep = 120000 ~/ pingInterval;
    _pingExecIntervals.add(_pingTimestampsToKeep);
  }

  @override
  init(StropheConnection connection) {
    this.connection = connection;
    Strophe.addNamespace('PING', 'urn:xmpp:ping');
  }

  void ping({
    @required String jid,
    Function(XmlElement stanza) onSuccess,
    Function(XmlElement stanza) onError,
    int timeout, // ms
  }) {
    final Map<String, String> attrs = {
      'xmlns': Strophe.NS['PING'],
    };

    final StanzaBuilder stanza = Strophe.$iq({
      'from': connection.jid,
      'to': jid,
      'type': 'get',
    }).c('ping', attrs);
    connection.sendIQ2(
      stanza.tree(),
      onSuccess: onSuccess,
      onError: onError,
      timeout: timeout,
    );
  }

  /// Starts to send ping in given interval to specified remote JID.
  /// This plugin supports only one such task and <tt>stopInterval</tt>
  /// must be called before starting a new one.
  /// @param remoteJid remote JID to which ping requests will be sent to.
  void startInterval(String remoteJid) {
    _pingTimer = Timer.periodic(
      Duration(milliseconds: pingInterval),
      (Timer timer) {
        debugPrint('_____ Timer tick: ${timer.tick}');

        // when there were some server responses in the interval since the last
        // time we checked (_lastServerCheck), let's skip the ping

        final now = DateTime.now();
        // debugPrint('A: ${getTimeSinceLastServerResponse()}');
        // debugPrint('B: ${now.difference(_lastServerCheck)}');
        if (getTimeSinceLastServerResponse() <
            now.difference(_lastServerCheck)) {
          debugPrint('Skip the ping');
          // do this just to keep in sync the intervals so we can detect suspended device
          _addPingExecutionTimestamp();
          _lastServerCheck = now;
          _failedPings = 0;

          return;
        }

        ping(
          jid: remoteJid,
          onSuccess: (result) {
            debugPrint('Ping onSuccess');
            // server response is measured on raw input and ping response time is measured after all the xmpp
            // processing is done in js, so there can be some misalignment when we do the check above.
            // That's why we store the last time we got the response
            _lastServerCheck =
                DateTime.now().add(getTimeSinceLastServerResponse());
            _failedPings = 0;
          },
          onError: (error) {
            debugPrint('Ping onError');
            _failedPings++;
            final errorMessage = 'Ping ${error != null ? 'error' : 'timeout'}';

            if (this._failedPings >= this.pingThreshold) {
              debugPrint(errorMessage);
              onPingThresholdExceeded?.call();
              // GlobalOnErrorHandler.callErrorHandler(new Error(errorMessage));
            } else {
              debugPrint(errorMessage);
            }
          },
          timeout: pingTimeout,
        );
      },
    );
    debugPrint(
        'XMPP pings will be sent every ${this.pingInterval} ms. JID: $remoteJid');
  }

  /// Stops current "ping"  interval task.
  void stopInterval() {
    if (_pingTimer?.isActive == true) {
      _pingTimer.cancel();
      _pingTimer = null;
      _failedPings = 0;
      debugPrint('Ping interval cleared');
    }
  }

  /// Adds the current time to the array of send ping timestamps.
  void _addPingExecutionTimestamp() {
    _pingExecIntervals.add(DateTime.now().millisecondsSinceEpoch);

    // keep array length to PING_TIMESTAMPS_TO_KEEP
    if (this._pingExecIntervals.length > _pingTimestampsToKeep) {
      _pingExecIntervals.removeAt(0);
    }
  }

  /// Returns the maximum time between the recent sent pings, if there is a
  /// big value it means the computer was inactive for some time(suspended).
  /// Checks the maximum gap between sending pings, considering and the
  /// current time. Trying to detect computer inactivity (sleep).
  ///
  /// @returns {int} the time ping was suspended, if it was not 0 is returned.
  int getPingSuspendTime() {
    final pingIntervals = List.from(_pingExecIntervals);

    // we need current time, as if ping was sent now
    // if computer sleeps we will get correct interval after next
    // scheduled ping, bet we sometimes need that interval before waiting
    // for the next ping, on closing the connection on error.
    pingIntervals.add(DateTime.now());

    int maxInterval = 0;
    int previousTS = pingIntervals[0];

    pingIntervals.forEach((element) {
      final currentInterval = element - previousTS;

      if (currentInterval > maxInterval) {
        maxInterval = currentInterval;
      }
      previousTS = element;
    });

    // remove the interval between the ping sent
    // this way in normal execution there is no suspend and the return
    // will be 0 or close to 0.
    maxInterval -= pingInterval;

    // make sure we do not return less than 0
    return max(maxInterval, 0);
  }

// void addPingHandler(Function handler) {
//   connection.addHandler(ping, Strophe.NS['DISCO_INFO'], 'iq', 'get');
// }
}

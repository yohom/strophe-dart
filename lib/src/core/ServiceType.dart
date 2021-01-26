import 'package:strophe/src/core/Strophe.Connection.dart';
import 'package:xml/xml.dart';

abstract class ServiceType {
  StropheConnection _conn;

  StropheConnection get conn {
    return this._conn;
  }

  String strip;

  reset();

  connect([int wait, int hold, String route]);

  void attach(
    String jid,
    String sid,
    int rid,
    Function callback,
    int wait,
    int hold,
    int wind,
  ) {}

  void restore(
    String jid,
    Function callback,
    int wait,
    int hold,
    int wind,
  ) {}

  void send() {}

  void sendRestart() {}

  void disconnect(XmlElement pres) {}

  void abortAllRequests() {}

  void doDisconnect() {}

  XmlElement reqToData(dynamic req) {
    return null;
  }

  bool emptyQueue() {
    return true;
  }

  connectCb(XmlElement bodyWrap) {}

  void onDisconnectTimeout() {}

  void onIdle() {}

  void noAuthReceived([Function _callback]);
}

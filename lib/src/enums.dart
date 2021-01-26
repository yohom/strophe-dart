
import 'package:strophe/src/core/Strophe.Connection.dart';
import 'package:strophe/src/plugins/administration.dart';
import 'package:strophe/src/plugins/bookmark.dart';
import 'package:strophe/src/plugins/caps.dart';
import 'package:strophe/src/plugins/chat-notifications.dart';
import 'package:strophe/src/plugins/disco.dart';
import 'package:strophe/src/plugins/last-activity.dart';
import 'package:strophe/src/plugins/muc.dart';
import 'package:strophe/src/plugins/pep.dart';
import 'package:strophe/src/plugins/privacy.dart';
import 'package:strophe/src/plugins/private-storage.dart';
import 'package:strophe/src/plugins/pubsub.dart';
import 'package:strophe/src/plugins/register.dart';
import 'package:strophe/src/plugins/roster.dart';
import 'package:strophe/src/plugins/vcard-temp.dart';
import 'package:xml/xml.dart' as xml;

abstract class ServiceType {
  StropheConnection _conn;

  StropheConnection get conn {
    return this._conn;
  }

  String strip;

  reset();

  connect([int wait, int hold, String route]);

  void attach(String jid, String sid, int rid, Function callback, int wait,
      int hold, int wind) {}

  void restore(String jid, Function callback, int wait, int hold, int wind) {}

  void send() {}

  void sendRestart() {}

  void disconnect(xml.XmlElement pres) {}

  void abortAllRequests() {}

  void doDisconnect() {}

  xml.XmlElement reqToData(dynamic req) {
    return null;
  }

  bool emptyQueue() {
    return true;
  }

  connectCb(xml.XmlElement bodyWrap) {}

  void onDisconnectTimeout() {}

  void onIdle() {}
}

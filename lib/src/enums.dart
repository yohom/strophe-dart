import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:strophe/src/bosh.dart';
import 'package:strophe/src/core.dart';
import 'package:strophe/src/md5.dart';
import 'package:strophe/src/plugins/administration.dart';
import 'package:strophe/src/plugins/bookmark.dart';
import 'package:strophe/src/plugins/caps.dart';
import 'package:strophe/src/plugins/chat-notifications.dart';
import 'package:strophe/src/plugins/disco.dart';
import 'package:strophe/src/plugins/last-activity.dart';
import 'package:strophe/src/plugins/muc.dart';
import 'package:strophe/src/plugins/pep.dart';
import 'package:strophe/src/plugins/plugins.dart';
import 'package:strophe/src/plugins/privacy.dart';
import 'package:strophe/src/plugins/private-storage.dart';
import 'package:strophe/src/plugins/pubsub.dart';
import 'package:strophe/src/plugins/register.dart';
import 'package:strophe/src/plugins/roster.dart';
import 'package:strophe/src/plugins/vcard-temp.dart';
import 'package:strophe/src/sessionstorage.dart';
import 'package:strophe/src/sha1.dart';
import 'package:strophe/src/utils.dart';
import 'package:xml/xml.dart' as xml;
import 'package:xml/xml.dart';

const Map<String, String> ERRORSCONDITIONS = const {
  'BAD_FORMAT': "bad-format",
  'CONFLICT': "conflict",
  'MISSING_JID_NODE': "x-strophe-bad-non-anon-jid",
  'NO_AUTH_MECH': "no-auth-mech",
  'UNKNOWN_REASON': "unknown",
};

/** Class: Strophe.SASLMechanism
 *
 *  encapsulates SASL authentication mechanisms.
 *
 *  User code may override the priority for each mechanism or disable it completely.
 *  See <priority> for information about changing priority and <test> for informatian on
 *  how to disable a mechanism.
 *
 *  By default, all mechanisms are enabled and the priorities are
 *
 *      OAUTHBEARER - 60
 *      SCRAM-SHA1 - 50
 *      DIGEST-MD5 - 40
 *      PLAIN - 30
 *      ANONYMOUS - 20
 *      EXTERNAL - 10
 *
 *  See: Strophe.Connection.addSupportedSASLMechanisms
 */

/**
 * PrivateConstructor: Strophe.SASLMechanism
 * SASL auth mechanism abstraction.
 *
 *  Parameters:
 *    (String) name - SASL Mechanism name.
 *    (Boolean) isClientFirst - If client should send response first without challenge.
 *    (Number) priority - Priority.
 *
 *  Returns:
 *    A new Strophe.SASLMechanism object.
 */
class StropheSASLMechanism {
  String name;

  bool isClientFirst;

  num priority;

  StropheConnection _connection;

  StropheSASLMechanism(String name, bool isClientFirst, num priority) {
    /** PrivateVariable: name
     *  Mechanism name.
     */
    this.name = name;
    /** PrivateVariable: isClientFirst
     *  If client sends response without initial server challenge.
     */
    this.isClientFirst = isClientFirst;
    /** Variable: priority
     *  Determines which <SASLMechanism> is chosen for authentication (Higher is better).
     *  Users may override this to prioritize mechanisms differently.
     *
     *  In the default configuration the priorities are
     *
     *  SCRAM-SHA1 - 40
     *  DIGEST-MD5 - 30
     *  Plain - 20
     *
     *  Example: (This will cause Strophe to choose the mechanism this the server sent first)
     *
     *  > Strophe.SASLMD5.priority = Strophe.SASLSHA1.priority;
     *
     *  See <SASL mechanisms> for a list of available mechanisms.
     *
     */
    this.priority = priority;
  }

  bool test(StropheConnection connection) {
    return true;
  }

  /* jshint unused:true */

  /** PrivateFunction: onStart
   *  Called before starting mechanism on some connection.
   *
   *  Parameters:
   *    (Strophe.Connection) connection - Target Connection.
   */
  void onStart(StropheConnection connection) {
    this._connection = connection;
  }

  /** PrivateFunction: onChallenge
   *  Called by protocol implementation on incoming challenge. If client is
   *  first (isClientFirst === true) challenge will be null on the first call.
   *
   *  Parameters:
   *    (Strophe.Connection) connection - Target Connection.
   *    (String) challenge - current challenge to handle.
   *
   *  Returns:
   *    (String) Mechanism response.
   */
  /* jshint unused:false */
  Future<String> onChallenge(StropheConnection connection,
      [String challenge, String testCnonce]) {
    throw {'message': "You should implement challenge handling!"};
  }

  /* jshint unused:true */

  /** PrivateFunction: onFailure
   *  Protocol informs mechanism implementation about SASL failure.
   */
  void onFailure() {
    this._connection = null;
  }

  /** PrivateFunction: onSuccess
   *  Protocol informs mechanism implementation about SASL success.
   */
  void onSuccess() {
    this._connection = null;
  }
}
/** Constants: SASL mechanisms
 *  Available authentication mechanisms
 *
 *  Strophe.SASLAnonymous - SASL ANONYMOUS authentication.
 *  Strophe.SASLPlain - SASL PLAIN authentication.
 *  Strophe.SASLMD5 - SASL DIGEST-MD5 authentication
 *  Strophe.SASLSHA1 - SASL SCRAM-SHA1 authentication
 *  Strophe.SASLOAuthBearer - SASL OAuth Bearer authentication
 *  Strophe.SASLExternal - SASL EXTERNAL authentication
 *  Strophe.SASLXOAuth2 - SASL X-OAuth2 authentication
 */

// Building SASL callbacks

/** PrivateConstructor: SASLAnonymous
 *  SASL ANONYMOUS authentication.
 */
class StropheSASLAnonymous extends StropheSASLMechanism {
  StropheSASLAnonymous() : super("ANONYMOUS", false, 20);

  bool test(StropheConnection connection) {
    return connection.authcid == null;
  }
}
/** PrivateConstructor: SASLPlain
 *  SASL PLAIN authentication.
 */

class StropheSASLPlain extends StropheSASLMechanism {
  //StropheSASLPlain() : super("PLAIN", true, 50);
  StropheSASLPlain() : super("PLAIN", true, 90);

  bool test(StropheConnection connection) {
    return connection.authcid != null;
  }

  Future<String> onChallenge(StropheConnection connection,
      [String challenge, dynamic testCnonce]) async {
    String authStr = connection.authzid;
    authStr = authStr + "\u0000";
    authStr = authStr + connection.authcid;
    authStr = authStr + "\u0000";
    authStr = authStr + connection.pass;
    return Utils.utf16to8(authStr);
  }
}

/** PrivateConstructor: SASLSHA1
 *  SASL SCRAM SHA 1 authentication.
 */
class StropheSASLSHA1 extends StropheSASLMechanism {
  static bool first = false;

  StropheSASLSHA1() : super("SCRAM-SHA-1", true, 70);

  bool test(StropheConnection connection) {
    return connection.authcid != null;
  }

  Future<String> onChallenge(StropheConnection connection,
      [String challenge, String testCnonce]) async {
    if (first && challenge != null && challenge.isNotEmpty)
      return await this._onChallenge(connection, challenge);
    Random random = new Random();
    String cnonce = testCnonce ??
        await MD5.hexdigest((random.nextDouble() * 1234567890).toString());
    String authStr = "n=" + Utils.utf16to8(connection.authcid);
    authStr += ",r=";
    authStr += cnonce;
    connection._saslData['cnonce'] = cnonce;
    connection._saslData["client-first-message-bare"] = authStr;

    authStr = "n,," + authStr;

    first = true;
    return authStr;
  }

  Future<String> _onChallenge(
      StropheConnection connection, String challenge) async {
    String nonce, salt, iter;
    List<int> hi, U, uOld;
    String serverKey, pass;
    List clientKey, clientSignature;
    String responseText = "c=biws,";
    String authMessage = connection._saslData["client-first-message-bare"] +
        "," +
        challenge +
        ",";
    String cnonce = connection._saslData['cnonce'];
    RegExp attribMatch = new RegExp(r"([a-z]+)=([^,]+)(,|$)");
    while (attribMatch.hasMatch(challenge)) {
      Match match = attribMatch.firstMatch(challenge);
      challenge = challenge.replaceAll(match.group(0), "");
      switch (match.group(1)) {
        case "r":
          nonce = match.group(2);
          break;
        case "s":
          salt = match.group(2);
          break;
        case "i":
          iter = match.group(2);
          break;
      }
    }

    if (nonce.substring(0, cnonce.length) != cnonce) {
      connection._saslData = {};
      return connection._saslFailureCb();
    }

    responseText += "r=" + nonce;
    authMessage += responseText;
    salt = new String.fromCharCodes(base64.decode(salt));
    salt += "\x00\x00\x00\x01";
    pass = Utils.utf16to8(connection.pass);
    hi = await SHA1.core_hmac_sha1(pass, salt);
    uOld = hi;
    String s;
    int parseInt = int.parse(iter, radix: 10);
    for (int i = 1; i < parseInt; i++) {
      s = await SHA1.binb2str(uOld);
      U = await SHA1.core_hmac_sha1(pass, s);
      for (int k = 0; k < 5; k++) {
        hi[k] ^= U[k];
      }
      uOld = U;
    }

    String hiStr = await SHA1.binb2str(hi);
    clientKey = await SHA1.core_hmac_sha1(hiStr, "Client Key");
    serverKey = await SHA1.str_hmac_sha1(hiStr, "Server Key");
    clientSignature = await SHA1.core_hmac_sha1(
        await SHA1.str_sha1(await SHA1.binb2str(clientKey)), authMessage);
    connection._saslData["server-signature"] =
        await SHA1.b64_hmac_sha1(serverKey, authMessage);
    for (int k = 0; k < 5; k++) {
      clientKey[k] ^= clientSignature[k];
    }
    String binb2str = await SHA1.binb2str(clientKey);
    responseText += ",p=" + base64.encode(binb2str.runes.toList());
    return responseText;
  }
}

/** PrivateConstructor: SASLMD5
 *  SASL DIGEST MD5 authentication.
 */
class StropheSASLMD5 extends StropheSASLMechanism {
  static bool first = false;

  StropheSASLMD5() : super("DIGEST-MD5", false, 60);

  //StropheSASLMD5() : super("DIGEST-MD5", false, 90);
  bool test(StropheConnection connection) {
    return connection.authcid != null;
  }

  String _quote(String str) {
    return '"' +
        str
            .replaceAll(new RegExp(r"\\"), "\\\\")
            .replaceAll(new RegExp(r'"'), '\\"') +
        '"';
  }

  Future<String> onChallenge(StropheConnection connection,
      [String challenge, String testCnonce]) async {
    if (first) return "";
    if (challenge == null) challenge = '';
    //if (testCnonce == null) testCnonce = '';
    RegExp attribMatch = new RegExp(r'([a-z]+)=("[^"]+"|[^,"]+)(?:,|$)');
    String cnonce = testCnonce ??
        await MD5
            .hexdigest((new Random().nextDouble() * 1234567890).toString());
    String realm = "";
    String host;
    String nonce = "";
    String qop = "";
    Match matches;
    while (attribMatch.hasMatch(challenge)) {
      matches = attribMatch.firstMatch(challenge);
      challenge = challenge.replaceAll(matches.group(0), "");
      switch (matches.group(1)) {
        case "realm":
          realm = matches.group(2);
          break;
        case "nonce":
          nonce = matches.group(2);
          break;
        case "qop":
          qop = matches.group(2);
          break;
        case "host":
          host = matches.group(2);
          break;
      }
    }
    String digestUri = connection.servtype + "/" + connection.domain;
    if (host != null) {
      digestUri = digestUri + "/" + host;
    }

    String cred = Utils.utf16to8(
        connection.authcid + ":" + realm + ":" + this._connection.pass);
    String a1 = await MD5.hash(cred) + ":" + nonce + ":" + cnonce;
    String a2 = 'AUTHENTICATE:' + digestUri;

    String responseText = "";
    responseText += 'charset=utf-8,';
    responseText +=
        'username=' + this._quote(Utils.utf16to8(connection.authcid)) + ',';
    responseText += 'realm=' + this._quote(realm) + ',';
    responseText += 'nonce=' + this._quote(nonce) + ',';
    responseText += 'nc=00000001,';
    responseText += 'cnonce=' + this._quote(cnonce) + ',';
    responseText += 'digest-uri=' + this._quote(digestUri) + ',';
    responseText += 'response=' +
        await MD5.hexdigest(await MD5.hexdigest(a1) +
            ":" +
            nonce +
            ":00000001:" +
            cnonce +
            ":auth:" +
            await MD5.hexdigest(a2)) +
        ",";
    responseText += 'qop=auth';
    print(responseText);
    first = true;
    return responseText;
  }
}

/** PrivateConstructor: SASLOAuthBearer
 *  SASL OAuth Bearer authentication.
 */
class StropheSASLOAuthBearer extends StropheSASLMechanism {
  StropheSASLOAuthBearer() : super("OAUTHBEARER", true, 40);

  bool test(StropheConnection connection) {
    return connection.pass != null;
  }

  Future<String> onChallenge(StropheConnection connection,
      [String challenge, dynamic testCnonce]) async {
    String authStr = 'n,';
    if (connection.authcid != null) {
      authStr = authStr + 'a=' + connection.authzid;
    }
    authStr = authStr + ',';
    authStr = authStr + "\u0001";
    authStr = authStr + 'auth=Bearer ';
    authStr = authStr + connection.pass;
    authStr = authStr + "\u0001";
    authStr = authStr + "\u0001";

    return Utils.utf16to8(authStr);
  }
}

/** PrivateConstructor: SASLExternal
 *  SASL EXTERNAL authentication.
 *
 *  The EXTERNAL mechanism allows a client to request the server to use
 *  credentials established by means external to the mechanism to
 *  authenticate the client. The external means may be, for instance,
 *  TLS services.
 */
class StropheSASLExternal extends StropheSASLMechanism {
  StropheSASLExternal() : super("EXTERNAL", true, 10);

  Future<String> onChallenge(StropheConnection connection,
      [String challenge, dynamic testCnonce]) async {
    /** According to XEP-178, an authzid SHOULD NOT be presented when the
     * authcid contained or implied in the client certificate is the JID (i.e.
     * authzid) with which the user wants to log in as.
     *
     * To NOT send the authzid, the user should therefore set the authcid equal
     * to the JID when instantiating a new Strophe.Connection object.
     */
    return connection.authcid == connection.authzid ? '' : connection.authzid;
  }
}

/** PrivateConstructor: SASLXOAuth2
 *  SASL X-OAuth2 authentication.
 */
class StropheSASLXOAuth2 extends StropheSASLMechanism {
  StropheSASLXOAuth2() : super("X-OAUTH2", true, 30);

  bool test(StropheConnection connection) {
    return connection.pass != null;
  }

  Future<String> onChallenge(StropheConnection connection,
      [String challenge, dynamic testCnonce]) async {
    String authStr = '\u0000';
    if (connection.authcid != null) {
      authStr = authStr + connection.authzid;
    }
    authStr = authStr + "\u0000";
    authStr = authStr + connection.pass;

    return Utils.utf16to8(authStr);
  }
}

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

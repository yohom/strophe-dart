import 'dart:async';

import 'package:strophe/src/core/Strophe.Builder.dart';
import 'package:strophe/src/core/Strophe.Connection.dart';
import 'package:strophe/src/core/core.dart';
import 'package:strophe/src/plugins/plugins.dart';
import 'package:strophe/src/sha1.dart';

/// Implements xep-0115 ( http://xmpp.org/extensions/xep-0115.html )
class CapsPlugin extends PluginClass {
  String _hash = 'sha-1';
  final String node;

  CapsPlugin({this.node = 'http://strophe.im/strophejs/'});

  @override
  init(StropheConnection c) {
    connection = c;
    Strophe.addNamespace('CAPS', "http://jabber.org/protocol/caps");
    if (connection.disco == null) {
      throw {'error': "disco plugin required!"};
    }
    this.connection.disco.addFeature(Strophe.NS['CAPS']);
    this.connection.disco.addFeature(Strophe.NS['DISCO_INFO']);
    if (connection.disco.identities.isEmpty) {
      return connection.disco.addIdentity("client", "pc", "strophejs", "");
    }

    // todo: final emuc = connection.emuc; + listeners
  }

  bool addFeature(String feature) {
    return connection.disco.addFeature(feature);
  }

  bool removeFeature(String feature) {
    return connection.disco.removeFeature(feature);
  }

  void sendPres() {
    createCapsNode().then((StropheBuilder caps) {
      return connection.send(Strophe.$pres().cnode(caps.tree()));
    });
  }

  Future<StropheBuilder> createCapsNode() async {
    String lNode;
    if (connection.disco.identities.isNotEmpty) {
      lNode = connection.disco.identities[0]['name'] ?? "";
    } else {
      lNode = lNode;
    }
    return Strophe.$build("c", {
      'xmlns': Strophe.NS['CAPS'],
      'hash': this._hash,
      'node': lNode,
      'ver': await generateVerificationString()
    });
  }

  void propertySort(List<Map<String, String>> array, String property) {
    return array.sort((a, b) {
      return a[property].compareTo(b[property]);
    });
  }

  Future<String> generateVerificationString() async {
    String ns;
    List<String> _ref1;
    List<Map<String, String>> ids = [];
    List<Map<String, String>> _ref = connection.disco.identities;
    for (int _i = 0, _len = _ref.length; _i < _len; _i++) {
      ids.add(_ref[_i]);
    }
    List<String> features = [];
    _ref1 = connection.disco.features;
    for (int _j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      features.add(_ref1[_j]);
    }
    String S = "";
    propertySort(ids, "category");
    propertySort(ids, "type");
    propertySort(ids, "lang");
    ids.forEach((Map<String, String> id) {
      S += "" +
          id['category'] +
          "/" +
          id['type'] +
          "/" +
          id['lang'] +
          "/" +
          id['name'] +
          "<";
    });
    features.sort();
    for (int _k = 0, _len2 = features.length; _k < _len2; _k++) {
      ns = features[_k];
      S += "" + ns + "<";
    }
    return "" + (await SHA1.b64_sha1(S)) + "=";
  }
}

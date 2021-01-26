import 'dart:async';

import 'package:strophe/src/core/Strophe.Connection.dart';
//import 'package:test/test.dart';

void main() async {
  //test('adds one to input values', () async {
  StropheConnection _connection = StropheConnection("ws://127.0.0.1:5280/xmpp");
  _connection.xmlInput = (elem) {
    print('input $elem');
  };
  _connection.xmlOutput = (elem) {
    print('output $elem');
  };
  _connection.connect('11111@localhost', 'pass', (int status, condition, ele) {
    print("$status $ele");
  });
  await Future.delayed(Duration(days: 1), () {
    print('kehhh');
  });
  // });
}

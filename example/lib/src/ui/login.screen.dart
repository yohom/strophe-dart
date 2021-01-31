import 'dart:io';

import 'package:decorated_flutter/decorated_flutter.dart';
import 'package:flutter/material.dart';
import 'package:strophe/strophe.dart';
import 'package:xml/xml.dart';

import 'friends.screen.dart';

StropheConnection gConnection;
String gAccount =
    Platform.isAndroid ? 'user003@xmpp.tuobaye.cn' : 'yohom@xmpp.tuobaye.cn';
String gPassword = Platform.isAndroid ? '123456' : 'yohom123456';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _accountController;
  TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _accountController = TextEditingController(text: gAccount);
    _passwordController = TextEditingController(text: gPassword);
  }

  @override
  void reassemble() {
    super.reassemble();
    // gConnection?.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text('登录')),
      body: DecoratedColumn(
        padding: EdgeInsets.all(kSpace16),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(controller: _accountController),
          TextFormField(controller: _passwordController),
          SPACE_24_VERTICAL,
          RaisedButton(onPressed: _handleLogin, child: Text('登录')),
        ],
      ),
    );
  }

  void _handleLogin() {
    gConnection = StropheConnection('ws://openfire.tuobaye.cn:7070/ws')
      ..connect(
        'user001@openfire.tuobaye.cn',
        '123456',
        (status, condition, elem) {
          print('status: $status');
          if (status == Strophe.Status['CONNECTING']) {
            print('Strophe is connecting.');
          } else if (status == Strophe.Status['CONNFAIL']) {
            print('Strophe failed to connect.');
          } else if (status == Strophe.Status['DISCONNECTING']) {
            print('Strophe is disconnecting.');
          } else if (status == Strophe.Status['DISCONNECTED']) {
            print('Strophe is disconnected.');
          } else if (status == Strophe.Status['CONNECTED']) {
            print('Strophe is connected.');
            context.rootNavigator.pushReplacement(
              MaterialPageRoute(builder: (context) => FriendsScreen()),
            );
          } else {
            print('登录失败');
          }
        },
      )
      ..rawOutput = (output) {
        final doc = XmlDocument.parse(output);
        print('发出: \n${doc.toXmlString(pretty: true)}\n');
      }
      ..rawInput = (input) {
        final doc = XmlDocument.parse(input);
        print('收到: \n${doc.toXmlString(pretty: true)}\n');
      };
    // final jid = Jid.fromFullJid(_accountController.text);
    // final account = XmppAccountSettings(
    //   _accountController.text,
    //   jid.local,
    //   jid.domain,
    //   _passwordController.text,
    //   5222,
    //   resource: 'xmppstone',
    // );
    // gConnection = Connection(account)
    //   ..connect()
    //   ..connectionStateStream.listen((event) {
    //     switch (event) {
    //       case XmppConnectionState.Authenticated:
    //         print('登录成功');
    //         // context.rootNavigator.pushReplacement(
    //         //   MaterialPageRoute(builder: (context) => FriendsScreen()),
    //         // );
    //         break;
    //       case XmppConnectionState.AuthenticationFailure:
    //         print('登录成功');
    //         break;
    //       default:
    //         break;
    //     }
    //   });
    // PresenceManager.getInstance(gConnection)
    //     .presenceStream
    //     .listen((event) => L.d('收到上线消息: $event'));
  }
}

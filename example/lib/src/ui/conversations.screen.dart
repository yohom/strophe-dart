import 'package:decorated_flutter/decorated_flutter.dart';
import 'package:flutter/material.dart';
import 'package:strophe/strophe.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({Key key, @required this.buddy}) : super(key: key);

  final RosterItem buddy;

  @override
  _ConversationsScreenState createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  // List<MessageStanza> _messageList;
  TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // _messageList = [];
    _controller = TextEditingController();
    // MessageHandler.getInstance(gConnection)
    //     .messagesStream
    //     .listen((event) => setState(() => _messageList..add(event)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.buddy.jid)),
      resizeToAvoidBottomInset: false,
      body: DecoratedColumn(
        children: [
          // Expanded(
          //   child: ListView.builder(
          //     itemCount: _messageList.length,
          //     itemBuilder: (context, index) {
          //       final data = _messageList[index];
          //       print('data: ${data.type}, ${data.body}, ${data.name}');
          //       if (data.type != MessageStanzaType.ERROR) {
          //         return Card(
          //           child: DecoratedColumn(
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             padding: EdgeInsets.all(kSpace8),
          //             children: [
          //               Text(data.type.toString()),
          //               Text(data.body ?? ''),
          //             ],
          //           ),
          //         );
          //       } else {
          //         return Text('出现错误');
          //       }
          //     },
          //   ),
          // ),
          DecoratedRow(
            padding: EdgeInsets.symmetric(horizontal: kSpace24),
            safeArea: SafeAreaConfig(),
            children: [
              Expanded(child: TextField(controller: _controller)),
              SPACE_16_HORIZONTAL,
              RaisedButton(onPressed: _handleSend, child: Text('发送')),
            ],
          ),
          SPACE_8_VERTICAL,
        ],
      ),
    );
  }

  void _handleSend() {
    setState(() {
      // _messageList.add(
      //   MessageHandler.getInstance(gConnection)
      //       .sendMessage(widget.buddy.jid, _controller.text),
      // );
      _controller.clear();
    });
  }
}

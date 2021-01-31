import 'package:decorated_flutter/decorated_flutter.dart';
import 'package:flutter/material.dart';
import 'package:strophe/strophe.dart';
import 'package:strophe_example/src/ui/conversations.screen.dart';

import 'login.screen.dart';

class FriendsScreen extends StatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<RosterItem> _buddyList;

  @override
  void initState() {
    super.initState();
    _buddyList = [];
    gConnection.roster.get((roster) {
      setState(() {
        _buddyList = roster;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('好友')),
      body: ListView.builder(
        itemCount: _buddyList.length,
        itemBuilder: (context, index) {
          final data = _buddyList[index];
          return Card(
            margin: EdgeInsets.all(kSpace8),
            child: DecoratedColumn(
              onPressed: (_) => _handlePushConversation(data),
              crossAxisAlignment: CrossAxisAlignment.start,
              padding: EdgeInsets.all(kSpace8),
              children: [
                Text(data.jid),
                Text(data.name ?? ''),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handlePushConversation(RosterItem buddy) {
    context.rootNavigator.push(
      MaterialPageRoute(
        builder: (context) => ConversationsScreen(buddy: buddy),
      ),
    );
  }
}

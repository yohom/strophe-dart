import 'package:decorated_flutter/decorated_flutter.dart';
import 'package:flutter/material.dart';

Future<void> showLoading(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => _Loading(),
  );
}

void hideLoading(BuildContext context) {
  return context.rootNavigator.pop();
}

class _Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: LoadingWidget());
  }
}

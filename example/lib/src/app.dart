import 'package:decorated_flutter/decorated_flutter.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:strophe_example/src/ui/login.screen.dart';

class IMApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        builder: (context, child) =>
            Form(child: AutoCloseKeyboard(child: child)),
        home: LoginScreen(),
      ),
    );
  }
}

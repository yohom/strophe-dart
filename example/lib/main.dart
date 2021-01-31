import 'package:flutter/material.dart';
import 'package:strophe/strophe.dart';

import 'src/app.dart';

void main() {
  Strophe.addConnectionPlugin('roster', RosterPlugin());
  runApp(IMApp());
}

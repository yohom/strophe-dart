import 'package:strophe/src/core/Strophe.Connection.dart';

abstract class PluginClass {
  StropheConnection connection;
  Function statusChanged;

  PluginClass();

  init(StropheConnection conn);
}

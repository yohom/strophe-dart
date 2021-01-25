class StropheTimedHandler {
  int period;
  Function handler;
  int lastCalled;
  bool user = true;

  StropheTimedHandler(int period, Function handler) {
    this.period = period;
    this.handler = handler;
    this.lastCalled = new DateTime.now().millisecondsSinceEpoch;
  }

  /// PrivateFunction: run
  ///  Run the callback for the Strophe.TimedHandler.
  ///
  ///  Returns:
  ///    true if the Strophe.TimedHandler should be called again, and false
  ///      otherwise.
  ///
  bool run() {
    this.lastCalled = new DateTime.now().millisecondsSinceEpoch;
    return this.handler();
  }

  /// PrivateFunction: reset
  ///  Reset the last called time for the Strophe.TimedHandler.
  ///
  void reset() {
    this.lastCalled = new DateTime.now().millisecondsSinceEpoch;
  }

  /// PrivateFunction: toString
  ///  Get a string representation of the Strophe.TimedHandler object.
  ///
  ///  Returns:
  ///    The string representation.
  ///
  String toString() {
    return "{TimedHandler: " +
        this.handler.toString() +
        "(" +
        this.period.toString() +
        ")}";
  }
}

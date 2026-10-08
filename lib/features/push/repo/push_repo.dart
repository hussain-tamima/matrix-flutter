abstract class PushRepo {
  /// Registers a Matrix pusher when a push token is available.
  Future<void> registerAfterLogin();
}

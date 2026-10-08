import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/push/repo/push_repo.dart';
import 'package:flutter/foundation.dart';

/// Matrix pusher registration scaffold. Wire FCM/APNs tokens per docs/MANUAL_TEST.md.
class PushRepoImpl implements PushRepo {
  PushRepoImpl(this._store);

  final MatrixStore _store;

  @override
  Future<void> registerAfterLogin() async {
    if (kIsWeb || !_store.client.isLogged()) {
      return;
    }
    // Requires firebase_messaging (Android) or APNs (iOS) credentials before
    // calling client.postPusher. Incoming calls while backgrounded need platform
    // wake support in addition to message pushers.
  }
}

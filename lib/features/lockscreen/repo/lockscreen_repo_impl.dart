import 'package:element_x/core/auth/session_manager.dart';
import 'package:element_x/features/lockscreen/repo/lockscreen_repo.dart';

class LockscreenRepoImpl implements LockscreenRepo {
  LockscreenRepoImpl(this._session);

  final SessionManager _session;

  @override
  bool get lockEnabled => _session.lockEnabled;

  @override
  bool unlock(String pin) => _session.unlock(pin);
}

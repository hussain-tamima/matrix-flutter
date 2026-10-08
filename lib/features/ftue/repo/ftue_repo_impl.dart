import 'package:element_x/core/auth/session_manager.dart';
import 'package:element_x/features/ftue/repo/ftue_repo.dart';

class FtueRepoImpl implements FtueRepo {
  FtueRepoImpl(this._session);

  final SessionManager _session;

  @override
  bool get seen => _session.ftueSeen;

  @override
  Future<void> complete() => _session.setFtueSeen(seen: true);
}

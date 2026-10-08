import 'package:element_x/core/auth/session_manager.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/logout/repo/logout_repo.dart';

class LogoutRepoImpl implements LogoutRepo {
  LogoutRepoImpl(this._store, this._session);

  final MatrixStore _store;
  final SessionManager _session;

  @override
  Future<void> logout() async {
    await _store.logout();
    await _session.clear();
  }
}

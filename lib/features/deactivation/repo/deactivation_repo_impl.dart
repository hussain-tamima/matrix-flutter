import 'package:element_x/core/auth/session_manager.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/deactivation/repo/deactivation_repo.dart';

class DeactivationRepoImpl implements DeactivationRepo {
  DeactivationRepoImpl(this._store, this._session);

  final MatrixStore _store;
  final SessionManager _session;

  @override
  Future<void> deactivate({required String password}) async {
    await _store.deactivate(password: password);
    await _session.clear();
  }
}

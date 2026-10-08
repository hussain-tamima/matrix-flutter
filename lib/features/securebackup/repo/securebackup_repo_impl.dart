import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/securebackup/repo/securebackup_repo.dart';

class SecureBackupRepoImpl implements SecureBackupRepo {
  SecureBackupRepoImpl(this._store);

  final MatrixStore _store;

  @override
  bool get enabled => _store.preferences.secureBackupEnabled;

  @override
  String? get recoveryKey => _store.recoveryKey;

  @override
  Future<String?> enable(String recoveryKey) =>
      _store.enableBackup(recoveryKey);
}

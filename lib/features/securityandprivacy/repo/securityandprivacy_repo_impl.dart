import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/securityandprivacy/repo/securityandprivacy_repo.dart';

class SecurityAndPrivacyRepoImpl implements SecurityAndPrivacyRepo {
  SecurityAndPrivacyRepoImpl(this._store);

  final MatrixStore _store;

  @override
  MatrixPreferences get preferences => _store.preferences;

  @override
  List<MatrixDevice> devices() => _store.devices;
}

import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/verifysession/repo/verifysession_repo.dart';

class VerifySessionRepoImpl implements VerifySessionRepo {
  VerifySessionRepoImpl(this._store);

  final MatrixStore _store;

  @override
  bool get verified => _store.preferences.sessionVerified;

  @override
  List<int> get emoji => const [7, 12, 3, 19, 8, 1, 14];

  @override
  void confirm() => _store.verifyCurrentDevice();
}

import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/contentscanner/repo/contentscanner_repo.dart';

class ContentScannerRepoImpl implements ContentScannerRepo {
  ContentScannerRepoImpl(this._store);

  final MatrixStore _store;

  @override
  bool get enabled => _store.preferences.contentScannerEnabled;

  @override
  void setEnabled({required bool enabled}) {
    _store.updatePreferences(
      _store.preferences.copyWith(contentScannerEnabled: enabled),
    );
  }
}

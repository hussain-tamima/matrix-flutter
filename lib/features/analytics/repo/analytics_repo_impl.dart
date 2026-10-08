import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/analytics/repo/analytics_repo.dart';

class AnalyticsRepoImpl implements AnalyticsRepo {
  AnalyticsRepoImpl(this._store);

  final MatrixStore _store;

  @override
  bool get enabled => _store.preferences.analyticsEnabled;

  @override
  void setEnabled({required bool enabled}) {
    _store.updatePreferences(
      _store.preferences.copyWith(analyticsEnabled: enabled),
    );
  }
}

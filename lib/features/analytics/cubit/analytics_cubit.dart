import 'package:element_x/features/analytics/cubit/analytics_state.dart';
export 'package:element_x/features/analytics/cubit/analytics_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/analytics/repo/analytics_repo.dart';
import 'package:flutter/foundation.dart';

class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit(this._repo, this._store)
    : super(AnalyticsState(enabled: _repo.enabled)) {
    _listener = () => emit(AnalyticsState(enabled: _repo.enabled));
    _store.addListener(_listener);
  }

  final AnalyticsRepo _repo;
  final MatrixStore _store;
  late final VoidCallback _listener;

  void setEnabled(bool value) => _repo.setEnabled(enabled: value);

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}

import 'package:element_x/features/contentscanner/cubit/contentscanner_state.dart';
export 'package:element_x/features/contentscanner/cubit/contentscanner_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:flutter/foundation.dart';
import 'package:element_x/features/contentscanner/repo/contentscanner_repo.dart';

class ContentScannerCubit extends Cubit<ContentScannerState> {
  ContentScannerCubit(this._repo, this._store)
    : super(ContentScannerState(enabled: _repo.enabled)) {
    _listener = () => emit(ContentScannerState(enabled: _repo.enabled));
    _store.addListener(_listener);
  }

  final ContentScannerRepo _repo;
  final MatrixStore _store;
  late final VoidCallback _listener;

  void setEnabled(bool value) => _repo.setEnabled(enabled: value);

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}

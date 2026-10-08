import 'package:element_x/features/cachecleaner/cubit/cachecleaner_state.dart';
export 'package:element_x/features/cachecleaner/cubit/cachecleaner_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:flutter/foundation.dart';
import 'package:element_x/features/cachecleaner/repo/cachecleaner_repo.dart';

class CacheCleanerCubit extends Cubit<CacheCleanerState> {
  CacheCleanerCubit(this._repo, this._store)
    : super(CacheCleanerState(bytes: _repo.bytes)) {
    _listener = () => emit(CacheCleanerState(bytes: _repo.bytes));
    _store.addListener(_listener);
  }

  final CacheCleanerRepo _repo;
  final MatrixStore _store;
  late final VoidCallback _listener;

  void clear() => _repo.clear();

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}

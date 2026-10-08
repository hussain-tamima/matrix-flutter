import 'package:element_x/features/verifysession/cubit/verifysession_state.dart';
export 'package:element_x/features/verifysession/cubit/verifysession_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:flutter/foundation.dart';
import 'package:element_x/features/verifysession/repo/verifysession_repo.dart';

class VerifySessionCubit extends Cubit<VerifySessionState> {
  VerifySessionCubit(this._repo, this._store)
    : super(VerifySessionState(verified: _repo.verified, emoji: _repo.emoji)) {
    _listener = load;
    _store.addListener(_listener);
  }

  final VerifySessionRepo _repo;
  final MatrixStore _store;
  late final VoidCallback _listener;

  void load() =>
      emit(VerifySessionState(verified: _repo.verified, emoji: _repo.emoji));

  void confirm() => _repo.confirm();

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}

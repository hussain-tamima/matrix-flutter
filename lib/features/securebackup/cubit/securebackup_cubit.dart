import 'package:element_x/features/securebackup/cubit/securebackup_state.dart';
export 'package:element_x/features/securebackup/cubit/securebackup_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:flutter/foundation.dart';
import 'package:element_x/features/securebackup/repo/securebackup_repo.dart';

class SecureBackupCubit extends Cubit<SecureBackupState> {
  SecureBackupCubit(this._repo, this._store)
    : super(
        SecureBackupState(
          enabled: _repo.enabled,
          recoveryKey: _repo.recoveryKey,
        ),
      ) {
    _listener = load;
    _store.addListener(_listener);
  }

  final SecureBackupRepo _repo;
  final MatrixStore _store;
  late final VoidCallback _listener;

  void load() => emit(
    SecureBackupState(enabled: _repo.enabled, recoveryKey: _repo.recoveryKey),
  );

  Future<void> enable(String key) async {
    try {
      final created = await _repo.enable(key.trim());
      emit(
        SecureBackupState(
          enabled: _repo.enabled,
          recoveryKey: created ?? _repo.recoveryKey,
        ),
      );
    } catch (error) {
      if (!isClosed) {
        emit(
          SecureBackupState(
            enabled: _repo.enabled,
            recoveryKey: _repo.recoveryKey,
            error: error.toString(),
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}

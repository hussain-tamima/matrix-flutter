import 'package:element_x/features/securityandprivacy/cubit/securityandprivacy_state.dart';
export 'package:element_x/features/securityandprivacy/cubit/securityandprivacy_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:flutter/foundation.dart';
import 'package:element_x/features/securityandprivacy/repo/securityandprivacy_repo.dart';

class SecurityAndPrivacyCubit extends Cubit<SecurityAndPrivacyState> {
  SecurityAndPrivacyCubit(this._repo, this._store)
    : super(
        SecurityAndPrivacyState(
          preferences: _repo.preferences,
          devices: _repo.devices(),
        ),
      ) {
    _listener = load;
    _store.addListener(_listener);
  }

  final SecurityAndPrivacyRepo _repo;
  final MatrixStore _store;
  late final VoidCallback _listener;

  void load() {
    emit(
      SecurityAndPrivacyState(
        preferences: _repo.preferences,
        devices: _repo.devices(),
      ),
    );
  }

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}

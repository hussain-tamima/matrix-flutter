import 'package:element_x/features/preferences/cubit/preferences_state.dart';
export 'package:element_x/features/preferences/cubit/preferences_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/preferences/repo/preferences_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class PreferencesCubit extends Cubit<PreferencesState> {
  PreferencesCubit(this._repo, this._store) : super(_snapshot(_repo)) {
    _listener = load;
    _store.addListener(_listener);
  }

  final PreferencesRepo _repo;
  final MatrixStore _store;
  late final VoidCallback _listener;

  static PreferencesState _snapshot(PreferencesRepo repo) {
    return PreferencesState(
      preferences: repo.current,
      displayName: repo.displayName,
      userId: repo.userId,
      homeserver: repo.homeserver,
      blocked: repo.blockedUsers(),
    );
  }

  void load() => emit(_snapshot(_repo));

  void update(MatrixPreferences preferences) => _repo.update(preferences);

  Future<void> setLock({required bool enabled, String pin = '0000'}) =>
      _repo.setLock(enabled: enabled, pin: pin);

  void setDisplayName(String name) {
    if (name.trim().isEmpty) {
      return;
    }
    _repo.setDisplayName(name.trim());
  }

  void unblock(String userId) => _repo.unblock(userId);

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}

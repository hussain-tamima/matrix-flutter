import 'package:element_x/core/auth/session_manager.dart';
import 'package:element_x/core/config/app_config.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/preferences/repo/preferences_repo.dart';

class PreferencesRepoImpl implements PreferencesRepo {
  PreferencesRepoImpl(this._store, this._session);

  final MatrixStore _store;
  final SessionManager _session;

  @override
  MatrixPreferences get current => _store.preferences;

  @override
  String get displayName => _store.currentUser.displayName;

  @override
  String get userId => _session.userId ?? _store.currentUser.id;

  @override
  String get homeserver =>
      _session.homeserver ?? AppConfig.defaultHomeserver;

  @override
  void update(MatrixPreferences preferences) =>
      _store.updatePreferences(preferences);

  @override
  Future<void> setLock({required bool enabled, String pin = '0000'}) async {
    await _session.setLockEnabled(enabled: enabled, pin: pin);
    _store.updatePreferences(
      _store.preferences.copyWith(lockScreenEnabled: enabled),
    );
  }

  @override
  void setDisplayName(String name) => _store.updateDisplayName(name);

  @override
  List<MatrixUser> blockedUsers() {
    return _store.preferences.blockedUserIds
        .map((id) => _store.userById(id) ?? MatrixUser(id: id, displayName: id))
        .toList();
  }

  @override
  void unblock(String userId) => _store.unblockUser(userId);
}

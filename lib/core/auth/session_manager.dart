import 'package:element_x/core/local_storage/session_store.dart';
import 'package:element_x/core/settings/app_settings_keys.dart';
import 'package:flutter/foundation.dart';

/// Persists the local session. Biometric keys are not used.
class SessionManager extends ChangeNotifier {
  SessionManager(this._store);

  final SessionStore _store;
  bool _unlocked = false;

  static const _tokenKey = 'accessToken';
  static const _loginKey = 'isLogin';
  static const _userIdKey = 'userId';
  static const _homeserverKey = 'homeserver';
  static const _displayNameKey = 'displayName';
  static const _deviceIdKey = 'deviceId';
  static const _ftueKey = 'ftueSeen';
  static const _lockKey = 'lockEnabled';
  static const _pinKey = 'appPin';

  bool get isLoggedIn => _store.read(_loginKey, defaultValue: false) == true;
  String? get accessToken => _store.read(_tokenKey) as String?;
  String? get userId => _store.read(_userIdKey) as String?;
  String? get homeserver => _store.read(_homeserverKey) as String?;
  String? get displayName => _store.read(_displayNameKey) as String?;
  String? get deviceId => _store.read(_deviceIdKey) as String?;
  bool get ftueSeen => _store.read(_ftueKey, defaultValue: false) == true;
  bool get lockEnabled => _store.read(_lockKey, defaultValue: false) == true;
  bool get unlocked => _unlocked || !lockEnabled;

  Future<void> saveSession({
    required String userId,
    required String homeserver,
    required String displayName,
    required String deviceId,
    String? accessToken,
  }) async {
    await _store.write(_loginKey, true);
    await _store.write(_userIdKey, userId);
    await _store.write(_homeserverKey, homeserver);
    await _store.write(_displayNameKey, displayName);
    await _store.write(_deviceIdKey, deviceId);
    if (accessToken != null && accessToken.isNotEmpty) {
      await _store.write(_tokenKey, accessToken);
    }
    _unlocked = !lockEnabled;
    notifyListeners();
  }

  Future<void> setFtueSeen({required bool seen}) async {
    await _store.write(_ftueKey, seen);
    notifyListeners();
  }

  Future<void> setLockEnabled({
    required bool enabled,
    String pin = '0000',
  }) async {
    await _store.write(_lockKey, enabled);
    if (enabled) {
      await _store.write(_pinKey, pin);
      _unlocked = false;
    } else {
      _unlocked = true;
    }
    notifyListeners();
  }

  bool unlock(String pin) {
    final expected = _store.read(_pinKey, defaultValue: '0000') as String;
    if (pin != expected) {
      return false;
    }
    _unlocked = true;
    notifyListeners();
    return true;
  }

  void lock() {
    if (!lockEnabled) {
      return;
    }
    _unlocked = false;
    notifyListeners();
  }

  Future<void> clear() async {
    final ftue = ftueSeen;
    final lock = lockEnabled;
    final pin = _store.read(_pinKey, defaultValue: '0000');
    final localPrefs = _store.read('localPrefs');
    final themeMode = _store.read(AppSettingsKeys.themeMode);
    final locale = _store.read(AppSettingsKeys.locale);
    await _store.clear();
    await _store.write(_ftueKey, ftue);
    await _store.write(_lockKey, lock);
    await _store.write(_pinKey, pin);
    if (localPrefs != null) {
      await _store.write('localPrefs', localPrefs);
    }
    if (themeMode != null) {
      await _store.write(AppSettingsKeys.themeMode, themeMode);
    }
    if (locale != null) {
      await _store.write(AppSettingsKeys.locale, locale);
    }
    _unlocked = false;
    notifyListeners();
  }
}

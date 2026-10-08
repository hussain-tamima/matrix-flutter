import 'package:dio/dio.dart';
import 'package:element_x/core/auth/session_manager.dart';
import 'package:element_x/core/di/di.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/network/dio_config.dart';
import 'package:element_x/features/login/repo/login_repo.dart';
import 'package:element_x/core/qr_login/qr_login_service.dart';
import 'package:element_x/features/push/repo/push_repo.dart';

import 'dart:async';

class LoginRepoImpl implements LoginRepo {
  LoginRepoImpl(this._store, this._session, this._qrLogin);

  final MatrixStore _store;
  final SessionManager _session;
  final QrLoginService _qrLogin;

  @override
  Future<void> login({
    required String homeserver,
    required String username,
    required String password,
  }) async {
    await _store.login(
      homeserver: homeserver,
      username: username,
      password: password,
    );
    await _remember();
    if (sl.isRegistered<Dio>()) {
      configureDioHomeserver(sl<Dio>(), _session);
    }
    if (sl.isRegistered<PushRepo>()) {
      unawaited(sl<PushRepo>().registerAfterLogin());
    }
  }

  @override
  Future<void> loginWithQr({required String homeserver}) {
    throw Exception('Scan a QR code to sign in');
  }

  @override
  Future<String?> loginWithQrPayload(List<int> qrBytes) async {
    final warning = await _qrLogin.signInFromScannedQr(qrBytes);
    await _remember();
    if (sl.isRegistered<Dio>()) {
      configureDioHomeserver(sl<Dio>(), _session);
    }
    if (sl.isRegistered<PushRepo>()) {
      unawaited(sl<PushRepo>().registerAfterLogin());
    }
    return warning;
  }

  @override
  Future<void> createAccount({
    required String homeserver,
    required String username,
    required String password,
    required String displayName,
  }) async {
    await _store.register(
      homeserver: homeserver,
      username: username,
      password: password,
      displayName: displayName,
    );
    await _remember();
    if (sl.isRegistered<Dio>()) {
      configureDioHomeserver(sl<Dio>(), _session);
    }
    if (sl.isRegistered<PushRepo>()) {
      unawaited(sl<PushRepo>().registerAfterLogin());
    }
  }

  Future<void> _remember() async {
    final client = _store.client;
    await _session.saveSession(
      userId: client.userID ?? '',
      homeserver: client.homeserver?.host ?? '',
      displayName: _store.currentUser.displayName,
      deviceId: client.deviceID ?? '',
      accessToken: client.accessToken,
    );
  }
}

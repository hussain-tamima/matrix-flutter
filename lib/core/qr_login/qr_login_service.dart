import 'package:dio/dio.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/qr_login/msc4108_reciprocate.dart';
import 'package:element_x/core/qr_login/msc4108_sign_in.dart';

class QrLoginService {
  QrLoginService(this._dio, this._store);

  final Dio _dio;
  final MatrixStore _store;

  Future<String?> signInFromScannedQr(List<int> qrBytes) async {
    final signIn = Msc4108SignIn(_dio);
    final result = await signIn.signInFromQr(qrBytes);
    await _store.restoreLoginSession(
      homeserver: result.homeserver,
      accessToken: result.accessToken,
      userId: result.userId,
      deviceId: result.deviceId,
    );
    return result.encryptionWarning;
  }

  Future<({List<int> qrBytes, String warning})> createReciprocateQr() async {
    final reciprocate = Msc4108Reciprocate(_dio, _store.client);
    final created = await reciprocate.createLoginQr();
    return (qrBytes: created.qrBytes, warning: created.warning);
  }
}

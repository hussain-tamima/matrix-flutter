import 'package:element_x/core/matrix/matrix_models.dart';

abstract class LinkNewDeviceRepo {
  List<MatrixDevice> devices();
  List<String> get verificationEmojis;
  String? get verificationStatus;
  Future<void> verify(String deviceId);
  Future<void> confirm();
  void cancel();
}

import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/linknewdevice/repo/linknewdevice_repo.dart';

class LinkNewDeviceRepoImpl implements LinkNewDeviceRepo {
  LinkNewDeviceRepoImpl(this._store);

  final MatrixStore _store;

  @override
  List<MatrixDevice> devices() => _store.devices;

  @override
  List<String> get verificationEmojis => _store.verificationEmojis;

  @override
  String? get verificationStatus => _store.verificationStatus;

  @override
  Future<void> verify(String deviceId) => _store.verifyDevice(deviceId);

  @override
  Future<void> confirm() => _store.confirmVerification();

  @override
  void cancel() => _store.cancelVerification();
}

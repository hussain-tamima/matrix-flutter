abstract class SecureBackupRepo {
  bool get enabled;
  String? get recoveryKey;
  Future<String?> enable(String recoveryKey);
}

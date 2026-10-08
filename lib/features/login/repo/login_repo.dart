abstract class LoginRepo {
  Future<void> login({
    required String homeserver,
    required String username,
    required String password,
  });

  Future<void> loginWithQr({required String homeserver});

  Future<String?> loginWithQrPayload(List<int> qrBytes);

  Future<void> createAccount({
    required String homeserver,
    required String username,
    required String password,
    required String displayName,
  });
}

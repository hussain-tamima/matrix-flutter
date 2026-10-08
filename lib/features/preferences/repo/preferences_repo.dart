import 'package:element_x/core/matrix/matrix_models.dart';

abstract class PreferencesRepo {
  MatrixPreferences get current;
  String get displayName;
  String get userId;
  String get homeserver;
  void update(MatrixPreferences preferences);
  Future<void> setLock({required bool enabled, String pin});
  void setDisplayName(String name);
  List<MatrixUser> blockedUsers();
  void unblock(String userId);
}

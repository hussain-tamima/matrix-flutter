import 'package:element_x/core/matrix/matrix_models.dart';

abstract class UserProfileRepo {
  MatrixUser? user(String userId);
  bool isBlocked(String userId);
  bool get verified;
  Future<String> openDirect(String userId);
  void block(String userId);
  void unblock(String userId);
}

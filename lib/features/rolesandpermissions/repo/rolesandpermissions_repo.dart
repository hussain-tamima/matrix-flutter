import 'package:element_x/core/matrix/matrix_models.dart';

abstract class RolesAndPermissionsRepo {
  List<RoomMember> members(String roomId);
  String displayName(String userId);
  void setRole(String roomId, String userId, String role);
}

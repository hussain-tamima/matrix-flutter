import 'package:element_x/core/matrix/matrix_models.dart';

abstract class RoomMemberModerationRepo {
  RoomMember? member(String roomId, String userId);
  String displayName(String userId);
  void setRole(String roomId, String userId, String role);
  void kick(String roomId, String userId);
  void ban(String roomId, String userId);
}

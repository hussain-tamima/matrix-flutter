import 'package:element_x/core/matrix/matrix_models.dart';

abstract class RoomDetailsRepo {
  MatrixRoom? room(String roomId);
  List<RoomMember> members(String roomId);
  String displayName(String userId);
  String notificationMode(String roomId);
  int knockCount(String roomId);
  bool isReported(String roomId);
  void setFavourite(String roomId, {required bool favourite});
  Future<void> setNotificationMode(String roomId, String mode);
}

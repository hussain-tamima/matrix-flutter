import 'package:element_x/core/matrix/matrix_models.dart';

abstract class ForwardRepo {
  TimelineEvent? event(String eventId);
  List<MatrixRoom> destinations(String fromRoomId);
  Future<void> send(String roomId, String sourceEventId);
}

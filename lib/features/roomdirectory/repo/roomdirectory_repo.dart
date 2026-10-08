import 'package:element_x/core/matrix/matrix_models.dart';

abstract class RoomDirectoryRepo {
  List<MatrixRoom> rooms();
  Future<void> join(String roomId);
}

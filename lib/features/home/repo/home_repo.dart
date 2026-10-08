import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/home/models/room_filter.dart';

abstract class HomeRepo {
  List<MatrixRoom> rooms({required RoomFilter filter, String query = ''});
  List<MatrixRoom> spaces();
  bool get online;
  bool get syncing;
  bool get ftueSeen;
}

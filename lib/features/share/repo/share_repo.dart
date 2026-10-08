import 'package:element_x/core/matrix/matrix_models.dart';

abstract class ShareRepo {
  List<MatrixRoom> rooms();
  void share(String roomId, String text);
}

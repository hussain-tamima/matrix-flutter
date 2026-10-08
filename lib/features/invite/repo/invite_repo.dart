import 'package:element_x/core/matrix/matrix_models.dart';

abstract class InviteRepo {
  MatrixRoom? room(String roomId);
}

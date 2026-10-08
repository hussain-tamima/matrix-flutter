import 'package:element_x/core/matrix/matrix_models.dart';

abstract class StartChatRepo {
  List<MatrixUser> people();
  Future<String> openDirect(String userId);
}

import 'package:element_x/core/matrix/matrix_models.dart';

abstract class StartChatRepo {
  List<MatrixUser> people();
  String get homeserver;
  Future<String> openDirect(String userId);
}

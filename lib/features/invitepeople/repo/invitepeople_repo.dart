import 'package:element_x/core/matrix/matrix_models.dart';

abstract class InvitePeopleRepo {
  List<MatrixUser> candidates(String roomId);
  void invite(String roomId, String userId);
}

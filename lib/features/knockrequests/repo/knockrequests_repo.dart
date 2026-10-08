import 'package:element_x/core/matrix/matrix_models.dart';

abstract class KnockRequestsRepo {
  List<KnockRequest> requests(String roomId);
  String nameFor(String userId);
  void accept(KnockRequest request);
  void decline(KnockRequest request);
}

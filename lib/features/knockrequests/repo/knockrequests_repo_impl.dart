import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/knockrequests/repo/knockrequests_repo.dart';

class KnockRequestsRepoImpl implements KnockRequestsRepo {
  KnockRequestsRepoImpl(this._store);

  final MatrixStore _store;

  @override
  List<KnockRequest> requests(String roomId) => _store.knocksFor(roomId);

  @override
  String nameFor(String userId) =>
      _store.userById(userId)?.displayName ?? userId;

  @override
  void accept(KnockRequest request) => _store.acceptKnock(request);

  @override
  void decline(KnockRequest request) => _store.declineKnock(request);
}

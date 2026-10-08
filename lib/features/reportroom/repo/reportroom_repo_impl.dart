import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/reportroom/repo/reportroom_repo.dart';

class ReportRoomRepoImpl implements ReportRoomRepo {
  ReportRoomRepoImpl(this._store);

  final MatrixStore _store;

  @override
  bool isReported(String roomId) => _store.isReported(roomId);

  @override
  Future<void> report(String roomId, String reason) =>
      _store.reportRoom(roomId, reason: reason);
}

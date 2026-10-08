import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/space/models/space_summary.dart';
import 'package:element_x/features/space/repo/space_repo.dart';

class SpaceRepoImpl implements SpaceRepo {
  SpaceRepoImpl(this._store);

  final MatrixStore _store;

  @override
  SpaceSummary? summary(String spaceId) {
    final space = _store.roomById(spaceId);
    if (space == null || !space.isSpace) {
      return null;
    }
    return SpaceSummary(
      id: space.id,
      name: space.name,
      topic: space.topic,
      roomCount: children(spaceId).length,
    );
  }

  @override
  List<MatrixRoom> children(String spaceId) {
    return _store.rooms.where((room) => room.spaceId == spaceId).toList();
  }
}

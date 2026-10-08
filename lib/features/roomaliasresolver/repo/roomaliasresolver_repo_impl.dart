import 'package:element_x/core/matrix/matrix_error.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/roomaliasresolver/models/alias_resolution.dart';
import 'package:element_x/features/roomaliasresolver/repo/roomaliasresolver_repo.dart';

class RoomAliasResolverRepoImpl implements RoomAliasResolverRepo {
  RoomAliasResolverRepoImpl(this._store);

  final MatrixStore _store;

  @override
  Future<AliasResolution> resolve(String alias) async {
    final trimmed = alias.trim();
    if (!trimmed.startsWith('#')) {
      return const AliasResolution(error: 'resolve_alias_hash');
    }
    try {
      final roomId = await _store.resolveAlias(trimmed);
      if (roomId == null) {
        return const AliasResolution(error: 'resolve_alias_not_found');
      }
      return AliasResolution(roomId: roomId);
    } catch (error) {
      return AliasResolution(error: matrixError(error));
    }
  }
}

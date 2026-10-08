import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/cachecleaner/repo/cachecleaner_repo.dart';

class CacheCleanerRepoImpl implements CacheCleanerRepo {
  CacheCleanerRepoImpl(this._store);

  final MatrixStore _store;

  @override
  int get bytes => _store.cacheBytes;

  @override
  void clear() => _store.clearCache();
}

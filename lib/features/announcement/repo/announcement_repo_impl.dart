import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/announcement/repo/announcement_repo.dart';

class AnnouncementRepoImpl implements AnnouncementRepo {
  AnnouncementRepoImpl(this._store);

  final MatrixStore _store;

  @override
  MatrixAnnouncement? current() => _store.announcement;

  @override
  void dismiss() => _store.dismissAnnouncement();
}

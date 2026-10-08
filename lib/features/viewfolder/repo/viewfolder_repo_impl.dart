import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/viewfolder/repo/viewfolder_repo.dart';

class ViewFolderRepoImpl implements ViewFolderRepo {
  ViewFolderRepoImpl(this._store);

  final MatrixStore _store;

  @override
  List<TimelineEvent> files(String roomId) {
    return _store.eventsFor(roomId).where((event) {
      return event.kind == TimelineEventKind.file ||
          event.kind == TimelineEventKind.image ||
          event.kind == TimelineEventKind.voice;
    }).toList();
  }
}

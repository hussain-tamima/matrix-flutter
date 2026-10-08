import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/poll/models/poll_draft.dart';
import 'package:element_x/features/poll/repo/poll_repo.dart';

class PollRepoImpl implements PollRepo {
  PollRepoImpl(this._store);

  final MatrixStore _store;

  @override
  void create(String roomId, PollDraft draft) {
    _store.sendMessage(
      roomId: roomId,
      body: draft.question,
      kind: TimelineEventKind.poll,
      pollOptions: draft.options,
    );
  }
}

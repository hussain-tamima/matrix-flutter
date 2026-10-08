import 'package:element_x/features/messages/cubit/thread_state.dart';
export 'package:element_x/features/messages/cubit/thread_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/messages/repo/messages_repo.dart';
import 'package:flutter/foundation.dart';

class ThreadCubit extends Cubit<ThreadState> {
  ThreadCubit(this._repo, this._store, this.roomId, this.rootEventId)
    : super(const ThreadState()) {
    _listener = load;
    _store.addListener(_listener);
    load();
  }

  final MessagesRepo _repo;
  final MatrixStore _store;
  final String roomId;
  final String rootEventId;
  late final VoidCallback _listener;

  void load() {
    final events = _repo.thread(roomId, rootEventId);
    emit(ThreadState(root: _store.eventById(rootEventId), events: events));
  }

  void send(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _repo.sendText(roomId: roomId, body: trimmed, threadRootId: rootEventId);
  }

  String nameFor(String senderId) => _repo.senderName(senderId);
  bool mine(String senderId) => _repo.isMine(senderId);

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}

import 'dart:typed_data';

import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/messages/repo/messages_repo.dart';

class MessagesRepoImpl implements MessagesRepo {
  MessagesRepoImpl(this._store);

  final MatrixStore _store;

  @override
  MatrixRoom? room(String roomId) => _store.roomById(roomId);

  @override
  List<TimelineEvent> timeline(String roomId) => _store.eventsFor(roomId);

  @override
  List<TimelineEvent> thread(String roomId, String rootEventId) =>
      _store.eventsFor(roomId, threadRootId: rootEventId);

  @override
  List<TimelineEvent> pins(String roomId) =>
      _store.eventsFor(roomId, pinnedOnly: true);

  @override
  List<TimelineEvent> files(String roomId) {
    return _store.eventsFor(roomId).where((event) {
      return event.kind == TimelineEventKind.file ||
          event.kind == TimelineEventKind.image;
    }).toList();
  }

  @override
  int replyCount(String eventId) => _store.replyCount(eventId);

  @override
  String senderName(String senderId) =>
      _store.userById(senderId)?.displayName ?? senderId;

  @override
  bool isMine(String senderId) => senderId == _store.currentUser.id;

  @override
  bool isTyping(String roomId) => _store.isTyping(roomId);

  @override
  Future<void> markRead(String roomId) => _store.markRead(roomId);

  @override
  Future<void> sendText({
    required String roomId,
    required String body,
    String? threadRootId,
  }) {
    return _store.sendMessage(
      roomId: roomId,
      body: body,
      threadRootId: threadRootId,
    );
  }

  @override
  Future<void> sendAttachment({
    required String roomId,
    required TimelineEventKind kind,
    required String body,
    String? fileName,
    String? mimeType,
    Uint8List? bytes,
    List<String> pollOptions = const [],
  }) {
    return _store.sendMessage(
      roomId: roomId,
      body: body,
      kind: kind,
      fileName: fileName,
      mimeType: mimeType,
      bytes: bytes,
      pollOptions: pollOptions,
    );
  }

  @override
  Future<void> pin(String eventId, {required bool pinned}) =>
      _store.pinEvent(eventId, pinned: pinned);

  @override
  Future<void> vote(String eventId, String option) =>
      _store.votePoll(eventId, option);
}

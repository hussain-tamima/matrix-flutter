import 'dart:typed_data';

import 'package:element_x/core/matrix/matrix_models.dart';

abstract class MessagesRepo {
  MatrixRoom? room(String roomId);
  List<TimelineEvent> timeline(String roomId);
  List<TimelineEvent> thread(String roomId, String rootEventId);
  List<TimelineEvent> pins(String roomId);
  List<TimelineEvent> files(String roomId);
  int replyCount(String eventId);
  String senderName(String senderId);
  bool isMine(String senderId);
  bool isTyping(String roomId);
  Future<void> markRead(String roomId);
  Future<void> sendText({
    required String roomId,
    required String body,
    String? threadRootId,
  });
  Future<void> sendAttachment({
    required String roomId,
    required TimelineEventKind kind,
    required String body,
    String? fileName,
    String? mimeType,
    Uint8List? bytes,
    List<String> pollOptions = const [],
  });
  Future<void> pin(String eventId, {required bool pinned});
  Future<void> vote(String eventId, String option);
}

import 'package:element_x/features/messages/cubit/messages_state.dart';
export 'package:element_x/features/messages/cubit/messages_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/messages/repo/messages_repo.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:element_x/core/matrix/matrix_error.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class MessagesCubit extends Cubit<MessagesState> {
  MessagesCubit(this._repo, this._store, this.roomId)
    : super(const MessagesState()) {
    _listener = load;
    _store.addListener(_listener);
    load();
  }

  final MessagesRepo _repo;
  final MatrixStore _store;
  final String roomId;
  late final VoidCallback _listener;
  final ImagePicker _images = ImagePicker();
  AudioRecorder? _recorder;

  void load() {
    final room = _repo.room(roomId);
    if (room == null || room.isSpace) {
      emit(const MessagesState(missing: true));
      return;
    }
    _store.ensureTimeline(roomId);
    _repo.markRead(roomId);
    final events = _repo.timeline(roomId);
    emit(
      MessagesState(
        room: _repo.room(roomId),
        events: events,
        replyCounts: {
          for (final event in events) event.id: _repo.replyCount(event.id),
        },
        typing: _repo.isTyping(roomId),
        recording: state.recording,
      ),
    );
  }

  Future<void> send(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return;
    }
    try {
      await _repo.sendText(roomId: roomId, body: trimmed);
    } catch (error) {
      if (!isClosed) {
        emit(
          MessagesState(
            room: state.room,
            events: state.events,
            replyCounts: state.replyCounts,
            typing: state.typing,
            error: matrixError(error),
          ),
        );
      }
    }
  }

  Future<void> sendPhoto() async {
    try {
      final photo = await _images.pickImage(source: ImageSource.gallery);
      if (photo == null) {
        return;
      }
      await _repo.sendAttachment(
        roomId: roomId,
        kind: TimelineEventKind.image,
        body: photo.name,
        fileName: photo.name,
        mimeType: photo.mimeType,
        bytes: await photo.readAsBytes(),
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> sendFile() async {
    try {
      final files = await FilePicker.pickFiles();
      if (files.isEmpty) {
        return;
      }
      final file = files.first;
      await _repo.sendAttachment(
        roomId: roomId,
        kind: TimelineEventKind.file,
        body: file.name,
        fileName: file.name,
        bytes: await file.readAsBytes(),
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> sendVoice() async {
    try {
      final recorder = _recorder ??= AudioRecorder();
      if (!await recorder.hasPermission()) {
        throw Exception('Microphone permission was denied');
      }
      final directory = await getTemporaryDirectory();
      final path = p.join(
        directory.path,
        'voice-${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      await recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      if (!isClosed) {
        emit(_snapshot(recording: true));
      }
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> stopVoice() async {
    final recorder = _recorder;
    if (recorder == null) {
      return;
    }
    try {
      final path = await recorder.stop();
      if (!isClosed) {
        emit(_snapshot(recording: false));
      }
      if (path == null || path.isEmpty) {
        return;
      }
      final bytes = await XFile(path).readAsBytes();
      await _repo.sendAttachment(
        roomId: roomId,
        kind: TimelineEventKind.voice,
        body: 'Voice message',
        fileName: 'voice.m4a',
        mimeType: 'audio/mp4',
        bytes: bytes,
      );
    } catch (error) {
      _showError(error);
    }
  }

  MessagesState _snapshot({bool? recording, String? error}) {
    return MessagesState(
      room: state.room,
      events: state.events,
      replyCounts: state.replyCounts,
      typing: state.typing,
      missing: state.missing,
      recording: recording ?? state.recording,
      error: error,
    );
  }

  void _showError(Object error) {
    if (!isClosed) {
      emit(_snapshot(error: matrixError(error)));
    }
  }

  void vote(String eventId, String option) => _repo.vote(eventId, option);

  void togglePin(TimelineEvent event) =>
      _repo.pin(event.id, pinned: !event.isPinned);

  String nameFor(String senderId) => _repo.senderName(senderId);

  bool mine(String senderId) => _repo.isMine(senderId);

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    _recorder?.dispose();
    return super.close();
  }
}

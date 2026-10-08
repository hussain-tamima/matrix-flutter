import 'dart:async';

import 'package:matrix/matrix.dart';

const _participantFetchFailed = '[E2EE] Failed to fetch participants';

final _roomIdPattern = RegExp(r'not in room (![^,\s]+)');

final Set<String> _droppedRoomIds = {};
final Set<String> _queuedRoomIds = {};

StreamSubscription<SyncStatusUpdate>? _syncStatusSubscription;
Future<void>? _cleanup;
var _flushing = false;

/// Room id from Synapse's "not in room, and room previews are disabled" 403.
String? roomIdMissingOnServer(Object? error) {
  if (error is! MatrixException || error.error != MatrixError.M_FORBIDDEN) {
    return null;
  }
  final message = error.errorMessage;
  if (!message.contains('not in room') ||
      !message.contains('room previews are disabled')) {
    return null;
  }
  return _roomIdPattern.firstMatch(message)?.group(1);
}

/// Forgets [error]'s room once per process. Returns that room id when the
/// error is the preview 403, including when the room was already dropped.
String? queueRoomMissingOnServer(Client client, Object error) {
  final roomId = roomIdMissingOnServer(error);
  if (roomId == null) {
    return null;
  }
  if (!_droppedRoomIds.add(roomId)) {
    return roomId;
  }
  final room = client.getRoomById(roomId);
  if (room == null || room.membership != Membership.join) {
    return roomId;
  }
  // The SDK iterates `client.rooms` while fetching members. Changing
  // membership hides the room without resizing that list.
  room.membership = Membership.leave;
  _queuedRoomIds.add(roomId);
  if (_syncIsIdle(client.onSyncStatus.value?.status)) {
    _cleanup = _flushQueuedRooms(client);
  }
  return roomId;
}

/// Drops queued rooms after the sync loop that logged the 403 has finished.
void attachStaleRoomCleanup(Client client) {
  final previous = Logs().onLog;
  Logs().onLog = (event) {
    previous?.call(event);
    if (event.title != _participantFetchFailed) {
      return;
    }
    final error = event.exception;
    if (error == null) {
      return;
    }
    queueRoomMissingOnServer(client, error);
  };
  unawaited(_syncStatusSubscription?.cancel());
  _syncStatusSubscription = client.onSyncStatus.stream.listen((update) {
    if (_syncIsIdle(update.status)) {
      _cleanup = _flushQueuedRooms(client);
    }
  });
}

/// Waits for an in-flight local forget. Tests use this to observe the result.
Future<void> finishStaleRoomCleanup() => _cleanup ?? Future<void>.value();

bool _syncIsIdle(SyncStatus? status) {
  return switch (status) {
    null || SyncStatus.finished || SyncStatus.error => true,
    SyncStatus.waitingForResponse ||
    SyncStatus.processing ||
    SyncStatus.cleaningUp => false,
  };
}

Future<void> _flushQueuedRooms(Client client) async {
  if (_flushing || _queuedRoomIds.isEmpty) {
    return;
  }
  _flushing = true;
  try {
    final roomIds = List<String>.of(_queuedRoomIds);
    _queuedRoomIds.clear();
    client.rooms.removeWhere((room) => roomIds.contains(room.id));
    for (final roomId in roomIds) {
      try {
        await client.database.forgetRoom(roomId);
      } catch (error, stackTrace) {
        Logs().w('Could not forget room missing on server', error, stackTrace);
      }
    }
  } finally {
    _flushing = false;
    if (_queuedRoomIds.isNotEmpty) {
      await _flushQueuedRooms(client);
    }
  }
}

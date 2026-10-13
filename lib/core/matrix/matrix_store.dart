import 'dart:async';
import 'dart:convert';

import 'package:element_x/core/config/app_config.dart';
import 'package:element_x/core/local_storage/session_store.dart';
import 'package:element_x/core/matrix/group_call_events.dart';
import 'package:element_x/core/matrix/livekit_room_call.dart';
import 'package:element_x/core/matrix/matrix_call_media.dart';
import 'package:element_x/core/matrix/matrix_error.dart';
import 'package:element_x/core/matrix/matrix_database.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/core/matrix/stale_room.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart' hide RoomMember;

/// Live Matrix cache. Screens read this synchronously; writes go to the SDK.
class MatrixStore extends ChangeNotifier {
  MatrixStore(this.client, this._session, {this.databasePath}) {
    client.importantStateEvents.addAll([
      groupCallType,
      groupMemberType,
      matrixRtcMemberEventType,
    ]);
    _loadLocal();
    _syncing = client.isLogged();
    _rebuildRooms();
    _syncSubscription = client.onSync.stream.listen((_) => _onSync());
    _statusSubscription = client.onSyncStatus.stream.listen(_onStatus);
    _toDeviceSubscription = client.onToDeviceEvent.stream.listen((event) {
      try {
        _onCallEncryptionKeys(event);
      } catch (_) {}
    });
    _callSubscription = client.onTimelineEvent.stream.listen((event) {
      try {
        _onCallEvent(event);
      } catch (_) {}
    });
    // Late Megolm keys are replayed here, not on `onTimelineEvent`.
    // ignore: deprecated_member_use
    _decryptedCallSubscription = client.onEvent.stream.listen((update) {
      if (update.type != EventUpdateType.decryptedTimelineQueue) {
        return;
      }
      final room = client.getRoomById(update.roomID);
      if (room == null) {
        return;
      }
      try {
        _onCallEvent(Event.fromJson(update.content, room));
      } catch (_) {}
    });
  }

  static const localPrefsKey = 'localPrefs';
  static const settingsAccountData = 'io.element.element_x.settings';
  static const groupCallType = groupCallEventType;
  static const groupMemberType = groupCallMemberEventType;
  static const _groupCallType = groupCallEventType;
  static const _groupMemberType = groupCallMemberEventType;
  static const _groupSignalType = 'io.elementx.call.signal';
  static const _rtcNotificationType = rtcNotificationEventType;
  static const _rtcDeclineType = rtcDeclineEventType;
  static const _groupCallLimit = 4;
  static const _groupMemberTtl = Duration(seconds: 90);

  final Client client;
  final SessionStore _session;
  final String? databasePath;

  final Map<String, List<TimelineEvent>> _events = {};
  final Map<String, Timeline> _timelines = {};
  final Map<String, List<RoomMember>> _members = {};
  final Map<String, MatrixUser> _knownUsers = {};

  List<MatrixRoom> _rooms = [];
  List<MatrixRoom> _spaces = [];
  final Map<String, DateTime> _joinedAt = {};
  final Set<String> _acceptedOnHome = {};
  List<MatrixRoom> _directory = [];
  MatrixPreferences _local = const MatrixPreferences();
  String _displayName = '';
  bool _syncing = false;
  bool _online = true;
  bool _directoryLoading = false;
  MatrixCall? _activeCall;
  MatrixCallMedia? _callMedia;
  String? _callId;
  String? _callRoomId;
  String? _offerSdp;
  var _callSignalingSent = false;
  var _callMediaGeneration = 0;
  var _negotiateReady = false;
  String? _pendingNegotiateOffer;
  Future<void>? _negotiateChain;
  final List<RTCIceCandidate> _pendingOutbound = [];
  final List<RTCIceCandidate> _pendingRemote = [];
  Timer? _callTimer;
  Timer? _connectWatch;
  String? _remotePartyId;
  String? _callError;
  var _iceRestarted = false;
  var _failingCall = false;
  KeyVerification? _verification;
  StreamSubscription<Event>? _callSubscription;
  StreamSubscription<ToDeviceEvent>? _toDeviceSubscription;
  final List<_CallMediaKey> _pendingCallKeys = [];
  // ignore: deprecated_member_use
  StreamSubscription<EventUpdate>? _decryptedCallSubscription;
  var _groupSession = false;
  var _groupEpoch = 0;
  var _memberRev = 0;
  var _groupSyncing = false;
  var _groupSyncAgain = false;
  MediaStream? _groupLocal;
  MediaStream? _groupUpgrade;
  Timer? _groupHeartbeat;
  String? _dismissedGroupCallId;
  String? _incomingRtcNotificationId;
  final Set<String> _dismissedRtcNotifications = {};
  LivekitRoomCall? _elementCall;
  String? _elementCallUrl;
  var _matrixRtcPublished = false;
  final Map<String, MatrixCallMedia> _groupPeers = {};
  final Map<String, String> _groupOfferSdp = {};
  final Map<String, DateTime> _groupOfferSentAt = {};
  final Map<String, List<RTCIceCandidate>> _groupQueuedCandidates = {};
  final Set<String> _groupOffered = {};
  final Set<String> _groupIceRestarted = {};
  final Map<String, _GroupSnapshot> _groupSnapshots = {};
  final Set<String> _endedGroupCalls = {};
  final Set<String> _stateBackedCalls = {};
  final Set<String> _clearedStaleMembers = {};
  final List<Event> _queuedGroupSignals = [];

  StreamSubscription<SyncUpdate>? _syncSubscription;
  StreamSubscription<SyncStatusUpdate>? _statusSubscription;

  MatrixUser get currentUser => MatrixUser(
    id: client.userID ?? '',
    displayName: _displayName.isEmpty ? (client.userID ?? '') : _displayName,
    statusMessage: _local.statusMessage,
  );

  MatrixPreferences get preferences => _local.copyWith(
    blockedUserIds: client.isLogged()
        ? client.ignoredUsers
        : _local.blockedUserIds,
    secureBackupEnabled: _backupEnabled,
    sessionVerified: _sessionVerified,
    lockScreenEnabled: _local.lockScreenEnabled,
  );

  MatrixAnnouncement? get announcement => null;
  MatrixCall? get call => _activeCall;
  String? get callError => _callError;

  void clearCallError() {
    if (_callError == null) {
      return;
    }
    _callError = null;
    notifyListeners();
  }

  int get callMediaGeneration => _callMediaGeneration;
  MediaStream? get localCallStream =>
      _elementCall?.local ?? _groupLocal ?? _callMedia?.local;
  MediaStream? get remoteCallStream {
    final session = _elementCall;
    if (session != null) {
      for (final stream in session.remotes.values) {
        return stream;
      }
      return null;
    }
    if (_groupSession) {
      for (final media in _groupPeers.values) {
        final remote = media.remote;
        if (remote != null) {
          return remote;
        }
      }
      return null;
    }
    return _callMedia?.remote;
  }

  MediaStream? remoteStreamFor(String partyId) =>
      _elementCall?.remotes[partyId] ?? _groupPeers[partyId]?.remote;

  lk.VideoTrack? get localCallVideoTrack => _elementCall?.localCamera;
  lk.VideoTrack? get remoteCallVideoTrack => _elementCall?.remoteCamera;
  lk.VideoTrack? videoTrackFor(String partyId) =>
      _elementCall?.cameraFor(partyId);

  List<MatrixCallParticipant> get callParticipants {
    final session = _elementCall;
    if (session != null && _callRoomId != null) {
      final room = _sdkRoom(_callRoomId!);
      return [
        for (final person in session.participants)
          _livekitParticipant(room, person),
      ];
    }
    if (!_groupSession || _callRoomId == null) {
      return const [];
    }
    final snap = _groupSnapshots[_callRoomId];
    if (snap == null) {
      return const [];
    }
    final room = _sdkRoom(_callRoomId!);
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      for (final member in snap.members.values)
        if (member.partyId != _partyId && member.expiresAt > now)
          MatrixCallParticipant(
            partyId: member.partyId,
            userId: member.userId,
            displayName: room == null
                ? member.userId
                : _memberName(room, member.userId),
            connected: _groupPeers[member.partyId]?.isConnected ?? false,
          ),
    ];
  }

  MatrixGroupCall? groupCallFor(String roomId) {
    final snap = _liveSnapshot(roomId);
    if (snap == null) {
      return null;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final count = snap.members.values
        .where((member) => member.expiresAt > now)
        .length;
    if (count == 0) {
      return null;
    }
    return MatrixGroupCall(
      roomId: roomId,
      callId: snap.callId,
      video: snap.video,
      participantCount: count,
      joined: _groupSession && _callRoomId == roomId && _callId == snap.callId,
    );
  }

  List<String> get verificationEmojis =>
      _verification?.sasEmojis.map((emoji) => emoji.emoji).toList() ?? const [];
  String? get verificationStatus => _verificationLabel(_verification?.state);
  String? get recoveryKey => _recoveryKey;
  int get cacheBytes => databaseSize(databasePath);
  bool get online => _online;
  bool get syncing => _syncing;
  bool get directoryLoading => _directoryLoading;
  List<MatrixUser> get users => List.unmodifiable(_knownUsers.values);
  List<MatrixRoom> get rooms => List.unmodifiable(_rooms);
  List<MatrixRoom> get spaces => List.unmodifiable(_spaces);
  List<MatrixRoom> get directory => List.unmodifiable(_directory);

  List<MatrixDevice> get devices {
    final userId = client.userID;
    if (userId == null) {
      return const [];
    }
    final keys = client.userDeviceKeys[userId]?.deviceKeys.values ?? const [];
    return [
      for (final device in keys)
        MatrixDevice(
          id: device.deviceId ?? '',
          name: device.deviceDisplayName ?? device.deviceId ?? 'Device',
          lastSeen: device.lastActive,
          verified: device.verified,
          current: device.deviceId == client.deviceID,
        ),
    ];
  }

  bool get _backupEnabled => client.encryption?.ssss.defaultKeyId != null;

  bool get _sessionVerified {
    final userId = client.userID;
    final deviceId = client.deviceID;
    if (userId == null || deviceId == null) {
      return false;
    }
    return client.userDeviceKeys[userId]?.deviceKeys[deviceId]?.verified ??
        false;
  }

  String? _recoveryKey;

  MatrixUser? userById(String id) {
    if (id == currentUser.id) {
      return currentUser;
    }
    return _knownUsers[id];
  }

  MatrixRoom? roomById(String id) {
    for (final room in _rooms) {
      if (room.id == id) {
        return room;
      }
    }
    for (final room in _spaces) {
      if (room.id == id) {
        return room;
      }
    }
    for (final room in _directory) {
      if (room.id == id) {
        return room;
      }
    }
    return null;
  }

  bool isJoined(String roomId) =>
      _sdkRoom(roomId)?.membership == Membership.join;

  List<TimelineEvent> eventsFor(
    String roomId, {
    String? threadRootId,
    bool pinnedOnly = false,
  }) {
    final events = _events[roomId] ?? const <TimelineEvent>[];
    return events.where((event) {
      if (pinnedOnly) {
        return event.isPinned;
      }
      if (threadRootId == null) {
        return event.threadRootId == null;
      }
      return event.id == threadRootId || event.threadRootId == threadRootId;
    }).toList();
  }

  TimelineEvent? eventById(String eventId) {
    for (final events in _events.values) {
      for (final event in events) {
        if (event.id == eventId) {
          return event;
        }
      }
    }
    return null;
  }

  int replyCount(String eventId) {
    var count = 0;
    for (final events in _events.values) {
      for (final event in events) {
        if (event.threadRootId == eventId) {
          count += 1;
        }
      }
    }
    return count;
  }

  List<RoomMember> membersOf(String roomId) =>
      List.unmodifiable(_members[roomId] ?? const []);

  List<KnockRequest> knocksFor(String roomId) {
    return [
      for (final member in membersOf(roomId))
        if (member.membership == Membership.knock.name)
          KnockRequest(roomId: roomId, userId: member.userId, reason: ''),
    ];
  }

  String notificationMode(String roomId) {
    final room = _sdkRoom(roomId);
    if (room == null) {
      return _localNotification(roomId);
    }
    return switch (room.pushRuleState) {
      PushRuleState.mentionsOnly => 'mentions',
      PushRuleState.dontNotify => 'mute',
      PushRuleState.notify => 'all',
    };
  }

  bool isReported(String roomId) => _reportedRooms.contains(roomId);

  bool isTyping(String roomId) =>
      _sdkRoom(roomId)?.typingUsers.isNotEmpty ?? false;

  Future<void> refreshDirectory({String? term}) async {
    if (!client.isLogged()) {
      _directory = [];
      notifyListeners();
      return;
    }
    _directoryLoading = true;
    notifyListeners();
    try {
      final response = await client.queryPublicRooms(
        limit: 30,
        filter: term == null || term.trim().isEmpty
            ? null
            : PublicRoomQueryFilter(genericSearchTerm: term.trim()),
      );
      _directory = [
        for (final chunk in response.chunk)
          MatrixRoom(
            id: chunk.roomId,
            name: chunk.name ?? chunk.canonicalAlias ?? chunk.roomId,
            topic: chunk.topic ?? '',
            alias: chunk.canonicalAlias ?? '',
            isPublic: true,
            isSpace: chunk.roomType == 'm.space',
            isEncrypted: false,
            lastActivity: DateTime.now(),
            lastMessage: '${chunk.numJoinedMembers} members',
          ),
      ];
    } finally {
      _directoryLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureTimeline(String roomId) async {
    if (_timelines.containsKey(roomId)) {
      return;
    }
    final room = _sdkRoom(roomId);
    if (room == null) {
      return;
    }
    Timeline? loaded;
    loaded = await room.getTimeline(
      onUpdate: () {
        final current = loaded;
        if (current == null) {
          return;
        }
        _events[roomId] = _mapEvents(current.events, room);
        notifyListeners();
      },
    );
    _timelines[roomId] = loaded;
    _events[roomId] = _mapEvents(loaded.events, room);
    unawaited(ensureMembers(roomId));
    notifyListeners();
  }

  Future<void> ensureMembers(String roomId) async {
    final room = _sdkRoom(roomId);
    if (room == null) {
      return;
    }
    final List<User> participants;
    try {
      participants = await room.requestParticipants();
    } on MatrixException catch (error) {
      final droppedRoomId = queueRoomMissingOnServer(client, error);
      if (droppedRoomId == null) {
        rethrow;
      }
      if (droppedRoomId == roomId) {
        _timelines.remove(roomId)?.cancelSubscriptions();
        _events.remove(roomId);
        _members.remove(roomId);
      }
      _rebuildRooms();
      notifyListeners();
      return;
    }
    _members[roomId] = [
      for (final user in participants)
        RoomMember(
          roomId: roomId,
          userId: user.id,
          role: _roleName(user.powerLevel),
          membership: user.membership.name,
        ),
    ];
    for (final user in participants) {
      _knownUsers[user.id] = MatrixUser(
        id: user.id,
        displayName: user.displayName ?? user.id,
      );
    }
    notifyListeners();
  }

  Future<void> updatePreferences(MatrixPreferences preferences) async {
    final previous = client.ignoredUsers.toSet();
    final next = preferences.blockedUserIds.toSet();
    _local = preferences;
    await _persistLocal();
    if (client.isLogged()) {
      await _uploadSettings();
    }
    if (client.isLogged()) {
      for (final id in next.difference(previous)) {
        await client.ignoreUser(id, leaveRooms: false);
      }
      for (final id in previous.difference(next)) {
        await client.unignoreUser(id);
      }
    }
    notifyListeners();
  }

  Future<void> updateDisplayName(String displayName) async {
    final userId = client.userID;
    if (userId == null) {
      throw Exception('Not signed in');
    }
    await client.setProfileField(userId, 'displayname', {
      'displayname': displayName,
    });
    _displayName = displayName;
    notifyListeners();
  }

  void dismissAnnouncement() {}

  Future<void> markRead(String roomId) async {
    final room = _sdkRoom(roomId);
    if (room == null) {
      return;
    }
    final eventId = _readMarkerEventId(room);
    if (eventId == null) {
      return;
    }
    try {
      await room.setReadMarker(
        eventId,
        mRead: preferences.sendReadReceipts ? eventId : null,
      );
    } on MatrixException catch (error) {
      // Local optimistic IDs or stale cache can point at events the HS no longer has.
      if (error.errcode == 'M_UNKNOWN' || error.errcode == 'M_NOT_FOUND') {
        return;
      }
      rethrow;
    }
  }

  /// Homeservers only accept persisted Matrix event IDs (`$…:domain`), not
  /// client transaction placeholders shown in `lastEvent` while sending.
  String? _readMarkerEventId(Room room) {
    final lastId = _persistedEventId(room.lastEvent);
    if (lastId != null) {
      return lastId;
    }
    final timeline = _timelines[room.id];
    if (timeline != null) {
      for (final event in timeline.events.reversed) {
        final id = _persistedEventId(event);
        if (id != null) {
          return id;
        }
      }
    }
    final marker = room.fullyRead;
    return marker.isEmpty ? null : marker;
  }

  String? _persistedEventId(Event? event) {
    if (event == null || !event.status.isSent) {
      return null;
    }
    final id = event.eventId;
    if (!id.startsWith('\$')) {
      return null;
    }
    return id;
  }

  Future<void> sendMessage({
    required String roomId,
    required String body,
    TimelineEventKind kind = TimelineEventKind.text,
    String? threadRootId,
    List<String> pollOptions = const [],
    String? fileName,
    String? mimeType,
    Uint8List? bytes,
    double? latitude,
    double? longitude,
  }) async {
    final room = _requireRoom(roomId);
    switch (kind) {
      case TimelineEventKind.text:
      case TimelineEventKind.notice:
        await room.sendTextEvent(
          body,
          msgtype: kind == TimelineEventKind.notice
              ? MessageTypes.Notice
              : MessageTypes.Text,
          threadRootEventId: threadRootId,
          parseCommands: false,
        );
      case TimelineEventKind.poll:
        await room.startPoll(
          question: body,
          answers: [
            for (var i = 0; i < pollOptions.length; i++)
              PollAnswer(id: '$i', mText: pollOptions[i]),
          ],
        );
      case TimelineEventKind.location:
        final lat = latitude;
        final lon = longitude;
        if (lat == null || lon == null) {
          throw Exception('Current location is not available');
        }
        await room.sendEvent({
          'msgtype': MessageTypes.Location,
          'body': body,
          'geo_uri': 'geo:$lat,$lon',
        }, type: EventTypes.Message);
      case TimelineEventKind.image:
      case TimelineEventKind.file:
      case TimelineEventKind.voice:
        final data = bytes;
        if (data == null || data.isEmpty) {
          throw Exception('Choose a file to send');
        }
        final name =
            fileName ??
            (kind == TimelineEventKind.voice ? 'voice.m4a' : 'file');
        final file = switch (kind) {
          TimelineEventKind.voice => MatrixAudioFile(
            bytes: data,
            name: name,
            mimeType: mimeType,
          ),
          TimelineEventKind.image => MatrixImageFile(
            bytes: data,
            name: name,
            mimeType: mimeType,
          ),
          _ => MatrixFile.fromMimeType(
            bytes: data,
            name: name,
            mimeType: mimeType,
          ),
        };
        await room.sendFileEvent(file, threadRootEventId: threadRootId);
      case TimelineEventKind.call:
        throw Exception('Call logs cannot be sent as messages');
    }
    await ensureTimeline(roomId);
  }

  Future<void> forwardEvent({
    required String destinationRoomId,
    required String sourceEventId,
  }) async {
    final event = _sdkEvent(sourceEventId);
    if (event == null) {
      throw Exception('Message not loaded');
    }
    final destination = _requireRoom(destinationRoomId);
    final kind = _kind(event);
    if (kind == null) {
      throw Exception('This message cannot be forwarded');
    }
    switch (kind) {
      case TimelineEventKind.poll:
        await destination.sendTextEvent(
          'Forwarded poll: ${event.body}',
          parseCommands: false,
        );
      case TimelineEventKind.text:
      case TimelineEventKind.notice:
        await destination.sendTextEvent(
          event.body,
          msgtype: kind == TimelineEventKind.notice
              ? MessageTypes.Notice
              : MessageTypes.Text,
          parseCommands: false,
        );
      case TimelineEventKind.location:
        final geoUri = event.content.tryGet<String>('geo_uri');
        if (geoUri == null || geoUri.isEmpty) {
          throw Exception('Location data is not available');
        }
        await destination.sendEvent({
          'msgtype': MessageTypes.Location,
          'body': event.body,
          'geo_uri': geoUri,
        }, type: EventTypes.Message);
      case TimelineEventKind.image:
      case TimelineEventKind.file:
      case TimelineEventKind.voice:
        final file = await event.downloadAndDecryptAttachment();
        await destination.sendFileEvent(file);
      case TimelineEventKind.call:
        throw Exception('This message cannot be forwarded');
    }
    await ensureTimeline(destinationRoomId);
  }

  Future<void> pinEvent(String eventId, {required bool pinned}) async {
    final event = _sdkEvent(eventId);
    if (event == null) {
      throw Exception('Message not loaded');
    }
    final ids = List<String>.from(event.room.pinnedEventIds);
    if (pinned) {
      ids.add(eventId);
    } else {
      ids.remove(eventId);
    }
    await event.room.setPinnedEvents(ids);
    await ensureTimeline(event.room.id);
  }

  Future<void> votePoll(String eventId, String option) async {
    final event = _sdkEvent(eventId);
    if (event == null) {
      throw Exception('Poll not loaded');
    }
    final answers = event.parsedPollEventContent.pollStartContent.answers;
    final match = answers.where(
      (answer) => answer.mText == option || answer.id == option,
    );
    if (match.isEmpty) {
      throw Exception('That option is not on the poll');
    }
    await event.answerPoll([match.first.id]);
  }

  Future<MatrixRoom> createRoom({
    required String name,
    String topic = '',
    bool isPublic = false,
    bool isEncrypted = true,
    bool isSpace = false,
    String? spaceId,
  }) async {
    final String roomId;
    if (isSpace) {
      roomId = await client.createSpace(
        name: name,
        topic: topic,
        visibility: isPublic ? Visibility.public : Visibility.private,
        waitForSync: true,
      );
    } else {
      roomId = await client.createGroupChat(
        groupName: name,
        enableEncryption: isEncrypted,
        preset: isPublic
            ? CreateRoomPreset.publicChat
            : CreateRoomPreset.privateChat,
        visibility: isPublic ? Visibility.public : Visibility.private,
      );
      if (topic.trim().isNotEmpty) {
        await client.getRoomById(roomId)?.setDescription(topic.trim());
      }
      final created = client.getRoomById(roomId);
      if (created != null) {
        await _allowGroupCallState(created);
      }
    }
    if (spaceId != null) {
      final space = client.getRoomById(spaceId);
      if (space != null && space.isSpace) {
        await space.setSpaceChild(roomId);
      }
    }
    _rebuildRooms();
    notifyListeners();
    return roomById(roomId) ??
        MatrixRoom(
          id: roomId,
          name: name,
          topic: topic,
          lastActivity: DateTime.now(),
          isSpace: isSpace,
        );
  }

  Future<String> ensureDirectChat(String userId) async {
    if (!userId.isValidMatrixIdStrict()) {
      throw Exception('Enter a full Matrix ID, like @name:server');
    }
    final roomId = await client.startDirectChat(userId);
    _rebuildRooms();
    notifyListeners();
    return roomId;
  }

  Future<String> joinRoom(String roomIdOrAlias) async {
    final existing = client.getRoomById(roomIdOrAlias);
    final directPartner = existing == null
        ? null
        : _directInvitePartner(existing);
    final roomId = await client.joinRoom(roomIdOrAlias);
    _joinedAt[roomId] = DateTime.now();
    _acceptedOnHome.add(roomId);
    if (directPartner != null) {
      try {
        await (client.getRoomById(roomId) ?? Room(id: roomId, client: client))
            .addToDirectChat(directPartner);
      } catch (error, stackTrace) {
        Logs().w(
          'Could not keep the joined room as a direct chat',
          error,
          stackTrace,
        );
      }
    }
    final joined = client.getRoomById(roomId);
    if (joined == null || joined.membership != Membership.join) {
      await client.waitForRoomInSync(roomId, join: true);
    }
    _rebuildRooms();
    notifyListeners();
    return roomId;
  }

  Future<String?> resolveAlias(String alias) async {
    final response = await client.getRoomIdByAlias(alias);
    return response.roomId;
  }

  Future<void> leaveRoom(String roomId) async {
    await _requireRoom(roomId).leave();
    _timelines.remove(roomId)?.cancelSubscriptions();
    _events.remove(roomId);
    _members.remove(roomId);
    _rebuildRooms();
    notifyListeners();
  }

  Future<void> updateRoom(String roomId, {String? name, String? topic}) async {
    final room = _requireRoom(roomId);
    if (name != null && name != room.name) {
      await room.setName(name);
    }
    if (topic != null) {
      await room.setDescription(topic);
    }
    _rebuildRooms();
    notifyListeners();
  }

  Future<void> setFavourite(String roomId, {required bool favourite}) async {
    final room = _requireRoom(roomId);
    if (favourite) {
      await room.addTag(TagType.favourite);
    } else {
      await room.removeTag(TagType.favourite);
    }
    _rebuildRooms();
    notifyListeners();
  }

  Future<void> invite(String roomId, String userId) async {
    if (!userId.isValidMatrixIdStrict()) {
      throw Exception('Enter a full Matrix ID, like @name:server');
    }
    await _requireRoom(roomId).invite(userId);
    await ensureMembers(roomId);
  }

  Future<void> setRole(String roomId, String userId, String role) async {
    final power = switch (role) {
      'admin' => 100,
      'moderator' => 50,
      _ => 0,
    };
    await _requireRoom(roomId).setPower(userId, power);
    await ensureMembers(roomId);
  }

  Future<void> kick(String roomId, String userId) async {
    await _requireRoom(roomId).kick(userId);
    await ensureMembers(roomId);
  }

  Future<void> ban(String roomId, String userId) async {
    await _requireRoom(roomId).ban(userId);
    await ensureMembers(roomId);
  }

  Future<void> acceptKnock(KnockRequest request) async {
    await invite(request.roomId, request.userId);
  }

  Future<void> declineKnock(KnockRequest request) async {
    await kick(request.roomId, request.userId);
  }

  Future<void> reportRoom(String roomId, {String reason = ''}) async {
    await client.reportRoom(roomId, reason);
    _reportedRooms.add(roomId);
    await _persistLocal();
    notifyListeners();
  }

  Future<void> setNotificationMode(String roomId, String mode) async {
    final room = _requireRoom(roomId);
    final state = switch (mode) {
      'mentions' => PushRuleState.mentionsOnly,
      'mute' => PushRuleState.dontNotify,
      _ => PushRuleState.notify,
    };
    await room.setPushRuleState(state);
    _notificationModes[roomId] = mode;
    await _persistLocal();
    notifyListeners();
  }

  Future<void> blockUser(String userId) =>
      client.ignoreUser(userId, leaveRooms: false);

  Future<void> unblockUser(String userId) => client.unignoreUser(userId);

  Future<String?> enableBackup(String recoveryKey) async {
    final encryption = client.encryption;
    if (encryption == null) {
      throw Exception('Encryption is not ready on this device');
    }
    if (encryption.ssss.defaultKeyId != null && recoveryKey.isNotEmpty) {
      final open = encryption.ssss.open();
      await open.unlock(keyOrPassphrase: recoveryKey);
      await open.maybeCacheAll();
      _recoveryKey = open.recoveryKey ?? recoveryKey;
      notifyListeners();
      return _recoveryKey;
    }
    final bootstrap = Bootstrap(encryption: encryption);
    if (bootstrap.state == BootstrapState.askWipeSsss) {
      throw Exception(
        'This account already has a recovery key. Enter that key.',
      );
    }
    if (bootstrap.state != BootstrapState.askNewSsss) {
      throw Exception('Secure backup cannot be created from this state');
    }
    await bootstrap.newSsss(recoveryKey.isEmpty ? null : recoveryKey);
    final created = bootstrap.newSsssKey?.recoveryKey;
    if (created == null || created.isEmpty) {
      throw Exception(
        bootstrap.errorResult?.error.toString() ??
            'Could not create a recovery key',
      );
    }
    _recoveryKey = created;
    notifyListeners();
    return created;
  }

  Future<void> verifyCurrentDevice() async {
    final userId = client.userID;
    final deviceId = client.deviceID;
    final device = userId == null || deviceId == null
        ? null
        : client.userDeviceKeys[userId]?.deviceKeys[deviceId];
    if (device == null) {
      throw Exception('This device is not in the device list yet');
    }
    await device.setVerified(true);
    notifyListeners();
  }

  Future<void> verifyDevice(String deviceId) async {
    final userId = client.userID;
    final device = userId == null
        ? null
        : client.userDeviceKeys[userId]?.deviceKeys[deviceId];
    if (device == null) {
      throw Exception('That device is not in the device list yet');
    }
    if (deviceId == client.deviceID) {
      throw Exception('This device is already signed in here');
    }
    _verification?.dispose();
    final request = await device.startVerification();
    request.onUpdate = notifyListeners;
    _verification = request;
    notifyListeners();
  }

  Future<void> confirmVerification() async {
    final request = _verification;
    if (request == null || request.state != KeyVerificationState.askSas) {
      throw Exception('There is nothing to confirm yet');
    }
    await request.acceptSas();
    notifyListeners();
  }

  void cancelVerification() {
    final request = _verification;
    _verification = null;
    if (request != null) {
      unawaited(request.cancel());
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> _iceServers = MatrixCallMedia.defaultIceServers;

  List<Map<String, dynamic>> get iceServers => _iceServers;

  Future<void> refreshIceServers() async {
    if (!client.isLogged()) {
      return;
    }
    try {
      final turn = await client.getTurnServer();
      final servers = <Map<String, dynamic>>[
        for (final uri in turn.uris)
          {
            'urls': uri.toString(),
            'username': turn.username,
            'credential': turn.password,
          },
        ...MatrixCallMedia.defaultIceServers,
      ];
      _iceServers = servers;
    } catch (_) {
      _iceServers = MatrixCallMedia.defaultIceServers;
    }
  }

  Future<void> startCall(String roomId, {bool video = false}) async {
    if (_groupSession && _callRoomId == roomId) {
      return;
    }
    final room = _requireRoom(roomId);
    final existing = _liveSnapshot(roomId);
    if (existing != null) {
      await _joinGroupCall(room, existing);
      return;
    }
    if (_activeCall != null) {
      throw Exception('A call is already in progress');
    }
    if (await _isGroupRoom(room)) {
      await _startGroupCall(room, video: video);
      return;
    }
    await _startDirectCall(room, video: video);
  }

  Future<void> joinGroupCall(String roomId) async {
    final room = _requireRoom(roomId);
    final existing = _liveSnapshot(roomId);
    if (existing == null) {
      throw Exception('There is no call to join');
    }
    await _joinGroupCall(room, existing);
  }

  Future<void> _startDirectCall(Room room, {required bool video}) async {
    final roomId = room.id;
    if (_activeCall != null) {
      throw Exception('A call is already in progress');
    }
    _callError = null;
    _failingCall = false;
    await refreshIceServers();
    final media = MatrixCallMedia(iceServers: _iceServers);
    final callId = client.generateUniqueTransactionId();
    _callId = callId;
    _callRoomId = roomId;
    _callMedia = media;
    _callSignalingSent = false;
    _negotiateReady = false;
    _pendingNegotiateOffer = null;
    _negotiateChain = null;
    _pendingOutbound.clear();
    _attachMedia(media);
    try {
      final sdp = await media.offer(
        video: video,
        onCandidate: _queueOutboundCandidate,
      );
      final invitee = _callInvitee(room);
      await _sendCallEvent(
        roomId: roomId,
        type: 'm.call.invite',
        content: {
          'call_id': callId,
          'version': '1',
          'lifetime': 60000,
          'party_id': _partyId,
          'offer': {'type': 'offer', 'sdp': sdp},
          'invitee': ?invitee,
        },
      );
      await _flushOutboundCandidates();
      _activeCall = MatrixCall(
        roomId: roomId,
        callId: callId,
        startedAt: DateTime.now(),
        video: video,
      );
      await _flushNegotiate();
      _armCallTimer(const Duration(seconds: 60));
      await media.setSpeaker(true);
      notifyListeners();
    } catch (error) {
      final invited = _callSignalingSent;
      await _finishCall(notifyRemote: invited);
      rethrow;
    }
  }

  Future<void> answerCall() async {
    final call = _activeCall;
    if (call != null && call.group) {
      final room = _requireRoom(call.roomId);
      await _enterGroup(
        room: room,
        callId: call.callId,
        video: call.video,
        startedAt: call.startedAt,
        status: MatrixCallStatus.connecting,
        create: false,
      );
      return;
    }
    final offer = _offerSdp;
    final roomId = _callRoomId;
    final callId = _callId;
    if (call == null ||
        call.status != MatrixCallStatus.incoming ||
        offer == null ||
        roomId == null ||
        callId == null) {
      throw Exception('There is no call to answer');
    }
    _requireRoom(roomId);
    await refreshIceServers();
    final media = MatrixCallMedia(iceServers: _iceServers);
    _callMedia = media;
    _callSignalingSent = false;
    _negotiateReady = false;
    _pendingOutbound.clear();
    _attachMedia(media);
    try {
      final sdp = await media.answer(
        offerSdp: offer,
        video: call.video,
        onCandidate: _queueOutboundCandidate,
      );
      if (_callId != callId) {
        await media.dispose();
        return;
      }
      await _sendCallEvent(
        roomId: roomId,
        type: 'm.call.answer',
        content: {
          'call_id': callId,
          'version': '1',
          'party_id': _partyId,
          'answer': {'type': 'answer', 'sdp': sdp},
        },
      );
      await _flushOutboundCandidates();
      await _flushRemoteCandidates();
      await _flushNegotiate();
      final current = _activeCall;
      if (current == null || _callId != callId) {
        return;
      }
      if (current.status != MatrixCallStatus.connected) {
        _activeCall = current.copyWith(status: MatrixCallStatus.connecting);
      }
      await media.setSpeaker(current.speakerOn);
      notifyListeners();
    } catch (error) {
      await media.dispose();
      if (identical(_callMedia, media)) {
        _callMedia = null;
      }
      rethrow;
    }
  }

  Future<void> rejectCall() async {
    final call = _activeCall;
    if (call != null &&
        call.group &&
        call.status == MatrixCallStatus.incoming) {
      final notificationId = _incomingRtcNotificationId;
      final roomId = call.roomId;
      _dismissedGroupCallId = call.callId;
      if (notificationId != null) {
        _dismissedRtcNotifications.add(notificationId);
      }
      _clearCallState();
      notifyListeners();
      if (notificationId != null) {
        try {
          await _sendRtcDecline(roomId, notificationId);
        } catch (_) {}
      }
      return;
    }
    await _finishCall(reject: true);
  }

  void updateCall(MatrixCall call) {
    _activeCall = call;
    if (_groupSession) {
      unawaited(_applyGroupControls(call));
      notifyListeners();
      return;
    }
    _callMedia?.setMuted(call.muted);
    _callMedia?.setVideoEnabled(call.video);
    unawaited(_callMedia?.setSpeaker(call.speakerOn));
    notifyListeners();
  }

  Future<void> endCall() => _finishCall();

  Future<void> clearCache() async {
    await client.clearCache();
    _events.clear();
    for (final timeline in _timelines.values) {
      timeline.cancelSubscriptions();
    }
    _timelines.clear();
    _members.clear();
    _rebuildRooms();
    notifyListeners();
  }

  void setOnline({required bool online}) {
    _online = online;
    notifyListeners();
  }

  void resetSessionData() {
    final media = _callMedia;
    _dropGroupMedia();
    _clearCallState();
    _groupSnapshots.clear();
    _endedGroupCalls.clear();
    _stateBackedCalls.clear();
    _clearedStaleMembers.clear();
    _dismissedGroupCallId = null;
    unawaited(media?.dispose());
    _events.clear();
    for (final timeline in _timelines.values) {
      timeline.cancelSubscriptions();
    }
    _timelines.clear();
    _members.clear();
    _knownUsers.clear();
    _directory = [];
    _displayName = '';
    _recoveryKey = null;
    _syncing = false;
    _rebuildRooms();
    notifyListeners();
  }

  Future<void> login({
    required String homeserver,
    required String username,
    required String password,
  }) async {
    await client.checkHomeserver(_homeserverUri(homeserver));
    await client.login(
      LoginType.mLoginPassword,
      identifier: AuthenticationUserIdentifier(user: username.trim()),
      password: password,
      initialDeviceDisplayName: AppConfig.deviceDisplayName,
    );
    await _captureProfile();
    _syncing = true;
    unawaited(refreshIceServers());
    _rebuildRooms();
    notifyListeners();
  }

  Future<void> restoreLoginSession({
    required Uri homeserver,
    required String accessToken,
    required String userId,
    required String deviceId,
  }) async {
    await client.checkHomeserver(homeserver);
    await client.init(
      newToken: accessToken,
      newUserID: userId,
      newHomeserver: homeserver,
      newDeviceID: deviceId,
      newDeviceName: AppConfig.deviceDisplayName,
    );
    await _captureProfile();
    _syncing = true;
    unawaited(refreshIceServers());
    _rebuildRooms();
    notifyListeners();
  }

  Future<void> register({
    required String homeserver,
    required String username,
    required String password,
    required String displayName,
  }) async {
    await client.checkHomeserver(_homeserverUri(homeserver));
    await client.register(
      username: _localpart(username),
      password: password,
      initialDeviceDisplayName: AppConfig.deviceDisplayName,
      auth: AuthenticationData(type: AuthenticationTypes.dummy),
    );
    await updateDisplayName(displayName);
    _syncing = true;
    unawaited(refreshIceServers());
    notifyListeners();
  }

  Future<void> logout() async {
    await _finishCall();
    try {
      if (client.isLogged()) {
        await client.logout();
      }
    } finally {
      resetSessionData();
    }
  }

  Future<void> deactivate({required String password}) async {
    final userId = client.userID;
    if (userId == null) {
      throw Exception('Not signed in');
    }
    await client.deactivateAccount(
      auth: AuthenticationData(
        type: AuthenticationTypes.password,
        additionalFields: {
          'identifier': {'type': 'm.id.user', 'user': userId},
          'password': password,
        },
      ),
    );
    await logout();
  }

  @override
  void dispose() {
    unawaited(_syncSubscription?.cancel());
    unawaited(_statusSubscription?.cancel());
    unawaited(_callSubscription?.cancel());
    unawaited(_toDeviceSubscription?.cancel());
    unawaited(_decryptedCallSubscription?.cancel());
    _callTimer?.cancel();
    _connectWatch?.cancel();
    _dropGroupMedia();
    unawaited(_callMedia?.dispose());
    for (final timeline in _timelines.values) {
      timeline.cancelSubscriptions();
    }
    unawaited(client.dispose());
    super.dispose();
  }

  void _onSync() {
    _syncing = false;
    _online = true;
    _applyAccountSettings();
    _rebuildRooms();
    unawaited(_captureProfile());
    _scheduleGroupSync();
    notifyListeners();
  }

  void _onCallEvent(Event event) {
    if (event.type == _groupSignalType) {
      if (event.content['party_id'] == _partyId) {
        return;
      }
      unawaited(_onGroupSignal(event));
      return;
    }
    if (event.type == _groupCallType || event.type == _groupMemberType) {
      if (event.content['party_id'] == _partyId) {
        return;
      }
      _applyGroupRosterEvent(event);
      _ringGroupCalls();
      notifyListeners();
      _scheduleGroupSync();
      return;
    }
    if (event.type == _rtcNotificationType) {
      _onRtcNotification(event);
      return;
    }
    if (event.type == _rtcDeclineType) {
      _onRtcDecline(event);
      return;
    }
    if (event.type == callEncryptionKeysEventType) {
      _ingestCallKeys(
        roomId: event.room.id,
        senderId: event.senderId,
        content: event.content,
      );
      return;
    }
    if (event.senderId == client.userID) {
      return;
    }
    switch (event.type) {
      case 'm.call.invite':
        unawaited(_onInvite(event));
      case 'm.call.answer':
        unawaited(_onAnswer(event));
      case 'm.call.candidates':
        unawaited(_onRemoteCandidates(event));
      case 'm.call.hangup':
      case 'm.call.reject':
        _onHangup(event);
      case 'm.call.select_answer':
        _onSelectAnswer(event);
      case 'm.call.negotiate':
        unawaited(_onNegotiate(event));
    }
  }

  Future<void> _onInvite(Event event) async {
    final callId = event.content['call_id'];
    final offer = event.content['offer'];
    final sdp = offer is Map ? offer['sdp'] : null;
    if (callId is! String || callId.isEmpty || sdp is! String || sdp.isEmpty) {
      return;
    }
    final invitee = event.content['invitee'];
    if (invitee is String && invitee.isNotEmpty && invitee != client.userID) {
      return;
    }
    final roomId = event.room.id;
    if (_callId != null) {
      await _sendHangup(roomId: roomId, callId: callId, reason: 'user_busy');
      return;
    }
    _offerSdp = sdp;
    _callId = callId;
    _callRoomId = roomId;
    _remotePartyId = _partyIdOf(event);
    _activeCall = MatrixCall(
      roomId: roomId,
      callId: callId,
      startedAt: DateTime.now(),
      status: MatrixCallStatus.incoming,
      video: _sdpHasVideo(sdp),
    );
    final lifetime = event.content['lifetime'];
    _armCallTimer(
      lifetime is num
          ? Duration(milliseconds: lifetime.toInt())
          : const Duration(seconds: 60),
    );
    notifyListeners();
  }

  Future<void> _onAnswer(Event event) async {
    if (event.content['call_id'] != _callId) {
      return;
    }
    final answer = event.content['answer'];
    final sdp = answer is Map ? answer['sdp'] : null;
    if (sdp is! String || sdp.isEmpty) {
      return;
    }
    final partyId = _partyIdOf(event);
    if (partyId != null) {
      _remotePartyId = partyId;
    }
    await _callMedia?.acceptAnswer(sdp);
    final call = _activeCall;
    if (call == null || _callId != event.content['call_id']) {
      return;
    }
    final selected = _remotePartyId;
    if (selected != null) {
      try {
        await _sendSelectAnswer(selected);
      } catch (_) {
        await _failCall('Could not send the call');
        return;
      }
    }
    if (_callId != event.content['call_id']) {
      return;
    }
    _activeCall = call.copyWith(status: MatrixCallStatus.connecting);
    notifyListeners();
  }

  void _onSelectAnswer(Event event) {
    if (event.content['call_id'] != _callId) {
      return;
    }
    final selected = event.content['selected_party_id'];
    if (selected is String && selected.isNotEmpty && selected != _partyId) {
      unawaited(_finishCall(notifyRemote: false));
    }
  }

  Future<void> _onNegotiate(Event event) async {
    if (event.content['call_id'] != _callId) {
      return;
    }
    final description = event.content['description'];
    if (description is! Map) {
      return;
    }
    final type = description['type'];
    final sdp = description['sdp'];
    if (sdp is! String || sdp.isEmpty) {
      return;
    }
    final roomId = _callRoomId;
    final callId = _callId;
    if (type == 'offer') {
      if (roomId == null || callId == null) {
        return;
      }
      _markRemoteVideo(sdp);
      if (!_negotiateReady || _callMedia == null) {
        _pendingNegotiateOffer = sdp;
        return;
      }
      await _answerNegotiateOffer(roomId, callId, sdp);
      return;
    }
    if (type == 'answer') {
      await _callMedia?.acceptAnswer(sdp);
    }
  }

  Future<void> _onRemoteCandidates(Event event) async {
    if (event.content['call_id'] != _callId) {
      return;
    }
    final candidates = event.content['candidates'];
    if (candidates is! List) {
      return;
    }
    final parsed = <RTCIceCandidate>[];
    for (final item in candidates) {
      if (item is Map && item['candidate'] is String) {
        final line = item['sdpMLineIndex'];
        parsed.add(
          RTCIceCandidate(
            item['candidate'] as String,
            item['sdpMid'] as String?,
            line is int ? line : (line is num ? line.toInt() : null),
          ),
        );
      }
    }
    if (parsed.isEmpty) {
      return;
    }
    if (_callMedia == null) {
      _pendingRemote.addAll(parsed);
      return;
    }
    for (final candidate in parsed) {
      await _callMedia?.addCandidate(candidate);
    }
  }

  void _onHangup(Event event) {
    if (event.content['call_id'] != _callId) {
      return;
    }
    unawaited(_finishCall(notifyRemote: false));
  }

  void _queueOutboundCandidate(RTCIceCandidate candidate) {
    if (!_callSignalingSent) {
      _pendingOutbound.add(candidate);
      return;
    }
    unawaited(_sendCandidatesSafely([candidate]));
  }

  Future<void> _flushOutboundCandidates() async {
    _callSignalingSent = true;
    final pending = List<RTCIceCandidate>.of(_pendingOutbound);
    _pendingOutbound.clear();
    await _sendCandidates(pending);
  }

  Future<void> _flushRemoteCandidates() async {
    final pending = List<RTCIceCandidate>.of(_pendingRemote);
    _pendingRemote.clear();
    for (final candidate in pending) {
      await _callMedia?.addCandidate(candidate);
    }
  }

  /// Applies a camera upgrade that arrived while this device was still ringing.
  ///
  /// Element Web often sends `m.call.negotiate` before `m.call.answer`. Answering
  /// that offer early has no peer connection, so the web client stays on
  /// connecting and the phone never opens the camera.
  Future<void> _flushNegotiate() async {
    _negotiateReady = true;
    final sdp = _pendingNegotiateOffer;
    _pendingNegotiateOffer = null;
    final roomId = _callRoomId;
    final callId = _callId;
    if (sdp == null || roomId == null || callId == null) {
      return;
    }
    await _answerNegotiateOffer(roomId, callId, sdp);
  }

  Future<void> _answerNegotiateOffer(String roomId, String callId, String sdp) {
    final previous = _negotiateChain ?? Future<void>.value();
    final task = previous.catchError((Object _) {}).then((_) async {
      if (_callId != callId || _callMedia == null) {
        return;
      }
      try {
        _markRemoteVideo(sdp);
        final answer = await _callMedia!.answerNegotiate(sdp);
        if (_callId != callId) {
          return;
        }
        await _sendCallEvent(
          roomId: roomId,
          type: 'm.call.negotiate',
          content: {
            'call_id': callId,
            'version': '1',
            'lifetime': 10000,
            'party_id': _partyId,
            'description': {'type': 'answer', 'sdp': answer},
          },
        );
      } catch (_) {}
    });
    _negotiateChain = task;
    return task;
  }

  void _markRemoteVideo(String sdp) {
    final call = _activeCall;
    if (call == null || call.video || !_sdpHasVideo(sdp)) {
      return;
    }
    _activeCall = call.copyWith(video: true);
    notifyListeners();
  }

  Future<void> _sendCandidatesSafely(List<RTCIceCandidate> candidates) async {
    try {
      await _sendCandidates(candidates);
    } catch (_) {}
  }

  Future<void> _sendCandidates(List<RTCIceCandidate> candidates) async {
    final roomId = _callRoomId;
    final callId = _callId;
    if (roomId == null || callId == null || candidates.isEmpty) {
      return;
    }
    if (_sdkRoom(roomId) == null) {
      return;
    }
    await _sendCallEvent(
      roomId: roomId,
      type: 'm.call.candidates',
      content: {
        'call_id': callId,
        'version': '1',
        'party_id': _partyId,
        'candidates': [
          for (final candidate in candidates)
            {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            },
        ],
      },
    );
  }

  Future<void> _sendHangup({
    required String roomId,
    required String callId,
    required String reason,
  }) async {
    if (_sdkRoom(roomId) == null) {
      return;
    }
    try {
      await _sendCallEvent(
        roomId: roomId,
        type: 'm.call.hangup',
        content: {
          'call_id': callId,
          'version': '1',
          'party_id': _partyId,
          'reason': reason,
        },
      );
    } catch (_) {}
  }

  Future<void> _sendReject({
    required String roomId,
    required String callId,
  }) async {
    if (_sdkRoom(roomId) == null) {
      return;
    }
    try {
      await _sendCallEvent(
        roomId: roomId,
        type: 'm.call.reject',
        content: {'call_id': callId, 'version': '1', 'party_id': _partyId},
      );
    } catch (_) {}
  }

  Future<void> _sendSelectAnswer(String selectedPartyId) async {
    final roomId = _callRoomId;
    final callId = _callId;
    if (roomId == null || callId == null) {
      return;
    }
    await _sendCallEvent(
      roomId: roomId,
      type: 'm.call.select_answer',
      content: {
        'call_id': callId,
        'version': '1',
        'party_id': _partyId,
        'selected_party_id': selectedPartyId,
      },
    );
  }

  Future<void> _sendCallEvent({
    required String roomId,
    required String type,
    required Map<String, Object?> content,
  }) async {
    if (_sdkRoom(roomId) == null) {
      throw Exception('Could not send the call');
    }
    await _sendPlainRoomEvent(
      roomId: roomId,
      type: type,
      content: Map<String, dynamic>.from(content),
    );
  }

  Future<String> _sendPlainRoomEvent({
    required String roomId,
    required String type,
    required Map<String, dynamic> content,
  }) async {
    final eventId = await client.sendMessage(
      roomId,
      type,
      client.generateUniqueTransactionId(),
      Map<String, Object?>.from(content),
    );
    if (eventId.isEmpty) {
      throw Exception('Could not send the call');
    }
    return eventId;
  }

  Future<void> _finishCall({
    String reason = 'user_hangup',
    bool notifyRemote = true,
    bool reject = false,
  }) async {
    if (_groupSession) {
      await _leaveGroupCall();
      return;
    }
    final roomId = _callRoomId;
    final callId = _callId;
    final media = _callMedia;
    final decline = reject && _activeCall?.status == MatrixCallStatus.incoming;
    if (callId == null && media == null && _activeCall == null) {
      return;
    }
    _clearCallState();
    notifyListeners();
    if (notifyRemote && roomId != null && callId != null) {
      if (decline) {
        await _sendReject(roomId: roomId, callId: callId);
      } else {
        await _sendHangup(roomId: roomId, callId: callId, reason: reason);
      }
    }
    await media?.dispose();
  }

  Future<void> _failCall(String message) async {
    if (_failingCall) {
      return;
    }
    _failingCall = true;
    _callError = message;
    await _finishCall(reason: 'ice_failed');
    _failingCall = false;
  }

  void _clearCallState() {
    _callTimer?.cancel();
    _callTimer = null;
    _connectWatch?.cancel();
    _connectWatch = null;
    _groupHeartbeat?.cancel();
    _groupHeartbeat = null;
    _activeCall = null;
    _callId = null;
    _callRoomId = null;
    _callMedia = null;
    _offerSdp = null;
    _remotePartyId = null;
    _callSignalingSent = false;
    _negotiateReady = false;
    _pendingNegotiateOffer = null;
    _negotiateChain = null;
    _iceRestarted = false;
    _pendingOutbound.clear();
    _pendingRemote.clear();
    _groupSession = false;
    _groupPeers.clear();
    _groupOfferSdp.clear();
    _groupOfferSentAt.clear();
    _groupQueuedCandidates.clear();
    _groupOffered.clear();
    _groupIceRestarted.clear();
    _queuedGroupSignals.clear();
    _groupLocal = null;
    _groupUpgrade = null;
    _incomingRtcNotificationId = null;
    _elementCallUrl = null;
    _matrixRtcPublished = false;
  }

  void _armCallTimer(Duration lifetime) {
    _callTimer?.cancel();
    _callTimer = Timer(lifetime, () {
      final call = _activeCall;
      if (call == null || call.status == MatrixCallStatus.connected) {
        return;
      }
      if (call.status == MatrixCallStatus.connecting) {
        unawaited(_failCall('The call could not connect'));
        return;
      }
      unawaited(_finishCall(reason: 'invite_timeout'));
    });
  }

  void _attachMedia(MatrixCallMedia media) {
    media.onStreamsChanged = _touchCallMedia;
    media.onConnectionState = _onPeerState;
    media.onIceConnectionState = _onIceState;
  }

  void _onPeerState(RTCPeerConnectionState state) {
    if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
      _markCallConnected();
      return;
    }
    if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
      unawaited(_onConnectStall());
    }
  }

  void _onIceState(RTCIceConnectionState state) {
    if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
        state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
      _armConnectWatch();
      return;
    }
    if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
      unawaited(_onConnectStall());
    }
  }

  void _markCallConnected() {
    _connectWatch?.cancel();
    _connectWatch = null;
    final call = _activeCall;
    if (call == null || call.status == MatrixCallStatus.connected) {
      return;
    }
    _callTimer?.cancel();
    _activeCall = call.copyWith(status: MatrixCallStatus.connected);
    notifyListeners();
  }

  void _armConnectWatch({bool reset = false}) {
    if (_activeCall?.status == MatrixCallStatus.connected) {
      return;
    }
    if (_callMedia?.isConnected == true) {
      return;
    }
    if (_connectWatch != null && !reset) {
      return;
    }
    _connectWatch?.cancel();
    _connectWatch = Timer(const Duration(seconds: 8), () {
      _connectWatch = null;
      unawaited(_onConnectStall());
    });
  }

  Future<void> _onConnectStall() async {
    final call = _activeCall;
    final media = _callMedia;
    if (call == null ||
        call.status == MatrixCallStatus.connected ||
        media == null ||
        media.isConnected ||
        _failingCall) {
      return;
    }
    if (_iceRestarted) {
      await _failCall('The call could not connect');
      return;
    }
    _iceRestarted = true;
    _connectWatch?.cancel();
    _connectWatch = null;
    final roomId = _callRoomId;
    final callId = _callId;
    if (roomId == null || callId == null) {
      await _failCall('The call could not connect');
      return;
    }
    try {
      final sdp = await media.restartIce();
      if (_callId != callId) {
        return;
      }
      await _sendCallEvent(
        roomId: roomId,
        type: 'm.call.negotiate',
        content: {
          'call_id': callId,
          'version': '1',
          'lifetime': 10000,
          'party_id': _partyId,
          'description': {'type': 'offer', 'sdp': sdp},
        },
      );
      _armConnectWatch(reset: true);
    } catch (_) {
      await _failCall('The call could not connect');
    }
  }

  Future<bool> _isGroupRoom(Room room) async {
    if (room.isDirectChat) {
      return false;
    }
    final joined = room.summary.mJoinedMemberCount;
    if (joined != null) {
      return joined >= 2;
    }
    try {
      final users = await room.requestParticipants([Membership.join]);
      return _otherJoinedCount(users) >= 1;
    } catch (_) {
      return _otherJoinedCount(room.getParticipants([Membership.join])) >= 1;
    }
  }

  int _otherJoinedCount(List<User> users) {
    final self = client.userID;
    return users.where((user) => user.id.isNotEmpty && user.id != self).length;
  }

  bool _groupCurrent(int epoch, String callId) =>
      epoch == _groupEpoch && _groupSession && _callId == callId;

  /// Membership published after hangup would leave this device in the call.
  /// Clear it when this attempt is no longer the active one.
  Future<bool> _elementCallStillCurrent({
    required int epoch,
    required String callId,
    required String roomId,
    required bool Function() published,
  }) async {
    if (_groupCurrent(epoch, callId)) {
      return true;
    }
    final session = _elementCall;
    _elementCall = null;
    if (session != null) {
      await session.dispose();
    }
    if (published() && !_groupSession) {
      try {
        await _publishMatrixRtcMembership(
          roomId: roomId,
          video: false,
          active: false,
        );
      } catch (_) {}
    }
    return false;
  }

  Future<void> _startGroupCall(Room room, {required bool video}) async {
    await _ensureCallStateLoaded(room);
    final joining = _hasOtherLiveMatrixRtcMember(room);
    await _enterGroup(
      room: room,
      callId: joining ? rtcRoomSlotId : client.generateUniqueTransactionId(),
      video: video,
      startedAt: DateTime.now(),
      status: joining ? MatrixCallStatus.connecting : MatrixCallStatus.outgoing,
      create: !joining,
    );
  }

  Future<void> _joinGroupCall(Room room, _GroupSnapshot snap) async {
    if (_groupSession && _callRoomId == room.id && _callId == snap.callId) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final others = snap.members.values
        .where((member) => member.partyId != _partyId && member.expiresAt > now)
        .length;
    if (others >= _groupCallLimit) {
      throw Exception('This call is full');
    }
    await _enterGroup(
      room: room,
      callId: snap.callId,
      video: snap.video,
      startedAt: snap.startedAt,
      status: MatrixCallStatus.connecting,
      create: false,
    );
  }

  Future<void> _enterGroup({
    required Room room,
    required String callId,
    required bool video,
    required DateTime startedAt,
    required MatrixCallStatus status,
    required bool create,
  }) async {
    final incoming =
        _activeCall != null &&
        _activeCall!.group &&
        _activeCall!.status == MatrixCallStatus.incoming &&
        _activeCall!.callId == callId;
    if (_activeCall != null && !incoming) {
      throw Exception('A call is already in progress');
    }
    _callError = null;
    _failingCall = false;
    await _allowGroupCallState(room);
    final epoch = ++_groupEpoch;
    _memberRev++;
    _groupSession = true;
    _callId = callId;
    _callRoomId = room.id;
    _dismissedGroupCallId = null;
    _endedGroupCalls.remove(callId);
    _clearedStaleMembers.remove('${room.id}|$callId|$_partyId');
    final expires = DateTime.now().add(_groupMemberTtl).millisecondsSinceEpoch;
    final existing = _groupSnapshots[room.id];
    final snap = existing != null && existing.callId == callId
        ? existing
        : _GroupSnapshot(callId: callId, video: video, startedAt: startedAt);
    snap.video = video;
    snap.startedAt = startedAt;
    snap.members[_partyId] = _GroupMember(
      partyId: _partyId,
      userId: client.userID ?? '',
      expiresAt: expires,
    );
    _groupSnapshots[room.id] = snap;
    _activeCall = MatrixCall(
      roomId: room.id,
      callId: callId,
      startedAt: startedAt,
      status: status,
      video: video,
      group: true,
      speakerOn: true,
    );
    notifyListeners();
    var published = false;
    try {
      final serviceUrl = await _livekitServiceUrl(room);
      if (serviceUrl == null) {
        throw Exception('This server has no call service');
      }
      _elementCallUrl = serviceUrl;
      if (!await _elementCallStillCurrent(
        epoch: epoch,
        callId: callId,
        roomId: room.id,
        published: () => published,
      )) {
        return;
      }
      final membershipEventId = await _publishMatrixRtcMembership(
        roomId: room.id,
        video: video,
        active: true,
      );
      published = true;
      if (!await _elementCallStillCurrent(
        epoch: epoch,
        callId: callId,
        roomId: room.id,
        published: () => published,
      )) {
        return;
      }
      if (create) {
        if (membershipEventId == null || membershipEventId.isEmpty) {
          throw Exception('Could not send the call');
        }
        await _sendRtcNotification(
          roomId: room.id,
          membershipEventId: membershipEventId,
          video: video,
        );
        if (!await _elementCallStillCurrent(
          epoch: epoch,
          callId: callId,
          roomId: room.id,
          published: () => published,
        )) {
          return;
        }
      }
      final livekit = await _livekitCredentials(
        roomId: room.id,
        serviceUrl: serviceUrl,
      );
      if (!await _elementCallStillCurrent(
        epoch: epoch,
        callId: callId,
        roomId: room.id,
        published: () => published,
      )) {
        return;
      }
      final session = LivekitRoomCall(
        onChanged: _onElementCallChanged,
        onRemoteJoined: () {
          final joinedRoom = _callRoomId;
          if (joinedRoom != null) {
            unawaited(_sendCallMediaKey(joinedRoom));
          }
        },
      );
      _elementCall = session;
      final userId = client.userID ?? '';
      await session.connect(
        url: livekit.url,
        token: livekit.jwt,
        video: video,
        encrypt: room.encrypted,
        identity: '$userId:$_partyId',
      );
      if (room.encrypted) {
        _applyPendingCallKeys(room.id);
        unawaited(_sendCallMediaKey(room.id));
      }
      if (!await _elementCallStillCurrent(
        epoch: epoch,
        callId: callId,
        roomId: room.id,
        published: () => published,
      )) {
        return;
      }
      try {
        await Helper.setSpeakerphoneOn(true);
      } catch (_) {}
      _armGroupHeartbeat();
      _markCallConnected();
      _touchCallMedia();
    } catch (error) {
      if (_groupCurrent(epoch, callId)) {
        _callError = matrixError(error);
        await _leaveGroupCall(publish: published);
      }
      rethrow;
    }
  }

  Future<void> _leaveGroupCall({bool publish = true}) async {
    if (!_groupSession &&
        _groupLocal == null &&
        _groupPeers.isEmpty &&
        _elementCall == null) {
      return;
    }
    final roomId = _callRoomId;
    final callId = _callId;
    final matrixRtc = _matrixRtcPublished;
    final session = _elementCall;
    _elementCall = null;
    _matrixRtcPublished = false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final snap = roomId == null ? null : _groupSnapshots[roomId];
    final others =
        snap?.members.values
            .where(
              (member) => member.partyId != _partyId && member.expiresAt > now,
            )
            .length ??
        0;
    _memberRev++;
    _groupEpoch++;
    final peers = List<MatrixCallMedia>.of(_groupPeers.values);
    final local = _groupLocal;
    final upgrade = _groupUpgrade;
    if (roomId != null) {
      _pendingCallKeys.removeWhere((item) => item.roomId == roomId);
    }
    snap?.members.remove(_partyId);
    if (callId != null && others == 0) {
      _endedGroupCalls.add(callId);
      _stateBackedCalls.remove(callId);
      if (roomId != null && _groupSnapshots[roomId]?.callId == callId) {
        _groupSnapshots.remove(roomId);
      }
    }
    _clearCallState();
    notifyListeners();
    for (final peer in peers) {
      await peer.dispose();
    }
    await _releaseStream(upgrade);
    await _releaseStream(local);
    await session?.dispose();
    if (!publish || roomId == null || callId == null) {
      return;
    }
    if (matrixRtc) {
      try {
        await _publishMatrixRtcMembership(
          roomId: roomId,
          video: false,
          active: false,
        );
      } catch (_) {}
      return;
    }
    try {
      await _publishMembership(roomId: roomId, callId: callId, active: false);
      if (others == 0) {
        await _publishCall(
          roomId: roomId,
          callId: callId,
          video: false,
          startedAt: DateTime.now(),
          active: false,
        );
      }
    } catch (_) {}
  }

  void _dropGroupMedia() {
    final session = _elementCall;
    _elementCall = null;
    if (session != null) {
      unawaited(session.dispose());
    }
    final peers = List<MatrixCallMedia>.of(_groupPeers.values);
    final local = _groupLocal;
    final upgrade = _groupUpgrade;
    _groupPeers.clear();
    _groupLocal = null;
    _groupUpgrade = null;
    _groupHeartbeat?.cancel();
    _groupHeartbeat = null;
    _groupSession = false;
    for (final peer in peers) {
      unawaited(peer.dispose());
    }
    unawaited(_releaseStream(upgrade));
    unawaited(_releaseStream(local));
  }

  Future<void> _releaseStream(MediaStream? stream) async {
    if (stream == null) {
      return;
    }
    for (final track in stream.getTracks()) {
      try {
        await track.stop();
      } catch (_) {}
    }
    try {
      await stream.dispose();
    } catch (_) {}
  }

  void _armGroupHeartbeat() {
    _groupHeartbeat?.cancel();
    _groupHeartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(_heartbeatGroup());
    });
  }

  Future<void> _heartbeatGroup() async {
    final rev = _memberRev;
    final epoch = _groupEpoch;
    final roomId = _callRoomId;
    final callId = _callId;
    if (!_groupSession || roomId == null || callId == null) {
      return;
    }
    if (rev != _memberRev || epoch != _groupEpoch) {
      return;
    }
    try {
      if (_elementCall != null) {
        await _publishMatrixRtcMembership(
          roomId: roomId,
          video: _activeCall?.video ?? false,
          active: true,
        );
        final sdkRoom = _sdkRoom(roomId);
        if (sdkRoom?.encrypted == true) {
          unawaited(_sendCallMediaKey(roomId));
        }
        return;
      }
      await _publishMembership(roomId: roomId, callId: callId, active: true);
      await _refreshCallAnnouncement(roomId, callId);
      if (rev != _memberRev) {
        await _publishMembership(roomId: roomId, callId: callId, active: false);
      }
    } catch (_) {}
  }

  Future<void> _refreshCallAnnouncement(String roomId, String callId) async {
    final room = _sdkRoom(roomId);
    final state = room?.getState(_groupCallType);
    if (state == null || state.content['call_id'] != callId) {
      return;
    }
    if (state.content['party_id'] != _partyId) {
      return;
    }
    final startedRaw = state.content['started_at'];
    final started = startedRaw is num
        ? DateTime.fromMillisecondsSinceEpoch(startedRaw.toInt())
        : _activeCall?.startedAt ?? DateTime.now();
    await _publishCall(
      roomId: roomId,
      callId: callId,
      video: state.content['video'] == true,
      startedAt: started,
      active: true,
    );
  }

  Future<String?> _publishMembership({
    required String roomId,
    required String callId,
    required bool active,
  }) async {
    final room = _sdkRoom(roomId);
    if (room == null) {
      return null;
    }
    final expires = DateTime.now().add(_groupMemberTtl).millisecondsSinceEpoch;
    final userId = client.userID ?? '';
    if (active && _groupSession && _callId == callId) {
      final snap = _groupSnapshots[roomId];
      if (snap != null && snap.callId == callId) {
        snap.members[_partyId] = _GroupMember(
          partyId: _partyId,
          userId: userId,
          expiresAt: expires,
        );
      }
    }
    final timeline = active
        ? <String, dynamic>{
            'call_id': callId,
            'party_id': _partyId,
            'user_id': userId,
            'expires_at': expires,
          }
        : <String, dynamic>{
            'call_id': callId,
            'party_id': _partyId,
            'active': false,
          };
    final eventId = await _sendPlainRoomEvent(
      roomId: roomId,
      type: _groupMemberType,
      content: timeline,
    );
    try {
      await client.setRoomStateWithKey(
        roomId,
        _groupMemberType,
        _partyId,
        active
            ? <String, Object?>{
                'call_id': callId,
                'user_id': userId,
                'expires_at': expires,
              }
            : <String, Object?>{},
      );
    } catch (_) {}
    return eventId;
  }

  Future<void> _sendRtcNotification({
    required String roomId,
    required String membershipEventId,
    required bool video,
  }) async {
    final room = _sdkRoom(roomId);
    if (room == null) {
      throw Exception('Could not send the call');
    }
    final sent = await room.sendEvent(
      <String, dynamic>{
        'slot_id': rtcRoomSlotId,
        'msc4354_sticky_key': rtcRoomSlotId,
        'm.mentions': {'user_ids': await _mentionIds(room), 'room': true},
        'notification_type': 'ring',
        'm.relates_to': {
          'event_id': membershipEventId,
          'rel_type': 'm.reference',
        },
        'sender_ts': DateTime.now().millisecondsSinceEpoch,
        'lifetime': rtcNotificationLifetimeMs,
        'm.call.intent': video ? 'video' : 'audio',
      },
      type: _rtcNotificationType,
      displayPendingEvent: false,
    );
    if (sent == null || sent.isEmpty) {
      throw Exception('Could not send the call');
    }
  }

  Future<List<String>> _mentionIds(Room room) async {
    final self = client.userID;
    List<User> users;
    try {
      users = await room.requestParticipants([Membership.join]);
    } catch (_) {
      users = room.getParticipants([Membership.join]);
    }
    return [
      for (final user in users)
        if (user.id.isNotEmpty && user.id != self) user.id,
    ];
  }

  String _matrixRtcStateKey() {
    final userId = client.userID ?? '';
    return '_${userId}_${_partyId}_m.call';
  }

  bool _hasOtherLiveMatrixRtcMember(Room room) {
    final events = room.states[matrixRtcMemberEventType];
    if (events == null) {
      return false;
    }
    final mine = _matrixRtcStateKey();
    for (final entry in events.entries) {
      if (entry.key == mine) {
        continue;
      }
      if (_matrixRtcMembershipLive(entry.value.content)) {
        return true;
      }
    }
    return false;
  }

  bool _matrixRtcMembershipLive(Map<String, dynamic> content) {
    final device = content['device_id'];
    if (device is! String || device.isEmpty) {
      return false;
    }
    final createdRaw = content['created_ts'];
    if (createdRaw is! num) {
      return false;
    }
    final basis = createdRaw.toInt();
    final expiresRaw = content['expires'];
    final expires = expiresRaw is num
        ? expiresRaw.toInt()
        : matrixRtcMemberExpiresMs;
    return DateTime.now().millisecondsSinceEpoch < basis + expires;
  }

  Future<String?> _publishMatrixRtcMembership({
    required String roomId,
    required bool video,
    required bool active,
  }) async {
    final key = _matrixRtcStateKey();
    if (!active) {
      await client.setRoomStateWithKey(
        roomId,
        matrixRtcMemberEventType,
        key,
        <String, Object?>{},
      );
      return null;
    }
    final url = _elementCallUrl;
    final userId = client.userID;
    if (url == null || userId == null) {
      throw Exception('This server has no call service');
    }
    final eventId = await client.setRoomStateWithKey(
      roomId,
      matrixRtcMemberEventType,
      key,
      <String, Object?>{
        'application': 'm.call',
        'call_id': '',
        'scope': 'm.room',
        'device_id': _partyId,
        'membershipID': '$userId:$_partyId',
        'created_ts': DateTime.now().millisecondsSinceEpoch,
        'expires': matrixRtcMemberExpiresMs,
        'm.call.intent': video ? 'video' : 'audio',
        'focus_active': <String, Object?>{
          'type': 'livekit',
          'focus_selection': 'oldest_membership',
        },
        'foci_preferred': [
          <String, Object?>{'type': 'livekit', 'livekit_service_url': url},
        ],
      },
    );
    _matrixRtcPublished = true;
    return eventId;
  }

  Future<String?> _livekitServiceUrl(Room room) async {
    final fromWellKnown = await _livekitServiceUrlFromWellKnown();
    if (fromWellKnown != null) {
      return fromWellKnown;
    }
    return _livekitServiceUrlFromMembership(room);
  }

  Future<String?> _livekitServiceUrlFromWellKnown() async {
    final base = client.homeserver;
    if (base == null) {
      return null;
    }
    try {
      final response = await client.httpClient.get(
        base.resolve('/.well-known/matrix/client'),
      );
      if (response.statusCode != 200) {
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return null;
      }
      return _livekitUrlFromFoci(decoded['org.matrix.msc4143.rtc_foci']);
    } catch (_) {
      return null;
    }
  }

  String? _livekitServiceUrlFromMembership(Room room) {
    final events = room.states[matrixRtcMemberEventType];
    if (events == null) {
      return null;
    }
    final mine = _matrixRtcStateKey();
    for (final entry in events.entries) {
      if (entry.key == mine) {
        continue;
      }
      final content = entry.value.content;
      if (!_matrixRtcMembershipLive(content)) {
        continue;
      }
      final url = _livekitUrlFromFoci(content['foci_preferred']);
      if (url != null) {
        return url;
      }
    }
    return null;
  }

  String? _livekitUrlFromFoci(Object? foci) {
    if (foci is! List) {
      return null;
    }
    for (final item in foci) {
      if (item is! Map) {
        continue;
      }
      if (item['type'] != 'livekit') {
        continue;
      }
      final url = item['livekit_service_url'];
      if (url is String && url.isNotEmpty) {
        return url;
      }
    }
    return null;
  }

  Uri _livekitServiceUri(String serviceUrl, String path) {
    final base = serviceUrl.endsWith('/') ? serviceUrl : '$serviceUrl/';
    return Uri.parse(base).resolve(path);
  }

  Future<({String url, String jwt})> _livekitCredentials({
    required String roomId,
    required String serviceUrl,
  }) async {
    final userId = client.userID;
    if (userId == null) {
      throw Exception('Not signed in');
    }
    final openId = (await client.requestOpenIdToken(userId, {})).toJson();
    // Legacy membership uses userId:deviceId. get_token assigns a hash the
    // web does not match, so the camera and microphone never arrive.
    return _readLivekitJwt(_livekitServiceUri(serviceUrl, 'sfu/get'), {
      'room': roomId,
      'openid_token': openId,
      'device_id': _partyId,
    });
  }

  Future<({String url, String jwt})> _readLivekitJwt(
    Uri uri,
    Map<String, Object?> payload,
  ) async {
    final response = await client.httpClient.post(
      uri,
      headers: {'content-type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200) {
      throw _livekitHttpError(response.body);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('Could not start the call');
    }
    final url = decoded['url'];
    final jwt = decoded['jwt'];
    if (url is! String || url.isEmpty || jwt is! String || jwt.isEmpty) {
      throw Exception('Could not start the call');
    }
    return (url: url, jwt: jwt);
  }

  Exception _livekitHttpError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = MatrixException.fromJson(
          Map<String, Object?>.from(decoded),
        );
        if (error.errorMessage.isNotEmpty) {
          return Exception(error.errorMessage);
        }
        if (error.errcode.isNotEmpty) {
          return Exception(error.errcode);
        }
      }
    } catch (error) {
      if (error is Exception && error is! FormatException) {
        rethrow;
      }
    }
    return Exception('Could not start the call');
  }

  void _onCallEncryptionKeys(ToDeviceEvent event) {
    if (event.type != callEncryptionKeysEventType) {
      return;
    }
    final roomId = event.content['room_id'];
    if (roomId is! String || roomId.isEmpty) {
      return;
    }
    _ingestCallKeys(
      roomId: roomId,
      senderId: event.sender,
      content: event.content,
    );
  }

  /// Element Call reads a to-device `keys` object (`{index, key}`). A list is
  /// dropped, so the web client never decrypts this device. The room event
  /// still uses a list, which is the older timeline shape.
  void _ingestCallKeys({
    required String roomId,
    required String senderId,
    required Map<String, dynamic> content,
  }) {
    if (senderId.isEmpty || senderId == client.userID) {
      return;
    }
    if (_callRoomId != null && roomId != _callRoomId) {
      return;
    }
    final identities = _callKeyIdentities(senderId, content);
    if (identities.isEmpty) {
      return;
    }
    for (final entry in _readCallKeyEntries(content['keys'])) {
      final bytes = _decodeCallKey(entry.key);
      if (bytes == null) {
        continue;
      }
      for (final identity in identities) {
        _pendingCallKeys.add(
          _CallMediaKey(
            roomId: roomId,
            identity: identity,
            key: bytes,
            index: entry.index,
          ),
        );
      }
    }
    if (_pendingCallKeys.length > 32) {
      _pendingCallKeys.removeRange(0, _pendingCallKeys.length - 32);
    }
    _applyPendingCallKeys(roomId);
  }

  List<({String key, int index})> _readCallKeyEntries(Object? keys) {
    if (keys is Map) {
      final encoded = keys['key'];
      final index = keys['index'];
      if (encoded is String && index is num) {
        return [(key: encoded, index: index.toInt())];
      }
      return const [];
    }
    if (keys is! List) {
      return const [];
    }
    final entries = <({String key, int index})>[];
    for (final item in keys) {
      if (item is! Map) {
        continue;
      }
      final encoded = item['key'];
      final index = item['index'];
      if (encoded is String && index is num) {
        entries.add((key: encoded, index: index.toInt()));
      }
    }
    return entries;
  }

  Set<String> _callKeyIdentities(
    String senderId,
    Map<String, dynamic> content,
  ) {
    final member = content['member'];
    final claimed = member is Map ? member['claimed_device_id'] : null;
    final memberId = member is Map ? member['id'] : null;
    final deviceField = content['device_id'];
    final device = claimed is String && claimed.isNotEmpty
        ? claimed
        : deviceField is String && deviceField.isNotEmpty
        ? deviceField
        : null;
    final identities = <String>{
      if (memberId is String && memberId.isNotEmpty) memberId,
      if (device != null) '$senderId:$device',
    };
    final remotes = _elementCall?.remoteIdentities ?? const <String>[];
    for (final remote in remotes) {
      if (device != null && remote == '$senderId:$device') {
        identities.add(remote);
      }
    }
    if (identities.isEmpty) {
      final matches = [
        for (final remote in remotes)
          if (remote.startsWith('$senderId:')) remote,
      ];
      if (matches.length == 1) {
        identities.add(matches.single);
      }
    }
    return identities;
  }

  Uint8List? _decodeCallKey(String encoded) {
    var normalized = encoded.replaceAll('-', '+').replaceAll('_', '/');
    final remainder = normalized.length % 4;
    if (remainder != 0) {
      normalized = normalized.padRight(
        normalized.length + (4 - remainder),
        '=',
      );
    }
    try {
      final bytes = base64Decode(normalized);
      if (bytes.isEmpty) {
        return null;
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }

  void _applyPendingCallKeys(String roomId) {
    final session = _elementCall;
    if (session == null || roomId != _callRoomId) {
      return;
    }
    final items = [
      for (final item in _pendingCallKeys)
        if (item.roomId == roomId) item,
    ];
    for (final item in items) {
      unawaited(session.setParticipantKey(item.identity, item.key, item.index));
    }
    final distinct = <String, _CallMediaKey>{};
    for (final item in items) {
      distinct[base64Encode(item.key)] = item;
    }
    if (distinct.length != 1) {
      return;
    }
    final key = distinct.values.first;
    for (final identity in session.remoteIdentities) {
      final known = items.any((item) => item.identity == identity);
      if (known) {
        continue;
      }
      unawaited(session.setParticipantKey(identity, key.key, key.index));
    }
  }

  Future<void> _sendCallMediaKey(String roomId) async {
    final session = _elementCall;
    final key = session?.localMediaKey;
    final userId = client.userID;
    if (session == null ||
        key == null ||
        userId == null ||
        _callRoomId != roomId) {
      return;
    }
    final encoded = base64Encode(key);
    final sentAt = DateTime.now().millisecondsSinceEpoch;
    final room = _sdkRoom(roomId);
    if (room != null) {
      try {
        await room.sendEvent(
          {
            'keys': [
              {'index': 0, 'key': encoded},
            ],
            'device_id': _partyId,
            'call_id': '',
            'sent_ts': sentAt,
          },
          type: callEncryptionKeysEventType,
          displayPendingEvent: false,
        );
      } catch (_) {}
    }
    final peers = _matrixRtcPeerDevices(roomId);
    if (peers.isEmpty) {
      return;
    }
    try {
      await client.userDeviceKeysLoading;
    } catch (_) {}
    final devices = <DeviceKeys>[];
    for (final peer in peers) {
      var device =
          client.userDeviceKeys[peer.userId]?.deviceKeys[peer.deviceId];
      if (device == null) {
        try {
          await client.updateUserDeviceKeys(additionalUsers: {peer.userId});
        } catch (_) {}
        device = client.userDeviceKeys[peer.userId]?.deviceKeys[peer.deviceId];
      }
      if (device != null) {
        devices.add(device);
      }
    }
    if (devices.isEmpty) {
      return;
    }
    try {
      await client.sendToDeviceEncrypted(devices, callEncryptionKeysEventType, {
        'keys': {'index': 0, 'key': encoded},
        'room_id': roomId,
        'member': {'claimed_device_id': _partyId, 'id': '$userId:$_partyId'},
        'session': {'call_id': '', 'application': 'm.call', 'scope': 'm.room'},
        'sent_ts': sentAt,
      });
    } catch (_) {}
  }

  List<({String userId, String deviceId})> _matrixRtcPeerDevices(
    String roomId,
  ) {
    final events = _sdkRoom(roomId)?.states[matrixRtcMemberEventType];
    if (events == null) {
      return const [];
    }
    final mine = _matrixRtcStateKey();
    final peers = <({String userId, String deviceId})>[];
    for (final entry in events.entries) {
      if (entry.key == mine) {
        continue;
      }
      final content = entry.value.content;
      if (!_matrixRtcMembershipLive(content)) {
        continue;
      }
      final deviceId = content['device_id'];
      final userId = entry.value.senderId;
      if (deviceId is String && deviceId.isNotEmpty && userId.isNotEmpty) {
        peers.add((userId: userId, deviceId: deviceId));
      }
    }
    return peers;
  }

  void _onElementCallChanged() {
    final roomId = _callRoomId;
    if (roomId != null) {
      _applyPendingCallKeys(roomId);
    }
    if (_elementCall == null) {
      return;
    }
    final call = _activeCall;
    if (call != null &&
        call.group &&
        call.status != MatrixCallStatus.connected) {
      _markCallConnected();
    }
    _touchCallMedia();
  }

  Future<void> _sendRtcDecline(
    String roomId,
    String notificationEventId,
  ) async {
    await _sendPlainRoomEvent(
      roomId: roomId,
      type: _rtcDeclineType,
      content: {
        'm.relates_to': {
          'event_id': notificationEventId,
          'rel_type': 'm.reference',
        },
        'msc4354_sticky_key': notificationEventId,
      },
    );
  }

  Future<void> _publishCall({
    required String roomId,
    required String callId,
    required bool video,
    required DateTime startedAt,
    required bool active,
  }) async {
    final room = _sdkRoom(roomId);
    if (room == null) {
      return;
    }
    final userId = client.userID;
    final expires = DateTime.now().add(_groupMemberTtl).millisecondsSinceEpoch;
    final body = active
        ? <String, dynamic>{
            'call_id': callId,
            'video': video,
            'started_at': startedAt.millisecondsSinceEpoch,
            if (userId != null) 'party_id': _partyId,
            'user_id': ?userId,
            if (userId != null) 'expires_at': expires,
          }
        : <String, dynamic>{'call_id': callId, 'active': false};
    await _sendPlainRoomEvent(
      roomId: roomId,
      type: _groupCallType,
      content: body,
    );
    try {
      await client.setRoomStateWithKey(
        roomId,
        _groupCallType,
        '',
        active ? Map<String, Object?>.from(body) : <String, Object?>{},
      );
      if (active) {
        _stateBackedCalls.add(callId);
      }
    } catch (_) {}
  }

  Future<void> _allowGroupCallState(Room room) async {
    final current = room.getState(EventTypes.RoomPowerLevels);
    final raw = current?.content;
    if (raw == null) {
      return;
    }
    final events = <String, Object?>{};
    final eventsRaw = raw['events'];
    if (eventsRaw is Map) {
      for (final entry in eventsRaw.entries) {
        final key = entry.key;
        if (key is String) {
          events[key] = entry.value;
        }
      }
    }
    if (events[_groupCallType] == 0 &&
        events[_groupMemberType] == 0 &&
        events[matrixRtcMemberEventType] == 0) {
      return;
    }
    events[_groupCallType] = 0;
    events[_groupMemberType] = 0;
    events[matrixRtcMemberEventType] = 0;
    final body = <String, Object?>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      if (key != 'events') {
        body[key] = entry.value;
      }
    }
    body['events'] = events;
    try {
      await client.setRoomStateWithKey(
        room.id,
        EventTypes.RoomPowerLevels,
        '',
        body,
      );
    } catch (_) {}
  }

  void _scheduleGroupSync() {
    unawaited(_syncGroupCalls());
  }

  Future<void> _syncGroupCalls() async {
    if (!client.isLogged()) {
      return;
    }
    if (_groupSyncing) {
      _groupSyncAgain = true;
      return;
    }
    _groupSyncing = true;
    try {
      do {
        _groupSyncAgain = false;
        await _syncGroupCallsOnce();
      } while (_groupSyncAgain);
    } finally {
      _groupSyncing = false;
    }
  }

  Future<void> _syncGroupCallsOnce() async {
    for (final room in client.rooms) {
      if (room.membership != Membership.join) {
        continue;
      }
      await _ensureCallStateLoaded(room);
      _foldGroupState(room);
      await _clearStaleMembership(room);
    }
    for (final snap in _groupSnapshots.values) {
      _pruneSnapshot(snap);
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    _groupSnapshots.removeWhere((roomId, snap) {
      if (_groupSession && _callRoomId == roomId && _callId == snap.callId) {
        return false;
      }
      final expired = snap.members.values.every(
        (member) => member.expiresAt <= now,
      );
      if (!expired) {
        return false;
      }
      return DateTime.now().difference(snap.startedAt) > _groupMemberTtl;
    });
    if (_elementCall == null &&
        _groupSession &&
        _callRoomId != null &&
        _callId != null) {
      final snap = _liveSnapshot(_callRoomId!);
      if (snap == null || snap.callId != _callId) {
        await _leaveGroupCall(publish: false);
        return;
      }
      await _reconcilePeers();
    }
    _ringGroupCalls();
    notifyListeners();
  }

  void _foldGroupState(Room room) {
    final state = room.getState(_groupCallType);
    if (state == null) {
      return;
    }
    final callId = state.content['call_id'];
    if (callId is! String || callId.isEmpty) {
      final existing = _groupSnapshots[room.id];
      if (existing == null || !_stateBackedCalls.contains(existing.callId)) {
        return;
      }
      if (_groupSession && _callId == existing.callId) {
        return;
      }
      _endedGroupCalls.add(existing.callId);
      _stateBackedCalls.remove(existing.callId);
      _groupSnapshots.remove(room.id);
      return;
    }
    if (_groupSession &&
        _callRoomId == room.id &&
        _callId != null &&
        _callId != callId) {
      return;
    }
    if (_endedGroupCalls.contains(callId)) {
      return;
    }
    _stateBackedCalls.add(callId);
    final startedRaw = state.content['started_at'];
    final started = startedRaw is num
        ? DateTime.fromMillisecondsSinceEpoch(startedRaw.toInt())
        : DateTime.now();
    final video = state.content['video'] == true;
    final existing = _groupSnapshots[room.id];
    final snap = existing != null && existing.callId == callId
        ? existing
        : _GroupSnapshot(callId: callId, video: video, startedAt: started);
    snap.video = video;
    snap.startedAt = started;
    _groupSnapshots[room.id] = snap;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final member in _membersFromState(room, callId)) {
      if (member.expiresAt > now) {
        snap.members[member.partyId] = member;
      }
    }
    _rememberAnnouncedMember(
      snap,
      Map<String, dynamic>.from(state.content),
      state.stateKey,
    );
    final live = snap.members.values.any((member) => member.expiresAt > now);
    if (!live &&
        snap.members.isNotEmpty &&
        DateTime.now().difference(started) > _groupMemberTtl &&
        !(_groupSession && _callId == callId)) {
      _endedGroupCalls.add(callId);
      _stateBackedCalls.remove(callId);
      _groupSnapshots.remove(room.id);
      unawaited(
        _publishCall(
          roomId: room.id,
          callId: callId,
          video: video,
          startedAt: started,
          active: false,
        ),
      );
    }
  }

  Future<void> _ensureCallStateLoaded(Room room) async {
    if (!room.partial) {
      return;
    }
    // Calls saved before these types were marked important are in the
    // non-preload box. That box is only read for types that are not important.
    client.importantStateEvents.remove(_groupCallType);
    client.importantStateEvents.remove(_groupMemberType);
    client.importantStateEvents.remove(matrixRtcMemberEventType);
    try {
      await room.postLoad();
    } catch (_) {
    } finally {
      client.importantStateEvents.addAll([
        _groupCallType,
        _groupMemberType,
        matrixRtcMemberEventType,
      ]);
    }
  }

  void _rememberAnnouncedMember(
    _GroupSnapshot snap,
    Map<String, dynamic> content,
    String? stateKey,
  ) {
    final partyRaw = content['party_id'];
    final partyId = partyRaw is String && partyRaw.isNotEmpty
        ? partyRaw
        : stateKey;
    if (partyId == null || partyId.isEmpty) {
      return;
    }
    final userId = content['user_id'];
    final expires = content['expires_at'];
    if (userId is! String || userId.isEmpty || expires is! num) {
      return;
    }
    final until = expires.toInt();
    if (until <= DateTime.now().millisecondsSinceEpoch) {
      return;
    }
    snap.members[partyId] = _GroupMember(
      partyId: partyId,
      userId: userId,
      expiresAt: until,
    );
  }

  List<_GroupMember> _membersFromState(Room room, String callId) {
    final table = room.states[_groupMemberType];
    if (table == null) {
      return const [];
    }
    final members = <_GroupMember>[];
    for (final entry in table.entries) {
      final content = entry.value.content;
      if (content['call_id'] != callId || entry.key.isEmpty) {
        continue;
      }
      final userId = content['user_id'];
      final expires = content['expires_at'];
      if (userId is! String || userId.isEmpty || expires is! num) {
        continue;
      }
      members.add(
        _GroupMember(
          partyId: entry.key,
          userId: userId,
          expiresAt: expires.toInt(),
        ),
      );
    }
    return members;
  }

  Future<void> _clearStaleMembership(Room room) async {
    final state = room.getState(_groupMemberType, _partyId);
    final callId = state?.content['call_id'];
    if (callId is! String || callId.isEmpty) {
      return;
    }
    if (_groupSession && _callRoomId == room.id && _callId == callId) {
      return;
    }
    _groupSnapshots[room.id]?.members.remove(_partyId);
    final key = '${room.id}|$callId|$_partyId';
    if (_clearedStaleMembers.contains(key)) {
      return;
    }
    _clearedStaleMembers.add(key);
    try {
      await _publishMembership(roomId: room.id, callId: callId, active: false);
    } catch (_) {}
  }

  void _pruneSnapshot(_GroupSnapshot snap) {
    final now = DateTime.now().millisecondsSinceEpoch;
    snap.members.removeWhere((partyId, member) {
      if (member.expiresAt > now) {
        return false;
      }
      return !(_groupSession && partyId == _partyId && _callId == snap.callId);
    });
  }

  _GroupSnapshot? _liveSnapshot(String roomId) {
    final snap = _groupSnapshots[roomId];
    if (snap == null || _endedGroupCalls.contains(snap.callId)) {
      return null;
    }
    _pruneSnapshot(snap);
    final now = DateTime.now().millisecondsSinceEpoch;
    final live = snap.members.values.any((member) => member.expiresAt > now);
    if (!live && !(_groupSession && _callId == snap.callId)) {
      return null;
    }
    return snap;
  }

  void _onRtcNotification(Event event) {
    if (event.senderId == client.userID || _activeCall != null) {
      return;
    }
    final eventId = event.eventId;
    if (eventId.isEmpty || _dismissedRtcNotifications.contains(eventId)) {
      return;
    }
    final remaining = _rtcNotificationRemaining(event);
    if (remaining == null) {
      return;
    }
    final roomId = event.room.id;
    if (_liveSnapshot(roomId) != null) {
      _ringGroupCalls();
      notifyListeners();
      return;
    }
    final intent = event.content['m.call.intent'];
    _incomingRtcNotificationId = eventId;
    _callId = eventId;
    _callRoomId = roomId;
    _activeCall = MatrixCall(
      roomId: roomId,
      callId: eventId,
      startedAt: DateTime.now(),
      status: MatrixCallStatus.incoming,
      video: intent != 'audio',
      group: true,
    );
    _armRtcRingTimer(remaining, eventId);
    notifyListeners();
  }

  void _onRtcDecline(Event event) {
    if (event.senderId != client.userID) {
      return;
    }
    final notificationId = _incomingRtcNotificationId;
    if (notificationId == null || !_rtcDeclineTargets(event, notificationId)) {
      return;
    }
    _dismissedRtcNotifications.add(notificationId);
    _clearCallState();
    notifyListeners();
  }

  bool _rtcDeclineTargets(Event event, String notificationId) {
    final relates = event.content['m.relates_to'];
    if (relates is! Map) {
      return false;
    }
    return relates['rel_type'] == 'm.reference' &&
        relates['event_id'] == notificationId;
  }

  Duration? _rtcNotificationRemaining(Event event) {
    final lifetimeRaw = event.content['lifetime'];
    if (lifetimeRaw is! num || lifetimeRaw <= 0) {
      return null;
    }
    final lifetime = lifetimeRaw.toInt();
    final origin = event.originServerTs.millisecondsSinceEpoch;
    final senderRaw = event.content['sender_ts'];
    var basis = origin;
    if (senderRaw is num && (senderRaw.toInt() - origin).abs() < 15000) {
      basis = senderRaw.toInt();
    }
    final remaining = basis + lifetime - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) {
      return null;
    }
    return Duration(milliseconds: remaining);
  }

  void _armRtcRingTimer(Duration lifetime, String notificationId) {
    _callTimer?.cancel();
    _callTimer = Timer(lifetime, () {
      if (_incomingRtcNotificationId != notificationId) {
        return;
      }
      final call = _activeCall;
      if (call == null || call.status != MatrixCallStatus.incoming) {
        _incomingRtcNotificationId = null;
        return;
      }
      _dismissedRtcNotifications.add(notificationId);
      _clearCallState();
      notifyListeners();
    });
  }

  void _ringGroupCalls() {
    final incoming = _activeCall;
    if (incoming != null &&
        incoming.group &&
        incoming.status == MatrixCallStatus.incoming) {
      if (_incomingRtcNotificationId != null) {
        if (_liveSnapshot(incoming.roomId) == null) {
          return;
        }
        _incomingRtcNotificationId = null;
        _clearCallState();
      } else {
        final still = _liveSnapshot(incoming.roomId);
        if (still == null || still.callId != incoming.callId) {
          _clearCallState();
        } else if (still.video != incoming.video) {
          _activeCall = incoming.copyWith(video: still.video);
        }
      }
    }
    if (_activeCall != null) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final room in client.rooms) {
      if (room.membership != Membership.join) {
        continue;
      }
      final snap = _liveSnapshot(room.id);
      if (snap == null || _dismissedGroupCallId == snap.callId) {
        continue;
      }
      final self = snap.members[_partyId];
      if (self != null && self.expiresAt > now) {
        continue;
      }
      final others = snap.members.values.where(
        (member) => member.partyId != _partyId && member.expiresAt > now,
      );
      if (others.isEmpty) {
        continue;
      }
      _callId = snap.callId;
      _callRoomId = room.id;
      _activeCall = MatrixCall(
        roomId: room.id,
        callId: snap.callId,
        startedAt: snap.startedAt,
        status: MatrixCallStatus.incoming,
        video: snap.video,
        group: true,
      );
      return;
    }
  }

  void _applyGroupRosterEvent(Event event) {
    final roomId = event.room.id;
    final callId = event.content['call_id'];
    if (callId is! String ||
        callId.isEmpty ||
        _endedGroupCalls.contains(callId)) {
      if (callId is String && event.content['active'] == false) {
        _endedGroupCalls.add(callId);
        if (_groupSnapshots[roomId]?.callId == callId &&
            !(_groupSession && _callId == callId)) {
          _groupSnapshots.remove(roomId);
        }
      }
      return;
    }
    if (event.type == _groupCallType) {
      if (event.content['active'] == false) {
        _endedGroupCalls.add(callId);
        if (_groupSnapshots[roomId]?.callId == callId &&
            !(_groupSession && _callId == callId)) {
          _groupSnapshots.remove(roomId);
        }
        return;
      }
      final startedRaw = event.content['started_at'];
      final started = startedRaw is num
          ? DateTime.fromMillisecondsSinceEpoch(startedRaw.toInt())
          : event.originServerTs;
      final video = event.content['video'] == true;
      final existing = _groupSnapshots[roomId];
      if (existing == null || existing.callId != callId) {
        if (_groupSession && _callRoomId == roomId && _callId != callId) {
          return;
        }
        _groupSnapshots[roomId] = _GroupSnapshot(
          callId: callId,
          video: video,
          startedAt: started,
        );
      } else {
        existing.video = video;
        existing.startedAt = started;
      }
      final snap = _groupSnapshots[roomId];
      if (snap != null && snap.callId == callId) {
        _rememberAnnouncedMember(snap, event.content, event.stateKey);
      }
      return;
    }
    final partyRaw = event.content['party_id'];
    final partyId = partyRaw is String && partyRaw.isNotEmpty
        ? partyRaw
        : event.stateKey;
    if (partyId == null || partyId.isEmpty) {
      return;
    }
    final snap = _groupSnapshots[roomId];
    if (event.content['active'] == false) {
      if (snap?.callId == callId) {
        snap!.members.remove(partyId);
      }
      return;
    }
    final userId = event.content['user_id'];
    final expires = event.content['expires_at'];
    if (userId is! String || expires is! num) {
      return;
    }
    final target = snap != null && snap.callId == callId
        ? snap
        : _GroupSnapshot(
            callId: callId,
            video: false,
            startedAt: event.originServerTs,
          );
    if (snap == null || snap.callId == callId) {
      target.members[partyId] = _GroupMember(
        partyId: partyId,
        userId: userId,
        expiresAt: expires.toInt(),
      );
      _groupSnapshots[roomId] = target;
    }
  }

  Future<void> _reconcilePeers() async {
    final roomId = _callRoomId;
    final callId = _callId;
    final epoch = _groupEpoch;
    if (roomId == null || callId == null || !_groupSession) {
      return;
    }
    final snap = _groupSnapshots[roomId];
    if (snap == null || snap.callId != callId) {
      return;
    }
    _pruneSnapshot(snap);
    final now = DateTime.now().millisecondsSinceEpoch;
    final remotes =
        snap.members.values
            .where(
              (member) => member.partyId != _partyId && member.expiresAt > now,
            )
            .toList()
          ..sort((a, b) => a.partyId.compareTo(b.partyId));
    final allowed = remotes
        .take(_groupCallLimit - 1)
        .map((member) => member.partyId)
        .toSet();
    final gone = _groupPeers.keys.where((id) => !allowed.contains(id)).toList();
    for (final id in gone) {
      final media = _groupPeers.remove(id);
      _groupOffered.remove(id);
      _groupOfferSdp.remove(id);
      _groupOfferSentAt.remove(id);
      _groupIceRestarted.remove(id);
      _groupQueuedCandidates.remove(id);
      await media?.dispose();
    }
    if (!_groupCurrent(epoch, callId)) {
      return;
    }
    for (final partyId in allowed) {
      if (!_groupCurrent(epoch, callId)) {
        return;
      }
      if (_partyId.compareTo(partyId) <= 0) {
        continue;
      }
      final media = _groupPeers[partyId];
      if (media == null) {
        await _offerTo(partyId);
        continue;
      }
      if (media.hasRemoteDescription) {
        continue;
      }
      final sdp = _groupOfferSdp[partyId];
      final sent = _groupOfferSentAt[partyId];
      if (sdp == null ||
          (sent != null &&
              DateTime.now().difference(sent) < const Duration(seconds: 5))) {
        continue;
      }
      try {
        await _sendGroupSignal(
          partyId,
          description: {'type': 'offer', 'sdp': sdp},
        );
        _groupOfferSentAt[partyId] = DateTime.now();
      } catch (_) {}
    }
  }

  Future<void> _offerTo(String partyId) async {
    if (_groupPeers.containsKey(partyId) || _groupOffered.contains(partyId)) {
      return;
    }
    final local = _groupLocal;
    final call = _activeCall;
    if (local == null || call == null || _partyId.compareTo(partyId) <= 0) {
      return;
    }
    _groupOffered.add(partyId);
    final media = MatrixCallMedia(iceServers: _iceServers, sharedLocal: local);
    _groupPeers[partyId] = media;
    _attachGroupMedia(partyId, media);
    try {
      final sdp = await media.offer(
        video: local.getVideoTracks().isNotEmpty,
        onCandidate: (candidate) {
          unawaited(_sendGroupCandidates(partyId, [candidate]));
        },
      );
      _groupOfferSdp[partyId] = sdp;
      _groupOfferSentAt[partyId] = DateTime.now();
      await _sendGroupSignal(
        partyId,
        description: {'type': 'offer', 'sdp': sdp},
      );
      await _flushQueuedCandidates(partyId);
    } catch (_) {
      _groupOffered.remove(partyId);
      _groupOfferSdp.remove(partyId);
      _groupPeers.remove(partyId);
      await media.dispose();
    }
  }

  Future<void> _onGroupSignal(Event event) async {
    if (_elementCall != null) {
      return;
    }
    final callId = event.content['call_id'];
    final dest = event.content['dest_party_id'];
    final partyId = event.content['party_id'];
    if (callId is! String ||
        dest != _partyId ||
        partyId is! String ||
        partyId.isEmpty) {
      return;
    }
    if (!_groupSession || _callId != callId) {
      if (_queuedGroupSignals.length < 32) {
        _queuedGroupSignals.add(event);
      }
      return;
    }
    await _applyGroupSignal(event);
  }

  Future<void> _applyGroupSignal(Event event) async {
    final partyId = event.content['party_id'];
    if (partyId is! String || partyId.isEmpty || !_groupSession) {
      return;
    }
    final description = event.content['description'];
    if (description is Map) {
      final type = description['type'];
      final sdp = description['sdp'];
      if (sdp is String && sdp.isNotEmpty && type == 'offer') {
        await _onGroupOffer(partyId, sdp);
      } else if (sdp is String && sdp.isNotEmpty && type == 'answer') {
        await _groupPeers[partyId]?.acceptAnswer(sdp);
        _touchCallMedia();
      }
    }
    final candidates = event.content['candidates'];
    if (candidates is! List) {
      return;
    }
    final parsed = <RTCIceCandidate>[];
    for (final item in candidates) {
      if (item is Map && item['candidate'] is String) {
        final line = item['sdpMLineIndex'];
        parsed.add(
          RTCIceCandidate(
            item['candidate'] as String,
            item['sdpMid'] as String?,
            line is int ? line : (line is num ? line.toInt() : null),
          ),
        );
      }
    }
    if (parsed.isEmpty) {
      return;
    }
    final media = _groupPeers[partyId];
    if (media == null) {
      (_groupQueuedCandidates[partyId] ??= []).addAll(parsed);
      return;
    }
    for (final candidate in parsed) {
      await media.addCandidate(candidate);
    }
  }

  Future<void> _onGroupOffer(String partyId, String sdp) async {
    final existing = _groupPeers[partyId];
    if (existing != null) {
      if (!existing.hasRemoteDescription) {
        return;
      }
      try {
        final answer = await existing.answerNegotiate(sdp);
        await _sendGroupSignal(
          partyId,
          description: {'type': 'answer', 'sdp': answer},
        );
      } catch (_) {}
      return;
    }
    if (_partyId.compareTo(partyId) > 0) {
      return;
    }
    final local = _groupLocal;
    final call = _activeCall;
    if (local == null || call == null) {
      return;
    }
    final media = MatrixCallMedia(iceServers: _iceServers, sharedLocal: local);
    _groupPeers[partyId] = media;
    _attachGroupMedia(partyId, media);
    try {
      final answer = await media.answer(
        offerSdp: sdp,
        video: call.video,
        onCandidate: (candidate) {
          unawaited(_sendGroupCandidates(partyId, [candidate]));
        },
      );
      await _flushQueuedCandidates(partyId);
      await _sendGroupSignal(
        partyId,
        description: {'type': 'answer', 'sdp': answer},
      );
    } catch (_) {
      _groupPeers.remove(partyId);
      await media.dispose();
    }
  }

  Future<void> _flushQueuedCandidates(String partyId) async {
    final pending = _groupQueuedCandidates.remove(partyId);
    final media = _groupPeers[partyId];
    if (pending == null || media == null) {
      return;
    }
    for (final candidate in pending) {
      await media.addCandidate(candidate);
    }
  }

  Future<void> _sendGroupCandidates(
    String partyId,
    List<RTCIceCandidate> candidates,
  ) async {
    if (candidates.isEmpty || !_groupSession) {
      return;
    }
    try {
      await _sendGroupSignal(
        partyId,
        candidates: [
          for (final candidate in candidates)
            {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            },
        ],
      );
    } catch (_) {}
  }

  Future<void> _sendGroupSignal(
    String dest, {
    Map<String, Object?>? description,
    List<Map<String, Object?>>? candidates,
  }) async {
    final roomId = _callRoomId;
    final callId = _callId;
    if (roomId == null || callId == null) {
      return;
    }
    final room = _sdkRoom(roomId);
    if (room == null) {
      return;
    }
    final sent = await room.sendEvent(
      <String, dynamic>{
        'call_id': callId,
        'party_id': _partyId,
        'dest_party_id': dest,
        'description': ?description,
        'candidates': ?candidates,
      },
      type: _groupSignalType,
      displayPendingEvent: false,
    );
    if (sent == null || sent.isEmpty) {
      throw Exception('Could not send the call');
    }
  }

  void _attachGroupMedia(String partyId, MatrixCallMedia media) {
    media.onStreamsChanged = _touchCallMedia;
    media.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _markCallConnected();
      }
      _touchCallMedia();
    };
    media.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        unawaited(_restartGroupIce(partyId));
      }
    };
  }

  Future<void> _restartGroupIce(String partyId) async {
    if (_groupIceRestarted.contains(partyId)) {
      return;
    }
    final media = _groupPeers[partyId];
    if (media == null || !_groupSession) {
      return;
    }
    _groupIceRestarted.add(partyId);
    try {
      final sdp = await media.restartIce();
      await _sendGroupSignal(
        partyId,
        description: {'type': 'offer', 'sdp': sdp},
      );
    } catch (_) {}
  }

  Future<void> _applyGroupControls(MatrixCall call) async {
    final session = _elementCall;
    if (session != null) {
      if (_callId != call.callId) {
        return;
      }
      await session.setMuted(call.muted);
      await session.setVideo(call.video);
      try {
        await Helper.setSpeakerphoneOn(call.speakerOn);
      } catch (_) {}
      _touchCallMedia();
      return;
    }
    final local = _groupLocal;
    if (local == null || _callId != call.callId) {
      return;
    }
    for (final track in local.getAudioTracks()) {
      track.enabled = !call.muted;
    }
    if (call.video && local.getVideoTracks().isEmpty) {
      try {
        final captured = await navigator.mediaDevices.getUserMedia({
          'audio': false,
          'video': true,
        });
        if (!_groupSession || !identical(_groupLocal, local)) {
          await _releaseStream(captured);
          return;
        }
        final previous = _groupUpgrade;
        _groupUpgrade = captured;
        await _releaseStream(previous);
        for (final track in captured.getVideoTracks()) {
          track.enabled = true;
          await local.addTrack(track);
          for (final peer in _groupPeers.values) {
            await peer.addLocalTrack(track);
          }
        }
        for (final entry in _groupPeers.entries) {
          if (!entry.value.hasRemoteDescription &&
              _partyId.compareTo(entry.key) <= 0) {
            continue;
          }
          final sdp = await entry.value.renegotiateOffer();
          await _sendGroupSignal(
            entry.key,
            description: {'type': 'offer', 'sdp': sdp},
          );
        }
      } catch (_) {}
    } else {
      for (final track in local.getVideoTracks()) {
        track.enabled = call.video;
      }
    }
    try {
      await Helper.setSpeakerphoneOn(call.speakerOn);
    } catch (_) {}
    _touchCallMedia();
  }

  MatrixCallParticipant _livekitParticipant(
    Room? room,
    LivekitParticipant person,
  ) {
    final userId = _matrixUserId(person.identity);
    return MatrixCallParticipant(
      partyId: person.identity,
      userId: userId,
      displayName: person.name.isNotEmpty
          ? person.name
          : room == null
          ? userId
          : _memberName(room, userId),
      connected: _elementCall?.remotes.containsKey(person.identity) ?? false,
    );
  }

  /// LiveKit identities are `@user:server:DEVICE`. Profile lookup needs the
  /// Matrix user id, which stops after the server name.
  String _matrixUserId(String identity) {
    final match = RegExp(r'^(@[^:]+:[^:]+)').firstMatch(identity);
    return match?.group(1) ?? identity;
  }

  String _memberName(Room room, String userId) {
    if (userId == client.userID && _displayName.isNotEmpty) {
      return _displayName;
    }
    final known = _knownUsers[userId]?.displayName;
    if (known != null && known.isNotEmpty && known != userId) {
      return known;
    }
    try {
      final name = room
          .unsafeGetUserFromMemoryOrFallback(userId)
          .calcDisplayname();
      if (name.isNotEmpty) {
        return name;
      }
    } catch (_) {}
    return userId;
  }

  String? _callInvitee(Room room) {
    final self = client.userID;
    final direct = room.directChatMatrixID;
    if (direct != null && direct.isNotEmpty && direct != self) {
      return direct;
    }
    final others = room
        .getParticipants([Membership.join])
        .map((user) => user.id)
        .where((id) => id.isNotEmpty && id != self)
        .toSet();
    if (others.length == 1) {
      return others.first;
    }
    return null;
  }

  String? _partyIdOf(Event event) {
    final partyId = event.content['party_id'];
    if (partyId is String && partyId.isNotEmpty) {
      return partyId;
    }
    return null;
  }

  void _touchCallMedia() {
    _callMediaGeneration++;
    notifyListeners();
  }

  bool _sdpHasVideo(String sdp) {
    for (final raw in sdp.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (!line.startsWith('m=video ')) {
        continue;
      }
      final parts = line.split(' ');
      if (parts.length > 1 && parts[1] != '0') {
        return true;
      }
    }
    return false;
  }

  String? _partyFallback;

  String get _partyId {
    final device = client.deviceID;
    if (device != null && device.isNotEmpty) {
      return device;
    }
    return _partyFallback ??=
        'element-x-${DateTime.now().microsecondsSinceEpoch}';
  }

  String? _verificationLabel(KeyVerificationState? state) {
    return switch (state) {
      null => null,
      KeyVerificationState.askSas =>
        'Confirm these emoji match the other device',
      KeyVerificationState.waitingAccept =>
        'Waiting for the other device to accept',
      KeyVerificationState.done => 'Device verified',
      KeyVerificationState.error => 'Verification failed',
      _ => 'Verification in progress',
    };
  }

  Map<String, Object?> _settingsPayload() {
    return {
      'analyticsEnabled': _local.analyticsEnabled,
      'sendReadReceipts': _local.sendReadReceipts,
      'notificationsEnabled': _local.notificationsEnabled,
      'labsThreads': _local.labsThreads,
      'labsRichText': _local.labsRichText,
      'developerMode': _local.developerMode,
      'showHiddenEvents': _local.showHiddenEvents,
      'contentScannerEnabled': _local.contentScannerEnabled,
      'mediaAutoLoad': _local.mediaAutoLoad,
      'locationSharingEnabled': _local.locationSharingEnabled,
      'statusMessage': _local.statusMessage,
    };
  }

  Future<void> _uploadSettings() async {
    final userId = client.userID;
    if (userId == null) {
      return;
    }
    try {
      await client.setAccountData(
        userId,
        settingsAccountData,
        _settingsPayload(),
      );
    } catch (_) {}
  }

  void _applyAccountSettings() {
    if (!client.isLogged()) {
      return;
    }
    final event = client.accountData[settingsAccountData];
    if (event == null) {
      unawaited(_uploadSettings());
      return;
    }
    final content = event.content;
    bool flag(String key, bool fallback) {
      final value = content[key];
      return value is bool ? value : fallback;
    }

    final status = content['statusMessage'];
    _local = _local.copyWith(
      analyticsEnabled: flag('analyticsEnabled', _local.analyticsEnabled),
      sendReadReceipts: flag('sendReadReceipts', _local.sendReadReceipts),
      notificationsEnabled: flag(
        'notificationsEnabled',
        _local.notificationsEnabled,
      ),
      labsThreads: flag('labsThreads', _local.labsThreads),
      labsRichText: flag('labsRichText', _local.labsRichText),
      developerMode: flag('developerMode', _local.developerMode),
      showHiddenEvents: flag('showHiddenEvents', _local.showHiddenEvents),
      contentScannerEnabled: flag(
        'contentScannerEnabled',
        _local.contentScannerEnabled,
      ),
      mediaAutoLoad: flag('mediaAutoLoad', _local.mediaAutoLoad),
      locationSharingEnabled: flag(
        'locationSharingEnabled',
        _local.locationSharingEnabled,
      ),
      statusMessage: status is String && status.isNotEmpty
          ? status
          : _local.statusMessage,
    );
  }

  void _onStatus(SyncStatusUpdate update) {
    if (update.status == SyncStatus.error) {
      _syncing = false;
      // The SDK abandons its first sync after 10s and retries. That timeout
      // is not a dropped connection.
      if (update.error?.exception is! TimeoutException) {
        _online = false;
      }
      notifyListeners();
    } else if (update.status == SyncStatus.finished) {
      _online = true;
      _syncing = false;
      notifyListeners();
    }
  }

  void _rebuildRooms() {
    final sdkRooms = client.rooms.where((room) {
      return room.membership == Membership.join ||
          room.membership == Membership.invite;
    }).toList();
    final spaceIds = <String, String>{};
    for (final room in sdkRooms.where((room) => room.isSpace)) {
      for (final child in room.spaceChildren) {
        final childId = child.roomId;
        if (childId != null) {
          spaceIds[childId] = room.id;
        }
      }
    }
    final mapped = <MatrixRoom>[];
    final spaces = <MatrixRoom>[];
    for (final room in sdkRooms) {
      final hero = room.directChatMatrixID;
      if (hero != null) {
        _knownUsers[hero] = MatrixUser(
          id: hero,
          displayName: room.getLocalizedDisplayname(),
        );
      }
      final last = room.lastEvent;
      final invited = room.membership == Membership.invite;
      final model = MatrixRoom(
        id: room.id,
        name: room.getLocalizedDisplayname(),
        topic: room.topic,
        alias: room.canonicalAlias,
        isDirect: room.isDirectChat,
        isSpace: room.isSpace,
        isEncrypted: room.encrypted,
        isFavourite: room.isFavourite,
        isPublic: room.joinRules == JoinRules.public,
        isInvited: invited,
        invitedBy: invited ? _invitedBy(room) : '',
        spaceId: spaceIds[room.id],
        unreadCount: room.notificationCount,
        lastMessage: _lastMessage(last),
        lastActivity: _roomActivity(room, last),
        heroUserId: hero,
        memberIds: [?client.userID, ?hero],
      );
      if (room.isSpace) {
        spaces.add(model);
      }
      // Joined spaces normally live in the drawer. A room the user just
      // accepted has to stay on the home list, or Accept looks like it failed.
      if (!room.isSpace || invited || _acceptedOnHome.contains(room.id)) {
        mapped.add(model);
      }
    }
    _rooms = mapped;
    _spaces = spaces;
  }

  /// Invite sync has no timeline event, so `lastEvent` is usually null.
  /// The SDK treats that as "now" instead of the epoch.
  DateTime _roomActivity(Room room, Event? last) {
    final stamp = last?.originServerTs;
    final joinedAt = _joinedAt[room.id];
    if (stamp != null && stamp.millisecondsSinceEpoch > 0) {
      if (joinedAt != null && joinedAt.isAfter(stamp)) {
        return joinedAt;
      }
      return stamp;
    }
    if (joinedAt != null) {
      return joinedAt;
    }
    if (room.membership == Membership.invite) {
      return room.latestEventReceivedTime;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Direct invites are only marked `is_direct` while membership is invite.
  /// After join, People filter uses `m.direct`, which the invitee does not have yet.
  String? _directInvitePartner(Room room) {
    if (room.membership != Membership.invite) {
      return null;
    }
    final userId = client.userID;
    if (userId == null) {
      return null;
    }
    final invitation = room.getState(EventTypes.RoomMember, userId);
    if (invitation?.content['is_direct'] != true) {
      return null;
    }
    final senderId = invitation?.senderId;
    if (senderId == null || senderId.isEmpty || senderId == userId) {
      return null;
    }
    return senderId;
  }

  String _invitedBy(Room room) {
    final userId = client.userID;
    if (userId == null) {
      return '';
    }
    final membership = room.getState(EventTypes.RoomMember, userId);
    final senderId = membership?.senderId;
    if (senderId == null || senderId.isEmpty || senderId == userId) {
      return '';
    }
    final sender = room.getState(EventTypes.RoomMember, senderId);
    if (sender != null) {
      final name = sender.asUser(room).calcDisplayname();
      if (name.isNotEmpty) {
        return name;
      }
    }
    return senderId.localpart ?? senderId;
  }

  List<TimelineEvent> _mapEvents(List<Event> events, Room room) {
    final pinned = room.pinnedEventIds.toSet();
    final mapped = <TimelineEvent>[];
    final calls = <String, List<Event>>{};
    for (final event in events) {
      if (event.relationshipType == RelationshipTypes.edit) {
        continue;
      }
      if (event.type.startsWith('m.call.')) {
        final callId = event.content.tryGet<String>('call_id');
        if (callId == null || callId.isEmpty) {
          continue;
        }
        (calls[callId] ??= []).add(event);
        continue;
      }
      final kind = _kind(event);
      if (kind == null) {
        continue;
      }
      final threadRoot = event.relationshipType == RelationshipTypes.thread
          ? event.relationshipEventId
          : null;
      mapped.add(
        TimelineEvent(
          id: event.eventId,
          roomId: room.id,
          senderId: event.senderId,
          body: event.messageType == MessageTypes.BadEncrypted
              ? 'Unable to decrypt this message'
              : event.body,
          timestamp: event.originServerTs,
          kind: kind,
          threadRootId: threadRoot,
          isPinned: pinned.contains(event.eventId),
          pollOptions: _pollOptions(event),
          pollVotes: _pollVotes(event),
          fileName: event.content.tryGet<String>('filename'),
        ),
      );
    }
    for (final group in calls.values) {
      final log = _callLog(group, room, pinned);
      if (log != null) {
        mapped.add(log);
      }
    }
    mapped.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return mapped;
  }

  TimelineEvent? _callLog(List<Event> events, Room room, Set<String> pinned) {
    Event? invite;
    Event? answer;
    Event? hangup;
    Event? reject;
    for (final event in events) {
      switch (event.type) {
        case 'm.call.invite':
          invite ??= event;
        case 'm.call.answer':
          answer ??= event;
        case 'm.call.hangup':
          if (hangup == null ||
              event.originServerTs.isAfter(hangup.originServerTs)) {
            hangup = event;
          }
        case 'm.call.reject':
          reject ??= event;
      }
    }
    Event? earliest;
    for (final event in [answer, hangup, reject]) {
      if (event == null) {
        continue;
      }
      if (earliest == null ||
          event.originServerTs.isBefore(earliest.originServerTs)) {
        earliest = event;
      }
    }
    final anchor = invite ?? earliest;
    if (anchor == null) {
      return null;
    }
    final video = invite != null && _isVideoCallInvite(invite);
    final kindLabel = video
        ? 'preview_video_call'.tr()
        : 'preview_voice_call'.tr();
    final outcome = _callOutcome(
      answer: answer,
      hangup: hangup,
      reject: reject,
    );
    return TimelineEvent(
      id: anchor.eventId,
      roomId: room.id,
      senderId: anchor.senderId,
      body: outcome == null ? kindLabel : '$kindLabel · $outcome',
      timestamp: anchor.originServerTs,
      kind: TimelineEventKind.call,
      isPinned: pinned.contains(anchor.eventId),
      video: video,
    );
  }

  String? _callOutcome({
    required Event? answer,
    required Event? hangup,
    required Event? reject,
  }) {
    if (answer != null && hangup != null) {
      return 'call_log_duration'.tr(
        args: [
          _formatCallDuration(
            hangup.originServerTs.difference(answer.originServerTs),
          ),
        ],
      );
    }
    if (answer != null) {
      return null;
    }
    if (reject != null) {
      return 'call_log_declined'.tr();
    }
    if (hangup == null) {
      return null;
    }
    final reason = hangup.content.tryGet<String>('reason');
    return switch (reason) {
      'invite_timeout' => 'call_log_missed'.tr(),
      'user_busy' => 'call_log_declined'.tr(),
      'user_hangup' => 'call_log_cancelled'.tr(),
      _ => 'call_log_cancelled'.tr(),
    };
  }

  String _formatCallDuration(Duration duration) {
    final seconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:$remainder';
    }
    return '$minutes:$remainder';
  }

  TimelineEventKind? _kind(Event event) {
    if (event.type == PollEventContent.startType) {
      return TimelineEventKind.poll;
    }
    if (event.type != EventTypes.Message &&
        event.type != EventTypes.Sticker &&
        event.messageType != MessageTypes.BadEncrypted) {
      return null;
    }
    return switch (event.messageType) {
      MessageTypes.Image => TimelineEventKind.image,
      MessageTypes.File => TimelineEventKind.file,
      MessageTypes.Audio => TimelineEventKind.voice,
      MessageTypes.Location => TimelineEventKind.location,
      MessageTypes.Notice => TimelineEventKind.notice,
      MessageTypes.BadEncrypted => TimelineEventKind.notice,
      _ => TimelineEventKind.text,
    };
  }

  List<String> _pollOptions(Event event) {
    if (event.type != PollEventContent.startType) {
      return const [];
    }
    return [
      for (final answer
          in event.parsedPollEventContent.pollStartContent.answers)
        answer.mText,
    ];
  }

  Map<String, int> _pollVotes(Event event) {
    final timeline = _timelines[event.room.id];
    if (timeline == null || event.type != PollEventContent.startType) {
      return const {};
    }
    final votes = <String, int>{};
    for (final answers in event.getPollResponses(timeline).values) {
      for (final answer in answers) {
        votes[answer] = (votes[answer] ?? 0) + 1;
      }
    }
    return votes;
  }

  String _lastMessage(Event? event) {
    if (event == null) {
      return '';
    }
    if (event.messageType == MessageTypes.BadEncrypted) {
      return 'Unable to decrypt';
    }
    return switch (event.type) {
      'm.call.invite' =>
        _isVideoCallInvite(event) ? 'preview_video_call' : 'preview_voice_call',
      'm.call.answer' => 'preview_call_answered',
      'm.call.hangup' => 'preview_call_ended',
      'm.call.reject' => 'preview_call_declined',
      'm.call.negotiate' ||
      'm.call.candidates' ||
      'm.call.select_answer' ||
      _groupCallType ||
      _groupMemberType ||
      _groupSignalType ||
      _rtcNotificationType ||
      _rtcDeclineType => 'preview_call_activity',
      _ => _lastMessageBody(event),
    };
  }

  bool _isVideoCallInvite(Event event) {
    final offer = event.content.tryGet<Map<String, Object?>>('offer');
    final sdp = offer?['sdp'];
    if (sdp is String && sdp.contains('m=video')) {
      return true;
    }
    return false;
  }

  String _lastMessageBody(Event event) {
    final body = event.body.trim();
    if (body.isEmpty || body.startsWith('Unknown message format of type')) {
      return 'preview_unsupported_event';
    }
    return body;
  }

  Event? _sdkEvent(String eventId) {
    for (final timeline in _timelines.values) {
      for (final event in timeline.events) {
        if (event.eventId == eventId) {
          return event;
        }
      }
    }
    return null;
  }

  Room? _sdkRoom(String roomId) => client.getRoomById(roomId);

  Room _requireRoom(String roomId) {
    final room = _sdkRoom(roomId);
    if (room == null) {
      throw Exception('Room not found');
    }
    return room;
  }

  String _roleName(PowerLevel power) {
    return switch (power.role) {
      PowerLevelRole.owner || PowerLevelRole.admin => 'admin',
      PowerLevelRole.moderator => 'moderator',
      PowerLevelRole.user => 'member',
    };
  }

  Future<void> _captureProfile() async {
    if (!client.isLogged()) {
      return;
    }
    try {
      final profile = await client.getUserProfile(client.userID!);
      final name = profile.displayname;
      if (name != null && name.isNotEmpty) {
        _displayName = name;
        notifyListeners();
      }
    } catch (_) {
      _displayName = _localpart(client.userID ?? '');
    }
  }

  void _loadLocal() {
    final raw = _session.read(localPrefsKey);
    if (raw is! String || raw.isEmpty) {
      return;
    }
    final json = jsonDecode(raw);
    if (json is! Map) {
      return;
    }
    final modes = json['notificationModes'];
    if (modes is Map) {
      _notificationModes
        ..clear()
        ..addAll(
          modes.map((key, value) => MapEntry(key.toString(), value.toString())),
        );
    }
    _local = MatrixPreferences(
      analyticsEnabled: json['analyticsEnabled'] == true,
      sendReadReceipts: json['sendReadReceipts'] != false,
      notificationsEnabled: json['notificationsEnabled'] != false,
      lockScreenEnabled: json['lockScreenEnabled'] == true,
      labsThreads: json['labsThreads'] != false,
      labsRichText: json['labsRichText'] == true,
      developerMode: json['developerMode'] == true,
      showHiddenEvents: json['showHiddenEvents'] == true,
      contentScannerEnabled: json['contentScannerEnabled'] == true,
      mediaAutoLoad: json['mediaAutoLoad'] != false,
      locationSharingEnabled: json['locationSharingEnabled'] != false,
      statusMessage: json['statusMessage'] as String? ?? 'Available',
    );
  }

  Future<void> _persistLocal() async {
    await _session.write(
      localPrefsKey,
      jsonEncode({
        'analyticsEnabled': _local.analyticsEnabled,
        'sendReadReceipts': _local.sendReadReceipts,
        'notificationsEnabled': _local.notificationsEnabled,
        'lockScreenEnabled': _local.lockScreenEnabled,
        'labsThreads': _local.labsThreads,
        'labsRichText': _local.labsRichText,
        'developerMode': _local.developerMode,
        'showHiddenEvents': _local.showHiddenEvents,
        'contentScannerEnabled': _local.contentScannerEnabled,
        'mediaAutoLoad': _local.mediaAutoLoad,
        'locationSharingEnabled': _local.locationSharingEnabled,
        'statusMessage': _local.statusMessage,
        'notificationModes': _notificationModes,
      }),
    );
  }

  String _localNotification(String roomId) =>
      _notificationModes[roomId] ?? 'all';

  final Map<String, String> _notificationModes = {};
  final Set<String> _reportedRooms = {};

  Uri _homeserverUri(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Uri.parse(trimmed);
    }
    return Uri.https(trimmed, '');
  }

  String _localpart(String username) {
    final trimmed = username.trim();
    final withoutAt = trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
    return withoutAt.split(':').first;
  }
}

class _CallMediaKey {
  const _CallMediaKey({
    required this.roomId,
    required this.identity,
    required this.key,
    required this.index,
  });

  final String roomId;
  final String identity;
  final Uint8List key;
  final int index;
}

class _GroupSnapshot {
  _GroupSnapshot({
    required this.callId,
    required this.video,
    required this.startedAt,
  });

  final String callId;
  bool video;
  DateTime startedAt;
  final Map<String, _GroupMember> members = {};
}

class _GroupMember {
  _GroupMember({
    required this.partyId,
    required this.userId,
    required this.expiresAt,
  });

  final String partyId;
  final String userId;
  int expiresAt;
}

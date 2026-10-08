import 'dart:async';
import 'dart:convert';

import 'package:element_x/core/config/app_config.dart';
import 'package:element_x/core/local_storage/session_store.dart';
import 'package:element_x/core/matrix/matrix_call_media.dart';
import 'package:element_x/core/matrix/matrix_database.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/core/matrix/stale_room.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart' hide RoomMember;

/// Live Matrix cache. Screens read this synchronously; writes go to the SDK.
class MatrixStore extends ChangeNotifier {
  MatrixStore(this.client, this._session, {this.databasePath}) {
    _loadLocal();
    _syncing = client.isLogged();
    _rebuildRooms();
    _syncSubscription = client.onSync.stream.listen((_) => _onSync());
    _statusSubscription = client.onSyncStatus.stream.listen(_onStatus);
    _callSubscription = client.onTimelineEvent.stream.listen(_onCallEvent);
  }

  static const localPrefsKey = 'localPrefs';
  static const settingsAccountData = 'io.element.element_x.settings';

  final Client client;
  final SessionStore _session;
  final String? databasePath;

  final Map<String, List<TimelineEvent>> _events = {};
  final Map<String, Timeline> _timelines = {};
  final Map<String, List<RoomMember>> _members = {};
  final Map<String, MatrixUser> _knownUsers = {};

  List<MatrixRoom> _rooms = [];
  List<MatrixRoom> _spaces = [];
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
  MediaStream? get localCallStream => _callMedia?.local;
  MediaStream? get remoteCallStream => _callMedia?.remote;
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
    final roomId = await client.joinRoom(roomIdOrAlias);
    await client.waitForRoomInSync(roomId, join: true);
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
    if (_activeCall != null) {
      throw Exception('A call is already in progress');
    }
    _callError = null;
    _failingCall = false;
    await refreshIceServers();
    final room = _requireRoom(roomId);
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

  Future<void> rejectCall() => _finishCall(reject: true);

  void updateCall(MatrixCall call) {
    _activeCall = call;
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
    _clearCallState();
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
    _callTimer?.cancel();
    _connectWatch?.cancel();
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
    notifyListeners();
  }

  void _onCallEvent(Event event) {
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

  Future<void> _answerNegotiateOffer(
    String roomId,
    String callId,
    String sdp,
  ) {
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
    final eventId = await client.sendMessage(
      roomId,
      type,
      client.generateUniqueTransactionId(),
      content,
    );
    if (eventId.isEmpty) {
      throw Exception('Could not send the call');
    }
  }

  Future<void> _finishCall({
    String reason = 'user_hangup',
    bool notifyRemote = true,
    bool reject = false,
  }) async {
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

  String get _partyId => client.deviceID ?? 'element-x';

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
        spaceId: spaceIds[room.id],
        unreadCount: room.notificationCount,
        lastMessage: _lastMessage(last),
        lastActivity:
            last?.originServerTs ?? DateTime.fromMillisecondsSinceEpoch(0),
        heroUserId: hero,
        memberIds: [?client.userID, ?hero],
      );
      if (room.isSpace) {
        spaces.add(model);
      } else {
        mapped.add(model);
      }
    }
    _rooms = mapped;
    _spaces = spaces;
  }

  List<TimelineEvent> _mapEvents(List<Event> events, Room room) {
    final pinned = room.pinnedEventIds.toSet();
    final mapped = <TimelineEvent>[];
    for (final event in events) {
      if (event.relationshipType == RelationshipTypes.edit) {
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
    mapped.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return mapped;
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
      'm.call.invite' => _isVideoCallInvite(event)
          ? 'preview_video_call'.tr()
          : 'preview_voice_call'.tr(),
      'm.call.answer' => 'preview_call_answered'.tr(),
      'm.call.hangup' => 'preview_call_ended'.tr(),
      'm.call.reject' => 'preview_call_declined'.tr(),
      'm.call.negotiate' ||
      'm.call.candidates' ||
      'm.call.select_answer' =>
        'preview_call_activity'.tr(),
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
    if (body.isEmpty ||
        body.startsWith('Unknown message format of type')) {
      return 'preview_unsupported_event'.tr();
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

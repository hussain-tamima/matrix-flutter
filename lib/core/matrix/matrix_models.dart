import 'package:equatable/equatable.dart';

enum TimelineEventKind { text, image, poll, location, voice, notice, file }

class MatrixUser extends Equatable {
  const MatrixUser({
    required this.id,
    required this.displayName,
    this.statusMessage = '',
  });

  final String id;
  final String displayName;
  final String statusMessage;

  @override
  List<Object?> get props => [id, displayName, statusMessage];
}

class MatrixRoom extends Equatable {
  const MatrixRoom({
    required this.id,
    required this.name,
    required this.lastActivity,
    this.topic = '',
    this.alias = '',
    this.isDirect = false,
    this.isSpace = false,
    this.isEncrypted = true,
    this.isFavourite = false,
    this.isPublic = false,
    this.spaceId,
    this.unreadCount = 0,
    this.lastMessage = '',
    this.memberIds = const [],
    this.heroUserId,
  });

  final String id;
  final String name;
  final String topic;
  final String alias;
  final bool isDirect;
  final bool isSpace;
  final bool isEncrypted;
  final bool isFavourite;
  final bool isPublic;
  final String? spaceId;
  final int unreadCount;
  final String lastMessage;
  final DateTime lastActivity;
  final List<String> memberIds;
  final String? heroUserId;

  MatrixRoom copyWith({
    String? name,
    String? topic,
    String? alias,
    bool? isDirect,
    bool? isSpace,
    bool? isEncrypted,
    bool? isFavourite,
    bool? isPublic,
    String? spaceId,
    int? unreadCount,
    String? lastMessage,
    DateTime? lastActivity,
    List<String>? memberIds,
    String? heroUserId,
  }) {
    return MatrixRoom(
      id: id,
      name: name ?? this.name,
      topic: topic ?? this.topic,
      alias: alias ?? this.alias,
      isDirect: isDirect ?? this.isDirect,
      isSpace: isSpace ?? this.isSpace,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      isFavourite: isFavourite ?? this.isFavourite,
      isPublic: isPublic ?? this.isPublic,
      spaceId: spaceId ?? this.spaceId,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessage: lastMessage ?? this.lastMessage,
      lastActivity: lastActivity ?? this.lastActivity,
      memberIds: memberIds ?? this.memberIds,
      heroUserId: heroUserId ?? this.heroUserId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    topic,
    alias,
    isDirect,
    isSpace,
    isEncrypted,
    isFavourite,
    isPublic,
    spaceId,
    unreadCount,
    lastMessage,
    lastActivity,
    memberIds,
    heroUserId,
  ];
}

class RoomMember extends Equatable {
  const RoomMember({
    required this.roomId,
    required this.userId,
    this.role = 'member',
    this.membership = 'join',
  });

  final String roomId;
  final String userId;
  final String role;
  final String membership;

  RoomMember copyWith({String? role, String? membership}) {
    return RoomMember(
      roomId: roomId,
      userId: userId,
      role: role ?? this.role,
      membership: membership ?? this.membership,
    );
  }

  @override
  List<Object?> get props => [roomId, userId, role, membership];
}

class TimelineEvent extends Equatable {
  const TimelineEvent({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.body,
    required this.timestamp,
    this.kind = TimelineEventKind.text,
    this.threadRootId,
    this.isPinned = false,
    this.pollOptions = const [],
    this.pollVotes = const {},
    this.myPollVote,
    this.fileName,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String body;
  final DateTime timestamp;
  final TimelineEventKind kind;
  final String? threadRootId;
  final bool isPinned;
  final List<String> pollOptions;
  final Map<String, int> pollVotes;
  final String? myPollVote;
  final String? fileName;

  TimelineEvent copyWith({
    bool? isPinned,
    Map<String, int>? pollVotes,
    String? myPollVote,
  }) {
    return TimelineEvent(
      id: id,
      roomId: roomId,
      senderId: senderId,
      body: body,
      timestamp: timestamp,
      kind: kind,
      threadRootId: threadRootId,
      isPinned: isPinned ?? this.isPinned,
      pollOptions: pollOptions,
      pollVotes: pollVotes ?? this.pollVotes,
      myPollVote: myPollVote ?? this.myPollVote,
      fileName: fileName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    roomId,
    senderId,
    body,
    timestamp,
    kind,
    threadRootId,
    isPinned,
    pollOptions,
    pollVotes,
    myPollVote,
    fileName,
  ];
}

class KnockRequest extends Equatable {
  const KnockRequest({
    required this.roomId,
    required this.userId,
    required this.reason,
  });

  final String roomId;
  final String userId;
  final String reason;

  @override
  List<Object?> get props => [roomId, userId, reason];
}

class MatrixDevice extends Equatable {
  const MatrixDevice({
    required this.id,
    required this.name,
    required this.lastSeen,
    this.verified = false,
    this.current = false,
  });

  final String id;
  final String name;
  final DateTime lastSeen;
  final bool verified;
  final bool current;

  MatrixDevice copyWith({bool? verified}) {
    return MatrixDevice(
      id: id,
      name: name,
      lastSeen: lastSeen,
      verified: verified ?? this.verified,
      current: current,
    );
  }

  @override
  List<Object?> get props => [id, name, lastSeen, verified, current];
}

class MatrixPreferences extends Equatable {
  const MatrixPreferences({
    this.analyticsEnabled = false,
    this.sendReadReceipts = true,
    this.notificationsEnabled = true,
    this.lockScreenEnabled = false,
    this.secureBackupEnabled = false,
    this.sessionVerified = false,
    this.labsThreads = true,
    this.labsRichText = false,
    this.developerMode = false,
    this.showHiddenEvents = false,
    this.contentScannerEnabled = false,
    this.mediaAutoLoad = true,
    this.locationSharingEnabled = true,
    this.statusMessage = 'Available',
    this.blockedUserIds = const [],
  });

  final bool analyticsEnabled;
  final bool sendReadReceipts;
  final bool notificationsEnabled;
  final bool lockScreenEnabled;
  final bool secureBackupEnabled;
  final bool sessionVerified;
  final bool labsThreads;
  final bool labsRichText;
  final bool developerMode;
  final bool showHiddenEvents;
  final bool contentScannerEnabled;
  final bool mediaAutoLoad;
  final bool locationSharingEnabled;
  final String statusMessage;
  final List<String> blockedUserIds;

  MatrixPreferences copyWith({
    bool? analyticsEnabled,
    bool? sendReadReceipts,
    bool? notificationsEnabled,
    bool? lockScreenEnabled,
    bool? secureBackupEnabled,
    bool? sessionVerified,
    bool? labsThreads,
    bool? labsRichText,
    bool? developerMode,
    bool? showHiddenEvents,
    bool? contentScannerEnabled,
    bool? mediaAutoLoad,
    bool? locationSharingEnabled,
    String? statusMessage,
    List<String>? blockedUserIds,
  }) {
    return MatrixPreferences(
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      sendReadReceipts: sendReadReceipts ?? this.sendReadReceipts,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lockScreenEnabled: lockScreenEnabled ?? this.lockScreenEnabled,
      secureBackupEnabled: secureBackupEnabled ?? this.secureBackupEnabled,
      sessionVerified: sessionVerified ?? this.sessionVerified,
      labsThreads: labsThreads ?? this.labsThreads,
      labsRichText: labsRichText ?? this.labsRichText,
      developerMode: developerMode ?? this.developerMode,
      showHiddenEvents: showHiddenEvents ?? this.showHiddenEvents,
      contentScannerEnabled:
          contentScannerEnabled ?? this.contentScannerEnabled,
      mediaAutoLoad: mediaAutoLoad ?? this.mediaAutoLoad,
      locationSharingEnabled:
          locationSharingEnabled ?? this.locationSharingEnabled,
      statusMessage: statusMessage ?? this.statusMessage,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
    );
  }

  @override
  List<Object?> get props => [
    analyticsEnabled,
    sendReadReceipts,
    notificationsEnabled,
    lockScreenEnabled,
    secureBackupEnabled,
    sessionVerified,
    labsThreads,
    labsRichText,
    developerMode,
    showHiddenEvents,
    contentScannerEnabled,
    mediaAutoLoad,
    locationSharingEnabled,
    statusMessage,
    blockedUserIds,
  ];
}

enum MatrixCallStatus { outgoing, incoming, connecting, connected }

class MatrixCall extends Equatable {
  const MatrixCall({
    required this.roomId,
    required this.callId,
    required this.startedAt,
    this.status = MatrixCallStatus.outgoing,
    this.video = false,
    this.muted = false,
    this.speakerOn = true,
  });

  final String roomId;
  final String callId;
  final DateTime startedAt;
  final MatrixCallStatus status;
  final bool video;
  final bool muted;
  final bool speakerOn;

  MatrixCall copyWith({
    MatrixCallStatus? status,
    bool? video,
    bool? muted,
    bool? speakerOn,
  }) {
    return MatrixCall(
      roomId: roomId,
      callId: callId,
      startedAt: startedAt,
      status: status ?? this.status,
      video: video ?? this.video,
      muted: muted ?? this.muted,
      speakerOn: speakerOn ?? this.speakerOn,
    );
  }

  @override
  List<Object?> get props => [
    roomId,
    callId,
    startedAt,
    status,
    video,
    muted,
    speakerOn,
  ];
}

class MatrixAnnouncement extends Equatable {
  const MatrixAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    this.dismissed = false,
  });

  final String id;
  final String title;
  final String body;
  final bool dismissed;

  MatrixAnnouncement copyWith({bool? dismissed}) {
    return MatrixAnnouncement(
      id: id,
      title: title,
      body: body,
      dismissed: dismissed ?? this.dismissed,
    );
  }

  @override
  List<Object?> get props => [id, title, body, dismissed];
}

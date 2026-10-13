import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

class LivekitParticipant {
  const LivekitParticipant({required this.identity, required this.name});

  final String identity;
  final String name;
}

/// One Element Call session. Tracks are the LiveKit room's own streams.
class LivekitRoomCall {
  LivekitRoomCall({required this.onChanged, this.onRemoteJoined});

  final VoidCallback onChanged;

  /// Fires when someone else enters the LiveKit room, so their client can
  /// receive this device's media key without waiting for the heartbeat.
  final VoidCallback? onRemoteJoined;
  lk.Room? _room;
  lk.BaseKeyProvider? _keys;
  lk.EventsListener<lk.RoomEvent>? _events;
  Uint8List? _localMediaKey;
  final Map<String, ({Uint8List key, int index})> _keysByIdentity = {};
  var _disposed = false;

  /// This device's media key. Null when the call is not encrypted.
  Uint8List? get localMediaKey => _localMediaKey;

  List<String> get remoteIdentities =>
      _room?.remoteParticipants.keys.toList(growable: false) ?? const [];

  MediaStream? local;
  lk.VideoTrack? localCamera;
  final Map<String, MediaStream> remotes = {};
  final Map<String, lk.VideoTrack> cameras = {};
  final Map<String, MediaStream> _owned = {};
  List<LivekitParticipant> participants = const [];
  var _refreshTicket = 0;

  lk.VideoTrack? get remoteCamera {
    for (final track in cameras.values) {
      if (!track.muted) {
        return track;
      }
    }
    for (final track in cameras.values) {
      return track;
    }
    return null;
  }

  lk.VideoTrack? cameraFor(String identity) => cameras[identity];

  Future<void> connect({
    required String url,
    required String token,
    required bool video,
    required bool encrypt,
    required String identity,
  }) async {
    await lk.LiveKitClient.initialize();
    // A normal call just plays the remote stream. Adaptive stream pauses a
    // room camera when the video view has no size, which is what a phone
    // browser reports, so the web camera never starts.
    // One VP8 layer at 540p. Three portrait simulcast layers overload this
    // phone's software encoder, and Element Call then receives packets it
    // cannot decode.
    lk.BaseKeyProvider? keys;
    lk.E2EEOptions? encryption;
    if (encrypt) {
      keys = await _elementCallKeys();
      final raw = Uint8List.fromList(
        List<int>.generate(32, (_) => Random.secure().nextInt(256)),
      );
      await keys.setRawKey(raw, participantId: identity, keyIndex: 0);
      _keys = keys;
      _localMediaKey = raw;
      _keysByIdentity[identity] = (key: raw, index: 0);
      encryption = lk.E2EEOptions(keyProvider: keys);
    }
    final options = _roomOptions(encryption);
    final room = lk.Room(roomOptions: options);
    _room = room;
    _events = room.createListener()
      ..on<lk.TrackSubscribedEvent>((event) {
        unawaited(_rebind(event.participant.identity));
        _refresh();
      })
      ..on<lk.TrackUnsubscribedEvent>((_) => _refresh())
      ..on<lk.TrackMutedEvent>((_) => _refresh())
      ..on<lk.TrackUnmutedEvent>((_) => _refresh())
      ..on<lk.TrackPublishedEvent>((_) => _refresh())
      ..on<lk.TrackStreamStateUpdatedEvent>((_) => _refresh())
      ..on<lk.LocalTrackPublishedEvent>((event) {
        unawaited(_rebind(event.participant.identity));
        _refresh();
      })
      ..on<lk.LocalTrackUnpublishedEvent>((_) => _refresh())
      ..on<lk.ParticipantConnectedEvent>((event) {
        unawaited(_rebind(event.participant.identity));
        onRemoteJoined?.call();
        _refresh();
      })
      ..on<lk.ParticipantDisconnectedEvent>((_) => _refresh());
    await room.connect(url, token);
    final actual = room.localParticipant?.identity;
    if (keys != null &&
        _localMediaKey != null &&
        actual != null &&
        actual.isNotEmpty) {
      await keys.setRawKey(_localMediaKey!, participantId: actual, keyIndex: 0);
      _keysByIdentity[actual] = (key: _localMediaKey!, index: 0);
      await room.e2eeManager?.setKeyIndex(0, participantIdentity: actual);
    }
    await _publishLocalMedia(video: video);
    _refresh();
  }

  /// Shared capture and publish settings. Opus DTX is off because an
  /// encrypted silence gap leaves the other decoder muted.
  lk.RoomOptions _roomOptions(lk.E2EEOptions? encryption) {
    return lk.RoomOptions(
      adaptiveStream: false,
      dynacast: false,
      e2eeOptions: encryption,
      defaultAudioPublishOptions: const lk.AudioPublishOptions(dtx: false),
      defaultVideoPublishOptions: const lk.VideoPublishOptions(
        videoCodec: 'vp8',
        simulcast: false,
        backupVideoCodec: lk.BackupVideoCodec(codec: 'vp8', simulcast: false),
      ),
      defaultCameraCaptureOptions: const lk.CameraCaptureOptions(
        params: lk.VideoParametersPresets.h540_169,
      ),
    );
  }

  Future<void> _publishLocalMedia({required bool video}) async {
    final participant = _room?.localParticipant;
    await participant?.setMicrophoneEnabled(true);
    if (video) {
      await participant?.setCameraEnabled(true);
    }
  }

  /// Element Call derives AES-128 with HKDF. LiveKit's default provider
  /// leaves PBKDF2, so the other client's frames fail to decrypt.
  Future<lk.BaseKeyProvider> _elementCallKeys() async {
    final options = KeyProviderOptions(
      sharedKey: false,
      ratchetSalt: Uint8List.fromList('LKFrameEncryptionKey'.codeUnits),
      uncryptedMagicBytes: Uint8List.fromList('LK-ROCKS'.codeUnits),
      ratchetWindowSize: 10,
      keyRingSize: 255,
      keyDerivationAlgorithm: KeyDerivationAlgorithm.kHKDF,
    );
    final provider = await frameCryptorFactory.createDefaultKeyProvider(
      options,
    );
    return lk.BaseKeyProvider(provider, options);
  }

  /// Install a key after the frame cryptor for [identity] exists.
  Future<void> _rebind(String identity) async {
    await Future<void>.delayed(Duration.zero);
    if (_disposed || identity.isEmpty) {
      return;
    }
    final known = _keysByIdentity[identity];
    if (known != null) {
      await _installKey(identity, known.key, known.index);
      return;
    }
    final localId = _room?.localParticipant?.identity;
    final localKey = _localMediaKey;
    if (identity == localId && localKey != null) {
      await _installKey(identity, localKey, 0);
    }
  }

  Future<void> _installKey(String identity, Uint8List key, int index) async {
    final keys = _keys;
    if (keys == null || _disposed || identity.isEmpty || key.isEmpty) {
      return;
    }
    await keys.setRawKey(key, participantId: identity, keyIndex: index);
    await _room?.e2eeManager?.setKeyIndex(index, participantIdentity: identity);
  }

  /// Install another participant's media key so their camera can be decoded.
  Future<void> setParticipantKey(
    String identity,
    Uint8List key,
    int index,
  ) async {
    if (_keys == null || identity.isEmpty || key.isEmpty) {
      return;
    }
    final copy = Uint8List.fromList(key);
    _keysByIdentity[identity] = (key: copy, index: index);
    await _installKey(identity, copy, index);
  }

  Future<void> setMuted(bool muted) async {
    await _room?.localParticipant?.setMicrophoneEnabled(!muted);
  }

  Future<void> setVideo(bool enabled) async {
    await _room?.localParticipant?.setCameraEnabled(enabled);
    _refresh();
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _refreshTicket++;
    await _events?.dispose();
    _events = null;
    final room = _room;
    _room = null;
    _keys = null;
    _localMediaKey = null;
    try {
      await room?.disconnect();
    } catch (_) {}
    await room?.dispose();
    for (final stream in _owned.values) {
      try {
        await stream.dispose();
      } catch (_) {}
    }
    _owned.clear();
  }

  void _refresh() {
    final ticket = ++_refreshTicket;
    unawaited(_apply(ticket));
  }

  Future<void> _apply(int ticket) async {
    if (_disposed || ticket != _refreshTicket) {
      return;
    }
    final localParticipant = _room?.localParticipant;
    localCamera = _camera(localParticipant);
    local = await _sessionStream(
      camera: localCamera,
      participant: localParticipant,
      key: 'local',
    );
    if (_disposed || ticket != _refreshTicket) {
      return;
    }
    final next = <String, MediaStream>{};
    final nextCameras = <String, lk.VideoTrack>{};
    final people = <LivekitParticipant>[];
    final remotePeople = _room?.remoteParticipants.values;
    for (final participant in remotePeople ?? <lk.RemoteParticipant>[]) {
      if (_disposed || ticket != _refreshTicket) {
        return;
      }
      final camera = _camera(participant);
      final stream = await _sessionStream(
        camera: camera,
        participant: participant,
        key: participant.identity,
      );
      if (camera != null) {
        nextCameras[participant.identity] = camera;
      }
      if (stream != null) {
        next[participant.identity] = stream;
      }
      people.add(
        LivekitParticipant(
          identity: participant.identity,
          name: participant.name,
        ),
      );
    }
    remotes
      ..clear()
      ..addAll(next);
    cameras
      ..clear()
      ..addAll(nextCameras);
    participants = people;
    onChanged();
  }

  lk.VideoTrack? _camera(lk.Participant? participant) {
    if (participant == null) {
      return null;
    }
    lk.VideoTrack? mutedCamera;
    lk.VideoTrack? fallback;
    for (final publication in participant.videoTrackPublications) {
      if (publication is lk.RemoteTrackPublication) {
        if (!publication.subscribed) {
          unawaited(publication.subscribe());
        } else {
          unawaited(publication.enable());
        }
      }
      final track = publication.track;
      if (track is! lk.VideoTrack) {
        continue;
      }
      track.mediaStreamTrack.enabled = true;
      final camera = publication.source == lk.TrackSource.camera;
      if (publication.muted) {
        if (camera) {
          mutedCamera ??= track;
        }
        continue;
      }
      if (camera) {
        return track;
      }
      fallback ??= track;
    }
    return fallback ?? mutedCamera;
  }

  /// Camera plus microphone. A video-only stream would drop the other
  /// person's voice whenever their camera is on.
  Future<MediaStream?> _sessionStream({
    required lk.VideoTrack? camera,
    required lk.Participant? participant,
    required String key,
  }) async {
    final video = await _displayStream(camera, key);
    final audio = _audioTrack(participant);
    if (video == null) {
      return audio?.mediaStream;
    }
    if (audio == null) {
      return video;
    }
    return _attachAudio(video, audio.mediaStreamTrack, key);
  }

  /// Subscribes remote microphones the same way cameras are subscribed.
  /// A muted publication stays muted so [setMuted] still owns the local mic.
  lk.Track? _audioTrack(lk.Participant? participant) {
    if (participant == null) {
      return null;
    }
    for (final publication in participant.audioTrackPublications) {
      if (publication is lk.RemoteTrackPublication) {
        if (!publication.subscribed) {
          unawaited(publication.subscribe());
        } else {
          unawaited(publication.enable());
        }
      }
      final track = publication.track;
      if (track == null) {
        continue;
      }
      if (!publication.muted) {
        track.mediaStreamTrack.enabled = true;
      }
      return track;
    }
    return null;
  }

  Future<MediaStream> _attachAudio(
    MediaStream video,
    MediaStreamTrack audio,
    String key,
  ) async {
    if (video.getAudioTracks().any((item) => item.id == audio.id)) {
      return video;
    }
    try {
      await video.addTrack(audio);
      if (video.getAudioTracks().any((item) => item.id == audio.id)) {
        return video;
      }
    } catch (_) {}
    try {
      final stream = _owned[key] ??= await createLocalMediaStream('lk-$key');
      for (final item in video.getVideoTracks()) {
        final present = stream.getVideoTracks().any(
          (existing) => existing.id == item.id,
        );
        if (!present) {
          await stream.addTrack(item);
        }
      }
      final present = stream.getAudioTracks().any(
        (item) => item.id == audio.id,
      );
      if (!present) {
        for (final old in List<MediaStreamTrack>.of(stream.getAudioTracks())) {
          await stream.removeTrack(old);
        }
        await stream.addTrack(audio);
      }
      if (stream.getAudioTracks().isNotEmpty) {
        return stream;
      }
    } catch (_) {}
    return video;
  }

  /// A browser camera often arrives as a track whose LiveKit stream lists no
  /// video. A normal call adds that track to the stream the view plays.
  Future<MediaStream?> _displayStream(lk.VideoTrack? video, String key) async {
    if (video == null) {
      return null;
    }
    final track = video.mediaStreamTrack;
    track.enabled = true;
    final current = video.mediaStream;
    if (current.getVideoTracks().any((item) => item.id == track.id)) {
      return current;
    }
    try {
      await current.addTrack(track);
      if (current.getVideoTracks().isNotEmpty) {
        return current;
      }
    } catch (_) {}
    try {
      final stream = _owned[key] ??= await createLocalMediaStream('lk-$key');
      final present = stream.getVideoTracks().any(
        (item) => item.id == track.id,
      );
      if (!present) {
        for (final old in List<MediaStreamTrack>.of(stream.getVideoTracks())) {
          await stream.removeTrack(old);
        }
        await stream.addTrack(track);
      }
      if (stream.getVideoTracks().isNotEmpty) {
        return stream;
      }
    } catch (_) {}
    return current;
  }
}

import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Local WebRTC media for one Matrix `m.call` session.
class MatrixCallMedia {
  MatrixCallMedia({List<Map<String, dynamic>>? iceServers})
    : _iceServers = iceServers ?? _defaultIceServers;

  static const defaultIceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
  ];

  static const _defaultIceServers = defaultIceServers;

  final List<Map<String, dynamic>> _iceServers;

  RTCPeerConnection? _connection;
  MediaStream? _local;
  MediaStream? _remote;
  MediaStream? _upgradeCapture;
  var _hasRemoteDescription = false;
  Future<void>? _bindChain;
  final List<RTCIceCandidate> _pendingRemote = [];

  /// Fires when the local or remote stream is attached.
  void Function()? onStreamsChanged;

  /// Fires when the peer connection state changes.
  void Function(RTCPeerConnectionState state)? onConnectionState;

  /// Fires when ICE connectivity changes.
  void Function(RTCIceConnectionState state)? onIceConnectionState;

  MediaStream? get local => _local;
  MediaStream? get remote => _remote;

  RTCPeerConnectionState? connectionState;
  RTCIceConnectionState? iceConnectionState;

  bool get isConnected =>
      connectionState == RTCPeerConnectionState.RTCPeerConnectionStateConnected;

  Future<String> offer({
    required bool video,
    required void Function(RTCIceCandidate candidate) onCandidate,
  }) async {
    await _open(video: video, onCandidate: onCandidate);
    final description = await _connection!.createOffer();
    return _commitLocal(
      _connection!,
      description,
      'Could not create a call offer',
    );
  }

  Future<String> answer({
    required String offerSdp,
    required bool video,
    required void Function(RTCIceCandidate candidate) onCandidate,
  }) async {
    await _open(video: video, onCandidate: onCandidate, attachLocal: false);
    await _connection!.setRemoteDescription(
      RTCSessionDescription(offerSdp, 'offer'),
    );
    _hasRemoteDescription = true;
    await _flushPendingRemote();
    await _attachLocalTracks();
    final description = await _connection!.createAnswer();
    return _commitLocal(
      _connection!,
      description,
      'Could not create a call answer',
    );
  }

  Future<void> acceptAnswer(String sdp) async {
    await _connection?.setRemoteDescription(
      RTCSessionDescription(sdp, 'answer'),
    );
    _hasRemoteDescription = true;
    await _flushPendingRemote();
  }

  /// Applies a renegotiation offer from `m.call.negotiate` and returns the answer SDP.
  Future<String> answerNegotiate(String offerSdp) async {
    final connection = _connection;
    if (connection == null) {
      throw Exception('There is no call to renegotiate');
    }
    await connection.setRemoteDescription(
      RTCSessionDescription(offerSdp, 'offer'),
    );
    _hasRemoteDescription = true;
    await _flushPendingRemote();
    if (_sdpHasVideo(offerSdp)) {
      await _ensureLocalVideo();
    }
    await _attachLocalTracks();
    final description = await connection.createAnswer();
    return _commitLocal(
      connection,
      description,
      'Could not renegotiate the call',
    );
  }

  /// Restarts ICE and returns a new offer SDP for `m.call.negotiate`.
  Future<String> restartIce() async {
    final connection = _connection;
    if (connection == null) {
      throw Exception('There is no call to restart');
    }
    await connection.restartIce();
    final description = await connection.createOffer({'iceRestart': true});
    return _commitLocal(connection, description, 'Could not restart the call');
  }

  Future<void> addCandidate(RTCIceCandidate candidate) async {
    final safe = _safeCandidate(candidate);
    if (safe == null) {
      return;
    }
    final connection = _connection;
    if (connection == null || !_hasRemoteDescription) {
      _pendingRemote.add(safe);
      return;
    }
    await _applyCandidate(connection, safe);
  }

  void setMuted(bool muted) {
    for (final track
        in _local?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
  }

  void setVideoEnabled(bool enabled) {
    for (final track
        in _local?.getVideoTracks() ?? const <MediaStreamTrack>[]) {
      track.enabled = enabled;
    }
  }

  Future<void> setSpeaker(bool enabled) async {
    try {
      await Helper.setSpeakerphoneOn(enabled);
    } catch (_) {}
  }

  Future<void> dispose() async {
    onStreamsChanged = null;
    onConnectionState = null;
    onIceConnectionState = null;
    _bindChain = null;
    _pendingRemote.clear();
    for (final track in _local?.getTracks() ?? const <MediaStreamTrack>[]) {
      await track.stop();
    }
    await _local?.dispose();
    await _upgradeCapture?.dispose();
    _upgradeCapture = null;
    await _remote?.dispose();
    await _connection?.close();
    _connection = null;
    _local = null;
    _remote = null;
    _hasRemoteDescription = false;
    connectionState = null;
    iceConnectionState = null;
  }

  Future<void> _open({
    required bool video,
    required void Function(RTCIceCandidate candidate) onCandidate,
    bool attachLocal = true,
  }) async {
    _local = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video,
    });
    _connection = await createPeerConnection({
      'iceServers': _iceServers,
      'sdpSemantics': 'unified-plan',
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
    });
    _connection!.onIceCandidate = (candidate) {
      final safe = _safeCandidate(candidate);
      if (safe != null) {
        onCandidate(safe);
      }
    };
    _connection!.onConnectionState = (state) {
      connectionState = state;
      onConnectionState?.call(state);
    };
    _connection!.onIceConnectionState = (state) {
      iceConnectionState = state;
      onIceConnectionState?.call(state);
    };
    _connection!.onTrack = _enqueueRemoteTrack;
    onStreamsChanged?.call();
    if (!attachLocal) {
      return;
    }
    for (final track in _local!.getTracks()) {
      await _connection!.addTrack(track, _local!);
    }
  }

  /// Opens the camera when a renegotiation adds video to a voice answer.
  Future<void> _ensureLocalVideo() async {
    final local = _local;
    if (local == null || local.getVideoTracks().isNotEmpty) {
      return;
    }
    final captured = await navigator.mediaDevices.getUserMedia({
      'audio': false,
      'video': true,
    });
    if (_connection == null) {
      for (final track in captured.getTracks()) {
        await track.stop();
      }
      await captured.dispose();
      return;
    }
    _upgradeCapture = captured;
    for (final track in captured.getVideoTracks()) {
      track.enabled = true;
      await local.addTrack(track);
    }
    onStreamsChanged?.call();
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

  /// Puts local mic and camera on the offer's transceivers.
  ///
  /// Adding tracks before [RTCPeerConnection.setRemoteDescription] creates
  /// extra transceivers. Chrome's video m-line then gets answered send-only,
  /// so this device sends a picture and never receives one.
  ///
  /// [RTCRtpSender.replaceTrack] does not set a stream id. Without
  /// [RTCRtpSender.setStreams], the answer has no `a=msid` and Element Web
  /// drops the camera because `ontrack` arrives with an empty stream list.
  Future<void> _attachLocalTracks() async {
    final connection = _connection;
    final local = _local;
    if (connection == null || local == null) {
      return;
    }
    final transceivers = await connection.getTransceivers();
    final used = <MediaStreamTrack>{};
    for (final transceiver in transceivers) {
      if (transceiver.stoped) {
        continue;
      }
      final kind = _mediaKind(transceiver);
      final localTrack = kind == null ? null : _unusedLocalTrack(kind, used);
      if (localTrack == null) {
        continue;
      }
      final senderTrack = transceiver.sender.track;
      if (_sameTrack(senderTrack, localTrack)) {
        await transceiver.sender.setStreams([local]);
        used.add(localTrack);
        continue;
      }
      if (senderTrack != null) {
        continue;
      }
      await transceiver.sender.replaceTrack(localTrack);
      await transceiver.sender.setStreams([local]);
      await transceiver.setDirection(TransceiverDirection.SendRecv);
      used.add(localTrack);
    }
  }

  String? _mediaKind(RTCRtpTransceiver transceiver) {
    return _trackKind(transceiver.receiver.track) ??
        _trackKind(transceiver.sender.track);
  }

  String? _trackKind(MediaStreamTrack? track) {
    final kind = track?.kind;
    if (kind == 'audio' || kind == 'video') {
      return kind;
    }
    return null;
  }

  MediaStreamTrack? _unusedLocalTrack(String kind, Set<MediaStreamTrack> used) {
    final tracks = kind == 'video'
        ? _local?.getVideoTracks() ?? const <MediaStreamTrack>[]
        : _local?.getAudioTracks() ?? const <MediaStreamTrack>[];
    for (final track in tracks) {
      if (!used.contains(track)) {
        return track;
      }
    }
    return null;
  }

  bool _sameTrack(MediaStreamTrack? left, MediaStreamTrack right) {
    final id = right.id;
    return left != null && id != null && left.id == id;
  }

  void _enqueueRemoteTrack(RTCTrackEvent event) {
    final previous = _bindChain ?? Future<void>.value();
    _bindChain = previous.catchError((Object _) {}).then((_) async {
      try {
        await _bindRemoteTrack(event);
      } catch (_) {}
    });
  }

  /// Keeps the remote camera even when Chrome delivers it without a stream.
  ///
  /// `onTrack` fires once per track. Taking `streams.first` lets a later
  /// audio-only event replace the video, and a streamless video track is
  /// ignored. Audio still plays through the peer connection; video does not.
  Future<void> _bindRemoteTrack(RTCTrackEvent event) async {
    if (_connection == null) {
      return;
    }
    final track = event.track;
    final kind = _trackKind(track);
    if (kind == 'video') {
      track.enabled = true;
      if (_remote?.getVideoTracks().isNotEmpty ?? false) {
        onStreamsChanged?.call();
        return;
      }
      final streamed = _streamWithVideo(event.streams);
      if (streamed != null) {
        await _adoptRemoteVideoStream(streamed, event.streams);
      } else {
        await _addRemoteTrack(track);
      }
    } else if (kind == 'audio') {
      await _addRemoteTrack(track);
    } else {
      return;
    }
    if (_connection == null) {
      return;
    }
    onStreamsChanged?.call();
  }

  MediaStream? _streamWithVideo(List<MediaStream> streams) {
    for (final stream in streams) {
      if (stream.getVideoTracks().isNotEmpty) {
        return stream;
      }
    }
    return null;
  }

  Future<void> _adoptRemoteVideoStream(
    MediaStream stream,
    List<MediaStream> streams,
  ) async {
    final previous = _remote;
    if (previous != null && !identical(previous, stream)) {
      for (final audio in previous.getAudioTracks()) {
        await _addTrackIfMissing(stream, audio);
      }
    }
    for (final source in streams) {
      for (final audio in source.getAudioTracks()) {
        await _addTrackIfMissing(stream, audio);
      }
    }
    _remote = stream;
  }

  Future<void> _addRemoteTrack(MediaStreamTrack track) async {
    final stream = _remote ?? await createLocalMediaStream('remote');
    if (_connection == null) {
      return;
    }
    _remote = stream;
    await _addTrackIfMissing(stream, track);
  }

  Future<void> _addTrackIfMissing(
    MediaStream stream,
    MediaStreamTrack track,
  ) async {
    final existing = track.kind == 'video'
        ? stream.getVideoTracks()
        : stream.getAudioTracks();
    if (track.kind == 'video' && existing.isNotEmpty) {
      return;
    }
    final id = track.id;
    if (id != null && existing.any((item) => item.id == id)) {
      return;
    }
    try {
      await stream.addTrack(track);
    } catch (_) {}
  }

  Future<void> _flushPendingRemote() async {
    final connection = _connection;
    if (connection == null) {
      return;
    }
    final pending = List<RTCIceCandidate>.of(_pendingRemote);
    _pendingRemote.clear();
    for (final candidate in pending) {
      await _applyCandidate(connection, candidate);
    }
  }

  /// Drops end-of-candidates, loopback addresses, and fills null mid/index.
  ///
  /// Android `addIceCandidate` calls `String.getBytes()` on `sdpMid`. A null
  /// mid is a native abort, not a Dart exception. Loopback candidates never
  /// reach the other device and keep ICE retrying on `lo`.
  static RTCIceCandidate? _safeCandidate(RTCIceCandidate candidate) {
    final line = candidate.candidate;
    if (line == null || line.isEmpty || _isLoopback(line)) {
      return null;
    }
    final mid = candidate.sdpMid;
    final index = candidate.sdpMLineIndex;
    if (mid != null && index != null) {
      return candidate;
    }
    return RTCIceCandidate(line, mid ?? '', index ?? 0);
  }

  static bool _isLoopback(String line) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 5) {
      return false;
    }
    final address = parts[4];
    return address == '127.0.0.1' ||
        address == '::1' ||
        address == '0:0:0:0:0:0:0:1';
  }

  Future<void> _applyCandidate(
    RTCPeerConnection connection,
    RTCIceCandidate candidate,
  ) async {
    try {
      await connection.addCandidate(candidate);
    } catch (_) {}
  }

  String _requireSdp(String? sdp, String message) {
    if (sdp == null || sdp.isEmpty) {
      throw Exception(message);
    }
    return sdp;
  }

  /// Applies [description] locally and returns the SDP sent to the other client.
  ///
  /// VP8 is moved to the front of each video m-line first. This phone's
  /// hardware H.264 decoder discards Chrome's stream, so the remote picture
  /// stays black unless Element Web sends VP8.
  Future<String> _commitLocal(
    RTCPeerConnection connection,
    RTCSessionDescription description,
    String message,
  ) async {
    final sdp = _preferVp8(_requireSdp(description.sdp, message));
    await connection.setLocalDescription(
      RTCSessionDescription(sdp, description.type),
    );
    return sdp;
  }

  static final _vp8Payload = RegExp(
    r'^a=rtpmap:(\d+)\s+VP8/90000',
    caseSensitive: false,
  );

  static String _preferVp8(String sdp) {
    final lines = sdp.split(RegExp(r'\r?\n'));
    final vp8 = <String>{};
    for (final line in lines) {
      final match = _vp8Payload.firstMatch(line.trim());
      if (match != null) {
        vp8.add(match.group(1)!);
      }
    }
    if (vp8.isEmpty) {
      return sdp;
    }
    final newline = sdp.contains('\r\n') ? '\r\n' : '\n';
    final rewritten = <String>[
      for (final line in lines)
        if (line.trim().startsWith('m=video '))
          _movePayloadsFirst(line.trim(), vp8)
        else if (line.isNotEmpty)
          line,
    ];
    return '${rewritten.join(newline)}$newline';
  }

  static String _movePayloadsFirst(String mLine, Set<String> preferred) {
    final parts = mLine.split(' ');
    if (parts.length <= 3) {
      return mLine;
    }
    final front = <String>[];
    final rest = <String>[];
    for (final payload in parts.sublist(3)) {
      if (preferred.contains(payload)) {
        front.add(payload);
      } else {
        rest.add(payload);
      }
    }
    return [...parts.sublist(0, 3), ...front, ...rest].join(' ');
  }
}

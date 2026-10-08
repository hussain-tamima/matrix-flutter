import 'dart:async';

import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/call/cubit/call_cubit.dart';
import 'package:element_x/theme/app_theme.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _remote = RTCVideoRenderer();
  final _local = RTCVideoRenderer();
  var _renderersReady = false;
  String? _remoteVideoTrackId;
  var _remoteBindSerial = 0;

  @override
  void initState() {
    super.initState();
    _remote.onResize = _onRemoteResize;
    _initRenderers();
  }

  void _onRemoteResize() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initRenderers() async {
    try {
      await _remote.initialize();
      await _local.initialize();
    } catch (error) {
      if (mounted) {
        context.read<CallCubit>().reportMediaError(error);
      }
    }
    if (mounted) {
      setState(() => _renderersReady = true);
    }
  }

  @override
  void dispose() {
    _remote.onResize = null;
    _remote.srcObject = null;
    _local.srcObject = null;
    _remote.dispose();
    _local.dispose();
    super.dispose();
  }

  void _attach(CallCubit cubit) {
    if (!_renderersReady) {
      return;
    }
    _local.srcObject = cubit.localStream;
    _scheduleRemoteVideo(cubit.remoteStream);
  }

  /// Binds the remote camera before [RTCVideoView] builds.
  ///
  /// The view decides Texture vs empty box once, from `srcObject` at the first
  /// build. A post-frame bind leaves that child empty for the rest of the call.
  void _scheduleRemoteVideo(MediaStream? stream) {
    final track = _remoteVideoTrack(stream);
    final trackId = track?.id;
    if (track == null || trackId == null) {
      if (_remoteVideoTrackId != null) {
        _remoteVideoTrackId = null;
        _remoteBindSerial++;
        _remote.srcObject = null;
      }
      return;
    }
    track.enabled = true;
    if (_remoteVideoTrackId == trackId) {
      return;
    }
    final previous = _remoteVideoTrackId;
    _remoteVideoTrackId = trackId;
    if (previous == null) {
      unawaited(_bindRemoteVideo(stream, trackId));
      return;
    }
    final serial = ++_remoteBindSerial;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || serial != _remoteBindSerial) {
        return;
      }
      try {
        await _remote.setSrcObject(stream: null);
        if (!mounted || serial != _remoteBindSerial) {
          return;
        }
        await _remote.setSrcObject(stream: stream, trackId: trackId);
      } catch (_) {}
      if (mounted && serial == _remoteBindSerial) {
        setState(() {});
      }
    });
  }

  Future<void> _bindRemoteVideo(MediaStream? stream, String trackId) async {
    try {
      await _remote.setSrcObject(stream: stream, trackId: trackId);
    } catch (_) {}
  }

  MediaStreamTrack? _remoteVideoTrack(MediaStream? stream) {
    final tracks = stream?.getVideoTracks() ?? const <MediaStreamTrack>[];
    if (tracks.isEmpty) {
      return null;
    }
    return tracks.first;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CallCubit>();
    final state = cubit.state;
    final call = state.call;
    final rop = RopTheme.of(context);
    _attach(cubit);
    if (call == null) {
      final failure = state.error;
      if (failure == null) {
        return Scaffold(body: Center(child: Text('no_call'.tr())));
      }
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(failure, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: cubit.dismissFailure,
                  child: Text('close'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        if (call.status == MatrixCallStatus.incoming) {
          cubit.reject();
          return;
        }
        cubit.end();
      },
      child: Scaffold(
        backgroundColor: rop.railEnd,
        appBar: AppBar(
          backgroundColor: rop.railEnd,
          title: Text(state.roomName),
        ),
        body: Column(
          children: [
            Expanded(child: _stage(context, cubit, state, call)),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  state.error!,
                  style: TextStyle(color: rop.critical),
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: call.status == MatrixCallStatus.incoming
                    ? _incomingActions(cubit, state)
                    : _liveActions(context, cubit, call),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stage(
    BuildContext context,
    CallCubit cubit,
    CallState state,
    MatrixCall call,
  ) {
    final showRemote =
        _renderersReady && _remoteVideoTrack(cubit.remoteStream) != null;
    final showLocal =
        call.video &&
        call.status != MatrixCallStatus.incoming &&
        _renderersReady;
    final label = switch (call.status) {
      MatrixCallStatus.incoming =>
        (call.video ? 'incoming_video_call' : 'incoming_voice_call').tr(),
      MatrixCallStatus.outgoing => 'call_status_calling'.tr(),
      MatrixCallStatus.connecting => 'call_status_connecting'.tr(),
      MatrixCallStatus.connected =>
        (call.muted ? 'call_status_muted' : 'call_status_connected').tr(),
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        if (showRemote)
          RTCVideoView(
            _remote,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          )
        else
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  call.video ? Icons.videocam : Icons.call,
                  size: 72,
                  color: RopTheme.of(context).railText,
                ),
                const SizedBox(height: 12),
                Text(
                  state.roomName,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: RopTheme.of(context).textOnPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(color: RopTheme.of(context).railText),
                ),
              ],
            ),
          ),
        if (showLocal)
          Positioned(
            top: 16,
            right: 16,
            width: 112,
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RTCVideoView(
                _local,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ),
      ],
    );
  }

  Widget _incomingActions(CallCubit cubit, CallState state) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: RopTheme.of(context).criticalButton,
            ),
            onPressed: state.answering ? null : cubit.reject,
            icon: const Icon(Icons.call_end),
            label: Text('decline'.tr()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.online),
            onPressed: state.answering ? null : cubit.answer,
            icon: state.answering
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.call),
            label: Text('answer'.tr()),
          ),
        ),
      ],
    );
  }

  Widget _liveActions(BuildContext context, CallCubit cubit, MatrixCall call) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton.filled(
          tooltip: 'mute'.tr(),
          onPressed: () => cubit.setMuted(!call.muted),
          icon: Icon(call.muted ? Icons.mic_off : Icons.mic),
        ),
        IconButton.filled(
          tooltip: 'video'.tr(),
          onPressed: () => cubit.setVideo(!call.video),
          icon: Icon(call.video ? Icons.videocam : Icons.videocam_off),
        ),
        IconButton.filled(
          tooltip: 'speaker'.tr(),
          onPressed: () => cubit.setSpeaker(!call.speakerOn),
          icon: Icon(call.speakerOn ? Icons.volume_up : Icons.hearing),
        ),
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: RopTheme.of(context).criticalButton,
            foregroundColor: RopTheme.of(context).textOnPrimary,
          ),
          tooltip: 'hang_up'.tr(),
          onPressed: cubit.end,
          icon: const Icon(Icons.call_end),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'dart:ui';

import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/call/cubit/call_cubit.dart';
import 'package:element_x/theme/app_theme.dart';
import 'package:element_x/theme/rop_spacing.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// In-app call UI. Calls open full screen; minimize shrinks them to a bar or PiP.
class CallOverlay extends StatefulWidget {
  const CallOverlay({super.key});

  @override
  State<CallOverlay> createState() => _CallOverlayState();
}

class _CallOverlayState extends State<CallOverlay> with WidgetsBindingObserver {
  final _remote = RTCVideoRenderer();
  final _local = RTCVideoRenderer();
  var _renderersReady = false;
  String? _remoteVideoTrackId;
  var _remoteBindSerial = 0;
  var _minimized = false;
  Timer? _clock;
  var _handleSystemBack = true;
  VoidCallback? _onSystemBack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    _remote.onResize = null;
    _remote.srcObject = null;
    _local.srcObject = null;
    _remote.dispose();
    _local.dispose();
    super.dispose();
  }

  /// The overlay sits above the navigator, so [PopScope] cannot see the route.
  /// Consume system back here while the call is full screen.
  @override
  Future<bool> didPopRoute() async {
    if (!_handleSystemBack) {
      return false;
    }
    _onSystemBack?.call();
    return true;
  }

  void _attach(CallCubit cubit) {
    if (!_renderersReady) {
      return;
    }
    _local.srcObject = cubit.localStream;
    _scheduleRemoteVideo(cubit.remoteStream);
  }

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

  void _syncClock(MatrixCall call) {
    final live = call.status == MatrixCallStatus.connected;
    if (live && _clock == null) {
      _clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {});
        }
      });
    } else if (!live && _clock != null) {
      _clock?.cancel();
      _clock = null;
    }
  }

  void _minimize() {
    if (_minimized) {
      return;
    }
    setState(() => _minimized = true);
  }

  void _expand() {
    if (!_minimized) {
      return;
    }
    setState(() => _minimized = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CallCubit, CallState>(
      builder: (context, state) {
        final call = state.call;
        if (call == null) {
          return const SizedBox.shrink();
        }
        final cubit = context.read<CallCubit>();
        _attach(cubit);
        _syncClock(call);

        final incoming = call.status == MatrixCallStatus.incoming;
        final fullscreen = incoming || !_minimized;
        _handleSystemBack = fullscreen;
        _onSystemBack = () {
          if (incoming) {
            cubit.reject();
            return;
          }
          _minimize();
        };

        return PopScope(
          canPop: !fullscreen,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop || !_handleSystemBack) {
              return;
            }
            _onSystemBack?.call();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (incoming)
                _incomingScreen(context, cubit, state, call)
              else if (_minimized)
                _minimizedCall(context, cubit, state, call)
              else
                _fullScreen(context, cubit, state, call),
            ],
          ),
        );
      },
    );
  }

  bool _hasRemoteVideo(CallCubit cubit) {
    return _remoteVideoTrack(cubit.remoteStream) != null;
  }

  Widget _incomingScreen(
    BuildContext context,
    CallCubit cubit,
    CallState state,
    MatrixCall call,
  ) {
    final rop = RopTheme.of(context);
    final subtitle = call.video
        ? 'incoming_video_call'.tr()
        : 'incoming_voice_call'.tr();

    return Positioned.fill(
      child: ColoredBox(
        color: rop.railEnd,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              RopSpacing.lg,
              RopSpacing.xl,
              RopSpacing.lg,
              RopSpacing.lg,
            ),
            child: Column(
              children: [
                const Spacer(),
                _avatar(call, rop, radius: 56),
                const SizedBox(height: RopSpacing.lg),
                Text(
                  state.roomName,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: rop.textOnPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: RopSpacing.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: rop.railText),
                  textAlign: TextAlign.center,
                ),
                if (state.error != null) ...[
                  const SizedBox(height: RopSpacing.sm),
                  Text(
                    state.error!,
                    style: TextStyle(color: rop.critical),
                    textAlign: TextAlign.center,
                  ),
                ],
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _roundCallAction(
                      context,
                      label: 'decline'.tr(),
                      icon: Icons.call_end,
                      background: rop.criticalButton,
                      labelColor: rop.textOnPrimary,
                      onPressed: state.answering ? null : cubit.reject,
                    ),
                    _roundCallAction(
                      context,
                      label: 'answer'.tr(),
                      icon: Icons.call,
                      background: AppTheme.online,
                      labelColor: rop.textOnPrimary,
                      onPressed: state.answering ? null : cubit.answer,
                      loading: state.answering,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fullScreen(
    BuildContext context,
    CallCubit cubit,
    CallState state,
    MatrixCall call,
  ) {
    final rop = RopTheme.of(context);
    final showRemote = _renderersReady && _hasRemoteVideo(cubit);
    final showLocal = call.video && _renderersReady;

    return Positioned.fill(
      child: ColoredBox(
        color: rop.railEnd,
        child: Stack(
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
                    _avatar(call, rop, radius: 56),
                    const SizedBox(height: RopSpacing.lg),
                    Text(
                      state.roomName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: rop.textOnPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: RopSpacing.xs),
                    Text(
                      _subtitle(call),
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: rop.railText),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            if (showRemote)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x8C000000),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0xB3000000),
                    ],
                    stops: [0, 0.28, 0.62, 1],
                  ),
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: RopSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        _iconAction(
                          label: 'minimize'.tr(),
                          icon: Icons.keyboard_arrow_down,
                          color: Colors.white,
                          onPressed: _minimize,
                        ),
                        Expanded(
                          child: showRemote
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      state.roomName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: Colors.white),
                                    ),
                                    Text(
                                      _subtitle(call),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(color: Colors.white70),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: RopSpacing.lg,
                      ),
                      child: Text(
                        state.error!,
                        style: TextStyle(color: rop.critical),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      RopSpacing.md,
                      RopSpacing.md,
                      RopSpacing.md,
                      RopSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _dockButton(
                            label: 'mute'.tr(),
                            icon: call.muted ? Icons.mic_off : Icons.mic,
                            off: call.muted,
                            onPressed: () => cubit.setMuted(!call.muted),
                          ),
                        ),
                        Expanded(
                          child: _dockButton(
                            label: 'speaker'.tr(),
                            icon: call.speakerOn
                                ? Icons.volume_up
                                : Icons.hearing,
                            off: !call.speakerOn,
                            onPressed: () => cubit.setSpeaker(!call.speakerOn),
                          ),
                        ),
                        Expanded(
                          child: _dockButton(
                            label: 'video'.tr(),
                            icon: call.video
                                ? Icons.videocam
                                : Icons.videocam_off,
                            off: !call.video,
                            onPressed: () => cubit.setVideo(!call.video),
                          ),
                        ),
                        Expanded(
                          child: _dockButton(
                            label: 'hang_up'.tr(),
                            icon: Icons.call_end,
                            background: rop.criticalButton,
                            onPressed: cubit.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (showLocal)
              Positioned(
                right: 16,
                bottom: 168,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 108,
                    height: 148,
                    child: ColoredBox(
                      color: Colors.black,
                      child: RTCVideoView(
                        _local,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _minimizedCall(
    BuildContext context,
    CallCubit cubit,
    CallState state,
    MatrixCall call,
  ) {
    if (_renderersReady && _hasRemoteVideo(cubit)) {
      return Positioned(
        right: RopSpacing.sm,
        bottom: RopSpacing.sm,
        child: SafeArea(
          child: _videoPip(
            state,
            width: 120,
            height: 168,
            onExpand: _expand,
            onEnd: cubit.end,
          ),
        ),
      );
    }
    return _voiceBar(context, cubit, state, call);
  }

  Widget _voiceBar(
    BuildContext context,
    CallCubit cubit,
    CallState state,
    MatrixCall call,
  ) {
    final rop = RopTheme.of(context);

    return Positioned(
      top: 0,
      left: RopSpacing.sm,
      right: RopSpacing.sm,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: RopSpacing.xs),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            color: rop.railEnd.withValues(alpha: 0.92),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: RopSpacing.sm,
                  vertical: RopSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _expand,
                        child: Row(
                          children: [
                            Icon(
                              call.video ? Icons.videocam : Icons.call,
                              color: AppTheme.online,
                              size: 22,
                            ),
                            const SizedBox(width: RopSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    state.roomName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(color: rop.textOnPrimary),
                                  ),
                                  Text(
                                    _subtitle(call),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: rop.railText),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _compactControl(
                      label: 'mute'.tr(),
                      icon: call.muted ? Icons.mic_off : Icons.mic,
                      onPressed: () => cubit.setMuted(!call.muted),
                      rop: rop,
                    ),
                    _compactControl(
                      label: 'speaker'.tr(),
                      icon: call.speakerOn ? Icons.volume_up : Icons.hearing,
                      onPressed: () => cubit.setSpeaker(!call.speakerOn),
                      rop: rop,
                    ),
                    _compactControl(
                      label: 'hang_up'.tr(),
                      icon: Icons.call_end,
                      onPressed: cubit.end,
                      rop: rop,
                      destructive: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _videoPip(
    CallState state, {
    required double width,
    required double height,
    required VoidCallback onExpand,
    required VoidCallback onEnd,
  }) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: onExpand,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RTCVideoView(
                _remote,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xA6000000), Color(0x00000000)],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.roomName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'hang_up'.tr(),
                      button: true,
                      child: GestureDetector(
                        onTap: onEnd,
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(MatrixCall call, RopTheme rop, {required double radius}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white.withValues(alpha: 0.12),
      child: Icon(
        call.video ? Icons.videocam : Icons.call,
        size: radius * 0.7,
        color: rop.textOnPrimary,
      ),
    );
  }

  Widget _roundCallAction(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color background,
    required Color labelColor,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: background,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 72,
              height: 72,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(icon, color: Colors.white, size: 30),
              ),
            ),
          ),
        ),
        const SizedBox(height: RopSpacing.sm),
        Text(label, textAlign: TextAlign.center, style: _callLabel(labelColor)),
      ],
    );
  }

  Widget _dockButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool off = false,
    Color? background,
  }) {
    const diameter = 64.0;
    final fill = background ?? Colors.white.withValues(alpha: 0.16);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: label,
          button: true,
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: off && background == null
                    ? Border.all(color: Colors.white, width: 1.5)
                    : null,
              ),
              child: InkWell(
                onTap: onPressed,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: diameter,
                  height: diameter,
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _callLabel(const Color(0xE6FFFFFF)),
        ),
      ],
    );
  }

  TextStyle _callLabel(Color color) {
    return TextStyle(
      inherit: false,
      color: color,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.2,
      decoration: TextDecoration.none,
    );
  }

  Widget _iconAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Semantics(
      label: label,
      button: true,
      child: IconButton(color: color, onPressed: onPressed, icon: Icon(icon)),
    );
  }

  Widget _compactControl({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required RopTheme rop,
    bool destructive = false,
  }) {
    return Semantics(
      label: label,
      button: true,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          foregroundColor: destructive ? rop.textOnPrimary : rop.railText,
          backgroundColor: destructive ? rop.criticalButton : null,
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
      ),
    );
  }

  String _subtitle(MatrixCall call) {
    final status = _statusLabel(call);
    if (call.status != MatrixCallStatus.connected) {
      return status;
    }
    return '$status · ${_clockLabel(call)}';
  }

  String _clockLabel(MatrixCall call) {
    final elapsed = DateTime.now().difference(call.startedAt);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String _statusLabel(MatrixCall call) {
    return switch (call.status) {
      MatrixCallStatus.incoming =>
        (call.video ? 'incoming_video_call' : 'incoming_voice_call').tr(),
      MatrixCallStatus.outgoing => 'call_status_calling'.tr(),
      MatrixCallStatus.connecting => 'call_status_connecting'.tr(),
      MatrixCallStatus.connected =>
        call.muted ? 'call_status_muted'.tr() : 'call_status_connected'.tr(),
    };
  }
}

/// Shown when a call fails without an active session.
class CallErrorBanner extends StatelessWidget {
  const CallErrorBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final rop = RopTheme.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(RopSpacing.md),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: rop.surface,
            child: Padding(
              padding: const EdgeInsets.all(RopSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: rop.critical),
                  const SizedBox(width: RopSpacing.sm),
                  Expanded(child: Text(message)),
                  TextButton(onPressed: onDismiss, child: Text('close'.tr())),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

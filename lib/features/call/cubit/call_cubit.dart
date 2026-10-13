import 'package:element_x/features/call/cubit/call_state.dart';
export 'package:element_x/features/call/cubit/call_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_error.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/call/repo/call_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

class CallCubit extends Cubit<CallState> {
  CallCubit(this._repo, this._store) : super(const CallState()) {
    _listener = load;
    _store.addListener(_listener);
    load();
  }

  final CallRepo _repo;
  final MatrixStore _store;
  late final VoidCallback _listener;

  MediaStream? get localStream => _store.localCallStream;
  MediaStream? get remoteStream => _store.remoteCallStream;
  MediaStream? remoteStreamFor(String partyId) =>
      _store.remoteStreamFor(partyId);
  lk.VideoTrack? get localVideoTrack => _store.localCallVideoTrack;
  lk.VideoTrack? get remoteVideoTrack => _store.remoteCallVideoTrack;
  lk.VideoTrack? videoTrackFor(String partyId) => _store.videoTrackFor(partyId);

  void load() {
    final call = _repo.current;
    final stillRinging = call?.status == MatrixCallStatus.incoming;
    emit(
      CallState(
        call: call,
        roomName: call == null ? '' : _repo.roomName(call.roomId),
        mediaGeneration: _store.callMediaGeneration,
        participants: _repo.participants,
        error: _store.callError ?? state.error,
        answering: state.answering && stillRinging,
      ),
    );
  }

  Future<void> answer() async {
    emit(state.copyWith(answering: true, clearError: true));
    try {
      await _repo.answer();
      if (!isClosed) {
        load();
      }
    } catch (error) {
      if (!isClosed) {
        emit(state.copyWith(answering: false, error: matrixError(error)));
      }
    }
  }

  void setMuted(bool muted) {
    final call = state.call;
    if (call == null) {
      return;
    }
    _repo.update(call.copyWith(muted: muted));
  }

  void setVideo(bool video) {
    final call = state.call;
    if (call == null) {
      return;
    }
    _repo.update(call.copyWith(video: video));
  }

  void setSpeaker(bool speaker) {
    final call = state.call;
    if (call == null) {
      return;
    }
    _repo.update(call.copyWith(speakerOn: speaker));
  }

  Future<void> reject() => _repo.reject();

  void end() => _repo.end();

  void reportMediaError(Object error) {
    emit(state.copyWith(error: matrixError(error)));
  }

  void dismissFailure() {
    _store.clearCallError();
    if (!isClosed) {
      emit(state.copyWith(clearError: true));
    }
  }

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}

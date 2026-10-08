import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/call/repo/call_repo.dart';

class CallRepoImpl implements CallRepo {
  CallRepoImpl(this._store);

  final MatrixStore _store;

  @override
  MatrixCall? get current => _store.call;

  @override
  String roomName(String roomId) => _store.roomById(roomId)?.name ?? roomId;

  @override
  Future<void> start(String roomId, {bool video = false}) =>
      _store.startCall(roomId, video: video);

  @override
  Future<void> answer() => _store.answerCall();

  @override
  Future<void> reject() => _store.rejectCall();

  @override
  void update(MatrixCall call) => _store.updateCall(call);

  @override
  Future<void> end() => _store.endCall();
}

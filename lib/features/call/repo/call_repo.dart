import 'package:element_x/core/matrix/matrix_models.dart';

abstract class CallRepo {
  MatrixCall? get current;
  List<MatrixCallParticipant> get participants;
  MatrixGroupCall? groupCallIn(String roomId);
  String roomName(String roomId);
  Future<void> start(String roomId, {bool video = false});
  Future<void> join(String roomId);
  Future<void> answer();
  Future<void> reject();
  void update(MatrixCall call);
  Future<void> switchCamera();
  Future<void> end();
}

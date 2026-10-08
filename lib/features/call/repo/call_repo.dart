import 'package:element_x/core/matrix/matrix_models.dart';

abstract class CallRepo {
  MatrixCall? get current;
  String roomName(String roomId);
  Future<void> start(String roomId, {bool video = false});
  Future<void> answer();
  Future<void> reject();
  void update(MatrixCall call);
  Future<void> end();
}

import 'package:element_x/features/call/repo/call_repo.dart';
import 'package:element_x/features/roomcall/repo/roomcall_repo.dart';

class RoomCallRepoImpl implements RoomCallRepo {
  RoomCallRepoImpl(this._calls);

  final CallRepo _calls;

  @override
  bool get inCall => _calls.current != null;

  @override
  Future<void> start(String roomId, {bool video = false}) =>
      _calls.start(roomId, video: video);
}

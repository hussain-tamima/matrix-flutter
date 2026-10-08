abstract class RoomCallRepo {
  bool get inCall;
  Future<void> start(String roomId, {bool video = false});
}

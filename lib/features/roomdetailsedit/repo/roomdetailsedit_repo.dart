abstract class RoomDetailsEditRepo {
  ({String name, String topic})? details(String roomId);
  Future<void> save(
    String roomId, {
    required String name,
    required String topic,
  });
}

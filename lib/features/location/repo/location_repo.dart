abstract class LocationRepo {
  bool get sharingEnabled;
  Future<void> share(String roomId, String label);
}

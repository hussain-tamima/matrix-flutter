abstract class ReportRoomRepo {
  bool isReported(String roomId);
  Future<void> report(String roomId, String reason);
}

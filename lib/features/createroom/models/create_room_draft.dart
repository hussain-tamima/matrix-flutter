class CreateRoomDraft {
  const CreateRoomDraft({
    required this.name,
    this.topic = '',
    this.isPublic = false,
    this.isEncrypted = true,
    this.isSpace = false,
  });

  final String name;
  final String topic;
  final bool isPublic;
  final bool isEncrypted;
  final bool isSpace;
}

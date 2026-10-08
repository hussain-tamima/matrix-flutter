import 'package:element_x/features/createroom/models/create_room_draft.dart';

abstract class CreateRoomRepo {
  Future<String> create(CreateRoomDraft draft);
}

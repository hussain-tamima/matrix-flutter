import 'package:element_x/features/poll/models/poll_draft.dart';

abstract class PollRepo {
  void create(String roomId, PollDraft draft);
}

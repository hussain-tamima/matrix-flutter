import 'package:easy_localization/easy_localization.dart';

const roomPreviewKeys = {
  'preview_voice_call',
  'preview_video_call',
  'preview_call_ended',
  'preview_call_declined',
  'preview_call_answered',
  'preview_call_activity',
  'preview_unsupported_event',
};

/// Call and system previews are stored as keys so they follow the active locale.
String roomPreviewText(String lastMessage) {
  if (roomPreviewKeys.contains(lastMessage)) {
    return lastMessage.tr();
  }
  return lastMessage;
}

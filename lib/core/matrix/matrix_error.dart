import 'package:easy_localization/easy_localization.dart';
import 'package:matrix/matrix.dart';

/// Homeserver and SDK failures shown on the existing screens.
String matrixError(Object error) {
  if (error is MatrixException) {
    if (error.errorMessage.isNotEmpty) {
      return error.errorMessage;
    }
    return error.errcode;
  }
  final text = error.toString();
  const exceptionPrefix = 'Exception: ';
  if (text.startsWith(exceptionPrefix)) {
    return text.substring(exceptionPrefix.length);
  }
  return text;
}

const _translatedErrors = {
  'create_room_name_required',
  'join_room_missing',
  'join_room_not_found',
  'start_chat_id_required',
  'resolve_alias_missing',
  'resolve_alias_hash',
  'resolve_alias_not_found',
};

/// Validation keys are translated. Homeserver messages are already readable.
String userFacingError(String error) {
  if (_translatedErrors.contains(error)) return error.tr();
  return error;
}

import 'package:element_x/core/config/app_config.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:matrix/matrix.dart';

String defaultUserHomeserver(MatrixStore store) =>
    store.client.homeserver?.host ?? AppConfig.defaultHomeserver;

/// Resolves people-search / invite input to a full Matrix user ID, or null if
/// the input is not a user (room alias/id, empty, server-only, etc.).
String? resolveMatrixUserId(
  String input, {
  required String defaultHomeserver,
}) {
  final text = input.trim();
  if (text.isEmpty) return null;
  if (text.startsWith('#') || text.startsWith('!')) return null;

  if (text.isValidMatrixIdStrict()) {
    return text;
  }

  final withoutAt = text.startsWith('@') ? text.substring(1) : text;
  if (withoutAt.isEmpty) return null;

  final colon = withoutAt.indexOf(':');
  if (colon >= 0) {
    final local = withoutAt.substring(0, colon);
    final server = withoutAt.substring(colon + 1);
    if (local.isEmpty || server.isEmpty) return null;
    final resolved = '@$local:$server';
    return resolved.isValidMatrixIdStrict() ? resolved : null;
  }

  if (withoutAt.contains(' ')) return null;

  final resolved = '@$withoutAt:$defaultHomeserver';
  return resolved.isValidMatrixIdStrict() ? resolved : null;
}

String matrixUserLocalpart(String userId) {
  final trimmed = userId.trim();
  final withoutAt = trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
  return withoutAt.split(':').first;
}

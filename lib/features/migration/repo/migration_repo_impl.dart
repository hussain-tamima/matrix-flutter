import 'package:element_x/features/migration/repo/migration_repo.dart';

class MigrationRepoImpl implements MigrationRepo {
  @override
  String summary() {
    return 'Previous sessions cannot be copied into this app. Sign in with your password or a QR code, then set up secure backup to restore encrypted history.';
  }
}

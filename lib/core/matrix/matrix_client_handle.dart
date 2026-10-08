import 'package:matrix/matrix.dart';

/// The running Matrix client and the on-disk database path, when there is one.
class MatrixClientHandle {
  const MatrixClientHandle(this.client, {this.databasePath});

  final Client client;
  final String? databasePath;
}

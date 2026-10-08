import 'package:element_x/core/config/app_config.dart';
import 'package:element_x/core/matrix/matrix_client_handle.dart';
import 'package:matrix/matrix.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

Future<MatrixClientHandle> openMatrixClient({bool inMemory = false}) async {
  if (!vod.isInitialized()) {
    await vod.init(wasmPath: 'pkg/');
  }
  final database = await MatrixSdkDatabase.init('element_x');
  final client = Client(AppConfig.deviceDisplayName, database: database);
  await client.init(waitForFirstSync: false);
  return MatrixClientHandle(client);
}

int databaseSize(String? path) => 0;

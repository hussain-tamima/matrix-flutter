import 'package:element_x/core/config/app_config.dart';
import 'package:element_x/core/matrix/group_call_events.dart';
import 'package:element_x/core/matrix/matrix_client_handle.dart';
import 'package:element_x/core/matrix/stale_room.dart';
import 'package:matrix/matrix.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

Future<MatrixClientHandle> openMatrixClient({bool inMemory = false}) async {
  if (!vod.isInitialized()) {
    await vod.init(wasmPath: 'pkg/');
  }
  final database = await MatrixSdkDatabase.init('element_x');
  final client = Client(AppConfig.deviceDisplayName, database: database);
  client.importantStateEvents.addAll([
    groupCallEventType,
    groupCallMemberEventType,
    matrixRtcMemberEventType,
  ]);
  await client.init(waitForFirstSync: false);
  attachStaleRoomCleanup(client);
  return MatrixClientHandle(client);
}

int databaseSize(String? path) => 0;
